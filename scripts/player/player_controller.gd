extends CharacterBody2D
class_name PlayerController

signal hp_changed(current_hp: int, max_hp: int)
signal died
signal cooldowns_updated(dash_cd: float, dash_max: float, s1_cd: float, s1_max: float, s2_cd: float, s2_max: float)

const SPRITE_PATH := "res://assets/generated/sprites/player_hero/player_hero_sprite_frames.tres"

var max_hp: int = 120
var current_hp: int = 120
var move_speed: float = 235.0
var crit_chance: float = 0.08
var life_on_kill: int = 0

# Auto-attack stats
var attack_damage: float = 24.0
var attack_cooldown: float = 0.52
var attack_range: float = 210.0
var projectile_speed: float = 560.0

# Dash stats
var dash_speed: float = 640.0
var dash_duration: float = 0.18
var dash_cooldown: float = 1.5
var dash_invuln: float = 0.24

# Skill 1 (Q)
var skill1_damage: float = 58.0
var skill1_cooldown: float = 4.2
var skill1_radius: float = 165.0

# Skill 2 (E)
var skill2_damage: float = 38.0
var skill2_cooldown: float = 7.0
var skill2_bolts: int = 5
var skill2_range: float = 420.0

var _atk_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_active_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.DOWN
var _invuln_timer: float = 0.0
var _skill1_timer: float = 0.0
var _skill2_timer: float = 0.0
var _hurt_timer: float = 0.0
var _attack_anim_timer: float = 0.0
var _is_dead: bool = false

var _facing: String = "down"
var _flip_h: bool = false
var _sprite: AnimatedSprite2D
var _combat: CombatSystem
var _arena: CloudArena


func setup(combat: CombatSystem, arena: CloudArena) -> void:
	_combat = combat
	_arena = arena
	_load_config()


func _load_config() -> void:
	var auto_cfg := GameData.get_skill_config("auto_attack")
	if not auto_cfg.is_empty():
		attack_damage = float(auto_cfg.get("damage", 24.0))
		attack_cooldown = float(auto_cfg.get("cooldown", 0.52))
		attack_range = float(auto_cfg.get("range", 210.0))
		projectile_speed = float(auto_cfg.get("projectile_speed", 560.0))

	var dash_cfg := GameData.get_skill_config("dash")
	if not dash_cfg.is_empty():
		dash_speed = float(dash_cfg.get("speed", 640.0))
		dash_duration = float(dash_cfg.get("duration", 0.18))
		dash_cooldown = float(dash_cfg.get("cooldown", 1.5))
		dash_invuln = float(dash_cfg.get("invuln_duration", 0.24))

	var s1_cfg := GameData.get_skill_config("skill_1")
	if not s1_cfg.is_empty():
		skill1_damage = float(s1_cfg.get("damage", 58.0))
		skill1_cooldown = float(s1_cfg.get("cooldown", 4.2))
		skill1_radius = float(s1_cfg.get("radius", 165.0))

	var s2_cfg := GameData.get_skill_config("skill_2")
	if not s2_cfg.is_empty():
		skill2_damage = float(s2_cfg.get("damage", 38.0))
		skill2_cooldown = float(s2_cfg.get("cooldown", 7.0))
		skill2_bolts = int(s2_cfg.get("bolt_count", 5))
		skill2_range = float(s2_cfg.get("range", 420.0))


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	add_child(col)

	_sprite = AnimatedSprite2D.new()
	if ResourceLoader.exists(SPRITE_PATH):
		_sprite.sprite_frames = load(SPRITE_PATH)
	_sprite.offset = Vector2(0, -48)
	add_child(_sprite)

	hp_changed.emit(current_hp, max_hp)
	_update_animation(Vector2.ZERO)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_atk_timer = maxf(0.0, _atk_timer - delta)
	_dash_timer = maxf(0.0, _dash_timer - delta)
	_skill1_timer = maxf(0.0, _skill1_timer - delta)
	_skill2_timer = maxf(0.0, _skill2_timer - delta)
	_invuln_timer = maxf(0.0, _invuln_timer - delta)
	_hurt_timer = maxf(0.0, _hurt_timer - delta)
	_attack_anim_timer = maxf(0.0, _attack_anim_timer - delta)

	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_input.length() > 1.0:
		move_input = move_input.normalized()

	if Input.is_action_just_pressed("dash") and _dash_timer <= 0.0 and _dash_active_timer <= 0.0:
		_start_dash(move_input)

	if Input.is_action_just_pressed("skill_1") and _skill1_timer <= 0.0:
		_cast_skill_1()

	if Input.is_action_just_pressed("skill_2") and _skill2_timer <= 0.0:
		_cast_skill_2()

	if _dash_active_timer > 0.0:
		_dash_active_timer -= delta
		velocity = _dash_dir * dash_speed
		modulate.a = 0.6
	else:
		modulate.a = 1.0 if _invuln_timer <= 0.0 else (0.55 if int(_invuln_timer * 20.0) % 2 == 0 else 1.0)
		velocity = move_input * move_speed

	move_and_slide()
	if _arena != null:
		global_position = _arena.clamp_to_arena(global_position, 28.0)

	if _atk_timer <= 0.0:
		_try_auto_attack()

	_update_facing(move_input)
	_update_animation(velocity)
	cooldowns_updated.emit(_dash_timer, dash_cooldown, _skill1_timer, skill1_cooldown, _skill2_timer, skill2_cooldown)


func _start_dash(move_input: Vector2) -> void:
	_dash_dir = move_input.normalized() if move_input.length() > 0.1 else _facing_vector()
	_dash_active_timer = dash_duration
	_dash_timer = dash_cooldown
	_invuln_timer = maxf(_invuln_timer, dash_invuln)


func _try_auto_attack() -> void:
	var target := _find_nearest_enemy(attack_range)
	if target == null:
		return
	_atk_timer = attack_cooldown
	_attack_anim_timer = 0.25

	var dir := (target.global_position - global_position).normalized()
	_update_facing(dir)

	var dmg_roll := _roll_damage(attack_damage)
	if _combat != null:
		_combat.spawn_projectile(
			global_position + Vector2(0, -18),
			dir * projectile_speed,
			dmg_roll["amount"],
			"enemy",
			Color(0.45, 0.95, 1.0),
			10.0,
			0.75,
			dmg_roll["crit"]
		)


func _cast_skill_1() -> void:
	_skill1_timer = skill1_cooldown
	_attack_anim_timer = 0.35
	if _combat != null:
		_combat.spawn_ring_burst(global_position, skill1_radius, Color(0.98, 0.85, 0.32))
		_combat.add_screen_shake(4.5)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(global_position) <= skill1_radius and enemy.has_method("take_damage"):
			var dmg_roll := _roll_damage(skill1_damage)
			enemy.take_damage(dmg_roll["amount"], dmg_roll["crit"])


func _cast_skill_2() -> void:
	_skill2_timer = skill2_cooldown
	_attack_anim_timer = 0.35

	var enemies := _get_enemies_in_range(skill2_range)
	for i in range(skill2_bolts):
		var angle: float = (float(i) / float(maxi(skill2_bolts, 1))) * TAU
		var dir := Vector2(cos(angle), sin(angle))
		var target: Node2D = enemies[i % enemies.size()] if not enemies.is_empty() else null
		if target != null:
			dir = (target.global_position - global_position).normalized().rotated(randf_range(-0.25, 0.25))
		var dmg_roll := _roll_damage(skill2_damage)
		if _combat != null:
			_combat.spawn_projectile(
				global_position + Vector2(0, -22),
				dir * 480.0,
				dmg_roll["amount"],
				"enemy",
				Color(0.75, 0.55, 1.0),
				9.0,
				1.3,
				dmg_roll["crit"],
				target
			)


func _roll_damage(base_dmg: float) -> Dictionary:
	var is_crit := randf() < crit_chance
	var final_dmg := int(round(base_dmg * (1.8 if is_crit else 1.0)))
	return {"amount": maxi(1, final_dmg), "crit": is_crit}


func _find_nearest_enemy(max_range: float) -> Node2D:
	var best: Node2D = null
	var best_dist := max_range
	for node in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(node) or node.get("_is_dead"):
			continue
		var d := global_position.distance_to(node.global_position)
		if d <= best_dist:
			best_dist = d
			best = node
	return best


func _get_enemies_in_range(max_range: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(node) and not node.get("_is_dead"):
			if global_position.distance_to(node.global_position) <= max_range:
				result.append(node)
	return result


func take_damage(amount: int, _is_crit: bool = false) -> void:
	if _is_dead or _invuln_timer > 0.0:
		return
	current_hp = maxi(0, current_hp - amount)
	_invuln_timer = 0.35
	_hurt_timer = 0.2
	hp_changed.emit(current_hp, max_hp)
	if _combat != null:
		_combat.spawn_damage_number(global_position, amount, false, false, true)
		_combat.add_screen_shake(5.0)
	if current_hp <= 0:
		_die()


func heal(amount: int) -> void:
	if _is_dead or amount <= 0:
		return
	var prev := current_hp
	current_hp = mini(max_hp, current_hp + amount)
	var gained := current_hp - prev
	if gained > 0:
		hp_changed.emit(current_hp, max_hp)
		if _combat != null:
			_combat.spawn_damage_number(global_position, gained, false, true, false)


func on_enemy_killed() -> void:
	if life_on_kill > 0:
		heal(life_on_kill)


func apply_upgrade(upgrade: Dictionary) -> void:
	var stat := str(upgrade.get("stat", ""))
	var val := float(upgrade.get("value", 0.0))
	match stat:
		"attack_damage_mult":
			attack_damage *= (1.0 + val)
		"attack_cooldown_mult":
			attack_cooldown = maxf(0.18, attack_cooldown * val)
		"max_hp_bonus":
			max_hp += int(val)
			heal(int(val))
			hp_changed.emit(current_hp, max_hp)
		"move_speed_mult":
			move_speed *= (1.0 + val)
		"dash_cooldown_mult":
			dash_cooldown = maxf(0.45, dash_cooldown * val)
		"skill1_power":
			skill1_damage *= (1.0 + val)
			skill1_radius *= 1.2
		"skill2_power":
			skill2_bolts += 2
			skill2_damage *= (1.0 + val)
		"life_on_kill":
			life_on_kill += int(val)
		"crit_chance":
			crit_chance = minf(0.75, crit_chance + val)


func _die() -> void:
	_is_dead = true
	velocity = Vector2.ZERO
	_play_anim("death")
	died.emit()


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


func _facing_vector() -> Vector2:
	match _facing:
		"up":
			return Vector2.UP
		"right":
			return Vector2.LEFT if _flip_h else Vector2.RIGHT
		_:
			return Vector2.DOWN


func _update_animation(vel: Vector2) -> void:
	if _is_dead:
		return
	if _hurt_timer > 0.0:
		_play_anim("hurt")
	elif _attack_anim_timer > 0.0:
		_play_anim("attack")
	elif vel.length() > 15.0:
		_play_anim("walk")
	else:
		_play_anim("idle")


func _play_anim(anim_name: String) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	_sprite.flip_h = _flip_h
	var full_name := "%s_%s" % [anim_name, _facing]
	if _sprite.sprite_frames.has_animation(full_name) and _sprite.animation != full_name:
		_sprite.play(full_name)
