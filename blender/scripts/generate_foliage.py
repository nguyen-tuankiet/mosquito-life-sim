"""Rải thực vật procedural theo MAP_BIBLE §8 (không AI-generate từng cây).

Hai chế độ (map_spec.json → foliage.types):
  sparse : mỗi cây là 1 EMPTY  "TreePoint_0001", "BananaPoint_0001", "CoconutPoint_0001"…
           (ít, cần chỉnh tay được) — swap_assets.py thay bằng .glb như HousePoint.
  cloud  : 1 mesh point-cloud "BambooPoints", "GrassPoints", "RicePoints"… mỗi đỉnh = 1 điểm,
           thuộc tính rot / scale / variant. Geometry Nodes instance proxy trong collection
           "ASSET_<Type>" → swap_assets.py chỉ cần đổ model thật vào collection đó.
           generate_map.py xuất map_points.json để Godot dựng MultiMesh.

Tất cả dùng seed cố định → chạy lại cho kết quả y hệt.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np  # noqa: E402

import common as C  # noqa: E402

PROXY = {  # Type → (kiểu, kích thước, màu) — placeholder trước khi có asset thật
    "TreePoint": ("cone", (2.5, 7.0), (0.20, 0.45, 0.18)),
    "BananaPoint": ("cone", (1.8, 4.0), (0.40, 0.65, 0.20)),
    "CoconutPoint": ("cone", (2.0, 13.0), (0.30, 0.55, 0.20)),
    "BambooPoint": ("cyl", (0.6, 11.0), (0.45, 0.60, 0.25)),
    "ShrubPoint": ("cone", (1.2, 1.8), (0.22, 0.40, 0.16)),
    "ReedPoint": ("cyl", (0.25, 2.0), (0.55, 0.62, 0.30)),
    "LilyPoint": ("cyl", (0.45, 0.02), (0.25, 0.55, 0.25)),
    "RicePoint": ("box", (1.0, 0.9), (0.55, 0.78, 0.28)),
    "GrassTallPoint": ("cone", (0.5, 1.0), (0.55, 0.68, 0.30)),
    "GrassPoint": ("cone", (0.4, 0.3), (0.45, 0.62, 0.28)),
}


def jitter_grid(rect, spacing, rng, jitter=0.4):
    """Điểm phân bố đều có nhiễu (gần Poisson-disk, nhanh, tất định)."""
    x0, z0, x1, z1 = rect
    xs = np.arange(x0 + spacing / 2, x1, spacing)
    zs = np.arange(z0 + spacing / 2, z1, spacing)
    X, Z = np.meshgrid(xs, zs)
    X = X.ravel() + rng.uniform(-jitter, jitter, X.size) * spacing
    Z = Z.ravel() + rng.uniform(-jitter, jitter, Z.size) * spacing
    return X, Z


def thin(X, Z, min_dist, count, rng):
    """Chọn tối đa `count` điểm cách nhau ≥ min_dist (dùng cho loại sparse ít cây)."""
    order = rng.permutation(X.size)
    keep = []
    for i in order:
        if all((X[i] - X[j]) ** 2 + (Z[i] - Z[j]) ** 2 >= min_dist ** 2 for j in keep):
            keep.append(i)
            if count and len(keep) >= count:
                break
    keep = np.array(sorted(keep), dtype=int)
    return X[keep], Z[keep]


def allowed(spec, M, t, X, Z):
    """Mặt nạ luật Bible cho từng loại. Trả về mask True = được đặt."""
    zid = M.zone_id(X, Z)
    base_block = M.road(X, Z, 0.5) | M.house(X, Z, 3.0) | M.landmark(X, Z)
    W = spec["water"]
    ok = np.zeros(X.shape, bool)
    for z in spec["foliage"]["types"][t]["zones"]:
        if z in spec["zones"]:
            ok |= zid == z
        elif z == "filler":
            ok |= zid == "filler"
        elif z == "Z04_rim":
            ok |= M.paddy(X, Z, 8.0) & ~M.paddy(X, Z, 3.0)
        elif z == "Z06_under":
            ok |= zid == "Z06"
        elif z == "canal_banks":
            for k in ("canal_main", "canal_branch"):
                d = C.dist_to_polyline(X, Z, W[k]["centerline"])
                ok |= (d > W[k]["w"] / 2 + 0.5) & (d < W[k]["w"] / 2 + W[k]["bank_w"])
        elif z == "pond_rim":
            r = C.ellipse_r(X, Z, W["pond_main"]["center"], W["pond_main"]["radii"])
            ok |= (r > 0.96) & (r < 1.10)
        elif z == "pond_water":
            r = C.ellipse_r(X, Z, W["pond_main"]["center"], W["pond_main"]["radii"])
            ok |= r < 0.9
        elif z == "paddy_rim":
            ok |= M.paddy(X, Z, 1.0) & ~M.paddy(X, Z, -0.5)
        else:
            raise ValueError(f"zone không hỗ trợ: {z}")

    if t == "LilyPoint":
        return ok & ~M.road(X, Z, 1.0)
    if t == "ReedPoint":
        return ok & ~base_block
    if t == "RicePoint":
        # không trên bờ ruộng / bờ R4
        bund = C.paddy_bund_mask(spec, X, Z, W["paddy_main"]["bund_w"])
        return ok & ~bund & ~base_block & ~M.landmark(X, Z, 6.0)

    block = base_block | M.water(X, Z, 0.8) | M.puddle(X, Z, 0.5)
    if t not in ("GrassPoint", "GrassTallPoint"):
        # luật Bible: không cây thân gỗ trong ruộng
        block |= M.paddy(X, Z, 0.5 if t != "CoconutPoint" else 3.0)
    if t in ("BambooPoint", "ShrubPoint") and "Z02" in spec["zones"]:
        block |= zid == "Z02"  # vườn bờ Tây (Z02a) nằm trong rừng tre → để trống
    return ok & ~block


def _proxy(t, col):
    kind, (r, h), color = PROXY[t]
    mat = C.material("MAT_PX_" + t, color)
    if kind == "cyl":
        ob = C.cylinder("PX_" + t, r, h, (0, 0, 0), col, mat, seg=8)
    elif kind == "cone":
        ob = C.cylinder("PX_" + t, r, h, (0, 0, 0), col, mat, seg=8, r_top=0.0)
    else:
        ob = C.box("PX_" + t, (r, r, h), (0, 0, 0), col, mat)
    ob["placeholder"] = True
    return ob


def _instancer_tree(name):
    """Geometry Nodes: point-cloud mesh → Instance on Points (chọn biến thể theo 'variant')."""
    bpy = C.bpy_mod()
    ng = bpy.data.node_groups.get(name)
    if ng:
        return ng
    ng = bpy.data.node_groups.new(name, "GeometryNodeTree")
    ng.interface.new_socket("Geometry", in_out="INPUT", socket_type="NodeSocketGeometry")
    ng.interface.new_socket("Assets", in_out="INPUT", socket_type="NodeSocketCollection")
    ng.interface.new_socket("Geometry", in_out="OUTPUT", socket_type="NodeSocketGeometry")
    N, L = ng.nodes, ng.links
    gi, go = N.new("NodeGroupInput"), N.new("NodeGroupOutput")
    ci = N.new("GeometryNodeCollectionInfo")
    ci.transform_space = "ORIGINAL"
    ci.inputs["Separate Children"].default_value = True
    ci.inputs["Reset Children"].default_value = True
    m2p = N.new("GeometryNodeMeshToPoints")
    iop = N.new("GeometryNodeInstanceOnPoints")
    iop.inputs["Pick Instance"].default_value = True
    na_rot = N.new("GeometryNodeInputNamedAttribute")
    na_rot.data_type = "FLOAT"
    na_rot.inputs["Name"].default_value = "rot"
    na_sc = N.new("GeometryNodeInputNamedAttribute")
    na_sc.data_type = "FLOAT"
    na_sc.inputs["Name"].default_value = "scale"
    na_var = N.new("GeometryNodeInputNamedAttribute")
    na_var.data_type = "INT"
    na_var.inputs["Name"].default_value = "variant"
    comb = N.new("ShaderNodeCombineXYZ")
    e2r = N.new("FunctionNodeEulerToRotation")
    L.new(gi.outputs["Geometry"], m2p.inputs["Mesh"])
    L.new(m2p.outputs["Points"], iop.inputs["Points"])
    L.new(gi.outputs["Assets"], ci.inputs["Collection"])
    L.new(ci.outputs["Instances"], iop.inputs["Instance"])
    L.new(na_var.outputs["Attribute"], iop.inputs["Instance Index"])
    L.new(na_rot.outputs["Attribute"], comb.inputs["Z"])
    L.new(comb.outputs["Vector"], e2r.inputs["Euler"])
    L.new(e2r.outputs["Rotation"], iop.inputs["Rotation"])
    L.new(na_sc.outputs["Attribute"], iop.inputs["Scale"])
    L.new(iop.outputs["Instances"], go.inputs["Geometry"])
    return ng


def _surface_y(spec, ctx, t, X, Z):
    if t == "LilyPoint":
        return np.full(X.shape, spec["water"]["pond_main"]["surface_y"] + 0.01)
    return ctx["height"](X, Z)


def build(spec, ctx):
    bpy = C.bpy_mod()
    fr = ctx["frame"]
    M = C.Masks(spec)
    F = spec["foliage"]
    root = C.collection("Foliage", ctx["root"])
    lib = C.collection("ASSET_LIBRARY", ctx["root"])  # proxy / asset thật cho cloud instancing
    ctx.setdefault("clouds", {})
    W, D = fr.W, fr.D

    for i, (t, cfg) in enumerate(F["types"].items()):
        rng = np.random.default_rng(F["seed"] + i * 7919)
        X, Z = jitter_grid((0, 0, W, D), cfg["min_dist"], rng, cfg.get("jitter", 0.4))
        m = allowed(spec, M, t, X, Z)
        X, Z = X[m], Z[m]
        if "keep" in cfg:
            k = rng.random(X.size) < cfg["keep"]
            X, Z = X[k], Z[k]
        if cfg["mode"] == "sparse":
            X, Z = thin(X, Z, cfg["min_dist"], cfg.get("count"), rng)
        n = X.size
        Y = _surface_y(spec, ctx, t, X, Z)
        rot = rng.uniform(-math.pi, math.pi, n)
        sc = rng.uniform(cfg["scale"][0], cfg["scale"][1], n)
        var = rng.integers(0, 1 << 16, n)

        if cfg["mode"] == "sparse":
            col = C.collection(t.replace("Point", "s"), root)
            for j in range(n):
                p = C.empty(f"{t}_{j + 1:04d}", fr.bl(X[j], Z[j], Y[j]), col, rot_z=rot[j], display="ARROWS",
                            size=1.0, props={"point_type": t, "variant": int(var[j]), "zone": str(M.zone_id(
                                np.array([X[j]]), np.array([Z[j]]))[0])})
                p.scale = (sc[j],) * 3
                ph = _proxy(t, col)
                ph.name = p.name + "__PH"
                ph.parent = p
            print(f"  {t:15s} sparse {n:6d}")
            continue

        # cloud
        acol = C.collection("ASSET_" + t, lib)
        if not acol.objects:
            px = _proxy(t, acol)
            px.location = (0, 0, -1000)  # proxy nằm xa; Reset Children đưa về gốc khi instance
        lib.hide_render = True
        lib.hide_viewport = True

        verts = np.stack([X - W / 2, -(Z - D / 2), Y], -1).astype(np.float32)
        me = bpy.data.meshes.new(t.replace("Point", "Points"))
        me.vertices.add(n)
        me.vertices.foreach_set("co", verts.ravel())
        for name, arr, typ in (("rot", rot, "FLOAT"), ("scale", sc, "FLOAT"), ("variant", var, "INT")):
            a = me.attributes.new(name, typ, "POINT")
            a.data.foreach_set("value", arr.astype(np.float32 if typ == "FLOAT" else np.int32))
        me.update()
        ob = bpy.data.objects.new(me.name, me)
        C.collection("Clouds", root).objects.link(ob)
        mod = ob.modifiers.new("Instancer", "NODES")
        mod.node_group = _instancer_tree("MAP_Instancer")
        sock = next(s for s in mod.node_group.interface.items_tree
                    if getattr(s, "in_out", "") == "INPUT" and s.name == "Assets")
        mod[sock.identifier] = acol
        ob["point_type"] = t
        ob["asset_collection"] = acol.name
        ob["count"] = n
        ctx["clouds"][t] = {"x": X, "z": Z, "y": Y, "rot": rot, "scale": sc, "variant": var}
        print(f"  {t:15s} cloud  {n:6d}")
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
