"""Thay placeholder bằng model thật theo asset_manifest.json.

  HousePoint_01 → house_vn_01.glb      (chưa có → fallback house2.glb, vẫn chưa có → giữ placeholder)
  JarPoint_*    → water_jar_vn.glb
  BambooPoints  → ASSET_BambooPoint ← bamboo_clump_01.glb, bamboo_clump_02.glb …

Chạy trên file .blend đã sinh:
  blender -b tools/blender/out/vietnamese_rural_village.blend -P tools/blender/swap_assets.py -- [--save] [--glb]
Hoặc: generate_map.py --swap

Chạy lại bao nhiêu lần cũng được (idempotent): asset cũ bị gỡ, placeholder được khôi phục rồi swap lại.
"""
import fnmatch
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common as C  # noqa: E402

MANIFEST_PATH = os.path.join(C.HERE, "asset_manifest.json")
ASSET_SUFFIX = "__ASSET"


def load_manifest(path=MANIFEST_PATH):
    with open(path, encoding="utf-8") as f:
        m = json.load(f)
    base = os.path.dirname(os.path.abspath(path))
    m["_dirs"] = [os.path.normpath(os.path.join(base, d)) for d in m["asset_dirs"]]
    return m


def _as_list(v):
    return [] if v is None else (v if isinstance(v, list) else [v])


def _is_lfs_pointer(path):
    with open(path, "rb") as f:
        return f.read(24).startswith(b"version https://git-lfs")


def resolve(manifest, rule):
    """Danh sách đường dẫn .glb dùng được cho một luật (biến thể đã qua fallback)."""
    def find(name):
        for d in manifest["_dirs"]:
            p = os.path.join(d, name)
            if os.path.isfile(p):
                if _is_lfs_pointer(p):
                    print(f"  ⚠ {p} là con trỏ Git LFS chưa tải — chạy: git lfs pull")
                    continue
                return p
        return None
    out = []
    fallbacks = _as_list(rule.get("fallback"))
    for i, name in enumerate(_as_list(rule.get("asset"))):
        p = find(name)
        if p is None and fallbacks:
            p = find(fallbacks[i % len(fallbacks)])
        if p:
            out.append(p)
    if not out:
        out = [p for p in (find(n) for n in fallbacks) if p]
    return list(dict.fromkeys(out))  # bỏ trùng khi nhiều biến thể cùng rơi về một fallback


# ───────────────────────── thư viện asset (import mỗi file 1 lần) ─────────────────────────

_LIB = {}


def lib_collection(path):
    """Import .glb vào collection ẩn LIB_<tên>; trả về (collection, bbox_min, bbox_max)."""
    bpy = C.bpy_mod()
    from mathutils import Vector
    if path in _LIB:
        return _LIB[path]
    name = "LIB_" + os.path.splitext(os.path.basename(path))[0]
    lib_root = C.collection("ASSET_LIBRARY", C.collection("MAP"))
    col = bpy.data.collections.get(name)
    if col is None:
        col = bpy.data.collections.new(name)
        lib_root.children.link(col)
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=path)
        for ob in set(bpy.data.objects) - before:
            for c in list(ob.users_collection):
                c.objects.unlink(ob)
            col.objects.link(ob)
    lib_root.hide_render = True
    lib_root.hide_viewport = True
    bpy.context.view_layer.update()
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for ob in col.all_objects:
        if ob.type != "MESH":
            continue
        for c in ob.bound_box:
            w = ob.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    if lo.x > hi.x:
        lo, hi = Vector((0, 0, 0)), Vector((1, 1, 1))
    _LIB[path] = (col, lo, hi)
    return _LIB[path]


def _bbox_local(ob):
    """Kích thước (x, y, z) của placeholder (kể cả con) trong hệ cục bộ của point cha."""
    from mathutils import Vector
    pts = []
    stack = [ob]
    while stack:
        o = stack.pop()
        stack.extend(o.children)
        if o.type == "MESH":
            M = ob.parent.matrix_world.inverted() @ o.matrix_world
            pts += [M @ Vector(c) for c in o.bound_box]
    if not pts:
        return None
    return Vector(max(p[i] for p in pts) - min(p[i] for p in pts) for i in range(3))


def fit_scale(fit, lo, hi, point, ph):
    size = hi - lo
    if not fit:
        return 1.0
    if fit.startswith("height:"):
        return float(fit.split(":")[1]) / max(size.z, 1e-6)
    target = _bbox_local(ph) if ph else None
    if fit == "footprint":
        fp = point.get("footprint")
        if fp is not None:
            tx, ty = float(fp[0]), float(fp[1])
        elif target is not None:
            tx, ty = target.x, target.y
        else:
            return 1.0
        return min(tx / max(size.x, 1e-6), ty / max(size.y, 1e-6))
    if fit == "length" and target is not None:
        return target.x / max(size.x, 1e-6)
    return 1.0


def _instance(name, col, lib, lo, hi, scale, parent=None):
    bpy = C.bpy_mod()
    inst = bpy.data.objects.new(name, None)
    inst.instance_type = "COLLECTION"
    inst.instance_collection = lib
    # đặt đáy-tâm của asset vào gốc point
    inst.location = (-(lo.x + hi.x) / 2 * scale, -(lo.y + hi.y) / 2 * scale, -lo.z * scale)
    inst.scale = (scale,) * 3
    col.objects.link(inst)
    if parent is not None:
        inst.parent = parent
    inst["swapped_asset"] = lib.name
    return inst


def _placeholder(point):
    return next((c for c in point.children if c.name.endswith("__PH")), None)


def _set_ph_visible(ph, visible):
    stack = [ph] if ph else []
    while stack:
        o = stack.pop()
        stack.extend(o.children)
        o.hide_render = not visible
        o.hide_viewport = not visible


def swap_points(manifest):
    bpy = C.bpy_mod()
    stats = {"swapped": 0, "placeholder": 0}
    points = [o for o in bpy.data.objects if o.type == "EMPTY" and o.get("point_type") and "Point_" in o.name]
    ordinal = {}
    for p in sorted(points, key=lambda o: o.name):
        for c in list(p.children):
            if c.name.endswith(ASSET_SUFFIX):
                bpy.data.objects.remove(c)
        ph = _placeholder(p)
        rule = next((r for r in manifest["points"] if fnmatch.fnmatchcase(p.name, r["match"])), None)
        paths = resolve(manifest, rule) if rule else []
        if not paths:
            _set_ph_visible(ph, True)
            stats["placeholder"] += 1
            continue
        k = p.get("variant")
        if k is None:
            k = ordinal.get(rule["match"], 0)
            ordinal[rule["match"]] = k + 1
        lib, lo, hi = lib_collection(paths[int(k) % len(paths)])
        s = fit_scale(rule.get("fit"), lo, hi, p, ph)
        _instance(p.name + ASSET_SUFFIX, p.users_collection[0], lib, lo, hi, s, parent=p)
        _set_ph_visible(ph, False)
        stats["swapped"] += 1
    return stats


def swap_clouds(manifest):
    bpy = C.bpy_mod()
    stats = {}
    for t, rule in manifest.get("clouds", {}).items():
        acol = bpy.data.collections.get("ASSET_" + t)
        if acol is None:
            continue
        for o in list(acol.objects):
            if o.name.endswith(ASSET_SUFFIX):
                bpy.data.objects.remove(o)
        proxies = [o for o in acol.objects if o.get("placeholder")]
        paths = resolve(manifest, rule)
        if not paths:
            stash = bpy.data.collections.get("ASSET_PROXY_STASH")
            for o in list(stash.objects) if stash else []:
                if o.name.startswith("PX_" + t):  # khôi phục proxy từ lần swap trước
                    stash.objects.unlink(o)
                    acol.objects.link(o)
            stats[t] = "placeholder"
            continue
        stash = C.collection("ASSET_PROXY_STASH", bpy.data.collections["ASSET_LIBRARY"])
        for o in proxies:  # proxy ra khỏi collection để Collection Info chỉ thấy asset thật
            acol.objects.unlink(o)
            if o.name not in stash.objects:
                stash.objects.link(o)
        for i, path in enumerate(paths):
            lib, lo, hi = lib_collection(path)
            s = fit_scale(rule.get("fit"), lo, hi, {}, None)
            _instance(f"{t}_v{i:02d}{ASSET_SUFFIX}", acol, lib, lo, hi, s)
        stats[t] = [os.path.basename(p) for p in paths]
    return stats


def run(manifest):
    s1 = swap_points(manifest)
    s2 = swap_clouds(manifest)
    print(f"  points: {s1['swapped']} đã thay, {s1['placeholder']} giữ placeholder")
    for t, v in s2.items():
        print(f"  {t:15s} → {v}")
    return s1, s2


if __name__ == "__main__":
    a = C.parse_args({"save": False, "glb": False})
    run(load_manifest())
    bpy = C.bpy_mod()
    if a.save:
        bpy.ops.wm.save_mainfile()
    if a.glb:
        import generate_map
        generate_map.export_glb(os.path.splitext(bpy.data.filepath)[0] + ".glb")
