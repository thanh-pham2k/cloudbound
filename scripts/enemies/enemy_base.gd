class_name EnemyBase
extends CharacterBody2D
## Monster & Boss AI: Patrol -> Detect -> Chase -> Attack -> Return.

signal died(enemy_id: String, is_boss: bool, reward_exp: int, reward_gold: int)

enum State { PATROL, CHASE, ATTACK, RETURN }

@export var enemy_id: String = "boar"
@export var display_name: String = "Yêu Quái"
@export var is_boss: bool = false
@export var max_hp: int = 60
@export var move_speed: float = 115.0
@export var attack_damage: int = 12
@export var detect_radius: float = 210.0
@export var leash_radius: float = 340.0
@export var attack_range: float = 46.0
@export var attack_cooldown: float = 1.2
@export var reward_exp: int = 25
@export var reward_gold: int = 10

var hp: int = 60
var is_dead: bool = false
var home_position: Vector2 = Vector2.ZERO

var _state: State = State.PATROL
var _patrol_target: Vector2 = Vector2.ZERO
var _patrol_wait: float = 0.8
var _attack_cd: float = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO
var _hit_flash_timer: float = 0.0
var _visual: IsoPlaceholder


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 2
	home_position = global_position
	hp = max_hp
	_patrol_target = home_position

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 22.0 if is_boss else 14.0
	col.shape = shape
	add_child(col)

	_visual = IsoPlaceholder.new()
	_visual.kind = "boss" if is_boss else "boar"
	_visual.item_scale = 1.0
	add_child(_visual)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_attack_cd = maxf(0.0, _attack_cd - delta)
	_hit_flash_timer = maxf(0.0, _hit_flash_timer - delta)
	_visual.hit_flash = _hit_flash_timer
	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 650.0 * delta)

	var player := get_tree().get_first_node_in_group("player") as Node2D
	var dist_to_player := global_position.distance_to(player.global_position) if player else INF
	var dist_from_home := global_position.distance_to(home_position)

	match _state:
		State.PATROL:
			if player and dist_to_player <= detect_radius:
				_state = State.CHASE
			else:
				_process_patrol(delta)
		State.CHASE:
			if not player or dist_from_home > leash_radius or dist_to_player > leash_radius:
				_state = State.RETURN
			elif dist_to_player <= attack_range:
				_state = State.ATTACK
			else:
				var dir := (player.global_position - global_position).normalized()
				velocity = dir * move_speed + _knockback_vel
		State.ATTACK:
			velocity = _knockback_vel
			if not player or dist_to_player > attack_range * 1.25:
				_state = State.CHASE
			elif _attack_cd <= 0.0:
				_attack_cd = attack_cooldown
				if player.has_method("take_damage"):
					var kb := (player.global_position - global_position).normalized() * (220.0 if is_boss else 140.0)
					player.take_damage(attack_damage, kb)
		State.RETURN:
			if player and dist_to_player <= detect_radius * 0.75 and dist_from_home < leash_radius * 0.6:
				_state = State.CHASE
			elif global_position.distance_to(home_position) <= 12.0:
				global_position = home_position
				hp = max_hp
				_state = State.PATROL
			else:
				velocity = (home_position - global_position).normalized() * (move_speed * 1.1)

	move_and_slide()
	queue_redraw()


func _process_patrol(delta: float) -> void:
	if global_position.distance_to(_patrol_target) <= 10.0:
		velocity = _knockback_vel
		_patrol_wait -= delta
		if _patrol_wait <= 0.0:
			_patrol_wait = randf_range(1.0, 2.2)
			var ang := randf() * TAU
			_patrol_target = home_position + Vector2(cos(ang) * 42.0, sin(ang) * 24.0)
	else:
		velocity = (_patrol_target - global_position).normalized() * (move_speed * 0.55) + _knockback_vel


func _draw() -> void:
	if is_dead:
		return
	var bar_w := 60.0 if is_boss else 34.0
	var bar_y := -82.0 if is_boss else -34.0
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w, 5.0), Color("#1E293B"))
	draw_rect(Rect2(-bar_w * 0.5 + 1.0, bar_y + 1.0, (bar_w - 2.0) * ratio, 3.0), Color("#DC2626"))


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	hp = maxi(0, hp - amount)
	_hit_flash_timer = 0.14
	_knockback_vel = knockback * (0.45 if is_boss else 1.0)
	_state = State.CHASE
	_visual.queue_redraw()
	queue_redraw()
	if hp <= 0:
		is_dead = true
		died.emit(enemy_id, is_boss, reward_exp, reward_gold)
		queue_free()
