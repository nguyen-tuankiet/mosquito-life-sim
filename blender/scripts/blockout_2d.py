"""M0 — 2D Blockout + Reference B (layout từng zone). Không cần Blender/GPU.

  python blender/scripts/blockout_2d.py                  # → docs/reference/layout/*.png
  python blender/scripts/blockout_2d.py --with-exports   # phủ thêm điểm thực vật/Point từ blender/exports (kiểm tra M2)

Chỉ đọc docs/map_spec.json (bản số của MAP_BIBLE) → ảnh này là "bản đồ đúng concept" để so với
minimap trong ảnh MASTER REFERENCE, TRƯỚC khi dựng 3D hay tìm asset.

Kết quả:
  00_blockout_2d.png      toàn map: zone, đường, nước, nhà, rào, landmark, điểm đẻ trứng, lưới 50 m
  01_house.png … 08_road.png   Reference B: mỗi zone một sheet (zone nổi bật + kích thước + nội dung)
Cần: numpy, Pillow.
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np  # noqa: E402
from PIL import Image, ImageDraw, ImageFont  # noqa: E402

import common as C  # noqa: E402

OUT_DIR = os.path.join(C.REPO, "docs", "reference", "layout")
FONT_PATHS = ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "C:/Windows/Fonts/arial.ttf",
              "/System/Library/Fonts/Supplemental/Arial.ttf", "/Library/Fonts/Arial.ttf"]
WATER = (52, 108, 140)
PADDY_WATER = (118, 160, 104)
BUND = (150, 190, 90)
HOUSE = (170, 60, 40)
FENCE = (225, 205, 150)
PANEL = (22, 34, 40)
TEXT = (235, 240, 235)
DIM = (150, 160, 150)
FACING_VN = {"south": "Nam", "north": "Bắc", "east": "Đông", "west": "Tây"}
SHEET_ORDER = [("Z01", "01_house"), ("Z02", "02_garden"), ("Z03", "03_pond"), ("Z04", "04_rice"),
               ("Z05", "05_canal"), ("Z06", "06_bamboo"), ("Z07", "07_grass"), ("Z08", "08_road")]
DOT = {"BambooPoint": (40, 90, 30), "ShrubPoint": (30, 70, 25), "ReedPoint": (150, 165, 80),
       "LilyPoint": (80, 160, 70), "RicePoint": (150, 205, 70), "GrassTallPoint": (175, 190, 100),
       "GrassPoint": (120, 160, 80)}


def font(size, bold=False):
    for p in FONT_PATHS:
        q = p.replace("DejaVuSans.ttf", "DejaVuSans-Bold.ttf") if bold else p
        if os.path.isfile(q):
            return ImageFont.truetype(q, size)
    return ImageFont.load_default()


def rgb(c):
    return tuple(int(v * 255) for v in c)


class Map2D:
    """Raster 2D của map (1 ô = 1/res m) + lớp vector (nhà, rào, nhãn)."""

    def __init__(self, spec, px=2.0):
        self.s, self.px = spec, px
        self.fr = C.Frame(spec)
        self.M = C.Masks(spec)
        xs = np.arange(0, self.fr.W, 1.0 / px) + 0.5 / px
        zs = np.arange(0, self.fr.D, 1.0 / px) + 0.5 / px
        self.X, self.Z = np.meshgrid(xs, zs)
        self.zid = self.M.zone_id(self.X, self.Z)
        self.masks = self._masks()

    def _masks(self):
        X, Z, M, W = self.X, self.Z, self.M, self.s["water"]
        m = {k: self.zid == k for k in self.s["zones"]}
        m["filler"] = self.zid == "filler"
        m["canal"] = np.zeros(X.shape, bool)
        for k in ("canal_main", "canal_branch"):
            m["canal"] |= C.dist_to_polyline(X, Z, W[k]["centerline"]) < W[k]["w"] / 2
        m["Z05"] = m["canal"]
        m["pond"] = C.ellipse_r(X, Z, W["pond_main"]["center"], W["pond_main"]["radii"]) < 1
        m["road"] = M.road(X, Z)
        m["Z08"] = m["road"]
        m["puddle"] = M.puddle(X, Z)
        pd = W["paddy_main"]
        x0, z0, x1, z1 = pd["rect"]
        bund = np.zeros(X.shape, bool)
        for i in range(pd["plot_cols"] + 1):
            bund |= np.abs(X - (x0 + (x1 - x0) * i / pd["plot_cols"])) < pd["bund_w"] / 2 + 0.4
        for j in range(pd["plot_rows"] + 1):
            bund |= np.abs(Z - (z0 + (z1 - z0) * j / pd["plot_rows"])) < pd["bund_w"] / 2 + 0.4
        m["paddy"] = M.paddy(X, Z)
        m["bund"] = m["paddy"] & bund
        return m

    def raster(self, focus=None):
        """Ảnh nền RGB. focus = mã zone → các vùng khác bị làm nhạt."""
        img = np.zeros(self.X.shape + (3,), np.float32)
        img[:] = np.array(rgb(self.s["filler"]["color"]), np.float32)
        for k, z in self.s["zones"].items():
            img[self.masks[k]] = rgb(z["color"])
        img[self.masks["paddy"]] = PADDY_WATER
        img[self.masks["bund"]] = BUND
        img[self.masks["road"]] = rgb(self.s["zones"]["Z08"]["color"])
        img[self.masks["pond"] | self.masks["canal"]] = WATER
        img[self.masks["puddle"]] = (120, 135, 130)
        if focus:
            sel = self.masks[focus]
            grey = img.mean(-1, keepdims=True)
            img = np.where(sel[..., None], img, grey * 0.45 + 30)
        im = Image.fromarray(img.clip(0, 255).astype(np.uint8))
        return im

    def p(self, x, z):
        return x * self.px, z * self.px

    def draw_vectors(self, d, with_labels=True, f=None):
        s = self.s
        f = f or font(13)
        # lưới 50 m
        for x in range(0, int(self.fr.W) + 1, 50):
            d.line([self.p(x, 0), self.p(x, self.fr.D)], fill=(255, 255, 255, 40), width=1)
        for z in range(0, int(self.fr.D) + 1, 50):
            d.line([self.p(0, z), self.p(self.fr.W, z)], fill=(255, 255, 255, 40), width=1)
        # rào
        fs = s["fences"]
        doors = [h["pos"][1] for h in s["houses"]["list"].values() if C.house_facing(s, h) in ("east", "west")]
        for run in fs["runs"]:
            for (x, z, tx, tz) in C.polyline_frames(s["roads"][run["along"]]["points"], fs["segment_len"])[:-1]:
                if "from_z" in run and not (run["from_z"] <= z <= run["to_z"]):
                    continue
                if run["door_gap"] and any(abs(z - dz) < run["door_gap"] for dz in doors):
                    continue
                for sd in run["sides"]:
                    ax, az = x - tz * run["offset"] * sd, z + tx * run["offset"] * sd
                    d.line([self.p(ax, az), self.p(ax + tx * fs["segment_len"], az + tz * fs["segment_len"])],
                           fill=FENCE, width=2)
        # cầu
        for b in s["bridges"].values():
            x, z = b["at"]
            d.rectangle([self.p(x - b["len"] / 2, z - b["w"] / 2), self.p(x + b["len"] / 2, z + b["w"] / 2)],
                        fill=(150, 110, 70), outline=(60, 40, 20))
        # nhà (xoay theo hướng cửa)
        for hid, h in s["houses"]["list"].items():
            (x, z), (w, dd) = h["pos"], h["size"]
            facing = C.house_facing(s, h)
            if facing in ("east", "west"):
                w, dd = dd, w
            d.rectangle([self.p(x - w / 2, z - dd / 2), self.p(x + w / 2, z + dd / 2)], fill=HOUSE,
                        outline=(255, 220, 120) if h.get("hero") else (60, 20, 10), width=2)
            dx, dz = {"south": (0, 1), "north": (0, -1), "east": (1, 0), "west": (-1, 0)}[facing]
            cx, cz = x + dx * (dd / 2 if dz else w / 2), z + dz * (dd / 2 if dz else w / 2)
            d.ellipse([self.p(cx - 1.2, cz - 1.2), self.p(cx + 1.2, cz + 1.2)], fill=(255, 220, 120))
            if with_labels:
                d.text(self.p(x + w / 2 + 1.5, z - 4), hid, fill=TEXT, font=f)
        # landmark
        for lid, L in s["landmarks"].items():
            x, z = L["pos"]
            d.ellipse([self.p(x - 2, z - 2), self.p(x + 2, z + 2)], outline=(255, 255, 255), width=2)
            if with_labels:
                d.text(self.p(x + 2.5, z + 1), lid, fill=(255, 255, 255), font=f)
        # điểm đẻ trứng
        for wid, e in s["egg_sites"].items():
            x, z = e["pos"]
            r = 2.2
            col = (255, 60, 170) if e.get("spawn_first_life") else (255, 230, 0)
            d.polygon([self.p(x, z - r), self.p(x + r, z), self.p(x, z + r), self.p(x - r, z)], fill=col,
                      outline=(0, 0, 0))

    def overlay_exports(self, d, exp_dir):
        pts = os.path.join(exp_dir, "map_points.json")
        if os.path.isfile(pts):
            for t, v in json.load(open(pts, encoding="utf-8"))["types"].items():
                arr = np.array(v["data"]).reshape(-1, v["stride"])
                for gx, _, gz, *_ in arr[::max(1, len(arr) // 6000)]:
                    d.point(self.p(gx + self.fr.W / 2, gz + self.fr.D / 2), fill=DOT.get(t, (0, 0, 0)))
        lay = os.path.join(exp_dir, "map_layout.json")
        if os.path.isfile(lay):
            for name, n in json.load(open(lay, encoding="utf-8"))["nodes"].items():
                if name.split("_")[0] in ("TreePoint", "BananaPoint", "CoconutPoint"):
                    gx, _, gz = n["pos"]
                    x, z = gx + self.fr.W / 2, gz + self.fr.D / 2
                    d.ellipse([self.p(x - 2.5, z - 2.5), self.p(x + 2.5, z + 2.5)], fill=(25, 75, 25))


def zone_bbox(spec, zid):
    z = spec["zones"][zid]
    if z["rects"]:
        r = np.array(z["rects"], float)
        return [r[:, 0].min(), r[:, 1].min(), r[:, 2].max(), r[:, 3].max()]
    if zid == "Z05":
        pts = np.array(spec["water"]["canal_main"]["centerline"] + spec["water"]["canal_branch"]["centerline"], float)
    else:
        pts = np.array([p for r in spec["roads"].values() if r["type"] != "trail" for p in r["points"]], float)
    return [pts[:, 0].min(), pts[:, 1].min(), pts[:, 0].max(), pts[:, 1].max()]


def zone_contents(spec, zid):
    """Danh sách nội dung zone (nhà, landmark, điểm đẻ trứng, nước, đường, thực vật) theo Bible."""
    out = []
    if zid == "Z01":
        for hid, h in spec["houses"]["list"].items():
            out.append(f"{hid}  ({h['pos'][0]:.0f}, {h['pos'][1]:.0f})  {h['size'][0]}×{h['size'][1]} m, "
                       f"cửa hướng {FACING_VN[C.house_facing(spec, h)]}" + ("  ★ nhà chính" if h.get("hero") else ""))
    if zid == "Z05":
        for k in ("canal_main", "canal_branch"):
            w = spec["water"][k]
            L = sum(math.dist(a, b) for a, b in zip(w["centerline"][:-1], w["centerline"][1:]))
            out.append(f"{k}: rộng {w['w']} m, sâu {w['depth']} m, dài ≈ {L:.0f} m, mặt nước y = {w['surface_y']}")
    if zid == "Z08":
        for rid, r in spec["roads"].items():
            L = sum(math.dist(a, b) for a, b in zip(r["points"][:-1], r["points"][1:]))
            out.append(f"{rid}: {r['type']}, rộng {r['w']} m, dài ≈ {L:.0f} m")
    for k, w in spec["water"].items():
        if w.get("zone") == zid and k not in ("canal_main", "canal_branch"):
            if "radii" in w:
                out.append(f"{k}: elip {2 * w['radii'][0]}×{2 * w['radii'][1]} m, sâu {w['depth']} m")
            elif "rect" in w:
                x0, z0, x1, z1 = w["rect"]
                out.append(f"{k}: {x1 - x0}×{z1 - z0} m, {w['plot_cols']}×{w['plot_rows']} thửa, nước {w['surface_y']} m")
            elif "patches" in w:
                out.append(f"{k}: {len(w['patches'])} vũng (chỉ khi mưa)")
    for lid, L in spec["landmarks"].items():
        if L["zone"] == zid:
            out.append(f"{lid}  {L['name']}  ({L['pos'][0]}, {L['pos'][1]})")
    for wid, e in spec["egg_sites"].items():
        if e["zone"] == zid:
            out.append(f"◆ {wid}  ({e['pos'][0]}, {e['pos'][1]})" + ("  ← spawn lần đầu" if e.get("spawn_first_life") else ""))
    for t, cfg in spec["foliage"]["types"].items():
        if zid in cfg["zones"] or (zid == "Z05" and "canal_banks" in cfg["zones"]) or \
                (zid == "Z03" and ("pond_rim" in cfg["zones"] or "pond_water" in cfg["zones"])) or \
                (zid == "Z04" and ("paddy_rim" in cfg["zones"] or "Z04_rim" in cfg["zones"])):
            out.append(f"🌿 {t}  (cách nhau ≥ {cfg['min_dist']} m)")
    return out


def wrap(text, f, width, d):
    words, lines, cur = text.split(" "), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if d.textlength(t, font=f) > width and cur:
            lines.append(cur)
            cur = w
        else:
            cur = t
    return lines + [cur]


def legend(d, x, y, spec):
    f = font(14)
    items = [(rgb(z["color"]), f"{k[-1]}  {z['name']}") for k, z in spec["zones"].items()]
    items += [(WATER, "Mặt nước (kênh, ao)"), (PADDY_WATER, "Nước ruộng"), (BUND, "Bờ ruộng"),
              (HOUSE, "Nhà (chấm vàng = cửa)"), (FENCE, "Hàng rào tre"), ((255, 230, 0), "Điểm đẻ trứng"),
              ((255, 60, 170), "Spawn lần đầu (chum W03)"), ((255, 255, 255), "Landmark L01…")]
    for i, (c, t) in enumerate(items):
        d.rectangle([x, y + i * 22, x + 16, y + i * 22 + 16], fill=c, outline=(0, 0, 0))
        d.text((x + 24, y + i * 22), t, fill=TEXT, font=f)
    return y + len(items) * 22


def compass_and_scale(d, x, y, px):
    f = font(14, True)
    d.polygon([(x, y - 22), (x - 9, y + 4), (x, y - 2), (x + 9, y + 4)], fill=TEXT)
    d.text((x - 5, y - 44), "N", fill=TEXT, font=f)
    sx = x + 40
    d.rectangle([sx, y, sx + 50 * px, y + 6], fill=TEXT)
    d.rectangle([sx + 25 * px, y, sx + 50 * px, y + 6], fill=(90, 90, 90))
    d.text((sx, y + 10), "0", fill=TEXT, font=font(12))
    d.text((sx + 50 * px - 22, y + 10), "50 m", fill=TEXT, font=font(12))


def full_blockout(m, out, exp_dir=None):
    s = m.s
    base = m.raster().convert("RGBA")
    over = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    m.draw_vectors(d)
    if exp_dir:
        m.overlay_exports(d, exp_dir)
    big = font(26, True)
    for k, z in s["zones"].items():
        if k == "Z05":
            cx, cz = 85, 243
        elif k == "Z08":
            cx, cz = 285, 260
        else:
            r = z["rects"][0] if k != "Z02" else z["rects"][1]
            cx, cz = (r[0] + r[2]) / 2, (r[1] + r[3]) / 2
        X, Y = m.p(cx, cz)
        d.ellipse([X - 17, Y - 17, X + 17, Y + 17], fill=(255, 255, 255, 235), outline=(0, 0, 0), width=2)
        d.text((X - 8, Y - 15), k[-1], fill=(0, 0, 0), font=big)
    img = Image.alpha_composite(base, over).convert("RGB")
    W = img.width + 420
    sheet = Image.new("RGB", (W, img.height), PANEL)
    sheet.paste(img, (0, 0))
    d = ImageDraw.Draw(sheet)
    x = img.width + 24
    d.text((x, 20), "M0 — 2D BLOCKOUT", fill=TEXT, font=font(26, True))
    d.text((x, 56), s["map"]["name"], fill=DIM, font=font(15))
    d.text((x, 78), f"{s['map']['width_x']} × {s['map']['depth_z']} m · lưới 50 m · gốc Tây-Bắc", fill=DIM, font=font(15))
    y = legend(d, x, 120, s)
    compass_and_scale(d, x + 20, y + 60, m.px)
    y += 110
    d.text((x, y), "Hành trình người chơi:", fill=TEXT, font=font(15, True))
    y += 24
    names = [s["zones"][z]["name"] for z in s["journey_order"]]
    for line in wrap(" → ".join(names), font(14), 370, d):
        d.text((x, y), line, fill=DIM, font=font(14))
        y += 20
    y += 16
    for line in wrap("Nguồn: docs/map_spec.json (= docs/MAP_BIBLE.md). So với minimap trong "
                     "docs/reference/visual/master_reference.webp — phải giống bố cục.", font(13), 370, d):
        d.text((x, y), line, fill=DIM, font=font(13))
        y += 18
    sheet.save(out)
    return out


def zone_sheet(m, zid, out):
    s = m.s
    z = s["zones"][zid]
    x0, z0, x1, z1 = zone_bbox(s, zid)
    pad = 25
    cx0, cz0 = max(0, x0 - pad), max(0, z0 - pad)
    cx1, cz1 = min(m.fr.W, x1 + pad), min(m.fr.D, z1 + pad)
    base = m.raster(focus=zid).convert("RGBA")
    over = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    m.draw_vectors(d, f=font(12))
    for r in z["rects"]:
        d.rectangle([m.p(r[0], r[1]), m.p(r[2], r[3])], outline=(255, 255, 255, 255), width=3)
        d.text((m.p(r[0], r[1])[0] + 4, m.p(r[0], r[1])[1] + 4),
               f"[{r[0]}, {r[1]}] → [{r[2]}, {r[3]}]  ({r[2] - r[0]}×{r[3] - r[1]} m)", fill=(255, 255, 255),
               font=font(14, True))
    img = Image.alpha_composite(base, over).convert("RGB")
    crop = img.crop((int(cx0 * m.px), int(cz0 * m.px), int(cx1 * m.px), int(cz1 * m.px)))
    # phóng để sheet dễ đọc (cạnh dài ~900 px)
    k = min(1.5, 900 / max(crop.size))
    crop = crop.resize((int(crop.width * k), int(crop.height * k)), Image.LANCZOS)
    # bản đồ nhỏ
    mini = m.raster(focus=zid).resize((200, int(200 * m.fr.D / m.fr.W)))
    dm = ImageDraw.Draw(mini)
    sx = 200 / m.fr.W
    dm.rectangle([cx0 * sx, cz0 * sx, cx1 * sx, cz1 * sx], outline=(255, 255, 255), width=2)

    W = crop.width + 480
    H = max(crop.height, 760)
    sheet = Image.new("RGB", (W, H), PANEL)
    sheet.paste(crop, (0, 0))
    d = ImageDraw.Draw(sheet)
    x = crop.width + 24
    d.text((x, 18), f"{SHEET_ORDER[[a for a, _ in SHEET_ORDER].index(zid)][1][:2]}  {z['name']}", fill=TEXT,
           font=font(26, True))
    d.text((x, 54), f"Zone {zid} · key: {z['key']}", fill=DIM, font=font(15))
    d.text((x, 76), f"Khung: x {x0:.0f}–{x1:.0f}, z {z0:.0f}–{z1:.0f} ({x1 - x0:.0f}×{z1 - z0:.0f} m)", fill=DIM,
           font=font(15))
    if z.get("ground_y") is not None:
        d.text((x, 98), f"Cao độ nền: y = {z['ground_y']} m", fill=DIM, font=font(15))
    sheet.paste(mini, (x, 128))
    y = 128 + mini.height + 18
    d.text((x, y), "Nội dung (theo MAP_BIBLE):", fill=TEXT, font=font(15, True))
    y += 26
    f = font(13)
    for item in zone_contents(s, zid):
        for line in wrap(item.replace("🌿 ", "• "), f, 440, d):
            if y > H - 24:
                break
            d.text((x, y), line, fill=TEXT, font=f)
            y += 18
    sheet.save(out)
    return out


def main():
    a = C.parse_args({"out_dir": OUT_DIR, "px": 2.0, "with_exports": False, "exports": C.EXPORT_DIR})
    spec = C.load_spec()
    warns = C.validate_spec(spec)
    for w in warns:
        print("⚠ BIBLE:", w)
    os.makedirs(a.out_dir, exist_ok=True)
    m = Map2D(spec, a.px)
    name = "00_blockout_2d_with_exports.png" if a.with_exports else "00_blockout_2d.png"
    print("✓", full_blockout(m, os.path.join(a.out_dir, name), a.exports if a.with_exports else None))
    if not a.with_exports:
        hi = Map2D(spec, a.px * 2)  # sheet từng zone: raster mịn gấp đôi
        for zid, fn in SHEET_ORDER:
            print("✓", zone_sheet(hi, zid, os.path.join(a.out_dir, fn + ".png")))


if __name__ == "__main__":
    main()
