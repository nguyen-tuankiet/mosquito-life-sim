"""Thư viện vẽ minh họa vector-ish (siêu mẫu + khử răng cưa) cho phần giới thiệu vòng đời muỗi.
Tất cả hình do code tự vẽ, không dùng ảnh ngoài => nét ở mọi độ phóng đại."""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 2560, 1440
SS = 3  # siêu mẫu khi dựng mask


def hexc(s):
    s = s.lstrip('#')
    return tuple(int(s[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


class Canvas:
    def __init__(self, w=W, h=H, bg=(0, 0, 0)):
        self.w, self.h = w, h
        self.a = np.zeros((h, w, 3), np.float32)
        self.a[:] = bg

    # ---- gradient / fill sources ----
    def _src(self, fill, xs, ys):
        if callable(fill):
            return fill(xs, ys)
        c = np.array(fill, np.float32)
        return np.broadcast_to(c, xs.shape + (3,))

    # ---- core: paint mask with fill ----
    def paint(self, mask, box, fill, alpha=1.0, mode='over'):
        x0, y0, x1, y1 = box
        xs, ys = np.meshgrid(np.arange(x0, x1, dtype=np.float32), np.arange(y0, y1, dtype=np.float32))
        src = self._src(fill, xs, ys)
        m = (mask * alpha)[..., None]
        reg = self.a[y0:y1, x0:x1]
        if mode == 'over':
            reg[:] = reg * (1 - m) + src * m
        elif mode == 'add':
            reg[:] = np.clip(reg + src * m, 0, 4)
        elif mode == 'mul':
            reg[:] = reg * (1 - m) + reg * src * m

    def poly_mask(self, pts, blur=0.0, pad=4):
        pts = np.asarray(pts, np.float64)
        x0 = int(max(0, math.floor(pts[:, 0].min()) - pad - blur * 3))
        y0 = int(max(0, math.floor(pts[:, 1].min()) - pad - blur * 3))
        x1 = int(min(self.w, math.ceil(pts[:, 0].max()) + pad + blur * 3))
        y1 = int(min(self.h, math.ceil(pts[:, 1].max()) + pad + blur * 3))
        if x1 <= x0 or y1 <= y0:
            return None, None
        bw, bh = x1 - x0, y1 - y0
        im = Image.new('L', (bw * SS, bh * SS), 0)
        d = ImageDraw.Draw(im)
        d.polygon([((x - x0) * SS, (y - y0) * SS) for x, y in pts], fill=255)
        im = im.resize((bw, bh), Image.LANCZOS)
        if blur > 0:
            im = im.filter(ImageFilter.GaussianBlur(blur))
        return np.asarray(im, np.float32) / 255.0, (x0, y0, x1, y1)

    def poly(self, pts, fill, alpha=1.0, blur=0.0, mode='over'):
        m, box = self.poly_mask(pts, blur)
        if m is None:
            return None
        self.paint(m, box, fill, alpha, mode)
        return m, box

    def ellipse(self, cx, cy, rx, ry, fill, rot=0.0, alpha=1.0, blur=0.0, mode='over'):
        t = np.linspace(0, 2 * math.pi, 120, endpoint=False)
        c, s = math.cos(rot), math.sin(rot)
        pts = np.stack([cx + rx * np.cos(t) * c - ry * np.sin(t) * s, cy + rx * np.cos(t) * s + ry * np.sin(t) * c], 1)
        return self.poly(pts, fill, alpha, blur, mode)

    def line(self, pts, width, fill, alpha=1.0, blur=0.0, taper=None, mode='over'):
        """Polyline dày (có thể thon dần: taper=(w0,w1))."""
        poly = tube(pts, width if taper is None else taper)
        return self.poly(poly, fill, alpha, blur, mode)

    def shaded(self, pts, base, shade, light=(-0.6, -0.8), spec=0.0, rim=None, alpha=1.0):
        """Tô một hình với gradient sáng→tối theo hướng ánh sáng, tuỳ chọn highlight."""
        pts = np.asarray(pts)
        cx, cy = pts[:, 0].mean(), pts[:, 1].mean()
        r = max(pts[:, 0].max() - pts[:, 0].min(), pts[:, 1].max() - pts[:, 1].min()) * 0.5 + 1
        lx, ly = light

        def f(xs, ys):
            t = ((xs - cx) * lx + (ys - cy) * ly) / r  # -1..1, âm = phía sáng
            t = np.clip((t + 1) / 2, 0, 1)[..., None]
            b = np.array(base, np.float32)
            s = np.array(shade, np.float32)
            return b * (1 - t) + s * t
        res = self.poly(pts, f, alpha)
        if res is None:
            return
        m, box = res
        if spec > 0:
            hx, hy = cx + lx * r * 0.45, cy + ly * r * 0.45
            self._blob_in(m, box, hx, hy, r * 0.35, r * 0.2, spec)
        if rim is not None:
            self._rim(m, box, rim)

    def _blob_in(self, m, box, hx, hy, rx, ry, a, color=(1, 1, 1), rot=0.0):
        x0, y0, x1, y1 = box
        xs, ys = np.meshgrid(np.arange(x0, x1, dtype=np.float32), np.arange(y0, y1, dtype=np.float32))
        c, s = math.cos(rot), math.sin(rot)
        dx, dy = xs - hx, ys - hy
        u = (dx * c + dy * s) / max(rx, 1e-3)
        v = (-dx * s + dy * c) / max(ry, 1e-3)
        g = np.exp(-(u * u + v * v) * 1.6)
        self.paint(m * g, box, color, a)

    def _rim(self, m, box, color):
        im = Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2))
        inner = np.asarray(im, np.float32) / 255.0
        edge = np.clip(m - inner * 0.0, 0, 1) * np.clip(1 - np.asarray(Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(5)), np.float32) / 255.0, 0, 1)
        self.paint(edge, box, color, 0.6)

    def blur_region(self, r):
        im = Image.fromarray((np.clip(self.a, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r))
        self.a = np.asarray(im, np.float32) / 255.0

    def add_glow(self, cx, cy, r, color, a):
        x0, y0 = int(max(0, cx - r)), int(max(0, cy - r))
        x1, y1 = int(min(self.w, cx + r)), int(min(self.h, cy + r))
        xs, ys = np.meshgrid(np.arange(x0, x1, dtype=np.float32), np.arange(y0, y1, dtype=np.float32))
        d = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2) / r
        g = np.clip(1 - d, 0, 1) ** 2
        self.paint(g, (x0, y0, x1, y1), color, a, 'add')

    def noise_grain(self, amt=0.012, seed=1):
        rng = np.random.default_rng(seed)
        self.a += rng.normal(0, amt, self.a.shape[:2])[..., None].astype(np.float32)

    def vignette(self, strength=0.35):
        ys, xs = np.mgrid[0:self.h, 0:self.w].astype(np.float32)
        d = np.sqrt(((xs - self.w / 2) / (self.w / 2)) ** 2 + ((ys - self.h / 2) / (self.h / 2)) ** 2)
        v = 1 - strength * np.clip(d - 0.55, 0, 1) ** 1.5
        self.a *= v[..., None]

    def solid(self, pts, base, shade=None, light=(-0.55, -0.7, 0.45), spec=0.5, shin=30.0, rim=(0.0, 0.0, 0.0), rim_k=0.0,
              alpha=1.0, a_edge=None, tex=0.0, bulge=1.0, seed=0, core=None, blur=0.0):
        """Tô một hình như vật thể 3D: cao độ giả từ khoảng cách tới biên -> pháp tuyến -> sáng khuếch tán + bóng + viền Fresnel.
        a_edge: nếu đặt, phần giữa trong mờ hơn (alpha=alpha) và rìa đặc hơn (a_edge) -> da trong suốt của lăng quăng/nhộng."""
        from scipy.ndimage import distance_transform_edt, gaussian_filter
        m, box = self.poly_mask(pts, blur=0.0, pad=6)
        if m is None:
            return None
        x0, y0, x1, y1 = box
        bm = m > 0.5
        dist = distance_transform_edt(bm).astype(np.float32)
        R = max(float(dist.max()), 1.0)
        d = np.clip(dist / R, 0, 1)
        h = np.sqrt(1 - (1 - d) ** 2) * R * 0.9 * bulge      # mặt cắt hình tròn
        h = gaussian_filter(h, 1.2)
        gy, gx = np.gradient(h)
        nz = 1.0 / np.sqrt(gx * gx + gy * gy + 1.0)
        nx, ny = -gx * nz, -gy * nz
        L = np.array(light, np.float32)
        L = L / np.linalg.norm(L)
        diff = np.clip(nx * L[0] + ny * L[1] + nz * L[2], 0, 1)
        Hv = L + np.array([0, 0, 1], np.float32)
        Hv = Hv / np.linalg.norm(Hv)
        sp = np.clip(nx * Hv[0] + ny * Hv[1] + nz * Hv[2], 0, 1) ** shin
        fres = (1 - nz) ** 2.2
        base = np.array(base, np.float32)
        shade = np.array(shade if shade is not None else base * 0.35, np.float32)
        t = np.clip(diff, 0, 1)[..., None]
        col = shade * (1 - t) + base * t
        if core is not None:
            ce = np.array(core, np.float32)
            col = col * (1 - (1 - fres[..., None]) * 0.0) 
        if tex > 0:
            rng = np.random.default_rng(seed)
            n1 = gaussian_filter(rng.normal(0, 1, h.shape).astype(np.float32), 1.0)
            n2 = gaussian_filter(rng.normal(0, 1, h.shape).astype(np.float32), 3.0)
            col = col * (1 + tex * (n1 * 0.6 + n2 * 0.8))[..., None]
        col = col + spec * sp[..., None] + np.array(rim, np.float32) * (fres * rim_k)[..., None]
        am = m * alpha
        if a_edge is not None:
            am = m * (alpha + (a_edge - alpha) * np.clip(fres * 1.6 + (1 - d) * 0.6, 0, 1))
        # đổ bóng tiếp xúc nhẹ phía dưới
        self.paint_img(col, am, (x0, y0, x1, y1))
        return m, box

    def paint_img(self, col, mask, box):
        x0, y0, x1, y1 = box
        reg = self.a[y0:y1, x0:x1]
        mm = mask[..., None]
        reg[:] = reg * (1 - mm) + col * mm

    def shadow(self, pts, dx=14, dy=22, blur=12, a=0.35, color=(0, 0, 0)):
        pts = np.asarray(pts, np.float64) + np.array([dx, dy])
        self.poly(pts, color, a, blur=blur)

    def grade(self, sat=0.84, contrast=1.04, warm=0.05):
        """Chỉnh màu theo bảng "Việt Nam rural cinematic": bớt bão hòa, ấm, đen nâng nhẹ về xanh rừng #14261F, trắng ngả kem #E8D7B5."""
        a = np.clip(self.a, 0, 1)
        lum = (a * np.array([0.299, 0.587, 0.114], np.float32)).sum(-1, keepdims=True)
        a = lum + (a - lum) * sat
        a = (a - 0.5) * contrast + 0.5
        a[..., 0] += warm
        a[..., 2] -= warm * 0.9
        deep = np.array(hexc('#14261F'), np.float32)
        cream = np.array(hexc('#E8D7B5'), np.float32)
        t = np.clip(a, 0, 1)
        t = deep * 0.55 * (1 - t) ** 2 + t * (1 - 0.1 * (1 - t) ** 2 * 0) 
        hi = np.clip((lum - 0.78) / 0.22, 0, 1)
        a = np.clip(t, 0, 1) * (1 - hi * 0.35) + cream * hi * 0.35
        self.a = a.astype(np.float32)

    def save(self, path, q=93):
        self.grade()
        im = Image.fromarray((np.clip(self.a, 0, 1) * 255 + 0.5).astype(np.uint8))
        im.save(path, quality=q, subsampling=0)


# ---------- gradients ----------
def lin(p0, p1, c0, c1, stops=None):
    p0 = np.array(p0, np.float32)
    p1 = np.array(p1, np.float32)
    d = p1 - p0
    L = float((d ** 2).sum())
    c0 = np.array(c0, np.float32)
    c1 = np.array(c1, np.float32)

    def f(xs, ys):
        t = np.clip(((xs - p0[0]) * d[0] + (ys - p0[1]) * d[1]) / L, 0, 1)[..., None]
        if stops:
            out = np.zeros(xs.shape + (3,), np.float32)
            tt = t[..., 0]
            pts = [(0.0, c0)] + [(s, np.array(c, np.float32)) for s, c in stops] + [(1.0, c1)]
            for (ta, ca), (tb, cb) in zip(pts[:-1], pts[1:]):
                seg = ((tt >= ta) & (tt <= tb))
                u = ((tt - ta) / max(tb - ta, 1e-6))[..., None]
                out = np.where(seg[..., None], ca * (1 - u) + cb * u, out)
            return out
        return c0 * (1 - t) + c1 * t
    return f


def radial(c, r, c0, c1):
    c0 = np.array(c0, np.float32)
    c1 = np.array(c1, np.float32)

    def f(xs, ys):
        t = np.clip(np.sqrt((xs - c[0]) ** 2 + (ys - c[1]) ** 2) / r, 0, 1)[..., None]
        return c0 * (1 - t) + c1 * t
    return f


# ---------- geometry ----------
def catmull(points, n=24, closed=False):
    P = [np.array(p, np.float64) for p in points]
    if closed:
        P = [P[-1]] + P + [P[0], P[1]]
    else:
        P = [P[0]] + P + [P[-1]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for t in np.linspace(0, 1, n, endpoint=False):
            t2, t3 = t * t, t * t * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    if not closed:
        out.append(P[-2])
    return np.array(out)


def bez(p0, p1, p2, p3, n=40):
    t = np.linspace(0, 1, n)[:, None]
    p0, p1, p2, p3 = [np.array(p, np.float64) for p in (p0, p1, p2, p3)]
    return (1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1 + 3 * (1 - t) * t ** 2 * p2 + t ** 3 * p3


def tube(pts, width):
    """Đa giác bao quanh polyline với bán kính thay đổi. width: số, hoặc (w0,w1), hoặc list theo từng điểm."""
    pts = np.asarray(pts, np.float64)
    n = len(pts)
    if isinstance(width, (int, float)):
        ws = np.full(n, width, np.float64)
    elif len(width) == 2 and n != 2:
        ws = np.linspace(width[0], width[1], n)
    else:
        ws = np.interp(np.linspace(0, 1, n), np.linspace(0, 1, len(width)), width)
    tang = np.gradient(pts, axis=0)
    ln = np.linalg.norm(tang, axis=1, keepdims=True)
    ln[ln == 0] = 1
    tang /= ln
    nrm = np.stack([-tang[:, 1], tang[:, 0]], 1)
    left = pts + nrm * (ws[:, None] / 2)
    right = pts - nrm * (ws[:, None] / 2)
    # nắp tròn hai đầu
    def cap(c, t, r, sign):
        a0 = math.atan2(t[1], t[0])
        angs = np.linspace(-math.pi / 2, math.pi / 2, 12) * sign + a0
        return np.stack([c[0] + r / 2 * np.cos(angs), c[1] + r / 2 * np.sin(angs)], 1)
    end = cap(pts[-1], tang[-1], ws[-1], 1)
    start = cap(pts[0], tang[0], ws[0], -1)
    return np.concatenate([left, end, right[::-1], start])


def rot(p, ang, c=(0, 0)):
    ca, sa = math.cos(ang), math.sin(ang)
    x, y = p[0] - c[0], p[1] - c[1]
    return (c[0] + x * ca - y * sa, c[1] + x * sa + y * ca)
