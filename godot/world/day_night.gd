extends Node3D
## M3 — chu kỳ ngày–đêm của làng (docs/ART_DIRECTION.md §2, thông số docs/art_look.json — dùng chung với Blender).
## Tạo WorldEnvironment (trời village_sky.gdshader, sương, AgX, glow, color grading), mặt trời + trăng
## (DirectionalLight3D có bóng đổ) và đèn vàng trước cửa từng nhà; nội suy theo giờ 0–24.
##
## Dùng:  var dn = preload("res://world/day_night.gd").new(); add_child(dn)
##        dn.setup("res://world/generated/art_look.json", "res://world/generated/map_layout.json")
##        dn.hour = 17.3; dn.auto = true   # auto: 1 ngày = game_day_seconds (75 s, khớp DAY_LEN_ADULT)

const SKY_SHADER := preload("res://shaders/village_sky.gdshader")

var hour := 17.3
var auto := false
var day_seconds := 75.0
var env: Environment
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var sky_mat: ShaderMaterial
var lamps: Array[OmniLight3D] = []
var look: Dictionary = {}


func setup(look_path: String, layout_path: String) -> void:
	var f := FileAccess.open(look_path, FileAccess.READ)
	if f:
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			look = parsed
	if look.is_empty():
		push_warning("Không đọc được %s — dùng ánh sáng trưa cố định" % look_path)
	day_seconds = float(look.get("game_day_seconds", 75.0))

	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = SKY_SHADER
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.fog_enabled = true
	env.fog_sky_affect = 0.25
	env.fog_sun_scatter = 0.25            # quầng sáng ngược nắng giờ vàng
	env.ssao_enabled = true
	env.glow_enabled = true
	env.adjustment_enabled = true
	var g: Dictionary = look.get("grading", {})
	env.adjustment_saturation = float(g.get("saturation", 1.0))
	env.adjustment_contrast = float(g.get("contrast", 1.0))
	env.adjustment_brightness = float(g.get("brightness", 1.0))
	env.glow_bloom = float(g.get("glow", 0.05))
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 250.0
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.name = "Moon"
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 120.0
	var m: Dictionary = look.get("moon", {})
	moon.light_color = Color.html(String(m.get("color", "#8FA8FF")))
	_aim(moon, _to_sky(float(m.get("elevation", 38.0)), float(m.get("azimuth", 120.0))))
	add_child(moon)
	sky_mat.set_shader_parameter("moon_dir", _to_sky(float(m.get("elevation", 38.0)), float(m.get("azimuth", 120.0))))
	_make_lamps(layout_path)
	apply(hour)


func _process(dt: float) -> void:
	if auto:
		hour = fmod(hour + 24.0 * dt / day_seconds, 24.0)
		apply(hour)


## Hướng từ mặt đất tới thiên thể, toạ độ Godot (Bắc = −Z, Đông = +X).
func _to_sky(elev_deg: float, az_deg: float) -> Vector3:
	var e := deg_to_rad(elev_deg)
	var a := deg_to_rad(az_deg)
	return Vector3(sin(a) * cos(e), sin(e), -cos(a) * cos(e))


func _aim(light: DirectionalLight3D, to_sky: Vector3) -> void:
	var up := Vector3.UP if abs(to_sky.y) < 0.99 else Vector3.FORWARD
	light.basis = Basis.looking_at(-to_sky, up)


## Độ cao + phương vị mặt trời theo giờ — cùng công thức blender/scripts/lighting.py → sun_angles().
func sun_angles(h: float) -> Vector2:
	var p: Dictionary = look.get("sun_path", {})
	var rise := float(p.get("rise_hour", 6.0))
	var sett := float(p.get("set_hour", 18.5))
	var t := (h - rise) / (sett - rise)
	var elev := float(p.get("max_elevation", 68.0)) * sin(PI * t) if t >= 0.0 and t <= 1.0 else -10.0
	var az := lerpf(float(p.get("rise_azimuth", 95.0)), float(p.get("set_azimuth", 255.0)), clampf(t, 0.0, 1.0))
	return Vector2(elev, az)


func sample(h: float) -> Dictionary:
	var keys: Array = look.get("cycle", [])
	if keys.is_empty():
		return {"sun_color": Color(1, 0.96, 0.9), "sun_energy": 1.2, "sky_top": Color(0.31, 0.53, 0.78),
			"sky_horizon": Color(0.75, 0.84, 0.9), "fog_color": Color(0.8, 0.85, 0.88), "fog_density": 0.002,
			"ambient": 0.8, "windows": 0.0, "clouds": 0.5, "cloud_color": Color(0.96, 0.95, 0.92)}
	h = fmod(h, 24.0)
	for i in keys.size() - 1:
		var a: Dictionary = keys[i]
		var b: Dictionary = keys[i + 1]
		if h >= float(a["hour"]) and h <= float(b["hour"]):
			var t := (h - float(a["hour"])) / maxf(float(b["hour"]) - float(a["hour"]), 0.0001)
			var out := {}
			for k in a:
				if a[k] is String:
					out[k] = Color.html(a[k]).lerp(Color.html(b[k]), t)
				else:
					out[k] = lerpf(float(a[k]), float(b[k]), t)
			return out
	return sample(0.0)


func apply(h: float) -> void:
	var s := sample(h)
	var sa := sun_angles(h)
	sun.visible = float(s["sun_energy"]) > 0.0 and sa.x > -2.0
	sun.light_color = s["sun_color"]
	sun.light_energy = float(s["sun_energy"])
	_aim(sun, _to_sky(maxf(sa.x, 1.0), sa.y))
	var night := clampf(1.0 - float(s["sun_energy"]) / 0.35, 0.0, 1.0)
	var m: Dictionary = look.get("moon", {})
	moon.visible = night > 0.01
	moon.light_energy = float(m.get("energy", 0.18)) * night

	sky_mat.set_shader_parameter("sky_top", s["sky_top"])
	sky_mat.set_shader_parameter("sky_horizon", s["sky_horizon"])
	sky_mat.set_shader_parameter("clouds", float(s.get("clouds", 0.5)))
	sky_mat.set_shader_parameter("cloud_color", s.get("cloud_color", Color(0.96, 0.95, 0.92)))
	sky_mat.set_shader_parameter("night", night)
	sky_mat.set_shader_parameter("mountain_light", 0.35 + 0.65 * float(s["ambient"]))
	env.fog_light_color = s["fog_color"]
	env.fog_density = float(s["fog_density"]) * float(look.get("fog_scale", 0.15))   # cùng hệ số với khối sương Blender
	env.ambient_light_energy = float(s["ambient"])
	env.tonemap_exposure = 1.0 + 0.8 * night          # đêm vẫn đọc được hình khối (ART_DIRECTION §2)

	var w: Dictionary = look.get("windows", {})
	for l in lamps:
		l.light_energy = float(w.get("energy_godot", 2.5)) * float(s["windows"])
		l.visible = float(s["windows"]) > 0.01


func _make_lamps(layout_path: String) -> void:
	var f := FileAccess.open(layout_path, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return
	var nodes: Dictionary = (parsed as Dictionary).get("nodes", {})
	var w: Dictionary = look.get("windows", {})
	for key in nodes:
		if not String(key).begins_with("HousePoint_"):
			continue
		var n: Dictionary = nodes[key]
		var p: Array = n["pos"]
		var fp: Array = n.get("props", {}).get("footprint", [12.0, 8.0])
		# mặt trước nhà = −Y Blender = +Z cục bộ trong Godot; đèn treo trước cửa, cao 2 m
		var off := Vector3(0.0, 2.0, float(fp[1]) * 0.5 + 0.6).rotated(Vector3.UP, float(n.get("rot_y", 0.0)))
		var l := OmniLight3D.new()
		l.name = String(key) + "_Lamp"
		l.position = Vector3(p[0], p[1], p[2]) + off
		l.light_color = Color.html(String(w.get("color", "#F2B35C")))
		l.omni_range = float(w.get("range", 9.0))
		l.shadow_enabled = false
		add_child(l)
		lamps.append(l)
