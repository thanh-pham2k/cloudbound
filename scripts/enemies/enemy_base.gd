extends CharacterBody2D
class_name EnemyBase

signal died(exp_reward: int, pos: Vector2)

enum AIState { IDLE, CHASE, RETREAT, TELEGRAPH, DEAD }

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

var _player: Node2D
var _combat: CombatSystem
var _arena: CloudArena
var _sprite: AnimatedSprite2D
var _hp_bar: ProgressBar


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
	add_child(_sprite)

	_hp_bar = ProgressBar.new()
	_hp_bar.size = Vector2(44, 6)
	_hp_bar.position = Vector2(-22, -74)
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp
	_hp_bar.show_percentage = false
	_hp_bar.visible = false
	add_child(_hp_bar)

	_play_anim("idle")


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_atk_timer = maxf(0.0, _atk_timer - delta)
	_hurt_timer = maxf(0.0, _hurt_timer - delta)

	if _player == null or not is_instance_valid(_player) or _player.get("_is_dead"):
		velocity = Vector2.ZERO
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

	if _hurt_timer > 0.0:
		_play_anim("hurt")
	elif velocity.length() > 10.0:
		_play_anim("walk")
	else:
		_play_anim("idle")


func _begin_telegraph(dir: Vector2) -> void:
	_state = AIState.TELEGRAPH
	_atk_timer = attack_cooldown + telegraph_time
	_play_anim("attack")

	if _combat == null:
		_state = AIState.CHASE
		return

	if projectile_speed > 0.0:
		var t := _combat.spawn_line_telegraph(global_position + Vector2(0, -16), dir, attack_range, 20.0, telegraph_time, Color(0.75, 0.45, 1.0))
		t.triggered.connect(func() -> void:
			if _is_dead or _player == null or not is_instance_valid(_player):
				return
			var fire_dir := (_player.global_position - global_position).normalized()
			_combat.spawn_projectile(global_position + Vector2(0, -16), fire_dir * projectile_speed, damage, "player", Color(0.85, 0.45, 1.0), 8.0, 1.6)
			_state = AIState.CHASE
		)
	else:
		var hit_pos := _player.global_position if aoe_radius > 0.0 else global_position + dir * (attack_range * 0.65)
		var hit_rad := aoe_radius if aoe_radius > 0.0 else 44.0
		var t := _combat.spawn_circle_telegraph(hit_pos, hit_rad, telegraph_time, Color(1.0, 0.3, 0.25))
		t.triggered.connect(func() -> void:
			if _is_dead or _player == null or not is_instance_valid(_player):
				return
			if _player.global_position.distance_to(hit_pos) <= hit_rad + 14.0 and _player.has_method("take_damage"):
				_player.take_damage(damage)
			_state = AIState.CHASE
		)


func take_damage(amount: int, is_crit: bool = false) -> void:
	if _is_dead:
		return
	current_hp = maxi(0, current_hp - amount)
	_hurt_timer = 0.16
	if _hp_bar != null:
		_hp_bar.visible = true
		_hp_bar.value = current_hp
	if _combat != null:
		_combat.spawn_damage_number(global_position, amount, is_crit, false, false)
	if current_hp <= 0:
		_die()


func _die() -> void:
	_is_dead = true
	_state = AIState.DEAD
	velocity = Vector2.ZERO
	collision_layer = 0
	if _hp_bar != null:
		_hp_bar.visible = false
	_play_anim("death")
	died.emit(exp_reward, global_position)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
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


func _play_anim(anim_name: String) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	_sprite.flip_h = _flip_h
	var full_name := "%s_%s" % [anim_name, _facing]
	if _sprite.sprite_frames.has_animation(full_name) and _sprite.animation != full_name:
		_sprite.play(full_name)
