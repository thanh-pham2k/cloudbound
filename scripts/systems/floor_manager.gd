extends Node
class_name FloorManager

signal wave_changed(wave_num: int, total_waves: int, label: String)
signal boss_spawned(boss: BossController)
signal portal_unlocked(portal: CloudPortal)
signal floor_cleared
signal enemy_killed(exp_reward: int)

@export_range(0.0, 1.0) var health_drop_chance := 0.22
@export_range(0.0, 1.0) var loot_drop_chance := 0.35
@export var health_amount := 18
@export var loot_amount := 1

const ORB_TEX := preload("res://assets/props/orb_pickup_01/base.png")
static var _orb_frames_cache: SpriteFrames


static func _get_orb_frames() -> SpriteFrames:
	if _orb_frames_cache == null:
		_orb_frames_cache = SpriteFrames.new()
		_orb_frames_cache.add_animation(&"orb_idle")
		_orb_frames_cache.add_frame(&"orb_idle", ORB_TEX)
	return _orb_frames_cache

var _floor_cfg: Dictionary = {}
var _waves: Array = []
var _current_wave_idx: int = -1
var _wave_elapsed: float = 0.0
var _spawn_timer: float = 0.0
var _spawned_in_wave: int = 0
var _active_enemies: int = 0
var _boss_active: bool = false
var _floor_done: bool = false
var _portal_spawned: bool = false
var _seamless_mode: bool = false
var _seamless_stage: int = 0

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
	_portal_spawned = false
	_advance_wave()


func start_scene_encounter(theme: String) -> void:
	_current_wave_idx = -1
	_waves = []
	_boss_active = false
	_floor_done = false
	_portal_spawned = false
	_seamless_mode = theme == "seamless_journey"
	_seamless_stage = 0
	_active_enemies = 0
	match theme:
		"seamless_journey":
			_seamless_stage = 1
			wave_changed.emit(1, 5, "Khu 1/5: Làng Thanh Vân — Tiến sang cầu đá!")
			# Zone 2 enemies
			_spawn_specific_enemy("ranged", Vector2(1380, -350))
			_spawn_specific_enemy("melee", Vector2(1580, -260))
			_spawn_specific_enemy("ranged", Vector2(1720, -340))
			# Zone 3 enemies
			_spawn_specific_enemy("melee", Vector2(2820, -730))
			_spawn_specific_enemy("ranged", Vector2(3120, -760))
			_spawn_specific_enemy("tank", Vector2(3050, -610))
		"mortal_realm":
			wave_changed.emit(1, 6, "Cảnh 1: Phàm Gian — Làng Thanh Vân")
			_spawn_portal(Vector2(315, -25))
		"stairway_clouds":
			wave_changed.emit(2, 6, "Cảnh 2: Thang Mây — Cầu Đá Cổ")
			_spawn_specific_enemy("ranged", Vector2(490, -86))
		"azure_outskirts":
			wave_changed.emit(3, 6, "Cảnh 3: Ngoại Vi Thanh Vân")
			_spawn_specific_enemy("ranged", Vector2(-160, -70))
			_spawn_specific_enemy("ranged", Vector2(328, -42))
			_spawn_specific_enemy("melee", Vector2(120, 118))
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
	enemy.died.connect(func(exp_reward: int, death_pos: Vector2) -> void:
		_on_enemy_died(exp_reward, death_pos)
		if not _seamless_mode and _active_enemies <= 0 and not _boss_active:
			_spawn_portal.call_deferred(Vector2(512, -106) if _arena != null and _arena.scene_theme == "stairway_clouds" else Vector2(0, -180))
	, CONNECT_ONE_SHOT)
	_active_enemies += 1
	_ysort_entities.add_child(enemy)


func _process(delta: float) -> void:
	if _seamless_mode and _player != null and not _floor_done:
		var px := _player.position.x
		if _seamless_stage == 1 and px >= 820.0:
			_seamless_stage = 2
			wave_changed.emit(2, 5, "Khu 2/5: Ngoại Vi Thanh Vân")
		elif _seamless_stage == 2 and px >= 2350.0:
			_seamless_stage = 3
			wave_changed.emit(3, 5, "Khu 3/5: Trung Tâm Thanh Vân")
		elif _seamless_stage == 3 and px >= 3920.0:
			_seamless_stage = 4
			_spawn_boss_at(Vector2(4760, -1160))
		elif _seamless_stage == 4 and _portal_spawned and px >= 5550.0:
			_seamless_stage = 5
			wave_changed.emit(5, 5, "Khu 5/5: Cổng Thiên Giới — Bước vào cổng!")
		return
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
	enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)
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


func _on_enemy_died(exp_reward: int, pos: Vector2) -> void:
	_active_enemies = maxi(0, _active_enemies - 1)
	if _player != null:
		_player.on_enemy_killed()
	enemy_killed.emit(exp_reward)
	if randf() < health_drop_chance:
		_spawn_pickup.call_deferred(OrbPickup.Kind.HEALTH, health_amount, pos, _get_orb_frames())
	if randf() < loot_drop_chance:
		_spawn_pickup.call_deferred(OrbPickup.Kind.LOOT, loot_amount, pos + Vector2(24, 0), _get_orb_frames())


func _spawn_pickup(kind: OrbPickup.Kind, amount: int, pos: Vector2, frames: SpriteFrames) -> void:
	if amount <= 0 or not is_instance_valid(_ysort_entities):
		return
	var pickup := OrbPickup.new()
	pickup.kind = kind
	pickup.amount = amount
	pickup.frames = frames
	pickup.position = _arena.clamp_to_arena(pos, 28.0) if _arena != null else pos
	_ysort_entities.add_child(pickup)


func _spawn_boss() -> void:
	var pos := Vector2(-57, -86) if (_arena != null and _arena.scene_theme == "boss_arena") else Vector2(0, -180)
	if _player != null and pos.distance_to(_player.global_position) < 220.0:
		pos = Vector2(0, 180)
	_spawn_boss_at(pos)


func _spawn_boss_at(pos: Vector2) -> void:
	_boss_active = true
	wave_changed.emit(4 if _seamless_mode else _waves.size(), 5 if _seamless_mode else _waves.size(), "BOSS: Thiên Lôi Tướng")
	var boss := BossController.new()
	boss.position = pos
	boss.setup(_player, _combat, _arena)
	boss.died.connect(_on_boss_died, CONNECT_ONE_SHOT)
	_ysort_entities.add_child(boss)
	if _combat != null:
		_combat.spawn_ring_burst(boss.position, 145.0, Color(0.45, 0.92, 1.0))
	boss_spawned.emit(boss)


func _on_boss_died(exp_reward: int, pos: Vector2) -> void:
	_boss_active = false
	enemy_killed.emit(exp_reward)
	_spawn_portal.call_deferred(Vector2(6240, -1510) if _seamless_mode else pos)


func _spawn_portal(pos: Vector2) -> void:
	if _ysort_entities == null or _portal_spawned:
		return
	_portal_spawned = true
	var portal := CloudPortal.new()
	if _arena != null:
		portal.painted_visuals = _arena.painted_visuals
		portal.heaven_gate = _arena.scene_theme == "gate_of_heaven"
		match _arena.scene_theme:
			"mortal_realm":
				portal.village_exit = true
				portal.visual_scale = 1.22
			"gate_of_heaven":
				portal.visual_scale = 1.18 if portal.painted_visuals else 1.65
	portal.position = _arena.clamp_to_arena(pos, 70.0) if _arena != null else pos
	if _player != null and is_instance_valid(_player) and portal.position.distance_to(_player.global_position) <= 84.0:
		portal.arm_delay = 0.55
	portal.entered.connect(func() -> void:
		_floor_done = true
		floor_cleared.emit()
	)
	_ysort_entities.add_child(portal)
	portal_unlocked.emit(portal)
