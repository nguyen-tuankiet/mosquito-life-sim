class_name StartMenu
extends RefCounted
## Màn hình bắt đầu (hiện trước phần story): nền hoàng hôn + logo + nút BẮT ĐẦU / GIỚI THIỆU,
## trang Giới thiệu (ảnh nguyên bản) và con trỏ chuột là con muỗi đang bay.

const W := 1280.0
const H := 720.0
const GOLD := Color(1, .86, .5)
## Trang giới thiệu: ảnh 1168x784 vừa chiều cao màn hình; các nút nằm sẵn trong ảnh (toạ độ ảnh gốc).
const ABOUT_SIZE := Vector2(1168, 784)
const ABOUT_GO := Rect2(340, 645, 320, 72)
const ABOUT_BACK := Rect2(680, 645, 255, 72)

var page := "home"   # "home" | "about"
var has_save := false   # có file lưu → hiện nút TIẾP TỤC
var _tex: Dictionary = {}
var _prev := Vector2(-1, -1)
var _vel := Vector2.ZERO
var _face := 1.0
var _tilt := 0.0

func _t(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]

## Vị trí các nút trang chủ: 2 nút (mới/giới thiệu) hoặc 3 nút khi có bản lưu.
func _rects() -> Dictionary:
	if has_save:
		return {"continue": Rect2(W / 2 - 190, 440, 380, 56), "start": Rect2(W / 2 - 190, 506, 380, 56), "about": Rect2(W / 2 - 190, 572, 380, 56)}
	return {"start": Rect2(W / 2 - 190, 470, 380, 66), "about": Rect2(W / 2 - 190, 552, 380, 66)}

func reset() -> void:
	page = "home"
	_prev = Vector2(-1, -1)

# ───────── điều khiển ─────────
## Trả về "start" (game mới), "continue" (chơi tiếp bản lưu) hoặc "".
func click(mouse: Vector2) -> String:
	if page == "home":
		var rc := _rects()
		if rc.has("continue") and (rc["continue"] as Rect2).has_point(mouse): return "continue"
		if (rc["start"] as Rect2).has_point(mouse): return "start"
		if (rc["about"] as Rect2).has_point(mouse):
			page = "about"
	else:
		if _about_rect(ABOUT_GO).has_point(mouse): return "start"
		if _about_rect(ABOUT_BACK).has_point(mouse):
			page = "home"
	return ""

func _about_scale() -> float:
	return H / ABOUT_SIZE.y

func _about_rect(r: Rect2) -> Rect2:
	var s := _about_scale()
	var ox := (W - ABOUT_SIZE.x * s) / 2.0
	return Rect2(ox + r.position.x * s, r.position.y * s, r.size.x * s, r.size.y * s)

# ───────── vẽ ─────────
func draw(hud: CanvasLayer, t: float, mouse: Vector2) -> void:
	var a := smoothstep(0.0, .8, t)
	if page == "home":
		_home(hud, t, a, mouse)
	else:
		_about(hud, mouse)
	_cursor(hud, t, mouse)

func _home(hud: CanvasLayer, t: float, a: float, mouse: Vector2) -> void:
	var bg := _t("res://assets/ui/title_bg.jpg")
	hud.rect(Vector2.ZERO, Vector2(W, H), Color(.05, .04, .03))
	if bg != null:
		hud.image(bg, Rect2(0, 0, W, H), Rect2(0, 0, bg.get_width(), bg.get_height()), Color(1, 1, 1, a))
	# phủ tối nhẹ đỉnh và đáy để logo/nút nổi
	for i in 8:
		var f := float(i) / 8.0
		hud.rect(Vector2(0, i * 14.0), Vector2(W, 14), Color(.1, .05, .02, .38 * (1.0 - f) * a))
		hud.rect(Vector2(0, H - 190 + i * 24.0), Vector2(W, 24), Color(.1, .05, .02, .5 * f * a))
	var logo := _t("res://assets/ui/logo.png")
	if logo != null:
		var lw := 640.0
		var lh := lw * logo.get_height() / logo.get_width()
		var lp := Vector2((W - lw) / 2.0, 36.0 + sin(t * 1.2) * 3.0)
		var src := Rect2(0, 0, logo.get_width(), logo.get_height())
		for o in [Vector2(3, 4), Vector2(-2, 3), Vector2(2, -2), Vector2(0, 6)]:
			hud.image(logo, Rect2(lp + o, Vector2(lw, lh)), src, Color(.12, .05, .0, .55 * a))
		hud.image(logo, Rect2(lp, Vector2(lw, lh)), src, Color(1, 1, 1, a))
	var rc := _rects()
	if rc.has("continue"):
		_button(hud, rc["continue"], "TIẾP TỤC HÀNH TRÌNH", a, mouse, true)
	_button(hud, rc["start"], "BẮT ĐẦU GAME MỚI" if has_save else "BẮT ĐẦU GAME", a, mouse, not has_save)
	_button(hud, rc["about"], "GIỚI THIỆU", a, mouse, false)
	hud.text("Bạn không chơi một con muỗi... Bạn chơi cả một dòng họ.", Vector2(W / 2, 664), 19, Color(1, .95, .85, .95 * a), 1)
	hud.text("Kỷ lục: %d thế hệ" % Game.best, Vector2(W - 24, H - 18), 15, Color(1, .95, .85, .8 * a), 2)

func _button(hud: CanvasLayer, r: Rect2, label: String, a: float, mouse: Vector2, primary: bool) -> void:
	var over := r.has_point(mouse)
	var glow := (.22 if over else .0) + (.08 if primary else .0)
	hud.panel(r.position - Vector2(4, 4), r.size + Vector2(8, 8), Color(GOLD.r, GOLD.g, GOLD.b, (.25 + glow) * a))
	hud.panel(r.position, r.size, Color(.2, .1, .04, .92 * a) if not over else Color(.36, .2, .08, .95 * a))
	hud.panel(r.position + Vector2(3, 3), r.size - Vector2(6, 6), Color(.12, .06, .02, .55 * a), 10.0)
	var tc := Color(1, .93, .72, a) if over else Color(.98, .84, .5, a)
	hud.text(label, r.get_center() + Vector2(0, 1), 28 if r.size.y > 60 else 24, tc, 1, true)

func _about(hud: CanvasLayer, mouse: Vector2) -> void:
	var img := _t("res://assets/ui/about.jpg")
	hud.rect(Vector2.ZERO, Vector2(W, H), Color(.04, .03, .02))
	if img == null:
		return
	var s := _about_scale()
	var iw := ABOUT_SIZE.x * s
	var ox := (W - iw) / 2.0
	var full := Rect2(0, 0, img.get_width(), img.get_height())
	# hai dải bên: kéo giãn cột mép ảnh (không lặp chữ) và làm tối cho liền mạch
	var edge := 6.0
	hud.image(img, Rect2(0, 0, ox + 1, H), Rect2(0, 0, edge, img.get_height()), Color(.55, .5, .45, 1))
	hud.image(img, Rect2(ox + iw - 1, 0, W - ox - iw + 1, H), Rect2(img.get_width() - edge, 0, edge, img.get_height()), Color(.55, .5, .45, 1))
	hud.image(img, Rect2(ox, 0, iw, H), full)
	for r in [ABOUT_GO, ABOUT_BACK]:
		var rr := _about_rect(r)
		if rr.has_point(mouse):
			hud.panel(rr, Color(GOLD.r, GOLD.g, GOLD.b, .2), 14.0)

# ───────── con trỏ: muỗi đang bay ─────────

func _cursor(hud: CanvasLayer, t: float, mouse: Vector2) -> void:
	if _prev.x < 0.0:
		_prev = mouse
	var v := mouse - _prev
	_prev = mouse
	_vel = _vel.lerp(v, .25)
	if absf(_vel.x) > .8:
		_face = lerpf(_face, signf(_vel.x), .35)
	_tilt = lerpf(_tilt, clampf(_vel.y * .03, -.5, .5) * _face, .2)
	var bob := Vector2(sin(t * 9.0) * 1.5, cos(t * 7.0) * 2.0)
	var p := mouse + bob
	var f := _face
	var rot := _tilt
	var k := 2.2   # phóng to để thấy rõ
	var rp := func(q: Vector2) -> Vector2:   # toạ độ cục bộ (mặt hướng +x) → màn hình
		var x := q.x * f * k
		var y := q.y * k
		return p + Vector2(x * cos(rot) - y * sin(rot), x * sin(rot) + y * cos(rot))
	var ink := Color(.07, .06, .05, 1)
	# chân
	for i in 3:
		var lx := -3.0 + i * 4.5
		var sway := sin(t * 6.0 + i) * 2.0
		hud.line(rp.call(Vector2(lx, 4)), rp.call(Vector2(lx - 4, 12 + sway)), ink, 1.8)
		hud.line(rp.call(Vector2(lx - 4, 12 + sway)), rp.call(Vector2(lx - 7, 20 + sway)), ink, 1.5)
	# cánh: hai cánh mảnh hướng ra sau-lên, vỗ bằng cách quay quanh gốc cánh
	var fl := sin(t * 60.0)
	var wc := Color(.9, .96, 1, .55)
	for w in 2:
		var ang := .75 + w * .35 + fl * .45
		var d := Vector2(-cos(ang), -sin(ang))
		var base := Vector2(-.5, -2.5)
		hud.poly(_ell_t(rp, base + d * 9.0, 9.0, 2.0, atan2(d.y, d.x)), Color(wc.r, wc.g, wc.b, wc.a - w * .15))
	# thân: bụng (có vằn sáng), ngực, đầu, vòi, râu
	hud.poly(_ell_t(rp, Vector2(-9, 2.5), 8.5, 2.7, .3), ink)
	for i in 3:
		hud.line(rp.call(Vector2(-12.0 + i * 3.2, .6 + i * .4)), rp.call(Vector2(-12.0 + i * 3.2, 4.8 + i * .4)), Color(.85, .85, .8, .9), 1.2)
	hud.circle(rp.call(Vector2(-.5, 0)), 3.6, ink)
	hud.circle(rp.call(Vector2(5, -.5)), 2.6, ink)
	hud.line(rp.call(Vector2(7, 0)), rp.call(Vector2(15, 2.5)), ink, 1.6)
	hud.line(rp.call(Vector2(6, -2)), rp.call(Vector2(10, -6.5)), ink, 1.2)

## Elip cục bộ qua rp (rp: Callable chuyển toạ độ); k<1 co bán kính tạo vằn sáng.
func _ell_t(rp: Callable, c: Vector2, rx: float, ry: float, ang: float, k: float = 1.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 14
	for i in n:
		var u := TAU * i / n
		var q := Vector2(cos(u) * rx * k, sin(u) * ry * k)
		pts.append(rp.call(c + Vector2(q.x * cos(ang) - q.y * sin(ang), q.x * sin(ang) + q.y * cos(ang))))
	return pts

# ───────── menu tạm dừng ─────────
const PAUSE_ITEMS := [["resume", "TIẾP TỤC"], ["menu", "LƯU & VỀ MENU CHÍNH"], ["quit", "LƯU & THOÁT GAME"]]

func _pause_rect(i: int) -> Rect2:
	return Rect2(W / 2 - 190, 262 + i * 70.0, 380, 58)

func pause_click(mouse: Vector2) -> String:
	for i in PAUSE_ITEMS.size():
		if _pause_rect(i).has_point(mouse):
			return PAUSE_ITEMS[i][0]
	return ""

func draw_pause(hud: CanvasLayer, t: float, mouse: Vector2) -> void:
	hud.rect(Vector2.ZERO, Vector2(W, H), Color(.02, .015, .01, .62))
	hud.panel(Vector2(W / 2 - 240, 170), Vector2(480, 370), Color(.1, .06, .03, .94))
	hud.panel(Vector2(W / 2 - 236, 174), Vector2(472, 362), Color(.16, .09, .04, .5), 14.0)
	hud.text("TẠM DỪNG", Vector2(W / 2, 214), 38, GOLD, 1, true)
	for i in PAUSE_ITEMS.size():
		_button(hud, _pause_rect(i), PAUSE_ITEMS[i][1], 1.0, mouse, i == 0)
	hud.text("P hoặc Esc: tiếp tục  ·  tiến trình được tự động lưu", Vector2(W / 2, 506), 14, Color(1, .95, .85, .75), 1)
	_cursor(hud, t, mouse)
