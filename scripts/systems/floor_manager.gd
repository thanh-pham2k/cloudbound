extends Node
class_name FloorManager

signal wave_changed(wave_num: int, total_waves: int, label: String)
signal boss_spawned(boss: BossController)
signal portal_unlocked(portal: CloudPortal)
signal floor_cleared
signal enemy_killed(exp_reward: int)

var _floor_cfg: Dictionary = {}
var _waves: Array = []
var _current_wave_idx: int = -1
var _wave_elapsed: float = 0.0
var _spawn_timer: float = 0.0
var _spawned_in_wave: int = 0
var _active_enemies: int = 0
var _boss_active: bool = false
var _floor_done: bool = false

var _player: PlayerController
var _combat: CombatSystem
var _arena: CloudArena
var _ysort_entities: Node2D


func setup(player: PlayerController, combat: CombatSystem, arena: CloudArena, entities_node: Node2D) -> void:
	_player = player
	_combat = combat
	_arena = arena
	_ysort_entities = entities_node
	_floor_cfg = GameData.get_floor_config(0)
	_waves = _floor_cfg.get("waves", [])
	if _arena != null and not _floor_cfg.is_empty() and _arena.scene_theme == "azure_outskirts":
		_arena.configure(float(_floor_cfg.get("arena_rx", 768.0)), float(_floor_cfg.get("arena_ry", 448.0)))


func start_floor() -> void:
	_current_wave_idx = -1
	_boss_active = false
	_floor_done = false
	_advance_wave()


func start_scene_encounter(theme: String) -> void:
	_current_wave_idx = -1
	_waves = []
	_boss_active = false
	_floor_done = false
	_active_enemies = 0
	match theme:
		"mortal_realm":
			wave_changed.emit(1, 6, "Cảnh 1: Phàm Gian — Làng Thanh Vân")
			_spawn_portal(Vector2(315, -25))
		"stairway_clouds":
			wave_changed.emit(2, 6, "Cảnh 2: Thang Mây — Cầu Đá Cổ")
			_spawn_specific_enemy("ranged", Vector2(540, 0))
		"azure_outskirts":
			wave_changed.emit(3, 6, "Cảnh 3: Ngoại Vi Thanh Vân")
			_spawn_specific_enemy("ranged", Vector2(60, 40))
			_spawn_specific_enemy("ranged", Vector2(180, -40))
			_spawn_specific_enemy("melee", Vector2(300, -100))
		"azure_center":
			wave_changed.emit(4, 6, "Cảnh 4: Trung Tâm Thanh Vân")
			_spawn_specific_enemy("melee", Vector2(-200, -120))
			_spawn_specific_enemy("ranged", Vector2(260, -140))
			_spawn_specific_enemy("ranged", Vector2(-260, 140))
			_spawn_specific_enemy("tank", Vector2(180, 120))
		"boss_arena":
			_spawn_boss()
		"gate_of_heaven":
			wave_changed.emit(6, 6, "Cảnh 6: Cổng Thiên Giới")
			_spawn_portal(Vector2(58, -162))
		_:
			start_floor()


func _spawn_specific_enemy(enemy_type: String, pos: Vector2) -> void:
	if _ysort_entities == null:
		return
	var enemy := EnemyBase.new()
	enemy.position = _arena.clamp_to_arena(pos, 32.0) if _arena != null else pos
	enemy.setup(enemy_type, _player, _combat, _arena)
	enemy.died.connect(func(exp_reward: int, _p: Vector2) -> void:
		_on_enemy_died(exp_reward, _p)
		if _active_enemies <= 0 and not _boss_active:
			_spawn_portal(Vector2(560, 0) if _arena != null and _arena.scene_theme == "stairway_clouds" else Vector2(0, -180))
	)
	_active_enemies += 1
	_ysort_entities.add_child(enemy)


func _process(delta: float) -> void:
	if _floor_done or _boss_active:
		return
	if _current_wave_idx < 0 or _current_wave_idx >= _waves.size():
		return

	var wave: Dictionary = _waves[_current_wave_idx]
	_wave_elapsed += delta
	_spawn_timer -= delta

	var total_to_spawn := int(wave.get("total_enemies", 10))
	if _spawned_in_wave < total_to_spawn and _spawn_timer <= 0.0:
		_spawn_enemy_from_wave(wave)
		_spawned_in_wave += 1
		_spawn_timer = float(wave.get("spawn_interval", 2.0))

	var max_dur := float(wave.get("duration_max", 90.0))
	if (_spawned_in_wave >= total_to_spawn and _active_enemies <= 0) or _wave_elapsed >= max_dur:
		_advance_wave()


func _advance_wave() -> void:
	_current_wave_idx += 1
	_wave_elapsed = 0.0
	_spawn_timer = 0.6
	_spawned_in_wave = 0

	if _current_wave_idx < _waves.size():
		var wave: Dictionary = _waves[_current_wave_idx]
		wave_changed.emit(_current_wave_idx + 1, _waves.size(), str(wave.get("label", "")))
	else:
		_spawn_boss()


func _spawn_enemy_from_wave(wave: Dictionary) -> void:
	if _arena == null or _ysort_entities == null:
		return
	var weights: Dictionary = wave.get("weights", {"melee": 1.0})
	var enemy_type := _pick_weighted(weights)
	var spawn_pos := _pick_spawn_pos()

	var enemy := EnemyBase.new()
	enemy.position = spawn_pos
	enemy.setup(enemy_type, _player, _combat, _arena)
	enemy.died.connect(_on_enemy_died)
	_active_enemies += 1
	_ysort_entities.add_child(enemy)


func _pick_spawn_pos() -> Vector2:
	for _i in range(12):
		var candidate := _arena.random_point_in_arena(240.0, 0.86)
		if _player == null or candidate.distance_to(_player.global_position) >= 260.0:
			return candidate
	return _arena.random_point_in_arena(0.0, 0.86)


func _pick_weighted(weights: Dictionary) -> String:
	var total := 0.0
	for k in weights.keys():
		total += float(weights[k])
	var roll := randf() * maxf(total, 0.001)
	var acc := 0.0
	for k in weights.keys():
		acc += float(weights[k])
		if roll <= acc:
			return str(k)
	return "melee"


func _on_enemy_died(exp_reward: int, _pos: Vector2) -> void:
	_active_enemies = maxi(0, _active_enemies - 1)
	if _player != null:
		_player.on_enemy_killed()
	enemy_killed.emit(exp_reward)


func _spawn_boss() -> void:
	_boss_active = true
	wave_changed.emit(_waves.size(), _waves.size(), "BOSS: Thiên Lôi Tướng")
	var boss := BossController.new()
	boss.position = Vector2(-57, -130) if (_arena != null and _arena.scene_theme == "boss_arena") else Vector2(0, -180)
	if _player != null and boss.position.distance_to(_player.global_position) < 220.0:
		boss.position = Vector2(0, 180)
	boss.setup(_player, _combat, _arena)
	boss.died.connect(_on_boss_died)
	_ysort_entities.add_child(boss)
	if _combat != null:
		_combat.spawn_circle_telegraph(boss.position, 145.0, 1.1, Color(1.0, 0.25, 0.2))
	boss_spawned.emit(boss)


func _on_boss_died(exp_reward: int, pos: Vector2) -> void:
	_boss_active = false
	enemy_killed.emit(exp_reward)
	_spawn_portal(pos)


func _spawn_portal(pos: Vector2) -> void:
	if _ysort_entities == null:
		return
	var portal := CloudPortal.new()
	if _arena != null:
		match _arena.scene_theme:
			"mortal_realm":
				portal.village_exit = true
				portal.visual_scale = 1.22
			"gate_of_heaven":
				portal.visual_scale = 1.65
	portal.position = _arena.clamp_to_arena(pos, 70.0) if _arena != null else pos
	portal.entered.connect(func() -> void:
		_floor_done = true
		floor_cleared.emit()
	)
	_ysort_entities.add_child(portal)
	portal_unlocked.emit(portal)
