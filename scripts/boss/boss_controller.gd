extends CharacterBody2D
class_name BossController

signal hp_changed(current_hp: int, max_hp: int)
signal phase_changed(phase: int)
signal died(exp_reward: int, pos: Vector2)

enum BossState { CHASE, TELEGRAPH, CHARGING, PHASE_TRANSITION, DEAD }

const PLAYER_COLLISION_RADIUS := 16.0
const ATTACK_IMPACT_FRAMES := {
	&"ground_slam_down": 5,
	&"cyan_rune_special_down": 3,
}

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
var _pattern_serial: int = 0
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
var _active_telegraphs: Array[TelegraphArea] = []
var _charge_origin: Vector2 = Vector2.ZERO
var _charge_local_points: PackedVector2Array = PackedVector2Array()
var _post_attack_timer: float = 0.0
var _post_attack_anim_name: StringName = &""
var _flash_tween: Tween


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
	const PAINTED := preload("res://scripts/world/painted_sprite.gd")
	const GUARDIAN := preload("res://assets/characters/boss_thunder_warden/base.png")
	PAINTED.set_actor_pose(_sprite, GUARDIAN, 225.0)
	add_child(_sprite)

	hp_changed.emit(current_hp, max_hp)
	_play_anim("idle")


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_hurt_timer = maxf(0.0, _hurt_timer - delta)
	_post_attack_timer = maxf(0.0, _post_attack_timer - delta)

	if _state == BossState.PHASE_TRANSITION:
		_transition_timer -= delta
		velocity = Vector2.ZERO
		_post_attack_timer = 0.0
		_play_anim("idle")
		if _transition_timer <= 0.0:
			_state = BossState.CHASE
			_atk_timer = 0.6
		return

	if _player == null or not is_instance_valid(_player) or _player.get("_is_dead"):
		velocity = Vector2.ZERO
		_post_attack_timer = 0.0
		_play_anim("idle")
		return

	if _state == BossState.CHARGING:
		var prev_pos := global_position
		var step_dt := minf(delta, _charge_timer)
		_charge_timer -= delta
		velocity = _charge_vel * (step_dt / maxf(delta, 0.0001))
		move_and_slide()
		if _arena != null:
			global_position = _arena.clamp_to_arena(global_position, 34.0)
		var new_pos := global_position
		_play_anim("walk", "", 0.0, false, 1.55)
		if not _charge_hit_done:
			var closest_on_sweep := Geometry2D.get_closest_point_to_segment(_player.global_position, prev_pos, new_pos)
			var hit_swept := _player.global_position.distance_to(closest_on_sweep) <= _charge_hit_radius
			var inside_shown_danger := TelegraphArea.polyline_contains_circle(_charge_origin, _charge_local_points, _charge_hit_radius, _player.global_position, 0.0)
			if hit_swept and inside_shown_danger:
				_charge_hit_done = true
				if _player.has_method("take_damage"):
					_player.take_damage(_charge_dmg)
		if _charge_timer <= 0.0:
			if _sprite != null:
				_sprite.speed_scale = 1.0
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
		_post_attack_timer = 0.0
		_play_anim("hurt")
	elif _post_attack_timer > 0.0 and _sprite != null and _sprite.is_playing() and _sprite.animation == _post_attack_anim_name:
		pass
	elif velocity.length() > 10.0:
		_play_anim("walk")
	else:
		_play_anim("idle")

	if _atk_timer <= 0.0:
		_trigger_next_pattern()


func _cancel_active_pattern() -> void:
	_pattern_serial += 1
	_post_attack_timer = 0.0
	_post_attack_anim_name = &""
	for t in _active_telegraphs:
		if is_instance_valid(t):
			t.cancel()
	_active_telegraphs.clear()
	if _sprite != null:
		_sprite.speed_scale = 1.0


func _start_post_attack_recovery() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var frames := _sprite.sprite_frames
	var anim := _sprite.animation
	if not frames.has_animation(anim) or frames.get_animation_loop(anim):
		_sprite.speed_scale = 1.0
		return
	var impact_frame := _get_attack_impact_frame(anim)
	_sprite.speed_scale = 1.0
	if not _sprite.is_playing():
		_sprite.play(anim)
		_sprite.set_frame_and_progress(impact_frame, 0.0)
	elif _sprite.frame < impact_frame:
		_sprite.set_frame_and_progress(impact_frame, 0.0)
	var fps := maxf(frames.get_animation_speed(anim), 1.0)
	var remaining_frames := maxi(0, frames.get_frame_count(anim) - _sprite.frame)
	if remaining_frames > 0:
		_post_attack_anim_name = anim
		_post_attack_timer = minf(float(remaining_frames) / fps, 0.30)


func _trigger_next_pattern() -> void:
	_cancel_active_pattern()
	_state = BossState.TELEGRAPH
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
	if _player == null or not is_instance_valid(_player) or _combat == null:
		_state = BossState.CHASE
		return
	var cfg: Dictionary = _patterns.get("slam", {})
	var t_time := float(cfg.get("telegraph_time", 0.85)) * (0.85 if phase == 2 else 1.0)
	var rad := float(cfg.get("radius", 135.0))
	var dmg := int(cfg.get("damage", 28))
	var target_pos := _player.global_position
	var serial := _pattern_serial

	_update_facing(target_pos - global_position)
	_play_anim("attack", "ground_slam", t_time, true)
	var t := _combat.spawn_circle_telegraph(target_pos, rad, t_time, Color(1.0, 0.25, 0.2))
	_active_telegraphs.append(t)
	t.triggered.connect(func() -> void:
		_active_telegraphs.erase(t)
		if _is_dead or _state == BossState.PHASE_TRANSITION or serial != _pattern_serial:
			return
		_start_post_attack_recovery()
		_combat.spawn_ring_burst(target_pos, rad, Color(1.0, 0.35, 0.25))
		_combat.add_screen_shake(7.0)
		if _player != null and is_instance_valid(_player) and not _player.get("_is_dead"):
			if t.contains_circle(_player.global_position, PLAYER_COLLISION_RADIUS) and _player.has_method("take_damage"):
				_player.take_damage(dmg)

		if phase == 2:
			var second_pos := target_pos + Vector2(randf_range(-110, 110), randf_range(-70, 70))
			if _arena != null:
				second_pos = _arena.clamp_to_arena(second_pos, rad * 0.5)
			var t2 := _combat.spawn_circle_telegraph(second_pos, rad * 0.9, 0.55, Color(1.0, 0.75, 0.2))
			_active_telegraphs.append(t2)
			t2.triggered.connect(func() -> void:
				_active_telegraphs.erase(t2)
				if _is_dead or _state == BossState.PHASE_TRANSITION or serial != _pattern_serial:
					return
				_combat.spawn_ring_burst(second_pos, rad * 0.9, Color(1.0, 0.75, 0.2))
				_combat.add_screen_shake(6.0)
				if _player != null and is_instance_valid(_player) and not _player.get("_is_dead"):
					if t2.contains_circle(_player.global_position, PLAYER_COLLISION_RADIUS) and _player.has_method("take_damage"):
						_player.take_damage(dmg)
				_state = BossState.CHASE
				_atk_timer = 1.1
			)
		else:
			_state = BossState.CHASE
			_atk_timer = 1.5
	)


func _build_charge_path(origin: Vector2, dir: Vector2, c_speed: float, c_dur: float) -> PackedVector2Array:
	var points := PackedVector2Array([origin])
	var sim_pos := origin
	var steps := maxi(1, int(ceil(c_dur * 60.0)))
	var step_dt := c_dur / float(steps)
	var can_test_move := is_inside_tree() and get_world_2d() != null
	for i in range(steps):
		var motion := dir * c_speed * step_dt
		if can_test_move:
			var col := KinematicCollision2D.new()
			if test_move(Transform2D(0.0, sim_pos), motion, col):
				sim_pos += col.get_travel()
				var rem := col.get_remainder().slide(col.get_normal())
				if rem.length_squared() > 0.001:
					var col2 := KinematicCollision2D.new()
					if test_move(Transform2D(0.0, sim_pos), rem, col2):
						sim_pos += col2.get_travel()
					else:
						sim_pos += rem
			else:
				sim_pos += motion
		else:
			sim_pos += motion
		if _arena != null:
			sim_pos = _arena.clamp_to_arena(sim_pos, 34.0)
		if sim_pos.distance_squared_to(points[points.size() - 1]) > 16.0 or i == steps - 1:
			points.append(sim_pos)
	return points


func _do_charge_pattern() -> void:
	if _player == null or not is_instance_valid(_player) or _combat == null:
		_state = BossState.CHASE
		return
	var cfg: Dictionary = _patterns.get("charge", {})
	var t_time := float(cfg.get("telegraph_time", 0.7)) * (0.85 if phase == 2 else 1.0)
	var c_speed := float(cfg.get("speed", 540.0)) * (1.15 if phase == 2 else 1.0)
	var c_dur := float(cfg.get("duration", 0.38))
	_charge_dmg = int(cfg.get("damage", 30))
	_charge_hit_radius = float(cfg.get("hit_radius", 68.0))

	var to_player := _player.global_position - global_position
	var dir := to_player.normalized() if to_player.length_squared() > 0.001 else Vector2.DOWN
	_update_facing(dir)
	_play_anim("walk", "heavy_walk")
	var serial := _pattern_serial

	var charge_points := _build_charge_path(global_position, dir, c_speed, c_dur)
	_charge_origin = charge_points[0]
	_charge_local_points.clear()
	for pt in charge_points:
		_charge_local_points.append(pt - _charge_origin)

	var t := _combat.spawn_capsule_telegraph(charge_points, _charge_hit_radius, t_time, Color(1.0, 0.55, 0.15))
	_active_telegraphs.append(t)
	t.triggered.connect(func() -> void:
		_active_telegraphs.erase(t)
		if _is_dead or _state == BossState.PHASE_TRANSITION or serial != _pattern_serial:
			return
		_charge_vel = dir * c_speed
		_charge_timer = c_dur
		_charge_hit_done = false
		_state = BossState.CHARGING
	)


func _do_barrage_pattern() -> void:
	if _player == null or not is_instance_valid(_player) or _combat == null:
		_state = BossState.CHASE
		return
	var cfg: Dictionary = _patterns.get("barrage", {})
	var t_time := float(cfg.get("telegraph_time", 0.65))
	var count := int(cfg.get("phase2_projectile_count", 11)) if phase == 2 else int(cfg.get("projectile_count", 7))
	var p_speed := float(cfg.get("projectile_speed", 360.0))
	var dmg := int(cfg.get("damage", 18))
	var serial := _pattern_serial

	var to_player := _player.global_position - global_position
	var base_dir := to_player.normalized() if to_player.length_squared() > 0.001 else Vector2.DOWN
	_update_facing(base_dir)
	var spread := deg_to_rad(130.0 if phase == 2 else 95.0)
	var locked_dirs: Array[Vector2] = []
	for i in range(count):
		var frac: float = (float(i) / float(maxi(count - 1, 1))) - 0.5
		locked_dirs.append(base_dir.rotated(frac * spread))

	var proj_rad := 11.0
	var proj_life := 2.2
	var fan_length := p_speed * proj_life
	var spawn_origin := global_position + Vector2(0, -24)
	_play_anim("attack", "cyan_rune_special", t_time, true)
	var t := _combat.spawn_projectile_fan_telegraph(spawn_origin, locked_dirs, fan_length, (proj_rad + 4.0) * 2.0, t_time, Color(0.7, 0.4, 1.0))
	t.aim_target = _player
	t.aim_origin = self
	t.aim_direction = base_dir
	_active_telegraphs.append(t)
	t.triggered.connect(func() -> void:
		_active_telegraphs.erase(t)
		if _is_dead or _state == BossState.PHASE_TRANSITION or serial != _pattern_serial:
			return
		_start_post_attack_recovery()
		if _player == null or not is_instance_valid(_player) or _player.get("_is_dead"):
			_state = BossState.CHASE
			return
		var fire_origin := global_position + Vector2(0, -24)
		for dir in t.fan_dirs:
			_combat.spawn_projectile(fire_origin, dir * p_speed, dmg, "player", Color(0.85, 0.45, 1.0), proj_rad, proj_life)
		_state = BossState.CHASE
		_atk_timer = 1.4 if phase == 1 else 1.0
	)


func take_damage(amount: int, is_crit: bool = false) -> bool:
	if _is_dead or _state == BossState.PHASE_TRANSITION or amount <= 0:
		return false
	current_hp = maxi(0, current_hp - amount)
	_hurt_timer = 0.14
	_post_attack_timer = 0.0
	_trigger_hit_flash()
	hp_changed.emit(current_hp, max_hp)
	if _combat != null:
		_combat.spawn_damage_number(global_position, amount, is_crit, false, false, 225.0)

	if phase == 1 and current_hp > 0 and float(current_hp) / float(max_hp) <= phase2_hp_ratio:
		_enter_phase_2()
	elif current_hp <= 0:
		_die()
	elif _state == BossState.CHASE:
		_play_anim("hurt", "", 0.0, true)
	return true


func _trigger_hit_flash() -> void:
	if _sprite == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_sprite.modulate = Color(1.6, 1.4, 1.4)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_sprite, "modulate", Color.WHITE, 0.1)


func _enter_phase_2() -> void:
	_cancel_active_pattern()
	phase = 2
	_state = BossState.PHASE_TRANSITION
	_transition_timer = 1.1
	velocity = Vector2.ZERO
	modulate = Color(1.0, 0.82, 0.95)
	_play_anim("idle")
	if _combat != null:
		_combat.spawn_ring_burst(global_position, 220.0, Color(0.95, 0.4, 1.0))
		_combat.add_screen_shake(10.0)
	phase_changed.emit(2)


func _die() -> void:
	_cancel_active_pattern()
	_is_dead = true
	remove_from_group("enemy")
	_state = BossState.DEAD
	velocity = Vector2.ZERO
	collision_layer = 0
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	if _sprite != null:
		_sprite.modulate = Color.WHITE
	_play_anim("death", "", 0.0, true)
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
	if absf(dir.x) > absf(dir.y) * 0.9 and absf(dir.x) > 0.12:
		_facing = "right"
		_flip_h = dir.x < 0.0
	elif dir.y < 0.0:
		_facing = "up"
		_flip_h = false
	else:
		_facing = "down"
		_flip_h = false


func _get_attack_impact_frame(full_name: StringName) -> int:
	if _sprite == null or _sprite.sprite_frames == null:
		return 0
	var frames := _sprite.sprite_frames
	if not frames.has_animation(full_name):
		return 0
	var count := frames.get_frame_count(full_name)
	if count <= 1:
		return 0
	if ATTACK_IMPACT_FRAMES.has(full_name):
		return clampi(int(ATTACK_IMPACT_FRAMES[full_name]), 0, count - 1)
	return clampi(roundi(float(count - 1) * 0.6), 0, count - 1)


func _play_anim(anim_name: String, painted_pattern: String = "", duration: float = 0.0, force_restart: bool = false, speed_scale_override: float = 1.0) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	_sprite.flip_h = _flip_h
	var raw_anim := anim_name
	var full_name := StringName("%s_%s" % [anim_name, _facing])
	if _painted_animation:
		if not painted_pattern.is_empty():
			anim_name = painted_pattern
		elif anim_name == "walk" or anim_name == "attack":
			anim_name = "heavy_walk"
		full_name = StringName("%s_down" % anim_name)
	var frames := _sprite.sprite_frames
	if not frames.has_animation(full_name):
		return
	var playback_speed := speed_scale_override
	if duration > 0.0 and raw_anim == "attack":
		var impact_frame := _get_attack_impact_frame(full_name)
		if impact_frame > 0:
			playback_speed = float(impact_frame) / (maxf(frames.get_animation_speed(full_name), 1.0) * duration)
	var is_loop := frames.get_animation_loop(full_name)
	if force_restart or _sprite.animation != full_name or (is_loop and not _sprite.is_playing()):
		if force_restart:
			_sprite.stop()
			_sprite.frame = 0
		_sprite.speed_scale = playback_speed
		_sprite.play(full_name)
	elif is_loop:
		_sprite.speed_scale = playback_speed
