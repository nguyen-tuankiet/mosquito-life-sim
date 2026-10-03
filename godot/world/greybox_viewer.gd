extends Node3D
## M1 — Xem 3D greybox của map để XÁC NHẬN GIỐNG layout trước khi làm asset (docs/ROADMAP.md).
## Nạp GLB lúc chạy (không cần Godot import) từ res://world/generated/, sinh bởi:
##   blender -b -P blender/scripts/generate_map.py -- --stage greybox --godot
##
## Điều khiển: giữ chuột phải + kéo = nhìn · WASD = bay · Q/E = xuống/lên · Shift = nhanh
##             1…8 = bay tới zone 1…8 · 0 = toàn cảnh · Tab = bật/tắt nhãn · F = bật/tắt sương

const GEN_DIR := "res://world/generated/"
const MAP_NAME := "vietnamese_rural_village"
const ZONE_KEYS := ["Z01", "Z02", "Z03", "Z04", "Z05", "Z06", "Z07", "Z08"]
# Tâm nhìn cho zone không có hình chữ nhật (kênh, đường) — toạ độ Bible (x, z), xem MAP_BIBLE §3.
const LINE_ZONE_FOCUS := {"Z05": Vector2(85, 243), "Z08": Vector2(285, 260)}
const MAP_SIZE := Vector2(500, 540)

var cam: Camera3D
var labels := Node3D.new()
var zone_focus := {}            # "Z01" → Vector3 (toạ độ Godot)
var yaw := 0.0
var pitch := -0.6
var env: Environment
var info: Label


func _ready() -> void:
	_setup_env()
	cam = Camera3D.new()
	cam.far = 3000.0
	add_child(cam)
	add_child(labels)
	info = Label.new()
	info.position = Vector2(12, 10)
	info.add_theme_color_override("font_outline_color", Color.BLACK)
	info.add_theme_constant_override("outline_size", 4)
	var ui := CanvasLayer.new()
	ui.add_child(info)
	add_child(ui)

	var stage := "greybox"
	var path := GEN_DIR + MAP_NAME + "_env.glb"
	if FileAccess.file_exists(path):
		stage = "env"
	else:
		path = GEN_DIR + MAP_NAME + "_greybox.glb"
	if not FileAccess.file_exists(path):
		info.text = "Chưa có %s\nChạy: blender -b -P blender/scripts/generate_map.py -- --stage greybox --godot" % path
		return
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(path, state)
	if err != OK:
		info.text = "Lỗi nạp GLB (%d): %s" % [err, path]
		return
	var root := doc.generate_scene(state)
	add_child(root)
	_fix_materials(root)
	_load_layout()
	_fly_overview()
	info.text = "M1 GREYBOX · %s (%s)\nChuột phải: nhìn · WASD/QE: bay · Shift: nhanh · 1–8: zone · 0: toàn cảnh · Tab: nhãn · F: sương" % [MAP_NAME, stage]


func _setup_env() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = Color(0.35, 0.58, 0.85)
	mat.sky_horizon_color = Color(0.78, 0.85, 0.9)
	sky.sky_material = mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = false
	env.fog_light_color = Color(0.8, 0.85, 0.9)
	env.fog_density = 0.002
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -60, 0)   # nắng chiều thấp, xem docs/ART_DIRECTION.md
	sun.light_color = Color(1.0, 0.9, 0.75)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 400.0
	add_child(sun)


func _fix_materials(n: Node) -> void:
	# Terrain dùng màu đỉnh (COLOR_0) để tô zone; bảo đảm material đọc màu đỉnh.
	if n is MeshInstance3D and n.name.begins_with("Terrain"):
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i)
			if m is BaseMaterial3D:
				var m2 := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
				m2.vertex_color_use_as_albedo = true
				m2.albedo_color = Color.WHITE
				mi.set_surface_override_material(i, m2)
	for c in n.get_children():
		_fix_materials(c)


func _load_layout() -> void:
	var f := FileAccess.open(GEN_DIR + "map_layout.json", FileAccess.READ)
	if f == null:
		return
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	var nodes: Dictionary = data.get("nodes", {})
	for key in nodes:
		var name_s := String(key)
		var n: Dictionary = nodes[key]
		var p: Array = n["pos"]
		var pos := Vector3(p[0], p[1], p[2])
		var props: Dictionary = n.get("props", {})
		if name_s.begins_with("Zone_"):
			var zid: String = props.get("zone", "")
			if not zone_focus.has(zid):
				zone_focus[zid] = Vector3(pos.x, 0, pos.z)
			_label(pos + Vector3(0, 25, 0), "%s  %s" % [zid.substr(2), props.get("zone_name", "")], 64, Color(1, 1, 1))
		elif name_s.begins_with("HousePoint_"):
			_label(pos + Vector3(0, 9, 0), String(props.get("house_id", name_s)), 32, Color(1, 0.85, 0.5))
		elif name_s.begins_with("LandmarkPoint_"):
			_label(pos + Vector3(0, 5, 0), "%s %s" % [props.get("landmark", ""), props.get("label", "")], 24, Color(0.85, 0.95, 1))
		elif name_s.begins_with("EggSite_"):
			_label(pos + Vector3(0, 2, 0), "◆ " + String(props.get("egg_site", "")), 20, Color(1, 0.9, 0.2))
	for zid in LINE_ZONE_FOCUS:
		var b: Vector2 = LINE_ZONE_FOCUS[zid]
		zone_focus[zid] = Vector3(b.x - MAP_SIZE.x / 2, 0, b.y - MAP_SIZE.y / 2)


func _label(pos: Vector3, text: String, size: int, col: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.02
	l.modulate = col
	l.outline_size = 8
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	labels.add_child(l)


func _fly_overview() -> void:
	cam.position = Vector3(0, 380, 330)
	yaw = 0.0
	pitch = deg_to_rad(-48)
	_apply_rot()


func _fly_zone(zid: String) -> void:
	if not zone_focus.has(zid):
		return
	var c: Vector3 = zone_focus[zid]
	cam.position = c + Vector3(0, 90, 110)
	yaw = 0.0
	pitch = deg_to_rad(-38)
	_apply_rot()


func _apply_rot() -> void:
	cam.rotation = Vector3(pitch, yaw, 0)


func _unhandled_input(e: InputEvent) -> void:
	var mm := e as InputEventMouseMotion
	var key := e as InputEventKey
	if mm and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= mm.relative.x * 0.004
		pitch = clamp(pitch - mm.relative.y * 0.004, -1.55, 1.55)
		_apply_rot()
	elif key and key.pressed and not key.echo:
		var k: int = key.keycode
		if k >= KEY_1 and k <= KEY_8:
			_fly_zone(ZONE_KEYS[k - KEY_1])
		elif k == KEY_0:
			_fly_overview()
		elif k == KEY_TAB:
			labels.visible = not labels.visible
		elif k == KEY_F:
			env.fog_enabled = not env.fog_enabled


func _process(dt: float) -> void:
	var v := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): v.z -= 1
	if Input.is_key_pressed(KEY_S): v.z += 1
	if Input.is_key_pressed(KEY_A): v.x -= 1
	if Input.is_key_pressed(KEY_D): v.x += 1
	if Input.is_key_pressed(KEY_E): v.y += 1
	if Input.is_key_pressed(KEY_Q): v.y -= 1
	if v == Vector3.ZERO:
		return
	var speed := 120.0 if Input.is_key_pressed(KEY_SHIFT) else 25.0
	cam.position += cam.global_transform.basis * v.normalized() * speed * dt
