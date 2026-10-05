"""Render ảnh 3D để duyệt greybox / environment (Cycles CPU — không cần GPU).

  python blender/scripts/render_views.py [--blend blender/master_map.blend] [--out docs/reference/greybox]
                                         [--samples 16] [--width 960] [--height 540]

Bộ góc chụp tuỳ stage của file .blend (scene["map_stage"]):
  greybox → docs/reference/greybox/: 00_overview, 01–08 nhìn xiên từng zone (như phím 1–8 của greybox_viewer),
            09_key_shot (sân H01), 10_mosquito (tầm muỗi cạnh chum W03)
  env     → docs/reference/env/: 00_overview, 01–08 "postcard" tầm mắt người mô phỏng 8 ảnh nhỏ của reference,
            09_key_shot (bờ ao cạnh cầu ao — hướng (a)), 10_mosquito
Ghép với ảnh reference: python blender/scripts/compare_reference.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common as C  # noqa: E402

ZONE_FOCUS = {"Z05": (85, 243), "Z08": (285, 260)}
NAMES = {"Z01": "01_house", "Z02": "02_garden", "Z03": "03_pond", "Z04": "04_rice", "Z05": "05_canal",
         "Z06": "06_bamboo", "Z07": "07_grass", "Z08": "08_road"}


# M2 "postcard": tầm mắt người (1.6 m), mô phỏng 8 ảnh nhỏ + ảnh chính của Reference A.
# (vị trí đứng, chiều cao, điểm nhìn, chiều cao điểm nhìn) — toạ độ Bible. Đây là quyết định NGHỆ THUẬT, không phải layout.
POSTCARDS = [
    ("01_house", (303.5, 85.5), 1.3, (304, 66), 1.2),
    ("02_garden", (182, 172), 1.6, (168, 150), 4.0),
    ("03_pond", (209.5, 343), 1.4, (175, 330), -0.2),
    ("04_rice", (328, 318), 1.6, (440, 300), 1.0),
    ("05_canal", (111, 92), 2.6, (101, 160), -0.6),        # đứng trên cầu R2 nhìn dọc kênh về Nam
    ("06_bamboo", (30, 215), 1.6, (0, 214), 2.5),          # trên lối mòn T1, trong rừng tre
    ("07_grass", (330, 428), 1.6, (430, 466), 0.5),
    ("08_road", (285, 150), 1.6, (285, 60), 1.5),
    # key shot — hướng (a) của M1_REVIEW §4: đứng bờ Đông ao cạnh cầu ao L08, nhìn về vườn / rừng tre
    ("09_key_shot", (219, 347), 1.7, (150, 318), 1.5),
]


def shots_env(spec):
    w03 = spec["egg_sites"]["W03_jar_chum"]["pos"]
    return ([("00_overview", (250, 640), 330, (250, 250), 0)] + POSTCARDS +
            [("10_mosquito", (w03[0] + 1.2, w03[1] + 1.5), 0.8, (w03[0] - 20, w03[1] + 40), 0.3)])


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
    a = C.parse_args({"blend": C.BLEND_PATH, "out": "", "samples": 16, "width": 960, "height": 540, "time": "",
                      "haze": True})
    bpy = C.bpy_mod()
    bpy.ops.wm.open_mainfile(filepath=os.path.abspath(a.blend))
    spec = C.load_spec()
    fr = C.Frame(spec)
    sc = bpy.context.scene
    stage = sc.get("map_stage", "greybox")
    out_dir = a.out or os.path.join(C.REPO, "docs", "reference", "greybox" if stage == "greybox" else "env")
    look = None
    if a.time:                                   # M3: ánh sáng theo docs/art_look.json
        import lighting
        look = lighting.load_look()
        hour = float(look["presets"].get(a.time, a.time))
        out_dir = a.out or os.path.join(C.REPO, "docs", "reference", "m3", a.time)
    shot_list = shots(spec) if stage == "greybox" else shots_env(spec)
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

    if look is not None:
        lighting.apply(sc, hour, look, haze=a.haze)
    # trời + nắng chiều phẳng (M1/M2 — giữ để ảnh duyệt cũ tái lập được)
    world = None if look is not None else bpy.data.worlds.new("Sky")
    if world is not None:
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
        if ob.type == "EMPTY" and ob.instance_type != "COLLECTION":
            ob.hide_render = True   # empty thuần (Point, Zone…) — giữ empty instance model thật
        if ob.get("rain_only"):
            ob.hide_render = True   # vũng nước chỉ có khi mưa; ảnh duyệt là trời nắng

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

    os.makedirs(out_dir, exist_ok=True)
    terrain = bpy.data.objects.get("Terrain")
    for name, (x, z), y, (tx, tz), ty in shot_list:
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
        sc.render.filepath = os.path.join(os.path.abspath(out_dir), name + ".webp")
        bpy.ops.render.render(write_still=True)
        if look is not None:
            lighting.grade_image(sc.render.filepath, look["grading"])
        print("✓", sc.render.filepath)


if __name__ == "__main__":
    main()
