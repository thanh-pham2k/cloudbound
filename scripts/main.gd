extends Node2D

@export var custom_scene_theme: String = ""
@export var next_scene_path: String = ""

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
	floor_manager.floor_cleared.connect(func() -> void:
		if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
			get_tree().change_scene_to_file(next_scene_path)
		else:
			ui.show_victory()
	)

	ui.restart_requested.connect(func() -> void:
		get_tree().reload_current_scene()
	)

	progression.reset()
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
		floor_manager.start_scene_encounter(custom_scene_theme)
	else:
		floor_manager.start_floor()


func _on_boss_spawned(boss: BossController) -> void:
	ui.show_boss_bar(boss.boss_name, boss.current_hp, boss.max_hp, boss.phase)
	boss.hp_changed.connect(ui.update_boss_hp)
	boss.phase_changed.connect(func(new_phase: int) -> void:
		ui.show_boss_bar(boss.boss_name, boss.current_hp, boss.max_hp, new_phase)
	)
