"""Sinh mặt nước theo MAP_BIBLE §5: Canal (kênh chính + nhánh), Pond, Rice Field (nước ruộng),
vũng sau mưa, và điểm đẻ trứng (EggSite_*) §6.

Mặt nước là mesh phẳng tách riêng khỏi Terrain → trong Godot gán shader nước riêng.
Cần chạy sau generate_terrain (dùng ctx["height"]).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np  # noqa: E402

import common as C  # noqa: E402

WATER_COLORS = {   # ART_DIRECTION §3: ao #4E7680, nước tù #5B6B48
    "natural_flowing": (0.30, 0.46, 0.50),
    "stagnant_slow": (0.36, 0.42, 0.28),
    "clean_still": (0.31, 0.46, 0.50),
    "shallow_nutrient": (0.42, 0.50, 0.36),
    "temporary": (0.45, 0.42, 0.34),
}


def _wmat(cls):
    return C.material("MAT_Water_" + cls, WATER_COLORS[cls], 0.05, alpha=0.75)


def _tag(ob, w, key):
    ob["water_body"] = key
    ob["water_class"] = w["class"]
    ob["zone"] = w["zone"]
    ob["surface_y"] = float(w.get("surface_y", 0.0))
    return ob


def build(spec, ctx):
    fr = ctx["frame"]
    height = ctx["height"]
    W = spec["water"]
    col = C.collection("Water", ctx["root"])

    # Kênh chính + kênh nhánh — dải nước rộng hơn lòng kênh 1 m để chồng lên bờ
    for key in ("canal_main", "canal_branch"):
        w = W[key]
        ob = C.ribbon("Water_" + key, w["centerline"], w["w"] + 1.0,
                      lambda x, z, y=w["surface_y"]: y, fr, col, _wmat(w["class"]), step=2.0, y_off=0.0)
        _tag(ob, w, key)

    # Ao
    w = W["pond_main"]
    ob = C.disc("Water_pond_main", w["center"], [r * 1.04 for r in w["radii"]], w["surface_y"], fr, col,
                _wmat(w["class"]))
    _tag(ob, w, "pond_main")

    # Nước ruộng (một tấm phẳng, bờ ruộng nhô lên khỏi mặt nước)
    w = W["paddy_main"]
    x0, z0, x1, z1 = w["rect"]
    y = w["surface_y"]
    ob = C.mesh_object("Water_paddy_main",
                       [fr.bl(x0, z0, y), fr.bl(x1, z0, y), fr.bl(x1, z1, y), fr.bl(x0, z1, y)],
                       [(0, 3, 2, 1)], col, _wmat(w["class"]))
    _tag(ob, w, "paddy_main")

    # Vũng sau mưa — chỉ hiện khi mưa (Godot đọc custom prop rain_only)
    w = W["puddles_meadow"]
    pcol = C.collection("Water_Temporary", col)
    for i, (x, z, r) in enumerate(w["patches"], 1):
        g = float(height(np.array([x]), np.array([z]))[0])
        ob = C.disc(f"Water_puddle_{i:02d}", (x, z), (r, r * 0.8), g + w["surface_y_above_ground"], fr, pcol,
                    _wmat(w["class"]), seg=24)
        _tag(ob, w, "puddles_meadow")
        ob["rain_only"] = True

    # Điểm đẻ trứng §6 (chỉ là empty có dữ liệu — vật chứa thật đặt ở generate_village)
    ecol = C.collection("EggSites", ctx["root"])
    for wid, e in spec["egg_sites"].items():
        x, z = e["pos"]
        g = float(height(np.array([x]), np.array([z]))[0])
        y = e["y"] if e["y_mode"] == "absolute" else g + e["y"]
        C.empty("EggSite_" + wid, fr.bl(x, z, y), ecol, display="SPHERE", size=0.6, props={
            "egg_site": wid, "zone": e["zone"], "kind": e["kind"],
            "game_site": e["game_site"] or "", "spawn_first_life": bool(e.get("spawn_first_life", False)),
        })
    return col


if __name__ == "__main__":
    import generate_terrain
    a = C.parse_args({"res": 2.0, "out": ""})
    spec = C.load_spec()
    C.reset_scene()
    ctx = {"frame": C.Frame(spec), "res": a.res, "root": C.collection("MAP")}
    generate_terrain.build(spec, ctx)
    build(spec, ctx)
    if a.out:
        C.bpy_mod().ops.wm.save_as_mainfile(filepath=os.path.abspath(a.out))
