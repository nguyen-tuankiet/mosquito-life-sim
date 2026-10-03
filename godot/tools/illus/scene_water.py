import math
import numpy as np
from lib import *

RNG = np.random.default_rng(7)


def underwater_bg(c, deep=(0.015, 0.14, 0.2), top=(0.30, 0.68, 0.72), surface_y=170):
    c.poly([(0, 0), (c.w, 0), (c.w, c.h), (0, c.h)], lin((0, surface_y), (0, c.h), top, deep, stops=[(0.35, (0.10, 0.42, 0.5))]))
    # bề mặt nước nhìn từ dưới: dải sáng bạc lượn sóng
    xs = np.linspace(0, c.w, 200)
    ys = surface_y + 18 * np.sin(xs / 140.0) + 8 * np.sin(xs / 53.0 + 1.3)
    c.poly(list(zip(xs, ys)) + [(c.w, 0), (0, 0)], (0.88, 0.97, 0.97), 0.95)
    c.poly(list(zip(xs, ys + 26)) + list(zip(xs[::-1], ys[::-1])), (0.7, 0.95, 0.95), 0.5, blur=10)
    # tia nắng
    for i in range(9):
        x = RNG.uniform(0, c.w)
        w = RNG.uniform(60, 190)
        sk = RNG.uniform(-260, -120)
        pts = [(x, surface_y), (x + w, surface_y), (x + w * 2.2 + sk, c.h * 0.95), (x + sk * 1.2, c.h * 0.95)]
        c.poly(pts, (0.75, 1.0, 0.95), RNG.uniform(0.035, 0.08), blur=26, mode='add')
    # hạt lơ lửng
    for i in range(260):
        x, y = RNG.uniform(0, c.w), RNG.uniform(surface_y + 30, c.h)
        r = RNG.uniform(1.2, 4.2)
        c.ellipse(x, y, r, r, (0.9, 1, 0.95), alpha=RNG.uniform(0.15, 0.5))


def plants(c, base_y, n=14, h=(280, 640), col=(0.12, 0.45, 0.22), dark=(0.04, 0.2, 0.12), seed=3):
    r = np.random.default_rng(seed)
    for i in range(n):
        x = r.uniform(-50, c.w + 50)
        hh = r.uniform(*h)
        sway = r.uniform(-120, 120)
        pts = catmull([(x, base_y), (x + sway * 0.3, base_y - hh * 0.4), (x + sway, base_y - hh * 0.75), (x + sway * 1.2, base_y - hh)], 12)
        shade = r.uniform(0, 1)
        cc = tuple(np.array(col) * (1 - shade) + np.array(dark) * shade)
        c.line(pts, 0, cc, taper=(r.uniform(16, 30), 3), alpha=r.uniform(0.7, 0.95))


def bottom(c, y0):
    c.poly([(0, y0), (c.w, y0 + 20), (c.w, c.h), (0, c.h)], lin((0, y0), (0, c.h), (0.2, 0.3, 0.26), (0.03, 0.08, 0.08)))
    for i in range(70):
        x, y = RNG.uniform(0, c.w), RNG.uniform(y0 + 10, c.h)
        r = RNG.uniform(10, 46)
        c.ellipse(x, y, r, r * RNG.uniform(0.45, 0.7), lin((x, y - r), (x, y + r), (0.5, 0.5, 0.45), (0.12, 0.14, 0.13)), alpha=0.85)


def bubble(c, x, y, r, a=0.8):
    c.ellipse(x, y, r, r, radial((x - r * 0.3, y - r * 0.3), r * 1.3, (0.85, 1, 1), (0.35, 0.8, 0.85)), alpha=0.28 * a)
    c.ellipse(x, y, r, r, (0.9, 1, 1), alpha=0.0)
    # viền
    t = np.linspace(0, 2 * math.pi, 80)
    ring = [(x + r * math.cos(a_), y + r * math.sin(a_)) for a_ in t]
    c.line(ring, max(2, r * 0.07), (0.9, 1, 1), alpha=0.55 * a)
    c.ellipse(x - r * 0.35, y - r * 0.4, r * 0.28, r * 0.14, (1, 1, 1), rot=-0.7, alpha=0.9 * a, blur=1)


def amber_segment(c, cx, cy, rx, ry, ang, k=0.0):
    """Một đốt thân lăng quăng (hổ phách trong mờ)."""
    base = (0.93, 0.74, 0.40)
    shade = (0.58, 0.34, 0.14)
    t = np.linspace(0, 2 * math.pi, 100, endpoint=False)
    ca, sa = math.cos(ang), math.sin(ang)
    pts = np.stack([cx + rx * np.cos(t) * ca - ry * np.sin(t) * sa, cy + rx * np.cos(t) * sa + ry * np.sin(t) * ca], 1)
    # sáng ở phía trên
    c.shaded(pts, base, shade, light=(-0.35, -0.95), spec=0.55)
    # gờ tối giữa các đốt
    c.line([(cx - rx * 0.95 * ca + 0 * sa, cy - rx * 0.95 * sa), (cx - rx * 0.95 * ca, cy - rx * 0.95 * sa)], 1, shade)


def larva(c, ox, oy, scale=1.0, rotation=0.0, seed=5):
    """Lăng quăng treo đầu xuống, ống thở lên mặt nước. (ox,oy) là điểm gắn ống thở (trên cùng)."""
    r = np.random.default_rng(seed)
    S = scale

    def T(p):
        x, y = p
        xr, yr = rot((x * S, y * S), rotation)
        return (ox + xr, oy + yr)

    # trục thân: từ ống thở xuống đầu (toạ độ cục bộ)
    spine = catmull([(0, 0), (6, 70), (24, 170), (30, 300), (6, 430), (-40, 540), (-110, 620), (-190, 668)], 30)
    n = len(spine)
    tang = np.gradient(spine, axis=0)
    tang /= np.linalg.norm(tang, axis=1, keepdims=True)
    # bóng/glow mờ phía sau
    glow = tube([T(p) for p in spine[20:]], [70 * S] * (n - 20))
    c.poly(glow, (0.9, 0.7, 0.35), 0.10, blur=40 * S, mode='add')
    # ống thở (siphon) – ngắn, tối, chạm mặt nước
    sp = [T(p) for p in catmull([(0, -34), (3, 20), (6, 70), (9, 110)], 10)]
    c.line(sp, 0, (0.42, 0.24, 0.1), taper=(20 * S, 34 * S))
    c.line([(x - 3 * S, y) for x, y in sp], 0, (0.8, 0.55, 0.28), taper=(5 * S, 9 * S), alpha=0.7)
    # lông ở đốt cuối
    # abdomen: 8 đốt
    segs = []
    t0, t1 = 20, int(n * 0.66)
    for i in range(8):
        k = t0 + (t1 - t0) * i / 7.0
        k = int(k)
        p = spine[k]
        wid = 36 + 5 * i * 0.5
        segs.append((p, tang[k], wid))
    # hậu môn / mang
    gp = T(spine[18] + np.array([0, -4]))
    for dx in (-30, 30):
        c.ellipse(gp[0] + dx * S, gp[1] + 6 * S, 12 * S, 24 * S, lin((0, 0), (0, 1), (0.95, 0.85, 0.6), (0.7, 0.5, 0.3)), rot=0.4 * (1 if dx > 0 else -1), alpha=0.85)
    # lông tơ hai bên (vẽ trước thân)
    for (p, tg, wid) in segs:
        q = T(p)
        nrm = np.array([-tg[1], tg[0]])
        for side in (-1, 1):
            for j in range(7):
                a = r.uniform(-0.5, 0.5)
                L = r.uniform(40, 96) * S
                d = rot((nrm[0] * side, nrm[1] * side), a)
                d = rot((d[0], d[1]), 0)
                base = (q[0] + nrm[0] * side * wid * S * 0.45, q[1] + nrm[1] * side * wid * S * 0.45)
                end = (base[0] + d[0] * L, base[1] + d[1] * L)
                c.line([base, ((base[0] + end[0]) / 2 + r.uniform(-6, 6), (base[1] + end[1]) / 2 + r.uniform(-6, 6)), end], 0, (0.35, 0.2, 0.1), taper=(3.5 * S, 0.8 * S), alpha=0.8)
    # thân liền một khối: bụng 8 đốt + ngực phình to, tô gradient hổ phách trong mờ
    i0, i1 = 16, int(n * 0.78)
    body_pts = [T(p) for p in spine[i0:i1]]
    m_ = len(body_pts)
    prof = [(0.0, 44), (0.15, 54), (0.6, 72), (1.0, 92)]
    wid = np.interp(np.linspace(0, 1, m_), [p[0] for p in prof], [p[1] * S for p in prof])
    poly = tube(body_pts, list(wid))
    c.shaded(poly, (0.97, 0.80, 0.46), (0.52, 0.28, 0.1), light=(-0.9, -0.35), spec=0.45)
    # ruột (đường tối chạy dọc thân, thấy xuyên qua da)
    c.line(body_pts[: int(m_ * 0.82)], 0, (0.45, 0.22, 0.08), taper=(12 * S, 30 * S), alpha=0.32, blur=2)
    # vạch ngăn đốt bụng
    for i in range(1, 9):
        k = int(m_ * (0.02 + 0.92 * i / 8.6))
        p = np.array(body_pts[k])
        tg = np.array(body_pts[min(k + 1, m_ - 1)]) - np.array(body_pts[max(k - 1, 0)])
        tg = tg / (np.linalg.norm(tg) + 1e-6)
        nr = np.array([-tg[1], tg[0]])
        w_ = wid[k] * 0.5
        arc = [tuple(p + nr * w_ * u + tg * (6 * S) * (1 - u * u)) for u in np.linspace(-0.95, 0.95, 14)]
        c.line(arc, 3.2 * S, (0.40, 0.2, 0.07), alpha=0.6)
        c.line([(x - 2.5 * S, y - 2.5 * S) for x, y in arc], 2.0 * S, (1.0, 0.92, 0.7), alpha=0.35)
    # vệt sáng dọc phía được chiếu
    c.line([(x - wid[min(j, m_ - 1)] * 0.22, y) for j, (x, y) in enumerate(body_pts)][: int(m_ * 0.9)], 0, (1, 0.95, 0.8), taper=(4 * S, 14 * S), alpha=0.30, blur=3)
    # đường viền ngực
    kth_i = int(n * 0.86)
    pth = T(spine[kth_i])
    tgt_ = tang[kth_i]
    ang_ = math.atan2(tgt_[1], tgt_[0]) + math.pi / 2 + rotation
    tt = np.linspace(0, 2 * math.pi, 120, endpoint=False)
    tp = np.stack([pth[0] + 112 * S * np.cos(tt) * math.cos(ang_) - 100 * S * np.sin(tt) * math.sin(ang_), pth[1] + 112 * S * np.cos(tt) * math.sin(ang_) + 100 * S * np.sin(tt) * math.cos(ang_)], 1)
    c.shaded(tp, (0.99, 0.84, 0.5), (0.5, 0.26, 0.09), light=(-0.8, -0.55), spec=0.5)
    c.ellipse(pth[0] + 12 * S, pth[1] + 16 * S, 54 * S, 38 * S, (0.45, 0.22, 0.08), alpha=0.25, blur=6)
    for j in range(18):
        a = r.uniform(0, 2 * math.pi)
        bx, by = pth[0] + math.cos(a) * 110 * S, pth[1] + math.sin(a) * 100 * S
        L = r.uniform(30, 70) * S
        c.line([(bx, by), (bx + math.cos(a) * L, by + math.sin(a) * L + r.uniform(-8, 8))], 0, (0.3, 0.17, 0.08), taper=(3 * S, 0.8 * S), alpha=0.6)
    # đầu
    khd = int(n * 0.93)
    phd = T(spine[khd] + np.array([-30, 50]))
    c.ellipse(phd[0], phd[1], 78 * S, 70 * S, lin((phd[0], phd[1] - 56 * S), (phd[0], phd[1] + 56 * S), (0.72, 0.42, 0.18), (0.32, 0.17, 0.08)), rot=0.2)
    c.ellipse(phd[0] - 16 * S, phd[1] - 22 * S, 24 * S, 12 * S, (1, 0.9, 0.7), rot=-0.5, alpha=0.5, blur=3)
    # mắt (hai chấm đen bóng)
    for dx in (-26, 26):
        ex, ey = phd[0] + dx * S, phd[1] - 6 * S
        c.ellipse(ex, ey, 17 * S, 15 * S, radial((ex - 4 * S, ey - 4 * S), 20 * S, (0.12, 0.1, 0.1), (0.0, 0.0, 0.0)))
        c.ellipse(ex - 5 * S, ey - 5 * S, 4.5 * S, 3.5 * S, (1, 1, 1), alpha=0.9)
    # râu
    for sgn in (-1, 1):
        a = [(phd[0] + sgn * 40 * S, phd[1] - 24 * S), (phd[0] + sgn * 80 * S, phd[1] - 62 * S), (phd[0] + sgn * 96 * S, phd[1] - 110 * S)]
        c.line(catmull(a, 10), 0, (0.45, 0.25, 0.1), taper=(11 * S, 4 * S))
    # chổi miệng (lông ăn)
    for j in range(22):
        a = math.pi / 2 + r.uniform(-0.8, 0.8)
        bx, by = phd[0] + r.uniform(-30, 30) * S, phd[1] + 44 * S
        L = r.uniform(40, 84) * S
        c.line([(bx, by), (bx + math.cos(a) * L * 0.6 + r.uniform(-6, 6), by + math.sin(a) * L)], 0, (0.9, 0.78, 0.55), taper=(4 * S, 0.8 * S), alpha=0.75)


def build_larva_scene(path):
    c = Canvas(bg=(0.1, 0.4, 0.45))
    underwater_bg(c)
    plants(c, 1300, n=16, h=(380, 800), seed=11)
    bottom(c, 1210)
    plants(c, 1440, n=9, h=(240, 460), col=(0.16, 0.55, 0.26), seed=19)
    # lăng quăng chính (nằm giữa-phải để chừa chỗ chữ bên trái)
    c.blur_region(2.2)
    import organisms
    organisms.larva(c, 1780, 235, scale=1.12)
    # lăng quăng nhỏ phía sau mờ
    sub = Canvas(c.w, c.h)
    sub.a[:] = 0
    for (x, y, s) in [(1160, 260, 0.52, ), (2260, 330, 0.42), (900, 520, 0.38)]:
        pass
    # bong bóng
    for i in range(34):
        bubble(c, RNG.uniform(1100, 2500), RNG.uniform(250, 1150), RNG.uniform(6, 26), RNG.uniform(0.4, 1.0))
    for i in range(7):
        bubble(c, 1760 + RNG.uniform(-50, 120), 330 + RNG.uniform(-60, 80), RNG.uniform(10, 24))
    c.vignette(0.38)
    c.noise_grain(0.008)
    c.save(path)


if __name__ == '__main__':
    import sys
    build_larva_scene(sys.argv[1] if len(sys.argv) > 1 else 'larva.jpg')
