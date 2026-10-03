import math, sys, os
import numpy as np
from lib import *
from mosq import mosquito, make_T
import scene_water as sw

R = np.random.default_rng(21)
OUT = sys.argv[1] if len(sys.argv) > 1 else '.'


def full(c, fill):
    c.poly([(0, 0), (c.w, 0), (c.w, c.h), (0, c.h)], fill)


def bokeh(c, region, n, cols, r=(30, 120), a=(0.05, 0.16)):
    x0, y0, x1, y1 = region
    for i in range(n):
        col = cols[i % len(cols)]
        rr = R.uniform(*r)
        c.ellipse(R.uniform(x0, x1), R.uniform(y0, y1), rr, rr, col, alpha=R.uniform(*a), blur=3, mode='add')


def palm(c, x, y, h, lean, col, scale=1.0):
    trunk = catmull([(x, y), (x + lean * 0.3, y - h * 0.5), (x + lean, y - h)], 16)
    c.line(trunk, 0, col, taper=(30 * scale, 14 * scale))
    tip = trunk[-1]
    for k in range(11):
        a = -math.pi / 2 + (k - 5) * 0.36 + R.uniform(-0.05, 0.05)
        L = 250 * scale * (0.85 + 0.25 * R.random())
        side = 1 if a > -math.pi / 2 else -1
        pts = catmull([tuple(tip), (tip[0] + math.cos(a) * L * 0.5, tip[1] + math.sin(a) * L * 0.5 - 30 * scale), (tip[0] + math.cos(a) * L * 0.85, tip[1] + math.sin(a) * L * 0.8 + 60 * scale), (tip[0] + math.cos(a) * L, tip[1] + math.sin(a) * L + 150 * scale)], 14)
        c.line(pts, 0, col, taper=(9 * scale, 2 * scale))
        for i in range(2, len(pts) - 1, 2):
            p = pts[i]
            ln = 70 * scale * (1 - i / len(pts)) + 12
            for sg in (-1, 1):
                c.line([tuple(p), (p[0] + sg * ln * 0.55, p[1] + ln)], 0, col, taper=(6 * scale, 1.2 * scale))


def house(c, x, y, w, h, wall, roof):
    c.poly([(x, y), (x + w, y), (x + w, y - h), (x, y - h)], wall)
    c.poly([(x - 26, y - h), (x + w + 26, y - h), (x + w * 0.82, y - h - 82), (x + w * 0.18, y - h - 82)], roof)
    c.poly([(x + w * 0.4, y), (x + w * 0.6, y), (x + w * 0.6, y - h * 0.6), (x + w * 0.4, y - h * 0.6)], tuple(np.array(wall) * 0.55))


# ============================================================= TITLE
def title():
    c = Canvas()
    full(c, lin((0, 0), (0, c.h * 0.75), (0.16, 0.30, 0.50), (0.98, 0.62, 0.34), stops=[(0.55, (0.55, 0.62, 0.72))]))
    c.add_glow(1900, 760, 800, (1, 0.8, 0.45), 0.9)
    c.ellipse(1900, 760, 78, 78, (1, 0.95, 0.75))
    for i in range(7):
        x, y = R.uniform(100, 2300), R.uniform(80, 520)
        for k in range(5):
            c.ellipse(x + k * 90 - 180, y + R.uniform(-20, 20), R.uniform(90, 170), R.uniform(24, 46), (1, 0.82, 0.74), alpha=0.35, blur=14)
    # đồi xa
    for (yy, col, amp) in [(880, (0.35, 0.42, 0.50), 80), (940, (0.20, 0.30, 0.34), 60), (990, (0.10, 0.2, 0.2), 40)]:
        xs = np.linspace(0, c.w, 120)
        ys = yy - amp * np.sin(xs / 330 + yy) - amp * 0.4 * np.sin(xs / 120)
        c.poly(list(zip(xs, ys)) + [(c.w, c.h), (0, c.h)], col)
    # ruộng/ao phản chiếu
    c.poly([(0, 1040), (c.w, 1040), (c.w, c.h), (0, c.h)], lin((0, 1040), (0, c.h), (0.95, 0.60, 0.34), (0.10, 0.2, 0.25)))
    for i in range(36):
        y = R.uniform(1060, 1430)
        x = R.uniform(0, c.w)
        c.line([(x, y), (x + R.uniform(120, 360), y)], 3, (1, 0.85, 0.55), alpha=R.uniform(0.1, 0.35))
    # nhà & dừa bóng tối
    sil = (0.06, 0.1, 0.12)
    for (x, w_, h_) in [(280, 220, 120), (560, 180, 100), (1240, 240, 130), (1620, 190, 110)]:
        house(c, x, 1040, w_, h_, (0.1, 0.13, 0.14), (0.2, 0.1, 0.08))
    for (x, h_, l) in [(140, 520, -80), (430, 420, 60), (1100, 480, -50), (1500, 560, 90), (2050, 600, -90), (2330, 520, 60)]:
        palm(c, x, 1050, h_, l, sil, 1.0)
    # phản chiếu mờ
    c.vignette(0.35)
    c.noise_grain(0.006)
    c.save(os.path.join(OUT, 'i_title.jpg'))


# ============================================================= EGG
def egg():
    c = Canvas()
    # nền bokeh xanh phía sau
    full(c, lin((0, 0), (0, c.h), (0.42, 0.6, 0.28), (0.14, 0.28, 0.12)))
    bokeh(c, (0, 0, c.w, 700), 40, [(1, 0.95, 0.5), (0.7, 1, 0.5), (1, 1, 0.8)], r=(30, 130))
    # thành chum gốm
    wall_y = 920
    c.poly([(0, 0), (c.w, 0), (c.w, wall_y + 10), (0, wall_y - 12)], lin((0, 0), (0, wall_y), (0.62, 0.34, 0.2), (0.40, 0.19, 0.1), stops=[(0.5, (0.55, 0.28, 0.16))]))
    # vân đất nung
    for i in range(420):
        x, y = R.uniform(0, c.w), R.uniform(0, wall_y)
        c.ellipse(x, y, R.uniform(6, 40), R.uniform(2, 8), (0.3, 0.14, 0.07), alpha=R.uniform(0.04, 0.16), blur=2)
    for i in range(160):
        x, y = R.uniform(0, c.w), R.uniform(0, wall_y)
        c.ellipse(x, y, R.uniform(3, 14), R.uniform(3, 9), (0.8, 0.5, 0.32), alpha=R.uniform(0.05, 0.15))
    # rêu ẩm sát mực nước
    xs = np.linspace(0, c.w, 160)
    wy = wall_y - 6 * np.sin(xs / 150) + 6
    c.poly(list(zip(xs, wy - 140 - 40 * np.sin(xs / 80))) + list(zip(xs[::-1], wy[::-1] + 6)), (0.15, 0.25, 0.08), 0.3, blur=24)
    # nước
    c.poly(list(zip(xs, wy)) + [(c.w, c.h), (0, c.h)], lin((0, wall_y), (0, c.h), (0.42, 0.72, 0.72), (0.04, 0.2, 0.26), stops=[(0.2, (0.2, 0.52, 0.56))]), 0.97)
    # ánh sáng phản chiếu trên mặt nước
    for i in range(40):
        x, y = R.uniform(0, c.w), R.uniform(wall_y + 30, c.h)
        c.line([(x, y), (x + R.uniform(80, 340), y + R.uniform(-4, 4))], 3, (0.9, 1, 1), alpha=R.uniform(0.06, 0.22), blur=1)
    # khum nước (meniscus) – dải sáng
    c.poly(list(zip(xs, wy - 2)) + list(zip(xs[::-1], wy[::-1] + 14)), (0.9, 1, 0.97), 0.7, blur=3)
    # trứng Aedes: đen bóng, hình thuôn, đẻ rời thành hàng sát mép nước
    eggs = []
    for row in range(3):
        for i in range(14):
            x = 560 + i * 118 + R.uniform(-18, 18) + row * 48
            y = wall_y - 100 - row * 150 + R.uniform(-8, 8) + 6 * math.sin(x / 150)
            eggs.append((x, y, R.uniform(-0.3, 0.3) + (-0.08 if x < 1200 else 0.08)))
    eggs.sort(key=lambda e: e[1])
    for (x, y, a) in eggs:
        L, Wd = 176, 62
        # bóng đổ
        c.ellipse(x + 12, y + 20, Wd * 0.7, 22, (0.1, 0.04, 0.02), alpha=0.35, blur=6)
        t = np.linspace(0, 2 * math.pi, 80, endpoint=False)
        pts = []
        for tt in t:
            u = math.cos(tt)
            v = math.sin(tt)
            # hình quả trứng thuôn, một đầu nhọn hơn
            rx = Wd * 0.5 * (1 - 0.25 * u)
            pts.append((x + math.cos(a) * rx * v - math.sin(a) * (L / 2) * u, y + math.sin(a) * rx * v + math.cos(a) * (L / 2) * u))
        c.shaded(pts, (0.34, 0.3, 0.3), (0.02, 0.02, 0.02), light=(-0.8, -0.6), spec=0.85)
        # hoa văn lưới mờ trên vỏ
        for k in range(4):
            yy = y - 44 + k * 26
            c.line([(x - 18 * math.cos(a), yy), (x + 18 * math.cos(a), yy + 3)], 2, (0.55, 0.52, 0.5), alpha=0.22)
        c.ellipse(x - 14, y - 34, 8, 36, (1, 1, 1), rot=a, alpha=0.55, blur=2)
    # giọt nước, bong bóng
    for i in range(30):
        x, y = R.uniform(0, c.w), R.uniform(wall_y + 40, c.h - 40)
        sw.bubble(c, x, y, R.uniform(4, 18), R.uniform(0.3, 0.8))
    c.vignette(0.4)
    c.noise_grain(0.007)
    c.save(os.path.join(OUT, 'i_egg.jpg'))


# ============================================================= LARVA
def larva():
    sw.build_larva_scene(os.path.join(OUT, 'i_larva.jpg'))


# ============================================================= PUPA
def pupa_shape(c, ox, oy, s=1.0, rotation=0.0):
    def T(p):
        x, y = rot((p[0] * s, p[1] * s), rotation)
        return (ox + x, oy + y)
    # ống thở (kèn) hai cái dựng lên mặt nước
    for dx in (-40, 36):
        tr = [T(p) for p in catmull([(dx, -110), (dx - 8, -200), (dx - 6, -280), (dx - 2, -330)], 10)]
        c.line(tr, 0, (0.55, 0.32, 0.14), taper=(26 * s, 40 * s))
        c.ellipse(tr[-1][0], tr[-1][1], 24 * s, 9 * s, (0.95, 0.85, 0.65))
    # bụng cong (dưới) + mái chèo đuôi
    ab = [T(p) for p in catmull([(70, 90), (100, 210), (60, 320), (-30, 390), (-120, 395), (-190, 360)], 24)]
    wid = np.interp(np.linspace(0, 1, len(ab)), [0, 0.5, 1], [150, 110, 36])
    poly = tube(ab, list(wid * s))
    c.shaded(poly, (0.98, 0.78, 0.42), (0.48, 0.24, 0.08), light=(-0.8, -0.5), spec=0.4)
    for i in range(1, 8):
        k = int(len(ab) * i / 8.4)
        a = np.array(ab[k])
        tg = np.array(ab[min(k + 1, len(ab) - 1)]) - np.array(ab[max(k - 1, 0)])
        tg /= np.linalg.norm(tg) + 1e-6
        nr = np.array([-tg[1], tg[0]])
        arc = [tuple(a + nr * wid[k] * s * 0.5 * u + tg * 6 * s * (1 - u * u)) for u in np.linspace(-0.95, 0.95, 12)]
        c.line(arc, 3 * s, (0.4, 0.2, 0.07), alpha=0.6)
    tail = ab[-1]
    for sg in (-1, 1):
        c.ellipse(tail[0] - 40 * s, tail[1] + sg * 26 * s, 62 * s, 16 * s, (0.95, 0.82, 0.55), rot=sg * 0.35, alpha=0.9)
    # đầu-ngực phình to
    pts = []
    for t in np.linspace(0, 2 * math.pi, 100, endpoint=False):
        pts.append(T((190 * math.cos(t) * 0.95, 160 * math.sin(t) * 0.95 - 10)))
    c.shaded(pts, (1.0, 0.86, 0.52), (0.5, 0.26, 0.09), light=(-0.7, -0.7), spec=0.6)
    # mắt (đốm đen) & vân
    for dx in (-70, 30):
        e = T((dx, -50))
        c.ellipse(e[0], e[1], 17 * s, 21 * s, radial((e[0] - 6 * s, e[1] - 8 * s), 44 * s, (0.3, 0.18, 0.12), (0.02, 0.01, 0.01)))
        c.ellipse(e[0] - 5 * s, e[1] - 7 * s, 4.5 * s, 3.4 * s, (1, 1, 1), alpha=0.85)
    for k in range(5):
        a_ = T((-120 + k * 35, 60 + 6 * k))
        c.line([a_, (a_[0] + 10 * s, a_[1] + 40 * s)], 3 * s, (0.4, 0.2, 0.07), alpha=0.35)
    # chân/vòi gập
    c.line([T((-110, 70)), T((-60, 130)), T((10, 160)), T((60, 130))], 0, (0.55, 0.32, 0.14), taper=(10 * s, 6 * s), alpha=0.8)


def pupa():
    c = Canvas(bg=(0.1, 0.4, 0.45))
    sw.underwater_bg(c)
    sw.plants(c, 1300, n=14, h=(380, 800), seed=31)
    sw.bottom(c, 1210)
    c.blur_region(2.2)
    import organisms
    organisms.pupa(c, 1800, 560, 1.12, 0.0)
    for i in range(30):
        sw.bubble(c, R.uniform(1100, 2500), R.uniform(250, 1150), R.uniform(6, 24), R.uniform(0.4, 1.0))
    c.vignette(0.4)
    c.noise_grain(0.008)
    c.save(os.path.join(OUT, 'i_pupa.jpg'))


# ============================================================= EMERGE
def emerge():
    c = Canvas()
    full(c, lin((0, 0), (0, 900), (0.62, 0.82, 0.9), (0.85, 0.93, 0.8)))
    bokeh(c, (0, 0, c.w, 900), 36, [(1, 1, 0.85), (0.8, 1, 0.7)], r=(30, 110))
    # lá cây mờ ở phía sau
    for i in range(7):
        x = R.uniform(0, c.w)
        c.ellipse(x, R.uniform(80, 520), R.uniform(160, 340), R.uniform(70, 130), (0.28, 0.5, 0.2), rot=R.uniform(-0.6, 0.6), alpha=0.5, blur=26)
    sy = 960
    xs = np.linspace(0, c.w, 200)
    sur = sy + 5 * np.sin(xs / 90)
    c.poly(list(zip(xs, sur)) + [(c.w, c.h), (0, c.h)], lin((0, sy), (0, c.h), (0.30, 0.62, 0.62), (0.05, 0.22, 0.28)), 0.97)
    c.poly(list(zip(xs, sur - 2)) + list(zip(xs[::-1], sur[::-1] + 14)), (0.95, 1, 1), 0.7, blur=2)
    # phản chiếu bầu trời + vệt sáng
    for i in range(26):
        x, y = R.uniform(0, c.w), R.uniform(sy + 30, c.h)
        c.line([(x, y), (x + R.uniform(80, 360), y)], 3, (0.95, 1, 1), alpha=R.uniform(0.05, 0.2))
    # vỏ nhộng nổi
    import organisms
    organisms.pupa(c, 760, sy - 70, 0.62, 1.2)
    c.poly(list(zip(xs[:90], sur[:90] - 1)), (1, 1, 1), 0.0)
    # sóng gợn quanh chân muỗi & vỏ nhộng
    def ripple(x, y, r):
        t = np.linspace(0, 2 * math.pi, 100)
        c.line([(x + r * math.cos(a), y + r * 0.14 * math.sin(a)) for a in t], 3, (1, 1, 1), alpha=0.55)
    for r_ in (60, 110, 170):
        ripple(760, sy + 20, r_)
    # muỗi vừa chui ra: cánh còn nhăn, thân đứng trên mặt nước
    T = mosquito(c, 1560, sy - 330, s=1.05, sex='F', pose='stand', legs_spread=0.77, wings_up=0.22)
    for r_ in (50, 100, 150):
        ripple(1560 + 20, sy + 20, r_)
    c.vignette(0.3)
    c.noise_grain(0.006)
    c.save(os.path.join(OUT, 'i_emerge.jpg'))


# ============================================================= ADULT (female hero)
def adult_bg(c, cool=False):
    full(c, lin((0, 0), (0, c.h), (0.58, 0.74, 0.34), (0.12, 0.28, 0.12)))
    bokeh(c, (0, 0, c.w, c.h), 70, [(1, 0.95, 0.55), (0.75, 1, 0.55), (1, 1, 0.85)], r=(40, 150), a=(0.05, 0.14))
    # lá lớn mờ
    for i in range(6):
        c.ellipse(R.uniform(0, c.w), R.uniform(900, 1400), R.uniform(300, 520), R.uniform(80, 150), (0.2, 0.42, 0.14), rot=R.uniform(-0.4, 0.4), alpha=0.6, blur=28)
    c.blur_region(1)


def adult_female():
    c = Canvas()
    adult_bg(c)
    # chiếc lá làm chỗ đậu
    leaf = [(380, 1190), (900, 1050), (1500, 1020), (2200, 1060), (2540, 1180), (2200, 1330), (1500, 1360), (800, 1330)]
    c.poly(catmull(leaf, 14, closed=True), lin((0, 1020), (0, 1360), (0.36, 0.62, 0.2), (0.12, 0.3, 0.1)))
    c.line([(380, 1190), (1400, 1190), (2500, 1190)], 8, (0.78, 0.9, 0.55), alpha=0.5)
    mosquito(c, 1120, 560, s=1.85, sex='F', pose='stand', legs_spread=0.74)
    c.vignette(0.35)
    c.noise_grain(0.006)
    c.save(os.path.join(OUT, 'i_female.jpg'))


def adult_pair(mating=False):
    c = Canvas()
    adult_bg(c)
    if not mating:
        mosquito(c, 1980, 380, s=0.85, sex='M', pose='fly', flip=True, tilt=0.0)       # đực nhỏ hơn
        mosquito(c, 560, 680, s=1.2, sex='F', pose='fly', flip=False)
        out = 'i_sex.jpg'
    else:
        c.add_glow(1280, 640, 520, (1, 0.5, 0.65), 0.55)
        mosquito(c, 520, 740, s=1.1, sex='F', pose='fly', flip=False, tilt=-0.1)
        mosquito(c, 2080, 640, s=0.95, sex='M', pose='fly', flip=True, tilt=0.1)
        # trái tim
        t = np.linspace(0, 2 * math.pi, 120)
        hx = 16 * np.sin(t) ** 3
        hy = -(13 * np.cos(t) - 5 * np.cos(2 * t) - 2 * np.cos(3 * t) - np.cos(4 * t))
        pts = list(zip(1280 + hx * 15, 470 + hy * 15))
        c.poly(pts, radial((1280, 460), 280, (1, 0.45, 0.6), (0.85, 0.12, 0.3)), 0.95)
        c.ellipse(1230, 400, 40, 22, (1, 1, 1), rot=-0.7, alpha=0.7, blur=3)
        out = 'i_mating.jpg'
    c.vignette(0.35)
    c.noise_grain(0.006)
    c.save(os.path.join(OUT, out))


# ============================================================= FEED
def feed():
    c = Canvas()
    full(c, lin((0, 0), (0, c.h), (0.2, 0.15, 0.14), (0.06, 0.04, 0.05)))
    bokeh(c, (0, 0, c.w, 700), 30, [(1, 0.7, 0.5), (1, 0.85, 0.7)], r=(40, 140), a=(0.04, 0.1))
    # da người: đường cong lồi
    xs = np.linspace(0, c.w, 200)
    ys = 980 + 40 * np.sin(xs / 400 + 0.6) - 0.00009 * (xs - 1300) ** 2 * 0.6
    c.poly(list(zip(xs, ys)) + [(c.w, c.h), (0, c.h)], lin((0, 900), (0, c.h), (0.96, 0.74, 0.6), (0.62, 0.38, 0.3)))
    for i in range(500):
        x = R.uniform(0, c.w)
        y = np.interp(x, xs, ys) + R.uniform(8, 420)
        c.ellipse(x, y, R.uniform(1.5, 4), R.uniform(1.2, 3), (0.5, 0.28, 0.2), alpha=R.uniform(0.15, 0.4))
    for i in range(30):
        x = R.uniform(0, c.w)
        y = np.interp(x, xs, ys) + R.uniform(30, 400)
        c.line([(x, y), (x + R.uniform(100, 280), y + R.uniform(-6, 6))], 2, (0.75, 0.5, 0.4), alpha=0.18)
    # muỗi: cúi đầu, vòi cắm xuống da
    tilt = -0.42
    s_ = 1.35
    cx, cy = 1180, 360
    _t = make_T(cx, cy, s_, tilt, False)
    cy += float(np.interp(_t((-420, 150))[0], xs, ys)) - _t((-420, 150))[1] + 4
    T = mosquito(c, cx, cy, s=s_, sex='F', blood=0.65, pose='feed', tilt=tilt, legs_spread=0.7)
    tip = T((-420, 150))
    # đẩy da lên theo đầu vòi
    skin_y = tip[1]
    c.ellipse(tip[0], skin_y + 6, 60, 12, (0.55, 0.3, 0.24), alpha=0.5, blur=5)
    c.ellipse(tip[0], skin_y, 20, 6, (0.8, 0.1, 0.12), alpha=0.8)
    for i in range(4):
        c.ellipse(tip[0] + R.uniform(-60, 60), skin_y + R.uniform(-5, 6), 4, 4, (0.85, 0.1, 0.1), alpha=0.5)
    c.vignette(0.45)
    c.noise_grain(0.007)
    c.save(os.path.join(OUT, 'i_feed.jpg'))
    return tip, skin_y


# ============================================================= LAY
def lay():
    c = Canvas()
    full(c, lin((0, 0), (0, 900), (0.55, 0.78, 0.9), (0.82, 0.92, 0.8)))
    bokeh(c, (0, 0, c.w, 900), 30, [(1, 1, 0.85), (0.8, 1, 0.7)], r=(30, 110))
    sy = 1010
    xs = np.linspace(0, c.w, 200)
    sur = sy + 5 * np.sin(xs / 90)
    c.poly(list(zip(xs, sur)) + [(c.w, c.h), (0, c.h)], lin((0, sy), (0, c.h), (0.28, 0.58, 0.58), (0.04, 0.2, 0.26)), 0.97)
    c.poly(list(zip(xs, sur - 2)) + list(zip(xs[::-1], sur[::-1] + 14)), (0.95, 1, 1), 0.7, blur=2)
    for i in range(24):
        x, y = R.uniform(0, c.w), R.uniform(sy + 30, c.h)
        c.line([(x, y), (x + R.uniform(80, 360), y)], 3, (0.95, 1, 1), alpha=R.uniform(0.05, 0.2))
    def ripple(x, y, r, a=0.55):
        t = np.linspace(0, 2 * math.pi, 100)
        c.line([(x + r * math.cos(q), y + r * 0.14 * math.sin(q)) for q in t], 3, (1, 1, 1), alpha=a)
    for r_ in (40, 95, 160, 240):
        ripple(1720, sy + 22, r_, 0.5 - r_ / 800)
    # trứng đang rơi/nổi
    for i in range(14):
        x = 1680 + R.uniform(-130, 130)
        y = sy - 40 + R.uniform(-30, 180) * (i % 3) / 2
        yy = min(y, sy + 20)
        c.ellipse(x, yy, 11, 30, radial((x - 4, yy - 8), 30, (0.35, 0.3, 0.3), (0.02, 0.02, 0.02)), rot=R.uniform(-0.5, 0.5))
        c.ellipse(x - 3, yy - 10, 3, 9, (1, 1, 1), alpha=0.6)
    # muỗi bay thấp, đầu bụng chạm mặt nước
    Tt = make_T(0, 0, 1.3, 0.62, False)
    tipy = Tt((700, 62))
    mosquito(c, 1760 - tipy[0], sy - 8 - tipy[1], s=1.3, sex='F', pose='fly', tilt=0.62, blood=0.0)
    c.vignette(0.3)
    c.noise_grain(0.006)
    c.save(os.path.join(OUT, 'i_lay.jpg'))


if __name__ == '__main__':
    which = sys.argv[2].split(',') if len(sys.argv) > 2 else ['title', 'egg', 'larva', 'pupa', 'emerge', 'female', 'sex', 'mating', 'feed', 'lay']
    for w in which:
        print('draw', w, flush=True)
        {'title': title, 'egg': egg, 'larva': larva, 'pupa': pupa, 'emerge': emerge, 'female': adult_female,
         'sex': lambda: adult_pair(False), 'mating': lambda: adult_pair(True), 'feed': feed, 'lay': lay}[w]()
