extends Node2D

@export var custom_scene_theme: String = ""
@export var next_scene_path: String = ""

var _scene_transition_active := false
var _spawn_pos := Vector2.ZERO
var _camera_following := false

@onready var arena: CloudArena = $CloudArena
@onready var entities: Node2D = $YSort/Entities
@onready var player: PlayerController = $YSort/Entities/Player
@onready var camera: Camera2D = $YSort/Entities/Player/Camera2D
@onready var effects: Node2D = $Effects
@onready var combat: CombatSystem = $CombatSystem
@onready var progression: ProgressionSystem = $ProgressionSystem
@onready var floor_manager: FloorManager = $FloorManager
@onready var ui: UIManager = $UIManager


func _ready() -> void:
	combat.setup(effects, camera)
	combat.painted_visuals = arena.painted_visuals
	player.setup(combat, arena)
	floor_manager.setup(player, combat, arena, entities)

	# Wire Player -> UI
	player.hp_changed.connect(ui.update_hp)
	player.cooldowns_updated.connect(ui.update_cooldowns)
	player.died.connect(ui.show_game_over)

	# Wire Progression -> UI
	progression.exp_changed.connect(ui.update_exp)
	progression.level_up_choices_ready.connect(ui.show_upgrade_choices)
	ui.upgrade_selected.connect(func(upg: Dictionary) -> void:
		progression.on_upgrade_chosen(upg, player)
		GameData.selected_upgrades.append(upg.duplicate(true))
	)

	# Wire FloorManager -> Progression & UI
	floor_manager.wave_changed.connect(ui.update_wave)
	floor_manager.enemy_killed.connect(progression.add_exp)
	floor_manager.boss_spawned.connect(_on_boss_spawned)
	floor_manager.portal_unlocked.connect(func(portal: CloudPortal) -> void:
		var objective := "Cổng đã mở! Hãy bước vào!"
		if portal.village_exit:
			objective = "Hãy bước vào cổng để đến Thang Mây."
		elif portal.heaven_gate or not arena.painted_visuals:
			objective = "Cổng Thiên Giới đã mở! Hãy bước vào!"
		ui.update_wave(5, 5, objective)
	)
	floor_manager.floor_cleared.connect(_on_floor_cleared)

	ui.restart_requested.connect(func() -> void:
		GameData.reset_run()
		get_tree().reload_current_scene()
	)

	if GameData.scene_entry.get("scene", "") == scene_file_path:
		var entry := GameData.scene_entry.duplicate(true)
		GameData.scene_entry.clear()
		for upgrade in GameData.selected_upgrades:
			player.apply_upgrade(upgrade, false)
		player.current_hp = clampi(int(entry.get("hp", player.max_hp)), 1, player.max_hp)
		progression.restore(entry)
		var fade := _create_scene_fade(1.0)
		var reveal := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		reveal.tween_property(fade, "color:a", 0.0, 0.22)
		reveal.tween_callback(fade.get_parent().queue_free)
	else:
		GameData.reset_run()
		progression.reset()
	GameData.loot_changed.connect(ui.update_loot)
	ui.update_loot(GameData.loot_currency)
	ui.update_hp(player.current_hp, player.max_hp)
	camera.zoom = Vector2(0.75, 0.75)
	if custom_scene_theme != "":
		if arena.scene_theme != custom_scene_theme:
			arena.scene_theme = custom_scene_theme
			arena._rebuild_visuals()
			arena._spawn_pillars()
		match custom_scene_theme:
			"mortal_realm":
				player.position = Vector2(0, 60)
				camera.position = Vector2(0, 23)
			"stairway_clouds":
				player.position = Vector2(-475, 145)
				camera.position = Vector2(475, -75)
			"azure_outskirts":
				player.position = Vector2(-280, 91)
				camera.position = Vector2(280, -8)
			"azure_center":
				player.position = Vector2(-120, 60)
				camera.position = Vector2(120, 20)
			"boss_arena":
				player.position = Vector2(-220, 120)
				camera.position = Vector2(220, -75)
			"gate_of_heaven":
				player.position = Vector2(-102, 105)
				camera.position = Vector2(102, -132)
		camera.reset_smoothing()
		_spawn_pos = player.position
		floor_manager.start_scene_encounter(custom_scene_theme)
	else:
		_spawn_pos = player.position
		floor_manager.start_floor()


func _process(delta: float) -> void:
	if player == null or camera == null or player.get("_is_dead"):
		return
	if not _camera_following and player.position.distance_to(_spawn_pos) > 8.0:
		_camera_following = true
	if _camera_following and camera.position.length_squared() > 0.25:
		camera.position = camera.position.lerp(Vector2.ZERO, clampf(delta * 2.5, 0.0, 1.0))


func _on_floor_cleared() -> void:
	if _scene_transition_active or (player != null and player.get("_is_dead")):
		return
	if next_scene_path.is_empty() or not ResourceLoader.exists(next_scene_path):
		ui.show_victory()
		return

	_scene_transition_active = true
	ui.set_process_unhandled_input(false)
	var tree := get_tree()
	tree.paused = true
	var fade := _create_scene_fade(0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var transition := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	transition.tween_property(fade, "color:a", 1.0, 0.22)
	await transition.finished

	GameData.scene_entry = progression.snapshot()
	GameData.scene_entry["hp"] = player.current_hp
	GameData.scene_entry["scene"] = next_scene_path
	tree.paused = false
	var result := tree.change_scene_to_file(next_scene_path)
	if result != OK:
		_scene_transition_active = false
		ui.set_process_unhandled_input(true)
		fade.get_parent().queue_free()
		GameData.scene_entry.clear()
		push_error("Could not load Cloudbound scene: " + next_scene_path)


func _create_scene_fade(alpha: float) -> ColorRect:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var fade := ColorRect.new()
	fade.color = Color(0.0, 0.0, 0.0, alpha)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return fade


func _on_boss_spawned(boss: BossController) -> void:
	ui.show_boss_bar(boss.boss_name, boss.current_hp, boss.max_hp, boss.phase)
	boss.hp_changed.connect(ui.update_boss_hp)
	boss.phase_changed.connect(func(new_phase: int) -> void:
		ui.show_boss_bar(boss.boss_name, boss.current_hp, boss.max_hp, new_phase)
	)
