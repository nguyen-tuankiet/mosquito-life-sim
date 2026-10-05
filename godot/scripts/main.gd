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
var menu := StartMenu.new()
var menu_t := 0.0
var pause_t := 0.0
var load_frames := 0
var _after_load := "intro"   # sau màn hình chờ: "intro" (game mới) | "continue" (nạp bản lưu)
var _cap := false          # chuột đã bị bắt (đang điều khiển) ở khung hình trước — để khôi phục sau tạm dừng
var _loading := false      # đang nạp bản lưu: không tự lưu đè lên
const STAGES := ["egg", "larva", "pupa", "adult"]

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
		elif a == "--legacy-world": adult.use_village = false   # thế giới nén cũ quanh nhà (không nạp map làng)
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
	if scenario == "test_save":
		_test_save()
		get_tree().quit()
		return
	if scenario == "test_village":
		_test_village()
		get_tree().quit()
		return
	if scenario == "test_talk":
		_test_talk()
		get_tree().quit()
		return
	if scenario == "intro":
		mode = "intro"
		intro_t = float(OS.get_environment("INTRO_T")) if OS.get_environment("INTRO_T") != "" else 0.0
	elif scenario != "":
		_setup_scenario()
	elif not start_adult:
		mode = "menu"
		menu.has_save = SaveGame.exists()
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
	if not _loading:
		save_game()

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

## Kiểm thử lưu/nạp: --scenario=test_save (in "[save] ..." và "[save] OK" nếu đúng hết)
func _test_save() -> void:
	var bad := 0
	var chk := func(name: String, ok: bool) -> void:
		print("[save] ", name, " ", "ok" if ok else "SAI")
		if not ok: bad += 1
	SaveGame.clear()
	Game.new_lineage()
	Game.L["sex"] = "F"; Game.L["gen"] = 3
	Game.new_generation_stats()
	_loading = true
	enter_stage("larva", false)
	aquatic.pl["growth"] = 42.0; aquatic.pl["molts"] = 1; aquatic.p_pos = Vector3(1.5, -2.0, 3.0)
	Game.quests[0]["prog"] = 2.0
	Game.G["food"] = 7
	save_game()
	chk.call("đã ghi file", SaveGame.exists())
	Game.new_lineage(); Game.new_generation_stats()
	enter_stage("egg", false)
	chk.call("nạp trả true", load_game())
	chk.call("giai đoạn larva", mode == "larva")
	chk.call("thế hệ 3", int(Game.L["gen"]) == 3)
	chk.call("growth 42", is_equal_approx(float(aquatic.pl["growth"]), 42.0))
	chk.call("molts 1", int(aquatic.pl["molts"]) == 1)
	chk.call("vị trí", aquatic.p_pos.is_equal_approx(Vector3(1.5, -2.0, 3.0)))
	chk.call("nhiệm vụ tiến độ", is_equal_approx(float(Game.quests[0]["prog"]), 2.0))
	chk.call("thống kê food 7", int(Game.G["food"]) == 7)
	# trưởng thành
	Game.L["sex"] = "F"
	enter_stage("adult", false)
	adult.body.global_position = Vector3(5, 3, 5); adult.pl["energy"] = 33.0; adult.pl["blood"] = .4
	save_game()
	Game.new_lineage(); Game.new_generation_stats()
	chk.call("nạp adult", load_game())
	chk.call("mode adult", mode == "adult")
	chk.call("energy 33", is_equal_approx(float(adult.pl["energy"]), 33.0))
	chk.call("blood .4", is_equal_approx(float(adult.pl["blood"]), .4))
	chk.call("vị trí adult", adult.body.global_position.is_equal_approx(Vector3(5, 3, 5)))
	# tổng kết thế hệ
	summary = {"t": 5.0, "gen": 3}
	mode = "summary"
	save_game()
	chk.call("nạp summary", load_game() and mode == "summary" and int(summary.get("gen", 0)) == 3)
	SaveGame.clear()
	print("[save] ", "OK" if bad == 0 else "CÓ %d LỖI" % bad)

# ═════════════ tạm dừng · lưu · nạp ═════════════
func _set_paused(p: bool) -> void:
	if p == paused:
		return
	paused = p
	get_tree().paused = false
	if p:
		pause_t = 0.0
		save_game()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _cap else Input.MOUSE_MODE_VISIBLE

## Lưu và quay về menu chính (có nút TIẾP TỤC).
func _to_menu() -> void:
	save_game()
	paused = false
	adult.leave()
	aquatic.leave()
	title_cam.make_current()
	menu.reset()
	menu.has_save = SaveGame.exists()
	menu_t = 0.0
	mode = "menu"

func save_game() -> void:
	if (scenario != "" and scenario != "test_save") or start_adult:
		return
	if mode in STAGES and dead:
		return
	var d := {"mode": mode, "L": Game.L, "G": Game.G, "quests": Game.quests, "quest_stage": Game.quest_stage}
	match mode:
		"summary":
			d["summary"] = summary
		"egg", "larva", "pupa":
			d["detail"] = {"p_pos": aquatic.p_pos, "yaw": aquatic.view_yaw, "pitch": aquatic.view_pitch,
				"pl": SaveGame.plain(aquatic.pl), "stage_t": aquatic.stage_t}
		"adult":
			d["detail"] = {"pos": adult.body.global_position, "yaw": adult.view_yaw, "pitch": adult.view_pitch,
				"pl": SaveGame.plain(adult.pl, ["mode", "sucking", "mate", "lay"]),
				"t": float(adult.A.get("t", 0.0)), "clock": float(adult.A.get("clock", 0.0))}
		_:
			return
	SaveGame.write(d)

## Nạp bản lưu: vào lại đúng giai đoạn, khôi phục chỉ số và vị trí. Trả về false nếu không có / hỏng.
func load_game() -> bool:
	var d := SaveGame.read()
	if d.is_empty():
		return false
	Game.L = d["L"]
	Game.G = d["G"]
	var m: String = d["mode"]
	if m == "summary":
		summary = d.get("summary", {})
		summary["t"] = 0.0
		mode = "summary"
		return true
	if not (m in STAGES):
		return false
	_loading = true
	enter_stage(m, false)
	_loading = false
	Game.quests = d.get("quests", Game.quests)
	Game.quest_stage = d.get("quest_stage", Game.quest_stage)
	var det: Dictionary = d.get("detail", {})
	if not det.is_empty():
		if m == "adult":
			adult.body.global_position = det["pos"]
			adult.v = Vector3.ZERO
			adult.view_yaw = det["yaw"]
			adult.view_pitch = det["pitch"]
			adult.pl.merge(det["pl"], true)
			adult.A["t"] = det["t"]
			adult.A["clock"] = det["clock"]
			adult.emerge_t = 99.0   # bỏ cảnh vừa vũ hóa
		else:
			aquatic.p_pos = det["p_pos"]
			aquatic.view_yaw = det["yaw"]
			aquatic.view_pitch = det["pitch"]
			aquatic.pl.merge(det["pl"], true)
			aquatic.stage_t = det["stage_t"]
	hud.banner("TIẾP TỤC HÀNH TRÌNH", "Thế hệ %d · %s · ngày %d — bấm chuột để điều khiển tiếp" % [int(Game.L["gen"]), String(Game.STAGE_NAMES[m]).to_lower(), Game.day_no()])
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and mode in STAGES:
		save_game()

func _on_died(c: String) -> void:
	if dead:
		return
	dead = true
	dead_t = 0.0
	cause = c
	if scenario != "":
		print("[died] ", c, " · mode=", mode)

func _resolve_death() -> void:
	SaveGame.clear()
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
	save_game()

# ═════════════ vòng lặp ═════════════
func _process(dt: float) -> void:
	t += dt
	frame_i += 1
	if Input.is_action_just_pressed("mute"):
		Sfx.muted = not Sfx.muted
	if (Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_cancel")) and mode in STAGES and not dead:
		_set_paused(not paused)
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
			"menu":
				menu_t += dt
				Input.mouse_mode = Input.MOUSE_MODE_HIDDEN   # con trỏ là con muỗi tự vẽ
				var go := false
				var cont := false
				if menu_t > .4:
					if _menu_click:
						var act := menu.click(get_viewport().get_mouse_position())
						go = act == "start"
						cont = act == "continue"
					elif menu.page == "home" and (Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("act")):
						go = not menu.has_save
						cont = menu.has_save
					elif menu.page == "about" and Input.is_key_pressed(KEY_ESCAPE):
						menu.page = "home"
				_menu_click = false
				if cont and not SaveGame.exists():
					cont = false
					menu.has_save = false
				if cont or go:
					Sfx.beep(480, .08, "sine", .03, 60)
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
					menu.reset()
					# dựng cả làng (map + cây cỏ) ngay bây giờ, sau màn hình chờ, để lúc nhộng nở thành muỗi không bị giật
					_after_load = "continue" if cont else "intro"
					load_frames = 0
					mode = "loading"
			"loading":
				load_frames += 1
				if load_frames == 3:
					adult.build()
					adult.visible = true      # hiện 1 lát (dưới màn hình chờ) để GPU biên dịch shader / nạp mesh trước
					adult.cam.make_current()
				elif load_frames >= 8:
					adult.visible = false
					title_cam.make_current()
					if _after_load == "continue":
						if not load_game():
							menu.has_save = false
							menu.reset()
							mode = "menu"
							menu_t = 0.0
					else:
						hud.flash(Color(0, 0, 0), .6)
						mode = "intro"
						intro_t = 0.0
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
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN   # con trỏ muỗi tự vẽ, game không bắt chuột
		pause_t += dt
		var mp := get_viewport().get_mouse_position()
		menu.draw_pause(hud, pause_t, mp)
		if _menu_click and pause_t > .15:
			match menu.pause_click(mp):
				"resume": _set_paused(false)
				"menu": _to_menu()
				"quit":
					save_game()
					get_tree().quit()
	if mode in STAGES and not paused:
		_cap = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	_menu_click = false
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
var _menu_click := false
func _input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_click = true
		_menu_click = true

func _clicked() -> bool:
	var c := _click
	_click = false
	return c

func _draw_mode() -> void:
	match mode:
		"menu": menu.draw(hud, menu_t, get_viewport().get_mouse_position())
		"loading": menu.draw_loading(hud, t, _after_load == "continue")
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
		if scenario.begins_with("adult_v_"):
			_village_shot(scenario.substr(8))
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

# M4: ảnh kiểm tra trong map làng — [giờ, Bible (x, z), cao trên mặt đất, yaw, pitch, khoảng cách camera]
const VILLAGE_SHOTS := {
	"jar": [17.3, Vector2(301.2, 83.2), .95, .25, -.08, 1.1], "yard": [17.3, Vector2(298, 100), 5.0, .1, -.22, 1.6],
	"pond": [16.5, Vector2(214, 333), 1.4, PI / 2.0, -.06, 1.0], "paddy": [10.0, Vector2(368, 262), 1.6, -PI / 2.0 + .25, -.08, 1.0],
	"road": [9.0, Vector2(291, 236), 1.6, .15, -.06, 1.0], "bamboo": [15.0, Vector2(30, 300), 1.0, -PI / 2.0, -.03, 1.0],
	"canal": [16.0, Vector2(112, 118), 1.3, .3, -.1, 1.0], "night": [21.5, Vector2(300, 98), 2.0, 0.0, -.05, 1.4],
	"high": [17.3, Vector2(300, 140), 9.0, .2, -.15, 1.4],
	"market": [8.5, Vector2(262, 262), 1.7, 0.05, -.06, 1.1], "market_top": [8.5, Vector2(258, 268), 9.0, 0.0, -.5, 1.4],
	"evening": [19.3, Vector2(318, 128), 1.8, PI - .15, -.08, 1.2], "field": [8.0, Vector2(330, 297), 1.8, -PI / 2.0 + .1, -.06, 1.1],
	"evening2": [19.3, Vector2(319, 121), 1.6, 0.0, -.05, 1.1],
	"pets": [10.0, Vector2(302.5, 76.5), 1.1, PI / 2.0 - .85, -.14, .9],
	"lane": [9.5, Vector2(296, 121), 1.5, -PI / 2.0 + .05, -.05, 1.0], "hamlet": [16.0, Vector2(252, 330), 1.8, PI / 2.0 + .35, -.06, 1.0],
}
func _village_shot(k: String) -> void:
	if adult.vmap == null or not VILLAGE_SHOTS.has(k):
		print("[shot] không có map làng hoặc cảnh ", k)
		return
	var c: Array = VILLAGE_SHOTS[k]
	adult.A["clock"] = c[0]
	adult.A["weather"] = "normal"
	adult._apply_weather()
	var lp: Vector2 = adult.vmap.bible_to_local(c[1])
	adult.body.global_position = Vector3(lp.x, adult.gy(lp.x, lp.y) + c[2], lp.y)
	adult.view_yaw = c[3]
	adult.view_pitch = c[4]
	adult.debug_cam_dist = c[5]
	adult._update_zone(adult.body.global_position)
	hud.banner_t = 99.0       # ảnh chụp: không che bằng bảng thông báo khu vực
	adult.snap_residents()
	var bp: Vector3 = adult.body.global_position
	for h in adult.hosts:     # cho người gần đó nói ngay để ảnh có bong bóng thoại
		if h.persona != "" and Vector2(h.pos.x - bp.x, h.pos.y - bp.z).length() < 22.0:
			h.chat_t = randf() * .1
	print("[shot] ", k, " local=", adult.body.global_position, " zone=", adult.zone)

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
			for d in adult.dragons:      # kiểm luồng chơi, không kiểm né chuồn chuồn (ao Z03 có nhiều chuồn chuồn)
				d.st = "rest"; d.t = 99.0
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
				var sp: Vector3 = Game.site_pos(3)
				body.global_position = Vector3(sp.x, Game.site_wy(3) + .3, sp.y)
				adult.pl["landed"] = null
				adult.pl["mode"] = "free"
				Input.action_release("feed")
				adult.v = Vector3.ZERO
				Input.action_press("act")

# ═════════ M4: kiểm tra map làng trong game ═════════
var _tv_fail := 0
func _tv(ok: bool, msg: String) -> void:
	print("[village] ", "PASS " if ok else "FAIL ", msg)
	if not ok: _tv_fail += 1

func _test_village() -> void:
	Game.new_lineage()
	Game.L["sex"] = "F"
	Game.L["site"] = 2
	Game.new_generation_stats()
	adult.enter(false)
	var vm: VillageMap = adult.vmap
	_tv(vm != null, "nạp map làng")
	if vm == null:
		return
	# 1. nguồn nước ở đúng điểm đẻ trứng chuẩn (MAP_BIBLE §6) và đúng zone
	var want := {"puddle": ["W01_puddle_rain", "Z07", Vector2(330, 450)], "bucket": ["W02_bucket", "Z01", Vector2(292, 66)],
		"jar": ["W03_jar_chum", "Z01", Vector2(300, 80)], "pond": ["W05_pond", "Z03", Vector2(170, 337)],
		"canal": ["W06_canal", "Z05", Vector2(100, 162)], "paddy": ["W07_paddy", "Z04", Vector2(385, 282)]}
	for i in Game.SITES.size():
		var id: String = Game.SITES[i]["id"]
		var sp := Game.site_pos(i)
		var b := vm.local_to_bible(sp.x, sp.y)
		var w: Array = want[id]
		_tv(Game.site_map.has(i) and Game.site_map[i]["id"] == w[0] and b.distance_to(w[2]) < .01, "%s ở %s (Bible %s)" % [id, w[0], b])
		_tv(vm.zone_at(sp.x, sp.y) == w[1], "%s thuộc %s (zone_at = %s)" % [id, w[1], vm.zone_at(sp.x, sp.y)])
		_tv(adult.bounds.has_point(Vector2(sp.x, sp.y)), "%s trong vùng bay" % id)
		var g := vm.height_at(sp.x, sp.y)
		var wy := Game.site_wy(i)
		_tv(wy > g - .5 and wy < g + 3.0, "%s mặt nước %.2f so với đất/đáy %.2f" % [id, wy, g])
	# 2. lần đầu sinh ra ở chum W03 = PlayerSpawn_FirstLife
	var spn := vm.node_local("PlayerSpawn_FirstLife")
	var bp: Vector3 = adult.body.global_position
	_tv(Vector2(bp.x - spn.x, bp.z - spn.z).length() < .05, "vũ hóa tại PlayerSpawn_FirstLife (chum W03): %s" % bp)
	# 3. nhà có nội thất trùng nhà H01, nền nhà = mặt đất map
	_tv(absf(vm.height_at(0, 0)) < .01 and absf(adult.gy(0, 12) + .3) < .05, "nền nhà H01 = 0, sân thấp hơn 0,3 m")
	# 4. giới hạn bay theo CameraBounds (MAP_BIBLE §12)
	var r: Rect2 = adult.bounds
	var b0 := vm.local_to_bible(r.position.x, r.position.y)
	var b1 := vm.local_to_bible(r.end.x, r.end.y)
	_tv(b0.distance_to(Vector2(10, 10)) < .01 and b1.distance_to(Vector2(490, 530)) < .01, "vùng bay = playable_rect [10,10,490,530]")
	Game.q_force_all()
	adult.A["spray_at"] = -1.0
	for d in adult.dragons: d.st = "rest"; d.t = 99.0
	adult.body.global_position = Vector3(r.end.x - .5, 50.0, r.end.y - .5)
	adult.v = Vector3(20, 0, 20)
	Input.action_press("fwd")
	for k in 30: adult.update(1.0 / 60.0)
	Input.action_release("fwd")
	var q: Vector3 = adult.body.global_position
	_tv(q.x <= r.end.x + .001 and q.z <= r.end.y + .001 and q.y <= adult.max_y + .001, "không bay ra ngoài vùng bay / quá trần %.1f m: %s" % [adult.max_y, q])
	adult.body.global_position = Vector3(-100, -5.0, 100)
	adult.update(1.0 / 60.0)
	q = adult.body.global_position
	_tv(q.y >= adult.gy(q.x, q.z), "không chui xuống đất: y=%.2f đất=%.2f" % [q.y, adult.gy(q.x, q.z)])
	# 5. bay cao nhanh hơn (làng 500 m)
	var lp := vm.bible_to_local(Vector2(400, 470))
	var speeds := []
	for h in [1.0, 9.0]:
		adult.body.global_position = Vector3(lp.x, adult.gy(lp.x, lp.y) + h, lp.y)
		adult.v = Vector3.ZERO
		adult.view_yaw = 0.0
		adult.view_pitch = 0.0
		Input.action_press("fwd")
		for k in 90: adult.update(1.0 / 60.0)
		Input.action_release("fwd")
		speeds.append(adult.v.length())
	_tv(speeds[1] > speeds[0] * 2.0, "tốc độ sát đất %.2f m/s, bay cao %.2f m/s" % [speeds[0], speeds[1]])
	# 6. người & vật nuôi theo zone (MAP_BIBLE §13)
	adult.A["clock"] = 10.0
	for k in 10: adult.update(1.0 / 60.0)
	var by_zone := {}
	for h in adult.hosts:
		var z := "Z01" if adult.in_house(h.pos.x, h.pos.y) else vm.zone_at(h.pos.x, h.pos.y)
		by_zone[h.k] = z
	print("[village] vật chủ theo zone: ", by_zone)
	for k in adult.VILLAGE_HOSTS:
		var zw: String = adult.VILLAGE_HOSTS[k]["zone"]
		var zg: String = by_zone.get(k, "")
		_tv(zg == zw or (zw == "Z04" and zg == "Z08") or (zw == "Z02" and zg == "Z01"), "%s ở %s (đang ở %s)" % [k, zw, zg])
	_tv(by_zone.get("cow", "") == "Z04", "trâu ở ruộng lúa Z04")
	adult.A["clock"] = 22.0
	adult.update(1.0 / 60.0)
	var night_out := 0
	for h in adult.hosts:
		if h.def.get("day", false) and not h.away: night_out += 1
	_tv(night_out == 0, "ban đêm người ngoài đồng / đường về nhà")
	# 7. hành trình 1 → 8
	Game.L["zones"] = {}
	Game.G["zones"] = {}
	var q0 := int(Game.G["quests_done"])
	_tv(Game.zone_enter("Z01") == "journey" and Game.zone_enter("Z03") == "new" and Game.zone_enter("Z02") == "journey", "hành trình: Z01 → (Z03 ngoài thứ tự) → Z02")
	_tv(int(Game.G["quests_done"]) == q0 + 2 and Game.journey_next() == "Z04", "thưởng 2 chặng, chặng kế tiếp Z04 (%s)" % Game.journey_next())
	_tv(vm.zone_at(vm.bible_to_local(Vector2(30, 300)).x, vm.bible_to_local(Vector2(30, 300)).y) == "Z06" and vm.zone_at(vm.bible_to_local(Vector2(287, 260)).x, vm.bible_to_local(Vector2(287, 260)).y) == "Z08", "zone rừng tre Z06, đường làng Z08")
	# 7b. chợ làng (MAP v2.1): người bán/mua có mặt giờ họp chợ, vắng khi tan chợ
	var mr: Rect2 = vm.market_rect()
	_tv(mr.has_area() and vm.in_market(mr.get_center().x, mr.get_center().y), "có chợ làng %s" % mr)
	var mk_n := func() -> int:
		var c := 0
		for h in adult.hosts:
			if h.def.get("market", false) and not h.away and mr.grow(6.0).has_point(h.pos): c += 1
		return c
	adult.A["clock"] = 8.0
	adult.update(1.0 / 60.0)
	var n_open: int = mk_n.call()
	adult.A["clock"] = 13.0
	adult.update(1.0 / 60.0)
	var n_noon: int = mk_n.call()
	_tv(n_open == 6 and n_noon == 0, "chợ sáng 8h: %d người, trưa 13h tan chợ: %d người" % [n_open, n_noon])
	adult.body.global_position = Vector3(mr.get_center().x, adult.gy(mr.get_center().x, mr.get_center().y) + 1.5, mr.get_center().y)
	adult._update_zone(adult.body.global_position)
	_tv(adult.in_market and adult.zone == "Z08", "bay vào chợ → khu vực Chợ làng (Z08)")
	# 7c. người dân sống theo lịch (MAP v2.2): giữ nguyên giờ, cho đi 30 s (muỗi ở xa → đi nhanh), kiểm chỗ đứng
	var res: Array = []
	for h in adult.hosts:
		if h.def.has("res"): res.append(h)
	adult.body.global_position = Vector3(adult.bounds.position.x + 2, 20.0, adult.bounds.end.y - 2)
	var settle := func(hr: float) -> Dictionary:
		var t0 := Time.get_ticks_usec()
		for k in 300:
			adult.A["clock"] = hr
			adult.update(.1)
		var cnt := {"_ms": (Time.get_ticks_usec() - t0) / 300000.0}
		for h in res:
			var key: String = "away" if h.away else String(h.act)
			if not h.away and h.pos.distance_to(h.def["tg"][h.act]) > 4.0:
				key = "đang đi"
				print("  [đang đi] ", h.k, " ", h.act, " pos=", h.pos, " tgt=", h.def["tg"][h.act], " wp=", h.wp.size(), " st=", h.st, " react=", h.react)
			cnt[key] = int(cnt.get(key, 0)) + 1
		return cnt
	var c8: Dictionary = settle.call(8.0)
	var c12: Dictionary = settle.call(12.5)
	var c19: Dictionary = settle.call(19.2)
	var c22: Dictionary = settle.call(22.0)
	print("[village] %d người dân · 8h %s · 12h30 %s · 19h12 %s · 22h %s" % [res.size(), c8, c12, c19, c22])
	_tv(res.size() >= 20, "%d người dân trong 17 nhà" % res.size())
	_tv(int(c8.get("field", 0)) > 0 and int(c8.get("market", 0)) > 0 and int(c8.get("pond", 0)) + int(c8.get("away", 0)) > 0 and not c8.has("đang đi"),
		"8h: ra đồng, đi chợ, ra ao/đi học — ai cũng đã tới nơi")
	_tv(int(c12.get("away", 0)) == res.size(), "12h30: nghỉ trưa trong nhà / đi học (%d/%d khuất)" % [int(c12.get("away", 0)), res.size()])
	_tv(int(c19.get("sit", 0)) > 0, "19h12: ngồi hóng mát trước nhà")
	_tv(int(c22.get("away", 0)) == res.size(), "22h: mọi người đã vào nhà")
	_tv(float(c8["_ms"]) < 8.0, "cập nhật cả làng %.2f ms/khung (headless)" % float(c8["_ms"]))
	var sample: Object = null
	for h in res:
		if h.def["res"] == "farmer": sample = h; break
	if sample != null:
		var r2: Array = vm.route(sample.def["tg"]["in"], sample.def["tg"]["field"])
		var dlen := 0.0
		for i in range(r2.size() - 1): dlen += (r2[i] as Vector2).distance_to(r2[i + 1])
		var straight: float = (sample.def["tg"]["in"] as Vector2).distance_to(sample.def["tg"]["field"])
		_tv(r2.size() > 3 and dlen < straight * 2.5, "đường ra đồng theo đường làng: %d điểm, %.0f m (đường chim bay %.0f m)" % [r2.size(), dlen, straight])
	# 7d. tên con vật (chủ dự án đặt)
	var names := {}
	for h in adult.hosts:
		if h.def.has("nick"): names[h.k] = h.def["nick"]
	var want_n := {"dog": "Nguyên", "hen": "Trọng", "cow": "Vy", "cat": "Nhi", "mouse": "Thức", "bird": "Hân", "pig": "Giang"}
	_tv(names == want_n, "tên con vật: %s" % names)
	# 8. nguồn mật & chỗ ẩn
	_tv(adult.flowers.size() >= 30 and adult.bushes.size() >= 100, "%d hoa, %d chỗ ẩn nấp" % [adult.flowers.size(), adult.bushes.size()])
	print("[village] %s — %d lỗi" % ["ĐẠT" if _tv_fail == 0 else "CHƯA ĐẠT", _tv_fail])

# ═════════ thoại NPC miền Tây (talk.gd + data/thoai_mientay.json) ═════════
func _test_talk() -> void:
	var D := Talk.data()
	_tv(not D.is_empty() and Talk.personas().size() == 7, "nạp kho thoại, %d tính cách" % Talk.personas().size())
	var ctxs: Array = D["lines"].keys()
	var total := 0
	var long := []
	var fake := 0
	var marked := 0
	for c in ctxs:
		for p in D["lines"][c]:
			for l in D["lines"][c][p]:
				var t := String(l)
				total += 1
				if t.length() > 72: long.append(t)
				for f in ["mèn ơi", "trời đất ơi", "nghen", " hen.", " hen!", " hen?"]:
					if t.to_lower().contains(f): fake += 1
				for m in ["hổng", "hông", "dzậy", "dìa", "quá trời", "dữ vậy", "thiệt", "coi", "hoài", "bây", "mậy", "chớ"]:
					if t.contains(m):
						marked += 1
						break
	print("[talk] %d câu trong %d ngữ cảnh + %d cặp hỏi–đáp" % [total, ctxs.size(), D["chat"].size()])
	_tv(long.is_empty(), "câu ngắn (≤ 72 ký tự)%s" % ("" if long.is_empty() else ": " + str(long)))
	_tv(fake <= 1, "không lạm dụng 'mèn ơi / trời đất ơi / nghen / hen' (%d lần)" % fake)
	var ratio := float(marked) / total
	_tv(ratio > .12 and ratio < .55, "khẩu ngữ Nam Bộ có mà không nhồi: %d%% câu có hổng/dìa/hoài/coi…" % int(ratio * 100))
	var miss_ctx := []
	for p in Talk.personas():
		for c in Talk.ANNOYED:
			if Talk.pool(c, p).is_empty(): miss_ctx.append("%s/%s" % [c, p])
	_tv(miss_ctx.is_empty(), "mọi tính cách đều có câu cho mọi phản ứng với muỗi %s" % str(miss_ctx))
	# dân làng thật trong game → tỉ lệ chửi vui khi bị muỗi làm phiền
	Game.new_lineage()
	Game.L["sex"] = "F"
	Game.L["site"] = 2
	Game.new_generation_stats()
	adult.enter(false)
	var people := []
	for h in adult.hosts:
		if h.persona != "": people.append(h)
	var mix := {}
	for h in people: mix[h.persona] = int(mix.get(h.persona, 0)) + 1
	print("[talk] %d người biết nói, tính cách: %s" % [people.size(), mix])
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var rough := 0
	var n := 0
	var unfilled := 0
	for k in 4000:
		var h = people[rng.randi() % people.size()]
		var c: String = ["scratch", "swat", "miss", "bitten", "hear", "lost", "hit"][rng.randi() % 7]
		var l := Talk.pick(c, h.persona, "t%d" % k, h.me, rng)
		if l == "": continue
		n += 1
		if Talk.last_rough: rough += 1
		if l.contains("{"): unfilled += 1
	var rr := float(rough) / maxf(n, 1)
	_tv(rr >= .04 and rr <= .12, "chửi vui / cà khịa khi bị muỗi làm phiền: %.1f%% (mục tiêu 5–10%%)" % (rr * 100))
	_tv(unfilled == 0, "đã thay hết {t}/{T}")
	# phản ứng thật trong game: NPC bị làm phiền thì nói; hàng xóm đứng gần thì nói chuyện qua lại
	adult.A["clock"] = 19.2
	adult.snap_residents()
	adult.A["spray_at"] = -1.0
	for d in adult.dragons: d.st = "rest"; d.t = 99.0
	var a1 = null
	var a2 = null
	for h in people:
		if h.def.has("res") and h.act == "sit" and not h.away:
			if a1 == null: a1 = h
			elif a2 == null and (h.def["tg"]["in"] as Vector2).distance_to(a1.def["tg"]["in"]) > 30.0: a2 = h
	_tv(a1 != null, "có người đang ngồi hóng mát lúc 19h")
	if a1 == null: return
	adult.body.global_position = Vector3(a1.pos.x + 1.5, adult.gy(a1.pos.x, a1.pos.y) + 1.4, a1.pos.y + 1.5)
	a1.say_cd = 0.0
	a1.alert = .75
	var said := []
	for k in 40:
		adult.A["clock"] = 19.2
		adult.update(1.0 / 30.0)
		if a1.say_t > 0.0 and not said.has(a1.say_text): said.append(a1.say_text)
	_tv(not said.is_empty(), "%s (%s) bị muỗi làm phiền → nói: %s" % [a1.def["name"], a1.persona, said])
	if a2 != null:
		a2.pos = a1.pos + Vector2(2.0, 0)
		a2.def["tg"]["sit"] = a2.pos
		a1.alert = 0.0; a1.react = ""; a2.alert = 0.0
		a1.say_t = 0.0; a2.say_t = 0.0; a2.q_t = 0.0
		var got := false
		for tries in 30:
			a1.chat_t = 0.0
			a1.say_t = 0.0
			adult.update(1.0 / 30.0)
			if a2.q_t > 0.0:
				got = true
				print("[talk]   %s: “%s”  →  %s: “%s”" % [a1.def["name"], a1.say_text, a2.def["name"], a2.q_text])
				break
		_tv(got, "hai người ngồi gần nhau thì nói chuyện qua lại")
	print("[talk] vài câu mẫu:")
	for k in 14:
		var h = people[rng.randi() % people.size()]
		var c: String = ctxs[rng.randi() % ctxs.size()]
		var l := Talk.pick(c, h.persona, "m%d" % k, h.me, rng)
		if l != "": print("   [%s · %s] %s" % [Talk.data()["personas"][h.persona]["name"], c, l])
	print("[talk] %s — %d lỗi" % ["ĐẠT" if _tv_fail == 0 else "CHƯA ĐẠT", _tv_fail])

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
