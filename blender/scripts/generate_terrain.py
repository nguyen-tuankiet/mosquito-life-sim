"""Sinh địa hình (Terrain) theo MAP_BIBLE §3 + §9.

Độc lập:  blender -b -P blender/scripts/generate_terrain.py -- --res 2
Trong pipeline: generate_map.py gọi build(spec, ctx).

Kết quả: object "Terrain" (lưới đều, màu đỉnh theo zone), và ctx["height"](x, z) để các bước sau
lấy cao độ mặt đất.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np  # noqa: E402

import common as C  # noqa: E402


def _box_blur(a, r):
    if r <= 0:
        return a
    k = 2 * r + 1
    p = np.pad(a, r, mode="edge")
    c = p.cumsum(0).cumsum(1)
    c = np.pad(c, ((1, 0), (1, 0)))
    return (c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]) / (k * k)


def heightfield(spec, X, Z, res):
    """Cao độ Bible y tại lưới (X, Z). Trả về (H, zone_ids)."""
    M = C.Masks(spec)
    zid = M.zone_id(X, Z)
    H = np.full(X.shape, spec["filler"]["ground_y"], dtype=np.float64)
    for k, z in spec["zones"].items():
        if z["ground_y"] is not None:
            H[zid == k] = z["ground_y"]

    # gò nhẹ giữa rừng tre
    hb = spec["bamboo_hump"]
    d = np.hypot(X - hb["center"][0], Z - hb["center"][1]) / hb["radius"]
    H += np.where(zid == "Z06", hb["height"] * np.clip(1 - d * d, 0, 1), 0.0)

    # làm mềm ranh giới zone (~6 m)
    H = _box_blur(H, max(1, int(round(3.0 / res))))

    W = spec["water"]

    # ruộng: mặt 0.0 phẳng + bờ ruộng (bund) theo lưới thửa
    pd = W["paddy_main"]
    x0, z0, x1, z1 = pd["rect"]
    inside = C.in_rects(X, Z, [pd["rect"]])
    H[inside] = spec["zones"]["Z04"]["ground_y"]
    bund = C.paddy_bund_mask(spec, X, Z, pd["bund_w"] / 2 + res / 2)
    H[inside & bund] = pd["bund_y"]

    # nền nhà
    Hs = spec["houses"]
    for h in Hs["list"].values():
        (cx, cz), (sw, sd) = h["pos"], h["size"]
        r = max(sw, sd) / 2 + 1.0 + res  # + res: mép nền phẳng cả khi lấy mẫu giữa hai ô lưới
        m = (np.abs(X - cx) < r) & (np.abs(Z - cz) < r)
        H[m] = Hs["pad_y"]

    # chợ (MAP v2.1): mặt bằng phẳng
    if spec.get("market"):
        H = np.where(C.Masks(spec).market(X, Z, 1.0), spec["market"]["y"], H)

    # đường (đắp nền) — trail thì giữ nền rừng
    for r in spec["roads"].values():
        if r["y"] is None:
            continue
        d = C.dist_to_polyline(X, Z, r["points"])
        core = d < r["w"] / 2
        edge = (d >= r["w"] / 2) & (d < r["w"] / 2 + 1.5)
        t = np.clip((d - r["w"] / 2) / 1.5, 0, 1)
        H = np.where(core, r["y"], H)
        H = np.where(edge, r["y"] * (1 - t) + H * t, H)

    # vũng sau mưa: lõm nhẹ
    for x, z, rr in W["puddles_meadow"]["patches"]:
        d = np.hypot(X - x, Z - z) / rr
        H -= np.where(d < 1, W["puddles_meadow"]["depth"] * 0.5 * (1 + np.cos(np.pi * np.clip(d, 0, 1))), 0)

    # ao: lòng chảo cosin + bờ
    pdm = W["pond_main"]
    r = C.ellipse_r(X, Z, pdm["center"], pdm["radii"])
    bowl = pdm["bed_y"] + (pdm["surface_y"] + 0.05 - pdm["bed_y"]) * (r ** 2)
    H = np.where(r < 1, np.minimum(H, bowl), H)
    bank = (r >= 1) & (r < pdm["bank_scale"])
    t = (r - 1) / (pdm["bank_scale"] - 1)
    H = np.where(bank, (pdm["surface_y"] + 0.05) * (1 - t) + H * t, H)

    # kênh nhánh (đường đè lên = cống ngầm, nên làm trước rồi đắp lại đường)
    for key in ("canal_branch", "canal_main"):
        c = W[key]
        d = C.dist_to_polyline(X, Z, c["centerline"])
        hw = c["w"] / 2
        prof = c["bed_y"] + (c["surface_y"] + 0.05 - c["bed_y"]) * np.clip(d / hw, 0, 1) ** 2
        Hc = np.where(d < hw, np.minimum(H, prof), H)
        bk = (d >= hw) & (d < hw + c["bank_w"])
        t = np.clip((d - hw) / c["bank_w"], 0, 1)
        Hc = np.where(bk, np.minimum(H, (c["surface_y"] + 0.1) * (1 - t) + c["bank_y"] * t), Hc)
        if key == "canal_branch":
            # cống: đường đi qua kênh nhánh giữ nguyên mặt đường
            road = C.Masks(spec).road(X, Z, include_trail=False)
            Hc = np.where(road, H, Hc)
        H = Hc
    return H, zid


# Bảng màu nền stage env — docs/ART_DIRECTION.md §3 (sRGB hex → tuyến tính khi gán vào màu đỉnh).
LOOK = {
    "grass": "#5E8A34", "grass_dry": "#8A9A4A", "yard": "#8A6A48", "litter": "#5C4A2E", "mud": "#5A4430",
    "paddy_mud": "#4E4430", "bund": "#6F9A36", "road": "#9A6B45", "meadow": "#7FA040", "garden": "#4E7A2A",
}


def _lin(h):
    c = np.array([int(h.lstrip("#")[i:i + 2], 16) / 255 for i in (0, 2, 4)], np.float32)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def _noise(X, Z, scale, seed):
    """Value noise mượt (nội suy song tuyến lưới ngẫu nhiên) — biến thiên màu tự nhiên."""
    rng = np.random.default_rng(seed)
    gx, gz = X / scale, Z / scale
    nx, nz = int(gx.max()) + 2, int(gz.max()) + 2
    g = rng.random((nz, nx))
    i0, j0 = gz.astype(int), gx.astype(int)
    fz, fx = gz - i0, gx - j0
    fx, fz = fx * fx * (3 - 2 * fx), fz * fz * (3 - 2 * fz)
    return (g[i0, j0] * (1 - fx) + g[i0, j0 + 1] * fx) * (1 - fz) + (g[i0 + 1, j0] * (1 - fx) + g[i0 + 1, j0 + 1] * fx) * fz


def look_colors(spec, X, Z, H, zid):
    M = C.Masks(spec)
    n = 0.55 * _noise(X, Z, 9.0, 1) + 0.3 * _noise(X, Z, 3.0, 2) + 0.15 * _noise(X, Z, 40.0, 3)
    pick = {"filler": "grass", "Z01": "grass", "Z02": "garden", "Z03": "grass", "Z04": "paddy_mud",
            "Z06": "litter", "Z07": "meadow"}
    out = np.zeros(X.shape + (3,), np.float32)
    for k, v in pick.items():
        out[zid == k] = _lin(LOOK[v])
    # sân đất loang cỏ, rừng tre loang rêu, cỏ loang cỏ khô
    mix = np.clip((n - 0.45) * 3, 0, 1)[..., None]
    alt = np.zeros_like(out)
    for k, v in {"filler": "grass_dry", "Z01": "grass", "Z02": "grass", "Z03": "grass_dry", "Z06": "garden",
                 "Z07": "grass_dry", "Z04": "paddy_mud"}.items():
        alt[zid == k] = _lin(LOOK[v])
    out = out * (1 - mix * 0.6) + alt * mix * 0.6
    # sân đất quanh nhà (bán kính sân + mép loang), còn lại của Z01 là cỏ
    Hs = spec["houses"]
    # MAP v2: sân bo tròn, lệch ra phía cửa (không còn ô vuông nâu quanh mỗi nhà); sau nhà là cỏ/vườn
    yard = M.house(X, Z, 1.2)
    for h in Hs["list"].values():
        (fx, fz), _ = C.house_axes(spec, h)
        cx = h["pos"][0] + fx * (h["size"][1] / 2 + 2.5)
        cz = h["pos"][1] + fz * (h["size"][1] / 2 + 2.5)
        rad = max(h["size"]) / 2 + (Hs["yard_radius"] - 5.0) + 2.5 * n
        yard |= np.hypot(X - cx, Z - cz) < rad
    out[yard] = out[yard] * 0.25 + _lin(LOOK["yard"]) * 0.75
    out[C.paddy_bund_mask(spec, X, Z, spec["water"]["paddy_main"]["bund_w"] / 2 + 0.3) & M.paddy(X, Z)] = _lin(LOOK["bund"])
    mk = M.market(X, Z, 1.5 * n)                     # sân chợ đất nện, mép loang
    out[mk] = out[mk] * 0.15 + _lin(LOOK["yard"]) * 0.85
    out[M.road(X, Z)] = _lin(LOOK["road"])
    near = M.water(X, Z, 2.5) & (H < 0.15)          # bờ bùn ven kênh/ao
    out[near] = _lin(LOOK["mud"])
    out *= (0.85 + 0.3 * n)[..., None]
    return np.clip(out, 0, 1)


def build(spec, ctx):
    bpy = C.bpy_mod()
    fr = ctx["frame"]
    res = float(ctx.get("res", 2.0))
    col = C.collection("Terrain", ctx["root"])

    xs = np.arange(0.0, fr.W + 1e-6, res)
    zs = np.arange(0.0, fr.D + 1e-6, res)
    X, Z = np.meshgrid(xs, zs)          # shape (nz, nx)
    H, zid = heightfield(spec, X, Z, res)
    nz, nx = X.shape

    verts = np.stack([X - fr.W / 2, -(Z - fr.D / 2), H], axis=-1).reshape(-1, 3)
    ii, jj = np.meshgrid(np.arange(nz - 1), np.arange(nx - 1), indexing="ij")
    a = (ii * nx + jj).ravel()
    # Z tăng → Y Blender giảm, nên thứ tự (a, a+nx, a+nx+1, a+1) cho pháp tuyến hướng lên
    quads = np.stack([a, a + nx, a + nx + 1, a + 1], axis=-1)

    me = bpy.data.meshes.new("Terrain")
    me.vertices.add(len(verts))
    me.vertices.foreach_set("co", verts.astype(np.float32).ravel())
    me.loops.add(quads.size)
    me.loops.foreach_set("vertex_index", quads.astype(np.int32).ravel())
    me.polygons.add(len(quads))
    me.polygons.foreach_set("loop_start", (np.arange(len(quads)) * 4).astype(np.int32))
    me.update(calc_edges=True)
    me.validate()

    cols = np.zeros((nz * nx, 4), np.float32)
    cols[:, 3] = 1
    if ctx.get("stage") == "env":
        cols[:, :3] = look_colors(spec, X, Z, H, zid).reshape(-1, 3)
    else:
        # greybox: màu theo zone (để duyệt bố cục)
        flat = zid.ravel()
        cols[:, :3] = spec["filler"]["color"]
        for k, z in spec["zones"].items():
            cols[flat == k, :3] = z["color"]
        road = C.Masks(spec).road(X, Z).ravel()
        cols[road, :3] = spec["zones"]["Z08"]["color"]
        wet = (H.ravel() < -0.35)  # chỉ lòng chìm dưới mọi mặt nước; bờ trên mặt nước giữ màu zone (không răng cưa)
        cols[wet, :3] = (0.30, 0.26, 0.20)
    ca = me.color_attributes.new("zone_color", "FLOAT_COLOR", "POINT")
    ca.data.foreach_set("color", cols.ravel())

    for p in me.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new("Terrain", me)
    col.objects.link(ob)
    me.materials.append(C.material("MAT_Terrain", (0.5, 0.6, 0.3), 0.95, use_vcol="zone_color"))
    ob["bible"] = "MAP_BIBLE §3 §9"
    ob["res_m"] = res

    def height(x, z):
        """Lấy mẫu cao độ (song tuyến) tại toạ độ Bible."""
        x = np.clip(np.asarray(x, float) / res, 0, nx - 1.001)
        z = np.clip(np.asarray(z, float) / res, 0, nz - 1.001)
        i0, j0 = z.astype(int), x.astype(int)
        fz, fx = z - i0, x - j0
        h00, h01 = H[i0, j0], H[i0, j0 + 1]
        h10, h11 = H[i0 + 1, j0], H[i0 + 1, j0 + 1]
        return (h00 * (1 - fx) + h01 * fx) * (1 - fz) + (h10 * (1 - fx) + h11 * fx) * fz

    ctx["height"] = height
    ctx["H"] = H
    return ob


if __name__ == "__main__":
    a = C.parse_args({"res": 2.0, "out": ""})
    spec = C.load_spec()
    C.reset_scene()
    ctx = {"frame": C.Frame(spec), "res": a.res, "root": C.collection("MAP")}
    build(spec, ctx)
    if a.out:
        C.bpy_mod().ops.wm.save_as_mainfile(filepath=os.path.abspath(a.out))
