extends Node3D
## Dựng thực vật (tre, cỏ, lúa, sậy, bèo, bụi) bằng MultiMesh từ map_points.json do Blender xuất
## (blender/scripts/generate_map.py --stage env --swap --godot). Mỗi loại × biến thể × ô 64 m = 1 MultiMeshInstance3D
## với tầm nhìn tối đa riêng → hàng trăm nghìn cây vẫn nhẹ.
##
## Công thức đặt cây khớp Blender: world = T(pos)·R_y(rot)·S(scale)·T(offset)·S(asset_scale)

const CELL := 64.0
const VIS_RANGE := {
	"GrassPoint": 55.0, "GrassTallPoint": 110.0, "RicePoint": 140.0, "ReedPoint": 120.0,
	"LilyPoint": 120.0, "ShrubPoint": 180.0, "BambooPoint": 240.0,
}

var instance_count := 0


func build(points_path: String, foliage_dir: String) -> int:
	var f := FileAccess.open(points_path, FileAccess.READ)
	if f == null:
		push_warning("Không có %s" % points_path)
		return 0
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	var types: Dictionary = data.get("types", {})
	for t in types:
		var info: Dictionary = types[t]
		var assets: Array = info.get("assets", [])
		if assets.is_empty():
			continue
		var meshes: Array = []
		for a in assets:
			meshes.append(_load_mesh(foliage_dir + String(a["file"])))
		var arr: Array = info["data"]
		var stride: int = info["stride"]
		# gom transform theo (biến thể, ô)
		var buckets := {}
		for i in range(0, arr.size(), stride):
			var pos := Vector3(arr[i], arr[i + 1], arr[i + 2])
			var rot: float = arr[i + 3]
			var sc: float = arr[i + 4]
			var vi: int = int(arr[i + 5]) % assets.size()
			if meshes[vi] == null:
				continue
			var a: Dictionary = assets[vi]
			var off: Array = a["offset"]
			var basis := Basis(Vector3.UP, rot)
			var origin := pos + basis * (Vector3(off[0], off[1], off[2]) * sc)
			var xf := Transform3D(basis.scaled(Vector3.ONE * (sc * float(a["scale"]))), origin)
			xf = xf * (meshes[vi][1] as Transform3D)
			var key := Vector3i(vi, int(floor(pos.x / CELL)), int(floor(pos.z / CELL)))
			if not buckets.has(key):
				buckets[key] = []
			buckets[key].append(xf)
		for key in buckets:
			var xfs: Array = buckets[key]
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = meshes[key.x][0]
			mm.instance_count = xfs.size()
			for j in xfs.size():
				mm.set_instance_transform(j, xfs[j])
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "%s_v%d_%d_%d" % [t, key.x, key.y, key.z]
			mmi.multimesh = mm
			mmi.visibility_range_end = VIS_RANGE.get(t, 200.0)
			mmi.visibility_range_end_margin = 10.0
			mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if t == "BambooPoint" \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mmi)
			instance_count += xfs.size()
	return instance_count


## Trả về [Mesh, Transform3D của mesh trong file] — lấy MeshInstance3D đầu tiên của GLB.
func _load_mesh(path: String) -> Variant:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		push_warning("Không nạp được %s" % path)
		return null
	var root := doc.generate_scene(state)
	var found := _first_mesh(root, Transform3D.IDENTITY)
	root.queue_free()
	if found.is_empty():
		push_warning("%s không có mesh" % path)
		return null
	return found


func _first_mesh(n: Node, parent_xf: Transform3D) -> Array:
	var xf := parent_xf
	if n is Node3D:
		xf = parent_xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		return [(n as MeshInstance3D).mesh, xf]
	for c in n.get_children():
		var r := _first_mesh(c, xf)
		if not r.is_empty():
			return r
	return []
