extends Node3D
## Xem map để duyệt milestone (docs/ROADMAP.md): M1 greybox, M2 environment (nhà, cây, lúa, tre, nước).
## Nạp GLB lúc chạy (không cần Godot import) từ res://world/generated/, sinh bởi:
##   blender -b -P blender/scripts/generate_map.py -- --stage greybox --godot          (M1)
##   blender -b -P blender/scripts/generate_map.py -- --stage env --swap --godot       (M2, ưu tiên nếu có)
##
## Điều khiển: giữ chuột phải + kéo = nhìn · WASD = bay · Q/E = xuống/lên · Shift = nhanh
##             1…8 = bay tới zone 1…8 · 0 = toàn cảnh · Tab = bật/tắt nhãn · F = bật/tắt sương
##             G = bật/tắt cây cỏ · R = mưa (hiện vũng nước tạm thời)
##             M3: T = chạy/dừng thời gian (75 s/ngày) · [ ] = lùi/tiến 1 giờ · H = giờ vàng · J = trưa · N = đêm

const ZONE_KEYS := ["Z01", "Z02", "Z03", "Z04", "Z05", "Z06", "Z07", "Z08"]
# Tâm nhìn cho zone không có hình chữ nhật (kênh, đường) — toạ độ Bible (x, z), xem MAP_BIBLE §3.
const LINE_ZONE_FOCUS := VillageMap.LINE_ZONE_FOCUS
const MAP_SIZE := VillageMap.MAP_SIZE

var cam: Camera3D
var labels := Node3D.new()
var zone_focus := {}            # "Z01" → Vector3 (toạ độ Godot)
var yaw := 0.0
var pitch := -0.6
var env: Environment
var info: Label
var vmap: VillageMap            # nạp GLB, cây cỏ, ngày–đêm (dùng chung với game — godot/world/village_map.gd)
var foliage: Node3D
var day_night = null          # day_night.gd (không định kiểu để gọi hour/apply/auto của script)
var base_info := ""
var puddles_on := false


func _ready() -> void:
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

	vmap = VillageMap.new()
	vmap.name = "Village"
	add_child(vmap)
	if not vmap.load_map():
		info.text = vmap.error
		return
	env = vmap.env
	day_night = vmap.day_night
	foliage = vmap.foliage
	_load_layout()
	_fly_overview()
	base_info = ("%s · %s · %d cây cỏ\nChuột phải: nhìn · WASD/QE: bay · Shift: nhanh · 1–8: zone · 0: toàn cảnh"
		+ " · Tab: nhãn · F: sương · G: cây cỏ · R: mưa\nT: chạy thời gian · [ ]: ±1 giờ · H: giờ vàng · J: trưa · N: đêm") % [
			"M3 CINEMATIC" if vmap.stage == "env" else "M1 GREYBOX", VillageMap.MAP_NAME, vmap.foliage_count]
	info.text = base_info


func _load_layout() -> void:
	var nodes: Dictionary = vmap.layout
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
		elif k == KEY_F and env:
			env.fog_enabled = not env.fog_enabled
		elif k == KEY_T and day_night:
			day_night.auto = not day_night.auto
		elif (k == KEY_BRACKETLEFT or k == KEY_BRACKETRIGHT) and day_night:
			day_night.hour = fmod(day_night.hour + (1.0 if k == KEY_BRACKETRIGHT else 23.0), 24.0)
			day_night.apply(day_night.hour)
		elif (k == KEY_H or k == KEY_J or k == KEY_N) and day_night:
			day_night.hour = 17.3 if k == KEY_H else (12.0 if k == KEY_J else 22.0)
			day_night.apply(day_night.hour)
		elif k == KEY_G and foliage:
			foliage.visible = not foliage.visible
		elif k == KEY_R:
			puddles_on = not puddles_on
			vmap.set_puddles(puddles_on)


func _process(dt: float) -> void:
	if day_night and base_info != "":
		var hh := float(day_night.hour)
		info.text = base_info + "\n%02d:%02d%s" % [int(hh), int(fmod(hh, 1.0) * 60.0), "  ▶" if day_night.auto else ""]
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
