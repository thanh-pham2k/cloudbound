extends CharacterBody2D
class_name BossController

signal hp_changed(current_hp: int, max_hp: int)
signal phase_changed(phase: int)
signal died(exp_reward: int, pos: Vector2)

enum BossState { CHASE, TELEGRAPH, CHARGING, PHASE_TRANSITION, DEAD }

var boss_name: String = "Thiên Lôi Tướng"
var max_hp: int = 1650
var current_hp: int = 1650
var speed: float = 112.0
var phase: int = 1
var phase2_hp_ratio: float = 0.5
var exp_reward: int = 350

var _state: BossState = BossState.CHASE
var _is_dead: bool = false
var _pattern_idx: int = 0
var _atk_timer: float = 1.4
var _charge_timer: float = 0.0
var _charge_vel: Vector2 = Vector2.ZERO
var _charge_dmg: int = 30
var _charge_hit_radius: float = 68.0
var _charge_hit_done: bool = false
var _transition_timer: float = 0.0
var _hurt_timer: float = 0.0

var _facing: String = "down"
var _flip_h: bool = false
var _patterns: Dictionary = {}

var _player: Node2D
var _combat: CombatSystem
var _arena: CloudArena
var _sprite: AnimatedSprite2D
var _painted_animation := false


func setup(player: Node2D, combat: CombatSystem, arena: CloudArena) -> void:
	_player = player
	_combat = combat
	_arena = arena

	var cfg := GameData.get_boss_config()
	boss_name = str(cfg.get("name", "Thiên Lôi Tướng"))
	max_hp = int(cfg.get("max_hp", 1650))
	current_hp = max_hp
	speed = float(cfg.get("speed", 112.0))
	phase2_hp_ratio = float(cfg.get("phase2_hp_ratio", 0.5))
	exp_reward = int(cfg.get("exp_reward", 350))
	_patterns = cfg.get("patterns", {})


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	collision_layer = 4
	collision_mask = 1

	var cfg := GameData.get_boss_config()
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 28.0
	col.shape = shape
	add_child(col)

	_sprite = AnimatedSprite2D.new()
	var sp_path := str(cfg.get("sprite_frames", ""))
	if sp_path != "" and ResourceLoader.exists(sp_path):
		_sprite.sprite_frames = load(sp_path)
	var s := float(cfg.get("scale", 1.45))
	if _arena != null and _arena.scene_theme == "boss_arena":
		s *= 2.15
	_sprite.scale = Vector2(s, s)
	_sprite.offset = Vector2(0, -48)
	if _arena != null and _arena.painted_visuals:
		const GUARDIAN := preload("res://assets/generated/enemies/guardian/guardian_sprite_frames.tres")
		_sprite.sprite_frames = GUARDIAN
		_sprite.offset = Vector2(0.0, -63.0)
		_sprite.scale = Vector2.ONE * 225.0 / 120.0
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_painted_animation = true
	add_child(_sprite)

	hp_changed.emit(current_hp, max_hp)
	_play_anim("idle")


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_hurt_timer = maxf(0.0, _hurt_timer - delta)

	if _state == BossState.PHASE_TRANSITION:
		_transition_timer -= delta
		velocity = Vector2.ZERO
		if _transition_timer <= 0.0:
			_state = BossState.CHASE
			_atk_timer = 0.6
		return

	if _player == null or not is_instance_valid(_player) or _player.get("_is_dead"):
		velocity = Vector2.ZERO
		_play_anim("idle")
		return

	if _state == BossState.CHARGING:
		_charge_timer -= delta
		velocity = _charge_vel
		move_and_slide()
		if _arena != null:
			global_position = _arena.clamp_to_arena(global_position, 34.0)
		if not _charge_hit_done and _player.global_position.distance_to(global_position) <= _charge_hit_radius:
			_charge_hit_done = true
			if _player.has_method("take_damage"):
				_player.take_damage(_charge_dmg)
		if _charge_timer <= 0.0:
			_state = BossState.CHASE
			_atk_timer = 1.2 if phase == 1 else 0.85
		return

	if _state == BossState.TELEGRAPH:
		velocity = Vector2.ZERO
		return

	# CHASE state
	_atk_timer -= delta
	var to_player := _player.global_position - global_position
	var dir := to_player.normalized() if to_player.length() > 0.001 else Vector2.DOWN
	var cur_speed := speed * (1.28 if phase == 2 else 1.0)
	velocity = dir * cur_speed
	_update_facing(dir)
	move_and_slide()
	if _arena != null:
		global_position = _arena.clamp_to_arena(global_position, 34.0)

	if _hurt_timer > 0.0:
		_play_anim("hurt")
	elif velocity.length() > 10.0:
		_play_anim("walk")
	else:
		_play_anim("idle")

	if _atk_timer <= 0.0:
		_trigger_next_pattern()


func _trigger_next_pattern() -> void:
	_state = BossState.TELEGRAPH
	_play_anim("attack")
	var pat := _pattern_idx % 3
	_pattern_idx += 1

	match pat:
		0:
			_do_slam_pattern()
		1:
			_do_charge_pattern()
		_:
			_do_barrage_pattern()


func _do_slam_pattern() -> void:
	var cfg: Dictionary = _patterns.get("slam", {})
	var t_time := float(cfg.get("telegraph_time", 0.85)) * (0.85 if phase == 2 else 1.0)
	var rad := float(cfg.get("radius", 135.0))
	var dmg := int(cfg.get("damage", 28))
	var target_pos := _player.global_position

	if _combat == null:
		_state = BossState.CHASE
		return

	_play_anim("attack", "ground_slam", t_time)
	var t := _combat.spawn_circle_telegraph(target_pos, rad, t_time, Color(1.0, 0.25, 0.2))
	t.triggered.connect(func() -> void:
		if _is_dead:
			return
		_combat.spawn_ring_burst(target_pos, rad, Color(1.0, 0.35, 0.25))
		_combat.add_screen_shake(7.0)
		if _player != null and is_instance_valid(_player) and _player.global_position.distance_to(target_pos) <= rad + 16.0:
			if _player.has_method("take_damage"):
				_player.take_damage(dmg)

		if phase == 2:
			var second_pos := target_pos + Vector2(randf_range(-110, 110), randf_range(-70, 70))
			if _arena != null:
				second_pos = _arena.clamp_to_arena(second_pos, rad * 0.5)
			var t2 := _combat.spawn_circle_telegraph(second_pos, rad * 0.9, 0.55, Color(1.0, 0.75, 0.2))
			t2.triggered.connect(func() -> void:
				if _is_dead:
					return
				_combat.spawn_ring_burst(second_pos, rad * 0.9, Color(1.0, 0.75, 0.2))
				_combat.add_screen_shake(6.0)
				if _player != null and is_instance_valid(_player) and _player.global_position.distance_to(second_pos) <= rad * 0.9 + 16.0:
					if _player.has_method("take_damage"):
						_player.take_damage(dmg)
				_state = BossState.CHASE
				_atk_timer = 1.1
			)
		else:
			_state = BossState.CHASE
			_atk_timer = 1.5
	)


func _do_charge_pattern() -> void:
	var cfg: Dictionary = _patterns.get("charge", {})
	var t_time := float(cfg.get("telegraph_time", 0.7)) * (0.85 if phase == 2 else 1.0)
	var c_speed := float(cfg.get("speed", 540.0)) * (1.15 if phase == 2 else 1.0)
	var c_dur := float(cfg.get("duration", 0.38))
	_charge_dmg = int(cfg.get("damage", 30))
	_charge_hit_radius = float(cfg.get("hit_radius", 68.0))

	var dir := (_player.global_position - global_position).normalized()
	_update_facing(dir)
	var length := c_speed * c_dur

	if _combat == null:
		_state = BossState.CHASE
		return

	var t := _combat.spawn_line_telegraph(global_position, dir, length, 58.0, t_time, Color(1.0, 0.55, 0.15))
	t.triggered.connect(func() -> void:
		if _is_dead:
			return
		_charge_vel = dir * c_speed
		_charge_timer = c_dur
		_charge_hit_done = false
		_state = BossState.CHARGING
	)


func _do_barrage_pattern() -> void:
	var cfg: Dictionary = _patterns.get("barrage", {})
	var t_time := float(cfg.get("telegraph_time", 0.65))
	var count := int(cfg.get("phase2_projectile_count", 11)) if phase == 2 else int(cfg.get("projectile_count", 7))
	var p_speed := float(cfg.get("projectile_speed", 360.0))
	var dmg := int(cfg.get("damage", 18))

	if _combat == null:
		_state = BossState.CHASE
		return

	_play_anim("attack", "cyan_rune_special", t_time)
	var t := _combat.spawn_circle_telegraph(global_position, 90.0, t_time, Color(0.7, 0.4, 1.0))
	t.triggered.connect(func() -> void:
		if _is_dead or _player == null or not is_instance_valid(_player):
			return
		var base_dir := (_player.global_position - global_position).normalized()
		var spread := deg_to_rad(130.0 if phase == 2 else 95.0)
		for i in range(count):
			var frac: float = (float(i) / float(maxi(count - 1, 1))) - 0.5
			var dir := base_dir.rotated(frac * spread)
			_combat.spawn_projectile(global_position + Vector2(0, -24), dir * p_speed, dmg, "player", Color(0.85, 0.45, 1.0), 11.0, 2.2)
		_state = BossState.CHASE
		_atk_timer = 1.4 if phase == 1 else 1.0
	)


func take_damage(amount: int, is_crit: bool = false) -> void:
	if _is_dead or _state == BossState.PHASE_TRANSITION:
		return
	current_hp = maxi(0, current_hp - amount)
	_hurt_timer = 0.14
	hp_changed.emit(current_hp, max_hp)
	if _combat != null:
		_combat.spawn_damage_number(global_position + Vector2(0, -16), amount, is_crit, false, false)

	if phase == 1 and current_hp > 0 and float(current_hp) / float(max_hp) <= phase2_hp_ratio:
		_enter_phase_2()
	elif current_hp <= 0:
		_die()


func _enter_phase_2() -> void:
	phase = 2
	_state = BossState.PHASE_TRANSITION
	_transition_timer = 1.1
	modulate = Color(1.0, 0.82, 0.95)
	if _combat != null:
		_combat.spawn_ring_burst(global_position, 220.0, Color(0.95, 0.4, 1.0))
		_combat.add_screen_shake(10.0)
	phase_changed.emit(2)


func _die() -> void:
	_is_dead = true
	remove_from_group("enemy")
	_state = BossState.DEAD
	velocity = Vector2.ZERO
	collision_layer = 0
	_play_anim("death")
	died.emit(exp_reward, global_position)
	var tw := create_tween()
	if _painted_animation and _sprite.is_playing():
		var frames := _sprite.sprite_frames
		var animation := _sprite.animation
		tw.tween_interval(frames.get_frame_count(animation) / frames.get_animation_speed(animation))
	tw.tween_property(self, "modulate:a", 0.0, 0.7)
	tw.tween_callback(queue_free)


func _update_facing(dir: Vector2) -> void:
	if dir.length() < 0.08:
		return
	if absf(dir.x) > absf(dir.y) * 0.85:
		_facing = "right"
		_flip_h = dir.x < 0.0
	elif dir.y < 0.0:
		_facing = "up"
		_flip_h = false
	else:
		_facing = "down"
		_flip_h = false


func _play_anim(anim_name: String, painted_pattern: String = "", duration: float = 0.0) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	_sprite.flip_h = _flip_h
	var full_name := "%s_%s" % [anim_name, _facing]
	if _painted_animation:
		if not painted_pattern.is_empty():
			anim_name = painted_pattern
		elif anim_name == "walk" or anim_name == "attack":
			anim_name = "heavy_walk"
		full_name = "%s_down" % anim_name
	var frames := _sprite.sprite_frames
	if frames.has_animation(full_name) and (_sprite.animation != full_name or not _sprite.is_playing()):
		var playback_speed := 1.0
		if _painted_animation and duration > 0.0:
			playback_speed = frames.get_frame_count(full_name) / (frames.get_animation_speed(full_name) * duration)
		_sprite.play(full_name, playback_speed)
