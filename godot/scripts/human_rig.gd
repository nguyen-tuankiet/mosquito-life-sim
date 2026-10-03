class_name HumanRig
extends SkeletonModifier3D
## Điều khiển phụ lên bộ xương người SAU khi animation chạy: quay đầu nhìn theo muỗi và
## đưa tay phải tới một điểm (gãi chỗ bị đốt, giơ tay lên rồi vung xuống đập muỗi) bằng IK hai xương.

var head_target := Vector3.ZERO   # tọa độ thế giới
var head_w := 0.0
var arm_target := Vector3.ZERO
var arm_w := 0.0
var ids := {"head": -1, "neck": -1, "up": -1, "lo": -1, "hand": -1, "hips": -1}

static func attach(root: Node) -> HumanRig:
	for sk in root.find_children("*", "Skeleton3D", true, false):
		var m := HumanRig.new()
		(sk as Skeleton3D).add_child(m)
		m.setup(sk as Skeleton3D)
		return m
	return null

func setup(sk: Skeleton3D) -> void:
	ids["head"] = sk.find_bone("Head")
	ids["hips"] = sk.find_bone("Hips")
	ids["neck"] = sk.find_bone("Neck")
	ids["up"] = sk.find_bone("UpperArm.R")
	ids["lo"] = sk.find_bone("LowerArm.R")
	var hand := sk.find_bone("Palm.R")
	if hand < 0:
		hand = sk.find_bone("Wrist.R")
	ids["hand"] = hand

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	var inv := sk.global_transform.affine_inverse()
	if head_w > .01:
		_look(sk, inv)
	if arm_w > .01 and ids["up"] >= 0 and ids["lo"] >= 0 and ids["hand"] >= 0:
		_reach(sk, inv)

func _look(sk: Skeleton3D, inv: Transform3D) -> void:
	var tgt := inv * head_target
	for pair in [["neck", .35], ["head", .65]]:
		var i: int = ids[pair[0]]
		if i < 0:
			continue
		var g := sk.get_bone_global_pose(i)
		var dir := tgt - g.origin
		if dir.length() < .01:
			continue
		dir = dir.normalized()
		var yaw := clampf(atan2(dir.x, dir.z), -1.1, 1.1)
		var pitch := clampf(asin(clampf(dir.y, -1.0, 1.0)), -.6, .6)
		var want := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
		var q := Quaternion(Vector3(0, 0, 1), want)
		var part := Quaternion.IDENTITY.slerp(q, head_w * float(pair[1]))
		sk.set_bone_global_pose(i, Transform3D(Basis(part) * g.basis, g.origin))

func _aim(sk: Skeleton3D, bone: int, child: int, to: Vector3, w: float) -> void:
	var gb := sk.get_bone_global_pose(bone)
	var gc := sk.get_bone_global_pose(child)
	var cur := gc.origin - gb.origin
	var want := to - gb.origin
	if cur.length() < .001 or want.length() < .001:
		return
	var q := Quaternion(cur.normalized(), want.normalized())
	var part := Quaternion.IDENTITY.slerp(q, w)
	sk.set_bone_global_pose(bone, Transform3D(Basis(part) * gb.basis, gb.origin))

func _reach(sk: Skeleton3D, inv: Transform3D) -> void:
	var up: int = ids["up"]
	var lo: int = ids["lo"]
	var hand: int = ids["hand"]
	var tgt := inv * arm_target
	var a := sk.get_bone_global_pose(up).origin
	var b := sk.get_bone_global_pose(lo).origin
	var c := sk.get_bone_global_pose(hand).origin
	var l1 := (b - a).length()
	var l2 := (c - b).length()
	var to_t := tgt - a
	var d := clampf(to_t.length(), .08, (l1 + l2) * .995)
	var dir := to_t.normalized()
	var x := (d * d + l1 * l1 - l2 * l2) / (2.0 * d)
	var hh := sqrt(maxf(l1 * l1 - x * x, 0.0))
	var side := signf(a.x) if absf(a.x) > .001 else 1.0
	var pole := Vector3(side * .5, -.3, -.4)
	pole -= dir * pole.dot(dir)
	if pole.length() < .001:
		pole = Vector3(side, 0, 0)
	pole = pole.normalized()
	var elbow := a + dir * x + pole * hh
	_aim(sk, up, lo, elbow, arm_w)
	# sau khi xương trên quay, khuỷu đã dịch chuyển: nhắm xương dưới về điểm đích
	var hand_goal := a + dir * d
	var b2 := sk.get_bone_global_pose(lo).origin
	var c2 := sk.get_bone_global_pose(hand).origin
	var cur2 := c2 - b2
	var want2 := hand_goal - b2
	if cur2.length() > .001 and want2.length() > .001:
		var gl := sk.get_bone_global_pose(lo)
		var q2 := Quaternion(cur2.normalized(), want2.normalized())
		var part2 := Quaternion.IDENTITY.slerp(q2, arm_w)
		sk.set_bone_global_pose(lo, Transform3D(Basis(part2) * gl.basis, gl.origin))

## Vị trí thế giới của một xương theo tên (Torso, Neck, UpperArm.R…); ZERO nếu không có.
func bone_pos(bname: String) -> Vector3:
	var sk := get_skeleton()
	if sk == null:
		return Vector3.ZERO
	var i := sk.find_bone(bname)
	if i < 0:
		return Vector3.ZERO
	return sk.global_transform * sk.get_bone_global_pose(i).origin

func bone_world(key: String) -> Vector3:
	var sk := get_skeleton()
	var i: int = ids.get(key, -1)
	if sk == null or i < 0:
		return Vector3.ZERO
	return sk.global_transform * sk.get_bone_global_pose(i).origin
