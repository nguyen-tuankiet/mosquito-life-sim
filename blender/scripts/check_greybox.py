"""M1 — kiểm tra tự động greybox theo checklist trong docs/ROADMAP.md.

  python blender/scripts/check_greybox.py [--res 2] [--report docs/reference/greybox/M1_check.md]

Sinh lại greybox trong bộ nhớ (không ghi .blend) rồi kiểm tra:
  1. Bố cục khớp Bible (validate_spec)
  2. Không vật thể chìm / lơ lửng (gốc Point so với mặt đất / mặt nước)
  3. Nền nhà phẳng, đúng cao độ pad
  4. Đường liền mạch: không lọt xuống nước (trừ cầu/cống), độ dốc hợp lý
  5. Mặt nước đúng cao độ: bờ cao hơn mặt nước (không hở), lòng thấp hơn mặt nước
  6. Mọi thứ nằm trong camera bounds
Thoát mã 1 nếu có lỗi (FAIL); cảnh báo (WARN) không làm hỏng.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np  # noqa: E402

import common as C  # noqa: E402

TOL = 0.15          # m — sai lệch cho phép giữa gốc vật thể và mặt đỡ
MAX_ROAD_GRADE = 0.15


class Report:
    def __init__(self):
        self.rows = []

    def add(self, group, ok, msg, level="FAIL"):
        self.rows.append((group, "PASS" if ok else level, msg))

    @property
    def failed(self):
        return any(r[1] == "FAIL" for r in self.rows)

    def text(self):
        out = ["| Nhóm | Kết quả | Chi tiết |", "|---|---|---|"]
        out += [f"| {g} | {'✅' if s == 'PASS' else ('⚠️' if s == 'WARN' else '❌')} {s} | {m} |" for g, s, m in self.rows]
        return "\n".join(out)


def ring(cx, cz, rx, rz, n=360):
    a = np.linspace(0, 2 * math.pi, n, endpoint=False)
    return cx + rx * np.cos(a), cz + rz * np.sin(a)


def offset_lines(pts, d, step=1.0):
    fr = C.polyline_frames(pts, step)
    xs, zs = [], []
    for x, z, tx, tz in fr:
        for s in (-1, 1):
            xs.append(x - tz * d * s)
            zs.append(z + tx * d * s)
    return np.array(xs), np.array(zs)


def main():
    a = C.parse_args({"res": 2.0, "report": ""})
    import generate_terrain
    import generate_village
    import generate_water

    spec = C.load_spec()
    R = Report()
    warns = C.validate_spec(spec)
    R.add("Bố cục", not warns, "Khớp luật MAP_BIBLE §7/§14" if not warns else "; ".join(warns))

    C.reset_scene()
    ctx = {"frame": C.Frame(spec), "res": a.res, "root": C.collection("MAP")}
    generate_terrain.build(spec, ctx)
    generate_water.build(spec, ctx)
    generate_village.build(spec, ctx)
    h = ctx["height"]
    fr = ctx["frame"]
    W = spec["water"]
    M = C.Masks(spec)
    bpy = C.bpy_mod()

    # 2. chìm / lơ lửng
    bad = []
    n = 0
    for ob in bpy.data.objects:
        if ob.type != "EMPTY" or ob.parent is not None:
            continue
        t = ob.get("point_type", "")
        if not t or t in ("Zone", "CameraBounds"):
            continue
        bx, by, bz = ob.location
        x, z = bx + fr.W / 2, -by + fr.D / 2
        g = float(h(np.array([x]), np.array([z]))[0])
        kind = ob.get("kind", "")
        if t == "BridgePoint":
            continue  # kiểm riêng ở mục đường
        if t == "HousePoint":
            ref = spec["houses"]["pad_y"]
        elif kind in ("jetty", "boat"):
            ref = W["pond_main"]["surface_y"] + (0.6 if kind == "jetty" else 0.0)
        elif kind == "culvert":
            ref = g
        else:
            ref = g
        n += 1
        if abs(bz - ref) > TOL:
            bad.append(f"{ob.name} y={bz:.2f} (mặt đỡ {ref:.2f})")
    for ob in bpy.data.objects:
        if ob.name.startswith("EggSite_"):
            e = spec["egg_sites"][ob["egg_site"]]
            x, z = e["pos"]
            g = float(h(np.array([x]), np.array([z]))[0])
            n += 1
            if e["y_mode"] == "absolute" and g > e["y"] + 0.05:
                bad.append(f"{ob.name}: mặt nước {e['y']} nhưng đáy/đất tại đó {g:.2f} (khô)")
    R.add("Chìm / lơ lửng", not bad, f"{n} vật thể, sai lệch ≤ {TOL} m" if not bad else "; ".join(bad[:8]))

    # 3. nền nhà
    bad = []
    for hid, hs in spec["houses"]["list"].items():
        (x, z), (sw, sd) = hs["pos"], hs["size"]
        r = max(sw, sd) / 2
        X, Z = np.meshgrid(np.linspace(x - r, x + r, 9), np.linspace(z - r, z + r, 9))
        H = h(X, Z)
        if np.abs(H - spec["houses"]["pad_y"]).max() > TOL:
            bad.append(f"{hid} lệch {np.abs(H - spec['houses']['pad_y']).max():.2f} m")
    R.add("Nền nhà", not bad, "7/7 nhà phẳng ở y = %.1f m" % spec["houses"]["pad_y"] if not bad else "; ".join(bad))

    # 4. đường
    bridge_spans = [(b["at"], b["len"] / 2 + 1) for b in spec["bridges"].values()]
    for rid, r in spec["roads"].items():
        fr_pts = C.polyline_frames(r["points"], 1.0)
        X = np.array([p[0] for p in fr_pts])
        Z = np.array([p[1] for p in fr_pts])
        on_bridge = np.zeros(X.shape, bool)
        for (bx, bz), rr in bridge_spans:
            on_bridge |= np.hypot(X - bx, Z - bz) < rr
        H = h(X, Z)
        wet = (H < 0.0) & ~on_bridge
        grade = np.abs(np.diff(H)) / 1.0
        steep = grade[~(on_bridge[1:] | on_bridge[:-1])].max() if len(grade) else 0
        L = sum(math.dist(p, q) for p, q in zip(r["points"][:-1], r["points"][1:]))
        ok = not wet.any() and steep <= MAX_ROAD_GRADE
        msg = f"{rid}: dài {L:.0f} m, dốc max {steep * 100:.0f}%"
        if wet.any():
            msg += f", {wet.sum()} m lọt xuống nước tại ({X[wet][0]:.0f}, {Z[wet][0]:.0f})"
        R.add("Đường", ok, msg, level="FAIL" if wet.any() else "WARN")
    # cầu nối đúng hai bờ
    for bid, b in spec["bridges"].items():
        (bx, bz), L = b["at"], b["len"]
        ends = h(np.array([bx - L / 2, bx + L / 2]), np.array([bz, bz]))
        ok = (ends >= W["canal_main"]["surface_y"] + 0.2).all() and abs(b["deck_y"] - ends.max()) < 1.5
        R.add("Đường", ok, f"Cầu {bid}: hai đầu cầu y = {ends[0]:.2f} / {ends[1]:.2f}, mặt cầu {b['deck_y']} m")
    # liên thông (mạng đường)
    roads = {k: v for k, v in spec["roads"].items()}
    adj = {k: set() for k in roads}
    for a_, ra in roads.items():
        for b_, rb in roads.items():
            if a_ < b_:
                d = C.dist_to_polyline(np.array([p[0] for p in rb["points"]]), np.array([p[1] for p in rb["points"]]),
                                       ra["points"]).min()
                d2 = C.dist_to_polyline(np.array([p[0] for p in ra["points"]]), np.array([p[1] for p in ra["points"]]),
                                        rb["points"]).min()
                if min(d, d2) < (ra["w"] + rb["w"]) / 2 + 1:
                    adj[a_].add(b_)
                    adj[b_].add(a_)
    seen, stack = set(), ["R1_main_spine"]
    while stack:
        k = stack.pop()
        if k not in seen:
            seen.add(k)
            stack += list(adj[k])
    iso = sorted(set(roads) - seen)
    R.add("Đường", not iso, "Mọi đường nối với R1" if not iso else
          f"Không nối với R1: {', '.join(iso)} (đi bộ không tới; muỗi bay vẫn tới)", level="WARN")

    # 5. nước
    for key in ("canal_main", "canal_branch"):
        c = W[key]
        Xb, Zb = offset_lines(c["centerline"], c["w"] / 2 + 0.5 + 1.5)
        Hb = h(Xb, Zb)
        # bỏ chỗ hợp lưu / giao với nước khác / ra mép map
        inside = (Xb > 1) & (Xb < fr.W - 1) & (Zb > 1) & (Zb < fr.D - 1)
        other = M.water(Xb, Zb, 0.5) | M.paddy(Xb, Zb, 0.5)
        chk = inside & ~other
        leak = chk & (Hb < c["surface_y"])
        Xc, Zc = offset_lines(c["centerline"], 0.0)
        bed = h(Xc, Zc)
        road = M.road(Xc, Zc, a.res, include_trail=False)  # cầu/cống (+1 ô lưới quanh nền đường)
        dry = (bed > c["surface_y"]) & ~road & (Xc > 1) & (Xc < fr.W - 1)
        ok = not leak.any() and not dry.any()
        msg = f"{key}: bờ ≥ mặt nước {c['surface_y']} m tại {chk.sum()} điểm; lòng sâu {c['surface_y'] - bed[~road].max():.2f}–{c['surface_y'] - bed.min():.2f} m"
        if leak.any():
            msg += f"; HỞ {leak.sum()} điểm, vd ({Xb[leak][0]:.0f}, {Zb[leak][0]:.0f}) y={Hb[leak][0]:.2f}"
        if dry.any():
            msg += f"; lòng KHÔ {dry.sum()} điểm"
        if road.any():
            msg += f"; {int(road.sum() / 2)} m đi dưới cầu/cống"
        R.add("Mặt nước", ok, msg)
    p = W["pond_main"]
    Xr, Zr = ring(p["center"][0], p["center"][1], p["radii"][0] * 1.08, p["radii"][1] * 1.08)
    Hr = h(Xr, Zr)
    Xi, Zi = ring(p["center"][0], p["center"][1], p["radii"][0] * 0.5, p["radii"][1] * 0.5)
    ok = (Hr >= p["surface_y"]).all() and (h(Xi, Zi) < p["surface_y"]).all()
    R.add("Mặt nước", ok, f"pond_main: bờ min {Hr.min():.2f} ≥ mặt nước {p['surface_y']}; "
          f"đáy {h(np.array([p['center'][0]]), np.array([p['center'][1]]))[0]:.2f} m")
    pd = W["paddy_main"]
    x0, z0, x1, z1 = pd["rect"]
    X, Z = np.meshgrid(np.linspace(x0 + 2, x1 - 2, 60), np.linspace(z0 + 2, z1 - 2, 60))
    H = h(X, Z)
    flooded = (H < pd["surface_y"]).mean()
    edge_x = np.concatenate([np.linspace(x0, x1, 80), np.linspace(x0, x1, 80), np.full(80, x0 - 1.5), np.full(80, x1 + 1.5)])
    edge_z = np.concatenate([np.full(80, z0 - 1.5), np.full(80, z1 + 1.5), np.linspace(z0, z1, 80), np.linspace(z0, z1, 80)])
    ok_edge = ~M.water(edge_x, edge_z, 0.5) & ~M.road(edge_x, edge_z)
    leak = ok_edge & (h(edge_x, edge_z) < pd["surface_y"])
    R.add("Mặt nước", flooded > 0.8 and not leak.any(),
          f"paddy_main: {flooded * 100:.0f}% mặt ruộng ngập (còn lại là bờ ruộng)" +
          (f"; HỞ mép ruộng {leak.sum()} điểm" if leak.any() else "; mép ruộng kín"))

    # 6. camera bounds
    cam = spec["camera"]["playable_rect"]
    outside = []
    for ob in bpy.data.objects:
        if ob.type == "EMPTY" and ob.parent is None and ob.get("point_type") not in (None, "Zone", "CameraBounds"):
            x, z = ob.location.x + fr.W / 2, -ob.location.y + fr.D / 2
            if not (cam[0] <= x <= cam[2] and cam[1] <= z <= cam[3]):
                outside.append(ob.name)
    R.add("Camera bounds", not outside, "Mọi vật thể nằm trong playable_rect" if not outside else ", ".join(outside))

    print(R.text())
    if a.report:
        os.makedirs(os.path.dirname(os.path.abspath(a.report)), exist_ok=True)
        with open(a.report, "w", encoding="utf-8") as f:
            f.write("# M1 — Kết quả kiểm tra tự động greybox\n\n")
            f.write("Sinh bởi `python blender/scripts/check_greybox.py` từ `docs/map_spec.json`.\n\n")
            f.write(R.text() + "\n")
    sys.exit(1 if R.failed else 0)


if __name__ == "__main__":
    main()
