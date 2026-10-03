extends Node3D
class_name FxLayer
## Hiệu ứng chuyển giai đoạn: sóng nước, bọt khí, vỏ trứng rỗng, xác lột, vỏ nhộng.
## Mọi toạ độ là toạ độ của node cha (thế giới của màn chơi).

var items: Array = []
var surf_y := 0.0          # độ cao mặt nước (chủ cập nhật mỗi khung hình)

static func ghost_mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = .25
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.rim_enabled = true
	m.rim = .9
	m.rim_tint = .4
	return m

## Biến bản sao thành "vỏ" trong mờ; trả về danh sách vật liệu để làm mờ dần.
static func ghostify(n: Node, col: Color) -> Array:
	var mats: Array = []
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		var m := ghost_mat(col)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mats.append(m)
	return mats

func clear_all() -> void:
	for it in items:
		if is_instance_valid(it["n"]): it["n"].queue_free()
	items.clear()

## Vòng sóng lan trên mặt nước.
func ring(pos: Vector3, rmax: float, life: float = 1.8, delay: float = 0.0) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = .985
	tm.outer_radius = 1.0
	tm.rings = 32
	tm.ring_segments = 6
	mi.mesh = tm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 1, 1, .0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(pos.x, surf_y + rmax * .01, pos.z)
	mi.scale = Vector3(.01, 1, .01)
	mi.visible = false
	add_child(mi)
	items.append({"k": "ring", "n": mi, "m": m, "t": -delay, "life": life, "r": rmax})

## Bọt khí nổi lên.
func bubbles(pos: Vector3, n: int, k: float = 1.0, spread: float = .3) -> void:
	for i in n:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var r := randf_range(.018, .05) * k
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = 8
		sm.rings = 4
		mi.mesh = sm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(.9, 1, 1, .5)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = .05
		m.rim_enabled = true
		m.rim = 1.0
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = pos + Vector3(randf_range(-spread, spread), randf_range(-spread * .5, spread * .5), randf_range(-spread, spread)) * k
		add_child(mi)
		items.append({"k": "bub", "n": mi, "t": -randf_range(0.0, .5), "life": 12.0, "vy": randf_range(.35, .8) * k, "ph": randf() * 6.0})

## Bản sao trong mờ của một sinh vật (vỏ trứng, xác lột, vỏ nhộng).
## mode: "float" nằm nổi trên mặt nước · "drift" trôi/chìm chậm · "case" nằm nổi nghiêng (vỏ nhộng)
func ghost(src: Node3D, life: float, mode: String, col: Color = Color(.95, .92, .8, .42)) -> Node3D:
	var g := src.duplicate() as Node3D
	add_child(g)
	g.global_transform = src.global_transform
	var mats := ghostify(g, col)
	items.append({"k": "ghost", "n": g, "mats": mats, "col": col, "t": 0.0, "life": life, "mode": mode, "v": Vector3(randf_range(-.04, .04), -.05, randf_range(-.04, .04)),
		"spin": randf_range(-.4, .4), "ph": randf() * 6.0, "y0": g.position.y})
	return g

func update(dt: float) -> void:
	for i in range(items.size() - 1, -1, -1):
		var it: Dictionary = items[i]
		var n: Node3D = it["n"]
		if not is_instance_valid(n):
			items.remove_at(i)
			continue
		it["t"] += dt
		var t: float = it["t"]
		if t < 0.0:
			continue
		var life: float = it["life"]
		var done := false
		match it["k"]:
			"ring":
				n.visible = true
				var u := clampf(t / life, 0.0, 1.0)
				var r: float = float(it["r"]) * (1.0 - pow(1.0 - u, 2.5))
				n.scale = Vector3(maxf(r, .01), 1.0, maxf(r, .01))
				n.position.y = surf_y + r * .01
				(it["m"] as StandardMaterial3D).albedo_color.a = (1.0 - u) * .55
				done = u >= 1.0
			"bub":
				n.position.y += float(it["vy"]) * dt
				n.position.x += sin(t * 5.0 + float(it["ph"])) * .04 * dt * 8.0
				if n.position.y >= surf_y:
					done = true
			"ghost":
				var mode: String = it["mode"]
				var v: Vector3 = it["v"]
				if mode == "float" or mode == "case":
					n.position.y = lerpf(n.position.y, surf_y + (.0 if mode == "float" else .004), minf(1.0, dt * 3.0)) + sin(t * 1.6 + float(it["ph"])) * .0004
					n.position.x += v.x * dt * .3
					n.position.z += v.z * dt * .3
				else:
					v.x *= exp(-.8 * dt); v.z *= exp(-.8 * dt)
					v.y = lerpf(v.y, -.12, minf(1.0, dt * .6))
					it["v"] = v
					n.position += v * dt
					n.rotation.y += float(it["spin"]) * dt
					n.rotation.x += float(it["spin"]) * .3 * dt
				var fade := clampf((life - t) / minf(4.0, life * .4), 0.0, 1.0)
				var c: Color = it["col"]
				for m in it["mats"]:
					(m as StandardMaterial3D).albedo_color = Color(c.r, c.g, c.b, c.a * fade)
				done = t >= life
		if done:
			n.queue_free()
			items.remove_at(i)
