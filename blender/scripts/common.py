"""Tiện ích chung cho pipeline sinh map từ docs/MAP_BIBLE.md (qua map_spec.json).

Hệ toạ độ:
  Bible   : gốc Tây-Bắc, +x Đông, +z Nam, y lên (mét).
  Blender : gốc ở tâm map, +X Đông, +Y Bắc, +Z lên.
            bx = x - W/2,  by = -(z - D/2),  bz = y
  Godot   : (glTF đổi trục tự động) = (x - W/2, y, z - D/2)  — đúng như Bible §0.

Quy ước hướng asset: mặt trước của model nhìn về -Y Blender (= hướng Nam).
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
SPEC_PATH = os.path.join(REPO, "docs", "map_spec.json")
MANIFEST_PATH = os.path.join(REPO, "assets", "asset_manifest.json")
BLEND_PATH = os.path.join(REPO, "blender", "master_map.blend")
EXPORT_DIR = os.path.join(REPO, "blender", "exports")
GODOT_WORLD_DIR = os.path.join(REPO, "godot", "world", "generated")

FACING_ROT = {"south": 0.0, "east": math.pi / 2, "north": math.pi, "west": -math.pi / 2}


def load_spec(path=SPEC_PATH):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def parse_args(defaults):
    """Đọc tham số sau '--' (blender -b -P script.py -- --res 2) hoặc argv thường (python script.py --res 2)."""
    import argparse
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    p = argparse.ArgumentParser()
    for k, v in defaults.items():
        if isinstance(v, bool):
            p.add_argument("--" + k.replace("_", "-"), dest=k, action="store_true", default=v)
            p.add_argument("--no-" + k.replace("_", "-"), dest=k, action="store_false")
        else:
            p.add_argument("--" + k.replace("_", "-"), dest=k, type=type(v) if v is not None else str, default=v)
    return p.parse_known_args(argv)[0]


# ───────────────────────── chuyển toạ độ ─────────────────────────

class Frame:
    def __init__(self, spec):
        self.W = float(spec["map"]["width_x"])
        self.D = float(spec["map"]["depth_z"])

    def bl(self, x, z, y=0.0):
        return (x - self.W / 2, -(z - self.D / 2), y)

    def godot(self, x, z, y=0.0):
        return (x - self.W / 2, y, z - self.D / 2)


# ───────────────────────── hình học vector hoá ─────────────────────────

def dist_to_polyline(px, pz, pts):
    """Khoảng cách từ (px, pz) [mảng numpy cùng shape] tới polyline pts [[x, z], ...]."""
    px = np.asarray(px, dtype=np.float64)
    pz = np.asarray(pz, dtype=np.float64)
    best = np.full(px.shape, np.inf)
    for (ax, az), (bx, bz) in zip(pts[:-1], pts[1:]):
        dx, dz = bx - ax, bz - az
        l2 = dx * dx + dz * dz
        t = np.clip(((px - ax) * dx + (pz - az) * dz) / l2, 0.0, 1.0) if l2 > 0 else 0.0
        d = np.hypot(px - (ax + t * dx), pz - (az + t * dz))
        best = np.minimum(best, d)
    return best


def in_rects(px, pz, rects):
    m = np.zeros(np.shape(px), dtype=bool)
    for x0, z0, x1, z1 in rects:
        m |= (px >= x0) & (px <= x1) & (pz >= z0) & (pz <= z1)
    return m


def ellipse_r(px, pz, center, radii):
    """Bán kính chuẩn hoá của elip (1 = mép)."""
    return np.hypot((px - center[0]) / radii[0], (pz - center[1]) / radii[1])


def polyline_frames(pts, step):
    """Lấy mẫu polyline mỗi `step` mét → [(x, z, tx, tz)] với (tx, tz) là tiếp tuyến đơn vị."""
    out = []
    for (ax, az), (bx, bz) in zip(pts[:-1], pts[1:]):
        L = math.hypot(bx - ax, bz - az)
        if L == 0:
            continue
        tx, tz = (bx - ax) / L, (bz - az) / L
        n = max(1, int(math.ceil(L / step)))
        for i in range(n):
            t = i / n
            out.append((ax + tx * L * t, az + tz * L * t, tx, tz))
    (ax, az), (bx, bz) = pts[-2], pts[-1]
    L = math.hypot(bx - ax, bz - az) or 1.0
    out.append((bx, bz, (bx - ax) / L, (bz - az) / L))
    return out


def house_facing(spec, h):
    f = h.get("facing", "auto")
    if f != "auto":
        return f
    road_x = spec["roads"]["R1_main_spine"]["points"][0][0]
    return "east" if h["pos"][0] < road_x else "west"


# ───────────────────────── mặt nạ (mask) dùng chung ─────────────────────────

class Masks:
    """Các hàm kiểm tra vị trí theo luật Bible (nước, đường, nhà, zone)."""

    def __init__(self, spec):
        self.s = spec
        self.w = spec["water"]

    def zone_mask(self, px, pz, zid):
        return in_rects(px, pz, self.s["zones"][zid]["rects"])

    def zone_id(self, px, pz):
        """Mảng mã zone (chuỗi) theo zone_priority; 'filler' nếu không thuộc zone nào."""
        out = np.full(np.shape(px), "filler", dtype=object)
        taken = np.zeros(np.shape(px), dtype=bool)
        for zid in self.s["zone_priority"]:
            m = self.zone_mask(px, pz, zid) & ~taken
            out[m] = zid
            taken |= m
        return out

    def water(self, px, pz, margin=0.0):
        """True nếu điểm nằm trên mặt nước (kênh, ao, ruộng, vũng) — cộng thêm margin mét."""
        cm, cb, pd = self.w["canal_main"], self.w["canal_branch"], self.w["pond_main"]
        m = dist_to_polyline(px, pz, cm["centerline"]) < cm["w"] / 2 + margin
        m |= dist_to_polyline(px, pz, cb["centerline"]) < cb["w"] / 2 + margin
        m |= ellipse_r(px, pz, pd["center"], [r + margin for r in pd["radii"]]) < 1.0
        return m

    def puddle(self, px, pz, margin=0.0):
        m = np.zeros(np.shape(px), dtype=bool)
        for x, z, r in self.w["puddles_meadow"]["patches"]:
            m |= np.hypot(px - x, pz - z) < r + margin
        return m

    def paddy(self, px, pz, margin=0.0):
        x0, z0, x1, z1 = self.w["paddy_main"]["rect"]
        return in_rects(px, pz, [[x0 - margin, z0 - margin, x1 + margin, z1 + margin]])

    def road(self, px, pz, margin=0.0, include_trail=True):
        m = np.zeros(np.shape(px), dtype=bool)
        for rid, r in self.s["roads"].items():
            if not include_trail and r["type"] == "trail":
                continue
            m |= dist_to_polyline(px, pz, r["points"]) < r["w"] / 2 + margin
        return m

    def house(self, px, pz, margin=0.0):
        m = np.zeros(np.shape(px), dtype=bool)
        for h in self.s["houses"]["list"].values():
            (cx, cz), (sw, sd) = h["pos"], h["size"]
            r = max(sw, sd) / 2 + margin
            m |= (np.abs(px - cx) < r) & (np.abs(pz - cz) < r)
        return m

    def landmark(self, px, pz, radius=4.0):
        m = np.zeros(np.shape(px), dtype=bool)
        for L in self.s["landmarks"].values():
            if L["kind"] in ("marker", "house_ref", "bridge_ref", "jar_ref", "chicken"):
                continue
            m |= np.hypot(px - L["pos"][0], pz - L["pos"][1]) < radius
        return m


# ───────────────────────── kiểm tra Bible ─────────────────────────

def validate_spec(spec):
    """Kiểm tra các luật trong MAP_BIBLE §7/§14. Trả về danh sách cảnh báo (rỗng = OK)."""
    warns = []
    M = Masks(spec)
    H = spec["houses"]
    z01 = spec["zones"]["Z01"]["rects"][0]
    items = list(H["list"].items())
    for hid, h in items:
        x, z = h["pos"]
        if not (z01[0] <= x <= z01[2] and z01[1] <= z <= z01[3]):
            warns.append(f"{hid} nằm ngoài Z01")
        hw = max(h["size"]) / 2
        if M.water(np.array([x]), np.array([z]), margin=H["min_water_clearance"] + hw)[0]:
            warns.append(f"{hid} cách mặt nước < {H['min_water_clearance']} m")
        if M.road(np.array([x]), np.array([z]), margin=hw, include_trail=False)[0]:
            warns.append(f"{hid} đè lên đường")
    for i, (a, ha) in enumerate(items):
        for b, hb in items[i + 1:]:
            d = math.dist(ha["pos"], hb["pos"])
            if d < H["min_spacing"]:
                warns.append(f"{a}–{b} cách nhau {d:.1f} m < {H['min_spacing']} m")
    for wid, w in spec["egg_sites"].items():
        z = spec["zones"].get(w["zone"], {})
        if z.get("rects") and not in_rects(np.array([w["pos"][0]]), np.array([w["pos"][1]]), z["rects"])[0]:
            warns.append(f"{wid} không nằm trong {w['zone']}")
    for lid, L in spec["landmarks"].items():
        z = spec["zones"].get(L["zone"], {})
        if z.get("rects") and not in_rects(np.array([L["pos"][0]]), np.array([L["pos"][1]]), z["rects"])[0]:
            warns.append(f"Landmark {lid} không nằm trong {L['zone']}")
    return warns


# ───────────────────────── tiện ích Blender ─────────────────────────

def bpy_mod():
    import bpy  # noqa: import trễ để các hàm numpy dùng được ngoài Blender
    return bpy


def reset_scene():
    bpy = bpy_mod()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.unit_settings.system = "METRIC"
    sc.unit_settings.scale_length = 1.0
    return sc


def collection(name, parent=None):
    bpy = bpy_mod()
    col = bpy.data.collections.get(name)
    if col is None:
        col = bpy.data.collections.new(name)
        (parent or bpy.context.scene.collection).children.link(col)
    return col


def link(obj, col):
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    col.objects.link(obj)
    return obj


def material(name, color, roughness=0.8, alpha=1.0, use_vcol=None):
    bpy = bpy_mod()
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
        try:
            m.surface_render_method = "BLENDED"
        except AttributeError:
            m.blend_method = "BLEND"
    if use_vcol:
        attr = m.node_tree.nodes.new("ShaderNodeVertexColor")
        attr.layer_name = use_vcol
        m.node_tree.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
    m.diffuse_color = (*color, alpha)
    return m


def mesh_object(name, verts, faces, col, mat=None):
    bpy = bpy_mod()
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], [tuple(f) for f in faces])
    me.validate()
    me.update()
    ob = bpy.data.objects.new(name, me)
    col.objects.link(ob)
    if mat:
        me.materials.append(mat)
    return ob


def empty(name, loc, col, rot_z=0.0, display="PLAIN_AXES", size=1.0, props=None, scale=None):
    bpy = bpy_mod()
    ob = bpy.data.objects.new(name, None)
    ob.empty_display_type = display
    ob.empty_display_size = size
    ob.location = loc
    ob.rotation_euler = (0.0, 0.0, rot_z)
    if scale:
        ob.scale = scale
    for k, v in (props or {}).items():
        ob[k] = v
    col.objects.link(ob)
    return ob


def box(name, size, loc, col, mat=None, rot_z=0.0, base_origin=True):
    """Hộp (sx, sy, sz). base_origin=True: gốc ở đáy (đúng quy ước asset)."""
    sx, sy, sz = (s / 2 for s in size)
    z0, z1 = (0.0, size[2]) if base_origin else (-sz, sz)
    v = [(-sx, -sy, z0), (sx, -sy, z0), (sx, sy, z0), (-sx, sy, z0),
         (-sx, -sy, z1), (sx, -sy, z1), (sx, sy, z1), (-sx, sy, z1)]
    f = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    ob = mesh_object(name, v, f, col, mat)
    ob.location = loc
    ob.rotation_euler = (0.0, 0.0, rot_z)
    return ob


def cylinder(name, r, h, loc, col, mat=None, seg=12, r_top=None):
    r_top = r if r_top is None else r_top
    v, f = [], []
    for i in range(seg):
        a = 2 * math.pi * i / seg
        v.append((r * math.cos(a), r * math.sin(a), 0.0))
        v.append((r_top * math.cos(a), r_top * math.sin(a), h))
    for i in range(seg):
        j = (i + 1) % seg
        f.append((2 * i, 2 * j, 2 * j + 1, 2 * i + 1))
    f.append(tuple(2 * i for i in reversed(range(seg))))
    if r_top > 0:
        f.append(tuple(2 * i + 1 for i in range(seg)))
    ob = mesh_object(name, v, f, col, mat)
    ob.location = loc
    return ob


def ribbon(name, pts, width, y_fn, frame, col, mat=None, step=2.0, y_off=0.02):
    """Dải mesh dọc polyline (đường, kênh). y_fn(x, z) → cao độ Bible."""
    fr = polyline_frames(pts, step)
    v, f = [], []
    for i, (x, z, tx, tz) in enumerate(fr):
        nx, nz = -tz, tx
        for s in (-1, 1):
            px, pz = x + nx * width / 2 * s, z + nz * width / 2 * s
            v.append(frame.bl(px, pz, y_fn(px, pz) + y_off))
        if i:
            a = 2 * (i - 1)
            f.append((a, a + 1, a + 3, a + 2))  # pháp tuyến hướng lên (+Z)
    return mesh_object(name, v, f, col, mat)


def disc(name, center, radii, y, frame, col, mat=None, seg=48):
    cx, cz = center
    v = [frame.bl(cx, cz, y)]
    for i in range(seg):
        a = 2 * math.pi * i / seg
        v.append(frame.bl(cx + radii[0] * math.cos(a), cz + radii[1] * math.sin(a), y))
    f = [(0, 1 + (i + 1) % seg, 1 + i) for i in range(seg)]
    return mesh_object(name, v, f, col, mat)
