"""M3 — ánh sáng / mood cho ảnh duyệt Blender, đọc docs/art_look.json (dùng chung với godot/world/day_night.gd).

  apply(scene, hour)  → trời (dải màu theo bảng màu), mặt trời / trăng theo giờ, sương (volume), đèn cửa sổ,
                         color grading. Cùng công thức vị trí mặt trời với Godot.
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common as C  # noqa: E402

LOOK_PATH = os.path.join(C.REPO, "docs", "art_look.json")


def load_look(path=LOOK_PATH):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def hex_rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]


def srgb_to_lin(c):
    return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]


def sample(look, hour):
    """Nội suy khoá 'cycle' tại giờ `hour` → dict (màu sRGB 0–1)."""
    keys = look["cycle"]
    hour %= 24.0
    for a, b in zip(keys[:-1], keys[1:]):
        if a["hour"] <= hour <= b["hour"]:
            t = (hour - a["hour"]) / max(b["hour"] - a["hour"], 1e-6)
            out = {}
            for k, va in a.items():
                vb = b[k]
                if isinstance(va, str):
                    ca, cb = hex_rgb(va), hex_rgb(vb)
                    out[k] = [ca[i] + (cb[i] - ca[i]) * t for i in range(3)]
                else:
                    out[k] = va + (vb - va) * t
            return out
    raise ValueError(hour)


def sun_angles(look, hour):
    """(độ cao °, phương vị la bàn °) của mặt trời; độ cao < 0 = dưới chân trời. Công thức giống day_night.gd."""
    p = look["sun_path"]
    t = (hour - p["rise_hour"]) / (p["set_hour"] - p["rise_hour"])
    elev = p["max_elevation"] * math.sin(math.pi * t) if 0 <= t <= 1 else -10.0
    az = p["rise_azimuth"] + (p["set_azimuth"] - p["rise_azimuth"]) * min(max(t, 0), 1)
    return elev, az


def _dir_bl(elev, az):
    """Vector từ mặt đất hướng về thiên thể, toạ độ Blender (+Y = Bắc, +X = Đông)."""
    e, a = math.radians(elev), math.radians(az)
    return (math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e))


def _aim(ob, to_sky):
    from mathutils import Vector
    d = -Vector(to_sky)
    ob.rotation_euler = Vector((0, 0, -1)).rotation_difference(d).to_euler()


def _world(bpy, s, look=None):
    w = bpy.data.worlds.new("M3_Sky")
    w.use_nodes = True
    nt = w.node_tree
    N, L = nt.nodes, nt.links
    bg = N["Background"]
    tc = N.new("ShaderNodeTexCoord")
    sep = N.new("ShaderNodeSeparateXYZ")
    ramp = N.new("ShaderNodeValToRGB")
    L.new(tc.outputs["Generated"], sep.inputs[0])
    mp = N.new("ShaderNodeMapRange")          # z ∈ [-1, 1] → [0, 1]
    mp.inputs["From Min"].default_value = -1.0
    L.new(sep.outputs["Z"], mp.inputs["Value"])
    L.new(mp.outputs["Result"], ramp.inputs["Fac"])
    els = ramp.color_ramp.elements
    hor, top = srgb_to_lin(s["sky_horizon"]), srgb_to_lin(s["sky_top"])
    ground = [c * 0.35 for c in srgb_to_lin([0.36, 0.42, 0.25])]
    els[0].position, els[0].color = 0.40, (*ground, 1)
    els[1].position, els[1].color = 1.0, (*top, 1)
    e = els.new(0.5)                    # chân trời
    e.color = (*hor, 1)
    e2 = els.new(0.535)                 # ~4° trên chân trời: đã pha nửa xanh
    e2.color = (*[(h + t) / 2 for h, t in zip(hor, top)], 1)
    e3 = els.new(0.62)                  # ~14°: xanh đỉnh trời
    e3.color = (*top, 1)
    # mây tích: nhiễu fBm chiếu lên vòm trời (xy / (z + 0.25) để mây dẹt về chân trời), chỉ nửa trên
    # — cùng thuật toán với godot/shaders/village_sky.gdshader
    vm = N.new("ShaderNodeVectorMath")
    vm.operation = "DIVIDE"
    zz = N.new("ShaderNodeMath")
    zz.operation = "ADD"
    zz.inputs[1].default_value = 0.25
    L.new(sep.outputs["Z"], zz.inputs[0])
    comb = N.new("ShaderNodeCombineXYZ")
    for i in range(3):
        L.new(zz.outputs[0], comb.inputs[i])
    L.new(tc.outputs["Generated"], vm.inputs[0])
    L.new(comb.outputs[0], vm.inputs[1])
    noise = N.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 1.1
    noise.inputs["Detail"].default_value = 6.0
    noise.inputs["Roughness"].default_value = 0.55
    L.new(vm.outputs["Vector"], noise.inputs["Vector"])
    cr = N.new("ShaderNodeValToRGB")
    cr.color_ramp.elements[0].position = 0.52
    cr.color_ramp.elements[1].position = 0.72
    L.new(noise.outputs["Fac"], cr.inputs["Fac"])
    up = N.new("ShaderNodeMath")                 # chỉ trên chân trời
    up.operation = "GREATER_THAN"
    up.inputs[1].default_value = 0.02
    L.new(sep.outputs["Z"], up.inputs[0])
    msk = N.new("ShaderNodeMath")
    msk.operation = "MULTIPLY"
    L.new(cr.outputs["Color"], msk.inputs[0])
    L.new(up.outputs[0], msk.inputs[1])
    cloud_amt = N.new("ShaderNodeMath")
    cloud_amt.operation = "MULTIPLY"
    cloud_amt.inputs[1].default_value = s["clouds"]
    L.new(msk.outputs[0], cloud_amt.inputs[0])
    mix = N.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    L.new(cloud_amt.outputs[0], mix.inputs["Factor"])
    L.new(ramp.outputs["Color"], mix.inputs["A"])
    cc = srgb_to_lin(s["cloud_color"])
    mix.inputs["B"].default_value = (*cc, 1)
    out = mix.outputs["Result"]
    # dãy núi xa phía Bắc (MAP_BIBLE §2 / L14): đường sống núi = nhiễu theo phương vị, cao ~2–6° trên chân trời,
    # màu pha chân trời (sương xa). Cùng cách với village_sky.gdshader (khác hàm nhiễu).
    nv = N.new("ShaderNodeVectorMath")
    nv.operation = "NORMALIZE"
    L.new(tc.outputs["Generated"], nv.inputs[0])
    sn = N.new("ShaderNodeSeparateXYZ")
    L.new(nv.outputs["Vector"], sn.inputs[0])
    az = N.new("ShaderNodeMath")
    az.operation = "ARCTAN2"                      # atan2(x, y): phương vị la bàn (0 = Bắc, + = Đông)
    L.new(sn.outputs["X"], az.inputs[0])
    L.new(sn.outputs["Y"], az.inputs[1])
    azv = N.new("ShaderNodeCombineXYZ")
    L.new(az.outputs[0], azv.inputs["X"])
    mn = N.new("ShaderNodeTexNoise")
    mn.inputs["Scale"].default_value = 2.4
    mn.inputs["Detail"].default_value = 5.0
    L.new(azv.outputs[0], mn.inputs["Vector"])
    north = N.new("ShaderNodeMapRange")           # chỉ nửa phía Bắc, mờ dần về hai bên
    north.inputs["From Min"].default_value = 0.1
    north.inputs["From Max"].default_value = 0.5
    L.new(sn.outputs["Y"], north.inputs["Value"])
    rid = N.new("ShaderNodeMath")
    rid.operation = "MULTIPLY_ADD"                # ridge = noise * 0.08 - 0.005
    rid.inputs[1].default_value = 0.08
    rid.inputs[2].default_value = -0.005
    L.new(mn.outputs["Fac"], rid.inputs[0])
    ridn = N.new("ShaderNodeMath")
    ridn.operation = "MULTIPLY"
    L.new(rid.outputs[0], ridn.inputs[0])
    L.new(north.outputs["Result"], ridn.inputs[1])
    below = N.new("ShaderNodeMath")
    below.operation = "LESS_THAN"
    L.new(sn.outputs["Z"], below.inputs[0])
    L.new(ridn.outputs[0], below.inputs[1])
    above0 = N.new("ShaderNodeMath")
    above0.operation = "GREATER_THAN"
    above0.inputs[1].default_value = -0.01
    L.new(sn.outputs["Z"], above0.inputs[0])
    mm = N.new("ShaderNodeMath")
    mm.operation = "MULTIPLY"
    L.new(below.outputs[0], mm.inputs[0])
    L.new(above0.outputs[0], mm.inputs[1])
    mcol = [h * 0.45 + m * 0.55 for h, m in zip(hor, srgb_to_lin(hex_rgb("#5E7A92")))]
    mmix = N.new("ShaderNodeMix")
    mmix.data_type = "RGBA"
    L.new(mm.outputs[0], mmix.inputs["Factor"])
    L.new(out, mmix.inputs["A"])
    mmix.inputs["B"].default_value = (*[c * (0.35 + 0.65 * s["ambient"]) for c in mcol], 1)
    out = mmix.outputs["Result"]
    night = max(0.0, 1.0 - s["sun_energy"] / 0.35)
    if night > 0.01 and look is not None:
        # sao: nhiễu tần số cao, chỉ giữ đỉnh sáng; trăng tròn: đĩa theo hướng trăng (art_look.json → moon)
        st = N.new("ShaderNodeTexNoise")
        st.inputs["Scale"].default_value = 900.0
        st.inputs["Detail"].default_value = 0.0
        L.new(tc.outputs["Generated"], st.inputs["Vector"])
        sr = N.new("ShaderNodeMapRange")
        sr.inputs["From Min"].default_value = 0.80
        sr.inputs["From Max"].default_value = 0.86
        sr.inputs["To Max"].default_value = 1.6 * night
        L.new(st.outputs["Fac"], sr.inputs["Value"])
        smask = N.new("ShaderNodeMath")
        smask.operation = "MULTIPLY"
        L.new(sr.outputs["Result"], smask.inputs[0])
        L.new(up.outputs[0], smask.inputs[1])
        md = _dir_bl(look["moon"]["elevation"], look["moon"]["azimuth"])
        dp = N.new("ShaderNodeVectorMath")
        dp.operation = "DOT_PRODUCT"
        nrm = N.new("ShaderNodeVectorMath")
        nrm.operation = "NORMALIZE"
        L.new(tc.outputs["Generated"], nrm.inputs[0])
        L.new(nrm.outputs["Vector"], dp.inputs[0])
        dp.inputs[1].default_value = md
        disc = N.new("ShaderNodeMapRange")
        disc.inputs["From Min"].default_value = math.cos(math.radians(1.6))
        disc.inputs["From Max"].default_value = math.cos(math.radians(1.3))
        disc.inputs["To Max"].default_value = 6.0 * night
        L.new(dp.outputs["Value"], disc.inputs["Value"])
        add = N.new("ShaderNodeMath")
        add.operation = "ADD"
        L.new(smask.outputs[0], add.inputs[0])
        L.new(disc.outputs["Result"], add.inputs[1])
        mcol = N.new("ShaderNodeMix")
        mcol.data_type = "RGBA"
        mcol.blend_type = "ADD"
        mcol.inputs["Factor"].default_value = 1.0
        L.new(out, mcol.inputs["A"])
        sc_ = N.new("ShaderNodeVectorMath")
        sc_.operation = "SCALE"
        sc_.inputs[0].default_value = srgb_to_lin(hex_rgb("#E8EEFF"))
        L.new(add.outputs[0], sc_.inputs["Scale"])
        L.new(sc_.outputs["Vector"], mcol.inputs["B"])
        out = mcol.outputs["Result"]
    L.new(out, bg.inputs["Color"])
    bg.inputs["Strength"].default_value = 0.35 + 0.85 * s["ambient"]
    return w


def _haze_box(bpy, scene, s):
    """Sương xa = khối hộp volume bao map (không dùng world volume: vô hạn → nuốt hết nắng và trời)."""
    me = bpy.data.meshes.new("M3_Haze")
    hx, hy, h = 1000.0, 1000.0, 250.0
    v = [(-hx, -hy, -5), (hx, -hy, -5), (hx, hy, -5), (-hx, hy, -5),
         (-hx, -hy, h), (hx, -hy, h), (hx, hy, h), (-hx, hy, h)]
    f = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    me.from_pydata(v, [], f)
    ob = bpy.data.objects.new("M3_Haze", me)
    m = bpy.data.materials.new("M3_Haze")
    m.use_nodes = True
    N, L = m.node_tree.nodes, m.node_tree.links
    N.remove(N["Principled BSDF"])
    vol = N.new("ShaderNodeVolumePrincipled")
    vol.inputs["Color"].default_value = (*srgb_to_lin(s["fog_color"]), 1)
    vol.inputs["Density"].default_value = s["fog_density"] * 0.15
    vol.inputs["Anisotropy"].default_value = 0.45          # tán xạ về phía trước: quầng sáng ngược nắng
    L.new(vol.outputs["Volume"], N["Material Output"].inputs["Volume"])
    me.materials.append(m)
    ob["m3_light"] = True
    scene.collection.objects.link(ob)
    return ob


def apply(scene, hour, look=None, haze=True):
    bpy = C.bpy_mod()
    look = look or load_look()
    s = sample(look, hour)
    scene.world = _world(bpy, s, look)
    for ob in [o for o in scene.objects if o.get("m3_light")]:
        bpy.data.objects.remove(ob)
    if haze and s["fog_density"] > 0:
        _haze_box(bpy, scene, s)

    elev, az = sun_angles(look, hour)
    if s["sun_energy"] > 0 and elev > -2:
        sun = bpy.data.objects.new("M3_Sun", bpy.data.lights.new("M3_Sun", "SUN"))
        sun.data.energy = s["sun_energy"] * look["sun_energy_to_blender"]
        sun.data.color = srgb_to_lin(s["sun_color"])
        sun.data.angle = math.radians(1.5)
        _aim(sun, _dir_bl(max(elev, 1.0), az))
        sun["m3_light"] = True
        scene.collection.objects.link(sun)
    if s["sun_energy"] < 0.4:                 # trăng
        m = look["moon"]
        moon = bpy.data.objects.new("M3_Moon", bpy.data.lights.new("M3_Moon", "SUN"))
        moon.data.energy = m["energy"] * look["sun_energy_to_blender"] * (1 - s["sun_energy"] / 0.4)
        moon.data.color = srgb_to_lin(hex_rgb(m["color"]))
        moon.data.angle = math.radians(0.6)
        _aim(moon, _dir_bl(m["elevation"], m["azimuth"]))
        moon["m3_light"] = True
        scene.collection.objects.link(moon)
    if s["windows"] > 0.01:                   # đèn vàng ấm trong nhà (ART_DIRECTION §2 ban đêm)
        wcfg = look["windows"]
        for hp in [o for o in scene.objects if o.name.startswith("HousePoint_") and o.type == "EMPTY"]:
            fp = hp.get("footprint", [12, 8])
            lamp = bpy.data.objects.new(hp.name + "_M3Lamp", bpy.data.lights.new(hp.name + "_M3Lamp", "POINT"))
            lamp.data.energy = wcfg["energy_blender_w"] * s["windows"]
            lamp.data.color = srgb_to_lin(hex_rgb(wcfg["color"]))
            lamp.data.shadow_soft_size = 0.4
            lamp.parent = hp
            lamp.location = (0, -float(fp[1]) * 0.5 - 0.6, 2.0)   # trước cửa (mặt trước −Y cục bộ)
            lamp["m3_light"] = True
            scene.collection.objects.link(lamp)

    vs = scene.view_settings
    try:
        vs.view_transform = "AgX"
        vs.look = "AgX - Base Contrast"
    except TypeError:
        pass
    g = look["grading"]
    vs.exposure = 0.35 if s["sun_energy"] > 0.4 else 1.1    # đêm: nâng phơi sáng để vẫn đọc được hình khối
    try:
        scene.cycles.volume_step_rate = 4.0
        scene.cycles.volume_max_steps = 64
    except AttributeError:
        pass
    scene["m3_hour"] = hour
    scene["m3_grading"] = json.dumps(g)
    return s, (elev, az)


def grade_image(path, grading):
    """Color grading sau render (bão hoà + tương phản) — giống Environment.adjustment của Godot."""
    from PIL import Image, ImageEnhance
    im = Image.open(path).convert("RGB")
    im = ImageEnhance.Color(im).enhance(grading.get("saturation", 1.0))
    im = ImageEnhance.Contrast(im).enhance(grading.get("contrast", 1.0))
    im = ImageEnhance.Brightness(im).enhance(grading.get("brightness", 1.0))
    im.save(path, quality=85)
