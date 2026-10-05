"""Entry point: sinh map làng quê Việt Nam từ docs/MAP_BIBLE.md (docs/map_spec.json).

Chạy (theo milestone, xem docs/ROADMAP.md):
  M1 greybox : blender -b -P blender/scripts/generate_map.py -- --stage greybox --godot
  M2 env     : blender -b -P blender/scripts/generate_map.py -- --stage env --swap --godot
  (hoặc với module bpy của pip:  python blender/scripts/generate_map.py --stage greybox --godot)

Stage:
  greybox  Terrain, Water (Canal, Pond, Rice Field, vũng), Road, 8 Zone, House placeholders, Fence,
           Point/Landmark placeholders, Spawn, Camera bounds. KHÔNG cây cỏ, KHÔNG thay asset.
  env      greybox + thực vật procedural (Forest, Grassland, lúa…) + có thể --swap model thật.

Tạo ra:
  blender/master_map.blend                  — scene đầy đủ (file sinh ra, KHÔNG sửa tay)
  blender/exports/<map>_<stage>.glb         — GLB cho Godot (pipeline chính: Blender → GLB → Godot)
  blender/exports/map_layout.json           — mọi *Point / EggSite / Zone / Spawn (toạ độ Godot + props)
  blender/exports/map_points.json           — point cloud thực vật cho MultiMesh (chỉ stage env)
  --godot: copy các file trên sang godot/world/generated/
"""
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np  # noqa: E402

import common as C  # noqa: E402
import generate_foliage  # noqa: E402
import generate_terrain  # noqa: E402
import generate_village  # noqa: E402
import generate_water  # noqa: E402

GLB_SKIP_COLLECTIONS = {"Clouds", "ASSET_LIBRARY"}


def _in_skipped(ob):
    return any(c.name in GLB_SKIP_COLLECTIONS or c.name.startswith("ASSET_") or c.name.startswith("LIB_")
               for c in ob.users_collection)


def export_points(spec, ctx, path):
    fr = ctx["frame"]
    out = {"_format": "mỗi loại: stride 6 = [x, y, z, rot_y, scale, variant], toạ độ Godot (m). "
                      "assets[variant % len]: world = T(pos)·R_y(rot)·S(scale)·T(offset)·S(asset_scale)",
           "map": spec["map"]["name"], "types": {}}
    for t, c in ctx.get("clouds", {}).items():
        gx, gz = c["x"] - fr.W / 2, c["z"] - fr.D / 2
        # rot quanh Z Blender (ngược chiều kim đồng hồ nhìn từ trên) = rot quanh Y Godot
        arr = np.stack([gx, c["y"], gz, c["rot"], c["scale"], c["variant"]], -1)
        out["types"][t] = {"count": int(len(arr)), "stride": 6, "assets": cloud_assets(t),
                           "data": [round(float(v), 3) for v in arr.ravel()]}
    with open(path, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))


def cloud_assets(t):
    """Asset thật đã swap vào ASSET_<t> (rỗng nếu còn proxy) — để Godot dựng MultiMesh giống Blender."""
    bpy = C.bpy_mod()
    col = bpy.data.collections.get("ASSET_" + t)
    out = []
    for o in sorted(col.objects if col else [], key=lambda o: o.name):
        src = o.get("source_file")
        if not src:
            continue
        x, y, z = o.location
        out.append({"file": os.path.basename(src), "source": src, "scale": round(o.scale.x, 5),
                    "offset": [round(x, 4), round(z, 4), round(-y, 4)]})
    return out


def export_layout(spec, path):
    bpy = C.bpy_mod()
    items = {}
    for ob in bpy.data.objects:
        if ob.type != "EMPTY" or ob.parent is not None:
            continue
        x, y, z = ob.matrix_world.translation
        props = {k: (list(v) if hasattr(v, "__len__") and not isinstance(v, str) else v)
                 for k, v in ob.items() if not k.startswith("_")}
        items[ob.name] = {"pos": [round(x, 3), round(z, 3), round(-y, 3)],
                          "rot_y": round(ob.rotation_euler.z, 4),
                          "scale": [round(s, 3) for s in (ob.scale.x, ob.scale.z, ob.scale.y)],
                          "props": props}
    with open(path, "w", encoding="utf-8") as f:
        json.dump({"map": spec["map"]["name"], "coord": "godot", "nodes": items}, f, ensure_ascii=False, indent=1)


def export_glb(path):
    bpy = C.bpy_mod()
    bpy.ops.object.select_all(action="DESELECT")
    for ob in bpy.context.view_layer.objects:
        if not _in_skipped(ob) and not ob.hide_render:
            ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_extras=True,
                              export_apply=False, export_yup=True)


def main():
    a = C.parse_args({"stage": "greybox", "res": 2.0, "out": C.EXPORT_DIR, "blend": C.BLEND_PATH,
                      "glb": True, "swap": False, "strict": False, "godot": False})
    if a.stage not in ("greybox", "env"):
        sys.exit("--stage phải là greybox hoặc env")
    if a.swap and a.stage != "env":
        sys.exit("--swap chỉ dùng ở stage env (M2). Greybox phải được xác nhận trước khi thay asset.")
    t0 = time.time()
    spec = C.load_spec()
    warns = C.validate_spec(spec)
    for w in warns:
        print("⚠ BIBLE:", w)
    if warns and a.strict:
        sys.exit("Spec vi phạm MAP_BIBLE — dừng (--strict).")

    C.reset_scene()
    ctx = {"frame": C.Frame(spec), "res": a.res, "root": C.collection("MAP"), "stage": a.stage}
    print("→ Terrain");  generate_terrain.build(spec, ctx)
    print("→ Water");    generate_water.build(spec, ctx)
    print("→ Village");  generate_village.build(spec, ctx)
    if a.stage == "env":
        print("→ Foliage");  generate_foliage.build(spec, ctx)

    if a.swap:
        import swap_assets
        print("→ Swap assets")
        swap_assets.run(swap_assets.load_manifest())

    out = os.path.abspath(a.out)
    os.makedirs(out, exist_ok=True)
    name = f"{spec['map']['name']}_{a.stage}"
    bpy = C.bpy_mod()
    bpy.context.scene["map_stage"] = a.stage
    if a.blend:
        os.makedirs(os.path.dirname(os.path.abspath(a.blend)), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(a.blend))
    files = [os.path.join(out, "map_layout.json")]
    export_layout(spec, files[0])
    if a.stage == "env":
        files.append(os.path.join(out, "map_points.json"))
        export_points(spec, ctx, files[-1])
    if a.glb:
        files.append(os.path.join(out, name + ".glb"))
        export_glb(files[-1])
    if a.godot:
        import shutil
        os.makedirs(C.GODOT_WORLD_DIR, exist_ok=True)
        for f in files:
            shutil.copy2(f, C.GODOT_WORLD_DIR)
        # M3: thông số ánh sáng dùng chung (day_night.gd đọc res://world/generated/art_look.json)
        shutil.copy2(os.path.join(C.REPO, "docs", "art_look.json"), C.GODOT_WORLD_DIR)
        # asset thực vật cho MultiMesh (Godot không đọc được assets/ ngoài project)
        fol = os.path.join(C.GODOT_WORLD_DIR, "foliage")
        shutil.rmtree(fol, ignore_errors=True)   # bỏ asset cũ không còn dùng
        os.makedirs(fol, exist_ok=True)
        for t in ctx.get("clouds", {}):
            for asset in cloud_assets(t):
                shutil.copy2(os.path.join(C.REPO, asset["source"]), fol)
        print("→ Godot:", C.GODOT_WORLD_DIR)
    print(f"✓ Xong ({a.stage}) trong {time.time() - t0:.1f}s → {out}")


if __name__ == "__main__":
    main()
