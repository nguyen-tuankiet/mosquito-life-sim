class_name Bio
extends RefCounted
## Dựng sinh vật bằng code: thân "loft" chia đốt trong mờ, lông tơ, mắt bóng, chân khớp, cánh có gân.
## Quy ước: đầu hướng -Z (khớp với Node3D.look_at), thân kéo về +Z.

static var _sh_skin: Shader
static var _sh_hair: Shader
static var _sh_wing: Shader
static var _noise: Texture2D
static var _cache: Dictionary = {}

static func skin_shader() -> Shader:
	if _sh_skin == null: _sh_skin = load("res://shaders/bio.gdshader")
	return _sh_skin

static func hair_shader() -> Shader:
	if _sh_hair == null: _sh_hair = load("res://shaders/hair.gdshader")
	return _sh_hair

static func wing_shader() -> Shader:
	if _sh_wing == null: _sh_wing = load("res://shaders/wing.gdshader")
	return _sh_wing

static func noise() -> Texture2D:
	if _noise == null:
		var fn := FastNoiseLite.new()
		fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		fn.frequency = 0.05
		fn.fractal_octaves = 4
		var t := NoiseTexture2D.new()
		t.noise = fn
		t.seamless = true
		t.width = 256
		t.height = 256
		_noise = t
	return _noise

static func skin_mat(key: String, base: Color, core: Color, band: Color, tip: Color, body_len: float, segs: float, alpha_min: float = .62, spec: float = .7, rough: float = .3) -> ShaderMaterial:
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = skin_shader()
	m.set_shader_parameter("base_col", base)
	m.set_shader_parameter("core_col", core)
	m.set_shader_parameter("band_col", band)
	m.set_shader_parameter("tip_col", tip)
	m.set_shader_parameter("body_len", body_len)
	m.set_shader_parameter("segs", segs)
	m.set_shader_parameter("spec", spec)
	m.set_shader_parameter("rough", rough)
	m.set_shader_parameter("noise_tex", noise())
	_cache[key] = m
	return m

static func hair_mat(body_len: float, col: Color = Color(.16, .12, .08, .75)) -> ShaderMaterial:
	var key := "hair|%s|%s" % [body_len, col]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = hair_shader()
	m.set_shader_parameter("body_len", body_len)
	m.set_shader_parameter("col", col)
	_cache[key] = m
	return m

static func std_mat(c: Color, rough: float = .5, metal: float = 0.0, spec: float = .5, emit: float = 0.0) -> StandardMaterial3D:
	var key := "std|%s|%s|%s|%s|%s" % [c, rough, metal, spec, emit]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	m.metallic_specular = spec
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cache[key] = m
	return m

# ───────── loft: ống dọc theo đường xương sống ─────────
static func loft(spine: PackedVector3Array, radii: PackedFloat32Array, vcoord: PackedFloat32Array, sides: int, ell: Vector2 = Vector2.ONE, into: ArrayMesh = null) -> ArrayMesh:
	var n := spine.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prev_n := Vector3.UP
	var tans: Array = []
	for i in n:
		var a: Vector3 = spine[max(i - 1, 0)]
		var b: Vector3 = spine[min(i + 1, n - 1)]
		tans.append((b - a).normalized())
	if absf((tans[0] as Vector3).dot(Vector3.UP)) > .95:
		prev_n = Vector3.RIGHT
	for i in n:
		var t: Vector3 = tans[i]
		var nn := (prev_n - t * prev_n.dot(t)).normalized()
		prev_n = nn
		var bb := t.cross(nn).normalized()
		for j in sides + 1:
			var th := float(j) / sides * TAU
			var off := (nn * cos(th) * ell.x + bb * sin(th) * ell.y) * radii[i]
			st.set_uv(Vector2(float(j) / sides, vcoord[i]))
			st.add_vertex(spine[i] + off)
	for i in n - 1:
		for j in sides:
			var a2 := i * (sides + 1) + j
			var b2 := a2 + 1
			var c2 := a2 + sides + 1
			var d2 := c2 + 1
			st.add_index(a2); st.add_index(c2); st.add_index(b2)
			st.add_index(b2); st.add_index(c2); st.add_index(d2)
	st.generate_normals()
	return st.commit(into)

static func _sm(a: float, b: float, x: float) -> float:
	return smoothstep(a, b, x)

# ───────── LĂNG QUĂNG ─────────
const LARVA_L := 2.4
const LARVA_SEGS := 8.0

static func larva_radius(u: float) -> float:
	var e := 0.0
	if u < .14:
		e = lerpf(.30, .47, sin(clampf(u / .14, 0.0, 1.0) * PI * .5))
	elif u < .31:
		var t := (u - .14) / .17
		e = .47 - .14 * (1.0 - cos(PI * t)) * .5
	else:
		e = lerpf(.33, .17, (u - .31) / .69)
	if u >= .31:
		var k := (u - .31) / .69 * LARVA_SEGS
		var f := absf(sin(PI * k))
		e *= .86 + .14 * pow(f, .4)
	var tail := clampf((1.0 - u) / .035, 0.0, 1.0)
	e *= .15 + .85 * sqrt(tail)
	return e

static func larva_body_mesh() -> ArrayMesh:
	if _cache.has("larva_mesh"):
		return _cache["larva_mesh"]
	var n := 150
	var spine := PackedVector3Array()
	var rad := PackedFloat32Array()
	var vc := PackedFloat32Array()
	for i in n:
		var u := float(i) / (n - 1)
		spine.append(Vector3(0, 0, u * LARVA_L))
		rad.append(larva_radius(u))
		vc.append((u - .31) / .69)
	var m := loft(spine, rad, vc, 28, Vector2(1.08, .92))
	# ống thở: phần cuối thân vươn lên và hơi ra sau
	var sp2 := PackedVector3Array()
	var r2 := PackedFloat32Array()
	var v2 := PackedFloat32Array()
	var a := deg_to_rad(38.0)
	for i in 14:
		var t := float(i) / 13.0
		sp2.append(Vector3(0, sin(a) * .62 * t, LARVA_L * 1.002 + cos(a) * .62 * t * .5))
		r2.append(lerpf(.075, .05, t) * (1.0 - .35 * smoothstep(.85, 1.0, t)))
		v2.append(2.0 + t)
	loft(sp2, r2, v2, 10, Vector2.ONE, m)
	_cache["larva_mesh"] = m
	return m

static func _hair_strip(st: SurfaceTool, p0: Vector3, dir: Vector3, length: float, curve: Vector3, w: float) -> void:
	var p1 := p0 + dir * length * .5 + curve * .3
	var p2 := p0 + dir * length + curve
	var side := dir.cross(Vector3.UP).normalized() * w
	if side.length() < .0001:
		side = Vector3.RIGHT * w
	var pts := [p0, p1, p2]
	var ws := [1.0, .6, .1]
	for i in 2:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var wa: float = ws[i]
		var wb: float = ws[i + 1]
		st.set_uv(Vector2(0, float(i) / 2.0)); st.add_vertex(a - side * wa)
		st.set_uv(Vector2(1, float(i) / 2.0)); st.add_vertex(a + side * wa)
		st.set_uv(Vector2(0, float(i + 1) / 2.0)); st.add_vertex(b - side * wb)
		st.set_uv(Vector2(1, float(i) / 2.0)); st.add_vertex(a + side * wa)
		st.set_uv(Vector2(1, float(i + 1) / 2.0)); st.add_vertex(b + side * wb)
		st.set_uv(Vector2(0, float(i + 1) / 2.0)); st.add_vertex(b - side * wb)

static func larva_hair_mesh() -> ArrayMesh:
	if _cache.has("larva_hair"):
		return _cache["larva_hair"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# búi lông ở các đốt bụng
	for k in range(0, 9):
		var u := .31 + .69 * float(k) / LARVA_SEGS
		if k == 0: u = .17
		var r := larva_radius(u)
		var z := u * LARVA_L
		for side in [-1.0, 1.0]:
			var cnt := 7 if k > 0 else 5
			for h in cnt:
				var ang := deg_to_rad(rng.randf_range(-35, 35)) + deg_to_rad(8.0 * side)
				var dir := Vector3(side * cos(ang), sin(ang) * .7, rng.randf_range(.15, .75)).normalized()
				var base := Vector3(side * r * .95, rng.randf_range(-.25, .25) * r, z + rng.randf_range(-.04, .04))
				_hair_strip(st, base, dir, rng.randf_range(.35, .75) * (1.0 - u * .3), Vector3(0, rng.randf_range(-.08, .1), .08), .013)
		# lông mảnh phía lưng
		for h in 3:
			var dir2 := Vector3(rng.randf_range(-.3, .3), 1.0, rng.randf_range(.1, .6)).normalized()
			_hair_strip(st, Vector3(rng.randf_range(-.1, .1), r * .85, z), dir2, rng.randf_range(.22, .4), Vector3(0, 0, .1), .009)
	# chùm lông ở đuôi
	for h in 7:
		var dir3 := Vector3(rng.randf_range(-.8, .8), rng.randf_range(-.6, .5), 1.0).normalized()
		_hair_strip(st, Vector3(0, 0, LARVA_L * .985), dir3, rng.randf_range(.4, .7), Vector3(0, -.05, .08), .014)
	var m := st.commit()
	_cache["larva_hair"] = m
	return m

static func make_larva(variant: int = 0, tint_in: Color = Color.WHITE) -> Node3D:
	var tint := Color(.66, .56, .32).lerp(Color(.55, .55, .36), float(variant) * .0)
	var root := Node3D.new()
	var inner := Node3D.new()
	root.add_child(inner)
	inner.scale = Vector3.ONE * .30
	inner.position = Vector3(0, 0, .0)
	var body := MeshInstance3D.new()
	body.mesh = larva_body_mesh()
	body.material_override = skin_mat("larva_%s" % tint, tint, Color(.25, .15, .06), Color(.33, .24, .11), Color(.42, .27, .12), LARVA_L, LARVA_SEGS, .58, .42, .42)
	inner.add_child(body)
	var hair := MeshInstance3D.new()
	hair.mesh = larva_hair_mesh()
	hair.material_override = hair_mat(LARVA_L)
	hair.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inner.add_child(hair)
	var phase := randf() * 6.0
	for mi in [body, hair]:
		(mi as MeshInstance3D).set_instance_shader_parameter("t_off", phase)
		(mi as MeshInstance3D).set_instance_shader_parameter("wig_amp", .1)
	# đầu
	var head_mat := skin_mat("larva_head", Color(.55, .40, .21), Color(.22, .14, .07), Color(.3, .2, .1), Color(.3, .2, .1), LARVA_L, 1.0, .92, .5, .35)
	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = .32
	hs.height = .64
	hs.radial_segments = 32
	hs.rings = 16
	head.mesh = hs
	head.material_override = head_mat
	head.scale = Vector3(1.0, .88, 1.08)
	head.position = Vector3(0, -.02, -.14)
	head.set_instance_shader_parameter("wig_amp", 0.0)
	inner.add_child(head)
	var eye_mat := std_mat(Color(.03, .02, .02), .06, 0.0, 1.0)
	for sx in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = .105
		es.height = .21
		eye.mesh = es
		eye.material_override = eye_mat
		eye.position = Vector3(sx * .19, .1, -.33)
		inner.add_child(eye)
		var hl := MeshInstance3D.new()
		var hsm := SphereMesh.new()
		hsm.radius = .022
		hsm.height = .044
		hl.mesh = hsm
		hl.material_override = std_mat(Color.WHITE, .1, 0.0, 1.0, 2.0)
		hl.position = Vector3(sx * .17, .14, -.42)
		inner.add_child(hl)
		# râu
		var an := MeshInstance3D.new()
		var ac := CylinderMesh.new()
		ac.top_radius = .006
		ac.bottom_radius = .02
		ac.height = .34
		an.mesh = ac
		an.material_override = std_mat(Color(.25, .17, .09), .6)
		an.position = Vector3(sx * .13, .02, -.52)
		an.rotation_degrees = Vector3(-72, 0, sx * -14)
		inner.add_child(an)
	# bàn chải miệng
	var brush_mat := std_mat(Color(.35, .24, .12), .8)
	for sx in [-1.0, 1.0]:
		for k in 11:
			var br := MeshInstance3D.new()
			var bc := CylinderMesh.new()
			bc.top_radius = .002
			bc.bottom_radius = .014
			bc.height = .24
			br.mesh = bc
			br.material_override = brush_mat
			var spread := (float(k) - 5.0) / 5.0
			br.position = Vector3(sx * (.07 + spread * .02), -.13 + spread * .03, -.43)
			br.rotation_degrees = Vector3(-82 + abs(spread) * 15, spread * 20 * sx, spread * 28)
			inner.add_child(br)
	return root

static func set_larva_motion(n: Node3D, amp: float, speed: float, curl: float) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.has_meta("fixed"):
			continue
		m.set_instance_shader_parameter("wig_amp", amp)
		m.set_instance_shader_parameter("wig_speed", speed)
		m.set_instance_shader_parameter("curl", curl)

# ───────── NHỘNG ─────────
static func make_pupa() -> Node3D:
	var root := Node3D.new()
	var inner := Node3D.new()
	root.add_child(inner)
	inner.scale = Vector3.ONE * .5
	var ctl := [Vector3(0, .5, -.15), Vector3(0, .25, -.22), Vector3(0, -.05, -.15), Vector3(0, -.38, -.02), Vector3(0, -.6, .22),
		Vector3(0, -.68, .55), Vector3(0, -.56, .86), Vector3(0, -.32, 1.08), Vector3(0, -.05, 1.15)]
	var rr := [.2, .46, .54, .46, .31, .25, .2, .15, .06]
	var n := 90
	var spine := PackedVector3Array()
	var rad := PackedFloat32Array()
	var vc := PackedFloat32Array()
	for i in n:
		var f := float(i) / (n - 1) * (ctl.size() - 1)
		var i0 := clampi(int(floor(f)), 0, ctl.size() - 2)
		var t := f - i0
		var p0: Vector3 = ctl[max(i0 - 1, 0)]
		var p1: Vector3 = ctl[i0]
		var p2: Vector3 = ctl[i0 + 1]
		var p3: Vector3 = ctl[min(i0 + 2, ctl.size() - 1)]
		spine.append(p1.cubic_interpolate(p2, p0, p3, t))
		rad.append(lerpf(rr[i0], rr[i0 + 1], smoothstep(0.0, 1.0, t)))
		vc.append(-1.0 if i < n * .45 else (float(i) / n - .45) / .55)
	var mesh := loft(spine, rad, vc, 28, Vector2(1.0, 1.0))
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.material_override = skin_mat("pupa", Color(.55, .40, .22), Color(.26, .16, .08), Color(.34, .24, .12), Color(.34, .22, .12), 99.0, 6.0, .86, .35, .5)
	body.set_instance_shader_parameter("wig_amp", 0.0)
	inner.add_child(body)
	# mắt và cánh bên trong lớp vỏ nhộng
	var eye_mat := std_mat(Color(.05, .03, .03), .2, 0.0, .9)
	for sx in [-1.0, 1.0]:
		var e := Assets.sphere_mesh(.1, eye_mat)
		e.position = Vector3(sx * .24, .12, -.38)
		inner.add_child(e)
		var tr := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = .07
		tc.bottom_radius = .035
		tc.height = .5
		tr.mesh = tc
		tr.material_override = skin_mat("pupa_trumpet", Color(.42, .30, .17), Color(.2, .12, .06), Color(.3, .2, .1), Color(.3, .2, .1), 99.0, 1.0, .9, .5, .4)
		tr.set_instance_shader_parameter("wig_amp", 0.0)
		tr.position = Vector3(sx * .2, .62, -.18)
		tr.rotation_degrees = Vector3(-8, 0, sx * -14)
		inner.add_child(tr)
	# mái chèo ở đuôi
	for sx in [-1.0, 1.0]:
		var pd := Assets.sphere_mesh(.12, std_mat(Color(.5, .38, .22, .8), .4), Vector3(.25, 1.0, 1.7))
		pd.position = Vector3(sx * .09, -.02, 1.22)
		pd.rotation_degrees = Vector3(0, sx * 14, 0)
		inner.add_child(pd)
	return root

# ───────── MUỖI TRƯỞNG THÀNH ─────────
static func make_mosquito(sex: String) -> Node3D:
	var g := Node3D.new()
	g.scale = Vector3.ONE * .62
	var dark := Color(.12, .09, .07)
	# ngực gồ
	var thorax_mat := skin_mat("mq_thorax", Color(.20, .15, .11), Color(.08, .06, .04), Color(.55, .5, .42), Color(.1, .08, .06), 99.0, 1.0, 1.0, .5, .55)
	var th := MeshInstance3D.new()
	var ths := SphereMesh.new()
	ths.radius = .017
	ths.height = .034
	th.mesh = ths
	th.material_override = thorax_mat
	th.scale = Vector3(1, .95, 1.35)
	th.set_instance_shader_parameter("wig_amp", 0.0)
	g.add_child(th)
	var hump := Assets.sphere_mesh(.014, std_mat(Color(.45, .38, .28), .8), Vector3(.7, .55, 1.1))
	hump.position = Vector3(0, .008, -.003)
	g.add_child(hump)
	# đầu, mắt kép
	var head := Assets.sphere_mesh(.0105, std_mat(dark, .7))
	head.position = Vector3(0, .002, .03)
	g.add_child(head)
	for sx in [-1.0, 1.0]:
		var eye := Assets.sphere_mesh(.0072, std_mat(Color(.05, .03, .03), .08, 0.0, 1.0))
		eye.position = Vector3(sx * .0078, .003, .034)
		g.add_child(eye)
	# vòi
	var prob := Assets.cyl_mesh(.0016, .0022, .04 if sex == "F" else .02, std_mat(Color(.1, .08, .06), .5), 6)
	prob.rotation_degrees.x = 90
	prob.position = Vector3(0, -.002, .055 if sex == "F" else .047)
	g.add_child(prob)
	if sex == "M":
		for sx in [-1.0, 1.0]:
			var an := Assets.cyl_mesh(.0008, .004, .034, std_mat(Color(.5, .45, .38), .9), 6)
			an.position = Vector3(sx * .007, .012, .045)
			an.rotation_degrees = Vector3(52, 0, sx * 24)
			g.add_child(an)
	else:
		for sx in [-1.0, 1.0]:
			var an2 := Assets.cyl_mesh(.0005, .0012, .03, std_mat(dark, .6), 4)
			an2.position = Vector3(sx * .005, .01, .045)
			an2.rotation_degrees = Vector3(52, 0, sx * 14)
			g.add_child(an2)
	# bụng có vằn trắng
	var n := 60
	var spine := PackedVector3Array()
	var rad := PackedFloat32Array()
	var vc := PackedFloat32Array()
	var L := .075
	for i in n:
		var u := float(i) / (n - 1)
		spine.append(Vector3(0, -.002 - u * u * .012, -.014 - u * L))
		var env: float = .0125 * (sin(clampf(u, 0, 1) * PI * .85 + .35) * .85 + .15) * (1.0 - .35 * u)
		var k := u * 7.0
		env *= .9 + .1 * pow(absf(sin(PI * k)), .4)
		env *= .12 + .88 * sqrt(clampf((1.0 - u) / .05, 0.0, 1.0))
		rad.append(env)
		vc.append(u)
	var abd_mesh := loft(spine, rad, vc, 16, Vector2(1.0, .9))
	var abd := MeshInstance3D.new()
	abd.mesh = abd_mesh
	abd.name = "abd"
	abd.material_override = skin_mat("mq_abd_%s" % sex, Color(.13, .10, .08), Color(.07, .05, .04), Color(.85, .82, .74), Color(.1, .08, .06), 1.0, 7.0, 1.0, .6, .45)
	abd.set_instance_shader_parameter("wig_amp", 0.0)
	g.add_child(abd)
	# chân 3 đốt có khớp và vằn
	var leg_mat := std_mat(Color(.1, .08, .06), .55)
	var pale := std_mat(Color(.8, .78, .7), .6)
	for i in 6:
		var sx := 1.0 if i % 2 == 1 else -1.0
		var row := i / 2
		var root_p := Vector3(sx * .009, -.008, .014 - row * .013)
		var spread: float = [.9, 1.15, 1.45][row]
		var droop: float = [.7, .55, .45][row]
		var j1 := root_p + Vector3(sx * .02 * spread, .014, (0.008 - row * .01))
		var j2 := j1 + Vector3(sx * .02 * spread, -.012, (-row + 1.0) * .004 - .012)
		var j3 := j2 + Vector3(sx * .014, -.03 * droop - .008, (-row + 1.0) * .006 - .006)
		_limb(g, root_p, j1, .0012, leg_mat, pale)
		_limb(g, j1, j2, .0011, leg_mat, pale)
		_limb(g, j2, j3, .0007, leg_mat, pale)
	# cánh có gân
	var wmat := ShaderMaterial.new()
	wmat.shader = wing_shader()
	for pair in [["wl", -1.0], ["wr", 1.0]]:
		var w := Node3D.new()
		w.name = pair[0]
		w.position = Vector3(pair[1] * .009, .013, -.002)
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(.058, .017)
		pm.subdivide_width = 4
		mi.mesh = pm
		mi.material_override = wmat
		mi.position.x = pair[1] * .029
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if pair[1] < 0.0:
			mi.rotation_degrees.y = 180.0
		w.add_child(mi)
		g.add_child(w)
	return g

static func _limb(parent: Node3D, a: Vector3, b: Vector3, r: float, mat: Material, pale: Material) -> void:
	var d := b - a
	var len := d.length()
	if len < .0001:
		return
	var seg := Assets.cyl_mesh(r * .7, r, len, mat, 5)
	seg.position = (a + b) * .5
	seg.look_at_from_position(seg.position, b, Vector3.UP)
	seg.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	parent.add_child(seg)
	var ring := Assets.cyl_mesh(r * 1.15, r * 1.15, len * .16, pale, 5)
	ring.position = a.lerp(b, .88)
	ring.look_at_from_position(ring.position, b, Vector3.UP)
	ring.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	parent.add_child(ring)
	var joint := Assets.sphere_mesh(r * 1.2, mat)
	joint.position = b
	parent.add_child(joint)

# ───────── KẺ SĂN MỒI ─────────
static func make_nymph() -> Node3D:
	var g := Node3D.new()
	var n := 80
	var spine := PackedVector3Array()
	var rad := PackedFloat32Array()
	var vc := PackedFloat32Array()
	var L := 2.6
	for i in n:
		var u := float(i) / (n - 1)
		spine.append(Vector3(0, 0, u * L))
		var env: float = lerpf(.30, .4, smoothstep(0.0, .2, u)) * (1.0 - .6 * smoothstep(.55, 1.0, u))
		var k := u * 9.0
		env *= .9 + .1 * pow(absf(sin(PI * k)), .5)
		env *= .2 + .8 * sqrt(clampf((1.0 - u) / .05, 0.0, 1.0))
		rad.append(env)
		vc.append(u)
	var mesh := loft(spine, rad, vc, 18, Vector2(1.15, .75))
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.material_override = skin_mat("nymph", Color(.40, .40, .20), Color(.18, .18, .08), Color(.25, .24, .11), Color(.2, .2, .1), L, 9.0, 1.0, .5, .5)
	body.set_instance_shader_parameter("wig_amp", 0.0)
	g.add_child(body)
	var head := Assets.sphere_mesh(.34, skin_mat("nymph_head", Color(.34, .34, .17), Color(.15, .15, .07), Color(.2, .2, .1), Color(.2, .2, .1), 99.0, 1.0, 1.0, .5, .5), Vector3(1.1, .8, 1.0))
	head.position = Vector3(0, 0, -.28)
	head.set_instance_shader_parameter("wig_amp", 0.0)
	g.add_child(head)
	for sx in [-1.0, 1.0]:
		var eye := Assets.sphere_mesh(.13, std_mat(Color(.85, .7, .2), .12, 0.0, 1.0, .25), Vector3(1, 1, 1))
		eye.position = Vector3(sx * .27, .12, -.42)
		g.add_child(eye)
		var pup := Assets.sphere_mesh(.055, std_mat(Color(.05, .04, .02), .1))
		pup.position = Vector3(sx * .32, .14, -.5)
		g.add_child(pup)
	# chân 6 khúc
	var lm := std_mat(Color(.3, .3, .15), .6)
	var legs: Array = []
	for i in 6:
		var sx2 := 1.0 if i % 2 == 1 else -1.0
		var z0 := .15 + float(i / 2) * .4
		var a := Vector3(sx2 * .3, -.08, z0)
		var b := a + Vector3(sx2 * .42, .1, -.1 + float(i / 2) * .12)
		var c := b + Vector3(sx2 * .2, -.52, .05)
		_limb_plain(g, a, b, .042, lm)
		_limb_plain(g, b, c, .03, lm)
	# càng hàm (mặt nạ) — 2 phần tử để animation mở/đóng
	var jm := std_mat(Color(.14, .13, .06), .4)
	var jaws: Array = []
	for sx3 in [-1.0, 1.0]:
		var jaw := MeshInstance3D.new()
		var jc := CylinderMesh.new()
		jc.top_radius = .02
		jc.bottom_radius = .07
		jc.height = .6
		jaw.mesh = jc
		jaw.material_override = jm
		jaw.position = Vector3(sx3 * .13, -.1, -.78)
		jaw.rotation_degrees = Vector3(80, 0, sx3 * 12)
		g.add_child(jaw)
		jaws.append(jaw)
	g.set_meta("jaws", jaws)
	# mang đuôi
	for k in 3:
		var gl := Assets.sphere_mesh(.07, std_mat(Color(.45, .5, .25, .7), .4), Vector3(.35, .35, 1.8))
		gl.position = Vector3((k - 1) * .11, 0, L + .15)
		g.add_child(gl)
	return g

static func _limb_plain(parent: Node3D, a: Vector3, b: Vector3, r: float, mat: Material) -> void:
	var len := (b - a).length()
	var seg := Assets.cyl_mesh(r * .7, r, len, mat, 6)
	seg.position = (a + b) * .5
	seg.look_at_from_position(seg.position, b, Vector3.UP)
	seg.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	parent.add_child(seg)
	var joint := Assets.sphere_mesh(r * 1.15, mat)
	joint.position = b
	parent.add_child(joint)

static func make_beetle() -> Node3D:
	var g := Node3D.new()
	var shell_mat := StandardMaterial3D.new()
	shell_mat.albedo_color = Color(.12, .1, .05)
	shell_mat.roughness = .22
	shell_mat.metallic = .2
	shell_mat.clearcoat_enabled = true
	shell_mat.clearcoat = 1.0
	shell_mat.clearcoat_roughness = .12
	var shell := Assets.sphere_mesh(.42, shell_mat, Vector3(.82, .5, 1.3))
	g.add_child(shell)
	var edge := Assets.sphere_mesh(.43, std_mat(Color(.62, .5, .12), .35), Vector3(.84, .44, 1.31))
	edge.position.y = -.025
	g.add_child(edge)
	var head := Assets.sphere_mesh(.2, std_mat(Color(.1, .08, .04), .35), Vector3(1, .75, .9))
	head.position = Vector3(0, -.02, -.6)
	g.add_child(head)
	for sx in [-1.0, 1.0]:
		var eye := Assets.sphere_mesh(.07, std_mat(Color(.02, .02, .02), .08, 0.0, 1.0))
		eye.position = Vector3(sx * .13, .05, -.7)
		g.add_child(eye)
		var an := Assets.cyl_mesh(.006, .015, .32, std_mat(Color(.15, .1, .05), .7), 5)
		an.position = Vector3(sx * .1, .02, -.8)
		an.rotation_degrees = Vector3(-70, 0, sx * -20)
		g.add_child(an)
	var legs: Array = []
	var lm := std_mat(Color(.14, .1, .05), .5)
	for i in 6:
		var sx2 := 1.0 if i % 2 == 1 else -1.0
		var row := i / 2
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * .3, -.12, -.25 + row * .38)
		var seg := Assets.cyl_mesh(.025, .02, .55 + row * .15, lm, 5)
		seg.position = Vector3(sx2 * .3, -.12, 0)
		seg.rotation_degrees.z = sx2 * 70
		leg.add_child(seg)
		if row == 2:   # chân sau dẹt như mái chèo, có lông
			var paddle := Assets.box_mesh(Vector3(.5, .02, .22), std_mat(Color(.16, .12, .06, .9), .6))
			paddle.position = Vector3(sx2 * .62, -.2, 0)
			paddle.rotation_degrees.z = sx2 * 15
			leg.add_child(paddle)
		g.add_child(leg)
		legs.append(leg)
	g.set_meta("legs", legs)
	return g

static func make_strider() -> Node3D:
	var g := Node3D.new()
	var m := std_mat(Color(.12, .11, .08), .45)
	var body := Assets.sphere_mesh(.2, m, Vector3(.6, .5, 1.8))
	body.position.y = .38
	g.add_child(body)
	var head := Assets.sphere_mesh(.1, m)
	head.position = Vector3(0, .38, -.38)
	g.add_child(head)
	for sx in [-1.0, 1.0]:
		var eye := Assets.sphere_mesh(.04, std_mat(Color(.02, .02, .02), .1, 0.0, 1.0))
		eye.position = Vector3(sx * .07, .42, -.44)
		g.add_child(eye)
	for i in 6:
		var sx2 := 1.0 if i % 2 == 1 else -1.0
		var z0 := -.25 + float(i / 2) * .3
		var reach := 1.0 + float(i / 2 == 1) * .2 + float(i / 2 == 2) * .35
		var a := Vector3(sx2 * .1, .36, z0)
		var b := Vector3(sx2 * .55 * reach, .62, z0 + (float(i / 2) - 1.0) * .12)
		var c := Vector3(sx2 * 1.15 * reach, 0.0, z0 + (float(i / 2) - 1.0) * .3)
		_limb_plain(g, a, b, .012, m)
		_limb_plain(g, b, c, .009, m)
		var dim := Assets.cyl_mesh(.15, .15, .008, std_mat(Color(1, 1, 1, .22), .1), 14)
		dim.position = Vector3(c.x, -.008, c.z)
		g.add_child(dim)
	return g

# ───────── TRỨNG (muỗi Culex đẻ thành bè nổi, mỗi quả dựng đứng) ─────────
static func make_egg(marked: bool = false) -> Node3D:
	var g := Node3D.new()
	var mesh: ArrayMesh
	if _cache.has("egg_mesh"):
		mesh = _cache["egg_mesh"]
	else:
		var n := 28
		var spine := PackedVector3Array()
		var rad := PackedFloat32Array()
		var vc := PackedFloat32Array()
		for i in n:
			var t := float(i) / (n - 1)
			spine.append(Vector3(0, -.06 + t * .17, 0))
			# đáy tròn, đỉnh thon: giống quả trứng muỗi thật
			rad.append(.034 * pow(sin(PI * pow(t, .8)), .55) + .0005)
			vc.append(t)
		mesh = loft(spine, rad, vc, 14)
		_cache["egg_mesh"] = mesh
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var em := StandardMaterial3D.new()
	em.albedo_color = Color(.12, .085, .05)
	em.roughness = .24
	em.metallic_specular = .9
	em.clearcoat_enabled = true
	em.clearcoat = .7
	em.clearcoat_roughness = .18
	mi.material_override = em
	mi.name = "m"
	mi.rotation_degrees = Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
	g.add_child(mi)
	# mặt nước hơi gợn quanh chân quả trứng (sức căng bề mặt)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = .036
	tm.outer_radius = .06
	tm.rings = 24
	tm.ring_segments = 6
	ring.mesh = tm
	ring.scale = Vector3(1, .12, 1)
	ring.material_override = std_mat(Color(1, 1, 1, .22), .05, 0.0, 1.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.add_child(ring)
	if marked:
		var halo := MeshInstance3D.new()
		var hm := TorusMesh.new()
		hm.inner_radius = .11
		hm.outer_radius = .125
		hm.rings = 32
		hm.ring_segments = 6
		halo.mesh = hm
		halo.scale = Vector3(1, .08, 1)
		var hmat := StandardMaterial3D.new()
		hmat.albedo_color = Color(1, .85, .3, .9)
		hmat.emission_enabled = true
		hmat.emission = Color(1, .8, .25)
		hmat.emission_energy_multiplier = 1.6
		hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		halo.material_override = hmat
		halo.name = "halo"
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(halo)
	return g

static func raft_offsets(n: int) -> Array:
	var out: Array = [Vector2.ZERO]
	var ring := 1
	var sp := .1
	while out.size() < n:
		var cnt := 6 * ring
		for k in cnt:
			if out.size() >= n:
				break
			var a := float(k) / cnt * TAU + ring * .3
			out.append(Vector2(cos(a) * ring * sp, sin(a) * ring * sp * 1.35) + Vector2(randf_range(-.012, .012), randf_range(-.012, .012)))
		ring += 1
	return out

# ───────── THỨC ĂN CỦA LĂNG QUĂNG ─────────
static func _capsule(into: ArrayMesh, c: Vector3, d: Vector3, length: float, r: float) -> ArrayMesh:
	var dn := d.normalized()
	var sp := PackedVector3Array([c - dn * length * .5, c - dn * length * .25, c + dn * length * .25, c + dn * length * .5])
	var rr := PackedFloat32Array([r * .25, r, r, r * .25])
	var vc := PackedFloat32Array([0, .3, .7, 1])
	return loft(sp, rr, vc, 6, Vector2.ONE, into)

static func _food_mesh(kind: String, variant: int) -> ArrayMesh:
	var key := "food_%s_%d" % [kind, variant]
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = variant * 31 + kind.length()
	var m: ArrayMesh = null
	match kind:
		"bact":   # bông vi khuẩn: cụm que nhỏ kết dính
			m = ArrayMesh.new()
			for i in 12:
				var c := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * .045
				var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
				_capsule(m, c, d, rng.randf_range(.03, .055), .008)
		"plant":  # mảnh tảo / mảnh lá thực vật cong
			var n := 9
			var spine := PackedVector3Array()
			var rad := PackedFloat32Array()
			var vc := PackedFloat32Array()
			var curv := rng.randf_range(.5, 1.4)
			var ln := rng.randf_range(.18, .32)
			for i in n:
				var t := float(i) / (n - 1)
				spine.append(Vector3(sin(t * curv * 2.0) * ln * .25, (t - .5) * ln, cos(t * 3.0 + variant) * .015))
				rad.append(.045 * pow(sin(PI * clampf(t, .02, .98)), .6) + .002)
				vc.append(t)
			m = loft(spine, rad, vc, 8, Vector2(1.0, .1))
		"fila":   # sợi tảo
			var n2 := 14
			var sp2 := PackedVector3Array()
			var r2 := PackedFloat32Array()
			var v2 := PackedFloat32Array()
			for i in n2:
				var t2 := float(i) / (n2 - 1)
				sp2.append(Vector3(sin(t2 * 7.0 + variant) * .03, (t2 - .5) * .36, cos(t2 * 5.0) * .03))
				r2.append(.008 * (.6 + .4 * sin(t2 * PI)) + .002)
				v2.append(t2)
			m = loft(sp2, r2, v2, 6)
		"micro":  # động vật nguyên sinh dạng dép (Paramecium)
			var n3 := 22
			var sp3 := PackedVector3Array()
			var r3 := PackedFloat32Array()
			var v3 := PackedFloat32Array()
			for i in n3:
				var t3 := float(i) / (n3 - 1)
				sp3.append(Vector3(0, 0, (t3 - .5) * .16))
				r3.append(.036 * pow(sin(PI * t3), .55) * (1.0 - .25 * t3) + .0008)
				v3.append(t3)
			m = loft(sp3, r3, v3, 12, Vector2(1.0, .8))
	_cache[key] = m
	return m

static func make_food(tp: String) -> Node3D:
	var g := Node3D.new()
	var variant := randi() % 3
	match tp:
		"bact":
			var mi := MeshInstance3D.new()
			mi.mesh = _food_mesh("bact", variant)
			mi.material_override = std_mat(Color(.72, .78, .5, .8), .45, 0.0, .5, .35)
			g.add_child(mi)
		"plant":
			var mi2 := MeshInstance3D.new()
			var fil := randf() < .4
			mi2.mesh = _food_mesh("fila" if fil else "plant", variant)
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(.24, .52, .2) if not fil else Color(.3, .6, .22)
			gm.roughness = .55
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			gm.emission_enabled = true
			gm.emission = Color(.2, .5, .15)
			gm.emission_energy_multiplier = .25
			mi2.material_override = gm
			mi2.rotation = Vector3(randf() * 3.0, randf() * 6.0, randf() * 3.0)
			g.add_child(mi2)
		"micro":
			var mi3 := MeshInstance3D.new()
			mi3.mesh = _food_mesh("micro", variant)
			mi3.material_override = std_mat(Color(.95, .8, .55, .55), .15, 0.0, .8, .3)
			g.add_child(mi3)
			var nuc := Assets.sphere_mesh(.014, std_mat(Color(.35, .18, .08), .5))
			nuc.position = Vector3(0, 0, -.01)
			g.add_child(nuc)
			var vac := Assets.sphere_mesh(.008, std_mat(Color(1, 1, 1, .6), .1))
			vac.position = Vector3(.012, .008, .03)
			g.add_child(vac)
			var hm := MeshInstance3D.new()
			hm.mesh = _cilia_mesh()
			hm.material_override = hair_mat(99.0, Color(.9, .85, .7, .45))
			hm.set_instance_shader_parameter("wig_amp", 0.0)
			g.add_child(hm)
		_:
			for k in 2 + randi() % 2:
				var fl := Assets.sphere_mesh(.04 + randf() * .035, Assets.tex_material("ground_dirt", Vector3(3, 3, 3), Color(.42, .33, .24)), Vector3(1.0, .45 + randf() * .3, .8))
				fl.position = Vector3(randf_range(-.05, .05), randf_range(-.03, .03), randf_range(-.05, .05))
				fl.rotation = Vector3(randf() * 3.0, randf() * 3.0, randf() * 3.0)
				g.add_child(fl)
	# quầng sáng mờ để người chơi dễ phát hiện thức ăn trong nước đục (vẫn nhỏ và tự nhiên)
	var glint := MeshInstance3D.new()
	var gs := SphereMesh.new()
	gs.radius = .085
	gs.height = .17
	gs.radial_segments = 8
	gs.rings = 4
	glint.mesh = gs
	var gm2 := StandardMaterial3D.new()
	gm2.albedo_color = Color(.85, 1.0, .8, .13)
	gm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm2.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glint.material_override = gm2
	glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.add_child(glint)
	g.scale = Vector3.ONE * randf_range(.85, 1.3)
	return g

static func _cilia_mesh() -> ArrayMesh:
	if _cache.has("cilia"):
		return _cache["cilia"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 30:
		var t := rng.randf_range(.05, .95)
		var z := (t - .5) * .16
		var r := .036 * pow(sin(PI * t), .55) * (1.0 - .25 * t) * .9
		var a := rng.randf() * TAU
		var base := Vector3(cos(a) * r, sin(a) * r * .8, z)
		_hair_strip(st, base, Vector3(cos(a), sin(a), 0.2).normalized(), .035, Vector3(0, 0, .01), .0025)
	var m := st.commit()
	_cache["cilia"] = m
	return m
