class_name HoaQuaSonWorld
extends Node2D
## Playable Semantic Layout prototype for Phase 2 — Hoa Qua Son.
## Builds the 4 connected areas + secret branch from HoaQuaSonLayout.

const L := preload("res://scripts/world/hoa_qua_son_layout.gd")
const P := L.PALETTE

var player: PlayerController
var entities_root: Node2D
var terrain_layer: ConceptTerrain
var elder_npc: InteractableObject
var boss_chest: InteractableObject
var boss_exit: InteractableObject
var boss_exit_blocker: CollisionShape2D

# Quest progression: 0 = talk to Elder for Q1, 1 = Q1 active (kill 3), 2 = Q1 turn-in,
# 3 = Q2 active (collect 5 peaches), 4 = Q2 turn-in, 5 = Q3 active (defeat boss), 6 = Q3 done
var quest_stage: int = 0
var kills_count: int = 0
var peaches_count: int = 0
var boss_defeated: bool = false

var _hud_stats: Label
var _hud_area: Label
var _hud_hp_bar: ProgressBar
var _hud_exp_bar: ProgressBar
var _hud_quest: Label
var _hud_prompt: Label
var _dialogue_panel: PanelContainer
var _dialogue_speaker: Label
var _dialogue_body: Label
var _dialogue_npc_pos: Vector2 = Vector2.ZERO
var _toast_label: Label
var _toast_timer: float = 0.0


func _ready() -> void:
	_build_ground()
	_build_outer_boundary()

	entities_root = Node2D.new()
	entities_root.name = "Entities"
	entities_root.y_sort_enabled = true
	add_child(entities_root)

	_build_monkey_village()
	_build_peach_forest()
	_build_monster_clearing()
	_build_boss_cave()
	_spawn_player()
	_build_hud()
	_refresh_hud()


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and _toast_label:
			_toast_label.visible = false
	if player and _hud_prompt:
		var p := player.get_nearest_interactable_prompt()
		_hud_prompt.text = p
		_hud_prompt.visible = not p.is_empty() and not (_dialogue_panel and _dialogue_panel.visible)
		_hud_area.text = "Khu vực: %s" % _get_current_area_name(player.global_position)
		if _dialogue_panel and _dialogue_panel.visible and player.global_position.distance_to(_dialogue_npc_pos) > 110.0:
			_dialogue_panel.visible = false


func _build_ground() -> void:
	terrain_layer = ConceptTerrain.new()
	terrain_layer.name = "ConceptTerrain"
	add_child(terrain_layer)


func _build_outer_boundary() -> void:
	var body := StaticBody2D.new()
	body.name = "OuterBoundary"
	body.collision_layer = 2
	body.collision_mask = 0
	var poly := CollisionPolygon2D.new()
	poly.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	poly.polygon = PackedVector2Array(L.WALKABLE_BOUNDARY)
	body.add_child(poly)
	add_child(body)


func _build_monkey_village() -> void:
	var spawn_disc := IsoPlaceholder.new()
	spawn_disc.kind = "spawn_disc"
	spawn_disc.position = L.SPAWN_POS
	spawn_disc.z_index = -1
	add_child(spawn_disc)

	for i in L.HUTS.size():
		var hut: Dictionary = L.HUTS[i]
		var hut_kind := "hut" if i == 0 else "hut_small"
		_add_static_prop(hut_kind, hut["pos"], hut["scale"], Vector2(44.0, 22.0) * hut["scale"])

	for pos in L.FENCES:
		_add_static_prop("fence", pos, 1.0, Vector2(22.0, 8.0))
	for pos in L.LANTERNS:
		_add_static_prop("lantern", pos, 1.0, Vector2(10.0, 6.0))

	for npc_data in L.NPCS:
		var npc := InteractableObject.new()
		npc.kind = "npc"
		npc.item_id = npc_data["id"]
		npc.display_name = npc_data["name"]
		npc.position = npc_data["pos"]
		npc.prompt_text = "[E] Nói chuyện với %s" % npc_data["name"]
		npc.interacted.connect(_on_npc_interacted)
		entities_root.add_child(npc)
		if npc_data["id"] == "elder_monkey":
			elder_npc = npc


func _build_peach_forest() -> void:
	for pos in L.PEACH_TREES:
		_add_static_prop("peach_tree", pos, 1.0, Vector2(12.0, 8.0))
	for pos in L.GREEN_TREES:
		_add_static_prop("green_tree", pos, 1.0, Vector2(12.0, 8.0))
	for pos in L.BUSHES:
		_add_static_prop("bush", pos, 1.0, Vector2(16.0, 8.0))
	for pos in L.GRASS_TUFTS:
		var tuft := IsoPlaceholder.new()
		tuft.kind = "grass_tuft"
		tuft.position = pos
		tuft.z_index = -1
		add_child(tuft)

	for pos in L.PEBBLES:
		var peb := IsoPlaceholder.new()
		peb.kind = "pebble"
		peb.position = pos
		peb.z_index = -1
		add_child(peb)

	var stream := IsoPlaceholder.new()
	stream.kind = "stream"
	stream.position = L.BRIDGE_POS + Vector2(5.0, 5.0)
	stream.z_index = -2
	add_child(stream)

	var bridge := IsoPlaceholder.new()
	bridge.kind = "bridge"
	bridge.position = L.BRIDGE_POS
	bridge.z_index = -1
	add_child(bridge)

	for i in L.PEACH_PICKUPS.size():
		var peach := InteractableObject.new()
		peach.kind = "peach"
		peach.item_id = "peach_%d" % i
		peach.display_name = "Đào Tiên"
		peach.position = L.PEACH_PICKUPS[i]
		peach.prompt_text = "[E] Nhặt Đào Tiên"
		peach.interacted.connect(_on_peach_interacted)
		entities_root.add_child(peach)

	_add_static_prop("peach_tree", L.SECRET_SPECIAL_TREE, 1.2, Vector2(14.0, 9.0))

	var secret_chest := InteractableObject.new()
	secret_chest.kind = "chest"
	secret_chest.item_id = "secret_chest"
	secret_chest.display_name = "Rương Bí Mật"
	secret_chest.position = L.SECRET_CHEST_POS
	secret_chest.prompt_text = "[E] Mở Rương Bí Mật"
	secret_chest.interacted.connect(_on_chest_interacted)
	entities_root.add_child(secret_chest)


func _build_monster_clearing() -> void:
	for pos in L.ROCKS:
		_add_static_prop("rock", pos, 1.0, Vector2(20.0, 11.0))

	for m in L.MONSTERS:
		var enemy := EnemyBase.new()
		enemy.enemy_id = m["id"]
		enemy.enemy_kind = m.get("kind", "boar")
		enemy.display_name = m["name"]
		if enemy.enemy_kind == "imp":
			enemy.max_hp = 50
			enemy.move_speed = 135.0
			enemy.attack_damage = 14
		enemy.position = m["pos"]
		enemy.died.connect(_on_enemy_died)
		entities_root.add_child(enemy)


func _build_boss_cave() -> void:
	var cave_wall := IsoPlaceholder.new()
	cave_wall.kind = "cave_wall"
	cave_wall.position = Vector2(2205.0, -1170.0)
	cave_wall.item_scale = 1.0
	cave_wall.z_index = -2
	add_child(cave_wall)

	var stairs := IsoPlaceholder.new()
	stairs.kind = "stairs"
	stairs.position = Vector2(2010.0, -975.0)
	stairs.z_index = -1
	add_child(stairs)

	var front_rim := IsoPlaceholder.new()
	front_rim.kind = "cave_front_rim"
	front_rim.position = Vector2(2270, -992)
	front_rim.z_index = -1
	add_child(front_rim)

	for pos in L.BOSS_TORCHES:
		_add_static_prop("torch", pos, 1.0, Vector2(10.0, 6.0))

	var boss := EnemyBase.new()
	boss.enemy_id = L.BOSS["id"]
	boss.display_name = L.BOSS["name"]
	boss.is_boss = true
	boss.max_hp = 180
	boss.attack_damage = 18
	boss.move_speed = 130.0
	boss.detect_radius = 240.0
	boss.leash_radius = 320.0
	boss.attack_range = 60.0
	boss.reward_exp = 150
	boss.reward_gold = 50
	boss.position = L.BOSS["pos"]
	boss.died.connect(_on_enemy_died)
	entities_root.add_child(boss)

	boss_chest = InteractableObject.new()
	boss_chest.kind = "chest"
	boss_chest.item_id = "boss_chest"
	boss_chest.display_name = "Rương Yêu Vương"
	boss_chest.position = L.BOSS_CHEST_POS
	boss_chest.prompt_text = "[E] Mở Rương Phần Thưởng"
	boss_chest.visible = false
	boss_chest.active = false
	boss_chest.interacted.connect(_on_chest_interacted)
	entities_root.add_child(boss_chest)

	boss_exit = InteractableObject.new()
	boss_exit.kind = "exit_arch"
	boss_exit.item_id = "boss_exit"
	boss_exit.display_name = "Cổng Khu Vực Mới"
	boss_exit.position = L.BOSS_EXIT_POS
	boss_exit.prompt_text = "[E] Cổng bị khóa (Hạ Yêu Vương để mở)"
	boss_exit.unlocked = false
	boss_exit.interacted.connect(_on_exit_interacted)
	entities_root.add_child(boss_exit)

	var gate_body := StaticBody2D.new()
	gate_body.name = "BossExitBlocker"
	gate_body.position = L.BOSS_EXIT_POS
	gate_body.collision_layer = 2
	gate_body.collision_mask = 0
	boss_exit_blocker = CollisionShape2D.new()
	var gate_rect := RectangleShape2D.new()
	gate_rect.size = Vector2(72.0, 26.0)
	boss_exit_blocker.shape = gate_rect
	gate_body.add_child(boss_exit_blocker)
	entities_root.add_child(gate_body)


func _add_static_prop(kind: String, pos: Vector2, s: float, col_half: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 2
	body.collision_mask = 0

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = col_half * 2.0
	col.shape = rect
	body.add_child(col)

	var vis := IsoPlaceholder.new()
	vis.kind = kind
	vis.item_scale = s
	body.add_child(vis)

	entities_root.add_child(body)


func _spawn_player() -> void:
	player = PlayerController.new()
	player.name = "Player"
	player.position = L.SPAWN_POS
	player.spawn_position = L.SPAWN_POS
	player.stats_changed.connect(_refresh_hud)
	player.respawned.connect(func(): _show_toast("Bạn đã hồi sinh tại Làng Khỉ (giữ nguyên EXP & Vàng)."))

	var cam := Camera2D.new()
	cam.name = "Camera2D"
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	player.add_child(cam)

	entities_root.add_child(player)


func _on_npc_interacted(item: InteractableObject, p: PlayerController) -> void:
	if _dialogue_panel and _dialogue_panel.visible:
		_dialogue_panel.visible = false
		return

	_dialogue_npc_pos = item.global_position

	match quest_stage:
		0:
			quest_stage = 1
			_show_dialogue("Khỉ Trưởng Lão", "Yêu quái đang quấy phá ngoài Bãi Quái! Ngộ Không hãy tiêu diệt 3 Lợn Rừng để bảo vệ làng. (Thưởng: 50 EXP + 20 Vàng)")
		1:
			if kills_count >= 3:
				quest_stage = 3
				p.grant_rewards(50, 20)
				_show_dialogue("Khỉ Trưởng Lão", "Làm tốt lắm! (+50 EXP, +20 Vàng)\nNhiệm vụ 2: Hãy thu thập 5 Đào Tiên dưới gốc cây trong Rừng Đào. (Thưởng: 40 EXP + 15 Vàng)")
			else:
				_show_dialogue("Khỉ Trưởng Lão", "Ngươi đã hạ %d/3 Lợn Rừng ở Bãi Quái. Cố lên!" % kills_count)
		3:
			if peaches_count >= 5:
				quest_stage = 5
				p.grant_rewards(40, 15)
				_show_dialogue("Khỉ Trưởng Lão", "Tuyệt vời! (+40 EXP, +15 Vàng)\nNhiệm vụ cuối: Tiến vào Hang Boss đánh bại Yêu Vương để mở khóa khu vực mới! (Thưởng: 150 EXP)")
			else:
				_show_dialogue("Khỉ Trưởng Lão", "Đã thu thập %d/5 Đào Tiên. Nhớ kiểm tra dưới gốc các cây đào!" % peaches_count)
		5:
			if boss_defeated:
				quest_stage = 6
				_show_dialogue("Khỉ Trưởng Lão", "Hoa Quả Sơn đã bình yên! Cổng khu vực mới ở Hang Boss đã mở khóa.")
			else:
				_show_dialogue("Khỉ Trưởng Lão", "Yêu Vương đang chờ ở Hang Boss phía Đông Bắc. Hãy dùng Space để né đòn đập đất!")
		_:
			_show_dialogue("Khỉ Trưởng Lão", "Chúc mừng Đại Thánh đã hoàn thành chương đầu của Hoa Quả Sơn!")
	_refresh_hud()


func _show_dialogue(speaker: String, body: String) -> void:
	if _dialogue_panel:
		_dialogue_speaker.text = speaker
		_dialogue_body.text = body
		_dialogue_panel.visible = true


func _on_peach_interacted(item: InteractableObject, p: PlayerController) -> void:
	peaches_count += 1
	p.heal(25)
	item.active = false
	item.visible = false
	_show_toast("Nhặt Đào Tiên (%d/5) — Hồi 25 HP!" % peaches_count)
	_refresh_hud()


func _on_chest_interacted(item: InteractableObject, p: PlayerController) -> void:
	item.set_opened(true)
	if item.item_id == "secret_chest":
		p.heal(50)
		p.grant_rewards(30, 25)
		_show_toast("Mở Rương Bí Mật: +50 HP, +30 EXP, +25 Vàng!")
	else:
		p.grant_rewards(50, 50)
		_show_toast("Mở Rương Yêu Vương: +50 EXP, +50 Vàng!")
	_refresh_hud()


func _on_enemy_died(_enemy_id: String, is_boss: bool, rew_exp: int, rew_gold: int) -> void:
	if player:
		player.grant_rewards(rew_exp, rew_gold)
	if is_boss:
		boss_defeated = true
		if boss_chest:
			boss_chest.visible = true
			boss_chest.active = true
		if boss_exit:
			boss_exit.set_unlocked(true)
			boss_exit.prompt_text = "[E] Bước qua Cổng Khu Vực Mới (Hoàn thành Vertical Slice)"
		if boss_exit_blocker:
			boss_exit_blocker.set_deferred("disabled", true)
		if terrain_layer:
			terrain_layer.mark_boss_cleared()
		_show_toast("Yêu Vương đã bị đánh bại! Rương phần thưởng & Cổng khu vực mới đã mở!")
	else:
		kills_count += 1
		_show_toast("Đã hạ yêu quái (%d/3) — +%d EXP, +%d Vàng" % [kills_count, rew_exp, rew_gold])
	_refresh_hud()


func _on_exit_interacted(_item: InteractableObject, _p: PlayerController) -> void:
	if boss_defeated:
		_show_toast("CHÚC MỪNG! Bạn đã hoàn thành Vertical Slice Hoa Quả Sơn (4 khu vực + Boss)!")
	else:
		_show_toast("Cổng đang bị phong ấn. Hãy đánh bại Yêu Vương trước!")


func _get_current_area_name(pos: Vector2) -> String:
	var best_name := "Đường mòn"
	var best_dist := INF
	for area in L.AREAS:
		var d := pos.distance_to(area["center"])
		if d <= area["radius"].x * 0.95 and d < best_dist:
			best_dist = d
			best_name = area["name"]
	return best_name


func _make_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.118, 0.161, 0.231, 0.86)
	sb.border_color = P["gold"]
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	return sb


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)

	var panel_style := _make_panel_style()

	# Top-left Player Status Panel
	var stats_panel := PanelContainer.new()
	stats_panel.position = Vector2(14, 12)
	stats_panel.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(stats_panel)

	var stats_box := VBoxContainer.new()
	stats_box.custom_minimum_size = Vector2(280, 0)
	stats_panel.add_child(stats_box)

	_hud_stats = Label.new()
	_hud_stats.add_theme_font_size_override("font_size", 14)
	stats_box.add_child(_hud_stats)

	_hud_hp_bar = ProgressBar.new()
	_hud_hp_bar.custom_minimum_size = Vector2(260, 12)
	_hud_hp_bar.show_percentage = false
	_hud_hp_bar.modulate = Color("#EF4444")
	stats_box.add_child(_hud_hp_bar)

	_hud_exp_bar = ProgressBar.new()
	_hud_exp_bar.custom_minimum_size = Vector2(260, 8)
	_hud_exp_bar.show_percentage = false
	_hud_exp_bar.modulate = Color("#FBBF24")
	stats_box.add_child(_hud_exp_bar)

	_hud_area = Label.new()
	_hud_area.add_theme_color_override("font_color", P["gold"])
	_hud_area.add_theme_font_size_override("font_size", 13)
	stats_box.add_child(_hud_area)

	# Top-right Quest Tracker Panel
	var quest_panel := PanelContainer.new()
	quest_panel.position = Vector2(906, 12)
	quest_panel.custom_minimum_size = Vector2(360, 0)
	quest_panel.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(quest_panel)

	_hud_quest = Label.new()
	_hud_quest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud_quest.add_theme_font_size_override("font_size", 14)
	quest_panel.add_child(_hud_quest)

	# Bottom-center NPC Dialogue Panel
	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.position = Vector2(260, 520)
	_dialogue_panel.custom_minimum_size = Vector2(760, 110)
	_dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	_dialogue_panel.visible = false
	layer.add_child(_dialogue_panel)

	var dlg_box := VBoxContainer.new()
	_dialogue_panel.add_child(dlg_box)

	_dialogue_speaker = Label.new()
	_dialogue_speaker.add_theme_color_override("font_color", P["gold"])
	_dialogue_speaker.add_theme_font_size_override("font_size", 16)
	dlg_box.add_child(_dialogue_speaker)

	_dialogue_body = Label.new()
	_dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_body.add_theme_font_size_override("font_size", 14)
	dlg_box.add_child(_dialogue_body)

	var dlg_hint := Label.new()
	dlg_hint.text = "[E] Đóng hội thoại"
	dlg_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dlg_hint.add_theme_color_override("font_color", P["stone_light"])
	dlg_hint.add_theme_font_size_override("font_size", 12)
	dlg_box.add_child(dlg_hint)

	_hud_prompt = Label.new()
	_hud_prompt.position = Vector2(340, 642)
	_hud_prompt.size = Vector2(600, 28)
	_hud_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_prompt.add_theme_color_override("font_color", P["gold"])
	_hud_prompt.add_theme_color_override("font_outline_color", P["ink"])
	_hud_prompt.add_theme_constant_override("outline_size", 4)
	_hud_prompt.visible = false
	layer.add_child(_hud_prompt)

	var controls := Label.new()
	controls.text = "WASD: Di chuyển | Space: Lướt | K: Đánh gậy | E: Tương tác | F2: Thử phân vùng"
	controls.position = Vector2(340, 682)
	controls.size = Vector2(600, 28)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_color_override("font_outline_color", P["ink"])
	controls.add_theme_constant_override("outline_size", 3)
	layer.add_child(controls)

	_toast_label = Label.new()
	_toast_label.position = Vector2(240, 92)
	_toast_label.size = Vector2(800, 36)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_color_override("font_color", Color.WHITE)
	_toast_label.add_theme_color_override("font_outline_color", P["ink"])
	_toast_label.add_theme_constant_override("outline_size", 4)
	_toast_label.visible = false
	layer.add_child(_toast_label)


func _refresh_hud() -> void:
	if player and _hud_stats:
		_hud_stats.text = "Ngộ Không Lv.%d | DMG %d | Vàng %d | HP %d/%d" % [
			player.level, player.attack_damage, player.gold, player.hp, player.max_hp
		]
		if _hud_hp_bar:
			_hud_hp_bar.max_value = player.max_hp
			_hud_hp_bar.value = player.hp
		if _hud_exp_bar:
			var exp_prog := player.get_exp_progress()
			_hud_exp_bar.max_value = exp_prog.y
			_hud_exp_bar.value = exp_prog.x
	if _hud_quest:
		var q_text := ""
		match quest_stage:
			0:
				q_text = "Nhiệm vụ: Gặp Khỉ Trưởng Lão [E]\nNhận nhiệm vụ bảo vệ Hoa Quả Sơn"
			1:
				var q1_done := kills_count >= 3
				q_text = "Q1 — Bảo vệ làng (%d/3)\n%s" % [
					mini(kills_count, 3),
					"Quay về gặp Khỉ Trưởng Lão [?]" if q1_done else "Hạ 3 Lợn Rừng tại Bãi Quái (Thưởng: 50 EXP, 20 Vàng)"
				]
			3:
				var q2_done := peaches_count >= 5
				q_text = "Q2 — Thu thập Đào Tiên (%d/5)\n%s" % [
					mini(peaches_count, 5),
					"Quay về gặp Khỉ Trưởng Lão [?]" if q2_done else "Tìm dưới gốc cây ở Rừng Đào (Thưởng: 40 EXP, 15 Vàng)"
				]
			5:
				q_text = "Q3 — Đánh bại Yêu Vương (%s)\n%s" % [
					"1/1" if boss_defeated else "0/1",
					"Mở rương & bước qua Cổng Hang Boss!" if boss_defeated else "Tiến vào Hang Boss (Thưởng: 150 EXP)"
				]
			_:
				q_text = "Hoàn thành Vertical Slice Hoa Quả Sơn!"
		_hud_quest.text = q_text
	if elder_npc:
		var ready_turn_in := (quest_stage == 1 and kills_count >= 3) or (quest_stage == 3 and peaches_count >= 5)
		elder_npc.set_quest_marker("?" if ready_turn_in else ("!" if quest_stage == 0 else ""))


func _show_toast(msg: String) -> void:
	if _toast_label:
		_toast_label.text = msg
		_toast_label.visible = true
		_toast_timer = 4.0


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		get_tree().change_scene_to_file("res://scenes/segmentation_slice.tscn")
