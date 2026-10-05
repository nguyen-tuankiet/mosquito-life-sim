class_name Assets
extends RefCounted
## Tiện ích nạp model .glb, chuẩn hóa kích thước, phát animation, tạo vật liệu từ texture Poly Haven.

static var _cache: Dictionary = {}
static var _mats: Dictionary = {}

static func scene(name: String) -> PackedScene:
	if name.begins_with("island_tree_") and OS.has_feature("web"):
		name = "birch"   # bản web: model cây Poly Haven quá nặng (50-100MB/cây), thay bằng cây nhẹ
	if not _cache.has(name):
		var path := "res://assets/models/%s.glb" % name
		if not ResourceLoader.exists(path):
			path = "res://assets/ph/%s/%s.gltf" % [name, name]   # model Poly Haven
		_cache[name] = load(path)
	return _cache[name]

static func aabb_of(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		var t: Transform3D = mi.transform
		var p: Node = mi.get_parent()
		while p != null and p != n:
			if p is Node3D:
				t = (p as Node3D).transform * t
			p = p.get_parent()
		var a: AABB = t * mi.get_aabb()
		if first:
			out = a
			first = false
		else:
			out = out.merge(a)
	return out

## Dựng model, co giãn theo chiều cao đích; gốc nằm ở chân, giữa XZ. Trả về wrapper.
static func model(name: String, target_h: float, piece: String = "", fit: String = "y") -> Node3D:
	var n: Node3D = scene(name).instantiate() as Node3D
	if piece != "":
		var root: Node = n.get_child(0)
		var src: Node3D = root.get_node_or_null(piece) as Node3D
		if src != null:
			var holder := Node3D.new()
			var d: Node3D = src.duplicate() as Node3D
			d.position = Vector3.ZERO
			holder.add_child(d)
			n.free()
			n = holder
	var wrap := Node3D.new()
	wrap.add_child(n)
	var a := aabb_of(n)
	var h: float = a.size.y
	if fit == "x": h = a.size.x
	elif fit == "z": h = a.size.z
	elif fit == "max": h = max(a.size.x, max(a.size.y, a.size.z))
	h = max(h, 0.0001)
	var s: float = target_h / h
	n.scale = Vector3.ONE * s
	var c := a.get_center()
	n.position = Vector3(-c.x * s, -a.position.y * s, -c.z * s)
	wrap.set_meta("inner", n)
	wrap.set_meta("scale", s)
	return wrap

static func find_ap(n: Node) -> AnimationPlayer:
	if n.has_meta("ap"):
		return n.get_meta("ap")
	var inner: Node = n.get_meta("inner") if n.has_meta("inner") else n
	var aps := inner.find_children("*", "AnimationPlayer", true, false)
	var ap: AnimationPlayer = aps[0] if aps.size() > 0 else null
	n.set_meta("ap", ap)
	return ap

static func anim_name(ap: AnimationPlayer, short: String) -> String:
	for a in ap.get_animation_list():
		var s := String(a)
		if s.get_slice("|", s.get_slice_count("|") - 1) == short:
			return s
	return ""

## Phát animation theo tên ngắn (vd "Walk"); trả về false nếu không có.
static func play(n: Node, short: String, speed: float = 1.0, loop: bool = true, blend: float = .25) -> bool:
	var ap := find_ap(n)
	if ap == null:
		return false
	var an := anim_name(ap, short)
	if an == "":
		return false
	var anim := ap.get_animation(an)
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	if ap.current_animation != an:
		ap.play(an, blend, speed)
	else:
		ap.speed_scale = speed
	return true

static func freeze_at_end(n: Node, short: String) -> void:
	var ap := find_ap(n)
	if ap == null:
		return
	var an := anim_name(ap, short)
	if an == "":
		return
	ap.play(an)
	ap.seek(ap.get_animation(an).length, true)
	ap.pause()

static func tex_material(name: String, uv: Vector3 = Vector3(1, 1, 1), tint: Color = Color.WHITE) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [name, uv, tint]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	for ext in ["jpg", "png"]:
		if ResourceLoader.exists("res://assets/textures/%s_diff.%s" % [name, ext]):
			m.albedo_texture = load("res://assets/textures/%s_diff.%s" % [name, ext])
		if ResourceLoader.exists("res://assets/textures/%s_nor_gl.%s" % [name, ext]):
			m.normal_enabled = true
			m.normal_texture = load("res://assets/textures/%s_nor_gl.%s" % [name, ext])
		if ResourceLoader.exists("res://assets/textures/%s_rough.%s" % [name, ext]):
			m.roughness_texture = load("res://assets/textures/%s_rough.%s" % [name, ext])
	m.albedo_color = tint
	m.uv1_scale = uv
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 1.0
	_mats[key] = m
	return m

static func color_material(c: Color, rough: float = .85, emissive: float = 0.0) -> StandardMaterial3D:
	var key := "c|%s|%s|%s" % [c, rough, emissive]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emissive > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emissive
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats[key] = m
	return m

static func box_mesh(size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	return mi

static func sphere_mesh(r: float, mat: Material, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 20
	sm.rings = 10
	mi.mesh = sm
	mi.material_override = mat
	mi.scale = scl
	return mi

static func cyl_mesh(rt: float, rb: float, h: float, mat: Material, segs: int = 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = rt
	cm.bottom_radius = rb
	cm.height = h
	cm.radial_segments = segs
	mi.mesh = cm
	mi.material_override = mat
	return mi

## Làm bóng/ướt bề mặt các material của một model (vảy cá, vỏ...)
static func glossy(n: Node, rough: float = .35, metal: float = .25, coat: float = .6) -> void:
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i)
			if mat is StandardMaterial3D:
				var d := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				d.roughness = rough
				d.metallic = metal
				d.metallic_specular = .8
				d.clearcoat_enabled = true
				d.clearcoat = coat
				d.clearcoat_roughness = .2
				d.rim_enabled = true
				d.rim = .25
				d.rim_tint = .6
				mi.set_surface_override_material(i, d)

# ═════════════ NÂNG CẤP NGƯỜI & ĐỘNG VẬT: chia nhỏ lưới + vật liệu da/vải/tóc ═════════════
static var _upg_cache: Dictionary = {}

static func _qkey(p: Vector3) -> Vector3i:
	return Vector3i(roundi(p.x * 2000.0), roundi(p.y * 2000.0), roundi(p.z * 2000.0))

static func _smooth_normals(verts: PackedVector3Array, idx: PackedInt32Array) -> PackedVector3Array:
	var acc: Dictionary = {}
	for t in range(0, idx.size(), 3):
		var a := verts[idx[t]]
		var b := verts[idx[t + 1]]
		var c := verts[idx[t + 2]]
		var fn := (b - a).cross(c - a)
		for k in 3:
			var key := _qkey(verts[idx[t + k]])
			acc[key] = acc.get(key, Vector3.ZERO) + fn
	var out := PackedVector3Array()
	out.resize(verts.size())
	for i in verts.size():
		var v: Vector3 = acc.get(_qkey(verts[i]), Vector3.UP)
		out[i] = v.normalized() if v.length_squared() > 1e-12 else Vector3.UP
	return out

## Chia nhỏ 1 lần (Phong tessellation) để mềm hóa hình khối low-poly, giữ nguyên xương/trọng số/UV.
static func subdivide_arrays(arr: Array, alpha: float = .65) -> Array:
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var uvs = arr[Mesh.ARRAY_TEX_UV]
	var bones = arr[Mesh.ARRAY_BONES]
	var wts = arr[Mesh.ARRAY_WEIGHTS]
	var nv := verts.size()
	var nrm := _smooth_normals(verts, idx)
	var bpv := 0
	if bones != null and nv > 0:
		bpv = bones.size() / nv
	var ov := verts.duplicate()
	var on := nrm.duplicate()
	var ouv: PackedVector2Array = uvs.duplicate() if uvs != null else PackedVector2Array()
	var ob: PackedInt32Array = bones.duplicate() if bones != null else PackedInt32Array()
	var ow: PackedFloat32Array = wts.duplicate() if wts != null else PackedFloat32Array()
	var emap: Dictionary = {}
	var oidx := PackedInt32Array()
	var mid := func(a: int, b: int) -> int:
		var key := (mini(a, b) << 24) | maxi(a, b)
		if emap.has(key):
			return emap[key]
		var pa := verts[a]
		var pb := verts[b]
		var m := (pa + pb) * .5
		var qa := m - nrm[a] * (m - pa).dot(nrm[a])
		var qb := m - nrm[b] * (m - pb).dot(nrm[b])
		var pos := m.lerp((qa + qb) * .5, alpha)
		var ni := ov.size()
		ov.append(pos)
		on.append((nrm[a] + nrm[b]).normalized())
		if uvs != null:
			ouv.append(((uvs[a] as Vector2) + (uvs[b] as Vector2)) * .5)
		if bpv > 0:
			var wd: Dictionary = {}
			for k in bpv:
				var wa: float = wts[a * bpv + k]
				if wa > 0.0:
					wd[bones[a * bpv + k]] = wd.get(bones[a * bpv + k], 0.0) + wa * .5
				var wb: float = wts[b * bpv + k]
				if wb > 0.0:
					wd[bones[b * bpv + k]] = wd.get(bones[b * bpv + k], 0.0) + wb * .5
			var keys := wd.keys()
			keys.sort_custom(func(x, y): return wd[x] > wd[y])
			var tot := 0.0
			for k in mini(bpv, keys.size()):
				tot += wd[keys[k]]
			for k in bpv:
				if k < keys.size() and tot > 0.0:
					ob.append(keys[k])
					ow.append(wd[keys[k]] / tot)
				else:
					ob.append(0)
					ow.append(0.0)
		emap[key] = ni
		return ni
	for t in range(0, idx.size(), 3):
		var a: int = idx[t]
		var b: int = idx[t + 1]
		var c: int = idx[t + 2]
		var ab: int = mid.call(a, b)
		var bc: int = mid.call(b, c)
		var ca: int = mid.call(c, a)
		oidx.append_array(PackedInt32Array([a, ab, ca, ab, b, bc, ca, bc, c, ab, bc, ca]))
	var out: Array = []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = ov
	out[Mesh.ARRAY_NORMAL] = _smooth_normals(ov, oidx)
	out[Mesh.ARRAY_INDEX] = oidx
	if uvs != null: out[Mesh.ARRAY_TEX_UV] = ouv
	if bpv > 0:
		out[Mesh.ARRAY_BONES] = ob
		out[Mesh.ARRAY_WEIGHTS] = ow
	return out

static var _noise_n: Texture2D
static var _noise_cloth: Texture2D

static func _normal_noise(freq: float, as_cloth: bool) -> Texture2D:
	if as_cloth and _noise_cloth != null:
		return _noise_cloth
	if (not as_cloth) and _noise_n != null:
		return _noise_n
	var fn := FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = freq
	fn.fractal_octaves = 3
	var t := NoiseTexture2D.new()
	t.noise = fn
	t.as_normal_map = true
	t.bump_strength = 2.0 if not as_cloth else 4.0
	t.seamless = true
	t.width = 256
	t.height = 256
	if as_cloth:
		_noise_cloth = t
	else:
		_noise_n = t
	return t

static func _skin_material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c.lightened(.04)
	m.roughness = .52
	m.metallic_specular = .45
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = .55
	m.subsurf_scatter_skin_mode = true
	m.normal_enabled = true
	m.normal_texture = _normal_noise(.09, false)
	m.normal_scale = .35
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(7, 7, 7)
	m.rim_enabled = true
	m.rim = .25
	m.rim_tint = .8
	return m

static func _cloth_material(c: Color, rough: float = .93) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic_specular = .2
	m.normal_enabled = true
	m.normal_texture = _normal_noise(.35, true)
	m.normal_scale = .55
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(22, 22, 22)
	m.rim_enabled = true
	m.rim = .35
	m.rim_tint = .5
	return m

static func _hair_material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = .55
	m.metallic_specular = .35
	m.anisotropy_enabled = true
	m.anisotropy = .25
	m.normal_enabled = true
	m.normal_texture = _normal_noise(.5, true)
	m.normal_scale = .6
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(14, 3, 14)
	m.rim_enabled = true
	m.rim = .3
	m.rim_tint = .3
	return m

static func _eye_material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c.darkened(.4)
	m.roughness = .04
	m.metallic_specular = 1.0
	m.clearcoat_enabled = true
	m.clearcoat = 1.0
	m.clearcoat_roughness = .03
	return m

static func _styled(mat_name: String, src: Material) -> Material:
	var c := Color.WHITE
	if src is BaseMaterial3D:
		c = (src as BaseMaterial3D).albedo_color
	match mat_name:
		"Skin": return _skin_material(c)
		"Hair", "HairBase", "Eyebrows": return _hair_material(c)
		"Eyes", "Eye": return _eye_material(c)
		"Shoes", "Socks": return _cloth_material(c, .7)
		"Shirt", "Pants", "White", "Purple", "LightBlue": return _cloth_material(c)
	return src

## Làm mềm lưới có xương + áp vật liệu da/vải/tóc thực tế hơn. kind: "human" hoặc "animal".
static func upgrade_skinned(node: Node, key: String, kind: String = "human") -> void:
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var am := mi.mesh as ArrayMesh
		if am == null:
			continue
		var ck := "%s|%s" % [key, mi.name]
		if _upg_cache.has(ck):
			mi.mesh = _upg_cache[ck]
			continue
		var baked := "res://assets/baked/%s__%s.res" % [key, mi.name]
		if ResourceLoader.exists(baked):
			var bm = load(baked)
			if bm is ArrayMesh:
				_upg_cache[ck] = bm
				mi.mesh = bm
				continue
		var nm := ArrayMesh.new()
		for i in am.get_surface_count():
			var arr := am.surface_get_arrays(i)
			var old_mat := am.surface_get_material(i)
			var narr := subdivide_arrays(arr)
			nm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, narr)
			var mname := old_mat.resource_name if old_mat != null else ""
			var nmat: Material = old_mat
			if kind == "human":
				nmat = _styled(mname, old_mat)
			elif old_mat is BaseMaterial3D:
				var d := (old_mat as BaseMaterial3D).duplicate() as BaseMaterial3D
				d.roughness = .88
				d.rim_enabled = true
				d.rim = .3
				d.rim_tint = .6
				d.normal_enabled = true
				d.normal_texture = _normal_noise(.35, true)
				d.normal_scale = .5
				d.uv1_triplanar = true
				d.uv1_scale = Vector3(18, 18, 18)
				nmat = d
			nm.surface_set_material(nm.get_surface_count() - 1, nmat)
		_upg_cache[ck] = nm
		mi.mesh = nm
		# lưu bản đã xử lý để lần sau nạp tức thì (chỉ ghi được khi chạy từ thư mục dự án)
		DirAccess.make_dir_recursive_absolute("res://assets/baked")
		ResourceSaver.save(nm, baked)
