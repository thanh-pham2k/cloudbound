class_name PlayerController
extends CharacterBody2D
## Tôn Ngộ Không controller: 8-dir WASD, Space Dash, K Staff Attack, E Interact.

signal stats_changed
signal respawned

const MOVE_SPEED := 235.0
const DASH_SPEED := 620.0
const DASH_DURATION := 0.18
const DASH_COOLDOWN := 0.65
const ATTACK_COOLDOWN := 0.32
const ATTACK_RANGE := 72.0
const INTERACT_RANGE := 72.0
const LEVEL_EXP := [0, 50, 120, 210, 320]

var spawn_position: Vector2 = Vector2.ZERO
var last_facing: Vector2 = Vector2(1.0, -0.5).normalized()

var level: int = 1
var exp_points: int = 0
var gold: int = 0
var max_hp: int = 100
var hp: int = 100
var attack_damage: int = 20

var _dash_timer: float = 0.0
var _dash_cd: float = 0.0
var _attack_cd: float = 0.0
var _attack_fx_timer: float = 0.0
var _invuln_timer: float = 0.0
var _hit_flash_timer: float = 0.0

var _visual: IsoPlaceholder


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 2

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	add_child(col)

	_visual = IsoPlaceholder.new()
	_visual.kind = "hero"
	_visual.item_scale = 1.0
	add_child(_visual)


func _physics_process(delta: float) -> void:
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_attack_fx_timer = maxf(0.0, _attack_fx_timer - delta)
	_invuln_timer = maxf(0.0, _invuln_timer - delta)
	_hit_flash_timer = maxf(0.0, _hit_flash_timer - delta)
	_visual.hit_flash = _hit_flash_timer

	var input_vec := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_vec.length() > 0.01:
		last_facing = input_vec.normalized()
		_visual.facing_dir = last_facing
		_visual.queue_redraw()

	if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0 and _dash_timer <= 0.0:
		_dash_timer = DASH_DURATION
		_dash_cd = DASH_COOLDOWN
		_invuln_timer = DASH_DURATION + 0.06

	if _dash_timer > 0.0:
		_dash_timer -= delta
		velocity = last_facing * DASH_SPEED
	else:
		velocity = input_vec.normalized() * MOVE_SPEED if input_vec.length() > 0.01 else Vector2.ZERO

	move_and_slide()

	if Input.is_action_just_pressed("attack") and _attack_cd <= 0.0:
		_perform_attack()

	if Input.is_action_just_pressed("interact"):
		_perform_interact()

	if _attack_fx_timer > 0.0 or _dash_timer > 0.0:
		queue_redraw()


func _draw() -> void:
	if _dash_timer > 0.0:
		draw_line(Vector2(0, -12), -last_facing * 36.0 + Vector2(0, -12), Color(1, 1, 1, 0.7), 6.0)
	if _attack_fx_timer > 0.0:
		var base_ang := last_facing.angle()
		draw_arc(Vector2(0, -14), ATTACK_RANGE * 0.72, base_ang - 0.85, base_ang + 0.85, 16, Color("#FBBF24"), 5.0)


func _perform_attack() -> void:
	_attack_cd = ATTACK_COOLDOWN
	_attack_fx_timer = 0.16
	queue_redraw()
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or node.is_dead:
			continue
		var to_enemy: Vector2 = node.global_position - global_position
		if to_enemy.length() <= ATTACK_RANGE and (to_enemy.length() < 24.0 or to_enemy.normalized().dot(last_facing) > 0.15):
			node.take_damage(attack_damage, to_enemy.normalized() * 190.0)


func _perform_interact() -> void:
	var best: Node = null
	var best_dist: float = INTERACT_RANGE
	for node in get_tree().get_nodes_in_group("interactables"):
		if not is_instance_valid(node):
			continue
		if node.has_method("can_interact") and not node.can_interact():
			continue
		var d := global_position.distance_to(node.global_position)
		if d <= best_dist:
			best_dist = d
			best = node
	if best and best.has_method("interact"):
		best.interact(self)


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if _invuln_timer > 0.0:
		return
	hp = maxi(0, hp - amount)
	_invuln_timer = 0.35
	_hit_flash_timer = 0.14
	velocity += knockback
	_visual.queue_redraw()
	stats_changed.emit()
	if hp <= 0:
		respawn()


func respawn() -> void:
	global_position = spawn_position
	hp = max_hp
	_dash_timer = 0.0
	_invuln_timer = 0.6
	stats_changed.emit()
	respawned.emit()


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
	stats_changed.emit()


func grant_rewards(add_exp: int, add_gold: int) -> void:
	exp_points += add_exp
	gold += add_gold
	while level < 5 and exp_points >= LEVEL_EXP[level]:
		level += 1
		max_hp += 25
		attack_damage += 6
		hp = max_hp
	stats_changed.emit()


func get_nearest_interactable_prompt() -> String:
	var best: Node = null
	var best_dist: float = INTERACT_RANGE
	for node in get_tree().get_nodes_in_group("interactables"):
		if not is_instance_valid(node):
			continue
		if node.has_method("can_interact") and not node.can_interact():
			continue
		var d := global_position.distance_to(node.global_position)
		if d <= best_dist:
			best_dist = d
			best = node
	if best and best.has_method("get_prompt_text"):
		return best.get_prompt_text()
	return ""
