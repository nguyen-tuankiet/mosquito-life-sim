class_name Talk
extends RefCounted
## Thoại NPC làng quê miền Tây (kho câu: res://data/thoai_mientay.json, quy tắc viết: docs/DIALOGUE.md).
## pick(ngữ cảnh, tính cách, người nói) → câu đã thay {t}/{T}, hoặc "" (im lặng / mặc kệ).
##  - Câu '~' (chửi vui, cà khịa) chỉ bốc theo rough_rate của tính cách → trung bình cả làng ~5–10 %.
##  - Không lặp lại câu mà chính người đó vừa nói (nhớ 6 câu gần nhất).

const PATH := "res://data/thoai_mientay.json"
const ANNOYED := ["hear", "scratch", "swat", "miss", "hit", "bitten", "lost", "night_hear"]

static var _data: Dictionary = {}
static var _recent: Dictionary = {}     # người nói → [câu gần đây]
static var last_rough := false          # câu vừa bốc có phải câu chửi vui không (kiểm thử tỉ lệ)


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_data = d
	return _data


static func personas() -> Array:
	return data().get("personas", {}).keys()


## Tiếng tự xưng: tao / tui / con; người lớn tuổi: ông (nam) hoặc bà (nữ).
static func self_term(persona: String, female: bool) -> String:
	var s := String(data().get("personas", {}).get(persona, {}).get("self", "tao"))
	if s.contains("|"):
		return s.get_slice("|", 1 if female else 0)
	return s


static func talk_rate(persona: String) -> float:
	return float(data().get("personas", {}).get(persona, {}).get("talk_rate", 1.0))


## Các câu (thô, còn '~' và {t}) của một ngữ cảnh cho một tính cách: câu riêng + câu chung '*'.
static func pool(ctx: String, persona: String) -> Array:
	var c: Dictionary = data().get("lines", {}).get(ctx, {})
	var out: Array = []
	out.append_array(c.get(persona, []))
	out.append_array(c.get("*", []))
	return out


static func pick(ctx: String, persona: String, speaker: String, me: String, rng: RandomNumberGenerator = null) -> String:
	var all := pool(ctx, persona)
	if all.is_empty():
		return ""
	var rough: Array = []
	var calm: Array = []
	for l in all:
		(rough if String(l).begins_with("~") else calm).append(l)
	var rate := float(data().get("personas", {}).get(persona, {}).get("rough_rate", 0.05))
	var r := rng.randf() if rng else randf()
	var src: Array = rough if (not rough.is_empty() and r < rate) or calm.is_empty() else calm
	var recent: Array = _recent.get(speaker, [])
	var fresh := src.filter(func(l): return not recent.has(l))
	if fresh.is_empty():
		fresh = src
	var line: String = fresh[(rng.randi() if rng else randi()) % fresh.size()]
	last_rough = is_rough(line)
	recent.append(line)
	if recent.size() > 6:
		recent.pop_front()
	_recent[speaker] = recent
	return fill(line, me)


## Một cặp hỏi–đáp giữa hai người hàng xóm.
static func chat_pair(rng: RandomNumberGenerator = null) -> Array:
	var c: Array = data().get("chat", [])
	if c.is_empty():
		return []
	var p: Array = c[(rng.randi() if rng else randi()) % c.size()]
	return [fill(String(p[0]), "tao"), fill(String(p[1]), "tao")]


static func fill(line: String, me: String) -> String:
	if line.begins_with("~"):
		line = line.substr(1)
	return line.replace("{T}", me.capitalize()).replace("{t}", me)


static func is_rough(raw: String) -> bool:
	return raw.begins_with("~")
