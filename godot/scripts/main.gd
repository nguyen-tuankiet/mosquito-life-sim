extends Node
## Điều phối: màn hình, giai đoạn, chết/hồi sinh, chuyển thế hệ. Có chế độ chụp ảnh để kiểm thử.

const W := 1280.0
const H := 720.0

var hud: CanvasLayer
var aquatic: Node3D
var adult: Node3D
var mode := "title"
var paused := false
var dead := false
var dead_t := 0.0
var cause := ""
var summary: Dictionary = {}
var t := 0.0
var title_cam: Camera3D

# kiểm thử
var shot_path := ""
var shot_frames := 0
var scenario := ""
var frame_i := 0
var forced_sex := ""
var start_adult := false

func _ready() -> void:
	hud = preload("res://scripts/hud.gd").new()
	add_child(hud)
	aquatic = preload("res://scripts/aquatic.gd").new()
	aquatic.hud_ref = hud
	add_child(aquatic)
	adult = preload("res://scripts/adult.gd").new()
	adult.hud_ref = hud
	add_child(adult)
	aquatic.visible = false
	adult.visible = false
	adult.died.connect(_on_died)
	adult.finished.connect(_on_adult_finished)
	aquatic.died.connect(_on_died)
	aquatic.advance.connect(_on_aquatic_advance)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="): shot_path = a.substr(7)
		elif a.begins_with("--frames="): shot_frames = int(a.substr(9))
		elif a.begins_with("--scenario="): scenario = a.substr(11)
		elif a.begins_with("--sex="): forced_sex = a.substr(6)
		elif a == "--start=adult": start_adult = true
		elif a.begins_with("--dayscale="): Game.day_scale = float(a.substr(11))
	if scenario == "auto" or (scenario.begins_with("test_") and scenario != "test_quests"):
		Game.gate_days = false
	title_cam = Camera3D.new()
	add_child(title_cam)
	title_cam.make_current()
	if scenario == "bake":
		var t0 := Time.get_ticks_msec()
		for nm in ["man", "woman", "hoodie"]:
			Assets.upgrade_skinned(Assets.model(nm, 1.0), nm, "human")
		for nm in ["dog", "cat", "cow", "mouse", "pigeon"]:
			Assets.upgrade_skinned(Assets.model(nm, 1.0), nm, "animal")
		print("[bake] xong trong ", Time.get_ticks_msec() - t0, " ms")
		get_tree().quit()
		return
	if scenario == "phsizes":
		for nm in ["Barrel_01", "Barrel_02", "wooden_bucket_01", "wooden_bucket_02", "plastic_container", "ceramic_pot", "planter_pot_clay", "old_tyre", "modular_wooden_pier", "shrub_01", "shrub_02", "grass_medium_01", "fern_02", "island_tree_01", "island_tree_02", "island_tree_03", "jacaranda_tree", "tree_small_02", "rock_07", "boulder_01", "stone_01", "tree_stump_01", "pachira_aquatica_01", "modular_electricity_poles", "wooden_picnic_table", "jug_01", "weed_plant_02", "nettle_plant"]:
			var n := Assets.scene(nm).instantiate() as Node3D
			add_child(n)
			print("PHS ", nm, " ", Assets.aabb_of(n).size)
		get_tree().quit()
		return
	if scenario == "chickinfo":
		var n := Assets.scene("chicken").instantiate() as Node3D
		add_child(n)
		var ap := Assets.find_ap(n)
		print("CH ap=", ap, " anims=", ap.get_animation_list() if ap else [])
		print("CH aabb=", Assets.aabb_of(n))
		for c in n.find_children("*", "Node3D", true, false):
			print("CH node ", c.name, " ", c.get_class())
		get_tree().quit()
		return
	if scenario == "mosqinfo":
		var n := Bio.make_mosquito("F")
		add_child(n)
		for c in n.get_children():
			var a := Assets.aabb_of(c) if c is Node3D and not (c is MeshInstance3D) else AABB()
			print("MQ ", c.name, " ", c.get_class(), " pos=", (c as Node3D).position, " rot=", (c as Node3D).rotation_degrees, " mesh_aabb=", (c as MeshInstance3D).get_aabb() if c is MeshInstance3D else a)
		print("MQ total ", Assets.aabb_of(n))
		get_tree().quit()
		return
	if scenario == "boneinfo":
		var n := Assets.scene("man").instantiate() as Node3D
		add_child(n)
		for sk in n.find_children("*", "Skeleton3D", true, false):
			var names := []
			for i in (sk as Skeleton3D).get_bone_count():
				names.append((sk as Skeleton3D).get_bone_name(i) + "<" + str((sk as Skeleton3D).get_bone_parent(i)) + ">")
			print("BONES ", names)
		get_tree().quit()
		return
	if scenario == "sizes":
		for nm in ["pupa", "mosq", "egg", "larva"]:
			var n: Node3D = {"pupa": Bio.make_pupa(), "mosq": Bio.make_mosquito("F"), "egg": Bio.make_egg(false), "larva": Bio.make_larva(0, Color.WHITE)}[nm]
			add_child(n)
			print("SIZE ", nm, " ", Assets.aabb_of(n).size)
		get_tree().quit()
		return
	if scenario == "intro":
		mode = "intro"
		intro_t = float(OS.get_environment("INTRO_T")) if OS.get_environment("INTRO_T") != "" else 0.0
	elif scenario != "":
		_setup_scenario()
	elif not start_adult:
		mode = "intro"
	elif start_adult:
		Game.new_lineage()
		Game.L["sex"] = "F"
		Game.L["site"] = 2
		Game.new_generation_stats()
		Game.G["dayf"] = 9.0
		Game.G["build"] = "explorer"
		_on_aquatic_advance("adult")

# ═════════════ luồng chơi ═════════════
func start_game() -> void:
	Game.new_lineage()
	begin_generation()

func begin_generation() -> void:
	if forced_sex != "": Game.L["sex"] = forced_sex
	Game.new_generation_stats()
	enter_stage("egg", false)

func enter_stage(st: String, resp: bool) -> void:
	mode = st
	dead = false
	if st == "adult":
		aquatic.leave()
		adult.enter(resp)
	else:
		adult.leave()
		aquatic.enter(st, resp)

func _on_aquatic_advance(next: String) -> void:
	if next == "larva":
		hud.banner("TRỨNG ĐÃ NỞ — LĂNG QUĂNG", "Nắp trứng bật ra ở đầu dưới, ấu trùng chui xuống nước; vỏ trứng rỗng còn nổi trên mặt. " + String(Game.STAGE_FACT["larva"]))
		enter_stage("larva", false)
	elif next == "pupa":
		Game.choose_build()
		hud.banner("HÓA NHỘNG — " + String(Game.BUILDS[Game.G["build"]]["name"]).to_upper(), "Lăng quăng lột lớp da cuối cùng để lộ ra nhộng. " + String(Game.STAGE_FACT["pupa"]))
		enter_stage("pupa", false)
	elif next == "adult":
		enter_stage("adult", false)
		var w: String = Game.L["weather"]
		var wtxt: String = {"drought": "Hạn hán — nước cạn dần", "rain": "Trời mưa", "normal": "Trời quang"}[w]
		hud.banner("VŨ HÓA — MUỖI %s (%s)" % ["ĐỰC" if Game.L["sex"] == "M" else "CÁI", String(Game.BUILDS[Game.G["build"]]["name"]).to_upper()],
			"Vỏ nhộng nứt ở lưng, muỗi chui ra và đứng trên mặt nước tại \"%s\" chờ cánh khô.  ·  %s" % [Game.SITES[Game.L["site"]]["name"], wtxt])

func _on_died(c: String) -> void:
	if dead:
		return
	dead = true
	dead_t = 0.0
	cause = c

func _resolve_death() -> void:
	mode = "over"
	adult.leave()
	aquatic.leave()
	Game.save_best()
	title_cam.make_current()

func _on_adult_finished(eggs: int, site: int) -> void:
	summary = Game.finish_generation(eggs, site)
	mode = "summary"
	adult.leave()
	title_cam.make_current()

# ═════════════ vòng lặp ═════════════
func _process(dt: float) -> void:
	t += dt
	frame_i += 1
	if Input.is_action_just_pressed("mute"):
		Sfx.muted = not Sfx.muted
	if Input.is_action_just_pressed("pause") and mode in ["egg", "larva", "pupa", "adult"]:
		paused = not paused
		get_tree().paused = false
	var confirm := Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("up") or Input.is_action_just_pressed("act") or _clicked()
	hud.begin()
	if scenario == "adult_feed" and frame_i == 45:
		for hh in adult.hosts:
			if hh.k == "mom":
				print("FEEDDBG2 mosq=", adult.body.global_position, " mode=", adult.pl["mode"], " torso=", hh.rig.bone_pos("Torso"), " away=", hh.away, " tgt=", adult.pl["tgt_name"])
	if scenario == "adult_feed" and frame_i == 20:
		var fh: AdultWorld.Host = null
		for hh in adult.hosts:
			if hh.human and hh.k == "mom":
				fh = hh
		var spot_i := int(OS.get_environment("FEED_SPOT")) if OS.get_environment("FEED_SPOT") != "" else 1
		adult.body.global_position = Vector3(fh.pos.x, 1.2, fh.pos.y + 1.0)
		print("FEEDDBG pos=", fh.pos, " sitting=", fh.sitting, " torso=", fh.rig.bone_pos("Torso"), " neck=", fh.rig.bone_pos("Neck"), " head=", fh.rig.bone_pos("Head"), " node=", fh.node.global_position)
		for e in adult.bite_spots(fh, Vector3(0, 0, 1)):
			print("FEEDDBG spot ", e["name"], e["pos"], e["nrm"])
		Input.action_press("feed")
		adult.debug_land(fh, spot_i)
		var fn: Vector3 = adult.pl["tgt_nrm"]
		adult.view_yaw = atan2(fn.x, fn.z) + 1.2
		adult.view_pitch = -.05
		adult.debug_cam_dist = .3
	if scenario == "auto":
		_auto(dt)
	elif scenario == "test_rules":
		_test_rules(dt)
	elif scenario.begins_with("test_dodge"):
		_test_dodge(dt)
	elif scenario == "test_aim":
		_test_aim(dt)
	elif scenario == "test_move":
		_test_move(dt)
	elif scenario == "test_quests":
		_test_quests(dt)
	elif scenario.begins_with("adult") and scenario != "adult_wind" and adult.active:
		for h in adult.hosts: h.alert = 0.0
		adult.pl["energy"] = 100.0
	if not paused:
		match mode:
			"intro":
				_update_intro(dt, confirm)
			"title":
				if confirm: start_game()
			"summary":
				summary["t"] += dt
				if summary["t"] > .6 and confirm:
					Game.advance_generation(summary)
					begin_generation()
			"over":
				if confirm: start_game()
			"egg", "larva", "pupa":
				aquatic.update(dt)
				if dead:
					dead_t += dt
					if dead_t > 2.2: _resolve_death()
			"adult":
				adult.update(dt)
				if dead:
					dead_t += dt
					if dead_t > 2.2: _resolve_death()
	_draw_mode()
	hud.draw_banner(dt if not paused else 0.0)
	if mode in ["egg", "larva", "pupa", "adult"]:
		hud.draw_toasts(dt if not paused else 0.0)
	if dead and mode in ["egg", "larva", "pupa", "adult"]:
		hud.rect(Vector2.ZERO, Vector2(W, H), Color(.12, 0, 0, .5))
		hud.text("MẤT: " + cause, Vector2(W / 2, H / 2 - 18), 34, Color.WHITE, 1)
		hud.text("Vòng đời của bạn kết thúc ở ngày %d…" % Game.day_no(), Vector2(W / 2, H / 2 + 30), 22, Color(1, .91, .66), 1)
	if Sfx.muted:
		hud.text("TẮT ÂM", Vector2(W - 20, H - 20), 15, Color.WHITE, 2)
	if paused:
		hud.rect(Vector2.ZERO, Vector2(W, H), Color(0, 0, 0, .6))
		hud.text("TẠM DỪNG — nhấn P để tiếp tục", Vector2(W / 2, H / 2), 36, Color.WHITE, 1)
	if OS.get_environment("NOHUD") != "":
		hud.cmds.clear()
		for lb in (adult.site_labels if adult.cam != null else []):
			(lb as Label3D).visible = false
	if OS.get_environment("NOHUD") != "" and aquatic.active:
		for pr in aquatic.preds:
			pr.node.visible = false
	if frame_i == 2 and OS.get_environment("FOV") != "":
		if adult.cam != null: adult.cam.fov = float(OS.get_environment("FOV"))
		if aquatic.cam != null: aquatic.cam.fov = float(OS.get_environment("FOV"))
	if frame_i == 2 and OS.get_environment("DOFD") != "":
		var dd := float(OS.get_environment("DOFD"))
		for cm in [adult.cam, aquatic.cam]:
			if cm != null:
				var ca := CameraAttributesPractical.new()
				ca.dof_blur_far_enabled = true
				ca.dof_blur_far_distance = dd
				ca.dof_blur_far_transition = dd * 2.0
				ca.dof_blur_amount = .1
				(cm as Camera3D).attributes = ca
	if frame_i == 2 and OS.get_environment("CAMD") != "":
		adult.debug_cam_dist = float(OS.get_environment("CAMD"))
		aquatic.debug_cam_dist = float(OS.get_environment("CAMD"))
	if frame_i == 2 and OS.get_environment("PITCH") != "":
		adult.view_pitch = float(OS.get_environment("PITCH"))
		aquatic.view_pitch = float(OS.get_environment("PITCH"))
	if frame_i == 2 and OS.get_environment("YAW") != "":
		adult.view_yaw = float(OS.get_environment("YAW"))
		aquatic.view_yaw = float(OS.get_environment("YAW"))
	if frame_i == 2 and OS.get_environment("HOFF") != "":
		if adult.cam != null: adult.cam.h_offset = float(OS.get_environment("HOFF"))
		if aquatic.cam != null: aquatic.cam.h_offset = float(OS.get_environment("HOFF"))
	hud.end()
	if shot_path != "" and frame_i >= shot_frames:
		_save_shot()

var _click := false
func _input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_click = true

func _clicked() -> bool:
	var c := _click
	_click = false
	return c

func _draw_mode() -> void:
	match mode:
		"intro": _draw_intro()
		"title": _draw_title()
		"summary": _draw_summary()
		"over": _draw_over()
		"adult": adult.draw_hud(hud)
		_: aquatic.draw_hud(hud)


# ═════════════ STORY GIỚI THIỆU (các tranh minh họa từng giai đoạn → cuối cùng infographic tổng quát) ═════════════
## [ảnh, "", "", [], tiêu điểm (0..1), zoom đầu, zoom cuối, thời lượng]
const SLIDES := [
	["egg", "", "", [], Vector2(.5, .62), 1.0, 1.0, 8.0],
	["larva", "", "", [], Vector2(.5, .55), 1.0, 1.0, 8.0],
	["pupa", "", "", [], Vector2(.5, .4), 1.0, 1.0, 8.0],
	["adult", "", "", [], Vector2(.5, .45), 1.0, 1.0, 8.0],
	["sex", "", "", [], Vector2(.3, .35), 1.0, 1.0, 8.0],
	["mating", "", "", [], Vector2(.5, .5), 1.0, 1.0, 8.0],
	["lay", "", "", [], Vector2(.5, .5), 1.0, 1.0, 8.0],
	["cycle", "", "", [], Vector2(.5, .5), 1.0, 1.0, 8.0],
	["overview", "", "", [], Vector2(.5, .5), 1.0, 1.0, 0.0],
]
var intro_t := 0.0
var intro_tex: Dictionary = {}
var intro_step_last := -1
const INTRO_FADE := 1.2

func _itex(name: String) -> Texture2D:
	if not intro_tex.has(name):
		intro_tex[name] = load("res://assets/ui/p_%s.jpg" % name)
	return intro_tex[name]

var voice: AudioStreamPlayer
var voice_muted := false
const SPK := Rect2(16, 12, 52, 40)
var voice_len: Dictionary = {}

func _vstream(name: String) -> AudioStream:
	return load("res://assets/voice/%s.mp3" % name) as AudioStream

## thời lượng slide = độ dài lời thuyết minh + 1.5 giây
func _sdur(i: int) -> float:
	var nm: String = SLIDES[i][0]
	if not voice_len.has(nm):
		var st := _vstream(nm)
		voice_len[nm] = st.get_length() if st != null else 6.0
	return float(voice_len[nm]) + 1.5

func _play_voice(name: String) -> void:
	if voice == null:
		voice = AudioStreamPlayer.new()
		add_child(voice)
	voice.stream = _vstream(name)
	voice.volume_db = -80.0 if voice_muted else 0.0
	voice.play()

func _intro_total_before_last() -> float:
	var tt := 0.0
	for i in SLIDES.size() - 1:
		tt += _sdur(i)
	return tt

func _update_intro(dt: float, confirm: bool) -> void:
	intro_t += dt
	var final_t := _intro_total_before_last()
	var btn := Rect2(W / 2 - 370, H - 100, 740, 70)
	if confirm and SPK.has_point(get_viewport().get_mouse_position()):
		voice_muted = not voice_muted
		if voice != null:
			voice.volume_db = -80.0 if voice_muted else 0.0
		return
	if intro_t < final_t:
		if confirm:
			# bỏ qua giai đoạn hiện tại → sang giai đoạn kế tiếp
			var acc := 0.0
			for i in SLIDES.size() - 1:
				acc += _sdur(i)
				if intro_t < acc:
					intro_t = acc + .01
					break
			Sfx.beep(480, .08, "sine", .03, 60)
	else:
		var over_btn := btn.has_point(get_viewport().get_mouse_position())
		if Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("up") or (confirm and over_btn):
			hud.flash(Color(0, 0, 0), .8)
			intro_tex.clear()
			if voice != null: voice.stop()
			start_game()

## Vẽ ảnh vừa khít màn hình (không cắt chữ), zoom chậm hướng về tiêu điểm.
func _draw_kb(name: String, focus: Vector2, z: float, alpha: float) -> void:
	var tex := _itex(name)
	var ar := float(tex.get_width()) / float(tex.get_height())
	var w := W
	var h := W / ar
	if h > H:
		h = H
		w = H * ar
	var rw := w * z
	var rh := h * z
	var fx := (W - w) / 2.0 + w * focus.x
	var fy := (H - h) / 2.0 + h * focus.y
	var x := fx - (fx - (W - w) / 2.0) * z
	var y := fy - (fy - (H - h) / 2.0) * z
	hud.image(tex, Rect2(x, y, rw, rh), Rect2(0, 0, tex.get_width(), tex.get_height()), Color(1, 1, 1, alpha))

func _draw_intro() -> void:
	var n := SLIDES.size()
	var acc := 0.0
	var idx := n - 1
	var u := 0.0
	for i in n - 1:
		var d: float = _sdur(i)
		if intro_t < acc + d:
			idx = i
			u = intro_t - acc
			break
		acc += d
	if idx == n - 1:
		u = intro_t - acc
	hud.rect(Vector2.ZERO, Vector2(W, H), Color(.039, .094, .125))
	var sl: Array = SLIDES[idx]
	var final := idx == n - 1
	if idx > 0 and u < INTRO_FADE:
		var pv: Array = SLIDES[idx - 1]
		_draw_kb(pv[0], pv[4], pv[6], 1.0)
	var fade := smoothstep(0.0, INTRO_FADE, u)
	if final:
		_draw_kb("overview", sl[4], lerpf(1.1, 1.0, smoothstep(0.0, 3.0, u)), fade)
	else:
		var k := clampf(u / maxf(_sdur(idx), .1), 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		_draw_kb(sl[0], sl[4], lerpf(sl[5], sl[6], k), fade)
	# biểu tượng loa (bấm để tắt/bật tiếng thuyết minh)
	var sc := Color(1, 1, 1, .9) if not SPK.has_point(get_viewport().get_mouse_position()) else Color(.91, .7, .4)
	hud.panel(SPK.position, SPK.size, Color(0.04, 0.09, 0.12, .65))
	var sx := SPK.position.x + 12.0
	var sy := SPK.position.y + 20.0
	hud.poly(PackedVector2Array([Vector2(sx, sy - 6), Vector2(sx + 7, sy - 6), Vector2(sx + 16, sy - 13), Vector2(sx + 16, sy + 13), Vector2(sx + 7, sy + 6), Vector2(sx, sy + 6)]), sc)
	if voice_muted:
		hud.line(Vector2(sx + 21, sy - 8), Vector2(sx + 31, sy + 8), Color(1, .45, .35), 3.0)
		hud.line(Vector2(sx + 31, sy - 8), Vector2(sx + 21, sy + 8), Color(1, .45, .35), 3.0)
	else:
		for rr in [7.0, 12.0]:
			var pts := PackedVector2Array()
			for q in range(-4, 5):
				var an := float(q) / 4.0 * .9
				pts.append(Vector2(sx + 17 + cos(an) * rr, sy + sin(an) * rr))
			for q in range(pts.size() - 1):
				hud.line(pts[q], pts[q + 1], sc, 2.5)
	if not final:
		var tot := _intro_total_before_last()
		hud.rect(Vector2(0, 0), Vector2(W, 5), Color(0, 0, 0, .5))
		hud.rect(Vector2(0, 0), Vector2(W * clampf(intro_t / tot, 0.0, 1.0), 5), Color(.85, .64, .36))
		hud.text("Click / Enter: sang đoạn kế  ▶▶", Vector2(W - 24, 28), 17, Color(1, 1, 1, .75), 2)
		if idx != intro_step_last:
			intro_step_last = idx
			_play_voice(sl[0])
	else:
		if idx != intro_step_last:
			intro_step_last = idx
			_play_voice("overview")
		var a := clampf((u - 2.6) / .9, 0.0, 1.0)
		var btn := Rect2(W / 2 - 370, H - 100, 740, 70)
		var hov := btn.has_point(get_viewport().get_mouse_position())
		var pulse := 1.0 + .03 * sin(t * 4.0)
		var bc := Color(.91, .7, .4, a) if hov else Color(.78, .55, .28, a)
		hud.panel(btn.position - Vector2(4, 4), btn.size + Vector2(8, 8), Color(.91, .84, .71, .3 * a * pulse))
		hud.panel(btn.position, btn.size, bc)
		hud.text("BẮT ĐẦU TRẢI NGHIỆM THÀNH MỘT CON MUỖI", Vector2(W / 2, btn.position.y + 36), 26, Color(1, 1, 1, a), 1)

func _draw_title() -> void:
	hud.rect(Vector2.ZERO, Vector2(W, H), Color(.055, .16, .2))
	for i in 24:
		hud.circle(Vector2(fmod(i * 83.0 + t * 12.0, W), fmod(i * 47.0 + sin(t + i) * 20.0 + H, H)), 3.0 + i % 4, Color(1, 1, 1, .06))
	hud.text("MOSQUITO: LIFE CYCLE", Vector2(W / 2, 250), 70, Color.WHITE, 1)
	hud.text("You don't play a mosquito. You play a lineage.", Vector2(W / 2, 318), 26, Color(.62, .88, .82), 1)
	hud.text("Trứng → Lăng quăng → Nhộng → Muỗi trưởng thành → Giao phối → Đẻ trứng → Thế hệ tiếp theo", Vector2(W / 2, 366), 19, Color(.8, .95, .92), 1)
	hud.text("Chuột: nhìn · W A S D: bơi/bay · Space/Shift: lên/xuống · E: hành động · CHUỘT PHẢI: hút máu (ngắm chấm tâm vào người → chấm đỏ → giữ để bay tới, thả để rút lui)", Vector2(W / 2, 430), 19, Color.WHITE, 1)
	hud.text("M: tắt âm   ·   P: tạm dừng   ·   Chết không có nghĩa là hết — miễn là dòng họ đã sinh sản.", Vector2(W / 2, 464), 19, Color.WHITE, 1)
	if int(t * 2) % 2 == 0:
		hud.text("Nhấn ENTER, SPACE hoặc click để bắt đầu", Vector2(W / 2, 560), 30, Color(1, .91, .66), 1)
	hud.text("Kỷ lục: %d thế hệ" % Game.best, Vector2(W - 20, H - 20), 16, Color(.62, .86, .8), 2)

func _draw_summary() -> void:
	var s := summary
	var L := Game.L
	hud.rect(Vector2.ZERO, Vector2(W, H), Color(.05, .105, .135))
	hud.text("THẾ HỆ %02d HOÀN TẤT" % L["gen"], Vector2(W / 2, 56), 46, Color.WHITE, 1)
	hud.text("%s · build %s · sống %d ngày · %d trứng ở \"%s\"" % ["Muỗi đực" if s["sex"] == "M" else "Muỗi cái", Game.BUILDS[s["build"]]["name"], s["days"], s["eggs"], Game.SITES[s["site"]]["name"]], Vector2(W / 2, 108), 21, Color(.62, .88, .82), 1)
	hud.panel(Vector2(80, 150), Vector2(W - 160, 350))
	hud.text("DI TRUYỀN (Genetic Legacy) — điều kiện sống ảnh hưởng đến thế hệ sau", Vector2(106, 182), 20)
	hud.text("Nhiệm vụ hoàn thành: %d  (thưởng +%d%% số trứng)" % [Game.G.get("quests_done", 0), int((Game.q_bonus() - 1.0) * 100.0)], Vector2(W - 106, 182), 18, Color(.7, 1, .75), 2)
	var i := 0
	for k in Game.TRAITS:
		var y := 226.0 + i * 44.0
		hud.text(Game.TRAIT_NAMES[k], Vector2(120, y), 20)
		hud.rect(Vector2(300, y - 10), Vector2(400, 20), Color(1, 1, 1, .12))
		hud.rect(Vector2(300, y - 10), Vector2(400 * minf(1.0, (L["tr"][k] - 1.0) / 5.0), 20), Color(.44, .83, .63))
		hud.text("%.2f" % L["tr"][k], Vector2(716, y), 19)
		if s["ch"][k] > 0.05:
			hud.text("+%.2f  (%s)" % [s["ch"][k], s["why"][k]], Vector2(800, y), 18, Color(1, .91, .66))
		i += 1
	hud.panel(Vector2(80, 520), Vector2(W - 160, 140))
	var rsv := clampi(int(s["eggs"] / 25), 1, 6)
	var sib := clampi(int(round(s["eggs"] / 15.0)), 2, 12)
	hud.text("Thế hệ %02d: %d anh chị em cạnh tranh thức ăn và chia sẻ rủi ro" % [L["gen"] + 1, sib], Vector2(106, 548), 19)
	hud.text("Mục tiêu: sống sót 10 thế hệ · lập quần thể trong nhà người · vượt hạn hán · sống sót sau phun thuốc", Vector2(106, 580), 17, Color(.8, .95, .9))
	var got: String = ("Thành tựu mới: " + "   ".join(s["got"])) if s["got"].size() > 0 else ("Đã đạt: " + (", ".join(L["ach"].keys()) if L["ach"].size() > 0 else "chưa có"))
	hud.text(got, Vector2(106, 612), 18, Color(1, .85, .42))
	hud.text("Tiến độ: %d/10 thế hệ · %d/3 lần đẻ trong nhà người" % [L["gen"], L["house_lays"]], Vector2(106, 640), 16, Color(.8, .95, .9))
	if s["t"] > .6 and int(t * 2) % 2 == 0:
		hud.text("ENTER để tiếp tục sang thế hệ sau", Vector2(W / 2, 694), 26, Color(1, .91, .66), 1)

func _draw_over() -> void:
	hud.rect(Vector2.ZERO, Vector2(W, H), Color(.07, .035, .04))
	hud.text("VÒNG ĐỜI KẾT THÚC", Vector2(W / 2, 260), 62, Color(1, .42, .42), 1)
	hud.text(cause, Vector2(W / 2, 336), 26, Color.WHITE, 1)
	hud.text("Bạn sống tới ngày %d của vòng đời  ·  Thế hệ %d  ·  Kỷ lục: %d thế hệ" % [Game.day_no(), Game.L["gen"], Game.best], Vector2(W / 2, 396), 26, Color(1, .91, .66), 1)
	hud.text("Nhấn ENTER để bắt đầu vòng đời mới từ quả trứng", Vector2(W / 2, 480), 28, Color.WHITE, 1)

# ═════════════ kiểm thử ═════════════
func _setup_scenario() -> void:
	Game.new_lineage()
	Game.L["reserve"] = 5
	Game.new_generation_stats()
	Game.G["dayf"] = 9.0 if scenario.begins_with("adult") else 0.0
	if scenario.begins_with("adult"):
		Game.L["sex"] = "M" if scenario == "adult_i_male" else "F"
		Game.G["build"] = "explorer"
		mode = "adult"
		var t0 := Time.get_ticks_msec()
		adult.enter(false)
		print("adult.enter ms=", Time.get_ticks_msec() - t0)
		if scenario != "adult_emerge" and scenario != "adult_i_emerge":
			Game.q_force_all()
		adult.A["drag"] = null
		for d in adult.dragons: d.node.visible = false
		adult.dragons.clear()
		adult.A["spray_at"] = -1.0
		match scenario:
			"adult_living":
				adult.A["clock"] = 19.4
				adult.body.global_position = Vector3(-1.5, 1.4, 4.0)
				adult.view_yaw = -.35
				adult.view_pitch = -.12
			"adult_sleep":
				adult.A["clock"] = 23.4
				adult.body.global_position = Vector3(-8.2, 1.6, -2.9)
				adult.view_yaw = -PI / 2.0 + .45
				adult.view_pitch = -.18
			"adult_yard":
				adult.A["clock"] = 12.0
				adult.body.global_position = Vector3(-4, 1.6, 14)
				adult.view_yaw = -.4
				adult.view_pitch = -.1
			"adult_mosq":
				adult.A["clock"] = 12.0
				adult.debug_cam_dist = .3
				adult.body.global_position = Vector3(-4, 1.6, 14)
				adult.view_yaw = 1.1
				adult.view_pitch = -.12
				adult.pl["blood"] = .6
			"adult_emerge":
				adult.A["clock"] = 11.0
				adult.A["weather"] = "normal"
				adult._apply_weather()
				adult.view_yaw = 2.6
				adult.view_pitch = -.3
				adult.debug_cam_dist = .55
			"adult_chicken", "adult_bucket", "adult_jar":
				adult.A["clock"] = 11.0
				adult.A["weather"] = "normal"
				adult._apply_weather()
				var cc: Array = {"adult_chicken": [Vector3(2.2, .35, 7.9), 0.0, -.15, .9], "adult_bucket": [Vector3(-9.2, .55, 4.0), 0.0, -.3, 1.2], "adult_jar": [Vector3(10.5, .8, 8.2), 0.0, -.3, 1.6]}[scenario]
				adult.body.global_position = cc[0]
				adult.view_yaw = cc[1]
				adult.view_pitch = cc[2]
				adult.debug_cam_dist = cc[3]
			"adult_feed":
				adult.A["clock"] = 19.9
				adult.snap_hosts()
				adult.pl["mated"] = true
			"adult_i_village":
				adult.A["clock"] = 16.6
				adult.A["weather"] = "normal"
				adult._apply_weather()
				adult.body.global_position = Vector3(-2, 5.0, 23)
				adult.view_yaw = .12
				adult.view_pitch = -.12
				adult.debug_cam_dist = 6.0
			"adult_i_emerge":
				adult.A["clock"] = 10.0
				adult.A["weather"] = "normal"
				adult._apply_weather()
				adult.view_yaw = 2.5
				adult.view_pitch = -.3
				adult.debug_cam_dist = .5
			"adult_i_female", "adult_i_male":
				adult.A["clock"] = 10.5
				adult.A["weather"] = "normal"
				adult._apply_weather()
				adult.body.global_position = Vector3(12.5, .7, 10.5)
				adult.view_yaw = .9
				adult.view_pitch = -.05
				adult.debug_cam_dist = .27
			"adult_i_lay":
				adult.A["clock"] = 10.5
				adult.A["weather"] = "normal"
				adult._apply_weather()
				adult.body.global_position = Vector3(10.5, .78, 6.5)
				adult.view_yaw = .6
				adult.view_pitch = -.12
				adult.debug_cam_dist = .35
			"adult_village", "adult_pond", "adult_paddy", "adult_canal", "adult_house":
				adult.A["clock"] = 11.0
				var cfg: Array = {"adult_village": [Vector3(0, 6.0, 23), 0.0, -.22, 7.0], "adult_pond": [Vector3(13, 1.4, 4), -.72, -.12, 3.0],
					"adult_paddy": [Vector3(-14, 1.6, -5), .63, -.15, 3.0], "adult_canal": [Vector3(-8, 1.4, 14), -1.2, -.1, 3.5], "adult_house": [Vector3(6, 2.0, 13), .25, -.05, 3.0]}[scenario]
				adult.body.global_position = cfg[0]
				adult.view_yaw = cfg[1]
				adult.view_pitch = cfg[2]
				adult.A["weather"] = "normal"
				adult._apply_weather()
				adult.debug_cam_dist = cfg[3]
			"adult_x", "adult_wind", "adult_scratch":
				adult.A["clock"] = 18.2
				adult.body.global_position = Vector3(3.2, 1.35, -1.6)
				adult.view_yaw = 0.0
				adult.view_pitch = -.08
				adult.debug_cam_dist = .5 if scenario == "adult_x" else 2.2
			"adult_human":
				adult.A["clock"] = 19.9
				adult.debug_cam_dist = .9
				adult.body.global_position = Vector3(.8, 1.45, 3.05)
				adult.view_yaw = PI
				adult.view_pitch = -.02
			"adult_gym":
				adult.A["clock"] = 6.4
				adult.body.global_position = Vector3(-3.0, 1.4, 0.2)
				adult.view_yaw = 0.0
				adult.view_pitch = -.1
				adult.debug_cam_dist = 1.4
			"adult_brush":
				adult.A["clock"] = 6.75
				adult.body.global_position = Vector3(0.1, 1.4, -0.4)
				adult.view_yaw = .34
				adult.view_pitch = -.1
				adult.debug_cam_dist = 1.4
			"adult_bed2":
				adult.A["clock"] = 5.75
				adult.debug_cam_dist = 1.6
				adult.body.global_position = Vector3(-4.9, 1.7, -1.2)
				adult.view_yaw = 0.0
				adult.view_pitch = -.55
			"adult_bed":
				adult.A["clock"] = 23.4
				adult.body.global_position = Vector3(-2.4, 1.7, -1.4)
				adult.view_yaw = 1.12
				adult.view_pitch = -.42
			"adult_tv":
				adult.A["clock"] = 19.9
				adult.body.global_position = Vector3(0.0, 1.5, 1.7)
				adult.view_yaw = PI
				adult.view_pitch = -.12
			"adult_eat":
				adult.A["clock"] = 19.05
				adult.body.global_position = Vector3(2.6, 1.4, 1.6)
				adult.view_yaw = -.62
				adult.view_pitch = -.12
			"adult_kitchen":
				adult.A["clock"] = 19.2
				adult.body.global_position = Vector3(3.0, 1.3, 1.0)
				adult.view_yaw = .5
				adult.view_pitch = -.2
		adult.snap_hosts()
		if scenario == "adult_bed2":
			for i in 40: adult.update(.03)
			var ab := Assets.aabb_of(adult.bed_ref)
			print("[bed] aabb(local)=", ab, " pos=", adult.bed_ref.global_position, " rotY=", adult.bed_ref.rotation_degrees.y)
			for h in adult.hosts:
				if h.human and h.rig != null:
					print("[bed] ", h.k, " sleeping=", h.sleeping, " pos2=", h.pos, " node=", h.node.global_position, " hips=", h.rig.bone_world("hips"), " head=", h.rig.bone_world("head"))
		for h in adult.hosts:
			h.alert = 0.0
		if scenario == "adult_wind" or scenario == "adult_scratch":
			var mom: Object = null
			for h in adult.hosts: if h.k == "mom": mom = h
			adult.update(.02)
			adult.debug_land(mom, 3)
			mom.alert = 1.0 if scenario == "adult_wind" else .75
			mom.cd = 0.0
			Input.action_press("feed")
	elif scenario == "sites":
		for i in Game.SITES.size():
			Game.L["site"] = i
			for st in ["egg", "larva", "pupa"]:
				aquatic.enter(st, false)
			print("[sites] ", Game.SITES[i]["id"], " ok preds=", aquatic.preds.size(), " W=", aquatic.W)
		get_tree().quit()
	elif scenario == "fx_hatch" or scenario == "fx_molt":
		Game.L["site"] = 3
		mode = "egg" if scenario == "fx_hatch" else "larva"
		aquatic.enter(mode, false)
		for pr in aquatic.preds:
			pr.cd = 99.0
			pr.node.visible = false
		aquatic.debug_cam_dist = 1.6
		aquatic.view_pitch = .22
		if scenario == "fx_hatch":
			aquatic._fx_hatch()
			aquatic.enter("larva", false)
		else:
			aquatic.p_pos.y = -1.5
			aquatic._fx_molt()
	elif scenario.begins_with("aq_"):
		var st := scenario.substr(3)
		if st.ends_with("_pond"):
			st = st.substr(0, st.length() - 5)
			Game.L["site"] = 3
		if scenario == "aq_side" or scenario == "aq_close" or scenario == "aq_pupaclose":
			st = "pupa" if scenario == "aq_pupaclose" else "larva"
			Game.L["site"] = 3
		mode = st
		aquatic.enter(st, false)
		if scenario == "aq_egg":
			for pr in aquatic.preds: pr.node.visible = false; pr.cd = 99.0
			aquatic.debug_cam_dist = 0.9
		if scenario == "aq_close" or scenario == "aq_pupaclose":
			aquatic.debug_cam_dist = 2.6
			aquatic.p_pos = Vector3(-1.5, -3.0, 4.0)
			aquatic.view_yaw = 0.0
			aquatic.view_pitch = .0
			aquatic.node_player.rotation_degrees = Vector3(0, -90, 0)
			for p in aquatic.preds: p.cd = 99.0
		elif scenario == "aq_side":
			aquatic.p_pos = Vector3(-1.5, -3.0, 4.0)
			aquatic.view_yaw = 0.0
			aquatic.view_pitch = -.05
			aquatic.node_player.rotation_degrees = Vector3(0, -90, 0)
			aquatic.pl["growth"] = 40.0
			for p in aquatic.preds:
				p.cd = 99.0
				if p.k == "fish": p.pos = Vector3(3.0, -3.2, 3.0); p.face = Vector3(-1, 0, 0)
				if p.k == "beetle": p.pos = Vector3(-4.0, -2.4, 3.0); p.face = Vector3(1, 0, 0)
				if p.k == "nymph": p.pos = Vector3(.5, -aquatic.depth + .5, 3.0); p.home = p.pos; p.face = Vector3(1, 0, 0)
				if p.k == "strider": p.pos = Vector3(-3.5, 0, 3.0)
		if scenario.ends_with("_pond") and st == "larva":
			aquatic.p_pos = Vector3(-6, -3.5, 0)
			aquatic.view_yaw = -PI / 2.0
			for p in aquatic.preds:
				p.cd = 99.0
				if p.k == "fish": p.pos = Vector3(2, -3.5, 1.0); p.face = Vector3(-1, 0, 0)
				if p.k == "beetle": p.pos = Vector3(-2, -2.5, -1.5)
				if p.k == "nymph": p.pos = Vector3(-3.5, -aquatic.depth + .5, 2.0); p.home = p.pos

func _save_shot() -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(shot_path)
	print("SHOT saved ", shot_path, " size=", img.get_size(), " fps=", Engine.get_frames_per_second())
	get_tree().quit()

# ═════════ tự chơi để kiểm thử ═════════
var _auto_last := ""
var _auto_flip := false
func _auto(dt: float) -> void:
	if mode != _auto_last:
		print("[auto] mode=", mode, " gen=", Game.L.get("gen", 0), " sex=", Game.L.get("sex", ""), " t=", snappedf(t, .1))
		_auto_last = mode
	_auto_flip = not _auto_flip
	match mode:
		"title":
			start_game()
			Game.L["reserve"] = 3
		"summary":
			if summary["t"] > 1.0:
				Game.advance_generation(summary)
				begin_generation()
		"over":
			print("[auto] over!")
		"egg", "larva", "pupa":
			if dead: return
			for p in aquatic.preds: p.cd = 99.0
			Game.q_force_all()
			if mode == "egg":
				aquatic.p_pos = Vector3(aquatic.leaves[0]["pos"].x, 0, aquatic.leaves[0]["pos"].z)
				aquatic.pl["heat"] = 0.0
			elif mode == "larva":
				aquatic.pl["molts"] = 3
				aquatic.pl["growth"] += 40.0 * dt
				aquatic.pl["o2"] = 100.0
				aquatic.draining = false
			else:
				if not aquatic.pl["anchored"]:
					aquatic.pl["anchored"] = true
				aquatic.pl["pt"] += 4.0 * dt
		"adult":
			if dead: return
			Game.q_force_all()
			var A: Dictionary = adult.A
			for h in adult.hosts:
				h.alert = 0.0
			adult.pl["energy"] = 100.0
			A["spray_at"] = -1.0
			if not adult.ending.is_empty(): return
			var pl: Dictionary = adult.pl
			var body: CharacterBody3D = adult.body
			Input.action_release("act")
			if not pl["mated"]:
				for n in adult.npcs:
					if n.alive:
						body.global_position = n.pos + Vector3(0, .05, 0)
						adult.v = Vector3.ZERO
						Input.action_press("act")
						break
			elif Game.L["sex"] == "F" and pl["protein"] < .8:
				for h in adult.hosts:
					if h.k == "cow":
						if pl["landed"] == null:
							adult.debug_land(h, 0)
						Input.action_press("feed")
			elif Game.L["sex"] == "F":
				var sp: Vector3 = Game.SITES[3]["pos"]
				body.global_position = Vector3(sp.x, .4, sp.y)
				adult.pl["landed"] = null
				adult.pl["mode"] = "free"
				Input.action_release("feed")
				adult.v = Vector3.ZERO
				Input.action_press("act")

# ═════════ kiểm tra luật chơi ═════════
var _tr := 0.0
var _tr_stage := 0
func _tr_log(msg: String) -> void:
	print("[rules] t=%.1f %s" % [_tr, msg])

func _test_rules(dt: float) -> void:
	_tr += dt
	if mode == "title" and _tr_stage == 0:
		Game.new_lineage()
		Game.L["sex"] = "F"; Game.L["reserve"] = 2
		Game.new_generation_stats()
		Game.G["build"] = "survivor"
		mode = "adult"
		adult.enter(false)
		Game.q_force_all()
		adult.pl["mated"] = true
		for d in adult.dragons: d.node.visible = false
		adult.dragons.clear()
		adult.A["spray_at"] = -1.0
		adult.A["clock"] = 23.5
		adult.snap_hosts()
		adult.body.global_position = Vector3(-5.6, 1.6, -4.0)
		_tr_stage = 1
		_tr_log("bắt đầu: bay bằng phím fwd")
		Input.action_press("fwd")
		return
	if mode != "adult" and not (mode == "over" and _tr_stage == 5): return
	var pos: Vector3 = adult.body.global_position
	match _tr_stage:
		1:
			adult.pl["energy"] = 100.0
			for h in adult.hosts: h.alert = 0.0
			if _tr > 1.2:
				Input.action_release("fwd")
				_tr_log("sau 1.2s bay: pos=%s speed=%.2f (phải > 0)" % [pos, adult.v.length()])
				# đậu lên bố đang ngủ
				var dad: Object = null
				for h in adult.hosts: if h.k == "dad": dad = h
				adult.debug_land(dad, 0)
				_tr_log("đậu bằng cơ chế mới: mode=%s" % adult.pl["mode"])
				Input.action_press("feed")
				_tr_stage = 3
				_tr = 0.0
		2:
			for h in adult.hosts: if h.k != "dad": h.alert = 0.0
			if _tr > .2 and adult.pl["landed"] == null:
				Input.action_press("act")
				_tr_log("đậu: landed=%s" % [adult.pl["landed"] != null])
			if _tr > .3: Input.action_release("act")
			if _tr > .6 and adult.pl["landed"] != null:
				_tr_stage = 3
				_tr = 0.0
				Input.action_press("act")
		3:
			adult.pl["energy"] = 60.0
			Input.action_press("feed")
			for h in adult.hosts: if h.k == "dad": h.alert = 0.0 if _tr < 2.0 else h.alert
			if _tr > 2.0 and _tr < 2.05:
				_tr_log("đã hút: blood=%.2f protein=%.2f energy=%.0f" % [adult.pl["blood"], adult.pl["protein"], adult.pl["energy"]])
				for h in adult.hosts: if h.k == "dad": h.alert = 1.0; h.cd = 0.0
			if _tr > 2.05:
				for h in adult.hosts:
					if h.k == "dad" and h.st == "wind":
						_tr_log("bố giơ tay đập (wind), muỗi vẫn đang đậu → phải chết")
						_tr_stage = 4
						_tr = 0.0
		4:
			if dead:
				_tr_log("đã chết: %s" % cause)
				_tr_stage = 5
				_tr = 0.0
		5:
			if _tr > 2.5 and mode == "over":
				_tr_log("chết là chết luôn: mode=%s (không còn hồi sinh)" % mode)
				_tr_stage = 6
				_tr = 0.0
		6:
			if _tr > 1.0:
				print("[rules] DONE")
				get_tree().quit()

# ═════════ kiểm tra né cú đập: thả chuột phải kịp thời → sống sót ═════════
var _td := 0.0
var _td_stage := 0
func _test_dodge(dt: float) -> void:
	_td += dt
	if mode == "title" and _td_stage == 0:
		Game.new_lineage()
		Game.L["sex"] = "F"; Game.L["reserve"] = 0
		Game.new_generation_stats()
		Game.G["build"] = "survivor"
		mode = "adult"
		adult.enter(false)
		Game.q_force_all()
		adult.pl["mated"] = true
		for d in adult.dragons: d.node.visible = false
		adult.dragons.clear()
		adult.A["spray_at"] = -1.0
		adult.A["clock"] = 18.2
		adult.snap_hosts()
		var mom: Object = null
		for h in adult.hosts: if h.k == "mom": mom = h
		adult.body.global_position = Vector3(3.2, 1.3, -1.8)
		adult.update(.02)
		adult.debug_land(mom, 3)
		Input.action_press("feed")
		_td_stage = 1
		_td = 0.0
		return
	if mode != "adult": return
	var mom2: Object = null
	for h in adult.hosts: if h.k == "mom": mom2 = h
	adult.pl["energy"] = 100.0
	match _td_stage:
		1:
			if _td > .5:
				mom2.alert = 1.0; mom2.cd = 0.0
				_td_stage = 2
				_td = 0.0
				print("[dodge] cú đập bắt đầu; scenario=", scenario)
		2:
			var delay := .28 if scenario == "test_dodge" else 5.0   # test_dodge_late: không né
			if _td > delay and Input.is_action_pressed("feed"):
				Input.action_release("feed")
				print("[dodge] thả chuột phải lúc t=%.2f, mode=%s" % [_td, adult.pl["mode"]])
			if dead:
				print("[dodge] KẾT QUẢ: CHẾT (%s)" % cause)
				get_tree().quit()
			elif _td > 1.6:
				print("[dodge] KẾT QUẢ: SỐNG, mode=%s, cách vật chủ %.2f m, y=%.2f" % [adult.pl["mode"], Vector2(adult.body.global_position.x - mom2.pos.x, adult.body.global_position.z - mom2.pos.y).length(), adult.body.global_position.y])
				get_tree().quit()

# ═════════ kiểm tra: ngắm trúng người → chấm đỏ → giữ chuột phải → bay tới đậu ═════════
var _ta := 0.0
var _ta_stage := 0
func _test_aim(dt: float) -> void:
	_ta += dt
	if mode == "title" and _ta_stage == 0:
		Game.new_lineage()
		Game.L["sex"] = "F"; Game.L["reserve"] = 0
		Game.new_generation_stats()
		Game.G["build"] = "survivor"
		mode = "adult"
		adult.enter(false)
		Game.q_force_all()
		adult.pl["mated"] = true
		for d in adult.dragons: d.node.visible = false
		adult.dragons.clear()
		adult.A["spray_at"] = -1.0
		adult.A["clock"] = 18.2
		adult.snap_hosts()
		adult.body.global_position = Vector3(3.2, 1.3, -1.2)
		adult.view_yaw = 0.0
		adult.view_pitch = 0.0
		_ta_stage = 1
		_ta = 0.0
		return
	if mode != "adult": return
	for h in adult.hosts: h.alert = 0.0
	adult.pl["energy"] = 100.0
	match _ta_stage:
		1:
			if _ta > .3:
				print("[aim] ngắm trúng: ", adult.pl["aim"] != null, " mode=", adult.pl["mode"])
				Input.action_press("feed")
				_ta_stage = 2
				_ta = 0.0
		2:
			if adult.pl["mode"] == "feeding":
				print("[aim] ĐÃ ĐẬU sau %.2fs, blood=%.2f" % [_ta, adult.pl["blood"]])
				_ta_stage = 3
				_ta = 0.0
			elif _ta > 5.0:
				print("[aim] THẤT BẠI: mode=", adult.pl["mode"], " pos=", adult.body.global_position)
				get_tree().quit()
		3:
			if _ta > 1.0:
				print("[aim] hút máu: blood=%.2f; thả chuột phải" % adult.pl["blood"])
				Input.action_release("feed")
				_ta_stage = 4
				_ta = 0.0
		4:
			if _ta > 1.2:
				print("[aim] sau khi thả: mode=", adult.pl["mode"], " y=%.2f" % adult.body.global_position.y)
				get_tree().quit()

# ═════════ kiểm tra chuỗi nhiệm vụ tuần tự (không ép) ═════════
var _tq := 0.0
var _tq_last := ""
var _tq_seen := ""
func _test_quests(dt: float) -> void:
	_tq += dt
	if mode != _tq_last:
		print("[quest] t=%.1f mode=%s" % [_tq, mode])
		_tq_last = mode
	var act: String = Game.q_active().get("id", "")
	if act != _tq_seen:
		print("[quest] t=%.1f nhiệm vụ hiện tại: %s" % [_tq, act])
		_tq_seen = act
	match mode:
		"title":
			Game.new_lineage()
			Game.L["sex"] = "F"; Game.L["reserve"] = 3; Game.L["site"] = 3
			Game.new_generation_stats()
			start_game()
		"egg":
			for p in aquatic.preds: p.cd = 99.0
			var lp: Vector3 = aquatic.leaves[0]["pos"]
			aquatic.p_pos = Vector3(lp.x + 12, 0, lp.z + 8) if (act == "stay") else Vector3(lp.x, 0, lp.z)
			aquatic.pl["heat"] = minf(aquatic.pl["heat"], 60.0)
		"larva":
			for p in aquatic.preds: p.cd = 99.0
			aquatic.pl["o2"] = 100.0
			match act:
				"eat": Game.q_add("eat", 4.0)
				"breath": Game.q_add("breath", 3.0)
				"hunt": Game.q_add("hunt", 1.0)
				"molt1", "molt2", "molt3", "grow": aquatic.pl["growth"] += 15.0 * dt
			if aquatic.pl["molt_pending"]:
				aquatic.p_pos = aquatic.weeds[0] + Vector3(0, .2, 0)
				aquatic.p_vel = Vector3.ZERO
			else:
				aquatic.p_pos = Vector3(0, aquatic.surf - 3.0, 0)
			if _tq > 100.0:
				print("[quest] TIMEOUT larva"); get_tree().quit()
		"pupa":
			aquatic.p_vel = Vector3.ZERO
			match act:
				"breathe": aquatic.p_pos = Vector3(0, aquatic.surf - .1, 0)
				"hide": aquatic.p_pos = aquatic.weeds[0] + Vector3(0, .2, 0)
				"meta": aquatic.p_pos = aquatic.weeds[0] + Vector3(0, .2, 0)
				"emerge":
					aquatic.p_pos = Vector3(0, aquatic.surf - .1, 0)
					Input.action_press("act")
		"adult":
			Input.action_release("act")
			if act == "dry" and fmod(_tq, 2.0) < dt:
				print("[quest] hong cánh: ", Game.quests[0]["prog"], " pos=", adult.body.global_position)
			if act == "mate" or _tq > 90.0:
				print("[quest] ĐÃ TỚI NHIỆM VỤ GIAO PHỐI — chuỗi hoạt động đúng thứ tự")
				get_tree().quit()

var _tm := 0.0
var _tm_p := Vector3.ZERO
func _test_move(dt: float) -> void:
	_tm += dt
	if mode == "title":
		Game.new_lineage()
		Game.L["sex"] = "F"; Game.L["reserve"] = 0
		Game.new_generation_stats()
		Game.G["build"] = "survivor"
		mode = "adult"
		adult.enter(false)
		for q in Game.quests:
			if q["id"] != "digest" and not q["done"]:
				q["done"] = true; q["prog"] = q["goal"]
		adult.pl["mated"] = true
		adult.pl["blood"] = .8
		adult.A["clock"] = 14.0
		adult.A["weather"] = "normal"
		adult.snap_hosts()
		adult.body.global_position = Vector3(3.0, .5, 4.4)
		adult.view_yaw = 0.0
		adult.view_pitch = 0.0
		_tm = 0.0
		_tm_p = adult.body.global_position
		return
	if mode != "adult": return
	adult.pl["energy"] = 100.0
	if _tm > .5 and _tm < .5 + dt * 1.5 and adult.pl["perch"] == null:
		var ev := InputEventAction.new()
		ev.action = "act"
		ev.pressed = true
		Input.parse_input_event(ev)
	if _tm > .6 and _tm < .6 + dt * 1.5:
		var ev2 := InputEventAction.new()
		ev2.action = "act"
		ev2.pressed = false
		Input.parse_input_event(ev2)
	if int(_tm * 2) != int((_tm - dt) * 2):
		print("[move] t=%.1f pos=%s perch=%s digest=%s prompt=%s" % [_tm, adult.body.global_position, adult.pl["perch"], Game.q_find("digest")["prog"], adult.prompt])
	if _tm > 3.0:
		print("[move] dịch chuyển: ", adult.body.global_position - _tm_p)
		get_tree().quit()
