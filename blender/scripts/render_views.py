"""Render ảnh 3D để duyệt greybox / environment (Cycles CPU — không cần GPU).

  python blender/scripts/render_views.py [--blend blender/master_map.blend] [--out docs/reference/greybox]
                                         [--samples 16] [--width 960] [--height 540]

Góc chụp (toạ độ Bible lấy từ docs/map_spec.json):
  00_overview      toàn cảnh xiên từ phía Nam
  01_house … 08_road   mỗi zone 1 góc như phím 1–8 của godot/world/greybox_viewer
  09_key_shot      tầm mắt người ở sân nhà H01, nhìn về ao / ruộng (khung hình chính của ảnh reference)
  10_mosquito      tầm muỗi (0.8 m) cạnh chum W03 — điểm spawn
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common as C  # noqa: E402

ZONE_FOCUS = {"Z05": (85, 243), "Z08": (285, 260)}
NAMES = {"Z01": "01_house", "Z02": "02_garden", "Z03": "03_pond", "Z04": "04_rice", "Z05": "05_canal",
         "Z06": "06_bamboo", "Z07": "07_grass", "Z08": "08_road"}


def shots(spec):
    out = [("00_overview", (250, 640), 330, (250, 250), 0)]
    for zid, name in NAMES.items():
        z = spec["zones"][zid]
        if zid in ZONE_FOCUS:
            cx, cz = ZONE_FOCUS[zid]
        else:
            r = z["rects"][0] if zid != "Z02" else z["rects"][1]
            cx, cz = (r[0] + r[2]) / 2, (r[1] + r[3]) / 2
        out.append((name, (cx, cz + 110), 90, (cx, cz), 0))
    w03 = spec["egg_sites"]["W03_jar_chum"]["pos"]
    out.append(("09_key_shot", (300, 96), 1.7, (215, 330), 1.2))
    out.append(("10_mosquito", (w03[0] + 1.2, w03[1] + 1.5), 0.8, (w03[0] - 20, w03[1] + 40), 0.3))
    return out


def main():
    a = C.parse_args({"blend": C.BLEND_PATH, "out": os.path.join(C.REPO, "docs", "reference", "greybox"),
                      "samples": 16, "width": 960, "height": 540})
    bpy = C.bpy_mod()
    bpy.ops.wm.open_mainfile(filepath=os.path.abspath(a.blend))
    spec = C.load_spec()
    fr = C.Frame(spec)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = a.samples
    try:
        sc.cycles.use_denoising = True
        sc.cycles.denoiser = "OPENIMAGEDENOISE"
    except Exception:
        pass
    sc.render.resolution_x, sc.render.resolution_y = a.width, a.height
    sc.render.image_settings.file_format = "WEBP"
    sc.render.image_settings.quality = 85
    sc.view_settings.view_transform = "AgX" if "AgX" in [i.name for i in type(sc.view_settings).bl_rna.properties["view_transform"].enum_items] else "Filmic"

    # trời + nắng chiều (ART_DIRECTION §2)
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.45, 0.62, 0.85, 1)
    bg.inputs["Strength"].default_value = 0.9
    sc.world = world
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 3.5
    sun.data.color = (1.0, 0.9, 0.75)
    sun.data.angle = math.radians(2)
    sun.rotation_euler = (math.radians(58), 0, math.radians(-120))
    sc.collection.objects.link(sun)

    for ob in bpy.data.objects:
        if ob.type == "EMPTY":
            ob.hide_render = True

    cam = bpy.data.objects.new("ReviewCam", bpy.data.cameras.new("ReviewCam"))
    cam.data.clip_end = 3000
    cam.data.lens = 28
    sc.collection.objects.link(cam)
    target = bpy.data.objects.new("ReviewTarget", None)
    sc.collection.objects.link(target)
    tr = cam.constraints.new("TRACK_TO")
    tr.target = target
    tr.track_axis = "TRACK_NEGATIVE_Z"
    tr.up_axis = "UP_Y"
    sc.camera = cam

    os.makedirs(a.out, exist_ok=True)
    terrain = bpy.data.objects.get("Terrain")
    for name, (x, z), y, (tx, tz), ty in shots(spec):
        if y < 5 and terrain is not None:
            # góc thấp: cộng cao độ mặt đất tại chỗ đứng (lấy từ đỉnh lưới gần nhất)
            res = float(terrain.get("res_m", 2.0))
            nx = int(round(fr.W / res)) + 1
            i, j = int(round(z / res)), int(round(x / res))
            g = terrain.data.vertices[i * nx + j].co.z
            gi, gj = int(round(tz / res)), int(round(tx / res))
            gt = terrain.data.vertices[gi * nx + gj].co.z
            y, ty = y + g, ty + gt
        cam.location = fr.bl(x, z, y)
        target.location = fr.bl(tx, tz, ty)
        cam.data.lens = 18 if y < 5 else 28
        sc.render.filepath = os.path.join(os.path.abspath(a.out), name + ".webp")
        bpy.ops.render.render(write_still=True)
        print("✓", sc.render.filepath)


if __name__ == "__main__":
    main()
