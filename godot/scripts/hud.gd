extends CanvasLayer
## HUD vẽ bằng lệnh: mỗi khung hình các màn gọi begin() → text()/bar()/... → end().

const W := 1280.0
const H := 720.0
var ctl: Control
var cmds: Array = []
var font: Font
var banner_t := 99.0
var banner_title := ""
var banner_sub := ""
var flash_c := Color.WHITE
var flash_t := 0.0
var flash_d := 1.0

func _ready() -> void:
	layer = 10
	ctl = Control.new()
	ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	add_child(ctl)
	font = ThemeDB.fallback_font
	ctl.draw.connect(_on_draw)

func flash(c: Color, d: float = .6) -> void:
	flash_c = c
	flash_t = d
	flash_d = d

func _process(dt: float) -> void:
	flash_t = maxf(0.0, flash_t - dt)

func banner(t: String, s: String) -> void:
	banner_t = 0.0
	banner_title = t
	banner_sub = s

func begin() -> void:
	cmds.clear()

func draw_banner(dt: float) -> void:
	banner_t += dt
	if banner_t > 3.8:
		return
	var a := clampf(banner_t / .4, 0.0, 1.0) if banner_t < 3.0 else clampf((3.8 - banner_t) / .8, 0.0, 1.0)
	var lines := _wrap(banner_sub, 100)
	rect(Vector2(0, 190), Vector2(W, 96.0 + lines.size() * 26.0), Color(0, 0, 0, .58 * a))
	text(banner_title, Vector2(W / 2, 226), 40, Color(1, 1, 1, a), 1)
	var by := 272.0
	for ln in lines:
		text(String(ln), Vector2(W / 2, by), 20, Color(1, .91, .66, a), 1)
		by += 26.0

func _wrap(s: String, n: int) -> Array:
	var out: Array = []
	var line := ""
	for w in s.split(" "):
		if line.length() + w.length() + 1 > n and line != "":
			out.append(line)
			line = w
		else:
			line = w if line == "" else line + " " + w
	if line != "":
		out.append(line)
	return out

func draw_quests(y0: float = 190.0) -> void:
	if Game.quests.is_empty():
		return
	var total: int = Game.quests.size()
	var done_n := 0
	for q in Game.quests:
		if q["done"]:
			done_n += 1
	var cur: Dictionary = Game.q_active()
	var fact_lines: Array = _wrap(String(cur.get("fact", "")), 50) if not cur.is_empty() else []
	var desc_lines: Array = _wrap(String(cur.get("desc", "")), 44) if not cur.is_empty() else []
	var shown_done := mini(done_n, 3)
	var hgt := 34.0 + shown_done * 19.0 + (84.0 + desc_lines.size() * 16.0 + fact_lines.size() * 14.0 if not cur.is_empty() else 24.0)
	panel(Vector2(14, y0 - 6), Vector2(392, hgt), Color(.078, .149, .122, .8))
	text("NHIỆM VỤ  %d/%d  —  %s" % [mini(done_n + 1, total), total, String(Game.STAGE_NAMES.get(Game.quest_stage.trim_suffix("F").trim_suffix("M"), ""))], Vector2(28, y0 + 12), 15, Color(.91, .84, .71))
	var y := y0 + 36.0
	var k := 0
	for q in Game.quests:
		if q["done"]:
			k += 1
			if k > done_n - shown_done:
				text("[x] " + String(q["title"]), Vector2(28, y), 14, Color(.55, .9, .6, .85))
				y += 19.0
	if cur.is_empty():
		text("Đã hoàn thành mọi nhiệm vụ giai đoạn này", Vector2(28, y + 4), 15, Color(.7, 1, .75))
		return
	var waiting: bool = not Game.q_open(cur)
	text(String(cur["title"]), Vector2(28, y + 6), 19, Color(.8, .8, .75) if waiting else Color(.93, .88, .75))
	y += 30.0
	if waiting:
		text("Mở vào NGÀY %d — còn khoảng %d giây" % [int(cur["day"]), int(ceil(Game.q_wait_seconds(cur)))], Vector2(28, y), 15, Color(1, .82, .45))
		y += 22.0
		for ln in fact_lines:
			text(String(ln), Vector2(28, y), 12, Color(.62, .85, .8))
			y += 14.0
		return
	for ln in desc_lines:
		text(String(ln), Vector2(28, y), 14, Color(.9, .94, .98))
		y += 16.0
	var goal: float = cur["goal"]
	var prog: float = cur["prog"]
	var unit: String = cur["unit"]
	var ptxt := "%d/%d %s" % [int(prog), int(goal), unit] if goal <= 12.0 else "%d%%" % int(prog / goal * 100.0)
	rect(Vector2(28, y + 4), Vector2(300, 7), Color(1, 1, 1, .16))
	rect(Vector2(28, y + 4), Vector2(300.0 * clampf(prog / goal, 0.0, 1.0), 7), Color(.85, .64, .36))
	text(ptxt, Vector2(392, y + 9), 14, Color(.85, .92, 1), 2)
	y += 24.0
	for ln in fact_lines:
		text(String(ln), Vector2(28, y), 12, Color(.62, .85, .8))
		y += 14.0

func draw_toasts(dt: float) -> void:
	var y := 78.0
	for t in Game.toasts:
		t["t"] += dt
		var a := clampf(minf(t["t"] / .25, (3.0 - t["t"]) / .5), 0.0, 1.0)
		panel(Vector2(W / 2 - 190, y - 18 + (1.0 - a) * -12.0), Vector2(380, 34), Color(.1, .3, .15, .85 * a))
		text(String(t["text"]), Vector2(W / 2, y + 2 - (1.0 - a) * 12.0), 19, Color(.75, 1, .8, a), 1)
		y += 40.0
	Game.toasts = Game.toasts.filter(func(t): return t["t"] < 3.0)

func end() -> void:
	if flash_t > 0.0:
		rect(Vector2.ZERO, Vector2(W, H), Color(flash_c.r, flash_c.g, flash_c.b, .8 * pow(flash_t / flash_d, 1.6)))
	ctl.queue_redraw()

func text(s: String, pos: Vector2, size: int = 20, col: Color = Color(.93, .91, .85), align: int = 0, bold: bool = false) -> void:
	cmds.append({"t": "text", "s": s, "p": pos, "sz": size, "c": col, "a": align, "b": bold})

func rect(pos: Vector2, size: Vector2, col: Color) -> void:
	cmds.append({"t": "rect", "p": pos, "s": size, "c": col})

func circle(pos: Vector2, r: float, col: Color) -> void:
	cmds.append({"t": "circle", "p": pos, "r": r, "c": col})

func line(a: Vector2, b: Vector2, col: Color, w: float = 2.0) -> void:
	cmds.append({"t": "line", "a": a, "b": b, "c": col, "w": w})

func poly(pts: PackedVector2Array, col: Color) -> void:
	cmds.append({"t": "poly", "pts": pts, "c": col})

func panel(pos: Vector2, size: Vector2, col: Color = Color(0.078, 0.149, 0.122, 0.8)) -> void:
	cmds.append({"t": "panel", "p": pos, "s": size, "c": col})

func bar(pos: Vector2, w: float, h: float, v: float, col: Color, label: String = "") -> void:
	cmds.append({"t": "panel", "p": pos, "s": Vector2(w, h), "c": Color(0, 0, 0, .5), "r": h / 2.0})
	cmds.append({"t": "panel", "p": pos, "s": Vector2(max(h, w * clamp(v, 0.0, 1.0)), h), "c": col, "r": h / 2.0})
	if label != "":
		text(label, pos + Vector2(10, h * .5 + 5), int(h - 5), Color.WHITE, 0)

func image(tex: Texture2D, dst: Rect2, src: Rect2, col: Color = Color.WHITE) -> void:
	cmds.append({"t": "img", "tex": tex, "d": dst, "s": src, "c": col})

func vignette(col: Color) -> void:
	cmds.append({"t": "vig", "c": col})

func _on_draw() -> void:
	for c in cmds:
		match c["t"]:
			"rect":
				ctl.draw_rect(Rect2(c["p"], c["s"]), c["c"])
			"panel":
				var sb := StyleBoxFlat.new()
				sb.bg_color = c["c"]
				var r: float = c.get("r", 12.0)
				sb.set_corner_radius_all(int(r))
				ctl.draw_style_box(sb, Rect2(c["p"], c["s"]))
			"img":
				ctl.draw_texture_rect_region(c["tex"], c["d"], c["s"], c["c"])
			"circle":
				ctl.draw_circle(c["p"], c["r"], c["c"])
			"line":
				ctl.draw_line(c["a"], c["b"], c["c"], c["w"])
			"poly":
				ctl.draw_colored_polygon(c["pts"], c["c"])
			"vig":
				var col: Color = c["c"]
				for i in 6:
					var a := col.a * (float(i) / 6.0) * 0.5
					var m := 90.0 * (6 - i)
					ctl.draw_rect(Rect2(0, 0, W, 60 + (5 - i) * 10), Color(col.r, col.g, col.b, a * 0.4))
					ctl.draw_rect(Rect2(0, H - 60 - (5 - i) * 10, W, 60 + (5 - i) * 10), Color(col.r, col.g, col.b, a * 0.4))
					ctl.draw_rect(Rect2(0, 0, 60 + (5 - i) * 10, H), Color(col.r, col.g, col.b, a * 0.4))
					ctl.draw_rect(Rect2(W - 60 - (5 - i) * 10, 0, 60 + (5 - i) * 10, H), Color(col.r, col.g, col.b, a * 0.4))
					if m < 0: pass
			"text":
				var s: String = c["s"]
				var sz: int = c["sz"]
				var p: Vector2 = c["p"]
				var al := HORIZONTAL_ALIGNMENT_LEFT
				var w := -1.0
				if c["a"] == 1:
					al = HORIZONTAL_ALIGNMENT_CENTER; p.x -= 1500.0; w = 3000.0
				elif c["a"] == 2:
					al = HORIZONTAL_ALIGNMENT_RIGHT; p.x -= 3000.0; w = 3000.0
				p.y += sz * 0.35
				ctl.draw_string_outline(font, p, s, al, w, sz, 5, Color(0, 0, 0, .6 * (c["c"] as Color).a))
				ctl.draw_string(font, p, s, al, w, sz, c["c"])
