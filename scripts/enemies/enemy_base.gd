extends CharacterBody2D
class_name EnemyBase

signal died(exp_reward: int, pos: Vector2)

enum AIState { IDLE, CHASE, RETREAT, TELEGRAPH, DEAD }

const PLAYER_COLLISION_RADIUS := 16.0
const ATTACK_IMPACT_FRAMES := {
	&"attack_down": 3,
	&"cast_down": 4,
	&"axe_attack_down": 3,
	&"stone_punch_down": 4,
}

var enemy_id: String = "melee"
var max_hp: int = 48
var current_hp: int = 48
var speed: float = 148.0
var damage: int = 11
var attack_range: float = 58.0
var preferred_min_range: float = 0.0
var detect_range: float = 950.0
var attack_cooldown: float = 1.1
var telegraph_time: float = 0.35
var aoe_radius: float = 0.0
var projectile_speed: float = 0.0
var exp_reward: int = 18

var _state: AIState = AIState.IDLE
var _is_dead: bool = false
var _atk_timer: float = 0.0
var _hurt_timer: float = 0.0
var _facing: String = "down"
var _flip_h: bool = false
var _pose_height: float = 110.0

var _player: Node2D
var _combat: CombatSystem
var _arena: CloudArena
var _sprite: AnimatedSprite2D
var _painted_animation := false
var _painted_attack := "attack"
var _painted_walk := "walk"
var _hp_bar: Range
var _active_telegraph: TelegraphArea
var _telegraph_serial: int = 0
var _post_attack_timer: float = 0.0
var _post_attack_anim_name: StringName = &""
var _flash_tween: Tween


func setup(id: String, player: Node2D, combat: CombatSystem, arena: CloudArena) -> void:
	enemy_id = id
	_player = player
	_combat = combat
	_arena = arena

	var cfg := GameData.get_enemy_config(id)
	max_hp = int(cfg.get("max_hp", 48))
	current_hp = max_hp
	speed = float(cfg.get("speed", 148.0))
	damage = int(cfg.get("damage", 11))
	attack_range = float(cfg.get("attack_range", 58.0))
	preferred_min_range = float(cfg.get("preferred_min_range", 0.0))
	detect_range = float(cfg.get("detect_range", 950.0))
	attack_cooldown = float(cfg.get("attack_cooldown", 1.1))
	telegraph_time = float(cfg.get("telegraph_time", 0.35))
	aoe_radius = float(cfg.get("aoe_radius", 0.0))
	projectile_speed = float(cfg.get("projectile_speed", 0.0))
	exp_reward = int(cfg.get("exp_reward", 18))


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1

	var cfg := GameData.get_enemy_config(enemy_id)
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0 if enemy_id != "tank" else 24.0
	col.shape = shape
	add_child(col)

	_sprite = AnimatedSprite2D.new()
	var sp_path := str(cfg.get("sprite_frames", ""))
	if sp_path != "" and ResourceLoader.exists(sp_path):
		_sprite.sprite_frames = load(sp_path)
	var s := float(cfg.get("scale", 1.0))
	_sprite.scale = Vector2(s, s)
	_sprite.offset = Vector2(0, -48)
	var pose_height := 110.0
	if _arena != null and _arena.painted_visuals:
		const CASTER := preload("res://assets/generated/enemies/caster/caster_sprite_frames.tres")
		const BOAR := preload("res://assets/generated/enemies/boar/boar_sprite_frames.tres")
		const SPIRIT := preload("res://assets/generated/enemies/spirit/spirit_sprite_frames.tres")
		const GOLEM := preload("res://assets/generated/enemies/golem/golem_sprite_frames.tres")
		if _arena.scene_theme == "stairway_clouds":
			_sprite.sprite_frames = SPIRIT
			pose_height = 104.0
		elif enemy_id == "tank":
			_sprite.sprite_frames = GOLEM
			_painted_attack = "stone_punch"
			_painted_walk = "heavy_walk"
			pose_height = 140.0
		elif enemy_id == "ranged":
			_sprite.sprite_frames = CASTER
			_painted_attack = "cast"
		else:
			_sprite.sprite_frames = BOAR
			_painted_attack = "axe_attack"
		_sprite.offset = Vector2(0.0, -63.0)
		_sprite.scale = Vector2.ONE * pose_height / 120.0
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_painted_animation = true
	_pose_height = pose_height
	add_child(_sprite)

	if _arena != null and _arena.painted_visuals:
		const BAR := preload("res://assets/processed/ui/enemy_health_bar.png")
		const PAINTED := preload("res://scripts/world/painted_sprite.gd")
		_hp_bar = PAINTED.make_meter(BAR, Rect2(0, 0, 491, 183), 72.0)
		_hp_bar.position = Vector2(-36, -pose_height - 24)
	else:
		var plain := ProgressBar.new()
		plain.size = Vector2(44, 6)
		plain.position = Vector2(-22, -74)
		plain.show_percentage = false
		_hp_bar = plain
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp
	_hp_bar.visible = _arena != null and _arena.painted_visuals
	add_child(_hp_bar)

	_play_anim("idle")


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_atk_timer = maxf(0.0, _atk_timer - delta)
	_hurt_timer = maxf(0.0, _hurt_timer - delta)
	_post_attack_timer = maxf(0.0, _post_attack_timer - delta)

	if _player == null or not is_instance_valid(_player) or _player.get("_is_dead"):
		velocity = Vector2.ZERO
		_post_attack_timer = 0.0
		_play_anim("idle")
		return

	if _state == AIState.TELEGRAPH:
		velocity = Vector2.ZERO
		return

	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized() if dist > 0.001 else Vector2.DOWN

	if dist > detect_range:
		_state = AIState.IDLE
		velocity = Vector2.ZERO
	elif preferred_min_range > 0.0 and dist < preferred_min_range:
		_state = AIState.RETREAT
		velocity = -dir * (speed * 0.9)
		_update_facing(velocity)
	elif dist <= attack_range:
		velocity = Vector2.ZERO
		_update_facing(dir)
		if _atk_timer <= 0.0:
			_begin_telegraph(dir)
	else:
		_state = AIState.CHASE
		velocity = dir * speed
		_update_facing(dir)

	move_and_slide()
	if _arena != null:
		global_position = _arena.clamp_to_arena(global_position, 28.0)

	if _state == AIState.TELEGRAPH:
		return
	if _hurt_timer > 0.0:
		_post_attack_timer = 0.0
		_play_anim("hurt")
	elif _post_attack_timer > 0.0 and _sprite != null and _sprite.is_playing() and _sprite.animation == _post_attack_anim_name:
		return
	elif velocity.length() > 10.0:
		_play_anim("walk")
	else:
		_play_anim("idle")


func _cancel_telegraph() -> void:
	_telegraph_serial += 1
	_post_attack_timer = 0.0
	_post_attack_anim_name = &""
	if is_instance_valid(_active_telegraph):
		_active_telegraph.cancel()
	_active_telegraph = null
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
		_post_attack_timer = minf(float(remaining_frames) / fps, 0.24)


func _begin_telegraph(dir: Vector2) -> void:
	_cancel_telegraph()
	_state = AIState.TELEGRAPH
	_atk_timer = attack_cooldown + telegraph_time
	_play_anim("attack", telegraph_time, true)

	if _combat == null:
		_state = AIState.CHASE
		return

	var serial := _telegraph_serial
	if projectile_speed > 0.0:
		var spawn_pos := global_position + Vector2(0, -16)
		var to_target := _player.global_position - global_position if (_player != null and is_instance_valid(_player)) else dir
		var locked_dir := to_target.normalized() if to_target.length_squared() > 0.001 else dir
		_update_facing(locked_dir)
		var proj_rad := 8.0
		var proj_life := 1.6
		var proj_length := maxf(attack_range, projectile_speed * proj_life)
		var proj_width := (proj_rad + 4.0) * 2.0
		var t := _combat.spawn_line_telegraph(spawn_pos, locked_dir, proj_length, proj_width, telegraph_time, Color(0.75, 0.45, 1.0))
		t.aim_target = _player
		t.aim_origin = self
		t.aim_direction = locked_dir
		_active_telegraph = t
		t.triggered.connect(func() -> void:
			if _is_dead or serial != _telegraph_serial:
				return
			_active_telegraph = null
			_state = AIState.CHASE
			_start_post_attack_recovery()
			if _player == null or not is_instance_valid(_player) or _player.get("_is_dead"):
				return
			_combat.spawn_projectile(global_position + Vector2(0, -16), t.line_end.normalized() * projectile_speed, damage, "player", Color(0.85, 0.45, 1.0), proj_rad, proj_life)
		)
	else:
		var hit_pos := _player.global_position if aoe_radius > 0.0 else global_position + dir * (attack_range * 0.65)
		var hit_rad := aoe_radius if aoe_radius > 0.0 else 44.0
		var t := _combat.spawn_circle_telegraph(hit_pos, hit_rad, telegraph_time, Color(1.0, 0.3, 0.25))
		_active_telegraph = t
		t.triggered.connect(func() -> void:
			if _is_dead or serial != _telegraph_serial:
				return
			_active_telegraph = null
			_state = AIState.CHASE
			_start_post_attack_recovery()
			if _player == null or not is_instance_valid(_player) or _player.get("_is_dead"):
				return
			if t.contains_circle(_player.global_position, PLAYER_COLLISION_RADIUS) and _player.has_method("take_damage"):
				_player.take_damage(damage)
		)


func take_damage(amount: int, is_crit: bool = false) -> bool:
	if _is_dead or amount <= 0:
		return false
	current_hp = maxi(0, current_hp - amount)
	_hurt_timer = 0.16
	_post_attack_timer = 0.0
	_trigger_hit_flash()
	if _hp_bar != null:
		_hp_bar.visible = true
		_hp_bar.value = current_hp
	if _combat != null:
		_combat.spawn_damage_number(global_position, amount, is_crit, false, false, _pose_height + 24.0)
	if current_hp <= 0:
		_die()
	elif _state != AIState.TELEGRAPH:
		_play_anim("hurt", 0.0, true)
	return true


func _trigger_hit_flash() -> void:
	if _sprite == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_sprite.modulate = Color(1.6, 1.4, 1.4)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_sprite, "modulate", Color.WHITE, 0.1)


func _die() -> void:
	_cancel_telegraph()
	_is_dead = true
	remove_from_group("enemy")
	_state = AIState.DEAD
	velocity = Vector2.ZERO
	collision_layer = 0
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	if _sprite != null:
		_sprite.modulate = Color.WHITE
	if _hp_bar != null:
		_hp_bar.visible = false
	_play_anim("death", 0.0, true)
	died.emit(exp_reward, global_position)
	var tw := create_tween()
	if _painted_animation and _sprite.is_playing():
		var frames := _sprite.sprite_frames
		var animation := _sprite.animation
		tw.tween_interval(frames.get_frame_count(animation) / frames.get_animation_speed(animation))
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
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


func _play_anim(anim_name: String, duration: float = 0.0, force_restart: bool = false) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	_sprite.flip_h = _flip_h
	var raw_anim := anim_name
	var full_name := StringName("%s_%s" % [anim_name, _facing])
	if _painted_animation:
		match anim_name:
			"attack":
				anim_name = _painted_attack
			"walk":
				anim_name = _painted_walk
		full_name = StringName("%s_down" % anim_name)
	var frames := _sprite.sprite_frames
	if not frames.has_animation(full_name):
		return
	var is_loop := frames.get_animation_loop(full_name)
	if force_restart or _sprite.animation != full_name or (is_loop and not _sprite.is_playing()):
		var playback_speed := 1.0
		if duration > 0.0 and raw_anim == "attack":
			var impact_frame := _get_attack_impact_frame(full_name)
			if impact_frame > 0:
				playback_speed = float(impact_frame) / (maxf(frames.get_animation_speed(full_name), 1.0) * duration)
		if force_restart:
			_sprite.stop()
			_sprite.frame = 0
		_sprite.speed_scale = playback_speed
		_sprite.play(full_name)
