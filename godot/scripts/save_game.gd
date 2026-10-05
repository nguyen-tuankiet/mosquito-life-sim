class_name SaveGame
extends RefCounted
## Lưu / nạp tiến trình chơi (dòng họ, thống kê, nhiệm vụ, giai đoạn, vị trí) vào user://save.dat.

const PATH := "user://save.dat"
const TMP := "user://save.tmp"
const VERSION := 1

static func exists() -> bool:
	return FileAccess.file_exists(PATH)

static func clear() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

static func write(d: Dictionary) -> bool:
	d["v"] = VERSION
	var f := FileAccess.open(TMP, FileAccess.WRITE)
	if f == null:
		push_warning("SaveGame: không ghi được %s (lỗi %d)" % [TMP, FileAccess.get_open_error()])
		return false
	f.store_var(d, false)
	f.close()
	var da := DirAccess.open("user://")
	if da == null or da.rename(TMP, PATH) != OK:
		# rename không ghi đè được trên một số hệ thống: xoá bản cũ rồi đổi tên lại
		clear()
		if da == null or da.rename(TMP, PATH) != OK:
			push_warning("SaveGame: không đổi tên được file lưu")
			return false
	return true

## Trả về {} nếu không có file lưu hoặc file hỏng / sai phiên bản.
static func read() -> Dictionary:
	if not exists():
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var d: Variant = f.get_var(false)
	if not (d is Dictionary) or int(d.get("v", 0)) != VERSION or not d.has("L") or not d.has("G") or not d.has("mode"):
		return {}
	return d

## Chỉ giữ giá trị đơn giản (số, bool, chuỗi, vector, màu) để lưu an toàn; bỏ tham chiếu tới node/đối tượng.
static func plain(d: Dictionary, skip: Array = []) -> Dictionary:
	var o := {}
	for k in d:
		if skip.has(k):
			continue
		var v: Variant = d[k]
		if v is float or v is int or v is bool or v is String or v is Vector2 or v is Vector3 or v is Color:
			o[k] = v
	return o
