"""Sinh phần nhân tạo của làng theo MAP_BIBLE §4 §7 §10 §11 §12:
Road, Bridge, House placeholders (HousePoint_*), Fence (FencePoint_*), vật chứa nước
(JarPoint/BucketPoint/BasinPoint/TirePoint), Landmark (LandmarkPoint_*), Zone volumes,
PlayerSpawn, CameraBounds.

Mỗi "Point" là một EMPTY mang dữ liệu (custom props). Placeholder là con của Point và có tên
"<Point>__PH". swap_assets.py sẽ ẩn placeholder và gắn model thật (.glb) vào đúng Point đó.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np  # noqa: E402

import common as C  # noqa: E402

# độ nâng khác nhau để chỗ giao nhau không bị z-fighting (đường chính nằm trên)
ROAD_Y_OFF = {"dirt_road": 0.05, "dirt_path": 0.04, "bund": 0.035, "trail": 0.03, "footpath": 0.025}
# tuyến tính (≈ sRGB #9A6B45 đường đất, #6E4B33 đất ẩm — ART_DIRECTION §3)
ROAD_COLORS = {"dirt_road": (0.32, 0.15, 0.06), "dirt_path": (0.30, 0.15, 0.07),
               "bund": (0.16, 0.30, 0.05), "trail": (0.16, 0.08, 0.035), "footpath": (0.22, 0.12, 0.05)}


def _h(ctx, x, z):
    return float(ctx["height"](np.array([x]), np.array([z]))[0])


def _point(name, ctx, col, x, z, rot=0.0, y=None, props=None, display="ARROWS", size=1.0):
    y = _h(ctx, x, z) if y is None else y
    p = C.empty(name, ctx["frame"].bl(x, z, y), col, rot_z=rot, display=display, size=size, props=props)
    p["point_type"] = name.split("_")[0]
    return p


def _ph(point, ob):
    """Gắn placeholder làm con của point (toạ độ cục bộ = gốc point)."""
    ob.name = point.name + "__PH"
    ob.parent = point
    ob.location = (0, 0, 0)
    ob.rotation_euler = (0, 0, 0)
    ob["placeholder"] = True
    for c in list(ob.users_collection):
        c.objects.unlink(ob)
    for c in point.users_collection:
        c.objects.link(ob)
    return ob


def _house_placeholder(point, size, wall_h, col):
    """HOUSE_PLACEHOLDER: khối tường + mái ngói 2 mái (mặt trước = -Y)."""
    sx, sy = size
    walls = C.box("tmp", (sx, sy, wall_h), (0, 0, 0), col, C.material("MAT_PH_Wall", (0.92, 0.88, 0.78)))
    _ph(point, walls)
    walls.name = point.name + "__PH"
    rh, ov = 1.8, 0.6
    hx, hy = sx / 2 + ov, sy / 2 + ov
    v = [(-hx, -hy, wall_h), (hx, -hy, wall_h), (hx, 0, wall_h + rh), (-hx, 0, wall_h + rh),
         (-hx, hy, wall_h), (hx, hy, wall_h)]
    f = [(0, 1, 2, 3), (3, 2, 5, 4), (0, 3, 4), (1, 5, 2)]
    roof = C.mesh_object(point.name + "__PH_roof", v, f, col, C.material("MAT_PH_Roof", (0.62, 0.25, 0.16)))
    roof.parent = walls
    roof["placeholder"] = True
    door = C.box(point.name + "__PH_door", (1.2, 0.1, 2.1), (0, -sy / 2 - 0.05, 0), col,
                 C.material("MAT_PH_Door", (0.35, 0.22, 0.12)))
    door.parent = walls
    door["placeholder"] = True
    return walls


LANDMARK_PH = {
    "power_pole": lambda n, col: C.cylinder(n, 0.15, 8.0, (0, 0, 0), col, C.material("MAT_PH_Concrete", (0.7, 0.7, 0.68)), seg=8),
    "haystack": lambda n, col: C.cylinder(n, 2.2, 3.0, (0, 0, 0), col, C.material("MAT_PH_Hay", (0.80, 0.68, 0.35)), r_top=0.2),
    "big_tree": lambda n, col: C.cylinder(n, 0.9, 14.0, (0, 0, 0), col, C.material("MAT_PH_Trunk", (0.35, 0.25, 0.15)), seg=10, r_top=0.5),
    "hut": lambda n, col: C.box(n, (3.0, 3.0, 2.6), (0, 0, 0), col, C.material("MAT_PH_Bamboo", (0.72, 0.62, 0.38))),
    "jetty": lambda n, col: C.box(n, (6.0, 1.8, 0.25), (0, 0, 0), col, C.material("MAT_PH_Wood", (0.50, 0.36, 0.22))),
    "boat": lambda n, col: C.box(n, (1.2, 4.5, 0.5), (0, 0, 0), col, C.material("MAT_PH_Wood", (0.50, 0.36, 0.22))),
    "buffalo": lambda n, col: C.box(n, (1.0, 2.4, 1.5), (0, 0, 0), col, C.material("MAT_PH_Buffalo", (0.25, 0.24, 0.24))),
    "culvert": lambda n, col: C.box(n, (1.5, 5.0, 0.6), (0, 0, -0.3), col, C.material("MAT_PH_Concrete", (0.7, 0.7, 0.68))),
    "chicken": lambda n, col: C.box(n, (0.3, 0.4, 0.4), (0, 0, 0), col, C.material("MAT_PH_Chicken", (0.75, 0.45, 0.25))),
}

CONTAINER_PH = {  # kind → (Point prefix, bán kính, cao, màu)
    "jar": ("JarPoint", 0.45, 0.9, (0.45, 0.30, 0.20)),
    "bucket": ("BucketPoint", 0.18, 0.35, (0.20, 0.45, 0.70)),
    "basin": ("BasinPoint", 0.35, 0.18, (0.70, 0.70, 0.72)),
    "tire": ("TirePoint", 0.35, 0.22, (0.08, 0.08, 0.08)),
}


LOT_PH = {  # prefix → (dạng, bán kính, cao, màu) placeholder greybox
    "HayPoint": ("cone", 1.2, 1.8, (0.80, 0.68, 0.35)),
    "ChickenPoint": ("box", 0.3, 0.4, (0.75, 0.45, 0.25)),
    "GardenTreePoint": ("cyl", 1.6, 6.0, (0.22, 0.42, 0.16)),
    "GardenBananaPoint": ("cyl", 1.0, 3.5, (0.35, 0.55, 0.20)),
    "GardenPalmPoint": ("cyl", 0.3, 11.0, (0.40, 0.35, 0.20)),
}


def _lots(spec, ctx, M, counts, n_fence):
    """MAP v2 — mỗi nhà (trừ H01: sân do game dựng) là một lô đất: sân trước có chum/xô/chậu, gà;
    sau và hai bên có rơm, cây ăn trái, chuối, dừa; rào tre phía sau + hai bên. Vật nào đè đường, nước,
    ruộng, nhà khác, landmark hay điểm đẻ trứng thì bỏ (vật không đặt trên mép nền nhà để khỏi lơ lửng)."""
    lots = spec["houses"].get("lots")
    if not lots:
        return n_fence
    col = C.collection("Lots", ctx["root"])
    fs = spec["fences"]
    eggs = [e["pos"] for e in spec["egg_sites"].values()]
    pads = [(h["pos"], C.house_pad_r(h) + 1.0) for h in spec["houses"]["list"].values()]

    def free(x, z, margin=1.0):
        X, Z = np.array([x]), np.array([z])
        if (M.road(X, Z, margin)[0] or M.water(X, Z, 1.5)[0] or M.paddy(X, Z, 1.0)[0] or M.puddle(X, Z, 1.0)[0]
                or M.landmark(X, Z, 3.0)[0]):
            return False
        if any(math.dist((x, z), e) < 1.5 for e in eggs):
            return False
        # ngoài mọi nền nhà (+1 m): không chồng lên nhà, không đứng trên bậc nền
        return all(max(abs(x - c[0]), abs(z - c[1])) > r for c, r in pads)

    num = {}

    def put(prefix, x, z, rot, ph_kind=None, props=None):
        num[prefix] = num.get(prefix, 0) + 1
        p = _point(f"{prefix}_{num[prefix]:03d}", ctx, col, x, z, rot=rot, props=props, size=0.5)
        kind, r, hgt, colr = LOT_PH[prefix]
        mat = C.material("MAT_PH_" + prefix, colr)
        if kind == "box":
            _ph(p, C.box("tmp", (r, r, hgt), (0, 0, 0), col, mat))
        else:
            _ph(p, C.cylinder("tmp", r, hgt, (0, 0, 0), col, mat, seg=8, r_top=0.1 if kind == "cone" else r))
        return p

    for hid, h in spec["houses"]["list"].items():
        if h.get("hero"):
            continue
        rng = np.random.default_rng(lots["seed"] + int(hid[1:]))
        (fx, fz), (sx, sz) = C.house_axes(spec, h)
        hx, hz = h["pos"]
        hw, hd = h["size"][0] / 2, h["size"][1] / 2
        r = C.house_pad_r(h) + 2.0
        at = lambda u, v: (hx + sx * u + fx * v, hz + sz * u + fz * v)  # noqa: E731
        side = 1.0 if rng.random() < 0.5 else -1.0
        # sân trước: chum + xô (+ chậu), gà
        for prefix, u, v, prob, ck in (("JarPoint", side * hw * 0.7, r + 0.6, 0.9, "jar"),
                                       ("BucketPoint", side * (hw * 0.7 + 1.0), r + 0.9, 0.6, "bucket"),
                                       ("BasinPoint", -side * hw * 0.6, r + 1.2, 0.35, "basin")):
            x, z = at(u, v)
            if rng.random() < prob and free(x, z):
                counts[prefix] = counts.get(prefix, 0) + 1
                pt = _point(f"{prefix}_{counts[prefix]:02d}", ctx, col, x, z, rot=float(rng.uniform(0, 6.28)),
                            props={"egg_site": "", "zone": "Z01", "game_site": "", "lot": hid}, size=0.5)
                cp, cr, ch, cc = CONTAINER_PH[ck]
                _ph(pt, C.cylinder("tmp", cr, ch, (0, 0, 0), col, C.material("MAT_PH_" + cp, cc), seg=16))
        if rng.random() < 0.7:
            for _ in range(int(rng.integers(1, 4))):
                x, z = at(float(rng.uniform(-hw, hw)), float(rng.uniform(r + 1.5, r + 5.0)))
                if free(x, z, 0.5):
                    put("ChickenPoint", x, z, float(rng.uniform(0, 6.28)), props={"lot": hid})
        # sau nhà & hai bên: rơm, cây ăn trái, chuối, dừa
        if rng.random() < 0.45:
            x, z = at(float(rng.uniform(-hw, hw)), -(r + 2.5))
            if free(x, z, 1.5):
                put("HayPoint", x, z, float(rng.uniform(0, 6.28)), props={"lot": hid})
        for _ in range(int(rng.integers(2, 4))):
            x, z = at(float(rng.uniform(-hw - 3, hw + 3)), -float(rng.uniform(r + 4.0, r + 9.0)))
            if free(x, z, 1.5):
                put("GardenTreePoint", x, z, float(rng.uniform(0, 6.28)), props={"lot": hid})
        for sgn in (-1.0, 1.0):
            if rng.random() < 0.75:
                x, z = at(sgn * float(rng.uniform(r + 1.5, r + 3.5)), float(rng.uniform(-hd - 2, hd)))
                if free(x, z, 1.2):
                    put("GardenBananaPoint", x, z, float(rng.uniform(0, 6.28)), props={"lot": hid})
        if rng.random() < 0.45:
            x, z = at(-side * (hw + 3.0), r + 3.5)
            if free(x, z, 1.5):
                put("GardenPalmPoint", x, z, float(rng.uniform(0, 6.28)), props={"lot": hid})
        # rào tre: sau nhà + hai bên (để trống phía trước — sân mở ra lối/đường)
        ub, vb, us = hw + lots["fence_side"], -lots["fence_back"] - hd, hw + lots["fence_side"]
        seg = fs["segment_len"]
        lines = [((-ub, vb), (ub, vb))] + [((sg * us, vb), (sg * us, hd)) for sg in (-1.0, 1.0)]
        for (u0, v0), (u1, v1) in lines:
            L = math.hypot(u1 - u0, v1 - v0)
            k = max(1, int(L // seg))
            for i in range(k):
                t = (i + 0.5) / k
                x, z = at(u0 + (u1 - u0) * t, v0 + (v1 - v0) * t)
                if not free(x, z, 0.8):
                    continue
                dx, dz = at(u1, v1)[0] - at(u0, v0)[0], at(u1, v1)[1] - at(u0, v0)[1]
                n_fence += 1
                p = _point(f"FencePoint_{n_fence:03d}", ctx, col, x, z, rot=-math.atan2(dz, dx),
                           props={"lot": hid}, size=0.5)
                _ph(p, C.box("tmp", (seg, 0.08, fs["height"]), (0, 0, 0), col,
                             C.material("MAT_PH_Bamboo", (0.72, 0.62, 0.38))))
    print(f"  lô đất: {sum(num.values())} vật + rào → {n_fence} đoạn rào tổng; {num}")
    return n_fence


def build(spec, ctx):
    fr = ctx["frame"]
    root = ctx["root"]
    M = C.Masks(spec)

    # ── Đường §4 ──
    rcol = C.collection("Roads", root)
    for rid, r in spec["roads"].items():
        mat = C.material("MAT_Road_" + r["type"], ROAD_COLORS[r["type"]], 0.95)
        ob = C.ribbon("Road_" + rid, r["points"], r["w"], lambda x, z: _h(ctx, x, z), fr, rcol, mat,
                      step=2.0, y_off=ROAD_Y_OFF[r["type"]])
        ob["road"] = rid
        ob["road_type"] = r["type"]
        ob["zone"] = "Z08"
    for bid, b in spec["bridges"].items():
        x, z = b["at"]
        p = _point("BridgePoint_" + bid, ctx, rcol, x, z, rot=0.0, y=b["deck_y"], props={"road": b["road"]})
        # R2 chạy Đông–Tây → cầu dài theo trục X
        _ph(p, C.box("tmp", (b["len"], b["w"], 0.25), (0, 0, 0), rcol,
                     C.material("MAT_PH_Wood", (0.50, 0.36, 0.22))))

    # ── Nhà §7 ──
    hcol = C.collection("Houses", root)
    Hs = spec["houses"]
    for hid, h in Hs["list"].items():
        x, z = h["pos"]
        facing = C.house_facing(spec, h)
        p = _point(f"HousePoint_{hid[1:]}", ctx, hcol, x, z, rot=C.house_rot(spec, h), y=Hs["pad_y"],
                   props={"house_id": hid, "facing": facing, "footprint": list(h["size"]),
                          "hero": bool(h.get("hero", False)), "zone": "Z01"}, size=3)
        _house_placeholder(p, h["size"], Hs["wall_h"], hcol)

    # ── Hàng rào §8 fence_bamboo ──
    fcol = C.collection("Fences", root)
    fs = spec["fences"]
    doors = []
    for h in Hs["list"].values():
        f = C.house_facing(spec, h)
        x, z = h["pos"]
        if f in ("east", "west"):
            doors.append(z)
    n = 0
    for run in fs["runs"]:
        pts = spec["roads"][run["along"]]["points"]
        for (x, z, tx, tz) in C.polyline_frames(pts, fs["segment_len"])[:-1]:
            if "from_z" in run and not (run["from_z"] <= z <= run["to_z"]):
                continue
            if run["door_gap"] and any(abs(z - dz) < run["door_gap"] for dz in doors):
                continue  # chừa lối vào nhà
            if any(C.dist_to_polyline(np.array([x]), np.array([z]), r["points"])[0] < r["w"] / 2 + 1.5
                   for rid, r in spec["roads"].items() if rid != run["along"]):
                continue  # chừa chỗ ngõ / lối nhỏ nhập vào đường
            for s in run["sides"]:
                px, pz = x - tz * run["offset"] * s, z + tx * run["offset"] * s
                if M.water(np.array([px]), np.array([pz]), 0.5)[0]:
                    continue
                # đoạn rào dài theo hướng đường: trục X cục bộ → hướng (tx, tz)
                rot = -math.atan2(tz, tx)
                n += 1
                p = _point(f"FencePoint_{n:03d}", ctx, fcol, px + tx * fs["segment_len"] / 2,
                           pz + tz * fs["segment_len"] / 2, rot=rot, props={"along": run["along"]}, size=0.5)
                _ph(p, C.box("tmp", (fs["segment_len"], 0.08, fs["height"]), (0, 0, 0), fcol,
                             C.material("MAT_PH_Bamboo", (0.72, 0.62, 0.38))))

    # ── Vật chứa nước §6 (lu, xô, chậu, lốp) ──
    ccol = C.collection("Containers", root)
    counts = {}
    for wid, e in spec["egg_sites"].items():
        if e["kind"] not in CONTAINER_PH:
            continue
        prefix, r, hgt, colr = CONTAINER_PH[e["kind"]]
        counts[prefix] = counts.get(prefix, 0) + 1
        x, z = e["pos"]
        p = _point(f"{prefix}_{counts[prefix]:02d}", ctx, ccol, x, z,
                   props={"egg_site": wid, "zone": e["zone"], "game_site": e["game_site"] or ""}, size=0.5)
        _ph(p, C.cylinder("tmp", r, hgt, (0, 0, 0), ccol, C.material("MAT_PH_" + prefix, colr), seg=16,
                          r_top=r * (0.8 if e["kind"] == "jar" else 1.0)))

    # ── Lô đất từng hộ (MAP v2): chum, xô, rơm, gà, cây vườn, rào tre ──
    n = _lots(spec, ctx, M, counts, n)

    # ── Landmark §10 ──
    lcol = C.collection("Landmarks", root)
    for lid, L in spec["landmarks"].items():
        x, z = L["pos"]
        y = None
        if L["kind"] in ("jetty", "boat"):
            y = spec["water"]["pond_main"]["surface_y"] + (0.6 if L["kind"] == "jetty" else 0.0)
        p = _point(f"LandmarkPoint_{lid}", ctx, lcol, x, z, y=y,
                   props={"landmark": lid, "label": L["name"], "kind": L["kind"], "zone": L["zone"]}, size=1.5)
        if L["kind"] in LANDMARK_PH:
            _ph(p, LANDMARK_PH[L["kind"]]("tmp", lcol))

    # ── Zone volumes (empty hộp, dùng làm Area3D trong Godot) ──
    zcol = C.collection("Zones", root)
    for zid, z in spec["zones"].items():
        for i, (x0, z0, x1, z1) in enumerate(z["rects"]):
            cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
            C.empty(f"Zone_{zid}" + (chr(ord("a") + i) if len(z["rects"]) > 1 else ""),
                    fr.bl(cx, cz, 15.0), zcol, display="CUBE", size=1.0,
                    scale=((x1 - x0) / 2, (z1 - z0) / 2, 15.0),
                    props={"zone": zid, "zone_name": z["name"], "zone_key": z["key"]})

    # ── Spawn §11 + Camera §12 ──
    scol = C.collection("Gameplay", root)
    ps = spec["player_spawn"]["first_life"]
    e = spec["egg_sites"][ps["egg_site"]]
    x, z = e["pos"]
    C.empty("PlayerSpawn_FirstLife", fr.bl(x, z, _h(ctx, x, z) + e["y"]), scol,
            rot_z=C.FACING_ROT[ps["facing"]], display="SINGLE_ARROW", size=2,
            props={"egg_site": ps["egg_site"], "stage": "egg"})
    cam = spec["camera"]
    for name, rect in (("CameraBounds_Playable", cam["playable_rect"]), ("CameraBounds_Hard", cam["hard_rect"])):
        x0, z0, x1, z1 = rect
        C.empty(name, fr.bl((x0 + x1) / 2, (z0 + z1) / 2, cam["sky_ceiling_y"] / 2), scol, display="CUBE",
                scale=((x1 - x0) / 2, (z1 - z0) / 2, cam["sky_ceiling_y"] / 2),
                props={k: v for k, v in cam.items() if not isinstance(v, list)})
    return root


if __name__ == "__main__":
    import generate_terrain
    a = C.parse_args({"res": 2.0, "out": ""})
    spec = C.load_spec()
    C.reset_scene()
    ctx = {"frame": C.Frame(spec), "res": a.res, "root": C.collection("MAP")}
    generate_terrain.build(spec, ctx)
    build(spec, ctx)
    if a.out:
        C.bpy_mod().ops.wm.save_as_mainfile(filepath=os.path.abspath(a.out))
