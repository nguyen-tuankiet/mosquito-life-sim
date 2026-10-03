"""Lăng quăng & nhộng vẽ theo hướng thực tế: da trong mờ, thấy ruột/khí quản bên trong, lông tơ, bóng 3D."""
import math
import numpy as np
from lib import *

SKIN = (0.95, 0.88, 0.66)
SKIN_SH = (0.38, 0.27, 0.14)
RIM = (1.0, 0.97, 0.85)
DARK = (0.17, 0.09, 0.04)


def ell(cx, cy, rx, ry, rot=0.0, n=120):
    t = np.linspace(0, 2 * math.pi, n, endpoint=False)
    c, s = math.cos(rot), math.sin(rot)
    return np.stack([cx + rx * np.cos(t) * c - ry * np.sin(t) * s, cy + rx * np.cos(t) * s + ry * np.sin(t) * c], 1)


def hair(c, base, ang, L, w, col=(0.28, 0.17, 0.08), a=0.85, curl=0.0):
    p0 = np.array(base, float)
    d = np.array([math.cos(ang), math.sin(ang)])
    p1 = p0 + d * L * 0.5 + np.array([-d[1], d[0]]) * curl * L
    p2 = p0 + d * L + np.array([-d[1], d[0]]) * curl * L * 1.6
    c.line(catmull([tuple(p0), tuple(p1), tuple(p2)], 8), 0, col, taper=(w, w * 0.2), alpha=a)


def larva(c, ox, oy, scale=1.0, seed=5):
    r = np.random.default_rng(seed)
    S = scale
    spine = catmull([(0, 0), (4, 80), (20, 190), (28, 320), (4, 450), (-44, 555), (-116, 625), (-196, 660)], 36)
    n = len(spine)
    tang = np.gradient(spine, axis=0)
    tang /= np.linalg.norm(tang, axis=1, keepdims=True)
    nrm = np.stack([-tang[:, 1], tang[:, 0]], 1)

    def P(p):
        return (ox + p[0] * S, oy + p[1] * S)

    # bóng đổ mờ trong nước
    glow = tube([P(p) for p in spine[14:]], [150 * S] * (n - 14))
    c.poly(glow, (0.95, 0.85, 0.5), 0.08, blur=44 * S, mode='add')
    # ---- ống thở (siphon) có lược răng ----
    sip = [P(p) for p in catmull([(0, -46), (2, 6), (6, 56), (9, 98)], 14)]
    sp_poly = tube(sip, [26 * S, 42 * S])
    c.solid(sp_poly, (0.62, 0.40, 0.2), (0.14, 0.07, 0.03), spec=0.35, shin=18, rim=RIM, rim_k=0.3, tex=0.05)
    for k in range(5):
        q = sip[3 + k * 2]
        c.line([(q[0] + 12 * S, q[1]), (q[0] + 21 * S, q[1] + 6 * S)], 2.0 * S, (0.12, 0.06, 0.03), alpha=0.8)
    # mặt nước ôm lấy ống thở
    t = np.linspace(0, 2 * math.pi, 80)
    for rr, al in ((46, 0.55), (82, 0.35), (130, 0.18)):
        c.line([(sip[0][0] + rr * S * math.cos(a), sip[0][1] + 6 * S + rr * 0.13 * S * math.sin(a)) for a in t], 2.4, (0.95, 1, 1), alpha=al)

    # ---- bụng: ống liền, da trong mờ ----
    i0, i1 = 12, int(n * 0.80)
    body = [P(p) for p in spine[i0:i1]]
    m_ = len(body)
    prof = [(0.0, 56), (0.12, 66), (0.5, 86), (1.0, 108)]
    wid = np.interp(np.linspace(0, 1, m_), [p[0] for p in prof], [p[1] * S for p in prof])
    poly = tube(body, list(wid))
    c.shadow(poly, 10, 14, 10, 0.22, (0.02, 0.1, 0.13))
    c.solid(poly, SKIN, SKIN_SH, light=(-0.7, -0.55, 0.5), spec=0.55, shin=24, rim=RIM, rim_k=0.55, alpha=0.62, a_edge=0.97, tex=0.04, seed=3)
    # cấu trúc bên trong thấy xuyên da: ruột (đậm) + hai thân khí quản (bạc)
    gut = body[: int(m_ * 0.92)]
    c.line(gut, 0, (0.30, 0.2, 0.08), taper=(16 * S, 34 * S), alpha=0.5, blur=2.5)
    for off in (-0.26, 0.26):
        tr = []
        for k, (x, y) in enumerate(gut):
            j = i0 + k
            tr.append((x + nrm[j][0] * off * wid[k], y + nrm[j][1] * off * wid[k]))
        c.line(tr, 0, (0.93, 0.97, 0.98), taper=(5 * S, 8 * S), alpha=0.7, blur=0.8)
    # vằn giữa các đốt: rãnh tối + gờ sáng
    for i in range(1, 9):
        k = int(m_ * (0.02 + 0.93 * i / 8.7))
        p = np.array(body[k])
        tg = tang[i0 + k]
        nr = nrm[i0 + k]
        w_ = wid[k] * 0.5
        arc = [tuple(p + nr * w_ * u + tg * (8 * S) * (1 - u * u)) for u in np.linspace(-0.97, 0.97, 18)]
        c.line(arc, 5.0 * S, (0.28, 0.16, 0.06), alpha=0.55, blur=1.2)
        c.line([(x - 3 * S, y - 3 * S) for x, y in arc], 2.6 * S, (1.0, 0.96, 0.8), alpha=0.5, blur=0.8)
        # chùm lông tơ hình quạt hai bên đốt
        for sd in (-1, 1):
            b = tuple(p + nr * sd * w_ * 0.96)
            base_ang = math.atan2(nr[1] * sd, nr[0] * sd)
            for q in range(6):
                hair(c, b, base_ang + (q - 2.5) * 0.26, r.uniform(38, 74) * S, 3.4 * S, a=0.8, curl=r.uniform(-0.12, 0.12))
    # mang hậu môn (anal papillae)
    gp = P(spine[8] + np.array([0, 14]))
    for dx, rot_ in ((-30, 0.5), (30, -0.5)):
        c.solid(ell(gp[0] + dx * S, gp[1] + 28 * S, 15 * S, 36 * S, rot_), (0.96, 0.92, 0.8), (0.55, 0.45, 0.3), spec=0.5, alpha=0.7, a_edge=0.95, rim=RIM, rim_k=0.4)
    # ---- ngực (phình to, nhiều lông) ----
    kt = int(n * 0.86)
    pt = P(spine[kt])
    ang = math.atan2(tang[kt][1], tang[kt][0]) + math.pi / 2
    thx = ell(pt[0], pt[1], 118 * S, 104 * S, ang)
    c.shadow(thx, 12, 18, 12, 0.22, (0.02, 0.1, 0.13))
    c.solid(thx, (0.97, 0.88, 0.62), (0.34, 0.22, 0.1), light=(-0.7, -0.6, 0.5), spec=0.6, shin=26, rim=RIM, rim_k=0.55, alpha=0.7, a_edge=0.98, tex=0.05, seed=9)
    # cơ & các mảng sắc tố bên trong ngực
    for q in range(3):
        c.ellipse(pt[0] + (q - 1) * 44 * S, pt[1] + 8 * S, 24 * S, 46 * S, (0.45, 0.28, 0.12), rot=ang, alpha=0.16, blur=6)
    for q in range(28):
        a = r.uniform(0, 2 * math.pi)
        b = (pt[0] + math.cos(a) * 112 * S, pt[1] + math.sin(a) * 98 * S)
        hair(c, b, a + r.uniform(-0.25, 0.25), r.uniform(46, 112) * S, 3.8 * S, a=0.75, curl=r.uniform(-0.1, 0.1))
    # ---- đầu: sạm màu, bóng ----
    kh = int(n * 0.95)
    ph = P(spine[kh] + np.array([-34, 56]))
    hd = ell(ph[0], ph[1], 82 * S, 72 * S, 0.25)
    c.shadow(hd, 10, 16, 10, 0.25, (0.02, 0.1, 0.13))
    c.solid(hd, (0.62, 0.36, 0.16), (0.14, 0.07, 0.03), light=(-0.65, -0.65, 0.5), spec=0.8, shin=40, rim=(1, 0.85, 0.55), rim_k=0.35, tex=0.07, seed=13)
    # mắt: đốm đen bóng như hạt
    for dx in (-30, 30):
        ex, ey = ph[0] + dx * S, ph[1] - 6 * S
        c.solid(ell(ex, ey, 17 * S, 15 * S), (0.1, 0.09, 0.09), (0.0, 0.0, 0.0), spec=1.0, shin=60, light=(-0.5, -0.7, 0.5), bulge=1.4)
    # râu có lông
    for sg in (-1, 1):
        a = catmull([(ph[0] + sg * 52 * S, ph[1] - 28 * S), (ph[0] + sg * 92 * S, ph[1] - 66 * S), (ph[0] + sg * 108 * S, ph[1] - 118 * S)], 12)
        c.solid(tube(a, [14 * S, 6 * S]), (0.6, 0.38, 0.18), (0.18, 0.1, 0.05), spec=0.4)
        for k in range(2, len(a), 2):
            hair(c, a[k], math.atan2(-1, sg * 0.4) + r.uniform(-0.4, 0.4), 22 * S, 2.2 * S, a=0.7)
    # chổi miệng vàng nhạt, nhiều sợi mảnh
    for q in range(42):
        a = math.pi / 2 + r.uniform(-0.9, 0.9)
        b = (ph[0] + r.uniform(-34, 34) * S, ph[1] + 56 * S)
        hair(c, b, a, r.uniform(34, 84) * S, 3.0 * S, col=(0.94, 0.82, 0.55), a=0.8, curl=r.uniform(-0.2, 0.2))


def pupa(c, ox, oy, s=1.0, rotation=0.0, trumpets=True):
    def T(p):
        x, y = rot((p[0] * s, p[1] * s), rotation)
        return (ox + x, oy + y)
    # kèn thở có vành
    if trumpets:
        for dx in (-44, 40):
            tr = [T(p) for p in catmull([(dx, -110), (dx - 10, -200), (dx - 8, -280), (dx - 2, -336)], 12)]
            c.solid(tube(tr, [20 * s, 40 * s]), (0.78, 0.55, 0.28), (0.2, 0.1, 0.04), spec=0.5, shin=22, rim=RIM, rim_k=0.4, alpha=0.8, a_edge=0.98)
            tip = tr[-1]
            c.solid(ell(tip[0], tip[1], 26 * s, 10 * s), (0.97, 0.9, 0.7), (0.5, 0.4, 0.25), spec=0.5)
            c.ellipse(tip[0], tip[1], 14 * s, 4 * s, (0.1, 0.06, 0.03), alpha=0.8)
    # bụng gập, tròn, nhiều đốt + mái chèo
    ab = [T(p) for p in catmull([(76, 86), (110, 210), (66, 322), (-30, 392), (-128, 398), (-196, 362)], 30)]
    wid = np.interp(np.linspace(0, 1, len(ab)), [0, 0.5, 1], [150, 108, 34])
    poly = tube(ab, list(wid * s))
    c.shadow(poly, 12, 16, 12, 0.22, (0.02, 0.1, 0.13))
    c.solid(poly, SKIN, SKIN_SH, light=(-0.7, -0.5, 0.5), spec=0.6, shin=28, rim=RIM, rim_k=0.55, alpha=0.68, a_edge=0.97, tex=0.04, seed=21)
    for i in range(1, 8):
        k = int(len(ab) * i / 8.4)
        a = np.array(ab[k])
        tg = np.array(ab[min(k + 1, len(ab) - 1)]) - np.array(ab[max(k - 1, 0)])
        tg /= np.linalg.norm(tg) + 1e-6
        nr = np.array([-tg[1], tg[0]])
        arc = [tuple(a + nr * wid[k] * s * 0.5 * u + tg * 7 * s * (1 - u * u)) for u in np.linspace(-0.96, 0.96, 14)]
        c.line(arc, 4.2 * s, (0.28, 0.16, 0.06), alpha=0.55, blur=1)
        c.line([(x - 3 * s, y - 3 * s) for x, y in arc], 2.2 * s, (1.0, 0.96, 0.8), alpha=0.45, blur=0.8)
    tail = ab[-1]
    for sg in (-1, 1):
        c.solid(ell(tail[0] - 44 * s, tail[1] + sg * 28 * s, 66 * s, 17 * s, sg * 0.35), (0.96, 0.9, 0.72), (0.5, 0.4, 0.26), spec=0.4, alpha=0.7, a_edge=0.95, rim=RIM, rim_k=0.4)
    # đầu-ngực: sạm màu hơn (thấy muỗi trưởng thành đang hình thành bên trong)
    pts = ell(*T((14, -10)), 178 * s, 130 * s, rotation - 0.38)
    c.shadow(pts, 14, 20, 14, 0.22, (0.02, 0.1, 0.13))
    c.solid(pts, (0.84, 0.68, 0.46), (0.2, 0.12, 0.06), light=(-0.7, -0.6, 0.5), spec=0.7, shin=30, rim=RIM, rim_k=0.55, alpha=0.62, a_edge=0.98, tex=0.05, seed=17)
    # bên trong: mắt kép đen, cánh & chân gập lại thành các đường sẫm
    for (ex_, ey_, rx_, ry_) in ((-84, -52, 12, 15), (-40, -76, 11, 14)):
        e = T((ex_, ey_))
        c.solid(ell(e[0], e[1], rx_ * s, ry_ * s, rotation - 0.3), (0.12, 0.08, 0.07), (0.0, 0.0, 0.0), spec=0.9, shin=50, bulge=1.5, light=(-0.5, -0.7, 0.5))
    for q in range(9):
        e = T((np.random.default_rng(q).uniform(-120, 120), np.random.default_rng(q + 50).uniform(-90, 70)))
        c.ellipse(e[0], e[1], np.random.default_rng(q + 9).uniform(20, 46) * s, np.random.default_rng(q + 19).uniform(14, 30) * s, (0.28, 0.2, 0.14), alpha=0.3, blur=8)
    for q in range(3):
        a_, b_ = T((-150 + q * 30, 66 + q * 6)), T((-70 + q * 42, 124 + q * 10))
        c.line([a_, ((a_[0] + b_[0]) / 2 + 10 * s, (a_[1] + b_[1]) / 2), b_], 5 * s, (0.4, 0.3, 0.2), alpha=0.22, blur=1.4)
    wg = [T(p) for p in catmull([(60, -80), (110, 0), (120, 90), (86, 150)], 12)]
    c.line(wg, 0, (0.55, 0.45, 0.35), taper=(34 * s, 14 * s), alpha=0.22, blur=3)
    for q in range(18):
        a = np.random.default_rng(q).uniform(0, 2 * math.pi)
        b = T((math.cos(a) * 160, math.sin(a) * 124 - 10))
        hair(c, b, a + rotation, 60 * s, 3 * s, a=0.55)
