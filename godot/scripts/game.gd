extends Node
## Autoload "Game": dữ liệu cố định, dòng họ (lineage), thống kê thế hệ, tiện ích chung.

const TRAITS := ["vit", "mob", "det", "oxy", "fee", "rep"]
const TRAIT_NAMES := {"vit": "Sinh lực", "mob": "Cơ động", "det": "Cảm nhận", "oxy": "Oxy", "fee": "Kiếm ăn", "rep": "Sinh sản"}
const BUILDS := {
	"survivor": {"name": "Survivor", "desc": "Né tránh & ẩn nấp: khó bị phát hiện hơn"},
	"fast": {"name": "Fast Growth", "desc": "Ăn nhiều: hút mật hiệu quả, nhiều trứng hơn"},
	"explorer": {"name": "Explorer", "desc": "Khám phá: bay nhanh hơn, cảm nhận xa hơn"},
}
const STAGE_NAMES := {"egg": "TRỨNG", "larva": "LĂNG QUĂNG", "pupa": "NHỘNG", "adult": "TRƯỞNG THÀNH"}
const DAY_LEN_AQ := 18.0           # 1 ngày dưới nước = 18 giây thực
const DAY_LEN_ADULT := 75.0        # 1 ngày trưởng thành = 75 giây thực (1 chu kỳ ngày-đêm)
const CLOCK_RATE := 24.0 / DAY_LEN_ADULT
var day_scale := 1.0               # --dayscale=0.1 để kiểm thử nhanh
var gate_days := true              # nhiệm vụ chỉ mở khi tới ngày của nó

# Địa điểm nước. pos = vị trí trong thế giới trưởng thành (x, z, bán kính); pond = cấu hình hồ khi còn là ấu trùng.
const SITES := [
	{"id": "puddle", "name": "Vũng nước mưa", "water": .45, "temp": .8, "food": .5, "pred": .3, "light": .9, "human": .1, "human_ev": 0.0, "wy": .07, "ly": 1.2,
		"pos": Vector3(-15, 13, 1.7), "pond": {"w": 18.0, "d": 14.0, "depth": 4.0, "preds": ["beetle", "strider"], "tint": Color(0.40, 0.50, 0.38), "dark": 0.0}},
	{"id": "bucket", "name": "Xô nước", "water": .7, "temp": .55, "food": .25, "pred": .05, "light": .45, "human": .85, "human_ev": .3, "wy": .37, "ly": 1.0,
		"pos": Vector3(-9.2, 2.5, 0.3), "pond": {"w": 9.0, "d": 9.0, "depth": 9.0, "preds": [], "tint": Color(0.33, 0.55, 0.68), "dark": 0.0}},
	{"id": "jar", "name": "Chum nước", "water": .75, "temp": .5, "food": .35, "pred": .05, "light": .5, "human": .6, "human_ev": .2, "wy": .6, "ly": 1.5,
		"pos": Vector3(10.5, 6.5, 0.45), "pond": {"w": 8.0, "d": 8.0, "depth": 8.0, "preds": ["strider"], "tint": Color(0.38, 0.55, 0.45), "dark": 0.0}},
	{"id": "pond", "name": "Ao làng", "water": .85, "temp": .45, "food": .95, "pred": .9, "light": .5, "human": .1, "human_ev": 0.0, "wy": .07, "ly": 1.8,
		"pos": Vector3(21, -4, 4.5), "pond": {"w": 30.0, "d": 24.0, "depth": 9.0, "preds": ["fish", "beetle", "nymph", "strider"], "tint": Color(0.18, 0.46, 0.52), "dark": 0.0}},
	{"id": "canal", "name": "Kênh mương", "water": .5, "temp": .4, "food": .75, "pred": .55, "light": .6, "human": .15, "human_ev": .06, "wy": .13, "ly": 1.2,
		"pos": Vector3(9, 19.2, 1.5), "pond": {"w": 26.0, "d": 9.0, "depth": 6.0, "preds": ["fish", "strider"], "tint": Color(0.26, 0.42, 0.34), "dark": 0.1}},
	{"id": "paddy", "name": "Ruộng lúa", "water": .75, "temp": .7, "food": .85, "pred": .45, "light": .8, "human": .2, "human_ev": .08, "wy": .15, "ly": 1.3,
		"pos": Vector3(-22, -17, 3.2), "pond": {"w": 26.0, "d": 20.0, "depth": 3.6, "preds": ["beetle", "nymph", "strider"], "tint": Color(0.42, 0.50, 0.30), "dark": 0.0}},
]

var L: Dictionary = {}      # dòng họ
var quests: Array = []
var quest_stage := ""
var toasts: Array = []
var G: Dictionary = {}      # thống kê thế hệ hiện tại
var best: int = 1

func _ready() -> void:
	_register_inputs()
	var f := FileAccess.open("user://best.txt", FileAccess.READ)
	if f:
		best = max(1, int(f.get_as_text()))

func save_best() -> void:
	best = max(best, int(L.get("gen", 1)))
	var f := FileAccess.open("user://best.txt", FileAccess.WRITE)
	if f:
		f.store_string(str(best))

func _register_inputs() -> void:
	var add := func(action: String, keys: Array) -> void:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in keys:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
	add.call("fwd", [KEY_W])
	add.call("back", [KEY_S])
	add.call("left", [KEY_A])
	add.call("right", [KEY_D])
	add.call("up", [KEY_SPACE])
	add.call("down", [KEY_SHIFT, KEY_C, KEY_CTRL])
	add.call("act", [KEY_E])
	add.call("feed", [KEY_Q])
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("feed", mb)
	add.call("look_l", [KEY_LEFT])
	add.call("look_r", [KEY_RIGHT])
	add.call("look_u", [KEY_UP])
	add.call("look_d", [KEY_DOWN])
	add.call("confirm", [KEY_ENTER, KEY_KP_ENTER])
	add.call("mute", [KEY_M])
	add.call("pause", [KEY_P])

# ───────── dòng họ ─────────
func new_lineage() -> void:
	L = {"gen": 1, "tr": {"vit": 1.0, "mob": 1.0, "det": 1.0, "oxy": 1.0, "fee": 1.0, "rep": 1.0}, "reserve": 0, "sibs": 4, "site": 2,
		"sex": "M" if randf() < .5 else "F", "weather": "normal", "ach": {}, "house_lays": 0}

func new_generation_stats() -> void:
	G = {"food": 0, "nectar": 0.0, "hits": 0, "dist": 0.0, "noticed": 0, "low_o2": 0.0, "hidden": 0.0, "life_t": 0.0, "eggs": 0,
		"build": "survivor", "survived_spray": false, "weather0": L["weather"], "mated": false, "quests_done": 0}

func tv(k: String) -> float:
	return float(L["tr"][k]) - 1.0

func day_no() -> int:
	return 1 + int(float(G.get("dayf", 0.0)))

## Đồng hồ lịch của vòng đời: gọi mỗi khung hình với độ dài 1 ngày của giai đoạn hiện tại.
func tick_day(dt: float, day_len: float) -> void:
	var before := day_no()
	G["dlen"] = day_len * day_scale
	G["dayf"] = float(G.get("dayf", 0.0)) + dt / (day_len * day_scale)
	if day_no() != before:
		toasts.append({"text": "Sang NGÀY %d của vòng đời" % day_no(), "t": 0.0})
		var nxt := q_active()
		if not nxt.is_empty() and q_open(nxt) and int(nxt.get("day", 0)) == day_no():
			toasts.append({"text": "Nhiệm vụ mới: " + String(nxt["title"]), "t": -.4})

func q_open(q: Dictionary) -> bool:
	return not gate_days or day_no() >= int(q.get("day", 0))

## Giây còn lại tới khi nhiệm vụ mở.
func q_wait_seconds(q: Dictionary) -> float:
	var days_left := float(int(q.get("day", 0)) - 1) - float(G.get("dayf", 0.0))
	return maxf(0.0, days_left * float(G.get("dlen", DAY_LEN_AQ)))

func build_factors() -> Dictionary:
	var b: String = G.get("build", "survivor")
	return {
		"stealth": .75 if b == "survivor" else 1.0,
		"nectar": 1.25 if b == "fast" else 1.0,
		"eggs": 1.2 if b == "fast" else 1.0,
		"speed": 1.12 if b == "explorer" else 1.0,
		"sense": 1.3 if b == "explorer" else 1.0,
		"drain": .9 if b == "fast" else 1.0,
	}

func choose_build() -> void:
	var s := {"survivor": float(G["hidden"]) / 18.0, "fast": float(G["food"]) / 28.0, "explorer": float(G["dist"]) / 120.0}
	var b := "survivor"
	var m := -1.0
	for k in s:
		if s[k] > m:
			m = s[k]
			b = k
	G["build"] = b

# ───────── thuộc tính nguồn nước ─────────
func attrs(i: int) -> Dictionary:
	var s: Dictionary = SITES[i]
	var a := {"water": s["water"], "temp": s["temp"], "food": s["food"], "pred": s["pred"], "light": s["light"], "human": s["human"]}
	var w: String = L.get("weather", "normal")
	if w == "drought":
		a["temp"] = min(1.0, a["temp"] + .2); a["water"] = max(0.0, a["water"] - .15); a["food"] = max(0.0, a["food"] - .1)
	elif w == "rain":
		a["temp"] = max(0.0, a["temp"] - .1); a["water"] = min(1.0, a["water"] + .1); a["light"] = max(0.0, a["light"] - .15)
	return a

func goodness(a: Dictionary) -> Dictionary:
	return {
		"Nước tù": a["water"], "Nhiệt độ": clamp(1 - abs(a["temp"] - .5) * 2, 0, 1), "Thức ăn": a["food"],
		"Kẻ săn mồi": 1 - a["pred"], "Ánh sáng": clamp(1 - abs(a["light"] - .35) * 1.6, 0, 1), "Con người": 1 - a["human"],
	}

func score_of(a: Dictionary) -> float:
	var g := goodness(a)
	return .2 * g["Nước tù"] + .15 * g["Nhiệt độ"] + .2 * g["Thức ăn"] + .2 * g["Kẻ săn mồi"] + .1 * g["Ánh sáng"] + .15 * g["Con người"]

func site_dry(i: int) -> bool:
	return L.get("weather", "normal") == "drought" and SITES[i]["id"] == "puddle"

# ───────── kết thúc thế hệ ─────────
func finish_generation(eggs: int, site_idx: int) -> Dictionary:
	G["eggs"] = eggs
	var p := {
		"vit": min(1.0, G["hits"] / 3.0), "mob": min(1.0, G["dist"] / 140.0), "det": min(1.0, G["noticed"] / 3.0),
		"oxy": min(1.0, G["low_o2"] / 12.0), "fee": min(1.0, (G["food"] + G["nectar"] / 12.0) / 45.0), "rep": min(1.0, eggs / 150.0),
	}
	var why := {"vit": "bị thương nhiều", "mob": "bay/bơi nhiều", "det": "bị phát hiện, phải cảnh giác", "oxy": "thiếu oxy khi lặn", "fee": "ăn nhiều", "rep": "đẻ nhiều trứng"}
	var ch := {}
	for k in TRAITS:
		var d: float = snappedf(0.8 * p[k], 0.01)
		ch[k] = d
		L["tr"][k] = min(6.0, L["tr"][k] + d)
	var got: Array = []
	var ach := func(id: String, t: String) -> void:
		if not L["ach"].has(id):
			L["ach"][id] = 1
			got.append(t)
	if L["gen"] >= 10: ach.call("g10", "Sống sót 10 thế hệ")
	if L["gen"] >= 100: ach.call("g100", "Duy trì quần thể 100 thế hệ")
	if G["weather0"] == "drought": ach.call("drought", "Vượt qua hạn hán")
	if G["survived_spray"]: ach.call("spray", "Sống sót sau khi bị phun thuốc")
	if SITES[site_idx]["human"] >= .5:
		L["house_lays"] += 1
		if L["house_lays"] >= 3: ach.call("house", "Lập quần thể trong nhà người")
	save_best()
	return {"eggs": eggs, "site": site_idx, "ch": ch, "why": why, "got": got, "t": 0.0, "build": G["build"], "sex": L["sex"], "days": day_no()}

func advance_generation(sum: Dictionary) -> void:
	L["gen"] += 1
	L["site"] = sum["site"]
	L["sibs"] = clampi(int(round(sum["eggs"] / 15.0)), 2, 12)
	L["sex"] = "M" if randf() < .5 else "F"


# ═════════════ NHIỆM VỤ THEO GIAI ĐOẠN (tuần tự: xong việc này mới hiện việc tiếp) ═════════════
const STAGE_FACT := {
	"egg": "Thực tế: trứng muỗi nở sau khoảng 1–3 ngày trong nước ấm (Culex đẻ thành bè nổi, mỗi trứng dựng đứng; Aedes đẻ rời sát mép nước).",
	"larva": "Thực tế: lăng quăng sống 4–7 ngày, lọc vi sinh vật và mùn bã, thở bằng ống ở cuối bụng, lột xác 3 lần qua 4 tuổi (instar I–IV).",
	"pupa": "Thực tế: nhộng (cung quăng) kéo dài 1–3 ngày, không ăn; nổi sát mặt nước để thở trong khi cơ thể tái cấu trúc thành muỗi.",
	"adultF": "Thực tế: muỗi cái giao phối 1–2 ngày sau khi vũ hóa, hút máu sau khoảng 2–3 ngày, mất 2–3 ngày tiêu hóa máu cho trứng chín rồi mới đẻ; sống khoảng 2–4 tuần.",
	"adultM": "Thực tế: muỗi đực không hút máu, ăn mật hoa, bay thành đàn nghe tiếng vỗ cánh của muỗi cái; chỉ sống khoảng 1 tuần.",
}
const QDEF := {
	"egg": [
		{"id": "stay", "day": 1, "title": "Bám trụ trên mặt nước", "desc": "Giữ trứng nổi an toàn, tránh kẻ săn mồi", "fact": "Bè trứng nổi nhờ sức căng bề mặt; cá và côn trùng mặt nước ăn trứng.", "goal": 5.0, "unit": "giây"},
		{"id": "shade", "day": 1, "title": "Tránh nắng gắt", "desc": "Trôi vào bóng lá khoảng 4 giây để trứng khỏi khô", "fact": "Trứng phơi nắng nóng sẽ mất nước và không nở được.", "goal": 4.0, "unit": "giây"},
		{"id": "embryo", "day": 2, "title": "Phôi phát triển", "desc": "Giữ nhiệt độ ổn định để phôi lớn lên", "fact": "Trong vỏ trứng, phôi thành ấu trùng nhỏ trong khoảng 1–2 ngày ở 25–30°C.", "goal": 100.0, "unit": "%"},
		{"id": "hatch", "day": 2, "title": "Nở thành lăng quăng", "desc": "Ấu trùng phá nắp trứng và chui xuống nước", "fact": "Ấu trùng nở ra có sẵn miệng, râu và ống thở.", "goal": 1.0, "unit": ""},
	],
	"larva": [
		{"id": "eat", "day": 3, "title": "Kiếm ăn", "desc": "Ăn vi khuẩn, tảo, vi sinh vật hoặc mùn bã (chạm vào chúng)", "fact": "Lăng quăng lọc thức ăn bằng chổi lông ở miệng.", "goal": 4.0, "unit": ""},
		{"id": "breath", "day": 3, "title": "Thở bằng ống thở", "desc": "Lặn xuống rồi trồi lên mặt nước để thở, 3 lần", "fact": "Ống thở ở cuối bụng phải chạm mặt nước mới lấy được không khí.", "goal": 3.0, "unit": "lần"},
		{"id": "molt1", "day": 4, "title": "Lột xác lần 1 (Instar I → II)", "desc": "Ăn đủ lớn rồi ẩn mình trong rong/đá/dưới lá 3 giây", "fact": "Lúc lột xác ấu trùng rất yếu nên phải trốn kỹ.", "goal": 1.0, "unit": ""},
		{"id": "hunt", "day": 5, "title": "Thoát khỏi kẻ săn mồi", "desc": "Khi cá, bọ nước hoặc ấu trùng chuồn chuồn đuổi theo, hãy bơi/quẫy (E) hoặc núp vào rong để sống sót vài giây", "fact": "Ấu trùng muỗi trốn bằng cách lặn sâu, quẫy mạnh hoặc chui vào rong.", "goal": 1.0, "unit": ""},
		{"id": "molt2", "day": 5, "title": "Lột xác lần 2 (Instar II → III)", "desc": "Ăn tiếp cho đủ lớn rồi ẩn mình lột xác", "fact": "Mỗi lần lột, thân dài ra và vỏ cũ bỏ lại.", "goal": 1.0, "unit": ""},
		{"id": "molt3", "day": 6, "title": "Lột xác lần 3 (Instar III → IV)", "desc": "Ăn tiếp rồi ẩn mình lột xác lần cuối của giai đoạn ấu trùng", "fact": "Tuổi 4 là giai đoạn ấu trùng lớn nhất.", "goal": 1.0, "unit": ""},
		{"id": "grow", "day": 7, "title": "Tích lũy năng lượng hóa nhộng", "desc": "Ăn cho đến khi đầy 100% dinh dưỡng", "fact": "Năng lượng này nuôi nhộng suốt giai đoạn không ăn.", "goal": 100.0, "unit": "%"},
	],
	"pupa": [
		{"id": "breathe", "day": 8, "title": "Thở bằng ống thở trên đầu", "desc": "Nổi sát mặt nước khoảng 4 giây để lấy không khí", "fact": "Nhộng thở bằng hai ống nhỏ ở ngực, không phải ống ở bụng như lăng quăng.", "goal": 4.0, "unit": "giây"},
		{"id": "hide", "day": 8, "title": "Ẩn nấp", "desc": "Núp trong rong, đá hoặc dưới lá khoảng 5 giây", "fact": "Nhộng có thể lặn nhanh để trốn khi bị làm phiền.", "goal": 5.0, "unit": "giây"},
		{"id": "meta", "day": 9, "title": "Biến thái", "desc": "Nằm yên (bơi chậm) để cơ thể tái cấu trúc", "fact": "Nhộng thường mất khoảng 2 ngày để biến thành muỗi; cả vòng đời trứng → muỗi mất 7–10 ngày.", "goal": 100.0, "unit": "%"},
		{"id": "emerge", "day": 9, "title": "Chui ra khỏi vỏ", "desc": "Nổi lên mặt nước và giữ E 2 giây để vỏ nứt", "fact": "Muỗi chui ra qua vết nứt ở lưng nhộng và đứng trên mặt nước — lúc rất dễ bị ăn.", "goal": 2.0, "unit": "giây"},
	],
	"adultF": [
		{"id": "dry", "day": 10, "title": "Hong khô cánh", "desc": "Đứng yên trên mặt nước cho cánh khô và cứng", "fact": "Muỗi mới nở không bay được ngay: cánh còn mềm và ướt.", "goal": 6.0, "unit": "giây"},
		{"id": "mate", "day": 10, "title": "Tìm bạn tình", "desc": "Bay theo tiếng vỗ cánh của muỗi đực rồi giữ E để giao phối", "fact": "Muỗi cái thường chỉ giao phối một lần, trong vòng 1–2 ngày sau khi vũ hóa.", "goal": 1.0, "unit": ""},
		{"id": "host", "day": 11, "title": "Định vị vật chủ", "desc": "Lại gần một người hoặc con vật (mũi tên đỏ chỉ hướng)", "fact": "Muỗi cái phát hiện CO₂, nhiệt và mùi cơ thể từ xa.", "goal": 1.0, "unit": ""},
		{"id": "blood", "day": 11, "title": "Hút máu", "desc": "Ngắm chấm đỏ vào cơ thể, giữ chuột phải để đậu và hút (cần 40%)", "fact": "Chỉ muỗi cái hút máu, thường sau 2–3 ngày; protein trong máu giúp trứng phát triển.", "goal": 40.0, "unit": "%"},
		{"id": "digest", "day": 12, "title": "Nghỉ ngơi tiêu hóa", "desc": "Bụng nặng nên bay chậm: tìm bụi cây, góc tường hoặc trần nhà, nhấn E để đậu nghỉ 15 giây", "fact": "Sau bữa máu, muỗi cái nghỉ khoảng 2–3 ngày ở nơi kín, mát để tiêu hóa và trứng chín.", "goal": 15.0, "unit": "giây"},
		{"id": "lay", "day": 13, "title": "Đẻ trứng", "desc": "Bay tới nguồn nước tù phù hợp và giữ E để đẻ", "fact": "Muỗi cái đẻ 100–200 trứng mỗi lần (mỗi 3–4 ngày) ở nước tù ít kẻ săn mồi — nơi thế hệ sau sống.", "goal": 1.0, "unit": ""},
	],
	"adultM": [
		{"id": "dry", "day": 10, "title": "Hong khô cánh", "desc": "Đứng yên trên mặt nước cho cánh khô và cứng", "fact": "Muỗi mới nở không bay được ngay: cánh còn mềm và ướt.", "goal": 6.0, "unit": "giây"},
		{"id": "nectar", "day": 10, "title": "Uống mật hoa", "desc": "Giữ E khi ở sát một bông hoa", "fact": "Muỗi đực sống bằng mật hoa và nước đường từ thực vật.", "goal": 25.0, "unit": ""},
		{"id": "swarm", "day": 11, "title": "Tìm đàn", "desc": "Lắng nghe tiếng vỗ cánh, bay tới gần muỗi cái (8 m)", "fact": "Muỗi đực tụ thành đàn ở nơi sáng và nghe tiếng vỗ cánh đặc trưng của muỗi cái.", "goal": 1.0, "unit": ""},
		{"id": "mate", "day": 11, "title": "Giao phối", "desc": "Giữ E khi ở sát muỗi cái", "fact": "Giao phối xong, muỗi đực hoàn thành vai trò truyền gen.", "goal": 1.0, "unit": ""},
	],
}
const GEN_NOTES := {
	1: "Thế hệ 1: học cách sống sót ở nơi đầu tiên",
	2: "Thế hệ 2: con người có thể đổ nước — hãy cảnh giác",
	3: "Thế hệ 3: kẻ săn mồi trở nên nguy hiểm hơn",
	4: "Thế hệ 4: coi chừng hạn hán và thuốc diệt muỗi",
	5: "Thế hệ 5: môi trường biến động mạnh",
}

func q_begin(stage: String) -> void:
	quest_stage = stage
	quests = []
	for d in QDEF.get(stage, []):
		var q: Dictionary = d.duplicate()
		q["prog"] = 0.0
		q["done"] = false
		quests.append(q)

func q_edit(id: String, title: String, desc: String, goal: float, unit: String = "") -> void:
	for q in quests:
		if q["id"] == id:
			q["title"] = title; q["desc"] = desc; q["goal"] = goal; q["unit"] = unit

func q_find(id: String) -> Dictionary:
	for q in quests:
		if q["id"] == id:
			return q
	return {}

func q_active() -> Dictionary:
	for q in quests:
		if not q["done"]:
			return q
	return {}

func q_is_active(id: String) -> bool:
	var a := q_active()
	return not a.is_empty() and a["id"] == id and q_open(a)

func q_done(id: String) -> bool:
	var q := q_find(id)
	return q.is_empty() or q["done"]

func q_all_done() -> bool:
	return q_active().is_empty()

## Chỉ nhiệm vụ đang hiển thị (hiện tại) mới nhận tiến độ.
func q_add(id: String, n: float = 1.0) -> void:
	if not q_is_active(id):
		return
	var q := q_find(id)
	q["prog"] = minf(float(q["goal"]), float(q["prog"]) + n)
	if q["prog"] >= float(q["goal"]) - 1e-6:
		q_complete(q)

func q_set(id: String, value: float) -> void:
	if not q_is_active(id):
		return
	var q := q_find(id)
	q["prog"] = clampf(value, 0.0, float(q["goal"]))
	if q["prog"] >= float(q["goal"]) - 1e-6:
		q_complete(q)

func q_complete(q: Dictionary) -> void:
	q["done"] = true
	q["prog"] = q["goal"]
	G["quests_done"] = int(G.get("quests_done", 0)) + 1
	toasts.append({"text": "Hoàn thành: " + String(q["title"]), "t": 0.0})
	Sfx.beep(660, .12, "sine", .06, 220)
	var nxt := q_active()
	if not nxt.is_empty():
		toasts.append({"text": ("Nhiệm vụ mới: " if q_open(nxt) else "Ngày %d: " % int(nxt.get("day", 0))) + String(nxt["title"]), "t": -.4})

func q_force_all() -> void:
	for q in quests:
		if not q["done"]:
			q["done"] = true
			q["prog"] = q["goal"]
	G["quests_done"] = int(G.get("quests_done", 0))

func q_bonus() -> float:
	return minf(1.6, 1.0 + .04 * float(G.get("quests_done", 0)))

func gen_note() -> String:
	var g: int = L.get("gen", 1)
	return GEN_NOTES.get(g, "Thế hệ %d: dòng họ tiếp tục thích nghi" % g)
