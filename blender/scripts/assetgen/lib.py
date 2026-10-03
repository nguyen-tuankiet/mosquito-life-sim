"""Thư viện dựng asset procedural (v1) cho map — chạy trong Blender / bpy.

Quy chuẩn (docs/ASSET_GUIDELINES.md §4): mét, gốc ở đáy-giữa, mặt trước nhìn −Y, rào/cầu dài theo X.
Texture sinh bằng numpy (tileable), đóng gói trong .glb → không cần file ngoài, Godot đọc được trực tiếp.
"""
import math

import numpy as np

import bpy
from mathutils import Matrix, Vector

TEX_CACHE = {}
MAT_CACHE = {}


# ───────────────────────── texture procedural ─────────────────────────

def fbm(n, beta=2.0, seed=0, aniso=(1.0, 1.0)):
    """Nhiễu tileable 1/f^beta, chuẩn hoá về [0, 1]. aniso kéo giãn theo trục (vân gỗ, rơm)."""
    rng = np.random.default_rng(seed)
    fy = np.fft.fftfreq(n)[:, None] * aniso[1]
    fx = np.fft.rfftfreq(n)[None, :] * aniso[0]
    f = np.sqrt(fx * fx + fy * fy)
    f[0, 0] = 1.0
    spec = (rng.normal(size=f.shape) + 1j * rng.normal(size=f.shape)) / f ** (beta / 2)
    spec[0, 0] = 0
    a = np.fft.irfft2(spec, s=(n, n))
    a -= a.min()
    return a / (a.max() + 1e-9)


def ramp(t, c0, c1):
    t = np.clip(t, 0, 1)[..., None]
    return np.array(c0, np.float32) * (1 - t) + np.array(c1, np.float32) * t


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def image(name, rgba):
    """numpy (H, W, 3|4) [0,1] → bpy image đóng gói (gốc ảnh ở dưới-trái như Blender)."""
    if name in TEX_CACHE:
        return TEX_CACHE[name]
    h, w = rgba.shape[:2]
    if rgba.shape[2] == 3:
        rgba = np.concatenate([rgba, np.ones((h, w, 1), np.float32)], -1)
    img = bpy.data.images.new(name, w, h, alpha=True)
    img.pixels.foreach_set(np.ascontiguousarray(np.flipud(rgba), dtype=np.float32).ravel())
    img.pack()
    img.alpha_mode = "STRAIGHT"
    TEX_CACHE[name] = img
    return img


def tex_plaster(seed=1, c0="#C9B998", c1="#E2D6BE"):
    n = 512
    base = fbm(n, 2.2, seed)
    stain = fbm(n, 3.0, seed + 1, (1.0, 0.35))
    c = ramp(base * 0.6 + 0.2, hexc(c0), hexc(c1))
    dirt = np.clip((stain - 0.55) * 3, 0, 1)
    c = c * (1 - 0.35 * dirt[..., None]) + np.array(hexc("#8C8A70")) * 0.35 * dirt[..., None]
    rows = np.linspace(0, 1, n)[:, None]
    c *= (0.85 + 0.15 * np.clip(rows * 3, 0, 1))[..., None]          # chân tường ố
    return image(f"tex_plaster_{seed}_{c0}", c)


def tex_glaze(seed=9):
    """Men sành nâu của lu/chum: vệt chảy dọc."""
    n = 256
    g = fbm(n, 2.2, seed, (4.0, 0.3))
    return image(f"tex_glaze_{seed}", ramp(g, hexc("#3A2418"), hexc("#7A5034")))


def tex_wood(seed=2, tint="#6B4A30"):
    n = 512
    g = fbm(n, 2.5, seed, (6.0, 0.25))
    k = fbm(n, 2.0, seed + 5)
    c = ramp(g * 0.7 + k * 0.3, np.array(hexc(tint)) * 0.65, np.array(hexc(tint)) * 1.25)
    return image(f"tex_wood_{seed}_{tint}", c)


def tex_roof(seed=3):
    """Ngói vảy cá đỏ-nâu, có rêu. U ngang mái, V dọc dốc mái."""
    n = 512
    u, v = np.meshgrid(np.linspace(0, 1, n, endpoint=False), np.linspace(0, 1, n, endpoint=False))
    rows, cols = 8, 8
    rv = (v * rows) % 1.0
    off = (np.floor(v * rows) % 2) * 0.5
    cu = ((u * cols + off) % 1.0) - 0.5
    scallop = rv - (1 - 4 * cu ** 2) * 0.35
    shade = np.clip(scallop * 1.4, 0, 1)
    tile_id = np.floor(u * cols + off) + 97 * np.floor(v * rows)
    var = (np.sin(tile_id * 12.9898) * 43758.5453) % 1.0
    base = ramp(var * 0.6 + 0.2, hexc("#8E4326"), hexc("#B8643A"))
    c = base * (0.55 + 0.45 * shade[..., None])
    moss = np.clip((fbm(n, 2.4, seed) - 0.62) * 4, 0, 1)
    c = c * (1 - 0.6 * moss[..., None]) + np.array(hexc("#5E6B3E")) * 0.6 * moss[..., None]
    return image(f"tex_roof_{seed}", c)


def tex_straw(seed=4):
    n = 512
    g = fbm(n, 2.0, seed, (8.0, 0.15))
    c = ramp(g, hexc("#8C7034"), hexc("#D8BF72"))
    return image(f"tex_straw_{seed}", c)


def tex_concrete(seed=5):
    n = 256
    g = fbm(n, 2.6, seed)
    return image(f"tex_concrete_{seed}", ramp(g, hexc("#8A8780"), hexc("#B7B2A6")))


def tex_bark(seed=6, c0="#3E3024", c1="#7A6650"):
    n = 512
    g = fbm(n, 2.4, seed, (0.25, 5.0))
    return image(f"tex_bark_{seed}", ramp(g, hexc(c0), hexc(c1)))


def tex_bamboo_culm(seed=7):
    n = 256
    g = fbm(n, 2.0, seed, (0.3, 6.0))
    c = ramp(g, hexc("#5D7A2E"), hexc("#8FA84A"))
    v = np.linspace(0, 1, n)[:, None]
    node = np.exp(-((v % 0.25) - 0.0) ** 2 / 0.0004) + np.exp(-((v % 0.25) - 0.25) ** 2 / 0.0004)
    c = c * (1 - 0.45 * node[..., None]) + np.array(hexc("#C9C08A")) * 0.45 * node[..., None]
    return image(f"tex_bamboo_{seed}", np.broadcast_to(c, (n, n, 3)).copy())


def tex_leaf_cluster(seed, dark, light, kind="broad", count=26):
    """Một chùm nhiều lá trên 1 texture có alpha — dùng cho tán cây/bụi (ít mặt, nhìn dày)."""
    n = 256
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:n, 0:n] / n
    alpha = np.zeros((n, n), bool)
    col = np.zeros((n, n), np.float32)
    for i in range(count):
        cx, cy = rng.uniform(0.15, 0.85, 2)
        ang = rng.uniform(0, np.pi)
        ln = rng.uniform(0.18, 0.3) if kind == "broad" else rng.uniform(0.25, 0.4)
        wd = ln * (0.45 if kind == "broad" else 0.16)
        dx, dy = xx - cx, yy - cy
        u = dx * np.cos(ang) + dy * np.sin(ang)
        v = -dx * np.sin(ang) + dy * np.cos(ang)
        t = u / ln + 0.5
        inside = (t > 0) & (t < 1) & (np.abs(v) < wd * np.sin(np.pi * np.clip(t, 0, 1)) ** 0.8)
        alpha |= inside
        col[inside] = rng.uniform(0.2, 1.0)
    g = fbm(n, 2.0, seed)
    c = ramp(col * 0.7 + g * 0.3, hexc(dark), hexc(light))
    return image(f"tex_cluster_{seed}_{kind}", np.concatenate([c, alpha.astype(np.float32)[..., None]], -1))


def tex_leaf(kind, seed=8, dark=None, light=None):
    """Ảnh lá có alpha. kind: broad | lance (tre) | banana | frond (dừa) | blade (cỏ/lúa) | reed | lily."""
    od, ol = dark, light
    n = 256
    u, v = np.meshgrid(np.linspace(-1, 1, n), np.linspace(0, 1, n))   # v: gốc (0) → ngọn (1)
    rng = np.random.default_rng(seed)
    if kind == "broad":
        w = np.sin(np.pi * np.clip(v, 0, 1)) ** 0.8 * 0.9
        a = np.abs(u) < w
        dark, light = "#2F5A22", "#6E9A3A"
    elif kind == "lance":
        w = np.sin(np.pi * np.clip(v, 0, 1) ** 0.7) ** 1.2 * 0.55
        a = np.abs(u) < w
        dark, light = "#3E6B26", "#86AE48"
    elif kind == "banana":
        w = np.clip(np.sin(np.pi * v) ** 0.35, 0, 1) * 0.95
        tear = (np.sin(v * 70 + rng.uniform(0, 6)) > 0.75) & (np.abs(u) > 0.25)
        a = (np.abs(u) < w) & ~tear
        dark, light = "#4E7A2A", "#9CC155"
    elif kind == "frond":
        # cuống giữa + lá chét xiên
        side = np.abs(u)
        leaflet = ((v * 18 - side * 3.0) % 1.0) < 0.62
        w = 0.95 * np.sin(np.pi * np.clip(v, 0, 1)) ** 0.6
        a = ((side < w) & leaflet) | (side < 0.04)
        dark, light = "#3F6A26", "#8DB34E"
    elif kind == "blade":
        w = (1 - v) ** 0.9 * 0.85
        a = np.abs(u) < w
        dark, light = "#5E8E2E", "#A8CC5C"
    elif kind == "reed":
        w = (1 - v) ** 0.6 * 0.6
        a = np.abs(u) < w
        dark, light = "#6C7E38", "#B4B66A"
    elif kind == "lily":
        r = np.hypot(u, (v - 0.5) * 2)
        ang = np.arctan2((v - 0.5) * 2, u)
        a = (r < 0.95) & ~((np.abs(ang - np.pi / 2) < 0.18) & (r > 0.05))
        dark, light = "#2E5E2A", "#5E9442"
    else:
        raise ValueError(kind)
    dark, light = od or dark, ol or light       # màu truyền vào ghi đè màu mặc định của loại lá
    g = fbm(n, 2.0, seed)
    vein = np.exp(-(u / 0.035) ** 2)
    c = ramp(g * 0.5 + v * 0.3 + 0.1, hexc(dark), hexc(light))
    c = c * (1 - 0.25 * vein[..., None]) + np.array(hexc("#C8D890")) * 0.25 * vein[..., None]
    alpha = a.astype(np.float32)[..., None]
    return image(f"tex_leaf_{kind}_{seed}_{dark}", np.concatenate([c, alpha], -1))


# ───────────────────────── material ─────────────────────────

def mat(name, tex=None, color=(0.8, 0.8, 0.8), rough=0.85, clip=False, double=False, metal=0.0):
    if name in MAT_CACHE:
        return MAT_CACHE[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    b.inputs["Base Color"].default_value = (*color, 1)
    if tex is not None:
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = tex
        nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
        if clip:
            g = nt.nodes.new("ShaderNodeMath")
            g.operation = "GREATER_THAN"
            g.inputs[1].default_value = 0.5
            nt.links.new(t.outputs["Alpha"], g.inputs[0])
            nt.links.new(g.outputs[0], b.inputs["Alpha"])
    m.use_backface_culling = not double
    m.diffuse_color = (*color, 1)
    MAT_CACHE[name] = m
    return m


# ───────────────────────── mesh builder ─────────────────────────

class MB:
    """Gom đỉnh/mặt/UV/material rồi tạo 1 object duy nhất (nhiều surface)."""

    def __init__(self, name):
        self.name = name
        self.v, self.f, self.uv, self.mi = [], [], [], []
        self.mats = []

    def _mat(self, m):
        if m not in self.mats:
            self.mats.append(m)
        return self.mats.index(m)

    def face(self, verts, uvs, m):
        base = len(self.v)
        self.v += [tuple(p) for p in verts]
        self.f.append(tuple(range(base, base + len(verts))))
        self.uv.append([tuple(t) for t in uvs])
        self.mi.append(self._mat(m))

    def face_auto(self, verts, m, scale=1.0):
        """UV chiếu theo trục pháp tuyến chính (box mapping), `scale` mét / 1 lần lặp texture."""
        p = [Vector(x) for x in verts]
        n = (p[1] - p[0]).cross(p[2] - p[0])
        ax = max(range(3), key=lambda i: abs(n[i]))
        a, b = [(1, 2), (0, 2), (0, 1)][ax]
        self.face(verts, [(q[a] / scale, q[b] / scale) for q in p], m)

    # ── hình cơ bản ──
    def box(self, c, s, m, rot=0.0, scale=1.0, M=None):
        cx, cy, cz = c
        hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
        R = Matrix.Rotation(rot, 4, "Z")
        if M is not None:
            R = M @ R
        P = [R @ Vector((x, y, z)) + Vector((cx, cy, cz)) for x, y, z in
             [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, hy, -hz), (-hx, hy, -hz),
              (-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz)]]
        for q in [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]:
            self.face_auto([P[i] for i in q], m, scale)

    def tube(self, pts, radii, m, sides=8, cap=True, v_scale=1.0, twist=0.0):
        """Ống theo đường cong pts (list Vector), bán kính từng điểm. UV: u quanh, v dọc (mét/v_scale)."""
        pts = [Vector(p) for p in pts]
        rings = []
        acc = 0.0
        prev_n = None
        for i, p in enumerate(pts):
            t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
            if prev_n is None:
                ref = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
                n = t.cross(ref).normalized()
            else:
                n = (prev_n - t * prev_n.dot(t)).normalized()
            prev_n = n
            b = t.cross(n)
            if i:
                acc += (p - pts[i - 1]).length
            ring = []
            for k in range(sides + 1):
                a = 2 * math.pi * k / sides + twist * i
                ring.append(p + (n * math.cos(a) + b * math.sin(a)) * radii[i])
            rings.append((ring, acc))
        circ = 2 * math.pi * max(radii)
        for i in range(len(rings) - 1):
            (r0, v0), (r1, v1) = rings[i], rings[i + 1]
            for k in range(sides):
                self.face([r0[k], r0[k + 1], r1[k + 1], r1[k]],
                          [(k / sides * circ / v_scale, v0 / v_scale), ((k + 1) / sides * circ / v_scale, v0 / v_scale),
                           ((k + 1) / sides * circ / v_scale, v1 / v_scale), (k / sides * circ / v_scale, v1 / v_scale)], m)
        if cap and radii[-1] > 1e-4:
            r = rings[-1][0][:-1]
            self.face(r, [(0.5 + 0.5 * math.cos(2 * math.pi * k / sides), 0.5 + 0.5 * math.sin(2 * math.pi * k / sides))
                          for k in range(sides)], m)

    def lathe(self, prof, m, segs=24, v_scale=1.0, close_top=False, close_bottom=True, M=None):
        """Tiện tròn quanh trục Z. prof = [(r, z), …] từ dưới lên. M: Matrix 4x4 áp lên các đỉnh mới."""
        start = len(self.v)
        self._lathe(prof, m, segs, v_scale, close_top, close_bottom)
        if M is not None:
            for i in range(start, len(self.v)):
                self.v[i] = tuple(M @ Vector(self.v[i]))

    def _lathe(self, prof, m, segs, v_scale, close_top, close_bottom):
        L = [0.0]
        for (r0, z0), (r1, z1) in zip(prof[:-1], prof[1:]):
            L.append(L[-1] + math.hypot(r1 - r0, z1 - z0))
        circ = 2 * math.pi * max(r for r, _ in prof)
        for i in range(len(prof) - 1):
            (r0, z0), (r1, z1) = prof[i], prof[i + 1]
            for k in range(segs):
                a0, a1 = 2 * math.pi * k / segs, 2 * math.pi * (k + 1) / segs
                P = [(r0 * math.cos(a0), r0 * math.sin(a0), z0), (r0 * math.cos(a1), r0 * math.sin(a1), z0),
                     (r1 * math.cos(a1), r1 * math.sin(a1), z1), (r1 * math.cos(a0), r1 * math.sin(a0), z1)]
                U = [(k / segs * circ / v_scale, L[i] / v_scale), ((k + 1) / segs * circ / v_scale, L[i] / v_scale),
                     ((k + 1) / segs * circ / v_scale, L[i + 1] / v_scale), (k / segs * circ / v_scale, L[i + 1] / v_scale)]
                if r0 < 1e-5:
                    self.face(P[1:], U[1:], m)
                elif r1 < 1e-5:
                    self.face(P[:3], U[:3], m)
                else:
                    self.face(P, U, m)
        for close, (r, z), flip in ((close_bottom, prof[0], True), (close_top, prof[-1], False)):
            if close and r > 1e-5:
                ring = [(r * math.cos(2 * math.pi * k / segs), r * math.sin(2 * math.pi * k / segs), z) for k in range(segs)]
                uvs = [(0.5 + 0.5 * math.cos(2 * math.pi * k / segs), 0.5 + 0.5 * math.sin(2 * math.pi * k / segs))
                       for k in range(segs)]
                if flip:
                    ring, uvs = ring[::-1], uvs[::-1]
                self.face(ring, uvs, m)

    def ribbon(self, spine, width, normal_hint, m, uv_rect=(0, 0, 1, 1), widths=None):
        """Dải phẳng dọc spine (lá, lá dừa, phiến cỏ). UV: u ngang [0,1], v dọc [0,1] trong uv_rect."""
        spine = [Vector(p) for p in spine]
        u0, v0, u1, v1 = uv_rect
        n = len(spine)
        hint = Vector(normal_hint).normalized()
        left, right = [], []
        for i, p in enumerate(spine):
            t = (spine[min(i + 1, n - 1)] - spine[max(i - 1, 0)]).normalized()
            side = t.cross(hint)
            if side.length < 1e-6:
                side = t.cross(Vector((1, 0, 0)))
            side.normalize()
            w = (widths[i] if widths else width) / 2
            left.append(p - side * w)
            right.append(p + side * w)
        for i in range(n - 1):
            va, vb = v0 + (v1 - v0) * i / (n - 1), v0 + (v1 - v0) * (i + 1) / (n - 1)
            self.face([left[i], right[i], right[i + 1], left[i + 1]], [(u0, va), (u1, va), (u1, vb), (u0, vb)], m)

    def disc(self, c, r, m, segs=16, z=0.0, notch=0.0):
        cx, cy = c
        pts = [(cx + r * math.cos(2 * math.pi * k / segs + notch), cy + r * math.sin(2 * math.pi * k / segs + notch), z)
               for k in range(segs)]
        self.face(pts, [(0.5 + 0.5 * math.cos(2 * math.pi * k / segs), 0.5 + 0.5 * math.sin(2 * math.pi * k / segs))
                        for k in range(segs)], m)

    def build(self, col=None):
        me = bpy.data.meshes.new(self.name)
        me.from_pydata(self.v, [], self.f)
        uvl = me.uv_layers.new(name="UVMap")
        li = 0
        for poly, uvs in zip(me.polygons, self.uv):
            for k in range(poly.loop_total):
                uvl.data[poly.loop_start + k].uv = uvs[k]
            li += 1
        for m in self.mats:
            me.materials.append(m)
        me.polygons.foreach_set("material_index", self.mi)
        me.validate()
        me.update()
        ob = bpy.data.objects.new(self.name, me)
        (col or bpy.context.scene.collection).objects.link(ob)
        return ob

    def tris(self):
        return sum(len(f) - 2 for f in self.f)


def bezier(p0, p1, p2, n):
    p0, p1, p2 = Vector(p0), Vector(p1), Vector(p2)
    return [(1 - t) ** 2 * p0 + 2 * (1 - t) * t * p1 + t * t * p2 for t in (i / (n - 1) for i in range(n))]


def leaf_spine(base, direction, length, droop, n=5):
    """Đường cong của một chiếc lá: hướng `direction` (Vector), rủ xuống `droop` (0–1)."""
    d = Vector(direction).normalized()
    mid = Vector(base) + d * length * 0.55 + Vector((0, 0, length * 0.15))
    tip = Vector(base) + d * length + Vector((0, 0, -length * droop))
    return bezier(base, mid, tip, n)


def finalize(ob, keep_origin=False):
    """Gốc đáy-giữa (trừ khi keep_origin), áp transform."""
    me = ob.data
    co = np.zeros(len(me.vertices) * 3, np.float32)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    if not keep_origin:
        lo, hi = co.min(0), co.max(0)
        co -= np.array([(lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2]], np.float32)
        me.vertices.foreach_set("co", co.ravel())
        me.update()
    return ob


def export_glb(ob, path):
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True,
                              export_apply=True, export_image_format="AUTO")
