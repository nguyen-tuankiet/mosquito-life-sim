"""Dựng asset P0 procedural v1 → assets/_procedural/<thư mục>/<tên>.glb (+ contact sheet).

  blender -b -P blender/scripts/make_assets.py -- [--only house_vn_01,water_jar_vn] [--sheet]
  (hoặc: python blender/scripts/make_assets.py --sheet)

Đây là bản thay thế tạm cho model AI 3D / library. File thật cùng tên đặt ở assets/environment|props|creatures
sẽ được swap_assets.py ưu tiên hơn (assets/_procedural/ đứng sau trong asset_manifest.json → asset_dirs).
assets/_procedural/ được gitignore: chạy lại script là có (seed cố định → kết quả y hệt).
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common as C  # noqa: E402

OUT = os.path.join(C.REPO, "assets", "_procedural")
SHEET = os.path.join(C.REPO, "docs", "reference", "assets", "procedural_v1.webp")
# Ngân sách tam giác (docs/ASSET_GUIDELINES.md §4)
BUDGET = {"house": 15000, "water_jar": 2000, "bucket": 2000, "basin": 2000, "tire": 2000, "fence": 1500,
          "banyan": 8000, "fruit_tree": 8000, "bamboo_clump": 3000, "grass": 500, "rice": 500}


def budget(name):
    for k, v in BUDGET.items():
        if k in name:
            return v
    return 8000


def main():
    a = C.parse_args({"only": "", "sheet": False})
    C.reset_scene()
    from assetgen import assets_v1 as A
    from assetgen import lib as L
    m = A.M()
    names = [n for n in A.REGISTRY if not a.only or n in a.only.split(",")]
    built = []
    over = []
    for name in names:
        folder, fn, keep = A.REGISTRY[name]
        b = fn(m)
        tris = b.tris()
        ob = L.finalize(b.build(), keep_origin=keep)
        path = os.path.join(OUT, folder, name + ".glb")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        L.export_glb(ob, path)
        flag = "" if tris <= budget(name) else f"  ⚠ vượt ngân sách {budget(name)}"
        if flag:
            over.append(name)
        print(f"  {name:20s} {tris:6d} tris → {os.path.relpath(path, C.REPO)}{flag}")
        built.append(ob)
    if a.sheet:
        contact_sheet(built)
    print(f"✓ {len(built)} asset" + (f", vượt ngân sách: {', '.join(over)}" if over else ""))


def contact_sheet(objs):
    """Xếp các asset thành lưới, render Cycles CPU → docs/reference/assets/procedural_v1.webp."""
    bpy = C.bpy_mod()
    sc = bpy.context.scene
    cols = 7
    cell = 16.0
    for i, ob in enumerate(objs):
        dims = max(ob.dimensions)
        s = min(1.0, 12.0 / dims) if dims > 12 else (4.0 / dims if dims < 2.0 else 1.0)
        ob.scale = (s, s, s)
        ob.location = ((i % cols) * cell, -(i // cols) * cell, 0)
        ob.rotation_euler = (0, 0, math.radians(-25))
    rows = (len(objs) + cols - 1) // cols
    cx, cy = (cols - 1) * cell / 2, -(rows - 1) * cell / 2
    ground = bpy.data.objects.new("ground", bpy.data.meshes.new("ground"))
    w = cols * cell
    ground.data.from_pydata([(-cell, cell, 0), (w, cell, 0), (w, -rows * cell, 0), (-cell, -rows * cell, 0)], [],
                            [(0, 1, 2, 3)])
    ground.data.materials.append(C.material("MAT_sheet_ground", (0.55, 0.52, 0.45)))
    sc.collection.objects.link(ground)
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.68, 0.85, 1)
    sc.world = world
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(50), 0, math.radians(-35))
    sc.collection.objects.link(sun)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = cols * cell * 1.02
    cam.location = (cx, cy - 60, 45)
    cam.rotation_euler = (math.radians(62), 0, 0)
    sc.collection.objects.link(cam)
    sc.camera = cam
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 24
    sc.render.resolution_x, sc.render.resolution_y = 1400, int(1400 * rows / cols * 0.62) + 80
    sc.render.image_settings.file_format = "WEBP"
    sc.render.image_settings.quality = 88
    os.makedirs(os.path.dirname(SHEET), exist_ok=True)
    sc.render.filepath = SHEET
    bpy.ops.render.render(write_still=True)
    print("✓ contact sheet:", SHEET)


if __name__ == "__main__":
    main()
