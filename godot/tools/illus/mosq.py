"""Vẽ muỗi vằn (Aedes aegypti) nhìn nghiêng: thân đen, vằn trắng ở chân/bụng, hoa văn hình đàn lia ở ngực."""
import math
import numpy as np
from lib import *

BLACK = (0.06, 0.05, 0.06)
DARK = (0.16, 0.13, 0.12)
WHITE = (0.96, 0.95, 0.9)


def make_T(cx, cy, s, tilt, flip):
    ca, sa = math.cos(tilt), math.sin(tilt)

    def T(p):
        x, y = p
        if flip:
            x = -x
        x, y = x * s, y * s
        return (cx + x * ca - y * sa, cy + x * sa + y * ca)
    return T


def leg(c, T, joints, w0, band=True, col=BLACK, alpha=1.0, s=1.0):
    pts = catmull([T(p) for p in joints], 16)
    poly = tube(pts, [24 * s, 6.5 * s])
    base = tuple(np.array(col) * 1.6 + 0.04)
    c.solid(poly, base, (0.0, 0.0, 0.0), spec=0.55, shin=18, rim=(0.7, 0.6, 0.5), rim_k=0.25, alpha=alpha, tex=0.06, seed=3)
    if band:
        n = len(pts)
        for f in (0.5, 0.74, 0.88):
            k = int(n * f)
            seg = pts[max(k - 2, 0): min(k + 3, n)]
            wdt = (22 - 15 * f) * s
            c.solid(tube(seg, [wdt, wdt]), (0.96, 0.94, 0.86), (0.4, 0.38, 0.33), spec=0.35, shin=14, alpha=alpha, tex=0.03)


def wing(c, T, root, tip, curve, s=1.0, alpha=0.34):
    rx, ry = root
    tx, ty = tip
    mid1 = ((rx * 2 + tx) / 3 + curve[0], (ry * 2 + ty) / 3 + curve[1])
    mid2 = ((rx + tx * 2) / 3 + curve[0] * 0.6, (ry + ty * 2) / 3 + curve[1] * 0.6)
    top = [root, mid1, mid2, tip]
    L = math.hypot(tx - rx, ty - ry)
    prof = [(0.0, 8), (0.15, 40), (0.5, 70), (0.85, 46), (1.0, 6)]
    spine = catmull(top, 20)
    n = len(spine)
    wds = np.interp(np.linspace(0, 1, n), [p[0] for p in prof], [p[1] * L / 600.0 for p in prof])
    poly = tube([T(p) for p in spine], list(wds * s))
    c.poly(poly, lin(T(root), T(tip), (0.85, 0.92, 0.95), (0.7, 0.8, 0.9)), alpha)
    # gân cánh
    for off in (-0.4, -0.15, 0.1, 0.35):
        vein = []
        for i in range(n):
            nx = spine[i]
            vein.append(T((nx[0], nx[1] + off * wds[i] / max(s * 0.6, 0.01) * 0.0)))
        c.line([T(p) for p in spine[:: 2]], 1.6 * s, (0.35, 0.4, 0.45), alpha=0.35)
        break
    c.line([T(p) for p in spine], 2.4 * s, (0.3, 0.33, 0.36), alpha=0.55)
    c.poly(poly, (1, 1, 1), 0.10, blur=3 * s, mode='add')


def mosquito(c, cx, cy, s=1.0, tilt=0.0, flip=False, sex='F', blood=0.0, pose='stand', legs_spread=1.0, wings_up=1.0):
    T = make_T(cx, cy, s, tilt, flip)
    sc = s
    # ---------- chân sau (xa) ----------
    far = [
        [(70, 50), (10, 170), (-60, 300), (-90, 410)],
        [(150, 70), (120, 220), (110, 340), (120, 430)],
        [(230, 70), (330, 190), (420, 320), (470, 420)],
    ]
    near = [
        [(60, 56), (-30, 150), (-150, 250), (-210, 410)],
        [(150, 76), (200, 220), (250, 330), (280, 430)],
        [(235, 76), (320, 160), (500, 230), (640, 300)],
    ]
    if pose == 'fly':
        far = [[(70, 50), (-30, 140), (-90, 250), (-110, 330)], [(150, 70), (90, 190), (60, 320), (50, 400)], [(230, 70), (330, 170), (460, 300), (540, 380)]]
        near = [[(60, 56), (-60, 130), (-180, 200), (-250, 300)], [(150, 76), (160, 210), (170, 340), (190, 440)], [(235, 76), (340, 150), (500, 200), (640, 250)]]
    if pose == 'feed':
        far = [[(70, 50), (-20, 150), (-70, 260), (-80, 330)], [(150, 70), (110, 200), (60, 300), (30, 360)], [(230, 70), (330, 180), (400, 260), (420, 330)]]
        near = [[(60, 56), (-30, 140), (-110, 230), (-150, 330)], [(150, 76), (160, 210), (170, 300), (160, 360)], [(235, 76), (330, 160), (450, 250), (520, 330)]]
    for j in far:
        leg(c, T, [(x * 1, y * legs_spread if y > 100 else y) for x, y in j], 0, col=(0.1, 0.09, 0.1), alpha=0.75, s=sc)
    # ---------- bụng ----------
    ab = catmull([(250, -10), (360, 20), (480, 50), (610, 70), (700, 62)], 16)
    ab_poly = [T(p) for p in ab]
    wid = np.interp(np.linspace(0, 1, len(ab)), [0, 0.2, 0.55, 0.85, 1], [104, 112, 98, 72, 34])
    poly = tube(ab_poly, list(wid * sc))
    bcol = BLACK
    c.shadow(poly, 12, 18, 12, 0.2)
    c.solid(poly, (0.30, 0.26, 0.24), (0.02, 0.015, 0.02), spec=0.5, shin=22, rim=(0.8, 0.7, 0.55), rim_k=0.35, tex=0.14, seed=5)
    if blood > 0.01:
        # bụng căng đỏ khi no máu
        bw = wid * (1 + 0.5 * blood)
        poly2 = tube(ab_poly, list(bw * sc))
        c.solid(poly2, (0.92, 0.14, 0.16), (0.3, 0.01, 0.04), spec=0.8, shin=26, rim=(1, 0.5, 0.45), rim_k=0.5, alpha=0.96, a_edge=1.0, tex=0.03)
        for j in range(5):
            k = int(len(ab) * (0.18 + 0.17 * j))
            a, b = ab_poly[k], ab_poly[min(k + 1, len(ab) - 1)]
            c.line([(a[0], a[1] - bw[k] * sc * 0.5), (a[0] + 1, a[1] + bw[k] * sc * 0.5)], 7 * sc, (0.98, 0.78, 0.72), alpha=0.35)
    else:
        # vằn trắng ở gốc mỗi đốt bụng
        for j in range(5):
            f = 0.12 + 0.17 * j
            k = int(len(ab) * f)
            a = ab_poly[k]
            w2 = wid[k] * sc * 0.5
            nx = np.array(ab_poly[min(k + 1, len(ab) - 1)]) - np.array(ab_poly[max(k - 1, 0)])
            nx = nx / (np.linalg.norm(nx) + 1e-6)
            nr = np.array([-nx[1], nx[0]])
            arc = [tuple(np.array(a) + nr * w2 * u * 0.94 + nx * (-8 * sc) * (1 - u * u)) for u in np.linspace(-1, 1, 16)]
            c.solid(tube(arc, [16 * sc, 16 * sc]), (0.97, 0.95, 0.88), (0.45, 0.42, 0.36), spec=0.3, shin=14, tex=0.05, seed=j)
    # ---------- ngực ----------
    th = []
    for t in np.linspace(0, 2 * math.pi, 100, endpoint=False):
        th.append(T((150 + 158 * math.cos(t), -35 + 112 * math.sin(t) * (1.0 if math.sin(t) > 0 else 1.15))))
    c.shadow(th, 12, 18, 12, 0.2)
    c.solid(th, (0.42, 0.34, 0.28), (0.03, 0.02, 0.02), spec=0.55, shin=22, rim=(0.9, 0.8, 0.6), rim_k=0.4, tex=0.18, seed=8)
    # hoa văn đàn lia (hai vạch trắng cong) + vằn bên
    for sg in (-1, 1):
        arc = [T((150 + sg * (46 + 24 * math.sin(u * 1.2)) * 0.9 + (u - 0.5) * 0 , -120 + 130 * u + 0)) for u in np.linspace(0.05, 0.95, 18)]
        c.solid(tube(arc, [10 * sc, 8 * sc]), (0.96, 0.93, 0.84), (0.5, 0.45, 0.38), spec=0.25, shin=12, alpha=0.95, tex=0.08)
    c.solid(tube([T((150, -128)), T((150, -30))], [8 * sc, 8 * sc]), (0.92, 0.88, 0.8), (0.5, 0.45, 0.38), spec=0.2, alpha=0.8, tex=0.08)
    rngh = np.random.default_rng(4)
    for q in range(60):
        ang_ = rngh.uniform(0, 2 * math.pi)
        b0 = T((150 + 154 * math.cos(ang_), -35 + 108 * math.sin(ang_)))
        c.line([b0, (b0[0] + math.cos(ang_) * 18 * sc, b0[1] + math.sin(ang_) * 18 * sc)], 1.6 * sc, (0.1, 0.08, 0.07), alpha=0.7)
    for k in range(7):
        a = T((70 + k * 16, -115 + k * 4))
        c.ellipse(a[0], a[1], 2 * sc, 2 * sc, (0.9, 0.85, 0.8), alpha=0.4)
    # ---------- chân gần ----------
    for j in near:
        leg(c, T, [(x * 1, y * legs_spread if y > 100 else y) for x, y in j], 0, col=BLACK, alpha=1.0, s=sc)
    # ---------- đầu ----------
    hp = T((-60, 0))
    hd_ = np.array([T((-60 + 66 * math.cos(t), 62 * math.sin(t))) for t in np.linspace(0, 2 * math.pi, 90, endpoint=False)])
    c.solid(hd_, (0.4, 0.33, 0.28), (0.03, 0.02, 0.02), spec=0.5, shin=24, rim=(0.9, 0.8, 0.6), rim_k=0.35, tex=0.15, seed=12)
    # mắt kép
    ep = T((-78, -8))
    eye_ = np.array([(ep[0] + 44 * sc * math.cos(t), ep[1] + 50 * sc * math.sin(t)) for t in np.linspace(0, 2 * math.pi, 90, endpoint=False)])
    c.solid(eye_, (0.30, 0.34, 0.46), (0.0, 0.0, 0.015), spec=1.0, shin=60, rim=(0.5, 0.65, 0.9), rim_k=0.5, tex=0.2, seed=2, bulge=1.5, light=(-0.5, -0.75, 0.45))
    for k in range(40):  # ô mắt
        a = np.random.default_rng(k).uniform(0, 6.28)
        rr = np.random.default_rng(k + 99).uniform(0, 36)
        c.ellipse(ep[0] + math.cos(a) * rr * sc, ep[1] + math.sin(a) * rr * 1.1 * sc, 3.2 * sc, 3.2 * sc, (0.5, 0.58, 0.7), alpha=0.18)
    c.ellipse(ep[0] - 16 * sc, ep[1] - 20 * sc, 14 * sc, 8 * sc, (1, 1, 1), rot=-0.6, alpha=0.85, blur=1.5)
    c.ellipse(ep[0] + 10 * sc, ep[1] + 22 * sc, 7 * sc, 4 * sc, (0.8, 0.9, 1), rot=0.5, alpha=0.4, blur=1.5)
    # vòi (proboscis)
    if sex == 'F':
        pr = catmull([T((-100, 24)), T((-220, 70)), T((-330, 118)), T((-420, 150))], 14)
        c.solid(tube(pr, [15 * sc, 5 * sc]), (0.3, 0.26, 0.25), (0.0, 0.0, 0.0), spec=0.6, shin=20, rim=(0.8, 0.7, 0.6), rim_k=0.3, tex=0.05)
        # xúc biết (palps) ngắn
        pp = catmull([T((-96, 8)), T((-170, 36)), T((-230, 60))], 10)
        c.line(pp, 0, (0.12, 0.1, 0.1), taper=(11 * sc, 7 * sc))
    else:
        pr = catmull([T((-100, 24)), T((-200, 62)), T((-300, 104))], 14)
        c.line(pr, 0, (0.07, 0.06, 0.07), taper=(13 * sc, 5 * sc))
        # xúc biết dài, có chùm lông
        pp = catmull([T((-96, 8)), T((-200, 30)), T((-330, 70))], 12)
        c.line(pp, 0, (0.14, 0.12, 0.12), taper=(14 * sc, 9 * sc))
        for u in np.linspace(0.25, 1, 12):
            k = int(len(pp) * u) - 1
            base = pp[k]
            for sgn in (-1, 1):
                end = (base[0] + sgn * 8 * sc, base[1] + sgn * 36 * sc * (0.6 + u * 0.7))
                c.line([tuple(base), end], 0, (0.1, 0.09, 0.09), taper=(4 * sc, 0.8 * sc), alpha=0.8)
    # râu (antennae)
    an = catmull([T((-50, -50)), T((-110, -150)), T((-180, -250)), T((-250, -320))], 16)
    c.line(an, 0, (0.14, 0.12, 0.12), taper=(8 * sc, 3 * sc))
    for k in range(3, len(an), 2):
        base = an[k]
        if sex == 'M':
            for sgn in (-1, 1):
                L = (70 - 30 * k / len(an)) * sc
                end = (base[0] + sgn * L * 0.8 + 6 * sc, base[1] + sgn * (-L * 0.5))
                c.line([tuple(base), end], 0, (0.15, 0.13, 0.13), taper=(3 * sc, 0.8 * sc), alpha=0.8)
        else:
            c.ellipse(base[0], base[1], 3.4 * sc, 3.4 * sc, (0.9, 0.88, 0.85), alpha=0.7)
    # ---------- cánh ----------
    for (rt, tp, cv, al) in [((140, -118), (700, -330 * wings_up - 40 * (1 - wings_up)), (30, -70), 0.30), ((120, -112), (640, -290 * wings_up - 30 * (1 - wings_up)), (10, -40), 0.34)]:
        wing(c, T, rt, tp, cv, s=sc, alpha=al)
    # bóng nhẹ dưới thân (nếu đậu)
    return T
