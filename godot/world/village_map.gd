extends Node3D
class_name VillageMap
## Map làng quê (docs/MAP_BIBLE.md) nạp lúc chạy từ res://world/generated/ — dùng chung cho
## greybox_viewer.gd (duyệt map) và adult.gd (M4: muỗi trưởng thành bay trong map thật).
##
## Toạ độ:
##   Bible  (x, z): gốc góc Tây-Bắc, +x Đông, +z Nam (MAP_BIBLE §0, map_spec.json)
##   Godot map    : (x − 250, y, z − 270)  — toạ độ trong GLB / map_layout.json
##   local        : map − origin. adult.gd đặt origin = HousePoint_01 (nhà chính H01) để nhà có nội thất
##                  của game trùng đúng chỗ nhà H01 → mọi toạ độ cũ trong nhà giữ nguyên.
## Node này tự đặt position = −origin nên con của nó (GLB, cây cỏ, đèn) nằm đúng chỗ trong toạ độ local.

const GEN_DIR := "res://world/generated/"
const MAP_NAME := "vietnamese_rural_village"
const MAP_SIZE := Vector2(500, 540)
const WATER_SHADER := preload("res://shaders/water_surface.gdshader")
# mặt nước theo tên mesh (MAP_BIBLE §5 / §6): màu, hướng chảy
const WATER_LOOK := {
	"Water_canal_main": [Color(0.30, 0.46, 0.50, 0.85), Vector2(0.0, 0.25)],
	"Water_canal_branch": [Color(0.36, 0.42, 0.28, 0.9), Vector2(0.0, 0.08)],
	"Water_pond_main": [Color(0.306, 0.463, 0.502, 0.85), Vector2.ZERO],
	"Water_paddy_main": [Color(0.42, 0.50, 0.36, 0.55), Vector2.ZERO],
	"Water_puddle": [Color(0.45, 0.42, 0.34, 0.8), Vector2.ZERO],
}
# M3 — gió cho cây lẻ trong GLB (tên mesh = tên asset): [biên độ ngọn (m), chiều cao (m), tốc độ]
const TREE_WIND := {
	"banana_clump_vn": [0.25, 3.5, 1.0], "coconut_palm": [0.45, 13.0, 0.7], "fruit_tree_01": [0.15, 7.0, 0.9],
	"fruit_tree_02": [0.15, 7.0, 0.9], "banyan_tree": [0.12, 14.0, 0.6],
}
# mặt nước của vật chứa (đo từ asset đã đặt trong map): độ cao trên mặt đất, bán kính miệng
const CONTAINER_WATER := {"jar": [0.774, 0.19], "bucket": [0.207, 0.11]}
# bán kính vùng đẻ trứng quanh EggSite (m) — ao/ruộng/kênh rộng nên đẻ được trên cả vùng nước gần điểm
const SITE_RADIUS := {"puddle": 2.0, "bucket": 0.11, "jar": 0.19, "pond": 28.0, "canal": 6.0, "paddy": 14.0}

var stage := ""                    # "env" | "greybox" | "" (chưa có map)
var error := ""
var origin := Vector3.ZERO
var layout: Dictionary = {}        # map_layout.json → nodes (toạ độ Godot map)
var spec: Dictionary = {}          # map_spec.json (toạ độ Bible)
var root: Node3D                   # cảnh GLB
var foliage: Node3D
var day_night = null               # day_night.gd (không định kiểu: gọi hour/apply/auto của script)
var env: Environment
var puddles: Array[Node3D] = []
var foliage_count := 0
var _h := PackedFloat32Array()     # độ cao địa hình, lưới 1 m (501 × 541), toạ độ Godot map
var _hw := 0
var _hd := 0


static func available() -> bool:
	return FileAccess.file_exists(GEN_DIR + MAP_NAME + "_env.glb") or FileAccess.file_exists(GEN_DIR + MAP_NAME + "_greybox.glb")


## Nạp GLB + layout (+ cây cỏ, ngày–đêm). Trả về false nếu chưa có map (xem `error`).
func load_map(with_foliage: bool = true, with_day_night: bool = true, with_collision: bool = false) -> bool:
	var path := GEN_DIR + MAP_NAME + "_env.glb"
	stage = "env"
	if not FileAccess.file_exists(path):
		path = GEN_DIR + MAP_NAME + "_greybox.glb"
		stage = "greybox"
	if not FileAccess.file_exists(path):
		stage = ""
		error = "Chưa có %s\nChạy: blender -b -P blender/scripts/generate_map.py -- --stage env --swap --godot" % path
		return false
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(path, state)
	if err != OK:
		stage = ""
		error = "Lỗi nạp GLB (%d): %s" % [err, path]
		return false
	root = doc.generate_scene(state)
	add_child(root)
	_fix_materials(root)
	layout = _read_json(GEN_DIR + "map_layout.json").get("nodes", {})
	spec = _read_json(GEN_DIR + "map_spec.json")
	_build_heights()
	if with_day_night:
		day_night = preload("res://world/day_night.gd").new()
		day_night.name = "DayNight"
		add_child(day_night)
		day_night.setup(GEN_DIR + "art_look.json", GEN_DIR + "map_layout.json")
		env = day_night.env
	if with_foliage and stage == "env":
		var loader = preload("res://world/foliage_loader.gd").new()   # không định kiểu: gọi build()/_wind_mesh() của script
		loader.name = "Foliage"
		add_child(loader)
		foliage_count = loader.build(GEN_DIR + "map_points.json", GEN_DIR + "foliage/")
		foliage = loader
		_wind_trees(root, loader, {})
	if with_collision:
		_build_collision()
	return true


func set_origin(o: Vector3) -> void:
	origin = o
	position = -o


func _read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


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
	# chum / xô: asset có sẵn mặt nước (vật liệu "container_water*") nhưng import ra màu nâu như gỗ → gán vật liệu nước
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var cmi := n as MeshInstance3D
		for i in cmi.mesh.get_surface_count():
			var sm0 := cmi.mesh.surface_get_material(i)
			if sm0 != null and sm0.resource_name.begins_with("container_water"):
				cmi.set_surface_override_material(i, _container_water_mat())
				if cmi.name.begins_with("water_jar"):
					# trong chum có "đáy" men sứ nằm ngay trên mặt nước của asset (y≈0,78 > 0,774) nên che mất nước:
					# thêm một mặt nước phía trên đáy đó, dưới miệng chum (y 0,9)
					var disc := MeshInstance3D.new()
					var cm := CylinderMesh.new()
					cm.top_radius = .21
					cm.bottom_radius = .21
					cm.height = .004
					cm.radial_segments = 32
					disc.mesh = cm
					disc.material_override = _container_water_mat()
					disc.position = Vector3(0, .83, 0)
					cmi.add_child(disc)
	if n is MeshInstance3D and n.name.begins_with("Water_"):
		var key := "Water_puddle" if n.name.begins_with("Water_puddle") else String(n.name)
		if WATER_LOOK.has(key):
			var sm := ShaderMaterial.new()
			sm.shader = WATER_SHADER
			sm.set_shader_parameter("water_color", WATER_LOOK[key][0])
			sm.set_shader_parameter("flow", WATER_LOOK[key][1])
			(n as MeshInstance3D).material_override = sm
		if key == "Water_puddle":
			(n as Node3D).visible = false   # chỉ có khi mưa (MAP_BIBLE §5 rain_only)
			puddles.append(n as Node3D)
	for c in n.get_children():
		_fix_materials(c)


static var _cw_mat: StandardMaterial3D

static func _container_water_mat() -> StandardMaterial3D:
	if _cw_mat == null:
		_cw_mat = StandardMaterial3D.new()
		_cw_mat.albedo_color = Color(.2, .38, .42, .88)
		_cw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_cw_mat.roughness = .04
		_cw_mat.metallic = .35
		_cw_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _cw_mat


func _wind_trees(n: Node, loader, cache: Dictionary) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for key in TREE_WIND:
			if mi.mesh and (String(mi.mesh.resource_name).begins_with(key) or String(mi.name).begins_with(key)):
				if not cache.has(mi.mesh):
					cache[mi.mesh] = loader._wind_mesh(mi.mesh, TREE_WIND[key])
				mi.mesh = cache[mi.mesh]
				break
	for c in n.get_children():
		_wind_trees(c, loader, cache)


func set_puddles(on: bool) -> void:
	for p in puddles:
		p.visible = on


## Ẩn một node của GLB (vd. nhà H01 khi game dựng nhà có nội thất ở đúng chỗ đó).
func hide_node(name: String) -> void:
	if root == null:
		return
	var n := root.find_child(name, false, false) as Node3D
	if n:
		n.visible = false


# ───────── địa hình ─────────
func _build_heights() -> void:
	_hw = int(MAP_SIZE.x) + 1
	_hd = int(MAP_SIZE.y) + 1
	_h = PackedFloat32Array()
	_h.resize(_hw * _hd)
	var terrain := root.find_child("Terrain", false, false) as MeshInstance3D if root else null
	if terrain == null or terrain.mesh == null:
		return
	var verts: PackedVector3Array = terrain.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var xf := terrain.transform
	for p0 in verts:
		var p := xf * p0
		var ix := int(round(p.x + MAP_SIZE.x / 2.0))
		var iz := int(round(p.z + MAP_SIZE.y / 2.0))
		if ix >= 0 and ix < _hw and iz >= 0 and iz < _hd:
			_h[iz * _hw + ix] = p.y


## Độ cao mặt đất tại toạ độ Godot map (nội suy song tuyến trên lưới 1 m).
func map_height(x: float, z: float) -> float:
	if _h.is_empty():
		return 0.0
	var fx := clampf(x + MAP_SIZE.x / 2.0, 0.0, _hw - 1.001)
	var fz := clampf(z + MAP_SIZE.y / 2.0, 0.0, _hd - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var a := lerpf(_h[iz * _hw + ix], _h[iz * _hw + ix + 1], tx)
	var b := lerpf(_h[(iz + 1) * _hw + ix], _h[(iz + 1) * _hw + ix + 1], tx)
	return lerpf(a, b, tz)


## Độ cao mặt đất tại toạ độ local (đã trừ origin).
func height_at(x: float, z: float) -> float:
	return map_height(x + origin.x, z + origin.z) - origin.y


## Va chạm: địa hình (HeightMapShape3D từ lưới độ cao) + khối hộp cho các nhà trừ nhà chính H01.
func _build_collision() -> void:
	if _h.is_empty():
		return
	var sb := StaticBody3D.new()
	sb.name = "TerrainCollision"
	var hs := HeightMapShape3D.new()
	hs.map_width = _hw
	hs.map_depth = _hd
	hs.map_data = _h
	var cs := CollisionShape3D.new()
	cs.shape = hs
	sb.add_child(cs)
	for key in layout:
		if not String(key).begins_with("HousePoint_") or String(key) == "HousePoint_01":
			continue
		var n: Dictionary = layout[key]
		var p: Array = n["pos"]
		var fp: Array = n.get("props", {}).get("footprint", [12.0, 8.0])
		var bc := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(float(fp[0]), 4.5, float(fp[1]))
		bc.shape = bs
		bc.position = Vector3(p[0], float(p[1]) + 2.25, p[2])
		bc.rotation.y = float(n.get("rot_y", 0.0))
		sb.add_child(bc)
	add_child(sb)


# ───────── điểm, zone ─────────
## Vị trí local của một node trong map_layout.json (vd. "LandmarkPoint_L10b").
func node_local(name: String) -> Vector3:
	var n: Dictionary = layout.get(name, {})
	if n.is_empty():
		return Vector3.INF
	var p: Array = n["pos"]
	return Vector3(p[0], p[1], p[2]) - origin


func nodes_with_prefix(prefix: String) -> Array:
	var out: Array = []
	for key in layout:
		if String(key).begins_with(prefix):
			out.append(String(key))
	out.sort()
	return out


## Bible (x, z) → local (x, z).
func bible_to_local(b: Vector2) -> Vector2:
	return Vector2(b.x - MAP_SIZE.x / 2.0 - origin.x, b.y - MAP_SIZE.y / 2.0 - origin.z)


func local_to_bible(x: float, z: float) -> Vector2:
	return Vector2(x + origin.x + MAP_SIZE.x / 2.0, z + origin.z + MAP_SIZE.y / 2.0)


## Điểm đẻ trứng cho site game (`Game.SITES.id`): {pos: Vector3(x, z, bán kính), wy: mặt nước} — toạ độ local.
func egg_site(game_site: String) -> Dictionary:
	for key in layout:
		if not String(key).begins_with("EggSite_"):
			continue
		var n: Dictionary = layout[key]
		var props: Dictionary = n.get("props", {})
		if String(props.get("game_site", "")) != game_site:
			continue
		var p: Array = n["pos"]
		var wy := float(p[1])
		var ground := map_height(p[0], p[2])
		if CONTAINER_WATER.has(game_site):
			wy = ground + float(CONTAINER_WATER[game_site][0])
		elif game_site == "puddle":
			wy = ground + 0.03
		return {"pos": Vector3(float(p[0]) - origin.x, float(p[2]) - origin.z, float(SITE_RADIUS.get(game_site, 1.0))),
			"wy": wy - origin.y, "id": String(props.get("egg_site", "")), "zone": String(props.get("zone", ""))}
	return {}


## Zone tại toạ độ local: "Z01"…"Z08" hoặc "" (đất trống xen giữa).
## Kênh (Z05) và đường (Z08) không có hình chữ nhật → đo khoảng cách tới đường tim (map_spec.json).
func zone_at(x: float, z: float) -> String:
	var b := local_to_bible(x, z)
	var water: Dictionary = spec.get("water", {})
	for k in ["canal_main", "canal_branch"]:
		var w: Dictionary = water.get(k, {})
		if not w.is_empty() and _polyline_dist(b, w["centerline"]) < float(w["w"]) * 0.5 + float(w.get("bank_w", 0.0)):
			return "Z05"
	for k in spec.get("roads", {}):
		var r: Dictionary = spec["roads"][k]
		if String(k).begins_with("R") and _polyline_dist(b, r["points"]) < float(r["w"]) * 0.5 + 1.0:
			return "Z08"
	var zones: Dictionary = spec.get("zones", {})
	for zid in spec.get("zone_priority", []):
		for rc in zones.get(zid, {}).get("rects", []):
			if b.x >= rc[0] and b.x <= rc[2] and b.y >= rc[1] and b.y <= rc[3]:
				return zid
	return ""


## Điểm đại diện của zone (Bible x, z): tâm hình chữ nhật lớn nhất; kênh/đường lấy điểm giữa đường tim.
const LINE_ZONE_FOCUS := {"Z05": Vector2(85, 243), "Z08": Vector2(285, 260)}
func zone_focus(zid: String) -> Vector2:
	if LINE_ZONE_FOCUS.has(zid):
		return LINE_ZONE_FOCUS[zid]
	var best := Vector2(MAP_SIZE / 2.0)
	var area := -1.0
	for rc in spec.get("zones", {}).get(zid, {}).get("rects", []):
		var a := (float(rc[2]) - float(rc[0])) * (float(rc[3]) - float(rc[1]))
		if a > area:
			area = a
			best = Vector2((float(rc[0]) + float(rc[2])) / 2.0, (float(rc[1]) + float(rc[3])) / 2.0)
	return best


func zone_name(zid: String) -> String:
	return String(spec.get("zones", {}).get(zid, {}).get("name", "Làng quê"))


func _polyline_dist(p: Vector2, pts: Array) -> float:
	var best := INF
	for i in range(pts.size() - 1):
		var a := Vector2(pts[i][0], pts[i][1])
		var c := Vector2(pts[i + 1][0], pts[i + 1][1])
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, c)))
	return best


# ───────── mạng đường đi bộ cho người dân (MAP v2.2) ─────────
var _astar: AStar2D
var _path_pts: PackedVector2Array = PackedVector2Array()

## Lưới đường đi bộ từ mọi đường/ngõ/lối nhỏ trong map_spec.json (lấy mẫu mỗi 4 m, nối đầu mút vào đường gần nhất).
func build_paths(step: float = 4.0) -> int:
	_astar = AStar2D.new()
	_path_pts = PackedVector2Array()
	var ends: Array = []          # [id, road]
	var road_ids: Dictionary = {}  # road → [ids]
	for rid in spec.get("roads", {}):
		var pts: Array = spec["roads"][rid]["points"]
		var ids: Array = []
		for i in range(pts.size() - 1):
			var a := bible_to_local(Vector2(pts[i][0], pts[i][1]))
			var b := bible_to_local(Vector2(pts[i + 1][0], pts[i + 1][1]))
			var n := maxi(1, int(ceil(a.distance_to(b) / step)))
			for k in range(n + (1 if i == pts.size() - 2 else 0)):
				var p := a.lerp(b, float(k) / n)
				var id := _path_pts.size()
				_path_pts.append(p)
				_astar.add_point(id, p)
				if not ids.is_empty():
					_astar.connect_points(ids[-1], id)
				ids.append(id)
		road_ids[rid] = ids
		ends.append([ids[0], rid])
		ends.append([ids[-1], rid])
	for e in ends:
		var p: Vector2 = _path_pts[e[0]]
		var best := -1
		var bd := 3.5
		for rid in road_ids:
			if rid == e[1]:
				continue
			for id in road_ids[rid]:
				var d := p.distance_to(_path_pts[id])
				if d < bd:
					bd = d
					best = id
		if best >= 0:
			_astar.connect_points(e[0], best)
	return _path_pts.size()


## Lộ trình đi bộ (local x, z) từ `from` tới `to` theo đường làng; điểm cuối là `to`.
func route(from: Vector2, to: Vector2) -> Array:
	if _astar == null or _path_pts.is_empty() or from.distance_to(to) < 6.0:
		return [to]
	var a := _astar.get_closest_point(from)
	var b := _astar.get_closest_point(to)
	var out: Array = []
	for p in _astar.get_point_path(a, b):
		out.append(p)
	# bỏ điểm đầu nếu nó nằm "ngược" (đã đi quá nút gần nhất)
	if out.size() > 1 and from.distance_to(out[1]) < out[0].distance_to(out[1]):
		out.pop_front()
	out.append(to)
	return out


## Cửa nhà (đầu lối nhỏ P_Hxx) — local; Vector2.INF nếu nhà không có lối.
func house_door(hid: String) -> Vector2:
	var r: Dictionary = spec.get("roads", {}).get("P_" + hid, {})
	if r.is_empty():
		return Vector2.INF
	return bible_to_local(Vector2(r["points"][0][0], r["points"][0][1]))


## Chợ làng (MAP v2.1, map_spec.json → market): hình chữ nhật local (x, z); rỗng nếu map không có chợ.
func market_rect() -> Rect2:
	var mk: Dictionary = spec.get("market", {})
	if mk.is_empty():
		return Rect2()
	var c := bible_to_local(Vector2(mk["center"][0], mk["center"][1]))
	var sz := Vector2(mk["size"][0], mk["size"][1])
	return Rect2(c - sz / 2.0, sz)


func in_market(x: float, z: float) -> bool:
	var r := market_rect()
	return r.has_area() and r.grow(2.0).has_point(Vector2(x, z))


## Giờ họp chợ [[mở, đóng], …] (giờ trong ngày).
func market_hours() -> Array:
	return spec.get("market", {}).get("hours", [])


## Vùng bay được (MAP_BIBLE §12 playable_rect, Bible) → Rect2 local (x, z).
func playable_rect() -> Rect2:
	var cam: Dictionary = spec.get("camera", {})
	var r: Array = cam.get("playable_rect", [10, 10, 490, 530])
	var a := bible_to_local(Vector2(r[0], r[1]))
	var c := bible_to_local(Vector2(r[2], r[3]))
	return Rect2(a, c - a)
