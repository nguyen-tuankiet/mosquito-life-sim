"""Asset P0 procedural v1 — mỗi hàm dựng 1 model (Blender Z-up, mét, mặt trước −Y).

REGISTRY: tên file → (thư mục trong assets/, hàm dựng, giữ gốc?)
  giữ gốc = True: gốc là mặt sàn/mực nước (cầu ao, thuyền, cầu) — manifest dùng "align": "origin".
Đây là bản THAY THẾ TẠM cho model AI 3D / library (docs/ASSET_GUIDELINES.md §6). Thả file thật cùng tên vào
assets/<thư mục>/ là thắng bản procedural (assets/_procedural/ đứng sau trong asset_dirs).
"""
import math

import numpy as np

from mathutils import Matrix, Vector

from . import lib as L

# ───────────────────────── material dùng chung ─────────────────────────


def M():
    return {
        "plaster": L.mat("plaster", L.tex_plaster(1)),
        "plaster_y": L.mat("plaster_yellow", L.tex_plaster(11, "#C9B47A", "#E6D49A")),
        "roof": L.mat("roof_tile", L.tex_roof(3)),
        "wood": L.mat("wood", L.tex_wood(2)),
        "wood_dark": L.mat("wood_dark", L.tex_wood(12, "#3E2A1C")),
        "concrete": L.mat("concrete", L.tex_concrete(5)),
        "straw": L.mat("straw", L.tex_straw(4)),
        "bamboo": L.mat("bamboo", L.tex_bamboo_culm(7)),
        "bamboo_dry": L.mat("bamboo_dry", L.tex_wood(17, "#B59A5A")),
        "bark": L.mat("bark", L.tex_bark(6)),
        "bark_palm": L.mat("bark_palm", L.tex_bark(16, "#5A4C3C", "#9C8C74")),
        "glaze": L.mat("jar_glaze", L.tex_glaze(9), rough=0.35),
        "water": L.mat("container_water", None, (0.18, 0.26, 0.22), rough=0.05),
        "plastic_blue": L.mat("plastic_blue", None, (0.10, 0.35, 0.75), rough=0.45),
        "alu": L.mat("aluminium", None, (0.72, 0.72, 0.70), rough=0.35, metal=0.8),
        "rubber": L.mat("rubber", None, (0.05, 0.05, 0.05), rough=0.9),
        "tin": L.mat("tin_roof", L.tex_concrete(25), rough=0.5, metal=0.5),
        "green": L.mat("stem_green", None, (0.36, 0.48, 0.20)),
        "brown": L.mat("dry_brown", None, (0.40, 0.28, 0.16)),
        "pink": L.mat("lotus_pink", None, (0.86, 0.50, 0.62)),
        "coconut": L.mat("coconut", None, (0.36, 0.42, 0.14)),
        "leaf_broad": L.mat("leaf_broad", L.tex_leaf_cluster(21, "#2A5020", "#5E8A34"), clip=True, double=True),
        "leaf_mango": L.mat("leaf_mango", L.tex_leaf_cluster(22, "#1E3A18", "#4A7428"), clip=True, double=True),
        "leaf_bamboo": L.mat("leaf_bamboo", L.tex_leaf_cluster(23, "#3E6B26", "#8DB34E", kind="lance"), clip=True, double=True),
        "leaf_shrub": L.mat("leaf_shrub", L.tex_leaf_cluster(24, "#284A1C", "#6E9A3A"), clip=True, double=True),
        "banana": L.mat("leaf_banana", L.tex_leaf("banana", 25), clip=True, double=True),
        "frond": L.mat("leaf_frond", L.tex_leaf("frond", 26), clip=True, double=True),
        "blade": L.mat("leaf_blade", L.tex_leaf("blade", 27), clip=True, double=True),
        "blade_rice": L.mat("leaf_rice", L.tex_leaf("blade", 28, "#6FA033", "#B4DA5E"), clip=True, double=True),
        "reed": L.mat("leaf_reed", L.tex_leaf("reed", 29), clip=True, double=True),
        "lily": L.mat("leaf_lily", L.tex_leaf("lily", 30), clip=True, double=True),
    }


def rng(seed):
    return np.random.default_rng(seed)


# ───────────────────────── nhà ─────────────────────────

def _house(name, m, W, Dbody, Dporch, wall_h, ridge_h, wall_mat, columns=True, annex=False, seed=0):
    b = L.MB(name)
    D = Dbody + Dporch
    y0 = -D / 2                      # mép trước (hiên)
    yb = y0 + Dporch                 # tường trước
    y1 = D / 2                       # tường sau
    plinth = 0.45
    b.box((0, 0, plinth / 2), (W, D, plinth), m["concrete"], scale=2)
    b.box((0, (yb + y1) / 2, plinth + wall_h / 2), (W - 0.4, Dbody - 0.2, wall_h), wall_mat, scale=3)
    # cửa + cửa sổ (mặt trước)
    for x in (-W * 0.25, 0.0, W * 0.25):
        b.box((x, yb - 0.06, plinth + 1.1), (1.25, 0.08, 2.2), m["wood_dark"], scale=1.5)
    for x in (-W * 0.42, W * 0.42):
        b.box((x, yb - 0.05, plinth + 1.5), (0.9, 0.06, 0.9), m["wood"], scale=1)
    # cột hiên + xà
    if columns and Dporch > 0.5:
        n = 5
        for i in range(n):
            x = -W / 2 + 0.4 + (W - 0.8) * i / (n - 1)
            b.tube([(x, y0 + 0.3, plinth), (x, y0 + 0.3, wall_h + plinth - 0.25)], [0.12, 0.11], m["wood"], sides=8)
        b.box((0, y0 + 0.3, wall_h + plinth - 0.15), (W, 0.2, 0.25), m["wood"])
    # mái: sườn sau + sườn trước kéo dài phủ hiên (thấp hơn ở mép)
    ov = 0.45
    yr = (yb + y1) / 2
    zt = plinth + wall_h + ridge_h
    ze_back = plinth + wall_h - 0.15
    ze_front = plinth + wall_h - (0.55 if Dporch > 0.5 else 0.15)
    for (ya, za), (yb_, zb) in (((yr, zt), (y1 + ov, ze_back)), ((yr, zt), (y0 - ov, ze_front))):
        L_ = math.hypot(yb_ - ya, zb - za)
        for z_off, mm in ((0.0, m["roof"]), (-0.08, m["wood_dark"])):
            P = [(-W / 2 - ov, ya, za + z_off), (W / 2 + ov, ya, za + z_off), (W / 2 + ov, yb_, zb + z_off),
                 (-W / 2 - ov, yb_, zb + z_off)]
            if z_off:
                P = P[::-1]
            U = [(0, 0), ((W + 2 * ov) / 2.5, 0), ((W + 2 * ov) / 2.5, L_ / 2.5), (0, L_ / 2.5)]
            b.face(P, U if not z_off else U[::-1], mm)
    b.tube([(-W / 2 - ov, yr, zt + 0.05), (W / 2 + ov, yr, zt + 0.05)], [0.14, 0.14], m["roof"], sides=6)
    # đầu hồi (tam giác tường)
    for s in (-1, 1):
        x = s * (W / 2 - 0.2)
        P = [(x, yb + 0.1, plinth + wall_h), (x, y1 - 0.1, plinth + wall_h), (x, yr, zt - 0.1)]
        b.face(P if s > 0 else P[::-1], [(0, 0), (Dbody / 3, 0), (Dbody / 6, ridge_h / 3)], wall_mat)
    if annex:  # bếp phụ mái tôn bên phải
        ax = W / 2 + 1.4
        b.box((ax, y1 - 2.0, 1.2), (2.6, 3.6, 2.4), wall_mat, scale=3)
        b.face([(ax - 1.5, y1 - 4.0, 2.7), (ax + 1.5, y1 - 4.0, 2.3), (ax + 1.5, y1 + 0.1, 2.3), (ax - 1.5, y1 + 0.1, 2.7)],
               [(0, 0), (1.5, 0), (1.5, 2), (0, 2)], m["tin"])
    return b


def house_vn_01(m):
    return _house("house_vn_01", m, 14.4, 6.9, 2.5, 3.0, 2.4, m["plaster"], columns=True)


def house_vn_02(m):
    return _house("house_vn_02", m, 11.0, 6.4, 1.4, 2.8, 2.0, m["plaster_y"], columns=False, annex=True)


def house_vn_03(m):
    return _house("house_vn_03", m, 12.0, 6.0, 2.0, 2.8, 2.1, m["plaster"], columns=True, annex=True)


# ───────────────────────── vật chứa nước ─────────────────────────

def _vessel(name, m, outer, wall, water_z, mat, segs=24, extra=None):
    b = L.MB(name)
    b.lathe(outer, mat, segs=segs, v_scale=0.5)
    inner = [(max(r - wall, 0.01), z) for r, z in reversed(outer[1:])]
    inner[-1] = (inner[-1][0], outer[0][1] + wall)
    b.lathe(inner, mat, segs=segs, v_scale=0.5, close_bottom=False)
    # mặt nước (nơi lăng quăng sống)
    rr = np.interp(water_z, [z for _, z in outer], [r for r, _ in outer]) - wall
    b.disc((0, 0), rr * 0.98, m["water"], segs=segs, z=water_z)
    if extra:
        extra(b)
    return b


def water_jar_vn(m):
    prof = [(0.17, 0.0), (0.28, 0.06), (0.40, 0.25), (0.45, 0.45), (0.42, 0.62), (0.32, 0.78), (0.25, 0.86),
            (0.27, 0.88), (0.27, 0.91)]
    return _vessel("water_jar_vn", m, prof, 0.035, 0.78, m["glaze"], segs=28)


def bucket_vn(m):
    def handle(b):
        pts = [(0.17 * math.cos(a), 0.0, 0.33 + 0.12 * math.sin(a)) for a in np.linspace(0, math.pi, 9)]
        b.tube(pts, [0.008] * 9, m["alu"], sides=5, cap=False)
    return _vessel("bucket_vn", m, [(0.13, 0.0), (0.15, 0.17), (0.17, 0.33), (0.18, 0.35)], 0.012, 0.27,
                   m["plastic_blue"], segs=20, extra=handle)


def basin_vn(m):
    return _vessel("basin_vn", m, [(0.24, 0.0), (0.31, 0.10), (0.35, 0.16), (0.36, 0.18)], 0.01, 0.12, m["alu"], segs=24)


def old_tire(m):
    b = L.MB("old_tire")
    R, r = 0.30, 0.11
    pts = [(R * math.cos(a), R * math.sin(a), r) for a in np.linspace(0, 2 * math.pi, 25)]
    b.tube(pts, [r] * 25, m["rubber"], sides=10, cap=False)
    b.disc((0, 0), R - r * 0.6, m["water"], segs=16, z=r * 0.8)
    return b


# ───────────────────────── công trình ─────────────────────────

def bamboo_fence(m):
    b = L.MB("bamboo_fence")
    Lx, H = 3.0, 1.1
    for x in (-Lx / 2 + 0.05, Lx / 2 - 0.05):
        b.tube([(x, 0, 0), (x, 0, H + 0.15)], [0.05, 0.045], m["bamboo"], sides=6)
    for z in (0.32, 0.82):
        b.tube([(-Lx / 2, 0.04, z), (Lx / 2, 0.04, z)], [0.028, 0.028], m["bamboo"], sides=5, cap=False)
    R = rng(41)
    x = -Lx / 2 + 0.12
    while x < Lx / 2 - 0.1:
        h = H - R.uniform(0, 0.12)
        b.box((x, -0.02, h / 2), (0.045, 0.018, h), m["bamboo_dry"], rot=R.uniform(-0.05, 0.05), scale=1)
        x += 0.11
    return b


def power_pole_vn(m):
    b = L.MB("power_pole_vn")
    b.lathe([(0.20, 0.0), (0.11, 8.0)], m["concrete"], segs=4, v_scale=2, close_top=True)
    b.box((0, 0, 7.4), (1.8, 0.12, 0.12), m["concrete"])
    for x in (-0.75, 0.0, 0.75):          # sứ cách điện
        b.lathe([(0.04, 7.46), (0.06, 7.55), (0.03, 7.68)], m["water"], segs=8, close_top=True,
                M=Matrix.Translation((x, 0, 0)))
    return b


def haystack_vn(m):
    b = L.MB("haystack_vn")
    prof = [(1.9, 0.0), (2.15, 0.5), (2.05, 1.3), (1.6, 2.1), (0.9, 2.7), (0.3, 3.0), (0.06, 3.08)]
    b.lathe(prof, m["straw"], segs=20, v_scale=1.0, close_top=True)
    R = rng(51)
    for i, p in enumerate(b.v):        # rơm bù xù
        v = Vector(p)
        rad = Vector((v.x, v.y, 0))
        if rad.length > 0.1:
            k = 1 + R.uniform(-0.06, 0.06)
            b.v[i] = (v.x * k, v.y * k, v.z + R.uniform(-0.05, 0.05))
    b.tube([(0, 0, 2.6), (0.05, 0.02, 3.9)], [0.05, 0.035], m["bamboo_dry"], sides=5)
    return b


def _hut(name, m, walls):
    b = L.MB(name)
    S, floor = 3.0, 0.6
    for x in (-S / 2 + 0.1, S / 2 - 0.1):
        for y in (-S / 2 + 0.1, S / 2 - 0.1):
            b.tube([(x, y, 0), (x, y, 2.4)], [0.07, 0.06], m["bamboo"], sides=6)
    b.box((0, 0, floor), (S, S, 0.1), m["bamboo_dry"], scale=1)
    if walls:
        b.box((0, S / 2 - 0.1, floor + 0.9), (S - 0.2, 0.06, 1.7), m["straw"], scale=1.5)
        for s in (-1, 1):
            b.box((s * (S / 2 - 0.1), 0, floor + 0.9), (0.06, S - 0.2, 1.7), m["straw"], scale=1.5)
    # mái tranh dày 2 mái
    ridge, eave, ov = 3.3, 2.05, 0.55
    for s in (-1, 1):
        y_e = s * (S / 2 + ov)
        for dz, mm, flip in ((0.0, m["straw"], False), (-0.22, m["straw"], True)):
            P = [(-S / 2 - ov, 0, ridge + dz), (S / 2 + ov, 0, ridge + dz), (S / 2 + ov, y_e, eave + dz),
                 (-S / 2 - ov, y_e, eave + dz)]
            if (s > 0) != flip:
                P = P[::-1]
            b.face(P, [(0, 0), (2, 0), (2, 1.2), (0, 1.2)], mm)
    return b


def field_hut_vn(m):
    return _hut("field_hut_vn", m, walls=False)


def bamboo_hut_vn(m):
    return _hut("bamboo_hut_vn", m, walls=True)


def pond_jetty_vn(m):
    """Cầu ao: gốc = mặt sàn. Dài theo X (6 m), bậc xuống nước ở đầu −X."""
    b = L.MB("pond_jetty_vn")
    Lx, Wy = 6.0, 1.8
    R = rng(61)
    x = -Lx / 2
    while x < Lx / 2:
        b.box((x + 0.11, 0, -0.04), (0.2, Wy + R.uniform(-0.1, 0.05), 0.07), m["wood"], rot=R.uniform(-0.02, 0.02), scale=1)
        x += 0.22
    for xi in (-Lx / 2 + 0.2, 0.0, Lx / 2 - 0.2):
        for yi in (-Wy / 2 + 0.1, Wy / 2 - 0.1):
            b.tube([(xi, yi, -0.08), (xi, yi, -2.6)], [0.07, 0.07], m["wood_dark"], sides=6)
    for k, (dx, dz) in enumerate(((0.5, -0.35), (1.0, -0.7))):
        b.box((-Lx / 2 - dx, 0, dz), (0.45, Wy * 0.8, 0.08), m["wood"])
    return b


def wooden_boat_vn(m):
    """Thuyền gỗ nhỏ, dài theo Y (4.5 m). Gốc = mực nước, đáy ở z −0.25."""
    b = L.MB("wooden_boat_vn")
    Ly, half_w, depth, top = 4.5, 0.6, 0.25, 0.25
    stations = np.linspace(-Ly / 2, Ly / 2, 9)
    secs = []
    for y in stations:
        t = 1 - (2 * y / Ly) ** 2
        w = half_w * max(t, 0.02) ** 0.6
        zb = -depth * max(t, 0.0) ** 0.4 + top * (1 - max(t, 0.0)) * 0.6
        secs.append([(-w, y, top), (-w * 0.85, y, zb * 0.5), (0, y, zb), (w * 0.85, y, zb * 0.5), (w, y, top)])
    for i in range(len(secs) - 1):
        for k in range(4):
            P = [secs[i][k], secs[i][k + 1], secs[i + 1][k + 1], secs[i + 1][k]]
            b.face(P, [(k / 4, i / 8), ((k + 1) / 4, i / 8), ((k + 1) / 4, (i + 1) / 8), (k / 4, (i + 1) / 8)],
                   m["wood_dark"])
    for y in (-0.8, 0.6):
        b.box((0, y, top - 0.08), (half_w * 1.7, 0.25, 0.05), m["wood"])
    b.tube([(-0.3, -1.0, top), (0.35, 1.6, top + 0.05)], [0.025, 0.025], m["wood"], sides=5)
    return b


def bridge_vn(m):
    """Cầu ván qua kênh: dài theo X (24 m), rộng 3 m, gốc = mặt cầu."""
    b = L.MB("bridge_vn")
    Lx, Wy = 24.0, 3.0
    x = -Lx / 2
    while x < Lx / 2:
        b.box((x + 0.15, 0, -0.05), (0.28, Wy, 0.08), m["wood"], scale=1)
        x += 0.3
    for xi in np.linspace(-Lx / 2 + 0.3, Lx / 2 - 0.3, 7):
        for yi in (-Wy / 2 + 0.15, Wy / 2 - 0.15):
            b.tube([(xi, yi, -0.1), (xi, yi, -3.4)], [0.1, 0.1], m["wood_dark"], sides=6, cap=False)
    for yi in (-Wy / 2 + 0.05, Wy / 2 - 0.05):
        for xi in np.linspace(-Lx / 2 + 0.1, Lx / 2 - 0.1, 13):
            b.tube([(xi, yi, 0), (xi, yi, 0.95)], [0.04, 0.04], m["bamboo"], sides=5)
        b.tube([(-Lx / 2, yi, 0.92), (Lx / 2, yi, 0.92)], [0.04, 0.04], m["bamboo"], sides=5)
        b.tube([(-Lx / 2, yi, 0.5), (Lx / 2, yi, 0.5)], [0.03, 0.03], m["bamboo"], sides=5)
    return b


# ───────────────────────── thực vật ─────────────────────────

def _canopy(b, mat, center, radii, n, card, R, droop=0.2):
    cx, cy, cz = center
    for _ in range(n):
        d = Vector(R.normal(size=3))
        d.normalize()
        p = Vector((cx + d.x * radii[0] * R.uniform(0.6, 1.0), cy + d.y * radii[1] * R.uniform(0.6, 1.0),
                    cz + d.z * radii[2] * R.uniform(0.5, 1.0)))
        nrm = (p - Vector(center)).normalized()
        nrm.z += droop
        up = Vector((0, 0, 1)) if abs(nrm.z) < 0.9 else Vector((1, 0, 0))
        side = up.cross(nrm).normalized() * card / 2
        upv = nrm.cross(side).normalized() * card / 2
        rot = Matrix.Rotation(R.uniform(0, math.pi), 3, nrm)
        side, upv = rot @ side, rot @ upv
        b.face([p - side - upv, p + side - upv, p + side + upv, p - side + upv], [(0, 0), (1, 0), (1, 1), (0, 1)], mat)


def _branchy_tree(name, m, leaf, seed, height, trunk_r, crown, n_cards, card):
    R = rng(seed)
    b = L.MB(name)
    top = Vector((R.uniform(-0.3, 0.3), R.uniform(-0.3, 0.3), height * 0.45))
    b.tube(L.bezier((0, 0, 0), (0, 0, height * 0.25), top, 6), list(np.linspace(trunk_r, trunk_r * 0.6, 6)),
           m["bark"], sides=8, v_scale=1.5)
    for k in range(5):
        a = 2 * math.pi * k / 5 + R.uniform(-0.3, 0.3)
        end = top + Vector((math.cos(a) * crown[0] * 0.7, math.sin(a) * crown[1] * 0.7, height * R.uniform(0.15, 0.3)))
        mid = (top + end) / 2 + Vector((0, 0, 0.5))
        b.tube(L.bezier(top, mid, end, 4), list(np.linspace(trunk_r * 0.55, 0.04, 4)), m["bark"], sides=6, v_scale=1.5)
    _canopy(b, leaf, (0, 0, height * 0.65), crown, n_cards, card, R)
    return b


def fruit_tree_01(m):
    return _branchy_tree("fruit_tree_01", m, m["leaf_broad"], 71, 7.0, 0.18, (2.6, 2.6, 2.2), 150, 1.3)


def fruit_tree_02(m):
    return _branchy_tree("fruit_tree_02", m, m["leaf_mango"], 72, 7.0, 0.22, (3.0, 3.0, 2.0), 170, 1.4)


def banyan_tree(m):
    R = rng(73)
    b = L.MB("banyan_tree")
    b.tube([(0, 0, 0), (0, 0, 3), (0.2, 0.1, 6)], [1.0, 0.85, 0.7], m["bark"], sides=12, v_scale=2)
    for k in range(6):                  # rễ bạnh
        a = 2 * math.pi * k / 6 + R.uniform(-0.2, 0.2)
        b.tube(L.bezier((math.cos(a) * 2.2, math.sin(a) * 2.2, 0), (math.cos(a) * 1.0, math.sin(a) * 1.0, 0.8),
                        (0, 0, 2.5), 5), [0.35, 0.3, 0.25, 0.2, 0.15], m["bark"], sides=6, v_scale=2)
    b.lathe([(0.45, 0.05), (0.35, 1.3), (0.0, 1.4)], m["wood_dark"], segs=10,          # hốc cây (mặt trước)
            M=Matrix.Translation((0, -0.92, 0)) @ Matrix.Scale(0.4, 4, (0, 1, 0)))
    tips = []
    for k in range(9):
        a = 2 * math.pi * k / 9 + R.uniform(-0.2, 0.2)
        start = Vector((0, 0, R.uniform(4.5, 6.5)))
        end = Vector((math.cos(a) * R.uniform(6, 8), math.sin(a) * R.uniform(5, 7), R.uniform(8, 10)))
        b.tube(L.bezier(start, (start + end) / 2 + Vector((0, 0, 1.5)), end, 5), list(np.linspace(0.45, 0.08, 5)),
               m["bark"], sides=6, v_scale=2)
        tips.append(end)
    for k in range(22):                  # rễ phụ thõng xuống
        t = tips[k % len(tips)] * R.uniform(0.4, 0.9)
        b.tube([(t.x, t.y, t.z - 0.5), (t.x + R.uniform(-0.2, 0.2), t.y, 0.0)], [0.04, 0.03], m["bark"], sides=4, cap=False)
    _canopy(b, m["leaf_mango"], (0, 0, 10.0), (8.0, 7.0, 3.5), 420, 2.0, R)
    return b


def banana_clump_vn(m):
    R = rng(81)
    b = L.MB("banana_clump_vn")
    for s in range(4):
        base = Vector((R.uniform(-0.5, 0.5), R.uniform(-0.5, 0.5), 0))
        h = R.uniform(1.8, 2.8)
        top = base + Vector((R.uniform(-0.2, 0.2), R.uniform(-0.2, 0.2), h))
        b.tube([base, top], [0.13, 0.09], m["green"], sides=8)
        for k in range(7):
            a = 2 * math.pi * k / 7 + R.uniform(-0.3, 0.3)
            d = Vector((math.cos(a), math.sin(a), R.uniform(0.3, 1.0)))
            sp = L.leaf_spine(top, d, R.uniform(1.6, 2.2), R.uniform(0.3, 0.9), 6)
            b.ribbon(sp, 0.55, Vector((0, 0, 1)), m["banana"], widths=[0.1, 0.45, 0.55, 0.55, 0.45, 0.15])
    return b


def coconut_palm(m):
    R = rng(91)
    b = L.MB("coconut_palm")
    H = 12.0
    lean = Vector((R.uniform(1.0, 2.0), R.uniform(-0.5, 0.5), 0))
    top = Vector((0, 0, H)) + lean
    spine = L.bezier((0, 0, 0), (0, 0, H * 0.5), top, 9)
    b.tube(spine, list(np.linspace(0.24, 0.15, 9)), m["bark_palm"], sides=8, v_scale=0.6)
    for k in range(14):
        a = 2 * math.pi * k / 14 + R.uniform(-0.15, 0.15)
        up = R.uniform(-0.1, 0.8)
        sp = L.leaf_spine(top, (math.cos(a), math.sin(a), up), R.uniform(3.8, 4.8), R.uniform(0.7, 1.4), 7)
        b.ribbon(sp, 1.4, Vector((0, 0, 1)), m["frond"])
    for k in range(6):
        a = 2 * math.pi * k / 6
        c = top + Vector((math.cos(a) * 0.3, math.sin(a) * 0.3, -0.35))
        b.lathe([(0.0, -0.12), (0.12, 0.0), (0.0, 0.13)], m["coconut"], segs=8, M=Matrix.Translation(c))
    return b


def _bamboo(name, m, seed, n, spread):
    R = rng(seed)
    b = L.MB(name)
    for _ in range(n):
        a, r = R.uniform(0, 2 * math.pi), R.uniform(0, 0.7)
        base = Vector((math.cos(a) * r, math.sin(a) * r, 0))
        h = R.uniform(8.5, 11.5)
        out = Vector((math.cos(a), math.sin(a), 0)) * R.uniform(0.8, spread)
        top = base + out * 2.2 + Vector((0, 0, h))
        spine = L.bezier(base, base + Vector((0, 0, h * 0.55)), top, 6)
        rr = R.uniform(0.04, 0.06)
        b.tube(spine, [rr, rr * 0.95, rr * 0.85, rr * 0.7, rr * 0.5, rr * 0.3], m["bamboo"], sides=6, v_scale=1.0,
               cap=False)
        for k in range(8):
            t = R.uniform(0.45, 1.0)
            i = min(int(t * 5), 4)
            p = spine[i].lerp(spine[i + 1], t * 5 - i)
            d = Vector((R.normal(), R.normal(), -0.6)).normalized()
            side = d.cross(Vector((0, 0, 1))).normalized() * 0.65
            b.face([p - side, p + side, p + side + d * 1.1, p - side + d * 1.1], [(0, 1), (1, 1), (1, 0), (0, 0)],
                   m["leaf_bamboo"])
    return b


def bamboo_clump_01(m):
    return _bamboo("bamboo_clump_01", m, 101, 18, 1.4)


def bamboo_clump_02(m):
    return _bamboo("bamboo_clump_02", m, 102, 26, 2.0)


def _shrub(name, m, seed, leaf, size):
    R = rng(seed)
    b = L.MB(name)
    for k in range(5):
        a = 2 * math.pi * k / 5
        b.tube([(0, 0, 0), (math.cos(a) * 0.4 * size, math.sin(a) * 0.4 * size, 1.0 * size)], [0.03, 0.015],
               m["bark"], sides=4)
    _canopy(b, leaf, (0, 0, 1.0 * size), (0.9 * size, 0.9 * size, 0.8 * size), 38, 0.9 * size, R, droop=0.4)
    return b


def shrub_tropical_01(m):
    return _shrub("shrub_tropical_01", m, 111, m["leaf_shrub"], 1.0)


def shrub_tropical_02(m):
    return _shrub("shrub_tropical_02", m, 112, m["leaf_broad"], 0.8)


def fern_clump(m):
    R = rng(113)
    b = L.MB("fern_clump")
    for k in range(11):
        a = 2 * math.pi * k / 11 + R.uniform(-0.2, 0.2)
        sp = L.leaf_spine((0, 0, 0.05), (math.cos(a), math.sin(a), 1.6), R.uniform(0.8, 1.2), R.uniform(0.3, 0.7), 5)
        b.ribbon(sp, 0.35, Vector((0, 0, 1)), m["frond"])
    return b


def _blades(name, mat, seed, n, length, width, spread, droop, heads=0, head_mat=None):
    R = rng(seed)
    b = L.MB(name)
    for _ in range(n):
        a = R.uniform(0, 2 * math.pi)
        base = Vector((R.uniform(-spread, spread), R.uniform(-spread, spread), 0))
        d = Vector((math.cos(a) * R.uniform(0.15, 0.5), math.sin(a) * R.uniform(0.15, 0.5), 1.0))
        ln = R.uniform(*length)
        sp = L.bezier(base, base + d.normalized() * ln * 0.6, base + d * ln * 0.75 + Vector((d.x, d.y, -droop)) * ln * 0.4, 3)
        b.ribbon(sp, width, Vector((math.cos(a + 1.57), math.sin(a + 1.57), 0)), mat)
    for _ in range(heads):
        base = Vector((R.uniform(-spread, spread), R.uniform(-spread, spread), 0))
        ln = length[1] * R.uniform(0.9, 1.1)
        tip = base + Vector((R.uniform(-0.15, 0.15), R.uniform(-0.15, 0.15), ln))
        b.tube([base, tip], [0.006, 0.004], head_mat, sides=4, cap=False)
        b.tube([tip, tip + (tip - base).normalized() * 0.16], [0.014, 0.008], head_mat, sides=5)
    return b


def grass_clump_vn(m):
    return _blades("grass_clump_vn", m["blade"], 121, 8, (0.22, 0.36), 0.06, 0.08, 0.3)


def grass_tall(m):
    return _blades("grass_tall", m["blade"], 122, 14, (0.7, 1.05), 0.07, 0.15, 0.25, heads=3, head_mat=m["brown"])


def reed_clump(m):
    return _blades("reed_clump", m["reed"], 131, 12, (1.5, 2.1), 0.07, 0.18, 0.12, heads=3, head_mat=m["brown"])


def rice_patch_1m(m):
    R = rng(141)
    b = L.MB("rice_patch_1m")
    for i in range(4):
        for j in range(4):
            c = (-0.375 + i * 0.25 + R.uniform(-0.03, 0.03), -0.375 + j * 0.25 + R.uniform(-0.03, 0.03))
            for k in range(6):
                a = 2 * math.pi * k / 6 + R.uniform(-0.3, 0.3)
                base = Vector((c[0], c[1], 0))
                d = Vector((math.cos(a) * 0.25, math.sin(a) * 0.25, 1))
                ln = R.uniform(0.7, 0.9)
                sp = L.bezier(base, base + d * ln * 0.55, base + d * ln * 0.8 + Vector((d.x, d.y, 0)) * 0.6, 3)
                b.ribbon(sp, 0.035, Vector((math.cos(a + 1.57), math.sin(a + 1.57), 0)), m["blade_rice"])
    return b


def lily_pad_vn(m):
    R = rng(151)
    b = L.MB("lily_pad_vn")
    for k in range(5):
        c = Vector((R.uniform(-0.6, 0.6), R.uniform(-0.6, 0.6), 0.01))
        s = R.uniform(0.25, 0.4)
        rot = Matrix.Rotation(R.uniform(0, 6.28), 3, "Z")
        P = [c + rot @ Vector(v) * s for v in ((-1, -1, 0), (1, -1, 0), (1, 1, 0), (-1, 1, 0))]
        b.face(P, [(0, 0), (1, 0), (1, 1), (0, 1)], m["lily"])
    b.lathe([(0.0, 0.02), (0.09, 0.05), (0.05, 0.13), (0.0, 0.10)], m["pink"], segs=6)
    return b


REGISTRY = {
    # tên file: (thư mục, hàm, giữ gốc)
    "house_vn_01": ("environment/houses", house_vn_01, False),
    "house_vn_02": ("environment/houses", house_vn_02, False),
    "house_vn_03": ("environment/houses", house_vn_03, False),
    "water_jar_vn": ("props/water_jars", water_jar_vn, False),
    "bucket_vn": ("props/buckets", bucket_vn, False),
    "basin_vn": ("props/buckets", basin_vn, False),
    "old_tire": ("props/buckets", old_tire, False),
    "bamboo_fence": ("environment/roads", bamboo_fence, False),
    "power_pole_vn": ("environment/roads", power_pole_vn, False),
    "haystack_vn": ("environment/gardens", haystack_vn, False),
    "bamboo_hut_vn": ("environment/gardens", bamboo_hut_vn, False),
    "field_hut_vn": ("environment/rice_fields", field_hut_vn, False),
    "pond_jetty_vn": ("environment/ponds", pond_jetty_vn, True),
    "wooden_boat_vn": ("environment/ponds", wooden_boat_vn, True),
    "bridge_vn": ("environment/canals", bridge_vn, True),
    "fruit_tree_01": ("environment/gardens", fruit_tree_01, False),
    "fruit_tree_02": ("environment/gardens", fruit_tree_02, False),
    "banyan_tree": ("environment/gardens", banyan_tree, False),
    "banana_clump_vn": ("environment/gardens", banana_clump_vn, False),
    "coconut_palm": ("environment/grasslands", coconut_palm, False),
    "bamboo_clump_01": ("environment/bamboo", bamboo_clump_01, False),
    "bamboo_clump_02": ("environment/bamboo", bamboo_clump_02, False),
    "shrub_tropical_01": ("environment/bamboo", shrub_tropical_01, False),
    "shrub_tropical_02": ("environment/bamboo", shrub_tropical_02, False),
    "fern_clump": ("environment/bamboo", fern_clump, False),
    "grass_clump_vn": ("environment/grasslands", grass_clump_vn, False),
    "grass_tall": ("environment/grasslands", grass_tall, False),
    "reed_clump": ("environment/ponds", reed_clump, False),
    "rice_patch_1m": ("environment/rice_fields", rice_patch_1m, False),
    "lily_pad_vn": ("environment/ponds", lily_pad_vn, False),
}
