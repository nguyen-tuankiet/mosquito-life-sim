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
    bund = np.zeros(X.shape, bool)
    for i in range(pd["plot_cols"] + 1):
        bund |= np.abs(X - (x0 + (x1 - x0) * i / pd["plot_cols"])) < pd["bund_w"] / 2 + res / 2
    for j in range(pd["plot_rows"] + 1):
        bund |= np.abs(Z - (z0 + (z1 - z0) * j / pd["plot_rows"])) < pd["bund_w"] / 2 + res / 2
    H[inside & bund] = pd["bund_y"]

    # nền nhà
    Hs = spec["houses"]
    for h in Hs["list"].values():
        (cx, cz), (sw, sd) = h["pos"], h["size"]
        r = max(sw, sd) / 2 + 1.0
        m = (np.abs(X - cx) < r) & (np.abs(Z - cz) < r)
        H[m] = Hs["pad_y"]

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

    # màu đỉnh theo zone (để xem trước bố cục; texture thật thay sau)
    cols = np.zeros((nz * nx, 4), np.float32)
    cols[:, 3] = 1
    flat = zid.ravel()
    cols[:, :3] = spec["filler"]["color"]
    for k, z in spec["zones"].items():
        cols[flat == k, :3] = z["color"]
    road = C.Masks(spec).road(X, Z).ravel()
    cols[road, :3] = spec["zones"]["Z08"]["color"]
    wet = (H.ravel() < -0.05)
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
