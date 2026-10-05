extends Node3D
class_name AquaticWorld
## Giai đoạn dưới nước (3D): trứng → lăng quăng → nhộng. Mặt nước ở y = surf, đáy ở y = -depth.

signal died(cause: String)
signal advance(next: String)

const EGG_TIME := 9.0
const PUPA_TIME := 10.0
const FOOD := {
	"bact": {"r": .07, "val": 2.0, "c": Color(.72, .91, .42)},
	"plant": {"r": .14, "val": 4.0, "c": Color(.3, .62, .28)},
	"micro": {"r": .08, "val": 3.5, "c": Color(1, .72, .5)},
	"org": {"r": .1, "val": 5.0, "c": Color(.5, .38, .25)},
}

class Pred extends RefCounted:
	var k := ""
	var node: Node3D
	var pos := Vector3.ZERO
	var vel := Vector3.ZERO
	var face := Vector3(1, 0, 0)
	var st := "patrol"
	var t := 0.0
	var cd := 0.0
	var ph := 0.0
	var tgt := Vector3.ZERO
	var home := Vector3.ZERO
	var legs: Array = []

var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var root: Node3D
var dynroot: Node3D
var water_mat: ShaderMaterial
var water_plane: MeshInstance3D
var bubbles: CPUParticles3D
var built_for := -1
var built_weather := ""

var stage := "egg"
var active := false
var dead := false
var site: Dictionary = {}
var pc: Dictionary = {}
var W := 20.0
var D := 20.0
var depth := 6.0
var surf := 0.0
var lvl := 0.0          # độ hạ mực nước (hạn hán / bị đổ)
var weather := "normal"
var t := 0.0
var stage_t := 0.0
var pl: Dictionary = {}
var p_pos := Vector3.ZERO
var p_vel := Vector3.ZERO
var view_yaw := 0.0
var view_pitch := -.25
var node_player: Node3D
var preds: Array = []
var food: Array = []
var sibs: Array = []
var weeds: Array = []
var rocks: Array = []
var leaves: Array = []
var food_t := 0.0
var draining := false
var human_at := -1.0
var warned := false
var prompt := ""
var shake := 0.0
var hud_ref: Node
var fx_list: Array = []
var debug_cam_dist := 0.0
var pulse := 0.0
var _threat_flag := false
var raft_c := Vector3.ZERO
var _dt := 0.016
var _sy := 0.0
var _sp := 0.0
var _ps := Vector3.ZERO
var caustics: Array = []
var motes: CPUParticles3D
var fxl: FxLayer
var _emerge_t := 0.0

# ═════════════ dựng hồ ═════════════
func _ready() -> void:
	pass

func _rnd(a: float, b: float) -> float:
	return randf_range(a, b)

func _build_base() -> void:
	if root != null:
		return
	root = Node3D.new()
	add_child(root)
	dynroot = Node3D.new()
	add_child(dynroot)
	fxl = FxLayer.new()
	add_child(fxl)
	var we := WorldEnvironment.new()
	env = Environment.new()
	var sky := Sky.new()
	var pm := PanoramaSkyMaterial.new()
	pm.panorama = load("res://assets/textures/sky.hdr")
	sky.sky_material = pm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# phong cách "Việt Nam rural cinematic realism": màu trầm, ấm, bớt bão hòa
	env.adjustment_enabled = true
	env.adjustment_saturation = .86
	env.adjustment_contrast = 1.05
	env.adjustment_brightness = 1.0
	env.fog_enabled = true
	env.glow_enabled = true
	env.glow_intensity = .3
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.0
	env.volumetric_fog_albedo = Color(.6, .85, .9)
	env.volumetric_fog_anisotropy = .55
	env.volumetric_fog_length = 40.0
	env.ssao_enabled = false
	we.environment = env
	root.add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-62, -25, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.5
	sun.light_volumetric_fog_energy = 2.0
	sun.directional_shadow_max_distance = 40.0
	root.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 70
	cam.near = .03
	cam.far = 200
	root.add_child(cam)
	# mặt nước
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
uniform vec4 col : source_color = vec4(0.2, 0.5, 0.6, 0.55);
uniform float under = 0.0;
void fragment() {
	float t = TIME;
	vec2 uv = UV * 40.0;
	float w = sin(uv.x * 2.1 + t * 1.4) * 0.5 + sin(uv.y * 2.7 - t * 1.1) * 0.5 + sin((uv.x + uv.y) * 1.3 + t * 0.8) * 0.5;
	ALBEDO = col.rgb + vec3(0.05) * w;
	ALPHA = col.a;
	ROUGHNESS = 0.04;
	METALLIC = 0.25;
	SPECULAR = 0.9;
	EMISSION = col.rgb * 0.12 * (0.6 + 0.4 * w);
	NORMAL = normalize(NORMAL + vec3(dFdx(w), 0.0, dFdy(w)) * 0.6);
	if (under > 0.5) {
		float ndv = abs(dot(normalize(NORMAL), normalize(VIEW)));
		float win = smoothstep(0.36, 0.52, ndv);
		ALBEDO = mix(col.rgb * 0.22, vec3(0.75, 0.92, 1.0) * 0.95, win);
		ALPHA = mix(0.96, 0.22, win);
		EMISSION = mix(vec3(0.0), vec3(0.45, 0.6, 0.7) * (0.6 + 0.4 * w), win);
	}
}
"""
	water_mat = ShaderMaterial.new()
	water_mat.shader = sh
	water_plane = MeshInstance3D.new()
	var pmesh := PlaneMesh.new()
	pmesh.size = Vector2(60, 60)
	water_plane.mesh = pmesh
	water_plane.material_override = water_mat
	water_plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(water_plane)
	bubbles = CPUParticles3D.new()
	bubbles.amount = 60
	bubbles.lifetime = 5.0
	bubbles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	bubbles.direction = Vector3(0, 1, 0)
	bubbles.gravity = Vector3.ZERO
	bubbles.initial_velocity_min = .6
	bubbles.initial_velocity_max = 1.1
	var sm := SphereMesh.new()
	sm.radius = .05
	sm.height = .1
	bubbles.mesh = sm
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(1, 1, 1, .35)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bubbles.material_override = bm
	root.add_child(bubbles)

func _box(parent: Node3D, size: Vector3, c: Vector3, mat: Material) -> MeshInstance3D:
	var mi := Assets.box_mesh(size, mat)
	mi.position = c
	parent.add_child(mi)
	return mi

func _build_pond(site_idx: int) -> void:
	_build_base()
	for c in dynroot.get_children():
		c.queue_free()
	for c in root.get_children():
		if c.has_meta("pond"):
			c.queue_free()
	site = Game.SITES[site_idx]
	pc = site["pond"]
	W = float(pc["w"]) * 1.2; D = float(pc["d"]) * 1.2; depth = float(pc["depth"]) * 1.1
	var pond := Node3D.new()
	pond.set_meta("pond", true)
	root.add_child(pond)
	var dirt := Assets.tex_material("ground_dirt", Vector3(.25, .25, .25), Color(.8, .8, .75))
	var grass := Assets.tex_material("ground_grass", Vector3(.08, .08, .08), Color(.8, .95, .7))
	var rim_col := Color(.43, .48, .52) if site["id"] == "bucket" else (Color(.69, .39, .24) if site["id"] == "jar" else Color(.4, .35, .28))
	var rim: Material = Assets.color_material(rim_col, .6) if (site["id"] == "bucket" or site["id"] == "jar") else dirt
	var top := .5
	var hx := W / 2.0
	var hz := D / 2.0
	# đáy & tường hồ
	_box(pond, Vector3(W + 2, 1, D + 2), Vector3(0, -depth - .5, 0), dirt)
	_box(pond, Vector3(1, depth + top, D + 2), Vector3(-hx - .5, (-depth + top) / 2.0, 0), rim)
	_box(pond, Vector3(1, depth + top, D + 2), Vector3(hx + .5, (-depth + top) / 2.0, 0), rim)
	_box(pond, Vector3(W + 2, depth + top, 1), Vector3(0, (-depth + top) / 2.0, -hz - .5), rim)
	_box(pond, Vector3(W + 2, depth + top, 1), Vector3(0, (-depth + top) / 2.0, hz + .5), rim)
	# mặt đất xung quanh
	var g1 := Assets.box_mesh(Vector3(200, 1, 200), grass)
	g1.position = Vector3(0, -.5 + .0, 0)
	g1.visible = false
	pond.add_child(g1)
	for s in [[Vector3(100, 1, 200), Vector3(-hx - 1 - 50, top - .5, 0)], [Vector3(100, 1, 200), Vector3(hx + 1 + 50, top - .5, 0)],
			[Vector3(W + 2, 1, 100), Vector3(0, top - .5, -hz - 1 - 50)], [Vector3(W + 2, 1, 100), Vector3(0, top - .5, hz + 1 + 50)]]:
		_box(pond, s[0], s[1], grass)
	# tint nước & sương mù
	var tint: Color = pc["tint"]
	water_mat.set_shader_parameter("col", Color(tint.r * 1.1, tint.g * 1.2, tint.b * 1.2, .5))
	# rong, đá, lá
	weeds.clear(); rocks.clear(); leaves.clear()
	var nw := maxi(2, int(round(W / 7.0)))
	var wm := Assets.color_material(Color(.2, .55, .25), .8)
	for i in nw:
		var wx := -hx + W * (float(i) + .5) / nw + _rnd(-1, 1)
		var wz := _rnd(-hz * .7, hz * .7)
		var cluster := Node3D.new()
		cluster.position = Vector3(wx, -depth, wz)
		pond.add_child(cluster)
		for k in 6:
			var blade := Assets.model("grass", _rnd(1.6, 2.6), "Grass_Large_Extruded")
			blade.position = Vector3(_rnd(-.7, .7), 0, _rnd(-.7, .7))
			blade.rotation_degrees.y = _rnd(0, 360)
			cluster.add_child(blade)
		weeds.append(Vector3(wx, -depth + 1.3, wz))
	var nr := maxi(1, int(round(W / 12.0)))
	for i in nr:
		var rx := _rnd(-hx * .7, hx * .7)
		var rz := _rnd(-hz * .7, hz * .7)
		var rk := Assets.model("rock", _rnd(1.4, 2.0), "", "y")
		rk.position = Vector3(rx, -depth, rz)
		rk.rotation_degrees.y = _rnd(0, 360)
		pond.add_child(rk)
		rocks.append(Vector3(rx, -depth + .8, rz))
	var nl := maxi(1, int(round(W / 10.0)))
	for i in nl:
		var lx := -hx + W * (float(i) + .5) / nl + _rnd(-1.5, 1.5)
		var lz := _rnd(-hz * .6, hz * .6)
		var leaf := Assets.cyl_mesh(1.7, 1.7, .06, Assets.color_material(Color(.3, .6, .22), .6), 24)
		leaf.scale = Vector3(1.0, 1.0, .85)
		leaf.set_meta("leaf", true)
		leaf.position = Vector3(lx, 0, lz)
		pond.add_child(leaf)
		leaves.append({"pos": Vector3(lx, 0, lz), "node": leaf})
	bubbles.emission_box_extents = Vector3(hx * .9, .1, hz * .9)
	bubbles.position = Vector3(0, -depth, 0)
	bubbles.lifetime = depth / .8
	var dark: float = pc["dark"]
	sun.light_energy = 1.9 * (1.0 - dark * .7)
	_decorate_pond(pond, rim_col, site["id"] == "bucket" or site["id"] == "jar")

# ───────── chi tiết hồ: vân sáng, cây thủy sinh, sỏi, bụi lơ lửng ─────────
var _caustic_tex: Texture2D
var _ribbon: ArrayMesh
var _plant_mat: ShaderMaterial

func _caustic() -> Texture2D:
	if _caustic_tex == null:
		var fn := FastNoiseLite.new()
		fn.noise_type = FastNoiseLite.TYPE_CELLULAR
		fn.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
		fn.frequency = .06
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, .55, .8])
		g.colors = PackedColorArray([Color(0, 0, 0), Color(0, 0, 0), Color(1, 1, 1)])
		var t := NoiseTexture2D.new()
		t.noise = fn
		t.color_ramp = g
		t.seamless = true
		t.width = 512
		t.height = 512
		_caustic_tex = t
	return _caustic_tex

func _ribbon_mesh() -> ArrayMesh:
	if _ribbon == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var segs := 8
		for i in segs + 1:
			var h := float(i) / segs
			var w := .07 * (1.0 - h * .55)
			st.set_uv(Vector2(0, h)); st.add_vertex(Vector3(-w, h, 0))
			st.set_uv(Vector2(1, h)); st.add_vertex(Vector3(w, h, 0))
		for i in segs:
			var a := i * 2
			st.add_index(a); st.add_index(a + 1); st.add_index(a + 2)
			st.add_index(a + 1); st.add_index(a + 3); st.add_index(a + 2)
		st.generate_normals()
		_ribbon = st.commit()
		_plant_mat = ShaderMaterial.new()
		_plant_mat.shader = load("res://shaders/plant.gdshader")
	return _ribbon

func _decorate_pond(pond: Node3D, rim_col: Color, container: bool) -> void:
	var hx := W / 2.0
	var hz := D / 2.0
	caustics.clear()
	# vân sáng trên đáy (hai lớp xoay ngược chiều)
	for k in 2:
		var dc := Decal.new()
		dc.size = Vector3(W, depth + 1.0, D)
		dc.position = Vector3(0, -depth / 2.0, 0)
		dc.texture_emission = _caustic()
		dc.emission_energy = 1.1
		dc.modulate = Color(.7, 1.0, 1.0)
		dc.set_meta("dir", 1 if k == 0 else -1)
		dc.rotation.y = k * 1.3
		dc.upper_fade = .2
		dc.lower_fade = .6
		pond.add_child(dc)
		caustics.append(dc)
	# cây thủy sinh dạng dải lá (MultiMesh)
	var rib := _ribbon_mesh()
	var count := clampi(int(W * D / 3.2), 80, 420)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = rib
	mm.instance_count = count
	for i in count:
		var x := _rnd(-hx + .6, hx - .6)
		var z := _rnd(-hz + .6, hz - .6)
		var hgt := _rnd(.8, 2.8) if randf() < .8 else _rnd(2.8, minf(depth - .4, 5.0))
		var b := Basis.from_euler(Vector3(_rnd(-.12, .12), _rnd(0, TAU), _rnd(-.12, .12))).scaled(Vector3(_rnd(.8, 1.4), hgt, 1.0))
		mm.set_instance_transform(i, Transform3D(b, Vector3(x, -depth, z)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _plant_mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pond.add_child(mmi)
	# sỏi & đá cuội trên đáy
	var pm := SphereMesh.new()
	pm.radius = .5
	pm.height = 1.0
	pm.radial_segments = 8
	pm.rings = 5
	var pmm := MultiMesh.new()
	pmm.transform_format = MultiMesh.TRANSFORM_3D
	pmm.mesh = pm
	var pc_n := clampi(int(W * D / 1.5), 120, 520)
	pmm.instance_count = pc_n
	for i in pc_n:
		var r := _rnd(.06, .38)
		var tr := Transform3D(Basis.from_euler(Vector3(_rnd(0, 3), _rnd(0, 3), _rnd(0, 3))).scaled(Vector3(r, r * _rnd(.45, .8), r * _rnd(.7, 1.1))), Vector3(_rnd(-hx + .3, hx - .3), -depth + r * .15, _rnd(-hz + .3, hz - .3)))
		pmm.set_instance_transform(i, tr)
	var pmi := MultiMeshInstance3D.new()
	pmi.multimesh = pmm
	pmi.material_override = Assets.tex_material("ground_dirt", Vector3(2.5, 2.5, 2.5), Color(.78, .74, .68))
	pond.add_child(pmi)
	# thân lá súng nối xuống đáy
	for l in leaves:
		var lp: Vector3 = l["pos"]
		var stem := Assets.cyl_mesh(.025, .035, depth, Assets.color_material(Color(.22, .45, .18), .6), 6)
		stem.position = Vector3(lp.x, -depth / 2.0, lp.z)
		stem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pond.add_child(stem)
	# vát mép đáy (hồ tự nhiên) — không áp dụng với xô/chậu
	if not container:
		var dirt := Assets.tex_material("ground_dirt", Vector3(.25, .25, .25), Color(.75, .72, .66))
		for sgn in [-1.0, 1.0]:
			var w1 := Assets.box_mesh(Vector3(1.8, 1.8, D + 2), dirt)
			w1.position = Vector3(sgn * (hx - .1), -depth + .5, 0)
			w1.rotation_degrees.z = sgn * 45.0
			pond.add_child(w1)
			var w2 := Assets.box_mesh(Vector3(W + 2, 1.8, 1.8), dirt)
			w2.position = Vector3(0, -depth + .5, sgn * (hz - .1))
			w2.rotation_degrees.x = -sgn * 45.0
			pond.add_child(w2)
	# bụi và sinh vật phù du lơ lửng
	if motes == null:
		motes = CPUParticles3D.new()
		var sm := SphereMesh.new()
		sm.radius = .018
		sm.height = .036
		sm.radial_segments = 6
		sm.rings = 3
		motes.mesh = sm
		var mm2 := StandardMaterial3D.new()
		mm2.albedo_color = Color(1, 1, .9, .5)
		mm2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		motes.material_override = mm2
		motes.amount = 320
		motes.lifetime = 14.0
		motes.preprocess = 10.0
		motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		motes.direction = Vector3(0, 1, 0)
		motes.spread = 180.0
		motes.initial_velocity_min = .03
		motes.initial_velocity_max = .14
		motes.gravity = Vector3(0, -.01, 0)
		motes.scale_amount_min = .5
		motes.scale_amount_max = 1.8
		root.add_child(motes)
	motes.emission_box_extents = Vector3(hx * .95, depth * .5, hz * .95)
	motes.position = Vector3(0, -depth * .5, 0)

func _make_pond_content(nsib: int) -> void:
	preds.clear(); food.clear(); sibs.clear()
	for k in pc["preds"]:
		preds.append(_make_pred(k))
	var target := 8 + int(site["food"] * 34)
	for i in target:
		_spawn_food()
	for i in nsib:
		var sb := {"pos": Vector3(_rnd(-W / 2 + 2, W / 2 - 2), surf, _rnd(-D / 2 + 2, D / 2 - 2)), "vel": Vector3.ZERO, "alive": true, "tgt": Vector3.ZERO, "t": 0.0, "act": .2, "ph": _rnd(0, 6), "node": null, "off": Vector2.ZERO}
		var egg := _make_egg()
		dynroot.add_child(egg)
		sb["node"] = egg
		sibs.append(sb)

# ───────── mô hình sinh vật ─────────
func _make_egg(marked: bool = false) -> Node3D:
	return Bio.make_egg(marked)

func _make_larva(scale_: float, col: Color) -> Node3D:
	var g := Bio.make_larva(0, col)
	g.scale = Vector3.ONE * scale_
	return g

func _wiggle_larva(g: Node3D, tt: float, k: float, curl: float = 0.0) -> void:
	Bio.set_larva_motion(g, .06 + .05 * k, 7.0 + 5.0 * k, curl)

func _make_pupa(scale_: float) -> Node3D:
	var g := Bio.make_pupa()
	g.scale = Vector3.ONE * scale_
	return g

func _make_pred(k: String) -> Pred:
	var p := Pred.new()
	p.k = k
	p.ph = _rnd(0, 6)
	p.pos = Vector3(_rnd(-W / 2 + 3, W / 2 - 3), 0, _rnd(-D / 2 + 3, D / 2 - 3))
	p.face = Vector3(1, 0, 0) if randf() < .5 else Vector3(-1, 0, 0)
	match k:
		"fish":
			p.node = Assets.model("fish1" if randf() < .5 else "fish2", 2.0, "", "z")
			Assets.glossy(p.node, .32, .35, .7)
			p.pos.y = surf - depth * .45
		"beetle":
			p.node = _make_beetle(p)
			p.pos.y = surf - _rnd(1.5, depth - 1.0)
			p.tgt = p.pos
		"nymph":
			p.node = _make_nymph(p)
			var hz: Vector3 = (weeds + rocks)[randi() % (weeds.size() + rocks.size())]
			p.home = Vector3(hz.x + 1.0, -depth + .45, hz.z)
			p.pos = p.home
		"strider":
			p.node = _make_strider(p)
			p.pos.y = surf
	if p.k == "beetle": p.node.scale = Vector3.ONE * .6
	elif p.k == "nymph": p.node.scale = Vector3.ONE * .6
	elif p.k == "strider": p.node.scale = Vector3.ONE * .42
	dynroot.add_child(p.node)
	if p.k == "fish":
		Assets.play(p.node, "Swim", 1.2)
	return p

func _make_beetle(p: Pred) -> Node3D:
	var g := Bio.make_beetle()
	p.legs = g.get_meta("legs")
	return g

func _make_nymph(p: Pred) -> Node3D:
	var g := Bio.make_nymph()
	p.legs = g.get_meta("jaws")
	return g

func _make_strider(p: Pred) -> Node3D:
	return Bio.make_strider()

# ═════════════ điều khiển ═════════════
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

func fwd3() -> Vector3:
	return Vector3(-sin(view_yaw) * cos(view_pitch), sin(view_pitch), -cos(view_yaw) * cos(view_pitch))

func right3() -> Vector3:
	return Vector3(cos(view_yaw), 0, -sin(view_yaw))

# ═════════════ vào / ra giai đoạn ═════════════
func leave() -> void:
	active = false
	visible = false

func enter(st: String, resp: bool) -> void:
	stage = st
	active = true
	visible = true
	dead = false
	stage_t = 0.0
	t = 0.0 if not resp and st == "egg" else t
	prompt = ""
	var idx: int = Game.L["site"]
	var rebuild := (not resp and st == "egg") or built_for != idx or root == null
	if rebuild:
		_build_pond(idx)
		built_for = idx
		weather = Game.G["weather0"]
		fxl.clear_all()
		lvl = 0.0
		draining = false
		surf = 0.0
		_make_pond_content(Game.L["sibs"])
	cam.make_current()
	var old_pos := p_pos
	var old_growth: float = float(pl.get("growth", 0.0))
	var old_molts: int = int(pl.get("molts", 0))
	if node_player != null:
		node_player.queue_free()
		node_player = null
	pl = {"hp": 100.0, "maxhp": 100.0, "inv": 0.0, "act": 0.0, "hidden": false, "heat": 0.0, "et": 0.0, "o2": 100.0, "growth": 0.0, "dash_cd": 0.0, "dash_t": 0.0, "anchored": false, "pt": 0.0,
		"molts": 0, "molt_p": 0.0, "molt_pending": false, "was_surf": true, "below_t": 0.0, "threat_t": 0.0, "hatch_t": 0.0, "water_done": false, "safe_t": 0.0}
	var mh: float = 100.0 + 15.0 * Game.tv("vit")
	pl["maxhp"] = mh; pl["hp"] = mh
	match st:
		"egg":
			p_pos = Vector3(_rnd(-W / 2 + 3, W / 2 - 3), surf, _rnd(-D / 2 + 3, D / 2 - 3))
			raft_c = p_pos
			node_player = _make_egg(true)
			var offs := Bio.raft_offsets(sibs.size() + 1)
			for k in sibs.size():
				sibs[k]["off"] = offs[k + 1]
				sibs[k]["alive"] = true
				if sibs[k]["node"] != null:
					sibs[k]["node"].queue_free()
				sibs[k]["node"] = _make_egg()
				dynroot.add_child(sibs[k]["node"])
			for p in preds:
				var far := Vector2(p.pos.x - p_pos.x, p.pos.z - p_pos.z).length() < 8.0
				if far:
					p.pos.x = clampf(p_pos.x + (9.0 if p_pos.x < 0 else -9.0), -W / 2 + 2, W / 2 - 2)
					if p.k == "nymph": p.home.x = p.pos.x
				p.cd = maxf(p.cd, 2.5)
		"larva":
			var pg := 0.0
			if resp and old_pos != Vector3.ZERO:
				pg = old_growth * .5
			p_pos = Vector3(clampf(old_pos.x, -W / 2 + 2, W / 2 - 2), surf - .5, clampf(old_pos.z, -D / 2 + 2, D / 2 - 2)) if old_pos != Vector3.ZERO else Vector3(0, surf - .5, 0)
			node_player = _make_larva(1.0, Color.WHITE)
			for p in preds: p.cd = maxf(p.cd, 2.0)
			for sb in sibs:
				if sb["node"] != null: sb["node"].queue_free()
				sb["node"] = _make_larva(.6, Color.WHITE)
				dynroot.add_child(sb["node"])
				sb["pos"].y = surf - _rnd(.5, 2.0)
			var thr_now := [0.0, 25.0, 50.0, 75.0]
			pl["molts"] = old_molts if resp else 0
			pl["growth"] = maxf(pg, thr_now[int(pl["molts"])])
			if not resp:
				human_at = _rnd(35, 55) if (Game.L["gen"] > 1 and randf() < float(site["human_ev"])) else -1.0
				warned = false
		"pupa":
			p_pos = Vector3(clampf(old_pos.x, -W / 2 + 2, W / 2 - 2), clampf(old_pos.y, -depth + 1.0, surf - 1.0), clampf(old_pos.z, -D / 2 + 2, D / 2 - 2)) if old_pos != Vector3.ZERO else Vector3(0, surf - 3, 0)
			node_player = _make_pupa(1.0)
			for sb in sibs:
				if sb["node"] != null: sb["node"].queue_free()
				sb["node"] = _make_pupa(.75)
				dynroot.add_child(sb["node"])
	dynroot.add_child(node_player)
	if not resp:
		Game.q_begin(st)
		if st == "larva" and preds.is_empty():
			Game.q_edit("hunt", "Thợ lặn", "Lặn sâu dưới nước một lúc", 20.0, "giây")
		if st == "egg":
			pulse = 0.0
			hud_ref.banner("TRỨNG — " + Game.gen_note(), String(Game.STAGE_FACT["egg"]))
	p_vel = Vector3.ZERO
	view_yaw = 0.0
	view_pitch = -.5 if st == "egg" else -.15
	_cam_update(true, 0.0)

func kill(cause: String) -> void:
	if dead:
		return
	dead = true
	shake = .4
	Sfx.beep(180, .5, "saw", .08, -120)
	died.emit(cause)

func damage(d: float, cause: String) -> void:
	if pl["inv"] > 0.0 or dead:
		return
	if stage == "egg":
		kill(cause)
		return
	pl["hp"] -= d
	pl["inv"] = 1.2
	Game.G["hits"] += 1
	shake = .25
	Sfx.beep(260, .18, "square", .06, -120)
	if pl["hp"] <= 0.0:
		kill(cause)

# ═════════════ vòng cập nhật ═════════════
func shaded(p: Vector3) -> bool:
	for l in leaves:
		var lp: Vector3 = l["pos"]
		if absf(p.x - lp.x) < 2.0 and absf(p.z - lp.z) < 1.7:
			return true
	return false

func in_shelter(p: Vector3) -> bool:
	for w in weeds:
		if p.distance_to(w) < 1.7: return true
	for r in rocks:
		if p.distance_to(r) < 1.4: return true
	for l in leaves:
		if p.distance_to(Vector3(l["pos"].x, surf - .7, l["pos"].z)) < 1.8: return true
	return false

func _spawn_food() -> void:
	var r := randf()
	var tp := "bact" if r < .45 else ("plant" if r < .65 else ("micro" if r < .85 else "org"))
	var x := _rnd(-W / 2 + 1, W / 2 - 1)
	var z := _rnd(-D / 2 + 1, D / 2 - 1)
	var y := 0.0
	if tp == "plant": y = surf - _rnd(.3, 2.2)
	elif tp == "org": y = -depth + _rnd(.3, 2.5)
	else: y = -depth + _rnd(.5, depth - .6)
	var node := Bio.make_food(tp)
	node.position = Vector3(x, y, z)
	node.rotation = Vector3(randf() * 6.0, randf() * 6.0, randf() * 6.0)
	dynroot.add_child(node)
	food.append({"t": tp, "pos": Vector3(x, y, z), "ph": _rnd(0, 6.28), "node": node})

func _targets() -> Array:
	var a: Array = []
	var egg := stage == "egg"
	if not dead:
		a.append({"ref": "player", "pos": p_pos, "sp": p_vel.length(), "act": pl["act"], "hid": pl["hidden"], "egg": egg})
	for sb in sibs:
		if sb["alive"]:
			a.append({"ref": sb, "pos": sb["pos"], "sp": (sb["vel"] as Vector3).length(), "act": sb["act"], "hid": false, "egg": egg})
	return a

func _catch(tg: Dictionary, dmg: float, cause: String) -> void:
	if typeof(tg["ref"]) == TYPE_STRING:
		damage(dmg, cause)
	else:
		var sb: Dictionary = tg["ref"]
		sb["alive"] = false
		if sb["node"] != null:
			(sb["node"] as Node3D).visible = false

func _orient(n: Node3D, dir: Vector3, rate: float = 9.0) -> void:
	if dir.length() < .01:
		return
	var up := Vector3.UP
	if absf(dir.normalized().dot(Vector3.UP)) > .98:
		up = Vector3.RIGHT
	var tq := Basis.looking_at(dir.normalized(), up).get_rotation_quaternion()
	n.quaternion = n.quaternion.slerp(tq, 1.0 - exp(-rate * _dt))

func update(dt: float) -> void:
	if not active:
		return
	t += dt
	if shake > 0.0: shake -= dt
	_fx_update(dt)
	_update_env(dt)
	if dead:
		_update_sibs(dt)
		_update_preds(dt)
		_animate(dt)
		return
	Game.G["life_t"] += dt
	Game.tick_day(dt, Game.DAY_LEN_AQ)
	stage_t += dt
	# thủy vị
	if weather == "drought": lvl = minf(lvl + .035 * dt, 2.2)
	elif weather == "rain": lvl = maxf(lvl - .012 * dt, -.8)
	if draining: lvl += 1.8 * dt
	if pulse > 0.0:
		pulse -= dt
	surf = -lvl + (.22 * minf(1.0, pulse) if pulse > 0.0 else 0.0)
	if surf < -depth + .5:
		surf = -depth + .5
	if (stage == "larva" or stage == "pupa"):
		if human_at >= 0.0 and not draining and stage == "larva":
			if not warned and stage_t > human_at - 5.0:
				warned = true
				hud_ref.banner("CÓ NGƯỜI ĐẾN GẦN…", "Họ sắp đổ nước đi! Hãy lớn nhanh và hóa nhộng — hoặc chịu số phận")
			if stage_t > human_at:
				draining = true
				Sfx.beep(120, 1.0, "saw", .06, -60)
		if draining and surf <= -depth + .6:
			kill("Nước bị người đổ đi — môi trường sống biến mất")
			return
	_update_player(dt)
	if dead or not active:
		return
	_update_sibs(dt)
	_update_food(dt)
	_update_preds(dt)
	if stage == "larva":
		if _threat_flag:
			pl["threat_t"] += dt
			if pl["threat_t"] > 2.5:      # bị đuổi mà vẫn sống 2,5 giây là đủ
				Game.q_add("hunt", 1.0)
		else:
			if pl["threat_t"] > .3:
				Game.q_add("hunt", 1.0)
			pl["threat_t"] = 0.0
		# nếu mãi không gặp kẻ săn mồi, tự hoàn thành sau 45 giây ở nhiệm vụ này
		if Game.q_is_active("hunt"):
			pl["hunt_wait"] = float(pl.get("hunt_wait", 0.0)) + dt
			if pl["hunt_wait"] > 45.0:
				Game.q_add("hunt", 1.0)
	_animate(dt)

func _update_player(dt: float) -> void:
	pl["inv"] = maxf(0.0, pl["inv"] - dt)
	pl["act"] = maxf(0.0, pl["act"] - .9 * dt)
	view_yaw += ((1.0 if Input.is_action_pressed("look_l") else 0.0) - (1.0 if Input.is_action_pressed("look_r") else 0.0)) * 1.9 * dt
	view_pitch = clampf(view_pitch + ((1.0 if Input.is_action_pressed("look_u") else 0.0) - (1.0 if Input.is_action_pressed("look_d") else 0.0)) * 1.3 * dt, -1.3, 1.3)
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
	var act_hit := Input.is_action_just_pressed("act")
	prompt = ""
	if stage == "egg":
		var hw := Vector3(want.x, 0, want.z)
		var drift := Vector3(sin(t * .21) * .06, 0, cos(t * .17) * .06)
		p_vel = p_vel.lerp(hw.normalized() * .55 if hw.length() > .01 else Vector3.ZERO, 1.0 - exp(-3.0 * dt))
		p_pos += (p_vel + drift) * dt
		raft_c += drift * dt
		p_pos.x = clampf(p_pos.x, -W / 2 + .5, W / 2 - .5)
		p_pos.z = clampf(p_pos.z, -D / 2 + .5, D / 2 - .5)
		p_pos.y = surf + sin(t * 1.3 + 1.0) * .006
		var sh := shaded(p_pos)
		var rate: float = float(site["light"]) * 14.0 * (1.4 if weather == "drought" else (.6 if weather == "rain" else 1.0))
		pl["heat"] = clampf(pl["heat"] + (-6.0 if sh else rate) * dt, 0.0, 100.0)
		pl["hidden"] = false
		if pl["heat"] >= 100.0:
			kill("Trứng bị nắng nóng làm hỏng")
			return
		pl["et"] += dt
		Game.q_add("stay", dt)
		if sh:
			Game.q_add("shade", dt)
		if pl["heat"] < 85.0:
			Game.q_add("embryo", dt / 6.0 * 100.0)
		if Game.q_is_active("hatch") or Game.q_all_done():
			pl["hatch_t"] += dt
			if pl["hatch_t"] > .9:
				Game.q_add("hatch", 1.0)
				Sfx.beep(600, .2, "sine", .07, 400)
				_fx_hatch()
				advance.emit("larva")
				return
		var qa := Game.q_active()
		var qid: String = qa.get("id", "")
		prompt = {"stay": "WASD: dạt khỏi bè trứng nếu cần — tránh cá và sinh vật mặt nước", "shade": "Trôi vào bóng lá (WASD) để trứng không bị khô", "embryo": "Phôi đang phát triển — giữ trứng mát và an toàn", "hatch": "Sắp nở!"}.get(qid, "")
		return
	var pupa := stage == "pupa"
	var max_sp: float = (1.1 if pupa else 3.0) * (1.0 + .08 * Game.tv("mob"))
	if not (pupa and pl["anchored"]):
		if not pupa and act_hit and pl["dash_cd"] <= 0.0:
			var dir := want.normalized() if wants else (-node_player.global_transform.basis.z)
			p_vel = dir * 6.5
			pl["dash_cd"] = 1.1
			pl["dash_t"] = .35
			pl["act"] = 1.0
			Sfx.beep(380, .12, "triangle", .04, 200)
		pl["dash_cd"] = maxf(0.0, pl["dash_cd"] - dt)
		pl["dash_t"] = maxf(0.0, pl["dash_t"] - dt)
		if pl["dash_t"] > 0.0:
			p_vel *= exp(-1.6 * dt)          # lướt theo đà, giảm dần
		else:
			var target := want.normalized() * max_sp if wants else Vector3.ZERO
			p_vel = p_vel.lerp(target, 1.0 - exp((-4.2 if wants else -3.0) * dt))
		var sp := p_vel.length()
		p_pos += p_vel * dt
		p_pos.x = clampf(p_pos.x, -W / 2 + .6, W / 2 - .6)
		p_pos.z = clampf(p_pos.z, -D / 2 + .6, D / 2 - .6)
		p_pos.y = clampf(p_pos.y, -depth + .3, surf - .08)
		Game.G["dist"] += sp * dt
		if not pupa:
			pl["act"] = maxf(pl["act"], sp / 3.4)
	else:
		p_vel = Vector3.ZERO
		pl["act"] = 0.0
	var spd := p_vel.length()
	pl["hidden"] = in_shelter(p_pos) and pl["act"] < .45 and spd < 1.6
	if pupa:
		var at_s: bool = p_pos.y > surf - .45
		if at_s:
			pl["o2"] = minf(100.0, pl["o2"] + 40.0 * dt)
			Game.q_add("breathe", dt)
		else:
			pl["o2"] -= 1.6 * dt
		if pl["o2"] <= 0.0:
			pl["o2"] = 0.0
			pl["hp"] -= 10.0 * dt
			if pl["hp"] <= 0.0:
				kill("Nhộng ngạt thở dưới nước")
				return
		if pl["hidden"]:
			Game.q_add("hide", dt)
		if spd < 1.0:
			Game.q_add("meta", dt / 12.0 * 100.0)
		if Game.q_is_active("emerge") and at_s and Input.is_action_pressed("act"):
			Game.q_add("emerge", dt)
			shake = maxf(shake, .05)
			_emerge_t -= dt
			if _emerge_t <= 0.0:
				_emerge_t = .22
				fxl.bubbles(p_pos, 2, .8, .2)
				fxl.ring(Vector3(p_pos.x, surf, p_pos.z), .5, 1.2)
		if Game.q_all_done():
			advance.emit("adult")
			return
		var qa2 := Game.q_active()
		prompt = {"breathe": "Nổi sát mặt nước (Space) để thở bằng ống trên đầu", "hide": "Núp trong rong, đá hoặc dưới lá nổi", "meta": "Nằm yên — bơi chậm để biến thái", "emerge": "Nổi lên mặt nước và GIỮ E để chui ra khỏi vỏ"}.get(qa2.get("id", ""), "")
		return
	if pl["hidden"]: Game.G["hidden"] += dt
	# hô hấp
	var at_surf: bool = p_pos.y > surf - .3
	if at_surf:
		if not pl["was_surf"] and pl["below_t"] >= 1.0:
			Game.q_add("breath", 1.0)
			pl["below_t"] = 0.0
		pl["was_surf"] = true
	else:
		pl["was_surf"] = false
		pl["below_t"] += dt
		if preds.is_empty() and p_pos.y < surf - 1.8:
			Game.q_add("hunt", dt)
	var drain: float = 3.5 * (1.0 + (.3 if float(site["water"]) < .5 else 0.0)) / (1.0 + .2 * Game.tv("oxy"))
	if at_surf:
		pl["o2"] = minf(100.0, pl["o2"] + 55.0 * dt)
	else:
		pl["o2"] -= drain * dt
	if pl["o2"] < 25.0: Game.G["low_o2"] += dt
	if pl["o2"] <= 0.0:
		pl["o2"] = 0.0
		pl["hp"] -= 12.0 * dt
		if pl["hp"] <= 0.0:
			kill("Ngạt thở dưới nước")
			return
	else:
		pl["hp"] = minf(pl["maxhp"], pl["hp"] + 2.0 * dt)
	# ăn
	var fee_f: float = 1.0 + .1 * Game.tv("fee")
	var sz: float = .12 + pl["growth"] * .0012
	for i in range(food.size() - 1, -1, -1):
		var f: Dictionary = food[i]
		var fd: Dictionary = FOOD[f["t"]]
		if p_pos.distance_to(f["pos"]) < sz + float(fd["r"]) + .1:
			pl["growth"] += float(fd["val"]) * 1.5 * fee_f
			Game.G["food"] += 1
			Game.q_add("eat", 1.0)
			pl["act"] = minf(1.0, pl["act"] + .35)
			(f["node"] as Node3D).queue_free()
			food.remove_at(i)
			Sfx.beep(700 + randf() * 150, .05, "sine", .03)
	pl["growth"] += 1.0 * fee_f * dt   # lăng quăng lớn nhanh: ~100 giây là đủ tới Instar IV nếu ăn đều
	# mỗi nhiệm vụ hoàn thành đẩy thanh lớn lên tới một mốc (không phải chờ đủ thức ăn)
	var gfl := 0.0
	for qd in Game.quests:
		if qd["done"]:
			gfl = maxf(gfl, float({"eat": 15.0, "breath": 30.0, "molt1": 40.0, "hunt": 60.0, "molt2": 78.0, "molt3": 90.0}.get(qd["id"], 0.0)))
	pl["growth"] = maxf(pl["growth"], gfl)
	var thr := [25.0, 50.0, 75.0]
	var molts: int = pl["molts"]
	if molts < 3:
		var qid: String = ["molt1", "molt2", "molt3"][molts]
		if pl["growth"] >= thr[molts]:
			pl["growth"] = thr[molts]
			if Game.q_is_active(qid) and not pl["molt_pending"]:
				pl["molt_pending"] = true
				hud_ref.banner("ĐẾN LÚC LỘT XÁC → INSTAR %s" % ["II", "III", "IV"][molts], "Ẩn mình trong rong, đá hoặc dưới lá nổi khoảng 3 giây")
		if pl["molt_pending"]:
			if pl["hidden"]:
				pl["molt_p"] += dt
			else:
				pl["molt_p"] = maxf(0.0, pl["molt_p"] - dt * .5)
			if pl["molt_p"] >= 3.0:
				pl["molts"] += 1
				pl["molt_p"] = 0.0
				pl["molt_pending"] = false
				pl["hp"] = pl["maxhp"]
				Game.q_add(qid, 1.0)
				_fx_molt()
				Sfx.beep(520, .25, "sine", .06, 500)
				hud_ref.banner("LỘT XÁC THÀNH CÔNG", "Lớp da cũ (xác lột) được bỏ lại và trôi đi — bạn lên Instar %s" % ["II", "III", "IV"][molts])
	pl["growth"] = minf(pl["growth"], 100.0)
	Game.q_set("grow", pl["growth"])
	if Game.q_all_done():
		_fx_molt()
		advance.emit("pupa")
	prompt = "WASD: bơi · Space/Shift: lên/xuống · E: quẫy nước · lên mặt nước để thở"
	if pl["molt_pending"]:
		prompt = "ĐANG LỘT XÁC: ẩn mình trong rong/đá/dưới lá (%d%%)" % int(pl["molt_p"] / 3.0 * 100.0)
	elif molts < 3 and pl["growth"] >= thr[molts] - .01 and not pl["molt_pending"]:
		prompt = "Đã đủ lớn để lột xác — hoàn thành nhiệm vụ hiện tại trước"


func _update_food(dt: float) -> void:
	var target := 8 + int(site["food"] * 34)
	food_t -= dt
	if food.size() < target and food_t <= 0.0:
		_spawn_food()
		food_t = .35
	for f in food:
		var p: Vector3 = f["pos"]
		var ph: float = f["ph"]
		p.x += sin(t * .7 + ph) * .18 * dt + (sin(t * 2.0 + ph) * .6 * dt if f["t"] == "micro" else 0.0)
		p.y += cos(t * .5 + ph) * .12 * dt
		p.z += sin(t * .6 + ph * 1.3) * .16 * dt
		p.x = clampf(p.x, -W / 2 + .3, W / 2 - .3)
		p.z = clampf(p.z, -D / 2 + .3, D / 2 - .3)
		p.y = clampf(p.y, -depth + .2, surf - .15)
		f["pos"] = p
		(f["node"] as Node3D).position = p

func _update_sibs(dt: float) -> void:
	for sb in sibs:
		if not sb["alive"]:
			continue
		var pos: Vector3 = sb["pos"]
		if stage == "egg":
			var off: Vector2 = sb["off"]
			pos = Vector3(raft_c.x + off.x, surf + sin(t * 1.3 + sb["ph"]) * .006, raft_c.z + off.y)
			sb["vel"] = Vector3.ZERO
			sb["act"] = 0.0
		elif stage == "pupa":
			sb["vel"] = Vector3.ZERO
			sb["act"] = 0.0
			pos.y = clampf(pos.y, -depth + .4, surf - .3)
		else:
			sb["t"] -= dt
			if sb["t"] <= 0.0:
				sb["t"] = _rnd(1.2, 3.0)
				sb["tgt"] = Vector3(_rnd(-W / 2 + 1, W / 2 - 1), _rnd(-depth + .6, surf - .4), _rnd(-D / 2 + 1, D / 2 - 1))
			var dv: Vector3 = sb["tgt"] - pos
			var l := maxf(dv.length(), .01)
			sb["vel"] = dv / l * 1.2
			pos += sb["vel"] * dt
			sb["act"] = .25
			for i in food.size():
				if food[i]["pos"].distance_to(pos) < .4:
					(food[i]["node"] as Node3D).queue_free()
					food.remove_at(i)
					break
		sb["pos"] = pos

func _dirto(a: Vector3, b: Vector3) -> Vector3:
	var d := b - a
	return d / maxf(d.length(), .001)

func _update_preds(dt: float) -> void:
	_threat_flag = false
	var T := _targets()
	var egg := stage == "egg"
	for o in preds:
		o.cd = maxf(0.0, o.cd - dt)
		match o.k:
			"fish":
				var best = null
				var bd := 1e9
				for tg in T:
					if tg["hid"]: continue
					if tg["egg"] and shaded(tg["pos"]): continue
					var dv: Vector3 = tg["pos"] - o.pos
					var d := dv.length()
					var rr := 5.9 * (.6 if tg["sp"] < .3 else 1.0)
					if d > rr: continue
					if d > 2.0 and dv.dot(o.face) < -.6: continue
					if d < bd:
						bd = d; best = tg
				if best != null and o.cd <= 0.0:
					o.st = "chase"
					if typeof(best["ref"]) == TYPE_STRING: _threat_flag = true
					var tp: Vector3 = best["pos"]
					tp.y = minf(tp.y, surf - .3)
					var dir := _dirto(o.pos, tp)
					o.pos += dir * 4.9 * dt
					o.face = Vector3(dir.x, 0, dir.z).normalized() if Vector2(dir.x, dir.z).length() > .05 else o.face
					if bd < 1.0:
						_catch(best, 55.0, "Bị cá ăn thịt")
						o.cd = 2.5
						o.st = "patrol"
				else:
					o.st = "patrol"
					if o.pos.x < -W / 2 + 2.0: o.face = Vector3(1, 0, 0)
					if o.pos.x > W / 2 - 2.0: o.face = Vector3(-1, 0, 0)
					o.pos += o.face * 2.0 * dt
					var my := surf - depth * .45 + sin(t * .6 + o.ph) * 1.4
					o.pos.y += (my - o.pos.y) * minf(1.0, dt)
					o.pos.z += sin(t * .35 + o.ph) * .6 * dt
				o.pos.y = clampf(o.pos.y, -depth + .6, surf - .4)
				o.pos.z = clampf(o.pos.z, -D / 2 + 1.5, D / 2 - 1.5)
			"beetle":
				var bt = null
				var bd2 := 1e9
				if not egg:
					for tg in T:
						var d2: float = (tg["pos"] - o.pos).length()
						var rr2 := 7.0 * (.5 if tg["hid"] else 1.0)
						if d2 < rr2 and (tg["sp"] > 1.0 or tg["act"] > .35) and d2 < bd2:
							bd2 = d2; bt = tg
				if bt != null and o.cd <= 0.0:
					o.st = "chase"
					if typeof(bt["ref"]) == TYPE_STRING: _threat_flag = true
					var dir2 := _dirto(o.pos, bt["pos"])
					o.pos += dir2 * 4.1 * dt
					o.face = dir2
					if bd2 < .7:
						_catch(bt, 40.0, "Bị bọ nước cắn")
						o.cd = 2.2
						o.tgt = Vector3(_rnd(-W / 2 + 2, W / 2 - 2), _rnd(-depth + 1, surf - 1), _rnd(-D / 2 + 2, D / 2 - 2))
				else:
					o.st = "patrol"
					o.t -= dt
					if o.t <= 0.0:
						o.t = _rnd(2, 4)
						o.tgt = Vector3(_rnd(-W / 2 + 2, W / 2 - 2), _rnd(-depth + 1, surf - 1), _rnd(-D / 2 + 2, D / 2 - 2))
					var dir3 := _dirto(o.pos, o.tgt)
					o.pos += dir3 * 1.5 * dt
					o.face = dir3
				o.pos.y = clampf(o.pos.y, -depth + .5, surf - .4)
			"nymph":
				if o.st == "patrol" or o.st == "ambush":
					o.st = "ambush"
					o.pos = o.pos.lerp(o.home, minf(1.0, dt * 2.0))
					if o.cd <= 0.0 and not egg:
						for tg in T:
							var d3: float = (tg["pos"] - o.pos).length()
							if d3 < 2.8 and ((tg["sp"] > .4 and not tg["hid"]) or d3 < 1.5):
								o.st = "wind"; o.t = .5; o.tgt = tg["pos"]
								break
				elif o.st == "wind":
					o.t -= dt
					o.face = _dirto(o.pos, o.tgt)
					if o.t <= 0.0:
						o.st = "lunge"; o.t = .35
						o.vel = _dirto(o.pos, o.tgt) * 12.0
						Sfx.beep(150, .2, "saw", .06, 100)
				elif o.st == "lunge":
					o.t -= dt
					o.pos += o.vel * dt
					for tg in T:
						if (tg["pos"] - o.pos).length() < .9:
							_catch(tg, 80.0, "Bị ấu trùng chuồn chuồn vồ")
							o.t = 0.0
							break
					if o.t <= 0.0:
						o.st = "recover"; o.t = 2.4; o.cd = 2.4
				elif o.st == "recover":
					o.t -= dt
					o.pos += _dirto(o.pos, o.home) * 2.0 * dt
					if o.t <= 0.0: o.st = "ambush"
				o.pos.x = clampf(o.pos.x, -W / 2 + .5, W / 2 - .5)
				o.pos.y = clampf(o.pos.y, -depth + .3, surf - .4)
				o.pos.z = clampf(o.pos.z, -D / 2 + .5, D / 2 - .5)
			"strider":
				o.pos.y = surf
				if o.st == "patrol":
					if o.pos.x < -W / 2 + 1.5: o.face = Vector3(1, 0, 0)
					if o.pos.x > W / 2 - 1.5: o.face = Vector3(-1, 0, 0)
					o.pos += o.face * 1.3 * dt
					if o.cd <= 0.0:
						for tg in T:
							var dx := Vector2(tg["pos"].x - o.pos.x, tg["pos"].z - o.pos.z).length()
							if tg["egg"] and shaded(tg["pos"]): continue
							if tg["pos"].y > surf - .9 and dx < (1.3 if tg["egg"] else 3.6):
								o.st = "wind"; o.t = .45; o.tgt = tg["pos"]
								break
				elif o.st == "wind":
					o.t -= dt
					var dd := Vector3(o.tgt.x - o.pos.x, 0, o.tgt.z - o.pos.z)
					if dd.length() > .05:
						o.pos += dd.normalized() * 2.0 * dt
						o.face = dd.normalized()
					if o.t <= 0.0:
						o.st = "stab"; o.t = .25
						Sfx.beep(500, .08, "square", .04, -200)
						for tg in T:
							var dx2 := Vector2(tg["pos"].x - o.pos.x, tg["pos"].z - o.pos.z).length()
							if dx2 < (.7 if tg["egg"] else 1.0) and tg["pos"].y > surf - 1.7 and not (tg["egg"] and shaded(tg["pos"])):
								_catch(tg, 35.0, "Bị sinh vật mặt nước phục kích")
				elif o.st == "stab":
					o.t -= dt
					if o.t <= 0.0:
						o.st = "patrol"; o.cd = 2.5
		if (o.k == "nymph" or o.k == "strider") and (o.st == "wind" or o.st == "lunge") and (p_pos - o.pos).length() < 4.0:
			_threat_flag = true

# ═════════════ hình ảnh động, môi trường, camera ═════════════
func _update_env(dt: float) -> void:
	water_plane.position = Vector3(0, surf, 0)
	var under := cam.global_position.y < surf
	water_mat.set_shader_parameter("under", 1.0 if under else 0.0)
	env.volumetric_fog_density = (.035 + float(pc["dark"]) * .02) if under else .0
	for c in caustics:
		c.rotation.y += dt * (.05 if c.get_meta("dir") > 0 else -.04)
	var tint: Color = pc["tint"]
	var dark: float = pc["dark"]
	if under:
		env.fog_light_color = tint.lightened(.12).darkened(dark * .6)
		env.fog_density = .06 + dark * .05
		env.ambient_light_energy = .95 * (1.0 - dark * .5)
		env.background_energy_multiplier = .5
	else:
		env.fog_light_color = Color(.7, .8, .9)
		env.fog_density = .004
		env.ambient_light_energy = 1.0
		env.background_energy_multiplier = 1.0
	for l in leaves:
		(l["node"] as Node3D).position.y = surf + .02
	bubbles.position.y = -depth

func _animate(dt: float) -> void:
	_dt = dt
	# người chơi
	if node_player != null:
		node_player.position = p_pos
		if stage == "egg":
			var m: MeshInstance3D = node_player.get_node("m")
			var h: float = pl["heat"] / 100.0
			(m.material_override as StandardMaterial3D).albedo_color = Color(.12 + h * .55, .085 + h * .08, .05)
			var halo := node_player.get_node_or_null("halo") as Node3D
			if halo != null:
				halo.scale = Vector3(1.0 + .12 * sin(t * 4.0), .08, 1.0 + .12 * sin(t * 4.0))
		elif stage == "larva":
			if p_vel.length() > .15:
				_orient(node_player, p_vel)
			_wiggle_larva(node_player, t, 1.0 + pl["act"] * 1.2, .9 if pl["dash_t"] > 0.0 else 0.0)
		else:
			if not pl["anchored"] and p_vel.length() > .1:
				_orient(node_player, p_vel)
		node_player.visible = true
		var hid: bool = pl["hidden"]
		node_player.scale = Vector3.ONE * (1.0 + (pl["growth"] * .005 if stage == "larva" else 0.0))
		if pl["inv"] > 0.0 and int(t * 14) % 2 == 0:
			node_player.visible = false
	# anh chị em
	for sb in sibs:
		var n: Node3D = sb["node"]
		if n == null: continue
		n.visible = sb["alive"]
		n.position = sb["pos"]
		if stage == "larva" and (sb["vel"] as Vector3).length() > .1:
			_orient(n, sb["vel"])
			_wiggle_larva(n, t + sb["ph"], 1.0)
	# kẻ săn mồi
	for o in preds:
		o.node.position = o.pos
		match o.k:
			"fish":
				o.node.rotation.y = atan2(o.face.x, o.face.z)
				o.node.rotation.y = atan2(-o.face.x, -o.face.z) if false else o.node.rotation.y
			"beetle":
				_orient(o.node, o.face)
				for i in o.legs.size():
					(o.legs[i] as Node3D).rotation.x = sin(t * 12.0 + i) * .5
			"nymph":
				if o.face.length() > .01:
					_orient(o.node, o.face if o.st != "ambush" and o.st != "recover" else Vector3(1, 0, 0))
				var open := 6.0 if (o.st == "wind" or o.st == "lunge") else 80.0
				for i in o.legs.size():
					var sx := -1.0 if i == 0 else 1.0
					(o.legs[i] as Node3D).rotation_degrees = Vector3(open, 0, sx * 12.0)
			"strider":
				o.node.rotation.y = atan2(o.face.x, o.face.z) + PI
	_cam_update(false, dt)

func _cam_update(snap: bool, dt: float) -> void:
	var k := 1.0 if snap else 1.0 - exp(-28.0 * dt)
	_sy = view_yaw if snap else lerp_angle(_sy, view_yaw, k)
	_sp = view_pitch if snap else lerpf(_sp, view_pitch, k)
	_ps = p_pos if snap else _ps.lerp(p_pos, 1.0 - exp(-18.0 * dt))
	var fw := Vector3(-sin(_sy) * cos(_sp), sin(_sp), -cos(_sy) * cos(_sp))
	var dist3 := 2.0 if stage == "larva" else (1.8 if stage == "pupa" else 1.5)
	if debug_cam_dist > 0.0: dist3 = debug_cam_dist
	var c := _ps - fw * dist3 + Vector3(0, .12, 0)
	c.x = clampf(c.x, -W / 2 + .3, W / 2 - .3)
	c.z = clampf(c.z, -D / 2 + .3, D / 2 - .3)
	if stage == "egg":
		c.y = clampf(c.y, surf + .2, surf + 4.0)
	else:
		c.y = clampf(c.y, -depth + .2, surf - .15)
	if shake > 0.0:
		c += Vector3(randf_range(-.02, .02), randf_range(-.02, .02), 0)
	cam.global_position = c
	cam.look_at(_ps + fw * .4, Vector3.UP)

func _fx_update(dt: float) -> void:
	fxl.surf_y = surf
	fxl.update(dt)

## Trứng nở: nắp ở đầu dưới bật ra, ấu trùng chui xuống nước, vỏ rỗng còn nổi trên mặt.
func _fx_hatch() -> void:
	if node_player != null:
		fxl.ghost(node_player, 45.0, "float")
	for sb in sibs:
		var n: Node3D = sb["node"]
		if n != null and sb["alive"]:
			fxl.ghost(n, 45.0, "float")
	var cap := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = .045
	hm.height = .045
	hm.is_hemisphere = true
	cap.mesh = hm
	dynroot.add_child(cap)
	cap.position = p_pos + Vector3(0, -.09, 0)
	cap.rotation_degrees.x = 180.0
	fxl.ghost(cap, 9.0, "drift", Color(.35, .28, .2, .8))
	cap.queue_free()
	fxl.ring(Vector3(p_pos.x, surf, p_pos.z), 1.4, 2.2)
	fxl.ring(Vector3(p_pos.x, surf, p_pos.z), 2.6, 3.0, .3)
	fxl.bubbles(Vector3(p_pos.x, surf - .3, p_pos.z), 16, 1.0, .5)
	shake = .15
	if hud_ref != null:
		hud_ref.flash(Color(1, 1, 1), .35)

## Lột xác / hóa nhộng: bỏ lại lớp da cũ (xác lột) trôi lơ lửng.
func _fx_molt() -> void:
	if node_player == null:
		return
	var g := fxl.ghost(node_player, 26.0, "drift", Color(.95, .92, .8, .5))
	g.scale = node_player.scale
	fxl.bubbles(p_pos, 20, 1.0, .5)
	shake = .25
	if hud_ref != null:
		hud_ref.flash(Color(1, 1, 1), .4)

# ═════════════ HUD ═════════════
func draw_hud(hud: Node) -> void:
	hud_ref = hud
	var Wd := 1280.0
	var Ht := 720.0
	var L := Game.L
	# chấm hướng bơi (giống chấm tâm của muỗi): điểm phía trước theo hướng nhìn/di chuyển
	if (stage == "larva" or stage == "pupa") and cam != null:
		var tp := p_pos + fwd3() * 4.0
		if not cam.is_position_behind(tp):
			var dot := cam.unproject_position(tp)
			hud.circle(dot, 13.0, Color(1, 1, 1, .16))
			hud.circle(dot, 5.0, Color(1, 1, 1, .95))
	hud.text("THẾ HỆ %02d  ·  NGÀY %d  ·  %s" % [L["gen"], Game.day_no(), Game.STAGE_NAMES[stage]], Vector2(20, 24), 19)
	var y := 50.0
	if stage == "egg":
		var h: float = pl["heat"]
		hud.bar(Vector2(20, y), 300, 20, h / 100.0, Color(.91, .27, .17) if h > 70 else Color(1, .7, .28), "Nhiệt")
		y += 28
		hud.bar(Vector2(20, y), 300, 20, pl["et"] / EGG_TIME, Color(.43, .61, .44), "Sắp nở")
	elif stage == "larva":
		hud.bar(Vector2(20, y), 300, 20, pl["hp"] / pl["maxhp"], Color(.66, .36, .26), "Máu")
		y += 28
		hud.bar(Vector2(20, y), 300, 20, pl["o2"] / 100.0, Color(1, .42, .24) if pl["o2"] < 25 else Color(.35, .7, .68), "Oxy — lên mặt nước để thở")
		y += 28
		hud.bar(Vector2(20, y), 300, 20, pl["growth"] / 100.0, Color(.43, .61, .44), "Lớn lên — Instar %s" % ["I", "II", "III", "IV"][int(pl["molts"])])
		y += 28
		hud.bar(Vector2(20, y), 300, 20, 1.0 - pl["dash_cd"] / 1.1, Color(.89, .82, .49), "Quẫy (E)")
	else:
		hud.bar(Vector2(20, y), 300, 20, pl["hp"] / pl["maxhp"], Color(.66, .36, .26), "Máu")
		y += 28
		hud.bar(Vector2(20, y), 300, 20, pl["o2"] / 100.0, Color(1, .42, .24) if pl["o2"] < 25 else Color(.35, .7, .68), "Oxy — nổi lên mặt nước để thở")
	hud.text("Mục tiêu: sống sót %d/10 thế hệ" % L["gen"], Vector2(Wd - 20, 48), 16, Color(.8, .95, .82), 2)
	hud.text("Kỷ lục: %d thế hệ  ·  M: âm thanh  ·  P: tạm dừng" % Game.best, Vector2(Wd - 20, 70), 14, Color(.62, .86, .8), 2)
	var site_name: String = site["name"]
	hud.text(site_name, Vector2(Wd / 2, 24), 20, Color(.8, .95, 1), 1)
	if weather == "drought": hud.text("Hạn hán: mực nước đang hạ", Vector2(Wd / 2, 50), 16, Color(1, .91, .66), 1)
	if weather == "rain": hud.text("Mưa: mực nước dâng", Vector2(Wd / 2, 50), 16, Color(.85, .93, 1), 1)
	if draining: hud.text("NƯỚC ĐANG BỊ ĐỔ ĐI!", Vector2(Wd / 2, 90), 34, Color(1, .32, .32), 1)
	if pl.get("hidden", false) and stage != "egg":
		hud.text("đang ẩn nấp", Vector2(Wd / 2, Ht - 110), 18, Color(.8, 1, .9), 1)
	# cảnh báo kẻ săn mồi đang đuổi
	for o in preds:
		if o.st == "chase" or o.st == "wind":
			if not cam.is_position_behind(o.pos):
				var s := cam.unproject_position(o.pos)
				hud.text("!!" if o.st == "wind" else "!", s + Vector2(0, -40), 34, Color(1, .3, .3), 1)
	hud.draw_quests(190.0)
	hud.text(prompt, Vector2(Wd / 2, Ht - 40), 20, Color.WHITE, 1)
	if pl.get("molt_pending", false):
		hud.bar(Vector2(Wd / 2 - 160, Ht - 80), 320, 14, pl["molt_p"] / 3.0, Color(.85, .7, 1), "Lột xác")
