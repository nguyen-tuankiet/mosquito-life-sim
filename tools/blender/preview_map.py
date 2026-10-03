"""Ảnh xem trước top-down của map (không cần Blender/GPU) — để so với minimap trong ảnh MASTER REFERENCE.

  python tools/blender/preview_map.py [--out-dir tools/blender/out] [--png preview_top.png] [--px 2]

Đọc map_spec.json + map_points.json + map_layout.json (do generate_map.py sinh ra).
Cần: numpy, Pillow.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

import common as C  # noqa: E402
from generate_terrain import heightfield  # noqa: E402

DOT = {
    "BambooPoint": (40, 90, 30), "ShrubPoint": (30, 70, 25), "ReedPoint": (150, 165, 80),
    "LilyPoint": (80, 160, 70), "RicePoint": (150, 205, 70), "GrassTallPoint": (175, 190, 100),
    "GrassPoint": (120, 160, 80),
}


def main():
    a = C.parse_args({"out_dir": os.path.join(C.HERE, "out"), "png": "preview_top.png", "px": 2.0})
    spec = C.load_spec()
    fr = C.Frame(spec)
    s = a.px                                  # pixel / mét
    res = 1.0
    xs, zs = np.arange(0, fr.W, res), np.arange(0, fr.D, res)
    X, Z = np.meshgrid(xs, zs)
    H, zid = heightfield(spec, X, Z, res)
    M = C.Masks(spec)

    img = np.zeros(X.shape + (3,), np.float32)
    img[:] = spec["filler"]["color"]
    for k, z in spec["zones"].items():
        img[zid == k] = z["color"]
    img[M.road(X, Z)] = spec["zones"]["Z08"]["color"]
    img[M.paddy(X, Z) & (H < 0.2)] = (0.45, 0.62, 0.40)
    img[M.water(X, Z)] = (0.20, 0.42, 0.55)
    img[M.puddle(X, Z)] = (0.48, 0.52, 0.48)
    shade = np.clip(1 + (H - H.mean()) * 0.15, 0.7, 1.2)[..., None]
    im = Image.fromarray((np.clip(img * shade, 0, 1) * 255).astype(np.uint8))
    im = im.resize((int(fr.W * s), int(fr.D * s)), Image.NEAREST)
    d = ImageDraw.Draw(im)

    pts_path = os.path.join(a.out_dir, "map_points.json")
    if os.path.isfile(pts_path):
        P = json.load(open(pts_path, encoding="utf-8"))["types"]
        for t, v in P.items():
            arr = np.array(v["data"]).reshape(-1, v["stride"])
            step = max(1, len(arr) // 6000)   # thưa bớt cho dễ nhìn
            for gx, _, gz, *_ in arr[::step]:
                x, z = (gx + fr.W / 2) * s, (gz + fr.D / 2) * s
                d.point((x, z), fill=DOT.get(t, (0, 0, 0)))

    lay_path = os.path.join(a.out_dir, "map_layout.json")
    if os.path.isfile(lay_path):
        N = json.load(open(lay_path, encoding="utf-8"))["nodes"]
        for name, n in N.items():
            gx, _, gz = n["pos"]
            x, z = (gx + fr.W / 2) * s, (gz + fr.D / 2) * s
            t = name.split("_")[0]
            if t == "HousePoint":
                w, dd = n["props"]["footprint"]
                if n["props"]["facing"] in ("east", "west"):
                    w, dd = dd, w
                d.rectangle([x - w / 2 * s, z - dd / 2 * s, x + w / 2 * s, z + dd / 2 * s], fill=(170, 60, 40),
                            outline=(60, 20, 10))
            elif t in ("TreePoint", "BananaPoint", "CoconutPoint"):
                r = 2.5 * s if t != "CoconutPoint" else 3.5 * s
                d.ellipse([x - r, z - r, x + r, z + r], fill=(25, 75, 25) if t == "TreePoint" else (70, 130, 40))
            elif t == "FencePoint":
                d.point((x, z), fill=(220, 200, 140))
            elif t in ("JarPoint", "BucketPoint", "BasinPoint", "TirePoint", "BridgePoint"):
                d.rectangle([x - 2, z - 2, x + 2, z + 2], fill=(255, 230, 0))
            elif t == "LandmarkPoint":
                d.ellipse([x - 3, z - 3, x + 3, z + 3], outline=(255, 255, 255))
            elif t.startswith("PlayerSpawn"):
                d.ellipse([x - 6, z - 6, x + 6, z + 6], outline=(255, 40, 160), width=3)

    # nhãn zone giống minimap (①…⑧)
    for k, z in spec["zones"].items():
        for x0, z0, x1, z1 in z["rects"][:1]:
            cx, cz = (x0 + x1) / 2 * s, (z0 + z1) / 2 * s
            d.ellipse([cx - 11, cz - 11, cx + 11, cz + 11], fill=(255, 255, 255), outline=(0, 0, 0))
            d.text((cx - 4, cz - 6), k[-1], fill=(0, 0, 0))
    out = os.path.join(a.out_dir, a.png)
    im.save(out)
    print("✓", out)


if __name__ == "__main__":
    main()
