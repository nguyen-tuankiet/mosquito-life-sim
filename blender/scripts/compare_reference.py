"""Ghép ảnh so sánh Reference A ↔ render (duyệt M2/M3). Cần Pillow.

  python blender/scripts/compare_reference.py [--renders docs/reference/env] [--out docs/reference/env/compare_reference.webp]

Cắt các ô trong docs/reference/visual/master_reference.webp (ảnh chính + 8 ảnh khu vực) và đặt cạnh
ảnh render cùng tên do render_views.py tạo ra.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw, ImageFont  # noqa: E402

import common as C  # noqa: E402

REF = os.path.join(C.REPO, "docs", "reference", "visual", "master_reference.webp")
# (tên render, nhãn, ô cắt trong ảnh reference 1312×1199)
PAIRS = [
    ("09_key_shot", "Ảnh chính → key shot (hướng a: bờ ao)", (0, 120, 1025, 585)),
    ("01_house", "1. Nhà dân", (18, 617, 268, 750)),
    ("02_garden", "2. Vườn cây / Chuồng trại", (287, 617, 530, 750)),
    ("03_pond", "3. Ao / Hồ", (546, 617, 781, 750)),
    ("04_rice", "4. Ruộng lúa", (796, 617, 1045, 750)),
    ("05_canal", "5. Kênh mương", (1061, 617, 1296, 750)),
    ("06_bamboo", "6. Rừng tre / Bụi rậm", (18, 830, 268, 962)),
    ("07_grass", "7. Đồng cỏ", (287, 830, 530, 962)),
    ("08_road", "8. Đường làng", (546, 830, 781, 962)),
]


def font(size):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "C:/Windows/Fonts/arialbd.ttf"):
        if os.path.isfile(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def main():
    a = C.parse_args({"renders": os.path.join(C.REPO, "docs", "reference", "env"), "out": ""})
    out = a.out or os.path.join(a.renders, "compare_reference.webp")
    ref = Image.open(REF).convert("RGB")
    cw, ch, pad, head = 560, 315, 10, 34
    rows = [p for p in PAIRS if os.path.isfile(os.path.join(a.renders, p[0] + ".webp"))]
    sheet = Image.new("RGB", (cw * 2 + pad * 3, (ch + head + pad) * len(rows) + 50), (22, 34, 40))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 12), "REFERENCE A (trái)  ↔  RENDER (phải)", fill=(235, 240, 235), font=font(22))
    for i, (name, label, box) in enumerate(rows):
        y = 50 + i * (ch + head + pad)
        d.text((pad, y + 6), label, fill=(235, 240, 235), font=font(18))
        r = ref.crop(box)
        r = r.resize((cw, int(cw * r.height / r.width))).crop((0, 0, cw, ch)) if r.width / r.height > cw / ch \
            else r.resize((int(ch * r.width / r.height), ch))
        sheet.paste(r, (pad, y + head))
        g = Image.open(os.path.join(a.renders, name + ".webp")).convert("RGB").resize((cw, ch))
        sheet.paste(g, (cw + pad * 2, y + head))
    sheet.save(out, quality=85)
    print("✓", out)


if __name__ == "__main__":
    main()
