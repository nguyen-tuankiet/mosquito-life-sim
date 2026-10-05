extends Node3D
class_name AdultWorld
## Giai đoạn muỗi trưởng thành (3D). Đơn vị: mét. x: đông-tây, z: bắc-nam (nam = +z), y: độ cao.

const HWALL := 2.7
const HX0 := -7.0
const HX1 := 7.0
const HZ0 := -4.5
const HZ1 := 4.5
const FD := Vector2(5, 4.5)
const DOORS := {0: Vector2(-4, .5), 1: Vector2(0, .5), 2: Vector2(4.5, .5)}
const AWARE := {"sleep": .35, "tv": .55, "eat": .8, "cook": 1.0, "walk": 1.15, "brush": .9, "chore": 1.0, "play": 1.3, "study": .7, "read": .55, "exercise": 1.2, "water": 1.0, "stand": 1.0, "alert": 1.7, "idle": 1.0}
const ACTTXT := {"sleep": "đang ngủ", "tv": "xem TV", "eat": "ăn cơm", "cook": "nấu ăn", "walk": "đi lại", "brush": "đánh răng", "chore": "quét dọn", "play": "chơi đùa", "study": "học bài", "read": "đọc/ lướt điện thoại", "exercise": "tập thể dục", "water": "tưới cây", "stand": "đứng lại", "alert": "ĐANG TÌM MUỖI!"}
const SPOT := {
	"bed": {"dad": Vector2(-5.45, -3.35), "mom": Vector2(-5.45, -2.65), "kid": Vector2(-3.2, -3.85)},
	"sink": {"dad": Vector2(-.6, -2.2), "mom": Vector2(-.6, -2.2), "kid": Vector2(-.6, -2.2)},
	"table": {"dad": Vector2(4.4, -2.15), "mom": Vector2(5.6, -.65), "kid": Vector2(6.25, -1.4)},
	"stove": {"dad": Vector2(3.2, -3.6), "mom": Vector2(3.2, -3.6), "kid": Vector2(3.2, -3.6)},
	"chore": {"dad": Vector2(-2, 2.2), "mom": Vector2(-2, 2.2), "kid": Vector2(-2, 2.2)},
	"sofa": {"dad": Vector2(.95, 3.85), "mom": Vector2(.2, 3.85), "kid": Vector2(0, 2.0)},
	"plant": {"dad": Vector2(-5.2, 3.6), "mom": Vector2(-5.2, 3.6), "kid": Vector2(-5.2, 3.6)},
	"gym": {"dad": Vector2(-3.0, -1.2), "mom": Vector2(-3.0, -1.2), "kid": Vector2(-3.0, -1.2)},
	"out": {"dad": Vector2(5, 9), "mom": Vector2(5, 9), "kid": Vector2(5, 9)},
}
const FAMILY := {
	"dad": {"name": "Bố", "model": "man", "h": 1.78, "reward": 1.35, "nr": 2.8, "alert": 1.1, "swat": 1.2, "reach": 2.1, "spd": 1.3,
		"sched": [[0, "sleep", "bed"], [6.3, "exercise", "gym"], [6.6, "brush", "sink"], [6.85, "eat", "table"], [7.4, "away", "out"], [17.5, "read", "sofa"], [18.5, "water", "plant"], [18.85, "eat", "table"], [19.7, "tv", "sofa"], [21.2, "brush", "sink"], [21.6, "sleep", "bed"]]},
	"mom": {"name": "Mẹ", "model": "woman", "h": 1.65, "reward": 1.3, "nr": 2.8, "alert": 1.15, "swat": 1.15, "reach": 2.0, "spd": 1.2,
		"sched": [[0, "sleep", "bed"], [5.9, "brush", "sink"], [6.2, "cook", "stove"], [6.9, "eat", "table"], [7.4, "chore", "chore"], [8.5, "water", "plant"], [9, "away", "out"], [11, "cook", "stove"], [12.5, "eat", "table"], [13, "chore", "chore"], [14, "read", "sofa"], [15, "tv", "sofa"], [17.5, "cook", "stove"], [18.8, "eat", "table"], [19.6, "tv", "sofa"], [21, "brush", "sink"], [21.4, "sleep", "bed"]]},
	"kid": {"name": "Bé", "model": "hoodie", "h": 1.2, "reward": .9, "nr": 3.0, "alert": 1.0, "swat": .95, "reach": 1.6, "spd": 2.0,
		"sched": [[0, "sleep", "bed"], [6.7, "brush", "sink"], [6.95, "eat", "table"], [7.4, "away", "out"], [16.5, "play", "sofa"], [18.4, "study", "table"], [19, "eat", "table"], [19.6, "study", "table"], [20.4, "play", "sofa"], [21, "brush", "sink"], [21.4, "sleep", "bed"]]},
}
const ANIMALS := {
	"mouse": {"name": "Chuột", "nick": "Thức", "model": "mouse", "h": .13, "reward": .6, "nr": 1.4, "alert": .8, "swat": .8, "reach": .5, "home": Vector2(-16, 1), "amp": 2.5, "sp": 1.1, "r": .14, "cy": .08, "walk": "Rat_Walk", "idle": "Rat_Idle"},
	"dog": {"name": "Chó", "nick": "Nguyên", "model": "dog", "h": .6, "reward": 1.0, "nr": 1.9, "alert": 1.0, "swat": 1.0, "reach": 1.0, "home": Vector2(-12, -2), "amp": 3.0, "sp": .5, "r": .45, "cy": .35, "walk": "Walk", "idle": "Idle", "eat": "Eating"},
	"cat": {"name": "Mèo", "nick": "Nhi", "model": "cat", "h": .32, "reward": .9, "nr": 2.0, "alert": 1.3, "swat": 1.1, "reach": .9, "home": Vector2(3, 2.6), "amp": 1.1, "sp": .6, "r": .28, "cy": .2, "walk": "Walk", "idle": "Idle", "eat": "Idle_Eating"},
	"bird": {"name": "Chim", "nick": "Hân", "model": "pigeon", "h": .28, "reward": .8, "nr": 2.4, "alert": 1.4, "swat": 1.4, "reach": 4.0, "home": Vector2(33, 8), "amp": 0.0, "sp": 0.0, "r": .22, "cy": 3.45, "walk": "Walk", "idle": "Idle"},
	"cow": {"name": "Trâu", "nick": "Vy", "model": "cow", "h": 1.4, "reward": 1.1, "nr": 1.5, "alert": .5, "swat": .95, "reach": 2.0, "home": Vector2(27, 4.5), "amp": 1.5, "sp": .4, "r": .9, "cy": .9, "walk": "Walk", "idle": "Idle"},
}

# ── M4: thế giới trưởng thành nằm trong map làng thật (godot/world/village_map.gd) ──
# Toạ độ local: gốc = nhà chính H01 (HousePoint_01) → nhà có nội thất ở trên giữ nguyên toạ độ.
# Chỗ ở của thú cũ khi có map (local x, z); "L10b" = lấy theo LandmarkPoint trong map_layout.json.
const VILLAGE_HOMES := {"mouse": Vector2(-16, 1), "dog": Vector2(-12, 8), "cat": Vector2(3, 2.6), "bird": Vector2(33, 8), "cow": "L10b"}
# Người & vật nuôi theo zone (MAP_BIBLE §13). home: landmark hoặc Bible (x, z); path: đường đi lại (Bible), sp: m/s;
# day: chỉ xuất hiện ban ngày.
const VILLAGE_HOSTS := {
	"hen": {"name": "Gà mái", "nick": "Trọng", "model": "chicken", "h": .5, "reward": .7, "nr": 1.6, "alert": 1.2, "swat": 1.0, "reach": .8, "home": "L04", "amp": 1.6, "sp": .5, "r": .18, "cy": .25, "walk": "Walk", "idle": "Idle", "eat": "Bite_Front", "zone": "Z01"},
	"pig": {"name": "Lợn", "nick": "Giang", "model": "pig", "h": .75, "reward": 1.0, "nr": 1.5, "alert": .6, "swat": .8, "reach": 1.0, "home": "L07", "amp": 0.0, "sp": 0.0, "r": .4, "cy": .38, "walk": "Idle", "idle": "Idle", "zone": "Z02"},
	"villager": {"name": "Người qua đường", "model": "woman", "h": 1.62, "reward": 1.3, "nr": 2.8, "alert": 1.2, "swat": 1.2, "reach": 2.0, "path": [[287, 45], [287, 185], [287, 335], [287, 465]], "sp": 1.25, "r": .3, "cy": .95, "walk": "Female_Walk", "idle": "Female_Idle", "day": true, "zone": "Z08"},
}
# Chợ làng (MAP v2.1): người bán + người mua, chỉ có mặt giờ họp chợ (map_spec.json → market.hours).
# home "market" + off = lệch (m) so với tâm chợ; yaw: hướng mặt (0 = Nam).
const MARKET_HOSTS := {
	"seller1": {"name": "Cô bán rau", "model": "woman", "h": 1.6, "reward": 1.3, "nr": 2.6, "alert": 1.15, "swat": 1.2, "reach": 1.9, "home": "market", "off": Vector2(-11, -9.4), "yaw": 0.0, "amp": 0.0, "sp": 0.0, "r": .3, "cy": .95, "walk": "Female_Idle", "idle": "Female_Idle", "market": true, "zone": "Z08"},
	"seller2": {"name": "Bác bán cá", "model": "man", "h": 1.7, "reward": 1.3, "nr": 2.6, "alert": 1.1, "swat": 1.2, "reach": 2.0, "home": "market", "off": Vector2(0, 10.9), "yaw": PI, "amp": 0.0, "sp": 0.0, "r": .32, "cy": 1.0, "walk": "Man_Idle", "idle": "Man_Idle", "market": true, "zone": "Z08"},
	"seller3": {"name": "Bà bán quả", "model": "woman", "h": 1.55, "reward": 1.2, "nr": 2.4, "alert": 1.0, "swat": 1.1, "reach": 1.6, "home": "market", "off": Vector2(-7.2, -.9), "yaw": .4, "amp": 0.0, "sp": 0.0, "r": .3, "cy": .6, "walk": "Female_Sitting", "idle": "Female_Sitting", "market": true, "zone": "Z08"},
	"buyer1": {"name": "Người đi chợ", "model": "woman", "h": 1.62, "reward": 1.3, "nr": 2.8, "alert": 1.2, "swat": 1.2, "reach": 2.0, "home": "market", "off": Vector2(-2, 0), "amp": 5.0, "sp": .22, "r": .3, "cy": .95, "walk": "Female_Walk", "idle": "Female_Idle", "market": true, "zone": "Z08"},
	"buyer2": {"name": "Người đi chợ", "model": "man", "h": 1.7, "reward": 1.3, "nr": 2.6, "alert": 1.1, "swat": 1.15, "reach": 2.0, "home": "market", "off": Vector2(5, 2), "amp": 4.0, "sp": .27, "r": .32, "cy": 1.0, "walk": "Man_Walk", "idle": "Man_Idle", "market": true, "zone": "Z08"},
	"buyer3": {"name": "Em bé đi chợ", "model": "hoodie", "h": 1.15, "reward": .9, "nr": 3.0, "alert": 1.3, "swat": .95, "reach": 1.5, "home": "market", "off": Vector2(1, -3), "amp": 3.5, "sp": .4, "r": .25, "cy": .6, "walk": "Walk", "idle": "Idle", "market": true, "zone": "Z08"},
}
# ── MAP v2.2: người dân sống theo lịch ──
# Mỗi nhà H02–H18 có 1–2 người; mỗi vai một lịch [giờ bắt đầu, việc]. Đi lại theo đường/ngõ/lối nhỏ (VillageMap.route).
# in = trong nhà (khuất, muỗi không đốt được) · yard = sân · sit = ngồi hóng mát trước nhà · field = bờ ruộng R4
# market = chợ (chỉ khi chợ họp, không thì ở sân) · pond = bờ ao · school = đi học (ra khỏi làng theo R1 phía Bắc)
const RES_SCHED := {
	"farmer": [[0.0, "in"], [5.0, "yard"], [5.6, "field"], [10.8, "in"], [13.6, "field"], [17.0, "yard"], [18.6, "sit"], [20.6, "in"]],
	"trader": [[0.0, "in"], [4.9, "market"], [10.8, "yard"], [11.6, "in"], [14.6, "market"], [18.0, "yard"], [19.0, "sit"], [21.0, "in"]],
	"elder": [[0.0, "in"], [5.8, "sit"], [7.5, "pond"], [10.0, "sit"], [11.5, "in"], [14.5, "sit"], [15.8, "market"], [17.3, "sit"], [19.5, "in"]],
	"kid": [[0.0, "in"], [6.6, "yard"], [7.2, "school"], [16.2, "pond"], [17.6, "yard"], [18.8, "in"]],
}
const RES_TXT := {"in": "trong nhà", "yard": "ở sân", "sit": "ngồi hóng mát", "field": "làm ruộng", "market": "đi chợ",
	"pond": "ra ao", "school": "đi học"}
const RES_ROLE := {"farmer": "Nông dân", "trader": "Người buôn bán", "elder": "Cụ già", "kid": "Em bé"}
const RES_MODEL := {  # model → [chiều cao, cy, đi, đứng, ngồi]
	"man": [1.72, 1.0, "Man_Walk", "Man_Idle", "Man_Sitting"], "woman": [1.6, .95, "Female_Walk", "Female_Idle", "Female_Sitting"],
	"hoodie": [1.15, .6, "Walk", "Idle", "Idle"],
}
# chuồn chuồn (kẻ săn muỗi trưởng thành) theo zone: nhiều ở ao, ruộng, kênh, đồng cỏ (Bible x, z)
const VILLAGE_DRAGONS := [[170, 337], [195, 320], [400, 250], [100, 200], [400, 460], [270, 120]]

class Host extends RefCounted:
	var k := ""
	var def: Dictionary
	var human := false
	var node: Node3D
	var pos := Vector2.ZERO
	var y := 0.0
	var yaw := 0.0
	var alert := 0.0
	var st := "idle"
	var t := 0.0
	var cd := 0.0
	var ph := 0.0
	var act := "idle"
	var away := false
	var walk := false
	var hunt := 0.0
	var wake := 0.0
	var toss := 0.0
	var tossing := 0.0
	var sleeping := false
	var sitting := false
	var wp: Array = []
	var goal := ""
	var ring: MeshInstance3D
	var anim := ""
	var react := ""
	var track := Vector3.ZERO
	var lock := Vector3.ZERO
	var swung := false
	var rig: HumanRig
	var arm_w := 0.0
	var head_w := 0.0
	var tick := 0.0
	var ring_mat: StandardMaterial3D
	var sleep_pos := Vector3.ZERO
	var sleep_init := false
	var sleep_rot := -PI / 2.0
	var sleep_n := 0
	var sched_act := ""
	var wt := 0.0
	var rest_t := 0.0
	var resting := false
	var rest_anim := 0
	var path: Array = []      # M4: đường đi lại (local) cho người qua đường / nông dân
	var fast := 14.0          # MAP v2.2: tốc độ "đi xa" của người dân (đủ tới nơi trong ~2 s game-time)
	var hidden_move := false  # đang đi xa ngoài tầm nhìn → ẩn, hiện lại khi tới nơi hoặc khi muỗi lại gần
	# thoại (godot/scripts/talk.gd)
	var persona := ""         # hien / nong / ron / gia / nit / thatha / coc; "" = thú, không nói
	var me := "tao"           # tiếng tự xưng
	var say_text := ""
	var say_t := 0.0
	var say_cd := 0.0
	var chat_t := 0.0
	var q_text := ""          # câu đáp chờ nói (hàng xóm nói chuyện với nhau)
	var q_t := 0.0
	var bit_said := false
	var seg := 0
	var dir := 1

class Dragon extends RefCounted:
	var node: Node3D
	var pos := Vector3.ZERO
	var c := Vector2.ZERO
	var rad := 6.0
	var a := 0.0
	var by := 2.0
	var st := "patrol"
	var t := 0.0
	var ph := 0.0
	var yaw := 0.0
	var wings: Array = []

class Npc extends RefCounted:
	var node: Node3D
	var pos := Vector3.ZERO
	var home := Vector2.ZERO
	var target := Vector3.ZERO
	var t := 0.0
	var alive := true
	var ph := 0.0

class Flower extends RefCounted:
	var pos := Vector3.ZERO
	var nec := 100.0
	var core: MeshInstance3D

signal finished(eggs: int, site: int)
signal died(cause: String)

var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var body: CharacterBody3D
var mosq: Node3D
var dyn: Node3D
var static_root: Node3D
var room_lights: Array = []
var rain: CPUParticles3D
var clouds: Array = []
var cloud_mat: StandardMaterial3D
var spray_mesh: MeshInstance3D
var door_pivot: Node3D
var door_body: StaticBody3D
var puddle_wet: MeshInstance3D
var puddle_dry: MeshInstance3D
var site_labels: Array = []
var bushes: Array = []
var flowers: Array = []
var hosts: Array = []
var dragons: Array = []
var npcs: Array = []

var built := false
var active := false
var A := {}          # trạng thái thế giới: t, clock, weather, door_open, spray, spray_at, warned
var pl := {}         # trạng thái muỗi
var v := Vector3.ZERO
var view_yaw := 0.0
var view_pitch := -0.1
var mosq_yaw := 0.0
var fxl: FxLayer
var emerge_t := 99.0
var _ripple_t := 0.0
var prompt := ""
var ending: Dictionary = {}
var dead := false
var stage_t := 0.0
var shake := 0.0
var hud_ref: Node
var fx_list: Array = []
var headlight: OmniLight3D
var debug_cam_dist := 0.0
var bed_ref: Node3D
var lie_y := {"dad": .4, "mom": .4, "kid": .35}
var near_host_d := 9.0
var _sy := 0.0
var _sp := 0.0
var _ps := Vector3.ZERO
var vmap: VillageMap = null          # M4: map làng thật; null → thế giới nén cũ quanh nhà
var bounds := Rect2(-38, -24, 76, 48)  # vùng bay (x, z) local
var max_y := 16.0
var zone := ""                       # khu vực hiện tại (Z01…Z08)
var in_market := false               # đang ở chợ làng (MAP v2.1)
var _zone_t := 0.0
var use_village := true              # main.gd tắt bằng --legacy-world

# ═════════════ dựng thế giới tĩnh ═════════════
func _ready() -> void:
	pass

func build() -> void:
	if built:
		return
	built = true
	static_root = Node3D.new()
	add_child(static_root)
	dyn = Node3D.new()
	add_child(dyn)
	fxl = FxLayer.new()
	add_child(fxl)
	if use_village and VillageMap.available():
		_load_village()
	_build_environment()
	if vmap == null:
		_build_ground()
	_build_house()
	if vmap == null:
		_build_yard()
	else:
		_build_village_yard()
	_build_player()

## M4: nạp map làng (GLB + cây cỏ + ngày–đêm + va chạm địa hình), đặt gốc toạ độ ở nhà H01 và
## chuyển các nguồn nước sang đúng điểm đẻ trứng chuẩn (MAP_BIBLE §6).
func _load_village() -> void:
	var t0 := Time.get_ticks_msec()
	var vm := VillageMap.new()
	vm.name = "Village"
	static_root.add_child(vm)
	if not vm.load_map(true, true, true):
		push_warning("Không nạp được map làng — dùng thế giới cũ: " + vm.error)
		vm.queue_free()
		return
	vmap = vm
	var h01: Dictionary = vm.layout.get("HousePoint_01", {})
	var o: Array = h01.get("pos", [0, 0, 0])
	vm.set_origin(Vector3(o[0], o[1], o[2]))
	vm.hide_node("HousePoint_01")       # nhà có nội thất của game thay chỗ nhà H01 trong map
	bounds = vm.playable_rect()
	max_y = float(vm.spec.get("camera", {}).get("adult_max_y", 25.0)) - vm.origin.y
	Game.site_map.clear()
	for i in Game.SITES.size():
		var es := vm.egg_site(String(Game.SITES[i]["id"]))
		if not es.is_empty():
			Game.site_map[i] = es
	print("[village] map nạp trong %d ms · %d cây cỏ · %d nguồn nước chuẩn" % [Time.get_ticks_msec() - t0, vm.foliage_count, Game.site_map.size()])

## Độ cao mặt đất (local). Trong nhà / không có map = 0.
func gy(x: float, z: float) -> float:
	if vmap == null or in_house(x, z, .3):
		return 0.0
	return vmap.height_at(x, z)

func _build_environment() -> void:
	if vmap != null:
		_build_village_environment()
		return
	var we := WorldEnvironment.new()
	env = Environment.new()
	var sky := Sky.new()
	var pm := PanoramaSkyMaterial.new()
	pm.panorama = load("res://assets/textures/sky.hdr")
	sky.sky_material = pm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.12
	# phong cách "Việt Nam rural cinematic realism": màu trầm, ấm, bớt bão hòa
	env.adjustment_enabled = true
	env.adjustment_saturation = .86
	env.adjustment_contrast = 1.05
	env.adjustment_brightness = 1.0
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = .4
	env.fog_enabled = true
	env.fog_light_color = Color(0.74, 0.8, 0.74)
	env.fog_density = 0.004
	we.environment = env
	static_root.add_child(we)
	sun = DirectionalLight3D.new()
	sun.light_energy = 1.9
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	sun.rotation_degrees = Vector3(-52, -30, 0)
	static_root.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 72
	cam.near = 0.02
	cam.far = 300
	static_root.add_child(cam)
	# mây trắng bồng bềnh
	cloud_mat = StandardMaterial3D.new()
	cloud_mat.albedo_color = Color(1, 1, 1, .95)
	cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for ci in 24:
		var cg := Node3D.new()
		var cw := randf_range(14, 26)
		for k in randi_range(4, 7):
			var sph := SphereMesh.new()
			sph.radial_segments = 14
			sph.rings = 7
			var mi := MeshInstance3D.new()
			mi.mesh = sph
			mi.material_override = cloud_mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var rr := randf_range(.35, .6) * cw * (1.0 - .35 * absf(float(k) - 3.0) / 3.0)
			mi.scale = Vector3(rr * 1.3, rr * .5, rr)
			mi.position = Vector3((float(k) - 3.0) * cw * .3, randf_range(-1.5, 2.5), randf_range(-3, 3))
			cg.add_child(mi)
		cg.position = Vector3(randf_range(-150, 150), randf_range(40, 70), randf_range(-150, 60))
		static_root.add_child(cg)
		clouds.append(cg)
	_build_rain()

## M4: trời, nắng, trăng, sương, đèn cửa lấy từ day_night.gd (thông số docs/art_look.json — cùng ảnh duyệt M3).
func _build_village_environment() -> void:
	env = vmap.env
	sun = vmap.day_night.sun
	cam = Camera3D.new()
	cam.fov = 72
	cam.near = 0.02
	cam.far = 2500
	static_root.add_child(cam)
	cloud_mat = StandardMaterial3D.new()    # mây vẽ trong shader trời → không cần mây cầu
	_build_rain()

func _build_rain() -> void:
	rain = CPUParticles3D.new()
	rain.amount = 900
	rain.lifetime = 0.9
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(12, .1, 12)
	rain.direction = Vector3(0, -1, 0)
	rain.gravity = Vector3(0, -22, 0)
	rain.initial_velocity_min = 8
	rain.initial_velocity_max = 10
	rain.emitting = false
	var qm := QuadMesh.new()
	qm.size = Vector2(.012, .35)
	rain.mesh = qm
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.8, 0.88, 1.0, .55)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain.material_override = rm
	static_root.add_child(rain)

func _static_box(parent: Node3D, size: Vector3, center: Vector3, mat: Material, collide: bool = true, name: String = "") -> MeshInstance3D:
	var mi := Assets.box_mesh(size, mat)
	mi.position = center
	parent.add_child(mi)
	if collide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		sb.add_child(cs)
		mi.add_child(sb)
	return mi

func _build_ground() -> void:
	var gm := Assets.tex_material("grass2", Vector3(.1, .1, .1), Color(0.8, 1.0, 0.72))
	var g := Assets.box_mesh(Vector3(240, 1, 240), gm)
	g.position = Vector3(0, -.5, 0)
	static_root.add_child(g)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(240, 1, 240)
	cs.shape = bs
	sb.add_child(cs)
	g.add_child(sb)

func _add_wall(axis: String, f: float, a: float, b: float, gaps: Array, mat: Material) -> void:
	gaps = gaps.duplicate()
	gaps.sort_custom(func(p, q): return p["a"] < q["a"])
	var cur := a
	var seg := func(s: float, e: float, y0: float, y1: float, m: Material) -> void:
		if e - s < .01 or y1 - y0 < .01:
			return
		var ln := e - s
		var h := y1 - y0
		var mid := (s + e) / 2.0
		var ym := (y0 + y1) / 2.0
		var size := Vector3(ln, h, .2) if axis == "z" else Vector3(.2, h, ln)
		var ctr := Vector3(mid, ym, f) if axis == "z" else Vector3(f, ym, mid)
		_static_box(static_root, size, ctr, m)
	for g in gaps:
		seg.call(cur, g["a"], 0.0, HWALL, mat)
		if g["y0"] > 0.0:
			seg.call(g["a"], g["b"], 0.0, g["y0"], mat)
		if g["y1"] < HWALL:
			seg.call(g["a"], g["b"], g["y1"], HWALL, mat)
		if g.get("glass", false):
			var size: Vector3 = Vector3(g["b"] - g["a"], g["y1"] - g["y0"], .06) if axis == "z" else Vector3(.06, g["y1"] - g["y0"], g["b"] - g["a"])
			var mid2: float = (g["a"] + g["b"]) / 2.0
			var ctr: Vector3 = Vector3(mid2, (g["y0"] + g["y1"]) / 2.0, f) if axis == "z" else Vector3(f, (g["y0"] + g["y1"]) / 2.0, mid2)
			_static_box(static_root, size, ctr, Assets.color_material(Color(0.7, 0.85, 0.95, .28), .05))
		cur = g["b"]
	seg.call(cur, b, 0.0, HWALL, mat)

func _put(name: String, h: float, pos: Vector3, yaw_deg: float = 0.0, fit: String = "y", collide: bool = true, piece: String = "") -> Node3D:
	var m := Assets.model(name, h, piece, fit)
	m.position = pos
	m.rotation_degrees.y = yaw_deg
	static_root.add_child(m)
	if collide:
		var a := Assets.aabb_of(m)
		if a.size.x > .05 and a.size.z > .05:
			var sb := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = a.size
			cs.shape = bs
			cs.position = a.get_center()
			sb.add_child(cs)
			m.add_child(sb)
	return m

func _build_house() -> void:
	var wall := Assets.tex_material("wall_plaster", Vector3(.5, .5, .5), Color(1, .95, .85))
	var wood := Assets.tex_material("floor_wood", Vector3(.35, .35, .35))
	var tile := Assets.tex_material("floor_tile", Vector3(.6, .6, .6))
	var tile2 := Assets.tex_material("floor_tile", Vector3(.6, .6, .6), Color(.8, .95, .95))
	# sàn các phòng
	var floor_at := func(w: float, d: float, c: Vector3, m: Material) -> void:
		var mi := Assets.box_mesh(Vector3(w, .02, d), m)
		mi.position = c + Vector3(0, .01, 0)
		static_root.add_child(mi)
	floor_at.call(5.5, 5.0, Vector3(-4.25, 0, -2.0), wood)
	floor_at.call(3.0, 5.0, Vector3(0, 0, -2.0), tile2)
	floor_at.call(5.5, 5.0, Vector3(4.25, 0, -2.0), tile)
	floor_at.call(14.0, 4.0, Vector3(0, 0, 2.5), wood)
	# tường
	_add_wall("z", HZ0, HX0, HX1, [{"a": -5.6, "b": -4.2, "y0": 1.2, "y1": 2.1}, {"a": 3.8, "b": 5.0, "y0": 1.4, "y1": 2.2}], wall)
	_add_wall("x", HX0, HZ0, HZ1, [{"a": -3.4, "b": -2.4, "y0": 1.2, "y1": 2.0}], wall)  # cửa sổ phòng ngủ luôn hé mở
	_add_wall("x", HX1, HZ0, HZ1, [{"a": -3.2, "b": -1.8, "y0": 1.0, "y1": 2.0}, {"a": -1.0, "b": 0.0, "y0": 1.2, "y1": 1.9}], wall)
	_add_wall("z", HZ1, HX0, HX1, [{"a": 4.5, "b": 5.5, "y0": 0.0, "y1": 2.1}, {"a": -5.0, "b": -3.0, "y0": 1.0, "y1": 2.0}, {"a": -.5, "b": 1.5, "y0": 1.0, "y1": 2.0}, {"a": 2.2, "b": 3.6, "y0": 1.0, "y1": 2.0}, {"a": 6.0, "b": 6.8, "y0": 1.4, "y1": 2.2}], wall)
	_add_wall("z", .5, HX0, HX1, [{"a": -4.5, "b": -3.5, "y0": 0.0, "y1": 2.1}, {"a": -.5, "b": .5, "y0": 0.0, "y1": 2.1}, {"a": 3.0, "b": 6.0, "y0": 0.0, "y1": 2.1}], wall)
	_add_wall("x", -1.5, HZ0, .5, [], wall)
	_add_wall("x", 1.5, HZ0, .5, [], wall)
	# trần & mái
	_static_box(static_root, Vector3(14.4, .2, 9.4), Vector3(0, HWALL + .1, 0), Assets.color_material(Color(.93, .9, .84)))
	var roof := Assets.tex_material("rooftile", Vector3(.3, .3, .3), Color(1, .85, .75))
	for sgn in [-1.0, 1.0]:
		var r := Assets.box_mesh(Vector3(16.0, .25, 5.8), roof)
		r.position = Vector3(0, HWALL + 1.25, sgn * 2.55)
		r.rotation_degrees.x = -sgn * 24.0
		static_root.add_child(r)
	var gable := Assets.box_mesh(Vector3(14.4, 1.7, .2), wall)
	gable.position = Vector3(0, HWALL + 1.05, 0)
	gable.scale = Vector3(1, 1, 36)
	static_root.add_child(gable)
	# cửa chính (động)
	door_pivot = Node3D.new()
	door_pivot.position = Vector3(4.5, 0, HZ1)
	static_root.add_child(door_pivot)
	var dm := Assets.box_mesh(Vector3(1.0, 2.1, .06), Assets.tex_material("floor_wood", Vector3(.5, .5, .5), Color(.7, .5, .35)))
	dm.position = Vector3(.5, 1.05, 0)
	door_pivot.add_child(dm)
	var knob := Assets.sphere_mesh(.035, Assets.color_material(Color(.9, .75, .35), .3))
	knob.position = Vector3(.85, 1.0, .05)
	door_pivot.add_child(knob)
	door_body = StaticBody3D.new()
	var dcs := CollisionShape3D.new()
	var dbs := BoxShape3D.new()
	dbs.size = Vector3(1.0, 2.1, .2)
	dcs.shape = dbs
	dcs.position = Vector3(5.0, 1.05, HZ1)
	door_body.add_child(dcs)
	static_root.add_child(door_body)
	# nội thất — phòng ngủ
	var bed := _put("bed_double", 2.1, Vector3(-5.6, 0, -3.0), 90, "z")
	bed_ref = bed
	var bed2 := _put("bed_single", 1.6, Vector3(-3.2, 0, -3.85), 90, "z")
	lie_y["kid"] = Assets.aabb_of(bed2).size.y * .5
	lie_y["dad"] = Assets.aabb_of(bed).size.y * .51
	lie_y["mom"] = lie_y["dad"]
	_put("closet", 2.0, Vector3(-6.55, 0, 1.0), 90)
	# phòng tắm
	_put("toilet", .75, Vector3(-.95, 0, -4.15), 0)
	_put("bathtub", 1.7, Vector3(.55, 0, -3.8), 90, "z")
	_put("sink", .9, Vector3(-1.1, 0, -2.2), -90)
	_put("shower", 2.0, Vector3(1.1, 0, -4.0), 0, "y", false)
	# bếp
	_put("stove", .9, Vector3(3.2, 0, -4.1), 0)
	_put("fridge", 1.8, Vector3(6.4, 0, -4.0), 180)
	_put("table", .75, Vector3(5, 0, -1.4), 90)
	_put("chair", .95, Vector3(4.4, 0, -2.2), 0)
	_put("chair", .95, Vector3(5.6, 0, -2.2), 0)
	_put("chair", .95, Vector3(4.4, 0, -.6), 180)
	_put("chair", .95, Vector3(5.6, 0, -.6), 180)
	# phòng khách
	_put("sofa", .85, Vector3(0, 0, 3.7), 180, "y")
	_put("lamp", 1.5, Vector3(-2.0, 0, 3.8), 0, "y", false)
	var tvs := _static_box(static_root, Vector3(1.6, .45, .45), Vector3(0, .23, 1.0), Assets.tex_material("floor_wood", Vector3(.4, .4, .4), Color(.55, .4, .3)))
	var tvm := _put("tv", .75, Vector3(0, .45, 1.0), 0, "y", false)
	_put("houseplant", .9, Vector3(-5.2, 0, 3.6), 0, "y", false)
	# đèn phòng
	for c in [Vector3(-4.25, 2.3, -2.0), Vector3(0, 2.3, -2.0), Vector3(4.25, 2.3, -2.0), Vector3(0, 2.3, 2.5)]:
		var l := OmniLight3D.new()
		l.position = c
		l.omni_range = 9.0
		l.light_color = Color(1, .88, .68)
		l.light_energy = 0.0
		l.shadow_enabled = false
		static_root.add_child(l)
		room_lights.append(l)

func _water_disc(r: float, c: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = .02
	cm.radial_segments = 40
	mi.mesh = cm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, .82)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = .05
	m.metallic = .3
	mi.material_override = m
	mi.position = pos
	static_root.add_child(mi)
	return mi

func _patch(size: Vector2, c: Vector2, mat: Material, y: float = .012, h: float = .02) -> MeshInstance3D:
	var mi := Assets.box_mesh(Vector3(size.x, h, size.y), mat)
	mi.position = Vector3(c.x, y, c.y)
	static_root.add_child(mi)
	return mi

func _water_box(size: Vector2, c: Vector2, y: float, col: Color, yaw: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, .02, size.y)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r * .6, col.g * .62, col.b * .62, .9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = .3
	m.metallic = .0
	mi.material_override = m
	mi.position = Vector3(c.x, y, c.y)
	mi.rotation.y = yaw
	static_root.add_child(mi)
	return mi

func _scatter(name: String, h: float, p: Vector2, yaw: float = -1.0, fit: String = "y", piece: String = "") -> Node3D:
	return _put(name, h, Vector3(p.x, gy(p.x, p.y), p.y), rnd(0, 360) if yaw < 0.0 else yaw, fit, false, piece)

func _tint(n: Node, col: Color) -> void:
	var m := Assets.color_material(col, .8)
	for c in n.find_children("*", "MeshInstance3D", true, false):
		(c as MeshInstance3D).material_override = m

## Rải nhiều bản sao bằng MultiMesh (rẻ): ruộng lúa, cỏ.
func _multi(name: String, target_h: float, pts: Array, tint: Color = Color(0, 0, 0, 0), vary: float = .25, fit: String = "y") -> void:
	var m := Assets.model(name, target_h, "", fit)
	var inner: Node3D = m.get_meta("inner")
	for c in inner.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if mi.mesh == null:
			continue
		var t := mi.transform
		var p: Node = mi.get_parent()
		while p != null and p != m:
			if p is Node3D:
				t = (p as Node3D).transform * t
			p = p.get_parent()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mi.mesh
		mm.instance_count = pts.size()
		for i in pts.size():
			var s := 1.0 + rnd(-vary, vary)
			var b := Basis(Vector3.UP, rnd(0, TAU)).scaled(Vector3(s, s * rnd(.9, 1.15), s))
			mm.set_instance_transform(i, Transform3D(b, pts[i]) * t)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		if tint.a > 0.0:
			mmi.material_override = Assets.color_material(tint, .8)
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		static_root.add_child(mmi)
	m.free()

func _canal_z(x: float) -> float:
	return 19.2 + 1.6 * sin((x - 9.0) / 7.0)

func _build_canal(bank: Material, bed: Material) -> void:
	var x := -44.0
	while x < 44.0:
		var p0 := Vector2(x, _canal_z(x))
		var p1 := Vector2(x + 2.0, _canal_z(x + 2.0))
		var c := (p0 + p1) / 2.0
		var d := p1 - p0
		var ang := -atan2(d.y, d.x)
		var ln := d.length() + .1
		var nrm := Vector2(-d.y, d.x).normalized()
		var b := Assets.box_mesh(Vector3(ln, .02, 3.4), bed)
		b.position = Vector3(c.x, .02, c.y)
		b.rotation.y = ang
		static_root.add_child(b)
		_water_box(Vector2(ln, 2.5), c, .09, Color(.27, .42, .35), ang)
		for sg in [-1.0, 1.0]:
			var bk := Assets.box_mesh(Vector3(ln, .22, .7), bank)
			bk.position = Vector3(c.x + nrm.x * sg * 1.55, .1, c.y + nrm.y * sg * 1.55)
			bk.rotation.y = ang
			static_root.add_child(bk)
		x += 2.0

func _build_yard() -> void:
	var dirt := Assets.tex_material("ground_dirt", Vector3(.12, .12, .12), Color(.95, .85, .7))
	var road := Assets.tex_material("road", Vector3(.2, .2, .2), Color(1, .95, .85))
	var mud := Assets.tex_material("paddy", Vector3(.15, .15, .15), Color(.7, .65, .5))
	var bank := Assets.tex_material("bank", Vector3(.3, .3, .3), Color(.9, .8, .65))
	var bed := Assets.tex_material("mud2", Vector3(.3, .3, .3), Color(.4, .38, .3))
	# ── núi xa ──
	for i in 9:
		var a := -PI * .95 + float(i) * PI * .24
		var mt := Assets.sphere_mesh(1.0, Assets.color_material(Color(.2, .34, .34).lerp(Color(.3, .45, .42), randf()), 1.0))
		mt.position = Vector3(sin(a) * 150.0, 0, -cos(a) * 150.0) + Vector3(0, -6, 0)
		mt.scale = Vector3(rnd(40, 70), rnd(14, 30), rnd(20, 30))
		mt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		static_root.add_child(mt)
	# ── sân nhà & đường làng ──
	_patch(Vector2(30, 6.4), Vector2(0, 7.8), dirt)
	_patch(Vector2(84, 3.4), Vector2(0, 13.2), road, .013)
	for i in range(-5, 6):
		if i % 2 == 0:
			var po := _scatter("post", 5.2, Vector2(i * 8.0, 11.0), 0.0)
			_tint(po, Color(.55, .52, .47))
	# hàng rào tre dọc đường
	for i in range(-14, 15):
		if absi(i) > 1:
			var fp := Assets.cyl_mesh(.03, .03, 1.0, Assets.color_material(Color(.55, .45, .25)), 6)
			fp.position = Vector3(i * 2.4, .5, 10.9)
			static_root.add_child(fp)
	# ── kênh mương uốn lượn + cầu ──
	_build_canal(bank, bed)
	_put("bridge", 3.6, Vector3(-2, 0.02, _canal_z(-2.0)), 90, "x", false)
	for i in 40:
		var rx := rnd(-40, 40)
		var rzs := _canal_z(rx) + (2.1 if randf() < .5 else -2.1) + rnd(-.3, .3)
		_scatter("grass", rnd(.5, .9), Vector2(rx, rzs), -1.0, "y", "Grass_Large_Extruded")
	for i in 8:
		var rx := rnd(-40, 40)
		_scatter("grass_medium_01", 2.6, Vector2(rx, _canal_z(rx) + (2.4 if i % 2 == 0 else -2.4)), -1.0, "x")
	# ── địa điểm nước ──
	var s0: Vector3 = Game.SITES[0]["pos"]
	puddle_wet = _water_disc(s0.z, Color(.45, .5, .42), Vector3(s0.x, .03, s0.y))
	puddle_dry = Assets.cyl_mesh(s0.z, s0.z, .02, Assets.tex_material("ground_dirt", Vector3(.3, .3, .3)), 32)
	puddle_dry.position = Vector3(s0.x, .03, s0.y)
	puddle_dry.visible = false
	static_root.add_child(puddle_dry)
	var s1: Vector3 = Game.SITES[1]["pos"]
	var bm2 := Assets.color_material(Color(.45, .5, .55), .35)
	bm2.metallic = .6
	var bkt := Assets.cyl_mesh(.2, .15, .38, bm2, 24)
	bkt.position = Vector3(s1.x, .19, s1.y)
	static_root.add_child(bkt)
	var brim := MeshInstance3D.new()
	var btm := TorusMesh.new()
	btm.inner_radius = .17
	btm.outer_radius = .215
	brim.mesh = btm
	brim.material_override = bm2
	brim.position = Vector3(s1.x, .385, s1.y)
	static_root.add_child(brim)
	_water_disc(.18, Color(.3, .5, .6), Vector3(s1.x, .365, s1.y))
	var bh := MeshInstance3D.new()
	var bhm := TorusMesh.new()
	bhm.inner_radius = .2
	bhm.outer_radius = .212
	bh.mesh = bhm
	bh.material_override = bm2
	bh.position = Vector3(s1.x, .5, s1.y)
	bh.rotation_degrees.x = 90.0
	bh.scale = Vector3(1, 1, 1)
	static_root.add_child(bh)
	# chum nước (lu sành) ngoài sân + đồ chứa nước xung quanh
	var s2: Vector3 = Game.SITES[2]["pos"]
	var jm := Assets.color_material(Color(.42, .22, .12), .5)
	var jar := Assets.cyl_mesh(.5, .3, .62, jm, 28)
	jar.position = Vector3(s2.x, .31, s2.y)
	static_root.add_child(jar)
	var jrim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = .4
	tm.outer_radius = .54
	jrim.mesh = tm
	jrim.material_override = jm
	jrim.position = Vector3(s2.x, .64, s2.y)
	static_root.add_child(jrim)
	_water_disc(.43, Color(.3, .42, .36), Vector3(s2.x, .62, s2.y))
	_scatter("Barrel_01", .85, Vector2(s2.x + 1.5, s2.y - .4))
	_scatter("wooden_bucket_01", .5, Vector2(s2.x - 1.3, s2.y + .9))
	_scatter("plastic_container", .43, Vector2(s2.x - 1.9, s2.y - .8), 20.0)
	_water_disc(.3, Color(.35, .5, .5), Vector3(s2.x - 1.9, .39, s2.y - .8))
	var bk1 := _scatter("bucket", .45, Vector2(s2.x + .3, s2.y + 1.5))
	_tint(bk1, Color(.15, .42, .75))
	var bk2 := _scatter("bucket", .4, Vector2(s2.x + 1.1, s2.y + 1.3))
	_tint(bk2, Color(.7, .18, .12))
	_scatter("old_tyre", .6, Vector2(s2.x + 2.8, s2.y + .4), 0.0, "x")
	_scatter("jug_01", .22, Vector2(s2.x - .9, s2.y + 1.7))
	# ao làng: bờ đá, lau sậy, sen, bến & thuyền
	var s3: Vector3 = Game.SITES[3]["pos"]
	_water_disc(s3.z, Color(.14, .36, .42), Vector3(s3.x, .03, s3.y))
	for i in 30:
		var a := float(i) / 30.0 * TAU
		_put("boulder_01" if i % 3 == 0 else "rock", rnd(.3, .7), Vector3(s3.x + cos(a) * (s3.z + .15), 0, s3.y + sin(a) * (s3.z + .15)), rnd(0, 360), "y", false)
	for i in 34:
		var a := float(i) / 34.0 * TAU + .2
		var reed := Assets.cyl_mesh(.012, .02, rnd(1.0, 1.9), Assets.color_material(Color(.38, .58, .22)), 5)
		var rr2 := s3.z + rnd(.3, 1.2)
		reed.position = Vector3(s3.x + cos(a) * rr2, .7, s3.y + sin(a) * rr2)
		reed.rotation_degrees = Vector3(rnd(-8, 8), 0, rnd(-8, 8))
		static_root.add_child(reed)
	for i in 22:
		var a := rnd(0, TAU)
		var rr := rnd(.5, s3.z - .6)
		_put("lilypad", rnd(.45, .8), Vector3(s3.x + cos(a) * rr, .045, s3.y + sin(a) * rr), rnd(0, 360), "x", false)
	_put("modular_wooden_pier", 6.0, Vector3(s3.x - s3.z - 1.6, .0, s3.y), 90, "z", false)
	_put("boat", 3.0, Vector3(s3.x + 1.2, .02, s3.y + 1.7), 70, "x", false)
	for i in 6:
		var a := rnd(0, TAU)
		_scatter("grass_medium_01", 2.2, Vector2(s3.x + cos(a) * (s3.z + 1.4), s3.y + sin(a) * (s3.z + 1.4)), -1.0, "x")
	# kênh mương (điểm đẻ trứng)
	var s4: Vector3 = Game.SITES[4]["pos"]
	_water_box(Vector2(2.6, 2.4), Vector2(s4.x, s4.y), .095, Color(.34, .5, .42))
	# ruộng lúa (2 thửa) + bờ ruộng
	var s5: Vector3 = Game.SITES[5]["pos"]
	var plots := [Rect2(-35, -24, 26, 13), Rect2(-6.5, -24, 9.5, 12)]
	for pi in plots.size():
		var rc: Rect2 = plots[pi]
		var cx := rc.position.x + rc.size.x / 2.0
		var cz := rc.position.y + rc.size.y / 2.0
		_patch(rc.size, Vector2(cx, cz), mud, .02, .02)
		_water_box(rc.size - Vector2(.6, .6), Vector2(cx, cz), .1, Color(.42, .5, .33))
		for e in [[Vector2(rc.size.x + .6, .5), Vector2(cx, rc.position.y)], [Vector2(rc.size.x + .6, .5), Vector2(cx, rc.end.y)], [Vector2(.5, rc.size.y), Vector2(rc.position.x, cz)], [Vector2(.5, rc.size.y), Vector2(rc.end.x, cz)]]:
			var dk := Assets.box_mesh(Vector3(e[0].x, .26, e[0].y), bank)
			dk.position = Vector3(e[1].x, .12, e[1].y)
			static_root.add_child(dk)
		var pts: Array = []
		var gx := rc.position.x + 1.0
		while gx < rc.end.x - .6:
			var gz := rc.position.y + 1.0
			while gz < rc.end.y - .6:
				if pi > 0 or Vector2(gx - s5.x, gz - s5.y).length() > s5.z + .3:
					pts.append(Vector3(gx + rnd(-.2, .2), .08, gz + rnd(-.2, .2)))
				gz += .85
			gx += .85
		_multi("wheat", .95, pts, Color(.42, .68, .2), .25)
	_water_disc(s5.z, Color(.4, .5, .34), Vector3(s5.x, .11, s5.y))
	for i in 3:
		_scatter("hay", 1.3, Vector2(-8.0 + i * 1.6, -10.0 + (i % 2) * .8))
	# ── nhãn ──
	for i in Game.SITES.size():
		var lab := Label3D.new()
		lab.text = Game.SITES[i]["name"]
		lab.font_size = 48
		lab.pixel_size = .004
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.no_depth_test = true
		lab.modulate = Color(1, 1, 1, .95)
		lab.outline_size = 12
		var p: Vector3 = Game.SITES[i]["pos"]
		lab.position = Vector3(p.x, float(Game.SITES[i]["ly"]), p.y)
		lab.visible = false
		static_root.add_child(lab)
		site_labels.append(lab)
	# ── đồng cỏ phía đông ──
	var gp: Array = []
	for i in 260:
		gp.append(Vector3(rnd(14, 37), 0, rnd(1.5, 10)))
	_multi("grass", .55, gp, Color(0, 0, 0, 0), .35, "y")
	for i in 12:
		_scatter("grass_medium_01", rnd(1.8, 2.8), Vector2(rnd(14, 37), rnd(1.5, 10)), -1.0, "x")
	# ── hoa dại (nguồn mật) ──
	var pieces := ["Flower_5_Clump", "Flower_4_Clump", "Flower_3_Clump", "Flower_2_Clump", "Flower_1_Clump"]
	for i in 54:
		var x := 0.0
		var z := 0.0
		var ok := false
		while not ok:
			x = rnd(-34, 36)
			z = rnd(-22, 10)
			ok = not (x > -9 and x < 9 and z > -7 and z < 7)
			ok = ok and not (x < -8.0 and z < -11.0) and not (x > -7 and x < 3.5 and z < -11.0) and not (Vector2(x - s3.x, z - s3.y).length() < s3.z + 2.0)
			ok = ok and not (z > 10.0 and z < 12.0)
			for s in Game.SITES:
				var sp: Vector3 = s["pos"]
				if Vector2(x - sp.x, z - sp.y).length() < sp.z + 1.4:
					ok = false
		var hgt := rnd(.35, .75)
		var m := Assets.model("flowers", hgt, pieces[i % pieces.size()])
		m.position = Vector3(x, 0, z)
		m.rotation_degrees.y = rnd(0, 360)
		static_root.add_child(m)
		var f := Flower.new()
		f.pos = Vector3(x, hgt * .9, z)
		flowers.append(f)
	# ── rừng tre (vùng ẩn nấp) + lối mòn ──
	_patch(Vector2(34, 1.6), Vector2(20, -17.5), Assets.tex_material("dirtpath", Vector3(.25, .25, .25), Color(.9, .8, .65)), .014)
	for i in 18:
		var bp2 := Vector2(rnd(3, 37), rnd(-24, -13)) if i < 14 else Vector2(rnd(-37, -33), rnd(-2, 8))
		if absf(bp2.y + 17.5) < 1.5:
			bp2.y += 3.0
		for k in 4:
			_tint(_scatter("bamboo", rnd(6.5, 9.5), bp2 + Vector2(rnd(-1.4, 1.4), rnd(-1.4, 1.4))), Color(.3, .5, .2))
		bushes.append(Vector3(bp2.x, .9, bp2.y))
		_scatter("shrub_02", 2.2, bp2 + Vector2(rnd(-.5, .5), 1.6), -1.0, "x")
		_scatter("fern_02", 1.4, bp2 + Vector2(rnd(-1, 1), -1.6), -1.0, "x")
	# ── vườn cây: chuối, dừa, bụi quanh nhà & ngõ ──
	for p in [Vector2(-10, 7), Vector2(-11.5, -2), Vector2(9.5, -6.5), Vector2(11, 3), Vector2(-3, 15.8), Vector2(14, 8.5), Vector2(-24, 10), Vector2(26, 10.5), Vector2(-30, 22), Vector2(30, 22), Vector2(0, 22.5), Vector2(-14, -7)]:
		_scatter("palm", rnd(3.2, 4.2), p)
		_scatter("fern_02", rnd(1.8, 2.4), p + Vector2(.9, .5), -1.0, "x")
		bushes.append(Vector3(p.x, .9, p.y))
	for p in [Vector2(-13, 5), Vector2(13, 6), Vector2(-8, -8), Vector2(7.5, -9), Vector2(28, -11), Vector2(-14, 22), Vector2(18, 22), Vector2(35, 12), Vector2(-36, 20)]:
		_scatter("palm", rnd(7.5, 10.0), p)
	for p in [Vector2(-5, -9), Vector2(5, 8.8), Vector2(-17, 9), Vector2(16.5, 9.5), Vector2(22, 11.5), Vector2(-26, 14), Vector2(3, 21.5), Vector2(-12, 21)]:
		_scatter("shrub_0%d" % (1 + randi() % 4), 2.4, p, -1.0, "x")
		bushes.append(Vector3(p.x, .7, p.y))
	_put("trees", 5.5, Vector3(33, 0, 8), 0, "y", false, "NormalTree_2")  # cây có chim
	for p in [Vector3(-20, -9, 7.0), Vector3(34, -3, 8.0), Vector3(-34, 12, 7.5), Vector3(14, 16, 6.0), Vector3(-19, 11, 6.5)]:
		_put("island_tree_0%d" % (1 + randi() % 3), p.z, Vector3(p.x, 0, p.y), rnd(0, 360), "max", false)
	_scatter("tree_stump_01", .55, Vector2(-14, 10.2), -1.0, "y")
	# ── nhà hàng xóm (mái đỏ) ──
	_put("house2", 7.0, Vector3(44, 0, 22), -90, "y", false)
	_put("house2", 7.0, Vector3(-14, 0, 40), 180, "y", false)
	_put("house2", 6.5, Vector3(16, 0, 44), 180, "y", false)
	_put("house2", 6.5, Vector3(46, 0, 4), -90, "y", false)
	_put("house2", 7.0, Vector3(-48, 0, -2), 90, "y", false)
	_put("hut", 3.4, Vector3(-31, 0, 15.5), 20, "y", false)
	# ── chuồng trại ──
	_put("hut", 3.0, Vector3(-21.5, 0, 2.0), 90, "y", false)
	for i in range(0, 8):
		_put("fence", 2.6, Vector3(-37.5 + i * 2.6, 0, -4.5), 0, "x", false)
		_put("fence", 2.6, Vector3(-37.5 + i * 2.6, 0, 8.0), 0, "x", false)
	for i in range(0, 5):
		_put("fence", 2.6, Vector3(-37.5, 0, -4.5 + i * 2.6), 90, "x", false)
	_scatter("pig", .75, Vector2(-30, 5), 40.0)
	_scatter("pig", .65, Vector2(-33, 1.5), -30.0)
	_scatter("hay", 1.2, Vector2(-17.5, 6.0))
	_scatter("Barrel_02", .85, Vector2(-17.5, -2.5))
	# sân nhà: gà, giếng, xe kéo, chum chậu
	for ck in [[Vector2(2.2, 7.0), 30.0, "Idle"], [Vector2(0.4, 8.6), 200.0, "Bite_Front"], [Vector2(-1.6, 6.8), 100.0, "Bite_Front"], [Vector2(8.5, 9.4), 260.0, "Idle"], [Vector2(4.0, 9.8), 150.0, "Bite_Front"]]:
		var cn := _scatter("chicken", .5, ck[0], ck[1])
		Assets.play(cn, String(ck[2]), randf_range(.8, 1.2))
	_scatter("well", 1.6, Vector2(1.5, 9.8), 0.0)
	_scatter("cart", 1.3, Vector2(-8.5, 9.0), 25.0)
	_scatter("hay", 1.4, Vector2(-11.5, 6.0))
	_scatter("wicker_basket_01", .5, Vector2(-6.4, 6.2))
	_scatter("planter_pot_clay", .25, Vector2(-7.0, 5.4))
	_scatter("planter_pot_clay", .25, Vector2(-6.5, 5.1))
	_scatter("wooden_picnic_table", .8, Vector2(-2.5, 8.2), 90.0, "y")
	_scatter("folding_wooden_stool", .4, Vector2(-1.2, 8.4))
	# hiên nhà (mái ngói che phía trước)
	var rf := Assets.tex_material("rooftile", Vector3(.3, .3, .3), Color(1, .85, .75))
	var porch := Assets.box_mesh(Vector3(15.0, .14, 2.7), rf)
	porch.position = Vector3(0, HWALL - .1, HZ1 + 1.2)
	porch.rotation_degrees.x = 10.0
	static_root.add_child(porch)
	for px in [-6.8, -3.0, 2.6, 6.8]:
		var post := Assets.cyl_mesh(.06, .06, HWALL - .1, Assets.tex_material("plank", Vector3(.4, .4, .4), Color(.7, .55, .4)), 8)
		post.position = Vector3(px, (HWALL - .1) / 2.0, HZ1 + 2.35)
		static_root.add_child(post)
	# sương độc
	spray_mesh = Assets.sphere_mesh(1.0, Assets.color_material(Color(.75, 1.0, .35, .22), 1.0))
	spray_mesh.visible = false
	spray_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	static_root.add_child(spray_mesh)

## M4: sân nhà H01 + hoa (nguồn mật), chỗ ẩn nấp và nhãn nguồn nước trong map làng.
## Nhà, cây, ruộng, ao, kênh, đường… đã có trong map (Blender) nên không dựng lại.
func _build_village_yard() -> void:
	# hiên nhà (mái ngói che phía trước) — như thế giới cũ
	var rf := Assets.tex_material("rooftile", Vector3(.3, .3, .3), Color(1, .85, .75))
	var porch := Assets.box_mesh(Vector3(15.0, .14, 2.7), rf)
	porch.position = Vector3(0, HWALL - .1, HZ1 + 1.2)
	porch.rotation_degrees.x = 10.0
	static_root.add_child(porch)
	for px in [-6.8, -3.0, 2.6, 6.8]:
		var post := Assets.cyl_mesh(.06, .06, HWALL - .1 + .3, Assets.tex_material("plank", Vector3(.4, .4, .4), Color(.7, .55, .4)), 8)
		post.position = Vector3(px, (HWALL - .1 - .3) / 2.0, HZ1 + 2.35)
		static_root.add_child(post)
	# sân trước nhà: gà, giếng, bàn ghế, rổ rá (mặt sân thấp hơn nền nhà 0,3 m)
	for ck in [[Vector2(2.2, 7.0), 30.0, "Idle"], [Vector2(0.4, 8.6), 200.0, "Bite_Front"], [Vector2(-1.6, 6.8), 100.0, "Bite_Front"], [Vector2(8.5, 9.4), 260.0, "Idle"]]:
		var cn := _scatter("chicken", .5, ck[0], ck[1])
		Assets.play(cn, String(ck[2]), randf_range(.8, 1.2))
	_scatter("well", 1.6, Vector2(1.5, 9.8), 0.0)
	_scatter("wicker_basket_01", .5, Vector2(-6.4, 6.2))
	_scatter("planter_pot_clay", .25, Vector2(-7.0, 5.4))
	_scatter("planter_pot_clay", .25, Vector2(-6.5, 5.1))
	_scatter("wooden_picnic_table", .8, Vector2(-2.5, 8.2), 90.0, "y")
	_scatter("folding_wooden_stool", .4, Vector2(-1.2, 8.4))
	_put("trees", 5.5, Vector3(33, gy(33, 8), 8), 0, "y", false, "NormalTree_2")  # cây có chim đậu
	# hoa dại (nguồn mật): quanh sân, cạnh từng nguồn nước, vườn, đồng cỏ, ven đường
	var pieces := ["Flower_5_Clump", "Flower_4_Clump", "Flower_3_Clump", "Flower_2_Clump", "Flower_1_Clump"]
	var spots: Array = []
	for i in 14:
		var a := rnd(-PI * .9, PI * .9)
		spots.append(Vector2(sin(a) * rnd(9, 22), absf(cos(a)) * rnd(7, 20) + 5.0))
	for i in Game.SITES.size():
		var sp := Game.site_pos(i)
		for k in 4:
			var a := rnd(0, TAU)
			var rr := sp.z + rnd(1.2, 4.0)
			spots.append(Vector2(sp.x + cos(a) * rr, sp.y + sin(a) * rr))
	for zc in [[Vector2(120, 190), 40.0, 12], [Vector2(400, 460), 40.0, 12], [Vector2(170, 240), 30.0, 8], [Vector2(300, 140), 25.0, 6]]:
		var c: Vector2 = vmap.bible_to_local(zc[0])
		for k in int(zc[2]):
			spots.append(c + Vector2(rnd(-zc[1], zc[1]), rnd(-zc[1], zc[1])))
	var placed := 0
	for p in spots:
		var x: float = p.x
		var z: float = p.y
		var g := vmap.height_at(x, z)
		# chỉ trên đất khô (map y ≥ 0,15: loại ruộng, ao, kênh), ngoài nhà, ngoài vùng bay
		if g + vmap.origin.y < .15 or in_house(x, z, 1.0) or not bounds.has_point(Vector2(x, z)):
			continue
		var hgt := rnd(.35, .75)
		var m := Assets.model("flowers", hgt, pieces[placed % pieces.size()])
		m.position = Vector3(x, g, z)
		m.rotation_degrees.y = rnd(0, 360)
		static_root.add_child(m)
		var f := Flower.new()
		f.pos = Vector3(x, g + hgt * .9, z)
		flowers.append(f)
		placed += 1
	# chỗ ẩn nấp / đậu nghỉ: chuối, dừa, cây vườn trong map (rừng tre Z06 = ẩn khi bay thấp, xem update())
	for prefix in ["BananaPoint_", "CoconutPoint_", "TreePoint_", "GardenTreePoint_", "GardenBananaPoint_", "GardenPalmPoint_", "HayPoint_"]:
		for key in vmap.nodes_with_prefix(prefix):
			var lp := vmap.node_local(key)
			bushes.append(Vector3(lp.x, gy(lp.x, lp.z) + .9, lp.z))
	for k in ["LandmarkPoint_L05", "LandmarkPoint_L05b", "LandmarkPoint_L06", "LandmarkPoint_L06b", "LandmarkPoint_L07"]:
		var lp := vmap.node_local(k)
		if lp != Vector3.INF:
			bushes.append(Vector3(lp.x, gy(lp.x, lp.z) + .9, lp.z))
	# nhãn nguồn nước
	for i in Game.SITES.size():
		var lab := Label3D.new()
		lab.text = Game.SITES[i]["name"]
		lab.font_size = 48
		lab.pixel_size = .004
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.no_depth_test = true
		lab.modulate = Color(1, 1, 1, .95)
		lab.outline_size = 12
		var sp := Game.site_pos(i)
		lab.position = Vector3(sp.x, Game.site_wy(i) + 1.1, sp.y)
		lab.visible = false
		static_root.add_child(lab)
		site_labels.append(lab)
	# sương độc
	spray_mesh = Assets.sphere_mesh(1.0, Assets.color_material(Color(.75, 1.0, .35, .22), 1.0))
	spray_mesh.visible = false
	spray_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	static_root.add_child(spray_mesh)
	print("[village] %d hoa · %d chỗ ẩn nấp" % [placed, bushes.size()])

func rnd(a: float, b: float) -> float:
	return randf_range(a, b)

# ───────── muỗi người chơi ─────────
func _build_player() -> void:
	body = CharacterBody3D.new()
	body.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var cs := CollisionShape3D.new()
	var ss := SphereShape3D.new()
	ss.radius = .035
	cs.shape = ss
	body.add_child(cs)
	add_child(body)
	mosq = make_mosq("F")
	body.add_child(mosq)
	headlight = OmniLight3D.new()
	headlight.omni_range = 4.0
	headlight.light_color = Color(1, .95, .85)
	headlight.light_energy = 0.0
	headlight.position = Vector3(0, .3, .3)
	body.add_child(headlight)

func make_mosq(sex: String) -> Node3D:
	return Bio.make_mosquito(sex)

func flap(g: Node3D, t: float, k: float = 1.0) -> void:
	var a := sin(t * 70.0) * .6 * k
	(g.get_node("wl") as Node3D).rotation.z = -.2 - a
	(g.get_node("wr") as Node3D).rotation.z = .2 + a

# ═════════════ vào giai đoạn ═════════════
func enter(resp: bool) -> void:
	build()
	active = true
	visible = true
	cam.make_current()
	dead = false
	ending = {}
	prompt = ""
	stage_t = 0.0
	for f in fx_list:
		if is_instance_valid(f["n"]): f["n"].queue_free()
	fx_list.clear()
	if not resp:
		Game.q_begin("adultF" if Game.L["sex"] == "F" else "adultM")
		var r := randf()
		Game.L["weather"] = "drought" if r < .18 else ("rain" if r < .4 else "normal")
		_make_world(Game.L["weather"])
		_apply_weather()
	else:
		for h in hosts:
			h.alert = 0.0; h.st = "idle"; h.cd = 0.0; h.hunt = 0.0
		for d in dragons:
			d.st = "patrol"; d.t = 0.0
		if A.get("spray") != null:
			A["spray"] = null; A["warned"] = false; A["spray_at"] = -1.0; spray_mesh.visible = false
	var sp: Vector3 = Game.site_pos(Game.L["site"])
	body.global_position = Vector3(sp.x, Game.site_wy(Game.L["site"]), sp.y)
	v = Vector3.ZERO
	_emerge_setup()
	pl = {"energy": 70.0 if Game.L["sex"] == "F" else 85.0, "age": 0.0, "blood": 0.0, "protein": 0.0, "mated": false, "landed": null, "sucking": false,
		"mate": 0.0, "lay": 0.0, "inv": 0.0, "hidden": false, "exposure": 0.0, "flap": 0.0,
		"mode": "free", "sel": null, "aim": null, "tgt_off": Vector3.ZERO, "tgt_nrm": Vector3.UP, "tgt_h": null, "tgt_i": 0, "spot_o": Vector3.ZERO, "spots": [], "appr_t": 0.0, "retreat_t": 0.0, "retreat_to": Vector3.ZERO, "retreat_spd": 1.8, "retreat_urgent": false, "full_t": 0.0, "nrm": Vector3.UP, "perch": null, "unperch_t": 0.0}
	view_yaw = 0.0
	view_pitch = -.1
	if mosq:
		mosq.queue_free()
	mosq = make_mosq(Game.L["sex"])
	body.add_child(mosq)
	for n in npcs:
		pass
	npcs.clear()
	var cnt := 1 if Game.L["sex"] == "M" else 2
	for i in cnt:
		var x := 0.0
		var z := 0.0
		while true:
			if vmap != null:
				# bạn tình lượn gần nơi vũ hóa (12–24 m), ngoài nhà, trong vùng bay
				var a := rnd(0, TAU)
				x = body.global_position.x + cos(a) * rnd(12, 24); z = body.global_position.z + sin(a) * rnd(12, 24)
				if bounds.has_point(Vector2(x, z)) and not in_house(x, z, 1.0):
					break
				continue
			x = rnd(-22, 28); z = rnd(-14, 16)
			if Vector2(x - body.global_position.x, z - body.global_position.z).length() > 12.0:
				break
		var nn := Npc.new()
		nn.node = make_mosq("F" if Game.L["sex"] == "M" else "M")
		nn.node.scale = Vector3.ONE * .85
		dyn.add_child(nn.node)
		nn.pos = Vector3(x, gy(x, z) + rnd(.8, 2.0), z)
		nn.home = Vector2(x, z)
		nn.target = nn.pos
		nn.ph = rnd(0, 6)
		npcs.append(nn)
	_cam_update(0.0, true)

## Vừa vũ hóa: vỏ nhộng nổi trên mặt nước nơi lăng quăng đã lớn lên, muỗi đứng trên mặt nước, cánh còn nhăn.
func _emerge_setup() -> void:
	var si: int = Game.L["site"]
	var sp: Vector3 = Game.site_pos(si)
	var sy := Game.site_wy(si) - .04
	fxl.clear_all()
	fxl.surf_y = sy
	emerge_t = 0.0
	_ripple_t = 0.0
	var cs := Bio.make_pupa()
	cs.scale = Vector3.ONE * .1
	add_child(cs)
	cs.position = Vector3(sp.x - .03, sy + .01, sp.y - .1)
	cs.rotation = Vector3(deg_to_rad(-72.0), deg_to_rad(randf_range(-30.0, 30.0)), 0)
	fxl.ghost(cs, 150.0, "case", Color(.86, .76, .58, .55))
	cs.queue_free()
	fxl.ring(Vector3(sp.x, sy, sp.y - .1), .5, 2.4)
	fxl.ring(Vector3(sp.x, sy, sp.y - .1), .8, 3.0, .35)
	fxl.bubbles(Vector3(sp.x, sy - .05, sp.y - .1), 8, .25, .5)

func leave() -> void:
	active = false
	visible = false
	Sfx.hum(0, 0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _apply_weather() -> void:
	var w: String = A["weather"]
	rain.emitting = w == "rain"
	if vmap != null:
		vmap.set_puddles(w != "drought")    # vũng nước đồng cỏ khô cạn khi hạn hán (site_dry)
		return                               # sương/nắng theo thời tiết chỉnh trong _animate (day_night ghi đè mỗi khung)
	puddle_dry.visible = w == "drought"
	puddle_wet.visible = w != "drought"
	env.fog_density = .012 if w == "rain" else (.008 if w == "drought" else .004)
	env.fog_light_color = Color(.68, .73, .78) if w == "rain" else (Color(.92, .75, .5) if w == "drought" else Color(.66, .78, .9))

func _make_world(weather: String) -> void:
	for c in dyn.get_children():
		c.queue_free()
	hosts.clear(); dragons.clear(); npcs.clear()
	A = {"t": 0.0, "clock": 18.0 + rnd(0, 3), "weather": weather, "door_open": false, "spray": null, "spray_at": -1.0, "warned": false}
	for f in flowers:
		f.nec = 100.0
	var animals := ANIMALS if vmap == null else _village_hosts()
	for k in animals:
		var d: Dictionary = animals[k]
		var h := Host.new()
		h.k = k; h.def = d; h.human = false
		h.pos = d["home"]; h.y = gy(h.pos.x, h.pos.y) + float(d["cy"]); h.ph = rnd(0, 6); h.yaw = float(d.get("yaw", 0.0))
		if d.has("path"):
			h.path = d["path"]
			h.seg = randi() % maxi(1, h.path.size() - 1)
			h.pos = (h.path[h.seg] as Vector2).lerp(h.path[h.seg + 1], randf())
		h.node = Assets.model(d["model"], d["h"])
		Assets.upgrade_skinned(h.node, d["model"], "human" if d["model"] in ["man", "woman", "hoodie"] else "animal")
		dyn.add_child(h.node)
		Assets.play(h.node, d["idle"])
		hosts.append(h)
	for k in FAMILY:
		var d: Dictionary = FAMILY[k]
		var h := Host.new()
		h.k = k; h.def = d; h.human = true
		var e := _sched(d, A["clock"])
		h.act = e[1]
		h.away = e[1] == "away"
		h.pos = SPOT[e[2]][k]
		h.ph = rnd(0, 6); h.toss = rnd(6, 12)
		h.sleeping = h.act == "sleep"
		h.node = Assets.model(d["model"], d["h"])
		Assets.upgrade_skinned(h.node, d["model"], "human")
		h.rig = HumanRig.attach(h.node)
		dyn.add_child(h.node)
		hosts.append(h)
	for h in hosts:
		_assign_persona(h)
	for h in hosts:
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = Color(1, .12, .1, .2)
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.emission_enabled = true
		rmat.emission = Color(1, .1, .05)
		var ring := Assets.sphere_mesh(1.0, rmat)
		h.ring_mat = rmat
		ring.visible = false
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dyn.add_child(ring)
		h.ring = ring
	var nd := 1 + (1 if Game.L["gen"] > 5 else 0)
	var vd: Array = []   # chuồn chuồn trong làng: ít hơn, và không đặt gần chỗ muỗi nở (≥ 60 m)
	if vmap != null:
		var spawn := Vector2(Game.site_pos(Game.L["site"]).x, Game.site_pos(Game.L["site"]).y)
		for b in VILLAGE_DRAGONS:
			if vmap.bible_to_local(Vector2(b[0], b[1])).distance_to(spawn) >= 60.0:
				vd.append(b)
		nd = mini(vd.size(), 2 + (1 if Game.L["gen"] > 5 else 0))
	for i in nd:
		var d := Dragon.new()
		d.node = _make_dragon(d)
		dyn.add_child(d.node)
		if vmap != null:
			var b: Array = vd[i]
			d.c = vmap.bible_to_local(Vector2(b[0], b[1])) + Vector2(rnd(-4, 4), rnd(-4, 4))
		else:
			d.c = Vector2(rnd(12, 26) if i % 2 == 1 else rnd(-26, -12), rnd(-14, 14))
		d.rad = rnd(5, 9); d.a = rnd(0, 6); d.by = gy(d.c.x, d.c.y) + rnd(1.5, 3.5); d.ph = rnd(0, 6)
		d.pos = Vector3(d.c.x, d.by, d.c.y)
		dragons.append(d)
	if Game.L["gen"] >= 4 and randf() < .6:
		A["spray_at"] = rnd(40, 75)

## M4: thú cũ (chỗ ở dời theo map) + người & vật nuôi theo zone (MAP_BIBLE §13), toạ độ local.
func _village_hosts() -> Dictionary:
	var out := {}
	for k in ANIMALS:
		var d: Dictionary = ANIMALS[k].duplicate()
		d["home"] = _home_local(VILLAGE_HOMES.get(k, d["home"]))
		out[k] = d
	_residents(out)
	var extra := VILLAGE_HOSTS.duplicate()
	if vmap.market_rect().has_area():
		extra.merge(MARKET_HOSTS)
	for k in extra:
		var d: Dictionary = extra[k].duplicate()
		if d.has("path"):
			var pts: Array = []
			for b in d["path"]:
				pts.append(vmap.bible_to_local(Vector2(b[0], b[1])))
			d["path"] = pts
			d["home"] = pts[0]
		else:
			d["home"] = _home_local(d["home"], d.get("off", Vector2.ZERO))
		out[k] = d
	return out

## MAP v2.2: 1–2 người cho mỗi nhà H02–H18 (vai + chỗ làm cố định theo seed của nhà).
func _residents(out: Dictionary) -> void:
	vmap.build_paths()
	var mr := vmap.market_rect()
	for key in vmap.nodes_with_prefix("HousePoint_"):
		var hid: String = "H" + String(key).substr(11)
		if hid == "H01":
			continue
		var door := vmap.house_door(hid)
		if door == Vector2.INF:
			continue
		var hp := vmap.node_local(key)
		var front := (door - Vector2(hp.x, hp.z)).normalized()
		var side := Vector2(-front.y, front.x)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7700 + int(String(key).substr(11))
		var roles := ["farmer" if rng.randf() < .55 else "trader"]
		if rng.randf() < .65:
			roles.append("elder" if rng.randf() < .5 else "kid")
		for i in roles.size():
			var role: String = roles[i]
			var model := "hoodie" if role == "kid" else ("woman" if role == "trader" or rng.randf() < .5 else "man")
			var mdl: Array = RES_MODEL[model]
			var sgn := -1.0 if i == 0 else 1.0
			var tg := {
				"in": door,
				"yard": door + front * 2.5 + side * sgn * rng.randf_range(1.0, 3.0),
				"sit": door + front * 1.4 + side * sgn * 2.2,
				"field": vmap.bible_to_local(Vector2(rng.randf_range(300, 480), 300 + rng.randf_range(-.3, .3))),
				"market": (mr.get_center() + Vector2(rng.randf_range(-11, 11), rng.randf_range(-5, 5))) if mr.has_area() else door,
				"pond": vmap.bible_to_local(Vector2(rng.randf_range(214, 220), 337 + rng.randf_range(-9, 9))),
				"school": vmap.bible_to_local(Vector2(285, 42)),
			}
			out["res_%s_%d" % [hid, i]] = {"name": "%s · nhà %s" % [RES_ROLE[role], hid], "model": model, "h": mdl[0] * (.92 if role == "elder" else 1.0),
				"reward": .9 if role == "kid" else 1.3, "nr": 2.7, "alert": 1.3 if role == "kid" else (.85 if role == "elder" else 1.1),
				"swat": 1.1, "reach": 1.6 if role == "kid" else 2.0, "home": tg[_res_act(role, A["clock"])], "amp": 0.0, "sp": 0.0,
				"r": .26 if role == "kid" else .31, "cy": mdl[1], "walk": mdl[2], "idle": mdl[3], "sit": mdl[4],
				"res": role, "tg": tg, "zone": "Z01"}

## Việc theo lịch của một vai lúc `hr` (chợ không họp → ở sân).
func _res_act(role: String, hr: float) -> String:
	var act := "in"
	for e in RES_SCHED[role]:
		if hr >= float(e[0]):
			act = e[1]
	if act == "market" and vmap != null and _off_hours({"market": true}):
		act = "yard"
	return act

## Đặt ngay mọi người dân vào chỗ theo giờ hiện tại (kiểm thử / ảnh chụp).
func snap_residents() -> void:
	for h in hosts:
		if not h.def.has("res"):
			continue
		var act := _res_act(String(h.def["res"]), A["clock"])
		h.goal = act
		h.act = act
		h.pos = h.def["tg"][act]
		h.wp = []
		h.hidden_move = false
		h.away = act == "in" or act == "school"
		h.sitting = act == "sit"
		h.y = gy(h.pos.x, h.pos.y) + float(h.def["cy"])

## Một người dân: tới chỗ theo lịch bằng đường làng; "in"/"school" = tới nơi thì khuất. Trả về false khi đang khuất.
func _resident(h: Host, dt: float) -> bool:
	var df: Dictionary = h.def
	var act := _res_act(String(df["res"]), A["clock"])
	var tgt: Vector2 = df["tg"][act]
	if act != h.goal:
		h.goal = act
		h.wp = vmap.route(h.pos, tgt)
		h.sitting = false
		var L := 0.0
		var q := h.pos
		for w in h.wp:
			L += q.distance_to(w)
			q = w
		h.fast = maxf(14.0, L / 2.0)
	h.act = act
	if h.away and h.pos.distance_to(tgt) < .3 and (act == "in" or act == "school"):
		return false
	h.away = false
	h.y = gy(h.pos.x, h.pos.y) + float(df["cy"])
	if h.react != "" or h.st == "wind":
		var dv := Vector2(body.global_position.x - h.pos.x, body.global_position.z - h.pos.y)
		if dv.length() > .05:
			h.yaw = lerp_angle(h.yaw, atan2(dv.x, dv.y), 1.0 - exp(-6.0 * dt))
		h.sitting = false
		return true
	if not h.wp.is_empty():
		var p: Vector2 = h.wp[0]
		var dd := p - h.pos
		# gần muỗi thì đi bộ thật; ở xa (ngoài tầm nhìn rõ) đi nhanh để kịp lịch của ngày 75 giây
		var near := Vector2(body.global_position.x, body.global_position.z).distance_to(h.pos) < 60.0
		var spd := (1.8 if df["res"] == "kid" else 1.35) if near else h.fast
		h.hidden_move = not near
		if dd.length() <= spd * dt:
			h.pos = p
			h.wp.pop_front()
		else:
			h.pos += dd.normalized() * spd * dt
			h.yaw = atan2(dd.x, dd.y)
		h.walk = true
		return true
	h.hidden_move = false
	if act == "in" or act == "school":
		h.away = true
		return false
	h.sitting = act == "sit"
	if act == "sit":
		h.yaw = atan2(tgt.x - df["tg"]["in"].x, tgt.y - df["tg"]["in"].y)
	elif act == "field" or act == "market" or act == "pond":
		h.wt -= dt          # làm việc / dạo quanh chỗ đứng
		if h.wt <= 0.0:
			h.wt = rnd(4.0, 9.0)
			h.wp = [tgt + Vector2(rnd(-2.5, 2.5), rnd(-1.5, 1.5))]
	return true

func _home_local(h, off: Vector2 = Vector2.ZERO) -> Vector2:
	if h is String and h == "market":
		return vmap.market_rect().get_center() + off
	if h is String:
		var lp := vmap.node_local("LandmarkPoint_" + String(h))
		return Vector2(lp.x, lp.z) if lp != Vector3.INF else Vector2(10, 10)
	return h

func _make_dragon(d: Dragon) -> Node3D:
	var g := Node3D.new()
	var body_m := Assets.cyl_mesh(.025, .012, .6, Assets.color_material(Color(.12, .55, .55), .4), 8)
	body_m.rotation_degrees.x = 90
	g.add_child(body_m)
	var head := Assets.sphere_mesh(.05, Assets.color_material(Color(.09, .44, .44), .4))
	head.position = Vector3(0, 0, .3)
	g.add_child(head)
	for sx in [-1.0, 1.0]:
		var eye := Assets.sphere_mesh(.025, Assets.color_material(Color(1, .82, .3), .2, .4))
		eye.position = Vector3(sx * .03, .02, .33)
		g.add_child(eye)
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(.8, .9, 1.0, .5)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.cull_mode = BaseMaterial3D.CULL_DISABLED
	for pair in [[-1.0, .12], [1.0, .12], [-1.0, .02], [1.0, .02]]:
		var w := Node3D.new()
		w.position = Vector3(pair[0] * .02, .02, pair[1])
		var pm := PlaneMesh.new()
		pm.size = Vector2(.38, .09)
		var mi := MeshInstance3D.new()
		mi.mesh = pm
		mi.material_override = wm
		mi.position.x = pair[0] * .19
		w.add_child(mi)
		g.add_child(w)
		d.wings.append([w, pair[0]])
	g.scale = Vector3.ONE * 1.3
	return g

func snap_hosts() -> void:
	## đặt mọi người về đúng chỗ theo giờ hiện tại (dùng khi kiểm thử)
	for h in hosts:
		if not h.human: continue
		var e := _sched(h.def, A["clock"])
		h.act = e[1]
		h.away = e[1] == "away"
		h.pos = SPOT[e[2]][h.k]
		h.wp = []
		h.goal = ""
		h.sleeping = h.act == "sleep"
		h.sitting = (h.act == "tv" or h.act == "eat" or h.act == "study" or h.act == "read") and h.k != "kid"
		if h.sleeping: h.yaw = -PI / 2.0

func _sched(df: Dictionary, hr: float) -> Array:
	var e: Array = df["sched"][0]
	for s in df["sched"]:
		if hr >= s[0]:
			e = s
	return e

static func night_amt(h: float) -> float:
	if h >= 20.0 or h < 5.0: return 1.0
	if h >= 18.0: return (h - 18.0) / 2.0
	if h < 7.0: return 1.0 - (h - 5.0) / 2.0
	return 0.0

func room_at(x: float, z: float) -> int:
	if x < HX0 or x > HX1 or z < HZ0 or z > HZ1: return 4
	if z >= .5: return 3
	if x < -1.5: return 0
	if x < 1.5: return 1
	return 2

func in_house(x: float, z: float, m: float = 0.0) -> bool:
	return x > HX0 - m and x < HX1 + m and z > HZ0 - m and z < HZ1 + m

func sense_r() -> float:
	return 14.0 * (1.0 + .12 * Game.tv("det")) * Game.build_factors()["sense"]

# ═════════════ người đi lại theo lịch ═════════════
func route(f: Vector2, t: Vector2) -> Array:
	var r1 := room_at(f.x, f.y)
	var r2 := room_at(t.x, t.y)
	var w: Array = []
	if r1 == r2:
		w.append(t)
		return w
	if r1 <= 2:
		var d: Vector2 = DOORS[r1]
		w.append(Vector2(d.x, d.y - 1)); w.append(Vector2(d.x, d.y + 1))
	elif r1 == 4:
		w.append(Vector2(FD.x, FD.y + 1.6)); w.append(Vector2(FD.x, FD.y - 1))
	if r2 <= 2:
		var d2: Vector2 = DOORS[r2]
		w.append(Vector2(d2.x, d2.y + 1)); w.append(Vector2(d2.x, d2.y - 1))
	elif r2 == 4:
		w.append(Vector2(FD.x, FD.y - 1)); w.append(Vector2(FD.x, FD.y + 1.6))
	w.append(t)
	return w

func update_human(h: Host, dt: float) -> void:
	var df: Dictionary = h.def
	var e := _sched(df, A["clock"])
	var act: String = e[1]
	var tgt: Vector2 = SPOT[e[2]][h.k]
	var spd: float = df["spd"]
	if h.wake > 0.0:
		h.wake -= dt; act = "alert"; tgt = h.pos
	if act == "away":
		if h.away: return
	elif h.away:
		h.away = false; h.pos = SPOT["out"][h.k]; h.wp = []; h.goal = ""
	if act == "chore" or act == "play":
		tgt += Vector2(sin(A["t"] * .5 + h.ph) * 1.2, cos(A["t"] * .4 + h.ph) * .8)
	var ppos := Vector2(body.global_position.x, body.global_position.z)
	if h.hunt > 0.0:
		h.hunt -= dt
		if not pl["hidden"] and room_at(ppos.x, ppos.y) != 4:
			act = "alert"; tgt = ppos; spd *= 1.35
	if h.react != "" and not h.sleeping:
		var dv := Vector2(ppos.x - h.pos.x, ppos.y - h.pos.y)
		if dv.length() > .05:
			h.yaw = lerp_angle(h.yaw, atan2(dv.x, dv.y), 1.0 - exp(-7.0 * dt))
		h.walk = false
		if h.act == "walk":
			h.act = "stand"
		return
	if h.st == "wind": return
	var goal := "%d,%d,%d" % [int(tgt.x), int(tgt.y), room_at(tgt.x, tgt.y)]
	if goal != h.goal or (h.hunt > 0.0 and fmod(A["t"], .6) < dt):
		h.goal = goal; h.wp = route(h.pos, tgt)
	var moving := false
	while h.wp.size() > 0:
		var p: Vector2 = h.wp[0]
		var dd := p - h.pos
		var d := dd.length()
		var last := h.wp.size() == 1
		if d < (.08 if last else .2):
			h.wp.pop_front()
			if last: break
			continue
		var st := minf(d, spd * dt)
		h.pos += dd / d * st
		h.yaw = atan2(dd.x, dd.y)
		moving = true
		break
	h.walk = moving
	h.act = "walk" if moving else act
	if act == "away" and not moving and room_at(h.pos.x, h.pos.y) == 4 and h.pos.y > 7.0:
		h.away = true
	h.sched_act = e[1]
	h.sleeping = h.act == "sleep"
	h.sitting = (h.act == "tv" or h.act == "eat" or h.act == "study" or h.act == "read") and h.k != "kid"
	if not moving:
		match h.act:
			"tv", "read", "cook": h.yaw = PI
			"brush", "water", "sleep": h.yaw = -PI / 2.0
			"exercise": h.yaw = 0.0
			"eat", "study": h.yaw = {"dad": 0.0, "mom": PI, "kid": -PI / 2.0}[h.k]

func host_body(h: Host) -> Dictionary:
	if h.human:
		var s: float = h.def["h"] / 1.78
		if h.sleeping:
			return {"a": Vector3(h.pos.x - .85 * s, lie_y[h.k] + .13 * s, h.pos.y), "b": Vector3(h.pos.x + .9 * s, lie_y[h.k] + .13 * s, h.pos.y), "r": .21 * s}
		if h.sitting:
			return {"a": Vector3(h.pos.x, .5, h.pos.y), "b": Vector3(h.pos.x, 1.3 * s, h.pos.y), "r": .27 * s}
		var g := gy(h.pos.x, h.pos.y)
		return {"a": Vector3(h.pos.x, g + .12, h.pos.y), "b": Vector3(h.pos.x, g + 1.55 * s, h.pos.y), "r": .26 * s}
	var p := Vector3(h.pos.x, h.y, h.pos.y)
	return {"a": p, "b": p, "r": h.def["r"]}

func seg_point(a: Vector3, b: Vector3, p: Vector3) -> Vector3:
	var ab := b - a
	var l2 := ab.length_squared()
	var t := 0.0
	if l2 > 1e-9:
		t = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return a + ab * t

func host_dist(h: Host) -> float:
	var bd := host_body(h)
	var p := seg_point(bd["a"], bd["b"], body.global_position)
	return maxf(0.0, (body.global_position - p).length() - bd["r"])

# ═════════════ vòng cập nhật chính ═════════════
func fwd3() -> Vector3:
	return Vector3(-sin(view_yaw) * cos(view_pitch), sin(view_pitch), -cos(view_yaw) * cos(view_pitch))

func right3() -> Vector3:
	return Vector3(cos(view_yaw), 0, -sin(view_yaw))

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		view_yaw -= event.relative.x * .0025
		view_pitch = clampf(view_pitch - event.relative.y * .0025, -1.3, 1.3)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func fx_text(txt: String, p: Vector3, size: float = .2, life: float = 1.4) -> void:
	var l := Label3D.new()
	l.text = txt
	l.font_size = 64
	l.pixel_size = size / 64.0
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.modulate = Color(1, .3, .55)
	l.position = p
	add_child(l)
	fx_list.append({"n": l, "life": life, "max": life})

func _fx_update(dt: float) -> void:
	for f in fx_list:
		f["life"] -= dt
		if is_instance_valid(f["n"]):
			f["n"].position.y += .35 * dt
			f["n"].modulate.a = clampf(f["life"] / f["max"], 0.0, 1.0)
	for f in fx_list.filter(func(f): return f["life"] <= 0.0):
		if is_instance_valid(f["n"]): f["n"].queue_free()
	fx_list = fx_list.filter(func(f): return f["life"] > 0.0)

func kill(cause: String) -> void:
	if dead:
		return
	dead = true
	shake = .4
	Sfx.beep(180, .5, "saw", .08, -120)
	Sfx.hum(0, 0)
	died.emit(cause)

func update(dt: float) -> void:
	if not active:
		return
	_fx_update(dt)
	if dead:
		_animate(dt)
		return
	A["t"] += dt
	Game.G["life_t"] += dt
	Game.tick_day(dt, Game.DAY_LEN_ADULT)
	stage_t += dt
	A["clock"] = fmod(A["clock"] + dt * Game.CLOCK_RATE, 24.0)
	A["door_open"] = false
	for h in hosts:
		if h.human and not h.away and h.act == "walk" and (h.pos - FD).length() < 1.6:
			A["door_open"] = true
	door_body.get_child(0).disabled = A["door_open"]
	var bf := Game.build_factors()
	pl["flap"] += dt
	pl["inv"] = maxf(0.0, pl["inv"] - dt)
	view_yaw += ((1.0 if Input.is_action_pressed("look_l") else 0.0) - (1.0 if Input.is_action_pressed("look_r") else 0.0)) * 1.9 * dt
	view_pitch = clampf(view_pitch + ((1.0 if Input.is_action_pressed("look_u") else 0.0) - (1.0 if Input.is_action_pressed("look_d") else 0.0)) * 1.3 * dt, -1.3, 1.3)
	if shake > 0.0:
		shake -= dt
	var ppos := body.global_position
	if not ending.is_empty():
		ending["t"] += dt
		Sfx.hum(0, 0)
		v *= .9
		if ending["t"] > 3.4:
			finished.emit(ending["eggs"], ending["site"])
			active = false
		_animate(dt)
		return

	# bay tự do / tự bay tới chỗ hút máu / rút lui
	var fw := fwd3()
	var rt := right3()
	var want := Vector3.ZERO
	if Input.is_action_pressed("fwd"): want += fw
	if Input.is_action_pressed("back"): want -= fw
	if Input.is_action_pressed("right"): want += rt
	if Input.is_action_pressed("left"): want -= rt
	if Input.is_action_pressed("up"): want.y += 1.0
	if Input.is_action_pressed("down"): want.y -= 1.0
	var wants := want.length() > .01
	prompt = ""
	pl["sucking"] = false
	var auto := false
	if Game.q_is_active("dry"):
		auto = true
		v = Vector3.ZERO
		body.velocity = Vector3.ZERO
		Game.q_add("dry", dt)
		prompt = "Đang hong khô cánh — đứng yên chờ cánh cứng lại (xoay chuột để quan sát)"
		if Game.q_done("dry"):
			hud_ref.banner("CÁNH ĐÃ KHÔ", "Bạn có thể bay rồi!")
	elif Game.L["sex"] == "F" and pl["perch"] != null:
		auto = _perch_logic(dt, wants)
	elif Game.L["sex"] == "F":
		auto = _feed_logic(dt, wants)
	if not auto:
		var slow := clampf(near_host_d / 1.2, .6, 1.0)
		var max_sp: float = 2.5 * slow * (1.0 + .08 * Game.tv("mob")) * bf["speed"] * (1.0 - .55 * pl["blood"]) * (.75 if pl["energy"] < 20.0 else 1.0)
		if vmap != null and not in_house(ppos.x, ppos.z, 1.5):
			# M4: làng rộng 500 m — bay cao (trên ngọn cỏ, theo gió) thì nhanh hơn, tối đa ×2,6 ở độ cao ≥ 7,5 m
			max_sp *= 1.0 + 1.6 * clampf((ppos.y - gy(ppos.x, ppos.z) - 1.5) / 6.0, 0.0, 1.0)
		var target := want.normalized() * max_sp if wants else Vector3.ZERO
		if pl["blood"] > .5:
			target.y *= .7   # bụng no máu: bay lên khó hơn
		v = v.lerp(target, 1.0 - exp((-4.5 if wants else -3.2) * dt))
		body.velocity = v
		body.move_and_slide()
		v = body.velocity
	var p2 := body.global_position
	p2.x = clampf(p2.x, bounds.position.x, bounds.end.x); p2.z = clampf(p2.z, bounds.position.y, bounds.end.y)
	p2.y = clampf(p2.y, gy(p2.x, p2.z) + .05, max_y)
	body.global_position = p2
	Game.G["dist"] += v.length() * dt * .3
	ppos = body.global_position
	var spd := v.length()
	pl["hidden"] = false
	if pl["landed"] == null:
		for b in bushes:
			if ppos.distance_to(b) < 1.1:
				pl["hidden"] = true
	if vmap != null:
		_zone_t -= dt
		if _zone_t <= 0.0:
			_zone_t = .25
			_update_zone(ppos)
		# rừng tre / bụi rậm: bay thấp trong bụi là ẩn (MAP_BIBLE §13 Z06 resting_outdoor)
		if zone == "Z06" and pl["landed"] == null and ppos.y < gy(ppos.x, ppos.z) + 4.0:
			pl["hidden"] = true

	# năng lượng & tuổi
	pl["age"] += dt
	pl["energy"] -= (.6 if Game.L["sex"] == "F" else 1.3) * (1.0 + .35 * pl["blood"]) * bf["drain"] * (.5 if pl["landed"] != null else 1.0) * dt
	if not pl["sucking"]:
		pl["blood"] = maxf(0.0, pl["blood"] - .012 * dt)
	if pl["energy"] <= 0.0:
		pl["energy"] = 0.0
		kill("Chết đói — quá lâu không hút được máu" if Game.L["sex"] == "F" else "Kiệt sức vì thiếu năng lượng")
		return
	var max_age := 250.0 if Game.L["sex"] == "M" else 400.0
	if pl["age"] > max_age:
		kill("Hết tuổi thọ trước khi kịp sinh sản")
		return

	# tương tác
	var fl: Flower = null
	var fd := .3
	for f in flowers:
		var d := ppos.distance_to(f.pos + Vector3(0, .03, 0))
		if d < fd:
			fd = d; fl = f
	var mate: Npc = null
	for n in npcs:
		if n.alive and ppos.distance_to(n.pos) < 1.0:
			mate = n
	near_host_d = 9.0
	if Game.L["sex"] == "F":
		for h in hosts:
			if not h.away:
				near_host_d = minf(near_host_d, host_dist(h))
	if Game.L["sex"] == "F" and near_host_d < 3.0:
		Game.q_set("host", 1.0)
	var over_site := -1
	if Game.L["sex"] == "F" and pl["mated"] and Game.q_done("digest"):
		over_site = _site_over()
	var act_hold := Input.is_action_pressed("act")
	var act_hit := Input.is_action_just_pressed("act")
	if pl["mode"] != "free":
		pass
	elif mate != null and not pl["mated"] and (Game.q_is_active("mate") or Game.q_all_done()):
		prompt = "Giữ E để giao phối (đứng gần muỗi kia, nó sẽ bay chậm lại)"
		if act_hold:
			pl["mate"] += dt
			mate.pos = mate.pos.lerp(ppos + Vector3(0, .02, 0), minf(1.0, dt * 4.0))
			if randf() < dt * 5.0: fx_text("♥", ppos + Vector3(0, .1, 0), .15, 1.0)
			if pl["mate"] >= 1.2:
				_complete_mate(mate)
		else:
			pl["mate"] = maxf(0.0, pl["mate"] - dt * .4)
	elif over_site >= 0:
		pl["mate"] = maxf(0.0, pl["mate"] - dt)
		if Game.site_dry(over_site):
			prompt = "Chỗ này đã khô cạn!"
			pl["lay"] = 0.0
		else:
			prompt = "Giữ E: đẻ trứng ở %s" % Game.SITES[over_site]["name"]
			if act_hold:
				pl["lay"] += dt
				if pl["lay"] >= 1.8:
					_lay_eggs(over_site)
			else:
				pl["lay"] = maxf(0.0, pl["lay"] - dt)
	elif fl != null and fl.nec > 0.0:
		pl["mate"] = maxf(0.0, pl["mate"] - dt)
		prompt = "Giữ E: hút mật hoa"
		if act_hold:
			pl["energy"] = minf(100.0, pl["energy"] + 32.0 * bf["nectar"] * (.45 if Game.L["sex"] == "F" else 1.0) * (1.0 + .1 * Game.tv("fee")) * dt)
			fl.nec = maxf(0.0, fl.nec - 22.0 * dt)
			Game.G["nectar"] += 32.0 * dt
			Game.q_add("nectar", 6.0 * dt)
	else:
		pl["mate"] = maxf(0.0, pl["mate"] - dt)
		pl["lay"] = maxf(0.0, pl["lay"] - dt)
		pl["unperch_t"] = maxf(0.0, pl["unperch_t"] - dt)
		if Game.L["sex"] == "F" and pl["perch"] == null and pl["unperch_t"] <= 0.0 and mate == null:
			var ps := _perch_surface(ppos)
			if not ps.is_empty():
				if prompt == "":
					prompt = "Nhấn E: đậu nghỉ ở đây"
				if act_hit:
					pl["perch"] = ps["nrm"]
					body.global_position = ps["pos"]
					v = Vector3.ZERO
					Sfx.beep(300, .06, "sine", .03, 60)
		if mate != null and not pl["mated"]:
			prompt = "Chưa tới lúc giao phối — hoàn thành nhiệm vụ hiện tại trước"
		elif Game.L["sex"] == "F" and pl["mated"] and not Game.q_done("digest") and _site_over() >= 0:
			prompt = "Chưa thể đẻ: cần hút máu và nghỉ ngơi tiêu hóa trước"
	if Game.L["sex"] == "F" and Game.q_is_active("digest"):
		if pl["perch"] != null:
			Game.q_add("digest", dt)
			prompt = "Đang đậu nghỉ tiêu hóa máu (%d/15 giây) — phím di chuyển hoặc E để bay đi" % int(Game.q_find("digest")["prog"])
		elif prompt == "":
			prompt = "Bụng nặng, bay chậm — lại sát bụi cây / tường / trần rồi nhấn E để đậu nghỉ (%d/15 giây)" % int(Game.q_find("digest")["prog"])
	for f in flowers:
		if f.nec < 100.0: f.nec = minf(100.0, f.nec + 4.0 * dt)

	# vật chủ: sinh hoạt, cảnh giác & đập
	var stealth: float = bf["stealth"] * maxf(.5, 1.0 - .05 * Game.tv("det"))
	for h in hosts:
		var df: Dictionary = h.def
		_talk_update(h, dt, ppos)
		if not h.human and not df.has("res"):
			h.away = false
		if h.human:
			update_human(h, dt)
			if h.away:
				h.alert = 0.0; h.st = "idle"
				continue
		elif df.has("res"):
			if not _resident(h, dt):
				h.alert = 0.0; h.st = "idle"
				continue
		elif _off_hours(df):
			h.away = true     # người ngoài đồng / đường chỉ ra ngoài ban ngày; chợ chỉ đông giờ họp chợ
			h.alert = 0.0; h.st = "idle"
			continue
		elif not h.path.is_empty():
			h.away = false
			_walk_path(h, dt)
		elif df["amp"] > 0.0:
			h.away = false
			var home: Vector2 = df["home"]
			h.rest_t -= dt
			if h.rest_t <= 0.0:
				h.resting = not h.resting
				h.rest_t = rnd(3.0, 7.0) if h.resting else rnd(5.0, 11.0)
				h.rest_anim = randi() % 2
			if not h.resting:
				h.wt += dt
			var np := Vector2(home.x + sin(h.wt * df["sp"] + h.ph) * df["amp"], home.y + cos(h.wt * df["sp"] * .8 + h.ph) * df["amp"] * .7)
			if vmap != null:
				h.y = gy(np.x, np.y) + float(df["cy"])
			if not h.resting and (np - h.pos).length() > .002:
				h.yaw = atan2(np.x - h.pos.x, np.y - h.pos.y)
				h.walk = true
			h.pos = np
		h.cd = maxf(0.0, h.cd - dt)
		if h.st == "wind":
			h.t -= dt
			var swing_len := .22
			if h.t > swing_len:
				h.track = h.track.lerp(_threat_point(), 1.0 - exp(-3.5 * dt))   # bám theo muỗi chậm → có thể né
				h.tick -= dt
				if h.tick <= 0.0:
					h.tick = .18
					Sfx.beep(1150, .06, "square", .05)
			elif not h.swung:
				h.swung = true
				h.lock = h.track
			if h.t <= 0.0:
				h.st = "idle"
				h.swung = false
				h.cd = 1.6 if h.human else 3.0
				h.alert = .35
				h.react = ""
				if h.human:
					h.hunt = 6.0
					if h.sleeping: h.wake = 12.0
				var hit_r := .55 if (h.k == "dad" or h.k == "mom") else .45
				if ppos.distance_to(h.lock) < hit_r:
					_say(h, "hit", 1.0, true)
					kill("Bị %s đập chết" % _who(h))
					return
				fx_text("hụt!", h.lock + Vector3(0, .1, 0), .16, 1.0)
				_say(h, "miss", .85, true)
				Sfx.beep(220, .12, "square", .05, -100)
			continue
		var d := host_dist(h)
		var g := 0.0
		if pl["landed"] != null and pl["landed"]["h"] == h:
			g = (.08 + .18 * pl["blood"]) if pl["sucking"] else .02
		elif d < df["nr"] and not pl["hidden"]:
			g = .025 + .09 * minf(1.0, spd / 4.0)
		if h.human and h.hunt > 0.0 and not pl["hidden"] and (room_at(ppos.x, ppos.z) == room_at(h.pos.x, h.pos.y) or d < 3.0):
			g = maxf(g, .35)
		var aw: float = AWARE.get("alert" if h.hunt > 0.0 else h.act, 1.0) if h.human else 1.0
		g *= df["alert"] * stealth * aw
		if h.human and h.sleeping:
			h.toss -= dt
			if h.toss <= 0.0:
				h.tossing = 1.2; h.toss = rnd(8, 14)
			if h.tossing > 0.0:
				h.tossing -= dt
				if pl["landed"] != null and pl["landed"]["h"] == h:
					g += .35 * stealth
		if g > 0.0: h.alert += g * dt
		else: h.alert = maxf(0.0, h.alert - .14 * dt)
		if h.alert >= 1.0 and h.cd <= 0.0:
			_say(h, "swat", .8, true)
			h.st = "wind"
			h.t = .7 if h.k == "kid" else .9
			h.track = ppos
			h.swung = false
			Game.G["noticed"] += 1
			Sfx.beep(900, .25, "square", .06, -300)
			if h.sleeping: h.wake = 12.0
		elif h.alert > 1.0:
			h.alert = 1.0
		# dấu hiệu cho người chơi: nghi ngờ → gãi/khó chịu → giơ tay đập
		var rs := ""
		if h.st == "wind": rs = "wind"
		elif h.alert >= .7: rs = "scratch"
		elif h.alert >= .4: rs = "notice"
		if rs != h.react:
			if rs == "notice":
				_say(h, "night_hear" if h.sleeping else "hear", .7)
			elif rs == "scratch":
				_say(h, "scratch", .9, h.say_t <= 0.0)
			elif rs == "" and h.react == "scratch":
				_say(h, "lost", .5)
			if rs == "notice": Sfx.beep(520, .09, "triangle", .05)
			elif rs == "scratch":
				Sfx.beep(760, .09, "square", .05)
			h.react = rs
		if h.react != "" and d < 5.0:
			h.tick -= dt
			if h.tick <= 0.0:
				h.tick = clampf(1.1 - h.alert, .15, .8)
				Sfx.beep(600 + 500 * h.alert, .04, "sine", .03 + .03 * h.alert)

	# chuồn chuồn (chỉ ngoài trời)
	var dsense := 7.0 * (1.0 / maxf(.6, bf["stealth"] + .1)) * (1.1 if Game.L["gen"] > 3 else 1.0) * (.8 if Game.G["build"] == "survivor" else 1.0)
	for d in dragons:
		if d.st == "patrol":
			d.a += dt * .5
			var nx: float = d.c.x + cos(d.a) * d.rad
			var nz: float = d.c.y + sin(d.a * 1.3) * d.rad
			d.yaw = atan2(nx - d.pos.x, nz - d.pos.z)
			d.pos = Vector3(nx, d.by + sin(A["t"] * 1.2 + d.ph) * .6, nz)
			var dd := ppos.distance_to(d.pos)
			if not pl["hidden"] and emerge_t > 25.0 and dd < dsense and (spd > 1.2 or dd < 2.5):   # 25 giây đầu sau khi nở: chuồn chuồn chưa để ý
				d.st = "chase"; d.t = 3.4
				Game.G["noticed"] += 1
				Sfx.beep(1000, .15, "saw", .05)
		elif d.st == "chase":
			d.t -= dt
			var dv: Vector3 = ppos - d.pos
			var dl: float = maxf(dv.length(), .001)
			d.pos += dv / dl * 2.3 * dt
			d.yaw = atan2(dv.x, dv.z)
			if in_house(d.pos.x, d.pos.z, 1.2):
				var l: float = d.pos.x - (HX0 - 1.2)
				var r: float = HX1 + 1.2 - d.pos.x
				var t: float = d.pos.z - (HZ0 - 1.2)
				var b: float = HZ1 + 1.2 - d.pos.z
				var m: float = minf(minf(l, r), minf(t, b))
				if m == l: d.pos.x = HX0 - 1.2
				elif m == r: d.pos.x = HX1 + 1.2
				elif m == t: d.pos.z = HZ0 - 1.2
				else: d.pos.z = HZ1 + 1.2
			var dg := gy(d.pos.x, d.pos.z)
			d.pos.y = clampf(d.pos.y, dg + .3, dg + 8.0)
			if ppos.distance_to(d.pos) < .38:
				kill("Bị chuồn chuồn bắt")
				return
			if pl["hidden"] or d.t <= 0.0 or in_house(ppos.x, ppos.z, 0.0):
				var rg := gy(d.pos.x, d.pos.z)
				d.st = "rest"; d.t = 2.0; d.by = clampf(d.pos.y, rg + 1.2, rg + 4.0); d.c = Vector2(d.pos.x, d.pos.z)
		else:
			d.t -= dt
			if d.t <= 0.0: d.st = "patrol"

	# NPC bạn tình & tiếng vỗ cánh
	for n in npcs:
		if not n.alive: continue
		n.t -= dt
		if n.t <= 0.0:
			n.t = rnd(1.5, 3.5)
			var tx := clampf(n.home.x + rnd(-4, 4), bounds.position.x + 4, bounds.end.x - 4)
			var tz := clampf(n.home.y + rnd(-4, 4), bounds.position.y + 2, bounds.end.y - 2)
			n.target = Vector3(tx, gy(tx, tz) + rnd(.6, 2.2), tz)
		var dv2: Vector3 = n.target - n.pos
		var calm := 1.0
		if ppos.distance_to(n.pos) < 3.0:
			calm = .2   # bị tiếng vỗ cánh thu hút: bay chậm lại, lượn quanh
		if pl["mate"] > 0.0 and ppos.distance_to(n.pos) < 1.6:
			calm = 0.0
		if dv2.length() > .01:
			n.pos += dv2.normalized() * .9 * calm * dt
	var tgt: Npc = null
	var td := 1e9
	if not pl["mated"]:
		for n in npcs:
			if n.alive:
				var dd2 := ppos.distance_to(n.pos)
				if dd2 < td:
					td = dd2; tgt = n
	if tgt != null and Game.L["sex"] == "M" and td < 8.0:
		Game.q_set("swarm", 1.0)
	if tgt != null:
		var to := tgt.pos - ppos
		Sfx.hum(pow(clampf(1.0 - td / (16.0 * (1.0 + .12 * Game.tv("det"))), 0.0, 1.0), 1.4) * .22, to.dot(rt) / 6.0, 380.0 if Game.L["sex"] == "M" else 560.0)
	else:
		Sfx.hum(0, 0)

	# phun thuốc diệt muỗi
	if A["spray_at"] >= 0.0 and A["spray"] == null and stage_t > A["spray_at"] - 5.0 and not A["warned"]:
		A["warned"] = true
		var sx := rnd(-12, -9) if ppos.x > 0 else rnd(9, 12)
		A["spray"] = {"cx": sx if in_house(ppos.x, ppos.z, 2.0) else clampf(ppos.x + rnd(-3, 3), bounds.position.x + 8, bounds.end.x - 8), "cz": clampf(ppos.z + rnd(-3, 3), bounds.position.y + 6, bounds.end.y - 6), "t": -5.0, "r": 0.0}
		hud_ref.banner("CON NGƯỜI SẮP PHUN THUỐC DIỆT MUỖI!", "Hãy bay ra xa khỏi vùng sương xanh đang lan ra!")
	if A["spray"] != null:
		var sp: Dictionary = A["spray"]
		sp["t"] += dt
		sp["r"] = minf(9.0, sp["t"] * .7) if sp["t"] > 0 else 0.0
		if sp["t"] > 0 and sp["t"] < 18 and Vector2(ppos.x - sp["cx"], ppos.z - sp["cz"]).length() < sp["r"] and ppos.y < gy(sp["cx"], sp["cz"]) + 6.0:
			pl["exposure"] += dt
			if pl["exposure"] > 2.0:
				kill("Chết vì thuốc diệt muỗi")
				return
		else:
			pl["exposure"] = maxf(0.0, pl["exposure"] - dt)
		if sp["t"] >= 18:
			Game.G["survived_spray"] = true
			A["spray"] = null; A["spray_at"] = -1.0
			spray_mesh.visible = false
	_animate(dt)

# ═════════════ thoại NPC (Talk) ═════════════
const PERSONA_FIXED := {"dad": "ron", "mom": "nong", "kid": "nit", "seller1": "hien", "seller2": "coc", "seller3": "gia",
	"buyer1": "ron", "buyer2": "thatha", "buyer3": "nit", "villager": "nong"}
const ADULT_PERSONAS := ["hien", "nong", "ron", "thatha", "coc", "hien", "thatha", "ron"]
const HUMAN_CTX := {"cook": "cook", "eat": "eat", "tv": "tv", "chore": "chore", "read": "read", "water": "water", "study": "study",
	"play": "play", "exercise": "exercise", "sleep": "sleep", "walk": "walk", "stand": "walk"}
const RES_CTX := {"field": "field", "market": "market_buy", "yard": "yard", "sit": "sit", "pond": "pond", "school": "kid"}

## Tên gọi trong thông báo: con vật có tên → chỉ tên (vd. "Nguyên"), người → tên/vai như cũ.
func _who(h: Host) -> String:
	if h.def.has("nick"):
		return String(h.def["nick"])
	return String(h.def["name"])

func _assign_persona(h: Host) -> void:
	var model := String(h.def.get("model", ""))
	if not model in ["man", "woman", "hoodie"]:
		return                                   # thú không nói
	if PERSONA_FIXED.has(h.k):
		h.persona = PERSONA_FIXED[h.k]
	elif h.def.has("res"):
		var role := String(h.def["res"])
		h.persona = "nit" if role == "kid" else ("gia" if role == "elder" else ADULT_PERSONAS[absi(hash(h.k)) % ADULT_PERSONAS.size()])
	else:
		h.persona = "thatha"
	h.me = Talk.self_term(h.persona, model == "woman")
	h.chat_t = rnd(2.0, 12.0)

func _talk_ctx(h: Host) -> String:
	if h.def.has("res"):
		return RES_CTX.get(h.act, "")
	if h.human:
		return HUMAN_CTX.get(h.act, "")
	if h.k.begins_with("seller"):
		return "market_sell"
	if h.k.begins_with("buyer"):
		return "market_buy"
	return "walk"

## NPC nói một câu theo ngữ cảnh. force: bỏ qua thời gian nghỉ giữa hai câu (phản ứng tức thì: đập, hụt…).
func _say(h: Host, ctx: String, chance: float = 1.0, force: bool = false) -> void:
	if h.persona == "" or h.away or ctx == "":
		return
	if not force and (h.say_cd > 0.0 or randf() > chance):
		return
	var line := Talk.pick(ctx, h.persona, h.k, h.me)
	h.say_cd = rnd(5.0, 10.0)
	if line == "":
		return                                   # im lặng / mặc kệ
	h.say_text = line
	h.say_t = clampf(1.6 + line.length() * .06, 2.2, 4.8)

func _talk_update(h: Host, dt: float, ppos: Vector3) -> void:
	if h.persona == "":
		return
	h.say_t -= dt
	h.say_cd -= dt
	if h.q_t > 0.0:
		h.q_t -= dt
		if h.q_t <= 0.0 and not h.away:
			h.say_text = h.q_text
			h.say_t = clampf(1.6 + h.q_text.length() * .06, 2.2, 4.8)
			h.say_cd = rnd(5.0, 9.0)
	# bị đốt: có người kêu, có người mặc kệ
	var mine: bool = pl.get("landed") != null and pl["landed"]["h"] == h and pl.get("sucking", false)
	if mine and not h.bit_said:
		h.bit_said = true
		_say(h, "bitten", .6)
	elif not mine and pl.get("landed") == null:
		h.bit_said = false
	# nói chuyện đời thường khi muỗi ở gần (nghe được)
	h.chat_t -= dt * Talk.talk_rate(h.persona)
	if h.chat_t > 0.0 or h.away or h.hidden_move or h.react != "" or h.st == "wind":
		return
	h.chat_t = rnd(9.0, 20.0)
	if Vector2(ppos.x - h.pos.x, ppos.z - h.pos.y).length() > 20.0 or h.say_t > 0.0:
		return
	var busy := 0              # tối đa 2 người tán gẫu cùng lúc quanh muỗi (phản ứng với muỗi thì không giới hạn)
	for o in hosts:
		if o.say_t > 0.0 and Vector2(ppos.x - o.pos.x, ppos.z - o.pos.y).length() < 22.0:
			busy += 1
	if busy >= 2:
		return
	for o in hosts:
		if o != h and o.persona != "" and not o.away and not o.hidden_move and o.say_t <= 0.0 and o.q_t <= 0.0 \
				and o.react == "" and o.pos.distance_to(h.pos) < 5.0 and h.persona != "nit" and o.persona != "nit" and randf() < .45:
			var pair := Talk.chat_pair()
			if pair.size() == 2:
				h.say_text = pair[0]
				h.say_t = clampf(1.6 + String(pair[0]).length() * .06, 2.2, 4.8)
				h.say_cd = rnd(6.0, 10.0)
				o.q_text = pair[1]
				o.q_t = h.say_t * .8
				return
	_say(h, _talk_ctx(h), .85)

## Ngoài giờ có mặt: người ngoài đồng/đường về nhà ban đêm; người ở chợ chỉ có giờ họp chợ.
func _off_hours(df: Dictionary) -> bool:
	if df.get("market", false) and vmap != null:
		for iv in vmap.market_hours():
			if A["clock"] >= float(iv[0]) and A["clock"] < float(iv[1]):
				return false
		return true
	return df.get("day", false) and night_amt(A["clock"]) > .5

## M4: đi qua lại trên đường (người qua đường R1, nông dân trên bờ ruộng R4); dừng lại nhìn khi nghi có muỗi.
func _walk_path(h: Host, dt: float) -> void:
	h.y = gy(h.pos.x, h.pos.y) + float(h.def["cy"])
	if h.react != "" or h.st == "wind":
		var dv := Vector2(body.global_position.x - h.pos.x, body.global_position.z - h.pos.y)
		if dv.length() > .05:
			h.yaw = lerp_angle(h.yaw, atan2(dv.x, dv.y), 1.0 - exp(-6.0 * dt))
		return
	var tgt: Vector2 = h.path[h.seg + 1] if h.dir > 0 else h.path[h.seg]
	var dd := tgt - h.pos
	var st := float(h.def["sp"]) * dt
	if dd.length() <= st:
		h.pos = tgt
		if h.dir > 0:
			if h.seg + 1 >= h.path.size() - 1: h.dir = -1
			else: h.seg += 1
		else:
			if h.seg <= 0: h.dir = 1
			else: h.seg -= 1
		return
	h.pos += dd.normalized() * st
	h.yaw = atan2(dd.x, dd.y)
	h.walk = true

## M4: khu vực hiện tại + hành trình 1 → 8 (Game.zone_enter thưởng khi tới đúng chặng kế tiếp).
func _update_zone(p: Vector3) -> void:
	var z := "Z01" if in_house(p.x, p.z, 0.0) else vmap.zone_at(p.x, p.z)
	in_market = vmap.in_market(p.x, p.z)
	if in_market:
		z = "Z08"          # chợ ở ngã ba đường làng: người qua lại đông nhất (MAP_BIBLE §13 Z08)
		if not Game.G.get("market_seen", false):
			Game.G["market_seen"] = true
			var open := not _off_hours({"market": true})
			hud_ref.banner("CHỢ LÀNG" + ("" if open else " · ĐÃ TAN"), ("Nhiều người, nhiều mùi: nhiều máu để hút — nhưng cũng nhiều tay đập nhất làng." if open
				else "Chợ họp sáng 5h30–11h và chiều 15h–18h — giờ này vắng người, chỉ còn sạp trống."))
	zone = z
	match Game.zone_enter(z):
		"journey":
			hud_ref.banner("HÀNH TRÌNH %d/8 · %s" % [Game.JOURNEY.find(z) + 1, String(Game.ZONES[z]["name"]).to_upper()], String(Game.ZONES[z]["fact"]))
		"new":
			hud_ref.banner("KHU VỰC MỚI · %s" % String(Game.ZONES[z]["name"]).to_upper(), String(Game.ZONES[z]["fact"]))

func _site_over() -> int:
	var p := body.global_position
	for i in Game.SITES.size():
		var s: Vector3 = Game.site_pos(i)
		var top := .9 if vmap == null else Game.site_wy(i) + .9
		if Vector2(p.x - s.x, p.z - s.y).length() < s.z + .35 and p.y < top:
			return i
	return -1

func _complete_mate(n: Npc) -> void:
	pl["mated"] = true
	pl["mate"] = 0.0
	Game.q_set("mate", 1.0)
	n.alive = false
	n.node.visible = false
	Game.G["mated"] = true
	var p := body.global_position
	for i in 6:
		fx_text("♥", p + Vector3(randf_range(-.2, .2), randf_range(0, .3), randf_range(-.2, .2)), .22, 1.6)
	Sfx.beep(660, .25, "sine", .07, 400)
	if Game.L["sex"] == "M":
		var bf := Game.build_factors()
		var eggs := int(round(randf_range(55, 85) * (1.0 + .12 * Game.tv("rep")) * bf["eggs"] * Game.q_bonus() * (.6 + .4 * pl["energy"] / 100.0)))
		var bi := 0
		var bd := 1e9
		for i in Game.SITES.size():
			if Game.site_dry(i): continue
			var s: Vector3 = Game.site_pos(i)
			var d := Vector2(s.x - p.x, s.y - p.z).length()
			if d < bd:
				bd = d; bi = i
		ending = {"t": 0.0, "eggs": eggs, "site": bi, "text": "Giao phối thành công! Con cái bay đến \"%s\" và đẻ %d trứng." % [Game.SITES[bi]["name"], eggs], "sub": "Bạn đã truyền lại gen — cuộc đời bạn kết thúc, dòng họ vẫn tiếp tục."}

func _lay_eggs(i: int) -> void:
	var bf := Game.build_factors()
	var sc := Game.score_of(Game.attrs(i))
	var eggs := int(round((20.0 + 130.0 * minf(1.4, pl["protein"])) * (1.0 + .12 * Game.tv("rep")) * bf["eggs"] * Game.q_bonus() * (.55 + .45 * sc)))
	Game.q_set("lay", 1.0)
	ending = {"t": 0.0, "eggs": eggs, "site": i, "text": "Bạn đã đẻ %d trứng ở \"%s\"" % [eggs, Game.SITES[i]["name"]], "sub": "Bạn kiệt sức và qua đời — dòng họ của bạn tiếp tục ở thế hệ sau."}
	Sfx.beep(500, .3, "sine", .07, 300)

# ═════════════ hình ảnh động, ánh sáng, camera ═════════════
func _animate(dt: float) -> void:
	var nt := night_amt(A["clock"])
	var w: String = A["weather"]
	# ánh sáng & trời
	if vmap != null:
		_village_light(w)
	else:
		_legacy_light(nt, w)
	var lit := [0.0, 0.0, 0.0, 0.0]
	for h in hosts:
		if h.human and not h.away and not h.sleeping:
			var r := room_at(h.pos.x, h.pos.y)
			if r >= 0 and r < 4: lit[r] = 1.0
	for i in 4:
		var tgt: float = (1.6 if lit[i] > 0.0 else 0.0) if (nt > .05 or w == "rain") else (.5 if lit[i] > 0.0 else 0.0)
		(room_lights[i] as OmniLight3D).light_energy = lerpf((room_lights[i] as OmniLight3D).light_energy, tgt, minf(1.0, dt * 4.0))
	headlight.light_energy = .15 + 1.1 * nt
	cloud_mat.albedo_color = Color(1, 1, 1, .95).lerp(Color(.28, .32, .46, .8), nt).lerp(Color(.6, .62, .66, .95), .6 if w == "rain" else 0.0)
	for cg in clouds:
		(cg as Node3D).position.x += dt * 1.2
		if (cg as Node3D).position.x > 170.0:
			(cg as Node3D).position.x = -170.0
	door_pivot.rotation.y = lerpf(door_pivot.rotation.y, -1.5 if A["door_open"] else 0.0, minf(1.0, dt * 6.0))
	var pp := body.global_position
	rain.global_position = Vector3(pp.x, gy(pp.x, pp.z) + 9.0, pp.z)
	# hoa
	for f in flowers:
		pass
	# vật chủ
	for h in hosts:
		var nd: Node3D = h.node
		nd.visible = not h.away and not h.hidden_move
		if h.ring != null:
			h.ring.visible = h.st == "wind" and not h.away
		if h.away:
			continue
		if h.human:
			_animate_human(h, dt)
		else:
			nd.position = Vector3(h.pos.x, gy(h.pos.x, h.pos.y), h.pos.y)
			nd.rotation.y = h.yaw
			var moving: bool = h.walk
			var an: String = h.def["walk"] if moving else (h.def.get("eat", h.def["idle"]) if (h.resting and h.rest_anim == 1) else h.def["idle"])
			if h.sitting and not moving and h.def.has("sit"):
				an = h.def["sit"]
			Assets.play(nd, an, 1.0)
			h.walk = false
			if h.k == "bird":
				nd.position.y = gy(h.pos.x, h.pos.y) + 3.45 - .12
				nd.rotation.y = PI * .5
		if h.ring != null and h.ring.visible:
			var hr := (.55 if (h.k == "dad" or h.k == "mom") else .45) * (1.0 + .08 * sin(A["t"] * 24.0))
			var total2 := .7 if h.k == "kid" else .9
			h.ring.position = h.lock if h.swung else h.track
			h.ring.scale = Vector3.ONE * hr
			var prog := clampf(1.0 - h.t / total2, 0.0, 1.0)
			h.ring_mat.albedo_color = Color(1, .12, .1, .15 + .4 * prog)
			h.ring_mat.emission_energy_multiplier = .6 + 1.6 * prog
	# chuồn chuồn
	for d in dragons:
		d.node.position = d.pos
		d.node.rotation.y = d.yaw
		for pr in d.wings:
			(pr[0] as Node3D).rotation.z = pr[1] * sin(A["t"] * 60.0 + d.ph) * .5
	# NPC
	for n in npcs:
		if not n.alive: continue
		n.node.position = n.pos
		n.node.rotation.y = atan2(n.target.x - n.pos.x, n.target.z - n.pos.z)
		flap(n.node, A["t"] + n.ph)
	# sương độc
	if A["spray"] != null:
		var sp: Dictionary = A["spray"]
		spray_mesh.visible = true
		var r: float = .5 if sp["t"] < 0 else sp["r"]
		spray_mesh.scale = Vector3(r, minf(r, 6.0), r)
		spray_mesh.position = Vector3(sp["cx"], gy(sp["cx"], sp["cz"]) + minf(r, 6.0) * .5, sp["cz"])
	# nhãn địa điểm
	for i in Game.SITES.size():
		var s: Vector3 = Game.site_pos(i)
		(site_labels[i] as Label3D).visible = Vector2(pp.x - s.x, pp.z - s.y).length() < 10.0 + s.z
	# muỗi người chơi
	if v.length() > .3:
		var tyaw := atan2(v.x, v.z)
		mosq_yaw = lerp_angle(mosq_yaw, tyaw, minf(1.0, dt * 10.0))
	var tq := Quaternion.from_euler(Vector3(clampf(-v.y * .12, -.6, .6), mosq_yaw, 0))
	if pl["mode"] == "feeding" or pl["perch"] != null:
		var nrm: Vector3 = pl["nrm"]
		var tan := nrm.cross(Vector3.UP)
		if tan.length() < .2:
			tan = Vector3(sin(mosq_yaw), 0, cos(mosq_yaw))
		tan = tan.normalized()
		var xb := nrm.cross(tan).normalized()
		tq = (Basis(xb, nrm, tan) * Basis(Vector3.RIGHT, deg_to_rad(40.0))).get_rotation_quaternion()
	mosq.quaternion = mosq.quaternion.slerp(tq, 1.0 - exp(-13.0 * dt))
	flap(mosq, pl["flap"], .2 if pl["landed"] != null else 1.0)
	# cánh mới vũ hóa còn nhỏ & nhăn, nở và cứng dần trong lúc hong khô
	var dq: Dictionary = Game.q_find("dry")
	var dry_k := 1.0
	if not dq.is_empty() and not dq["done"]:
		dry_k = lerpf(.3, 1.0, clampf(float(dq["prog"]) / float(dq["goal"]), 0.0, 1.0))
		_ripple_t -= dt
		if _ripple_t <= 0.0:
			_ripple_t = 1.3
			fxl.ring(Vector3(body.global_position.x, fxl.surf_y, body.global_position.z), .16, 1.4)
	(mosq.get_node("wl") as Node3D).scale = Vector3.ONE * dry_k
	(mosq.get_node("wr") as Node3D).scale = Vector3.ONE * dry_k
	emerge_t += dt
	fxl.update(dt)
	var abd := mosq.get_node("abd") as MeshInstance3D
	var bl: float = pl["blood"]
	var pump := 1.0 + (.07 * sin(A["t"] * 17.0) if pl["sucking"] else 0.0)
	abd.scale = Vector3(1.0 + bl * .55, 1.0 + bl * .55, 1.0 + bl * .25) * pump
	abd.set_instance_shader_parameter("blood", bl)
	mosq.visible = true
	_cam_update(dt, false)

func _legacy_light(nt: float, w: String) -> void:
	env.background_energy_multiplier = lerpf(1.2, .2, nt) * (.9 if w == "rain" else 1.0)
	env.ambient_light_energy = lerpf(1.4, .4, nt) * (.85 if w == "rain" else 1.0)
	var elev := sin((A["clock"] - 6.0) / 12.0 * PI)
	if elev > 0.0:
		sun.rotation_degrees = Vector3(-lerpf(8.0, 62.0, elev), -30 + (A["clock"] - 12.0) * 8.0, 0)
		sun.light_energy = (1.9 if w != "rain" else .9) * clampf(elev * 2.0, 0.0, 1.0)
		sun.light_color = Color(.99, .86, .66).lerp(Color(.95, .55, .28), 1.0 - clampf(elev * 2.0, 0.0, 1.0))
	else:
		sun.rotation_degrees = Vector3(-50, 60, 0)
		sun.light_energy = .6
		sun.light_color = Color(.42, .58, .75)

## M4: chu kỳ ngày–đêm của map (art_look.json) theo đồng hồ game; mưa/hạn chỉnh thêm sau khi day_night áp.
func _village_light(w: String) -> void:
	var dn = vmap.day_night
	if absf(float(dn.hour) - A["clock"]) > .01 or A.get("_w", "") != w:
		dn.hour = A["clock"]
		dn.apply(A["clock"])
		A["_w"] = w
		if w == "rain":
			sun.light_energy *= .45
			env.fog_density *= 3.0
			env.fog_light_color = env.fog_light_color.lerp(Color(.62, .67, .72), .6)
			env.ambient_light_energy *= .85
		elif w == "drought":
			env.fog_density *= 1.6
			env.fog_light_color = env.fog_light_color.lerp(Color(.92, .75, .5), .5)

func _animate_human(h: Host, dt: float) -> void:
	var nd := h.node
	var s: float = h.def["h"] / 1.78
	var model_k: String = "Man" if h.def["model"] == "man" else ("Female" if h.def["model"] == "woman" else "")
	var want := ""
	var spd_scale := 1.0
	var pos := Vector3(h.pos.x, gy(h.pos.x, h.pos.y), h.pos.y)
	var rot := h.yaw
	if h.sleeping:
		want = (model_k + "_Death") if model_k != "" else "Death"
		rot = h.sleep_rot
		var tgt := _sleep_target(h)
		if not h.sleep_init:
			h.sleep_init = true
			h.sleep_n = 0
			h.sleep_pos = tgt + Vector3(.68 * s, -.11 * s, 0)
		elif h.rig != null:
			h.sleep_n += 1
			var hips := h.rig.bone_world("hips")
			if hips != Vector3.ZERO:
				h.sleep_pos += (tgt - hips) * (1.0 - exp(-12.0 * dt))
				# đầu phải về phía gối (-x); nếu bộ xương nằm ngược thì xoay 180° rồi căn lại
				if h.sleep_n == 12:
					var hd := h.rig.bone_world("head")
					if hd.x > hips.x + .1:
						h.sleep_rot += PI
						h.sleep_init = false
		pos = h.sleep_pos
	else:
		h.sleep_init = false
		if h.walk:
			if h.sched_act == "play" and model_k == "":
				want = "Run"
			else:
				want = (model_k + "_Walk") if model_k != "" else "Walk"
				spd_scale = float(h.def["spd"]) / 1.3 * (1.35 if h.hunt > 0.0 else 1.0)
		elif h.sitting:
			want = model_k + "_Sitting"
		elif h.act == "exercise" and model_k != "":
			want = model_k + "_Jump"
		else:
			want = (model_k + "_Idle") if model_k != "" else "Idle"
	if h.anim != want:
		h.anim = want
		if want.ends_with("Death"):
			Assets.freeze_at_end(nd, want)
		else:
			Assets.play(nd, want, spd_scale, true)
	elif not want.ends_with("Death"):
		Assets.play(nd, want, spd_scale, true)
	nd.position = pos
	nd.rotation.y = rot
	_rig_update(h, dt)

func _sleep_target(h: Host) -> Vector3:
	## vị trí hông khi nằm trên giường (đầu về phía gối)
	var s: float = float(h.def["h"]) / 1.78
	return Vector3(h.pos.x, lie_y[h.k] + .13 * s, h.pos.y)

func _rig_update(h: Host, dt: float) -> void:
	if h.rig == null:
		return
	var pp := body.global_position
	var awake := not h.sleeping
	h.head_w = lerpf(h.head_w, 1.0 if (h.react != "" and awake) else 0.0, 1.0 - exp(-6.0 * dt))
	h.rig.head_w = h.head_w
	h.rig.head_target = pp + Vector3(0, .02, 0)
	var s: float = float(h.def["h"]) / 1.78
	var w_t := 0.0
	var tgt := pp
	var fwd := Vector3(sin(h.yaw), 0, cos(h.yaw))
	var side := Vector3(fwd.z, 0, -fwd.x)
	var tt: float = A["t"] + h.ph
	if h.st == "wind" and awake:
		var raise := Vector3(h.pos.x, 2.05 * s, h.pos.y)
		var toward := Vector3(pp.x - h.pos.x, 0, pp.z - h.pos.y)
		if toward.length() > .01:
			raise += toward.normalized() * .12
		if h.t > .22:
			tgt = raise
		else:
			var k := 1.0 - h.t / .22
			tgt = raise.lerp(h.lock, k * k)
		w_t = 1.0
	elif h.react == "scratch" and awake:
		tgt = pp
		if pl["mode"] == "feeding" and pl["tgt_h"] == h and pl["spots"].size() > 0:
			tgt = pl["spots"][0]["pos"]
		tgt += Vector3(sin(A["t"] * 13.0) * .035, 0, cos(A["t"] * 11.0) * .035)
		w_t = .8
	elif awake and not h.walk and h.react == "" and h.hunt <= 0.0:
		# động tác theo hoạt động: tay đưa tới đúng thứ họ đang làm
		var base := Vector3(h.pos.x, 0, h.pos.y)
		var head_w := h.rig.bone_world("head")
		match h.act:
			"eat":
				var plate := base + fwd * .42 * s + Vector3(0, .8, 0)
				var mouth := head_w + fwd * .13 * s + Vector3(0, -.07, 0)
				tgt = plate.lerp(mouth, smoothstep(0.0, 1.0, .5 + .5 * sin(tt * 2.2)))
				w_t = .85
			"cook":
				tgt = Vector3(3.2, .98, -4.05) + Vector3(cos(tt * 3.0) * .1, 0, sin(tt * 3.0) * .1)
				w_t = .85
			"brush":
				tgt = head_w + fwd * .12 * s + Vector3(0, -.08, 0) + side * sin(tt * 13.0) * .025
				w_t = .9
			"read":
				tgt = head_w + fwd * .3 * s + Vector3(0, -.42, 0) + Vector3(sin(tt * .8) * .02, 0, 0)
				w_t = .75
			"study":
				tgt = base + fwd * .45 * s + Vector3(0, .8, 0) + side * sin(tt * 4.0) * .06
				w_t = .75
			"water":
				tgt = Vector3(-6.0, .75, 3.6) + Vector3(sin(tt * 1.4) * .18, 0, 0)
				w_t = .8
			"chore":
				tgt = base + fwd * .55 * s + Vector3(0, .35, 0) + side * sin(tt * 2.4) * .3
				w_t = .7
	h.arm_w = lerpf(h.arm_w, w_t, 1.0 - exp(-(10.0 if h.st == "wind" else 6.0) * dt))
	h.rig.arm_w = h.arm_w
	h.rig.arm_target = tgt

func _cam_update(dt: float, snap: bool) -> void:
	var k := 1.0 if snap else 1.0 - exp(-28.0 * dt)
	_sy = view_yaw if snap else lerp_angle(_sy, view_yaw, k)
	_sp = view_pitch if snap else lerpf(_sp, view_pitch, k)
	var pp := body.global_position
	_ps = pp if snap else _ps.lerp(pp, 1.0 - exp(-20.0 * dt))
	var fw := Vector3(-sin(_sy) * cos(_sp), sin(_sp), -cos(_sy) * cos(_sp))
	var dist3 := .42 if debug_cam_dist <= 0.0 else debug_cam_dist
	if debug_cam_dist <= 0.0 and emerge_t < 3.0:
		dist3 = lerpf(.22, .42, smoothstep(0.0, 3.0, emerge_t))
	var c := _ps - fw * dist3 + Vector3(0, .07, 0)
	if in_house(pp.x, pp.z, 0.0):
		c.x = clampf(c.x, HX0 + .15, HX1 - .15)
		c.z = clampf(c.z, HZ0 + .15, HZ1 - .15)
		c.y = clampf(c.y, .06, HWALL - .1)
	else:
		c.y = maxf(c.y, gy(c.x, c.z) + .06)
	if shake > 0.0:
		c += Vector3(randf_range(-.008, .008), randf_range(-.008, .008), 0)
	cam.global_position = c
	cam.look_at(_ps + fw * .3 + Vector3(0, .015, 0), Vector3.UP)

# ═════════════ HUD ═════════════
func draw_hud(hud: Node) -> void:
	var W := 1280.0
	var H := 720.0
	var L := Game.L
	var nt := night_amt(A["clock"])
	hud.text("THẾ HỆ %02d  ·  NGÀY %d  ·  %s  ·  %s" % [L["gen"], Game.day_no(), "MUỖI ĐỰC" if L["sex"] == "M" else "MUỖI CÁI", Game.BUILDS[Game.G["build"]]["name"]], Vector2(20, 24), 19)
	var maxage := 250.0 if L["sex"] == "M" else 400.0
	var y := 50.0
	var en: float = pl["energy"]
	hud.bar(Vector2(20, y), 300, 20, en / 100.0, Color(1, .3, .24) if en < 30 else Color(.85, .64, .36),
		("ĐÓI! Hút máu ngay" if en < 30 else "No bụng (hút máu để sống)") if L["sex"] == "F" else "Năng lượng (hút mật)")
	y += 28
	hud.bar(Vector2(20, y), 300, 20, 1.0 - pl["age"] / maxage, Color(.7, .73, .76), "Tuổi thọ")
	y += 28
	if L["sex"] == "F":
		hud.bar(Vector2(20, y), 300, 20, pl["blood"], Color(.6, .15, .14), "Máu đã hút")
		y += 28
	hud.draw_quests(y + 12.0)
	var hh := int(A["clock"])
	var mm := int((A["clock"] - hh) * 60)
	hud.text("%s %02d:%02d" % ["ĐÊM" if nt > .5 else "NGÀY", hh, mm], Vector2(W / 2, 24), 22, Color.WHITE, 1)
	hud.text("Mục tiêu: sống sót %d/10 thế hệ" % L["gen"], Vector2(W - 20, 48), 16, Color(.8, .95, .82), 2)
	hud.text("Kỷ lục: %d thế hệ  ·  M: âm thanh  ·  P: tạm dừng" % Game.best, Vector2(W - 20, 70), 14, Color(.62, .86, .8), 2)
	# bản đồ làng nhìn từ trên xuống
	if vmap != null:
		_draw_village_map(hud)
	else:
		_draw_legacy_map(hud)
	var pp := body.global_position
	# tên con vật trên đầu (chủ dự án đặt): chỉ tên, đổi màu theo mức cảnh giác; trong 15 m
	for h in hosts:
		if h.human or h.away or not h.def.has("nick"):
			continue
		var tp := Vector3(h.pos.x, h.y + float(h.def["r"]) * .7 + .12, h.pos.y)
		var td := pp.distance_to(tp)
		if td > 15.0 or cam.is_position_behind(tp):
			continue
		var ts := cam.unproject_position(tp)
		if ts.x < 20 or ts.x > W - 20 or ts.y < 30 or ts.y > H - 30:
			continue
		var ta := clampf(1.4 - td / 15.0, .35, 1.0)
		var tc := Color(1, 1, 1, ta).lerp(Color(1, .8, .3, ta), clampf(h.alert / .5, 0.0, 1.0)).lerp(Color(1, .3, .25, ta), clampf((h.alert - .5) / .5, 0.0, 1.0))
		hud.text(String(h.def["nick"]), ts + Vector2(0, -10), 20, tc, 1, true)
	# bong bóng thoại (godot/scripts/talk.gd): gần trước, bỏ bong bóng chồng lên nhau, tối đa 4
	var talkers: Array = []
	for h in hosts:
		if h.say_t > 0.0 and not h.away and not h.hidden_move and h.say_text != "":
			talkers.append(h)
	talkers.sort_custom(func(a, b): return Vector2(a.pos.x - pp.x, a.pos.y - pp.z).length() < Vector2(b.pos.x - pp.x, b.pos.y - pp.z).length())
	var drawn: Array = []
	for h in talkers:
		if drawn.size() >= 4:
			break
		var top2: float = (1.2 if h.sleeping else float(h.def["h"]) + .45 + gy(h.pos.x, h.pos.y)) if h.human else h.y + float(h.def["h"]) * .55
		var wp2 := Vector3(h.pos.x, top2, h.pos.y)
		var d2 := pp.distance_to(wp2)
		if d2 > 22.0 or cam.is_position_behind(wp2):
			continue
		var s2b := cam.unproject_position(wp2)
		if s2b.x < 20 or s2b.x > W - 20 or s2b.y < 30 or s2b.y > H - 30:
			continue
		var a := clampf(h.say_t / .4, 0.0, 1.0) * clampf(1.3 - d2 / 22.0, .45, 1.0)
		var lines := _wrap_words(h.say_text, 30)
		var wbox := 0.0
		for ln in lines:
			wbox = maxf(wbox, float(String(ln).length()) * 8.6)
		var hb := 22.0 * lines.size() + 10.0
		var bp := s2b + Vector2(-wbox / 2.0 - 10.0, -64.0 - hb)
		var box := Rect2(bp, Vector2(wbox + 20.0, hb))
		var clash := false
		for r in drawn:
			if (r as Rect2).intersects(box):
				clash = true
		if clash:
			continue
		drawn.append(box)
		hud.panel(bp, Vector2(wbox + 20.0, hb), Color(1, 1, .97, .9 * a))
		hud.poly(PackedVector2Array([s2b + Vector2(-7, -64), s2b + Vector2(7, -64), s2b + Vector2(0, -52)]), Color(1, 1, .97, .9 * a))
		var ly := bp.y + 16.0
		for ln in lines:
			hud.text(String(ln), Vector2(s2b.x, ly), 16, Color(.12, .1, .08, a), 1)
			ly += 22.0
	# nhãn & thanh cảnh giác trên đầu vật chủ
	for h in hosts:
		if h.away: continue
		var top: float = (1.2 if h.sleeping else float(h.def["h"]) + .25 + gy(h.pos.x, h.pos.y)) if h.human else h.y + float(h.def["r"]) + .25
		var wp := Vector3(h.pos.x, top, h.pos.y)
		var d := pp.distance_to(wp)
		if d > 12.0 or cam.is_position_behind(wp): continue
		var s := cam.unproject_position(wp)
		if s.x < -40 or s.x > W + 40: continue
		if h.alert > .04:
			hud.rect(s + Vector2(-34, -14), Vector2(68, 8), Color(0, 0, 0, .6))
			hud.rect(s + Vector2(-34, -14), Vector2(68 * h.alert, 8), Color(1, .3, .3) if h.alert > .7 else Color(1, .79, .3))
		if h.react == "notice":
			hud.text("?", s + Vector2(0, -40), 34, Color(1, .88, .3), 1)
		elif h.react == "scratch":
			hud.text("!", s + Vector2(0, -42), 40, Color(1, .6, .2), 1)
		elif h.react == "wind":
			hud.text("ĐẬP!", s + Vector2(0, -44), 34, Color(1, .24, .24), 1)
		if L["sex"] == "F" and d < 7.0 and (h.human or not h.def.has("nick")):
			var at: String = (" · " + String(ACTTXT.get("alert" if h.hunt > 0.0 else h.act, ""))) if h.human else ""
			if h.def.has("res"):
				at = " · " + String(RES_TXT.get(h.act, ""))
			hud.text(h.def["name"] + at, s + Vector2(0, 8), 15, Color(1, .6, .6) if h.hunt > 0.0 else Color.WHITE, 1)
	# chỉ hướng mục tiêu trong tầm cảm nhận
	var sr := sense_r()
	var best_t := {}
	var bd := 1e9
	if not pl["mated"]:
		for n in npcs:
			if n.alive:
				var dd: float = pp.distance_to(n.pos)
				if dd < bd: bd = dd; best_t = {"p": n.pos, "c": Color(1, .5, .69), "t": "bạn tình"}
	if L["sex"] == "F" and pl["blood"] < .95:
		for h in hosts:
			if not h.away:
				var hp := Vector3(h.pos.x, 1.0 + gy(h.pos.x, h.pos.y) if h.human else h.y, h.pos.y)
				var dd2 := pp.distance_to(hp)
				if dd2 < bd: bd = dd2; best_t = {"p": hp, "c": Color(1, .35, .24), "t": _who(h)}
	if not best_t.is_empty() and bd < sr and bd > 1.0:
		var col: Color = best_t["c"]
		col.a = clampf(1.0 - bd / sr, .35, 1.0)
		var bp: Vector3 = best_t["p"]
		var behind := cam.is_position_behind(bp)
		var s2 := cam.unproject_position(bp)
		if not behind and s2.x > 40 and s2.x < W - 40 and s2.y > 40 and s2.y < H - 40:
			hud.poly(PackedVector2Array([s2 + Vector2(0, 28), s2 + Vector2(-10, 10), s2 + Vector2(10, 10)]), col)
			hud.text("%s %.1fm" % [best_t["t"], bd], s2 + Vector2(0, 44), 14, col, 1)
		else:
			var dv := s2 - Vector2(W / 2, H / 2)
			if behind: dv = -dv
			var ang := dv.angle()
			var e := Vector2(clampf(W / 2 + cos(ang) * 440, 40, W - 40), clampf(H / 2 + sin(ang) * 290, 40, H - 40))
			var r := Vector2.from_angle(ang)
			var n2 := Vector2(-r.y, r.x)
			hud.poly(PackedVector2Array([e + r * 18, e - r * 10 + n2 * 11, e - r * 10 - n2 * 11]), col)
	for d in dragons:
		if d.st == "chase":
			var dp: Vector3 = d.pos
			if cam.is_position_behind(dp):
				hud.text("Chuồn chuồn phía sau!", Vector2(W / 2, H - 170), 18, Color(1, .42, .42), 1)
			else:
				var sd := cam.unproject_position(dp)
				hud.text("!", sd + Vector2(0, -36), 34, Color(1, .24, .24), 1)
	if pl["mate"] > 0.0 or pl["lay"] > 0.0:
		var vv := maxf(pl["mate"] / 1.5, pl["lay"] / 1.8)
		hud.rect(Vector2(W / 2 - 80, H / 2 + 70), Vector2(160, 10), Color(0, 0, 0, .6))
		hud.rect(Vector2(W / 2 - 80, H / 2 + 70), Vector2(160 * vv, 10), Color(1, .44, .66) if pl["mate"] > 0.0 else Color(1, .96, .84))
	if L["sex"] == "F" and en < 30 and not dead:
		hud.vignette(Color(.63, 0, 0, .35 + .2 * sin(Time.get_ticks_msec() / 160.0)))
	if pl["exposure"] > 0.0 and not dead:
		hud.text("ĐANG HÍT THUỐC ĐỘC!", Vector2(W / 2, 110), 32, Color(1, .3, .3), 1)
	if A["spray"] != null and A["spray"]["t"] < 0:
		hud.text("SẮP PHUN THUỐC — rời khỏi vùng sương!", Vector2(W / 2, 80), 26, Color(.84, 1, .42), 1)
	# chấm tâm: tầm bay của muỗi; chuyển đỏ khi ngắm trúng cơ thể người/thú
	if L["sex"] == "F":
		var cen := Vector2(W / 2, H / 2)
		var aimed: bool = pl["aim"] != null and pl["mode"] == "free" and pl["mated"]
		if aimed:
			hud.circle(cen, 16.0, Color(1, .15, .15, .16))
			hud.circle(cen, 5.5, Color(1, .15, .15, .98))
		elif pl["mode"] == "free":
			hud.circle(cen, 3.2, Color(1, 1, 1, .8))
		if pl["mode"] != "free" and pl["spots"].size() > 0:
			var tpos: Vector3 = pl["spots"][0]["pos"]
			if not cam.is_position_behind(tpos):
				hud.circle(cam.unproject_position(tpos), 5.0, Color(1, .2, .2, .95))
		# cảnh báo nguy hiểm: viền đỏ theo mức cảnh giác, đếm ngược cú đập
		var worst := 0.0
		var wind_h: Host = null
		for hst in hosts:
			if hst.away or host_dist(hst) > 5.0:
				continue
			worst = maxf(worst, hst.alert)
			if hst.st == "wind":
				wind_h = hst
		if worst > .5 and not dead:
			hud.vignette(Color(.85, 0, 0, clampf((worst - .5) * 1.6, 0.0, .8)))
		if wind_h != null and not dead:
			var tot := .7 if wind_h.k == "kid" else .9
			hud.rect(Vector2(W / 2 - 140, 128), Vector2(280, 14), Color(0, 0, 0, .55))
			hud.rect(Vector2(W / 2 - 140, 128), Vector2(280 * clampf(wind_h.t / tot, 0.0, 1.0), 14), Color(1, .25, .2))
			if int(Time.get_ticks_msec() / 120) % 2 == 0:
				hud.text("SẮP BỊ ĐẬP — THẢ CHUỘT PHẢI ĐỂ THOÁT!", Vector2(W / 2, 110), 30, Color(1, .3, .25), 1)
	if prompt != "" and ending.is_empty():
		hud.text(prompt, Vector2(W / 2, H - 70), 24, Color.WHITE, 1)
	elif ending.is_empty():
		hud.text("Chuột: nhìn · WASD: bay · Space/Shift: lên/xuống" + (" · bay cao = bay nhanh" if vmap != null else ""), Vector2(W / 2 + 100, H - 48), 17, Color(1, 1, 1, .85), 1)
		hud.text("CHUỘT PHẢI (chấm đỏ): hút máu · E: mật hoa / giao phối / đẻ trứng", Vector2(W / 2 + 100, H - 24), 17, Color(1, 1, 1, .85), 1)
	# bảng đánh giá nguồn nước
	if L["sex"] == "F":
		var si := -1
		var sd := 1e9
		for i in Game.SITES.size():
			var s: Vector3 = Game.site_pos(i)
			var dd3 := Vector2(pp.x - s.x, pp.z - s.y).length() - s.z
			if dd3 < 6.0 and dd3 < sd:
				sd = dd3; si = i
		if si >= 0:
			var at2 := Game.attrs(si)
			var gd := Game.goodness(at2)
			var sc2 := Game.score_of(at2)
			var bx := W - 330.0
			var by := 110.0
			hud.panel(Vector2(bx, by), Vector2(310, 236))
			hud.text("%s%s" % [Game.SITES[si]["name"], " — KHÔ" if Game.site_dry(si) else ""], Vector2(bx + 16, by + 26), 19)
			var yy := by + 58.0
			for k in gd:
				hud.text(k, Vector2(bx + 16, yy), 15, Color(.8, .88, .94))
				var vv2: float = gd[k]
				hud.rect(Vector2(bx + 130, yy - 7), Vector2(160, 13), Color(1, 1, 1, .12))
				hud.rect(Vector2(bx + 130, yy - 7), Vector2(160 * vv2, 13), Color(.44, .83, .42) if vv2 > .66 else (Color(.9, .76, .29) if vv2 > .4 else Color(.9, .35, .29)))
				yy += 26
			hud.text("Điểm phù hợp: %d%%" % int(sc2 * 100), Vector2(bx + 16, by + 216), 17, Color(1, .54, .54) if Game.site_dry(si) else Color.WHITE)
	if not ending.is_empty():
		hud.rect(Vector2.ZERO, Vector2(W, H), Color(0, 0, 0, .55))
		hud.text(ending["text"], Vector2(W / 2, H / 2 - 24), 28, Color.WHITE, 1)
		hud.text(ending["sub"], Vector2(W / 2, H / 2 + 24), 20, Color(1, .91, .66), 1)

# ═════════════ HÚT MÁU: chọn dấu X → giữ chuột phải bay tới & hút → thả ra tự rút lui ═════════════
func _wrap_words(t: String, n: int) -> Array:
	var out: Array = []
	var cur := ""
	for w in t.split(" "):
		if cur.length() + w.length() + 1 > n and cur != "":
			out.append(cur)
			cur = w
		else:
			cur = w if cur == "" else cur + " " + w
	if cur != "":
		out.append(cur)
	return out

func _draw_legacy_map(hud: Node) -> void:
	var H := 720.0
	var sc := 3.0
	var mw := 76.0 * sc
	var mh := 48.0 * sc
	var mx := 14.0
	var my := H - mh - 16.0
	var mp := func(x: float, z: float) -> Vector2: return Vector2(mx + (x + 38.0) * sc, my + (z + 24.0) * sc)
	hud.panel(Vector2(mx - 6, my - 6), Vector2(mw + 12, mh + 12), Color(.05, .09, .11, .82))
	hud.rect(Vector2(mx, my), Vector2(mw, mh), Color(.33, .52, .27))
	for rc in [Rect2(-35, -24, 26, 13), Rect2(-6.5, -24, 9.5, 12)]:
		hud.rect(mp.call(rc.position.x, rc.position.y), rc.size * sc, Color(.64, .74, .32))
		hud.rect(mp.call(rc.position.x + .5, rc.position.y + .5), (rc.size - Vector2(1, 1)) * sc, Color(.5, .66, .3))
	hud.rect(mp.call(14, 1.5), Vector2(23, 8.5) * sc, Color(.52, .7, .3))
	hud.rect(mp.call(3, -24), Vector2(34, 11) * sc, Color(.16, .36, .2))
	for k in 18:
		hud.circle(mp.call(5.0 + float((k * 37) % 32), -23.0 + float((k * 53) % 9)), 4.0, Color(.12, .3, .16))
	hud.rect(mp.call(-37.5, -4.5), Vector2(20, 12.5) * sc, Color(.55, .5, .3, .75))
	hud.rect(mp.call(-15, 4.5), Vector2(30, 6.4) * sc, Color(.72, .6, .42))
	hud.rect(mp.call(-38, 11.5), Vector2(76, 3.4) * sc, Color(.82, .72, .52))
	var prev := Vector2.ZERO
	for i in 39:
		var cx2 := -38.0 + i * 2.0
		var q: Vector2 = mp.call(cx2, _canal_z(cx2))
		if i > 0:
			hud.line(prev, q, Color(.28, .58, .82), 6.5)
		prev = q
	hud.circle(mp.call(21, -4), 4.7 * sc, Color(.2, .46, .66))
	hud.circle(mp.call(21, -4), 4.0 * sc, Color(.27, .58, .8))
	hud.rect(mp.call(HX0, HZ0), Vector2(14, 9) * sc, Color(.7, .3, .22))
	hud.rect(mp.call(HX0 + 1, HZ0 + 1), Vector2(12, 7) * sc, Color(.82, .42, .3))
	for hp in [Vector2(-31, 15.5)]:
		hud.rect(mp.call(hp.x - 2.5, hp.y - 2.5), Vector2(5, 5) * sc, Color(.72, .32, .24))
	for i in Game.SITES.size():
		var s2: Vector3 = Game.SITES[i]["pos"]
		hud.circle(mp.call(s2.x, s2.y), 3.2, Color(.75, .95, 1.0))
	var zones := [[1, 0.0, 0.0, "Nhà dân"], [2, -28.0, 1.5, "Vườn cây / Chuồng trại"], [3, 21.0, -4.0, "Ao / Hồ"], [4, -22.0, -17.0, "Ruộng lúa"],
		[5, 26.0, _canal_z(26.0), "Kênh mương"], [6, 20.0, -19.5, "Rừng tre / Bụi rậm"], [7, 26.0, 5.5, "Đồng cỏ"], [8, -27.0, 12.5, "Đường làng"]]
	var zone_name := ""
	var zd := 14.0
	for z in zones:
		var zp: Vector2 = mp.call(z[1], z[2])
		hud.circle(zp, 8.5, Color(0, 0, 0, .65))
		hud.circle(zp, 7.0, Color(1, .88, .45))
		hud.text(str(z[0]), zp + Vector2(0, 0), 12, Color(.15, .1, .05), 1)
		var dz := Vector2(body.global_position.x - float(z[1]), body.global_position.z - float(z[2])).length()
		if dz < zd:
			zd = dz
			zone_name = String(z[3])
	hud.text("Khu vực: %s" % (zone_name if zone_name != "" else "Làng quê"), Vector2(mx + 2, my - 16), 15, Color(1, .92, .65))
	hud.text("N", Vector2(mx + mw - 10, my + 11), 13, Color(1, 1, 1, .9))
	var pp := body.global_position
	for h in hosts:
		if not h.away:
			hud.circle(mp.call(h.pos.x, h.pos.y), 2.8, Color(1, .69, .29))
	for d in dragons:
		if Vector2(d.pos.x - pp.x, d.pos.z - pp.z).length() < 14.0:
			hud.circle(mp.call(d.pos.x, d.pos.z), 3.5, Color(1, .3, .3))
	var pc: Vector2 = mp.call(pp.x, pp.z)
	var fdir := Vector2(-sin(view_yaw), -cos(view_yaw))
	var side := Vector2(-fdir.y, fdir.x)
	hud.poly(PackedVector2Array([pc + fdir * 8.0, pc - fdir * 4.0 + side * 5.0, pc - fdir * 4.0 - side * 5.0]), Color.WHITE)

## M4: bản đồ cả làng (MAP_BIBLE, Bible x, z): zone, đường, kênh, ao, ruộng, nhà, nguồn nước, chặng hành trình kế tiếp.
func _draw_village_map(hud: Node) -> void:
	var H := 720.0
	var sc := .36
	var mw := VillageMap.MAP_SIZE.x * sc
	var mh := VillageMap.MAP_SIZE.y * sc
	var mx := 14.0
	var my := H - mh - 16.0
	var mb := func(b: Vector2) -> Vector2: return Vector2(mx + b.x * sc, my + b.y * sc)
	var ml := func(x: float, z: float) -> Vector2: return Vector2(mx, my) + vmap.local_to_bible(x, z) * sc
	var spec: Dictionary = vmap.spec
	hud.panel(Vector2(mx - 6, my - 6), Vector2(mw + 12, mh + 12), Color(.05, .09, .11, .82))
	var fc: Array = spec.get("filler", {}).get("color", [.5, .62, .32])
	hud.rect(Vector2(mx, my), Vector2(mw, mh), Color(fc[0], fc[1], fc[2]))
	var zones: Dictionary = spec.get("zones", {})
	for zid in zones:
		var zc: Array = zones[zid].get("color", [.5, .5, .5])
		for rc in zones[zid].get("rects", []):
			hud.rect(mb.call(Vector2(rc[0], rc[1])), Vector2(rc[2] - rc[0], rc[3] - rc[1]) * sc, Color(zc[0], zc[1], zc[2]))
	var water: Dictionary = spec.get("water", {})
	var paddy: Dictionary = water.get("paddy_main", {})
	if not paddy.is_empty():
		var r: Array = paddy["rect"]
		hud.rect(mb.call(Vector2(r[0], r[1])), Vector2(r[2] - r[0], r[3] - r[1]) * sc, Color(.42, .58, .3))
	for k in ["canal_main", "canal_branch"]:
		var w: Dictionary = water.get(k, {})
		var pts: Array = w.get("centerline", [])
		for i in range(pts.size() - 1):
			hud.line(mb.call(Vector2(pts[i][0], pts[i][1])), mb.call(Vector2(pts[i + 1][0], pts[i + 1][1])), Color(.27, .56, .8), maxf(2.0, float(w["w"]) * sc))
	var pond: Dictionary = water.get("pond_main", {})
	if not pond.is_empty():
		var poly := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			poly.append(mb.call(Vector2(pond["center"][0] + cos(a) * pond["radii"][0], pond["center"][1] + sin(a) * pond["radii"][1])))
		hud.poly(poly, Color(.27, .58, .8))
	for k in spec.get("roads", {}):
		var rd: Dictionary = spec["roads"][k]
		var pts: Array = rd["points"]
		for i in range(pts.size() - 1):
			hud.line(mb.call(Vector2(pts[i][0], pts[i][1])), mb.call(Vector2(pts[i + 1][0], pts[i + 1][1])), Color(.86, .74, .55), maxf(1.5, float(rd["w"]) * sc))
	var mr := vmap.market_rect()
	if mr.has_area():
		var a: Vector2 = ml.call(mr.position.x, mr.position.y)
		var b: Vector2 = ml.call(mr.end.x, mr.end.y)
		hud.rect(a, b - a, Color(.86, .62, .3))
		hud.text("Chợ", (a + b) / 2.0 + Vector2(0, -9), 11, Color(1, .95, .8), 1)
	for key in vmap.nodes_with_prefix("HousePoint_"):
		var lp := vmap.node_local(key)
		var c: Vector2 = ml.call(lp.x, lp.z)
		hud.rect(c - Vector2(3, 3), Vector2(6, 6), Color(.82, .36, .26) if key == "HousePoint_01" else Color(.72, .32, .24))
	for i in Game.SITES.size():
		var s2: Vector3 = Game.site_pos(i)
		hud.circle(ml.call(s2.x, s2.y), 3.0, Color(.75, .95, 1.0) if not Game.site_dry(i) else Color(.6, .5, .4))
	# số khu vực theo hành trình; chặng kế tiếp nhấp nháy
	var nxt := Game.journey_next()
	for zi in Game.JOURNEY.size():
		var zid: String = Game.JOURNEY[zi]
		var zp: Vector2 = mb.call(vmap.zone_focus(zid))
		var known: bool = Game.L.get("zones", {}).has(zid)
		if zid == nxt:
			hud.circle(zp, 10.0 + 2.0 * sin(Time.get_ticks_msec() / 180.0), Color(1, .85, .3, .45))
		hud.circle(zp, 7.5, Color(0, 0, 0, .65))
		hud.circle(zp, 6.2, Color(1, .88, .45) if known else Color(.75, .75, .72))
		hud.text(str(zi + 1), zp, 11, Color(.15, .1, .05), 1)
	var pp := body.global_position
	for h in hosts:
		if not h.away:
			hud.circle(ml.call(h.pos.x, h.pos.y), 2.2, Color(1, .69, .29))
	for d in dragons:
		if Vector2(d.pos.x - pp.x, d.pos.z - pp.z).length() < 30.0:
			hud.circle(ml.call(d.pos.x, d.pos.z), 3.0, Color(1, .3, .3))
	var pc: Vector2 = ml.call(pp.x, pp.z)
	var fdir := Vector2(-sin(view_yaw), -cos(view_yaw))
	var side := Vector2(-fdir.y, fdir.x)
	hud.poly(PackedVector2Array([pc + fdir * 8.0, pc - fdir * 4.0 + side * 5.0, pc - fdir * 4.0 - side * 5.0]), Color.WHITE)
	hud.text("N", Vector2(mx + mw - 10, my + 11), 13, Color(1, 1, 1, .9))
	var zn := "Chợ làng" if in_market else String(Game.ZONES.get(zone, {}).get("name", "Làng quê"))
	hud.text("Khu vực: %s" % zn, Vector2(mx + 2, my - 34), 15, Color(1, .92, .65))
	var jt := "Hành trình %d/8" % Game.journey_count()
	if nxt != "":
		jt += " · tiếp: %d. %s" % [Game.JOURNEY.find(nxt) + 1, String(Game.ZONES[nxt]["name"])]
	hud.text(jt, Vector2(mx + 2, my - 16), 13, Color(.8, .95, .82))

func bite_spots(h: Host, o: Vector3) -> Array:
	## Các điểm có thể đốt trên cơ thể vật chủ, ở phía đang hướng về muỗi (o = hướng ngang từ vật chủ ra phía muỗi).
	var out: Array = []
	var P := Vector3(h.pos.x, 0, h.pos.y)
	if h.human:
		var s: float = float(h.def["h"]) / 1.78
		var lat := Vector3(o.z, 0, -o.x)
		var side := 1.0 if sin(h.ph * 7.0) > 0.0 else -1.0
		if h.rig != null and h.rig.bone_pos("Torso") != Vector3.ZERO:
			var sd := "R" if side > 0.0 else "L"
			var dirv := ((o * .5 + Vector3.UP * .85) if h.sleeping else (o + Vector3.UP * .15)).normalized()
			var segs: Array
			if h.sleeping:
				segs = [["Cổ", "Neck", "Head", .2, .055], ["Tay", "UpperArm." + sd, "LowerArm." + sd, .5, .05], ["Ngực", "Torso", "Neck", .4, .12], ["Đùi", "UpperLeg." + sd, "LowerLeg." + sd, .5, .09], ["Bàn chân", "LowerLeg." + sd, "Foot." + sd, .85, .05]]
			elif h.sitting:
				segs = [["Cổ", "Neck", "Head", .2, .055], ["Vai", "Shoulder." + sd, "UpperArm." + sd, .5, .06], ["Ngực", "Torso", "Neck", .4, .13], ["Đùi", "UpperLeg." + sd, "LowerLeg." + sd, .5, .09], ["Cẳng chân", "LowerLeg." + sd, "Foot." + sd, .5, .06]]
			else:
				segs = [["Cổ", "Neck", "Head", .2, .055], ["Ngực", "Torso", "Neck", .4, .13], ["Cánh tay", "UpperArm." + sd, "LowerArm." + sd, .5, .05], ["Cẳng tay", "LowerArm." + sd, "Palm." + sd, .5, .04], ["Bắp chân", "LowerLeg." + sd, "Foot." + sd, .45, .06], ["Mắt cá chân", "LowerLeg." + sd, "Foot." + sd, .9, .045]]
			for sg in segs:
				var pa: Vector3 = h.rig.bone_pos(sg[1])
				var pb: Vector3 = h.rig.bone_pos(sg[2])
				if pa == Vector3.ZERO or pb == Vector3.ZERO:
					continue
				var axis := (pb - pa)
				var ctr := pa.lerp(pb, float(sg[3]))
				var nn := dirv
				if axis.length() > .01:
					axis = axis.normalized()
					nn = dirv - axis * dirv.dot(axis)
				if nn.length() < .15:
					nn = dirv
				nn = nn.normalized()
				out.append({"name": sg[0], "pos": ctr + nn * float(sg[4]) * s, "nrm": nn})
			if out.size() > 0:
				return out
		if h.sleeping:
			var a := Vector3(h.pos.x - .85 * s, lie_y[h.k] + .13 * s, h.pos.y)
			var b := Vector3(h.pos.x + .9 * s, lie_y[h.k] + .13 * s, h.pos.y)
			var n_up := (o * .5 + Vector3.UP * .85).normalized()
			var n_arm := (lat * side * .6 + Vector3.UP * .7).normalized()
			for e in [["Cổ", .12, n_up], ["Tay", .34, n_arm], ["Đùi", .68, n_up], ["Bàn chân", .97, n_up]]:
				out.append({"name": e[0], "pos": a.lerp(b, e[1]) + (e[2] as Vector3) * .2 * s, "nrm": e[2]})
		elif h.sitting:
			for e in [["Cổ", 1.18, .1, o], ["Vai", .98, .2, o], ["Đùi", .56, .24, o], ["Cẳng chân", .3, .26, o]]:
				var d: Vector3 = e[3]
				out.append({"name": e[0], "pos": P + d * float(e[2]) * s + Vector3(0, float(e[1]) * s, 0), "nrm": d})
		else:
			for e in [["Cổ", 1.48, .1, o], ["Ngực", 1.22, .2, o], ["Cánh tay", 1.02, .3, lat * side], ["Cẳng tay", .8, .32, lat * side], ["Bắp chân", .36, .14, o], ["Mắt cá chân", .1, .11, o]]:
				var d2: Vector3 = e[3]
				out.append({"name": e[0], "pos": P + d2 * float(e[2]) * s + Vector3(0, float(e[1]) * s, 0), "nrm": d2})
	else:
		var c := Vector3(h.pos.x, h.y, h.pos.y)
		var r: float = h.def["r"]
		for e in [["Lưng", Vector3.UP], ["Sườn", o], ["Vai", (o + Vector3.UP).normalized()]]:
			var dn: Vector3 = e[1]
			out.append({"name": e[0], "pos": c + dn * (r + .01), "nrm": dn})
	return out

func _horiz_out(h: Host, from: Vector3) -> Vector3:
	var o := Vector3(from.x - h.pos.x, 0, from.z - h.pos.y)
	if o.length() < .05:
		o = Vector3(sin(h.yaw), 0, cos(h.yaw))
	return o.normalized()

func _spot(h: Host, i: int, o: Vector3) -> Dictionary:
	var list := bite_spots(h, o)
	return list[clampi(i, 0, list.size() - 1)]

func _refresh_aim() -> void:
	## Tia từ tâm màn hình: nếu chạm vào cơ thể người/thú thì chấm tâm chuyển đỏ và lưu điểm đậu.
	pl["aim"] = null
	var org := cam.global_position
	var dir := -cam.global_transform.basis.z
	var best_s := 1e9
	for h in hosts:
		if h.away or host_dist(h) > 6.5:
			continue
		var bd := host_body(h)
		var a: Vector3 = bd["a"]
		var b: Vector3 = bd["b"]
		var rad: float = float(bd["r"])
		var d2 := b - a
		var rr := org - a
		var e := d2.dot(d2)
		var f := d2.dot(rr)
		var c := dir.dot(rr)
		var sp := 0.0
		var tp := 0.0
		if e < 1e-8:
			sp = maxf(-c, 0.0)
		else:
			var bb := dir.dot(d2)
			var denom := e - bb * bb
			if denom > 1e-8:
				sp = maxf((bb * f - c * e) / denom, 0.0)
			tp = clampf((bb * sp + f) / e, 0.0, 1.0)
			sp = maxf(bb * tp - c, 0.0)
		var p1 := org + dir * sp
		var p2 := a + d2 * tp
		if p1.distance_to(p2) <= rad * 1.35 + .05 and sp < 8.0 and sp < best_s:
			var n := p1 - p2
			if n.length() < .0001:
				n = org - p2
			n = n.normalized()
			best_s = sp
			pl["aim"] = {"h": h, "pos": p2 + n * rad, "nrm": n, "name": ""}
			if h.human:
				var sl := bite_spots(h, _horiz_out(h, org))
				var bdist := 1e9
				for e2 in sl:
					var rel: Vector3 = (e2["pos"] as Vector3) - org
					var dline := (rel - dir * rel.dot(dir)).length()
					if dline < bdist:
						bdist = dline
						pl["aim"] = {"h": h, "pos": e2["pos"], "nrm": e2["nrm"], "name": e2["name"]}

func _target_spot(h: Host) -> Dictionary:
	var nm: String = String(pl.get("tgt_name", ""))
	if h.human and nm != "":
		for e in bite_spots(h, pl["tgt_o"]):
			if e["name"] == nm:
				pl["tgt_nrm"] = e["nrm"]
				return {"pos": e["pos"], "nrm": e["nrm"], "name": nm}
	return {"pos": Vector3(h.pos.x, 0, h.pos.y) + (pl["tgt_off"] as Vector3), "nrm": pl["tgt_nrm"], "name": ""}

func debug_land(h: Host, i: int) -> void:
	## (kiểm thử) đặt muỗi đang hút máu tại một điểm trên vật chủ h
	var o := _horiz_out(h, body.global_position)
	var sp := _spot(h, i, o)
	pl["tgt_h"] = h
	pl["tgt_off"] = (sp["pos"] as Vector3) - Vector3(h.pos.x, 0, h.pos.y)
	pl["tgt_nrm"] = sp["nrm"]
	pl["tgt_name"] = sp.get("name", "")
	pl["tgt_o"] = o
	body.global_position = sp["pos"] + (sp["nrm"] as Vector3) * .031
	_land(h)

## Tìm bề mặt (tường, trần, sàn, bụi cây) trong tầm 0,5 m để đậu nghỉ.
func _perch_surface(p: Vector3) -> Dictionary:
	for b in bushes:
		if p.distance_to(b) < 1.1 and p.y < (1.8 if vmap == null else b.y + .9):
			return {"pos": p, "nrm": Vector3.UP}
	var space := get_world_3d().direct_space_state
	var best := {}
	var bd := .5
	for dir in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK, Vector3(1, 1, 0).normalized(), Vector3(-1, 1, 0).normalized(), Vector3(0, 1, 1).normalized(), Vector3(0, 1, -1).normalized()]:
		var q := PhysicsRayQueryParameters3D.create(p, p + dir * .5)
		q.exclude = [body.get_rid()]
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			var d := p.distance_to(hit["position"])
			if d < bd:
				bd = d
				best = {"pos": (hit["position"] as Vector3) + (hit["normal"] as Vector3) * .02, "nrm": hit["normal"]}
	var g := gy(p.x, p.z)
	if best.is_empty() and p.y < g + .12:
		best = {"pos": Vector3(p.x, g + .03, p.z), "nrm": Vector3.UP}
	if best.is_empty() and zone == "Z06" and p.y < g + 3.0:
		best = {"pos": p, "nrm": Vector3.UP}    # đậu trên thân tre trong rừng tre
	return best

func _perch_logic(dt: float, wants: bool) -> bool:
	var n: Vector3 = pl["perch"]
	v = Vector3.ZERO
	body.velocity = Vector3.ZERO
	pl["nrm"] = n
	if wants or Input.is_action_just_pressed("act") or Input.is_action_just_pressed("feed"):
		pl["perch"] = null
		pl["unperch_t"] = .4
		v = n * .8
		return false
	return true

func _land(h: Host) -> void:
	pl["mode"] = "feeding"
	pl["landed"] = {"h": h}
	pl["full_t"] = 0.0
	v = Vector3.ZERO
	Sfx.beep(330, .07, "sine", .04, 60)

func _clear_point(from: Vector3, to: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [body.get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return to
	return (hit["position"] as Vector3) - (to - from).normalized() * .12

func _begin_retreat() -> void:
	## Thả chuột phải: nếu không nguy hiểm chỉ lùi nhẹ ra khỏi người; nếu họ đã nghi ngờ thì lùi xa hơn;
	## nếu cú đập đã bắt đầu thì bật lên chỗ an toàn.
	var h: Host = pl["tgt_h"]
	var from := body.global_position
	var urgent: bool = h != null and h.st == "wind"
	var danger: bool = h != null and (h.react == "scratch" or h.react == "wind" or h.alert >= .5)
	pl["mode"] = "retreat"
	pl["landed"] = null
	pl["sucking"] = false
	pl["retreat_t"] = 0.0
	pl["spots"] = []
	var to := from
	var spd := 1.8
	if urgent and h != null:
		to = _safe_spot(h, from)
		spd = 4.6
	elif danger and h != null:
		var away := Vector3(from.x - h.pos.x, 0, from.z - h.pos.y)
		if away.length() < .05:
			away = pl["tgt_nrm"]
		away = away.normalized()
		to = _clear_point(from, from + away * 1.4 + Vector3(0, .5, 0))
		spd = 3.0
	else:
		var n: Vector3 = pl["tgt_nrm"]
		to = _clear_point(from, from + n * .6 + Vector3(0, .12, 0))
	pl["retreat_to"] = to
	pl["retreat_spd"] = spd
	pl["retreat_urgent"] = urgent
	v = (to - from).normalized() * minf(spd, 2.4)
	Sfx.beep(520, .08, "triangle", .04, 300)

func _safe_spot(h: Host, from: Vector3) -> Vector3:
	var reach: float = h.def["reach"]
	var indoor := in_house(from.x, from.z, .2)
	var y := minf(reach + .55, 2.5) if indoor else gy(from.x, from.z) + reach + .6
	var away := Vector3(from.x - h.pos.x, 0, from.z - h.pos.y)
	if away.length() < .05:
		away = Vector3(-sin(h.yaw), 0, -cos(h.yaw))
	away = away.normalized()
	var space := get_world_3d().direct_space_state
	var best := Vector3(from.x, y, from.z)
	var best_len := -1.0
	for cand in [Vector3(from.x + away.x * .9, y, from.z + away.z * .9), Vector3(from.x, y, from.z)]:
		var q := PhysicsRayQueryParameters3D.create(from, cand)
		q.exclude = [body.get_rid()]
		var hit := space.intersect_ray(q)
		var reach_pt: Vector3 = cand
		if not hit.is_empty():
			reach_pt = (hit["position"] as Vector3) - (cand - from).normalized() * .12
		var ln := (reach_pt - from).length()
		if ln > best_len:
			best_len = ln
			best = reach_pt
	return best

func _feed_logic(dt: float, wants: bool) -> bool:
	## Trả về true nếu tự động điều khiển muỗi trong khung hình này.
	var hold := Input.is_action_pressed("feed")
	var hit := Input.is_action_just_pressed("feed")
	var ppos := body.global_position
	var mode: String = pl["mode"]
	if mode == "free":
		_refresh_aim()
		pl["spots"] = []
		if hit:
			var aim: Variant = pl["aim"]
			if not pl["mated"]:
				prompt = "Muỗi cái phải giao phối trước rồi mới đi tìm máu — làm theo nhiệm vụ hiện tại"
			elif aim != null:
				var ah: Host = aim["h"]
				pl["tgt_h"] = ah
				pl["tgt_off"] = (aim["pos"] as Vector3) - Vector3(ah.pos.x, 0, ah.pos.y)
				pl["tgt_nrm"] = aim["nrm"]
				pl["tgt_name"] = aim.get("name", "")
				pl["tgt_o"] = _horiz_out(ah, ppos)
				pl["mode"] = "approach"
				pl["appr_t"] = 0.0
				Sfx.beep(420, .06, "sine", .04, 200)
			else:
				prompt = "Chưa ngắm trúng ai — đưa chấm tâm vào cơ thể người/thú (chấm chuyển đỏ)"
		elif pl["aim"] != null and pl["mated"]:
			prompt = "Giữ CHUỘT PHẢI: bay tới đậu & hút máu  ·  thả ra để tự rút lui"
		return false
	var h: Host = pl["tgt_h"]
	if h == null or h.away:
		_begin_retreat()
		return true
	var sp := _target_spot(h)
	var spos: Vector3 = sp["pos"]
	var snrm: Vector3 = sp["nrm"]
	if mode != "retreat":
		pl["spots"] = [{"h": h, "pos": spos, "nrm": snrm, "name": "", "sel": true}]
	match mode:
		"approach":
			prompt = "Đang bay tới… (thả chuột phải để hủy)"
			pl["appr_t"] += dt
			if not hold:
				if host_dist(h) < 1.6 or h.st == "wind":
					_begin_retreat()
				else:
					pl["mode"] = "free"
				return true
			var tp := spos + snrm * .04
			var dv := tp - ppos
			var dist := dv.length()
			if dist < .07:
				_land(h)
				return true
			var spd := minf(3.0, .5 + dist * 2.4)
			v = v.lerp(dv / maxf(dist, .001) * spd, 1.0 - exp(-7.0 * dt))
			body.velocity = v
			body.move_and_slide()
			v = body.velocity
			if pl["appr_t"] > 8.0:
				pl["mode"] = "free"
			return true
		"feeding":
			body.global_position = spos + snrm * (.031 - (.006 + .002 * sin(A["t"] * 17.0) if pl["sucking"] else 0.0))   # đầu ghim vòi sát da; lúc hút vòi cắm sâu hơn
			v = Vector3.ZERO
			pl["nrm"] = snrm
			if not hold:
				_begin_retreat()
				return true
			if pl["blood"] >= 1.0:
				prompt = "Đã no — rút lui!"
				pl["full_t"] += dt
				if pl["full_t"] > .5:
					_begin_retreat()
				return true
			prompt = "Đang hút máu %s — THẢ CHUỘT PHẢI nếu thấy nguy hiểm" % String(h.def["name"]).to_lower()
			pl["sucking"] = true
			var gain: float = .22 * (1.0 + .08 * Game.tv("fee")) * dt
			pl["blood"] = minf(1.0, pl["blood"] + gain)
			pl["protein"] += gain * h.def["reward"]
			pl["energy"] = minf(100.0, pl["energy"] + gain * 90.0)
			Game.q_set("blood", pl["protein"] * 100.0)
			return true
		"retreat":
			prompt = "Rút lui!"
			pl["retreat_t"] += dt
			var to: Vector3 = pl["retreat_to"]
			var dv2 := to - ppos
			var dist2 := dv2.length()
			var rspd: float = pl["retreat_spd"]
			var arrive := clampf(dist2 * 3.0, 0.15, 1.0)            # giảm tốc khi gần tới nơi
			v = v.lerp(dv2 / maxf(dist2, .001) * rspd * arrive, 1.0 - exp(-(16.0 if rspd > 4.0 else 9.0) * dt))
			body.velocity = v
			body.move_and_slide()
			v = body.velocity
			var far := Vector2(ppos.x - h.pos.x, ppos.z - h.pos.y).length() > float(h.def["swat"]) + .9
			var max_t := 1.3 if rspd > 4.0 else .9
			if dist2 < .12 or pl["retreat_t"] > max_t or (pl["retreat_urgent"] and far and pl["retreat_t"] > .35):
				pl["mode"] = "free"
				v *= .25
			return true
	return false

func _threat_point() -> Vector3:
	return body.global_position
