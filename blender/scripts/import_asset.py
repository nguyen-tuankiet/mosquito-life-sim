"""Dọn model thật (AI 3D / library) theo docs/ASSET_GUIDELINES.md §4 rồi lưu vào assets/<thư mục>/<tên>.glb.

  python blender/scripts/import_asset.py                    # mọi mục trong assets/import_config.json có file nguồn
  python blender/scripts/import_asset.py --only water_jar_vn --preview

Đầu vào: file thô (.glb/.gltf/.zip của Poly Haven…) đặt trong assets/_incoming/ (gitignore).
Các bước cho từng asset (cấu hình ở assets/import_config.json):
  1. import, gộp mesh, áp transform
  2. xoay (rotate_z) để mặt trước nhìn −Y; scale về kích thước thật (size: {"x"|"y"|"z": mét} hoặc "xyz")
  3. gốc đáy-giữa
  4. decimate về ngân sách tam giác (tris)
  5. vật liệu: "keep" (giữ texture gốc, thu nhỏ ≤ max_tex) | "auto_house" (gán mái/tường/gỗ/nền theo vùng —
     cho mesh trắng chưa có texture) | "single:<tên>" (1 vật liệu procedural, UV box)
  6. tuỳ chọn: water_disc (mặt nước trong lu/xô — nơi lăng quăng sống)
  7. xuất .glb vào assets/<folder>/<name>.glb (+ ảnh xem trước 4 hướng nếu --preview)
"""
import json
import math
import os
import sys
import tempfile
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np  # noqa: E402

import common as C  # noqa: E402

CONFIG = os.path.join(C.REPO, "assets", "import_config.json")
INCOMING = os.path.join(C.REPO, "assets", "_incoming")
PREVIEW = os.path.join(C.REPO, "docs", "reference", "assets")


def load_source(path):
    bpy = C.bpy_mod()
    if path.endswith(".zip"):
        tmp = tempfile.mkdtemp()
        with zipfile.ZipFile(path) as z:
            z.extractall(tmp)
        path = next(os.path.join(r, f) for r, _, fs in os.walk(tmp) for f in fs if f.endswith((".gltf", ".glb")))
    bpy.ops.import_scene.gltf(filepath=path)
    bpy.context.view_layer.update()
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    for o in bpy.context.scene.objects:
        o.select_set(o.type == "MESH")
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    ob.parent = None
    ob.matrix_world = ob.matrix_world.copy()
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for o in list(bpy.context.scene.objects):
        if o is not ob:
            bpy.data.objects.remove(o)
    return ob


def coords(ob):
    co = np.zeros(len(ob.data.vertices) * 3, np.float32)
    ob.data.vertices.foreach_get("co", co)
    return co.reshape(-1, 3)


def set_coords(ob, co):
    ob.data.vertices.foreach_set("co", co.astype(np.float32).ravel())
    ob.data.update()


def tris(ob):
    ob.data.calc_loop_triangles()
    return len(ob.data.loop_triangles)


def normalize(ob, cfg):
    co = coords(ob)
    a = math.radians(cfg.get("rotate_z", 0))
    if a:
        c, s = math.cos(a), math.sin(a)
        co = co @ np.array([[c, s, 0], [-s, c, 0], [0, 0, 1]], np.float32)
    lo, hi = co.min(0), co.max(0)
    size = hi - lo
    tgt = cfg["size"]
    k = np.ones(3, np.float32)
    if "xyz" in tgt:                    # từng trục riêng (rào: dài 3 m, cao 1.1 m)
        k = np.array(tgt["xyz"], np.float32) / size
    else:
        ax, val = next(iter(tgt.items()))
        k[:] = val / size["xyz".index(ax)]
    co = (co - np.array([(lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2]])) * k
    set_coords(ob, co)
    return co.max(0) - co.min(0)


def decimate(ob, target):
    bpy = C.bpy_mod()
    n = tris(ob)
    if n <= target:
        return n
    mod = ob.modifiers.new("dec", "DECIMATE")
    mod.ratio = target / n
    mod.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return tris(ob)


def box_uv(ob, scale_for_mat):
    """UV chiếu theo pháp tuyến chính, mỗi vật liệu một tỉ lệ (mét / 1 lần lặp texture)."""
    me = ob.data
    if not me.uv_layers:
        me.uv_layers.new(name="UVMap")
    uv = me.uv_layers.active.data
    for p in me.polygons:
        n = p.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        a, b = [(1, 2), (0, 2), (0, 1)][ax]
        s = scale_for_mat.get(p.material_index, 2.0)
        for li in p.loop_indices:
            v = me.vertices[me.loops[li].vertex_index].co
            uv[li].uv = (v[a] / s, v[b] / s)


def auto_house(ob, cfg):
    """Mesh nhà trắng → 4 vật liệu theo vùng: nền (thấp), mái (nghiêng/cao), mép mái dưới (gỗ tối), cột/hiên (gỗ), tường."""
    from assetgen import lib as L
    me = ob.data
    me.materials.clear()
    mats = {"plaster": L.mat("hv_plaster", L.tex_plaster(1)), "roof": L.mat("hv_roof", L.tex_roof(3)),
            "wood": L.mat("hv_wood", L.tex_wood(2)), "wood_dark": L.mat("hv_wood_dark", L.tex_wood(12, "#3E2A1C")),
            "concrete": L.mat("hv_concrete", L.tex_concrete(5))}
    order = list(mats)
    for m in mats.values():
        me.materials.append(m)
    co = coords(ob)
    H = co[:, 2].max()
    ymin, ymax = co[:, 1].min(), co[:, 1].max()
    xmin, xmax = co[:, 0].min(), co[:, 0].max()
    D = ymax - ymin
    W = xmax - xmin
    edge = 0.04
    r = cfg.get("regions", {})
    plinth, roof_z, porch = r.get("plinth", 0.07), r.get("roof_from", 0.42), r.get("porch_depth", 0.2)
    idx = []
    for p in me.polygons:
        c, n = p.center, p.normal
        at_edge = (c.x < xmin + edge * W or c.x > xmax - edge * W or c.y < ymin + edge * D or c.y > ymax - edge * D)
        if c.z < plinth * H:
            k = "concrete"
        elif abs(n.z) <= 0.35 and c.z > 0.3 * H and at_edge:
            k = "wood_dark"                  # diềm mái quanh mép ngoài (kể cả mái hiên thấp)
        elif c.z > roof_z * H and n.z > 0.25:
            k = "roof"
        elif c.z > roof_z * H * 0.85 and n.z < -0.25:
            k = "wood_dark"
        elif abs(n.z) < 0.4 and (c.y < ymin + porch * D or c.y > ymax - porch * D) and c.z < roof_z * H:
            k = "wood"                       # cột + mép hiên (trước/sau)
        elif c.z > roof_z * H and abs(n.z) <= 0.25:
            k = "plaster"                    # tường hồi (tam giác dưới mái)
        else:
            k = "plaster"
        idx.append(order.index(k))
    me.polygons.foreach_set("material_index", idx)
    box_uv(ob, {0: 3.0, 1: 2.5, 2: 1.2, 3: 1.2, 4: 2.0})


def cyl_uv(ob, scale):
    """UV hình trụ quanh trục Z (lu, chum): u theo vòng, v theo chiều cao — vân men chảy dọc."""
    me = ob.data
    if not me.uv_layers:
        me.uv_layers.new(name="UVMap")
    uv = me.uv_layers.active.data
    for p in me.polygons:
        us = []
        for li in p.loop_indices:
            v = me.vertices[me.loops[li].vertex_index].co
            us.append((math.atan2(v.y, v.x) / (2 * math.pi) + 0.5, v.z / scale))
        # tránh vệt kéo dài ở đường nối 0/1
        if max(u for u, _ in us) - min(u for u, _ in us) > 0.5:
            us = [(u + 1.0 if u < 0.5 else u, v) for u, v in us]
        for li, t in zip(p.loop_indices, us):
            uv[li].uv = (t[1], t[0] * 3.0)   # vân của tex_glaze chạy theo U → đặt U dọc thân lu


def single_material(ob, name, uv="box"):
    from assetgen import assets_v1 as A
    m = A.M()[name]
    ob.data.materials.clear()
    ob.data.materials.append(m)
    if uv == "cylindrical":
        cyl_uv(ob, 1.0)
    else:
        box_uv(ob, {0: 1.0 if name != "bamboo_dry" else 0.6})


def shrink_textures(ob, max_tex):
    for m in ob.data.materials:
        if not m or not m.use_nodes:
            continue
        for n in m.node_tree.nodes:
            if n.type == "TEX_IMAGE" and n.image and max(n.image.size) > max_tex:
                w, h = n.image.size
                k = max_tex / max(w, h)
                n.image.scale(int(w * k), int(h * k))
                n.image.pack()


def water_disc(ob, frac):
    """Mặt nước trong lu: đĩa tại frac × chiều cao, bán kính = thành trong ở độ cao đó."""
    import bmesh
    from assetgen import assets_v1 as A
    co = coords(ob)
    H = co[:, 2].max()
    z = frac * H
    band = co[np.abs(co[:, 2] - z) < 0.04 * H]
    r = np.percentile(np.hypot(band[:, 0], band[:, 1]), 8) * 0.98 if len(band) else 0.2
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    seg = 32
    vs = [bm.verts.new((r * math.cos(2 * math.pi * i / seg), r * math.sin(2 * math.pi * i / seg), z)) for i in range(seg)]
    f = bm.faces.new(vs)
    m = A.M()["water"]
    if m.name not in [x.name for x in ob.data.materials if x]:
        ob.data.materials.append(m)
    f.material_index = [x.name for x in ob.data.materials].index(m.name)
    bm.to_mesh(ob.data)
    bm.free()
    return r


def preview(ob, name):
    bpy = C.bpy_mod()
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 16
    sc.render.resolution_x, sc.render.resolution_y = 400, 300
    sc.render.image_settings.file_format = "WEBP"
    w = bpy.data.worlds.new("w")
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.75, 0.78, 0.85, 1)
    sc.world = w
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    sun.data.energy = 3.5
    sun.rotation_euler = (0.9, 0, 0.5)
    sc.collection.objects.link(sun)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    tgt = bpy.data.objects.new("tgt", None)
    sc.collection.objects.link(tgt)
    tr = cam.constraints.new("TRACK_TO")
    tr.target = tgt
    tr.track_axis = "TRACK_NEGATIVE_Z"
    tr.up_axis = "UP_Y"
    d = max(ob.dimensions) * 1.6
    tgt.location = (0, 0, ob.dimensions.z * 0.45)
    os.makedirs(PREVIEW, exist_ok=True)
    out = []
    for tag, a in (("front", -90), ("right", 0), ("back", 90), ("left", 180)):
        cam.location = (d * math.cos(math.radians(a)) * 0.9, d * math.sin(math.radians(a)) * 0.9, ob.dimensions.z * 0.9)
        p = os.path.join(PREVIEW, f"_tmp_{name}_{tag}.webp")
        sc.render.filepath = p
        bpy.ops.render.render(write_still=True)
        out.append(p)
    from PIL import Image
    ims = [Image.open(p) for p in out]
    sheet = Image.new("RGB", (400 * 4, 300))
    for i, im in enumerate(ims):
        sheet.paste(im.convert("RGB"), (i * 400, 0))
    dst = os.path.join(PREVIEW, f"imported_{name}.webp")
    sheet.save(dst, quality=85)
    for p in out:
        os.remove(p)
    return dst


def main():
    a = C.parse_args({"only": "", "preview": False})
    cfgs = json.load(open(CONFIG, encoding="utf-8"))["assets"]
    done = []
    for name, cfg in cfgs.items():
        if a.only and name not in a.only.split(","):
            continue
        src = os.path.join(INCOMING, cfg["source"])
        if not os.path.isfile(src):
            print(f"  – {name}: chưa có {os.path.relpath(src, C.REPO)}")
            continue
        C.reset_scene()
        from assetgen import lib as L
        L.MAT_CACHE.clear()       # scene mới → bỏ material/texture cache của lần trước
        L.TEX_CACHE.clear()
        ob = load_source(src)
        n0 = tris(ob)
        dims = normalize(ob, cfg)
        n1 = decimate(ob, cfg["tris"])
        mode = cfg.get("materials", "keep")
        if mode == "auto_house":
            auto_house(ob, cfg)
        elif mode.startswith("single:"):
            single_material(ob, mode.split(":", 1)[1], cfg.get("uv", "box"))
        shrink_textures(ob, cfg.get("max_tex", 1024))
        extra = ""
        if cfg.get("water_disc"):
            extra = f", mặt nước r={water_disc(ob, cfg['water_disc']):.2f} m"
        ob.name = name
        ob.data.name = name
        for p in ob.data.polygons:
            p.use_smooth = cfg.get("smooth", True)
        dst = os.path.join(C.REPO, "assets", cfg["folder"], name + ".glb")
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        L.export_glb(ob, dst)
        print(f"  ✓ {name}: {n0} → {n1} tris, {dims[0]:.2f} × {dims[1]:.2f} × {dims[2]:.2f} m, vật liệu {mode}{extra}"
              f" → {os.path.relpath(dst, C.REPO)}")
        if a.preview:
            print("    xem trước:", os.path.relpath(preview(ob, name), C.REPO))
        done.append(name)
    print(f"✓ {len(done)} asset")


if __name__ == "__main__":
    main()
