extends CharacterBody2D
class_name PlayerController

signal hp_changed(current_hp: int, max_hp: int)
signal died
signal cooldowns_updated(dash_cd: float, dash_max: float, s1_cd: float, s1_max: float, s2_cd: float, s2_max: float)

const SPRITE_PATH := "res://assets/generated/sprites/player_hero/player_hero_sprite_frames.tres"
const ACTION_BUFFER_WINDOW := 0.18
const ACTION_IMPACT_FRAMES := {
	&"attack_down": 3,
	&"attack_up": 3,
	&"attack_right": 3,
	&"skill_1_down": 4,
	&"skill_2_down": 3,
}

@export var painted_animation_frames: SpriteFrames

var max_hp: int = 999
var current_hp: int = 999
var move_speed: float = 235.0
var crit_chance: float = 0.08
var life_on_kill: int = 0

# Auto-attack stats
var attack_damage: float = 24.0
var attack_cooldown: float = 0.15
var attack_range: float = 210.0
var attack_arc_deg: float = 135.0
var projectile_speed: float = 560.0

# Dash stats
var dash_speed: float = 640.0
var dash_duration: float = 0.18
var dash_cooldown: float = 1.5
var dash_invuln: float = 0.24

# Skill 1 (Q)
var skill1_damage: float = 58.0
var skill1_cooldown: float = 0.1
var skill1_radius: float = 165.0

# Skill 2 (E)
var skill2_damage: float = 38.0
var skill2_cooldown: float = 0.1
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

var _active_action: String = ""
var _action_serial: int = 0
var _action_hit_applied: bool = false
var _action_impact_frame: int = 0
var _action_resolved_anim: StringName = &""
var _action_dir: Vector2 = Vector2.DOWN
var _action_facing: String = "down"
var _action_flip_h: bool = false
var _action_elapsed: float = 0.0
var _action_fallback_duration: float = 0.0
var _buffered_action: String = ""
var _buffered_action_timer: float = 0.0
var _buffered_attack_use_mouse: bool = false

var _attack_held: bool = false
var _attack_use_mouse: bool = false
var _is_dead: bool = false

var _facing: String = "down"
var _flip_h: bool = false
var _sprite: AnimatedSprite2D
var _flash_tween: Tween
var _combat: CombatSystem
var _arena: CloudArena


func setup(combat: CombatSystem, arena: CloudArena) -> void:
	_combat = combat
	_arena = arena
	if arena != null and arena.painted_visuals:
		const PAINTED := preload("res://scripts/world/painted_sprite.gd")
		const HERO := preload("res://assets/processed/characters/staff_wielding_monkey_hero.png")
		if painted_animation_frames != null:
			_sprite.sprite_frames = painted_animation_frames
			_sprite.offset = Vector2(0, -63)
			_sprite.scale = Vector2.ONE
			_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			_play_anim("idle", "", false, 1.0, true)
		else:
			PAINTED.set_actor_pose(_sprite, HERO, 122.0)
	_load_config()


func _load_config() -> void:
	var auto_cfg := GameData.get_skill_config("auto_attack")
	if not auto_cfg.is_empty():
		attack_damage = float(auto_cfg.get("damage", 24.0))
		attack_cooldown = float(auto_cfg.get("cooldown", 0.52))
		attack_range = float(auto_cfg.get("range", 210.0))
		attack_arc_deg = float(auto_cfg.get("arc_deg", 135.0))
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
	_clear_input_buffer()
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
	_sprite.frame_changed.connect(_on_sprite_frame_changed)
	_sprite.animation_finished.connect(_on_sprite_animation_finished)
	add_child(_sprite)

	hp_changed.emit(current_hp, max_hp)
	_update_animation(Vector2.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if _is_dead or get_tree().paused:
		_attack_held = false
		return
	if event.is_action_pressed("attack"):
		_attack_held = true
		_attack_use_mouse = event is InputEventMouseButton
		if not event.is_echo():
			try_manual_attack(true)
	elif event.is_action_released("attack"):
		_attack_held = false


func _physics_process(delta: float) -> void:
	if _is_dead or get_tree().paused:
		_attack_held = false
		return

	_atk_timer = maxf(0.0, _atk_timer - delta)
	_dash_timer = maxf(0.0, _dash_timer - delta)
	_skill1_timer = maxf(0.0, _skill1_timer - delta)
	_skill2_timer = maxf(0.0, _skill2_timer - delta)
	_invuln_timer = maxf(0.0, _invuln_timer - delta)
	_hurt_timer = maxf(0.0, _hurt_timer - delta)
	if _buffered_action_timer > 0.0:
		_buffered_action_timer = maxf(0.0, _buffered_action_timer - delta)
		if _buffered_action_timer <= 0.0:
			_buffered_action = ""

	if not _active_action.is_empty():
		_action_elapsed += delta
		if _action_fallback_duration > 0.0:
			if not _action_hit_applied and _action_elapsed >= _action_fallback_duration * 0.5:
				_trigger_action_impact()
			if _action_elapsed >= _action_fallback_duration:
				_active_action = ""
				_action_resolved_anim = &""
				_action_fallback_duration = 0.0
				_consume_buffered_action()
		elif not _action_hit_applied and _sprite != null and _sprite.animation == _action_resolved_anim and _sprite.frame >= _action_impact_frame:
			_trigger_action_impact()

	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_input.length() > 1.0:
		move_input = move_input.normalized()

	if Input.is_action_just_pressed("dash") and _dash_timer <= 0.0 and _dash_active_timer <= 0.0:
		_start_dash(move_input)

	if Input.is_action_just_pressed("skill_1") and _skill1_timer <= 0.0:
		_cast_skill_1()

	if Input.is_action_just_pressed("skill_2") and _skill2_timer <= 0.0:
		_cast_skill_2()

	var is_dashing := _dash_active_timer > 0.0
	if is_dashing:
		_dash_active_timer -= delta
		velocity = _dash_dir * dash_speed
		modulate.a = 0.6
	else:
		modulate.a = 1.0 if _invuln_timer <= 0.0 else (0.55 if int(_invuln_timer * 20.0) % 2 == 0 else 1.0)
		velocity = move_input * move_speed

	move_and_slide()
	if _arena != null:
		global_position = _arena.clamp_to_arena(global_position, 28.0)

	if _active_action.is_empty() and not _buffered_action.is_empty():
		_consume_buffered_action()

	if _attack_held and _atk_timer <= 0.0:
		try_manual_attack()

	if is_dashing:
		_update_facing(_dash_dir)
	elif _active_action.is_empty() and _hurt_timer <= 0.0:
		_update_facing(move_input)
	_update_animation(velocity, is_dashing)
	cooldowns_updated.emit(_dash_timer, dash_cooldown, _skill1_timer, skill1_cooldown, _skill2_timer, skill2_cooldown)


func _start_dash(move_input: Vector2) -> void:
	_clear_input_buffer()
	_cancel_active_action()
	_dash_dir = move_input.normalized() if move_input.length() > 0.1 else _facing_vector()
	_dash_active_timer = dash_duration
	_dash_timer = dash_cooldown
	_invuln_timer = maxf(_invuln_timer, dash_invuln)
	_update_facing(_dash_dir)
	_play_anim("dash", "right", _dash_dir.x < 0.0, 1.0, true)


func try_manual_attack(allow_buffer: bool = false) -> bool:
	if _is_dead or (is_inside_tree() and get_tree().paused):
		return false
	if _atk_timer > 0.0 or _dash_active_timer > 0.0 or _hurt_timer > 0.0:
		return false
	if not _active_action.is_empty():
		if allow_buffer and _action_hit_applied:
			_buffer_action("attack", _attack_use_mouse)
		return false
	_atk_timer = attack_cooldown

	var dir := _facing_vector()
	if _attack_use_mouse and is_inside_tree():
		var mouse_dir := get_global_mouse_position() - global_position
		if mouse_dir.length_squared() > 4.0:
			dir = mouse_dir.normalized()
	else:
		var target := _find_nearest_enemy(attack_range)
		if target != null:
			var to_target := (target.global_position - global_position)
			if to_target.length_squared() > 1.0:
				dir = to_target.normalized()
	_update_facing(dir)
	_start_action("attack", dir)
	return true


func _cast_skill_1() -> void:
	if _is_dead or _dash_active_timer > 0.0 or _hurt_timer > 0.0 or _skill1_timer > 0.0:
		return
	if _active_action == "skill_1" or _active_action == "skill_2":
		if _action_hit_applied:
			_buffer_action("skill_1")
		return
	if _active_action == "attack":
		_clear_input_buffer()
		_cancel_active_action()
	_skill1_timer = skill1_cooldown
	_start_action("skill_1", _facing_vector())


func _cast_skill_2() -> void:
	if _is_dead or _dash_active_timer > 0.0 or _hurt_timer > 0.0 or _skill2_timer > 0.0:
		return
	if _active_action == "skill_1" or _active_action == "skill_2":
		if _action_hit_applied:
			_buffer_action("skill_2")
		return
	if _active_action == "attack":
		_clear_input_buffer()
		_cancel_active_action()
	_skill2_timer = skill2_cooldown
	_start_action("skill_2", _facing_vector())


func _buffer_action(action: String, use_mouse: bool = false) -> void:
	_buffered_action = action
	_buffered_action_timer = ACTION_BUFFER_WINDOW
	_buffered_attack_use_mouse = use_mouse


func _clear_input_buffer() -> void:
	_buffered_action = ""
	_buffered_action_timer = 0.0


func _consume_buffered_action() -> void:
	if _is_dead or (is_inside_tree() and get_tree().paused):
		return
	if not _active_action.is_empty() or _dash_active_timer > 0.0 or _hurt_timer > 0.0:
		return
	var queued := _buffered_action
	var use_mouse := _buffered_attack_use_mouse
	if queued.is_empty() or _buffered_action_timer <= 0.0:
		_clear_input_buffer()
		return
	_clear_input_buffer()
	match queued:
		"skill_1":
			if _skill1_timer <= 0.0:
				_cast_skill_1()
		"skill_2":
			if _skill2_timer <= 0.0:
				_cast_skill_2()
		"attack":
			if _atk_timer <= 0.0:
				_attack_use_mouse = use_mouse
				try_manual_attack(false)


func _start_action(action: String, dir: Vector2) -> void:
	_action_serial += 1
	_active_action = action
	_action_hit_applied = false
	_action_dir = dir.normalized() if dir.length_squared() > 0.0001 else Vector2.DOWN
	_action_facing = _facing
	_action_flip_h = _flip_h
	_action_elapsed = 0.0
	_action_fallback_duration = 0.0
	_action_resolved_anim = _resolve_action_anim(action, _action_facing)
	_action_impact_frame = _resolve_impact_frame(_action_resolved_anim)

	if _sprite == null or _sprite.sprite_frames == null or _action_resolved_anim == &"":
		_action_fallback_duration = _action_target_duration(action)
		return

	var frames := _sprite.sprite_frames
	var frame_count := frames.get_frame_count(_action_resolved_anim)
	if frame_count <= 1:
		_action_fallback_duration = _action_target_duration(action)
		_play_resolved_anim(_action_resolved_anim, _action_flip_h, 1.0, true)
		return

	var speed_scale := 1.0
	var target_dur := _action_target_duration(action)
	var fps := maxf(frames.get_animation_speed(_action_resolved_anim), 1.0)
	var anim_dur := float(frame_count) / fps
	if target_dur < anim_dur:
		speed_scale = clampf(anim_dur / maxf(target_dur, 0.05), 1.0, 6.0)
	_play_resolved_anim(_action_resolved_anim, _action_flip_h, speed_scale, true)


func _action_target_duration(action: String) -> float:
	match action:
		"attack":
			return maxf(0.06, attack_cooldown * 0.9)
		"skill_1":
			return maxf(0.08, skill1_cooldown)
		"skill_2":
			return maxf(0.08, skill2_cooldown)
		_:
			return 0.18


func _cancel_active_action() -> void:
	_action_serial += 1
	_active_action = ""
	_action_hit_applied = false
	_action_resolved_anim = &""
	_action_fallback_duration = 0.0
	_action_elapsed = 0.0


func _on_sprite_frame_changed() -> void:
	if _is_dead or (is_inside_tree() and get_tree().paused):
		return
	if _active_action.is_empty() or _action_hit_applied:
		return
	if _sprite.animation == _action_resolved_anim and _sprite.frame >= _action_impact_frame:
		_trigger_action_impact()


func _on_sprite_animation_finished() -> void:
	if _active_action.is_empty():
		return
	if _sprite.animation != _action_resolved_anim:
		return
	if not _action_hit_applied and not _is_dead and not (is_inside_tree() and get_tree().paused):
		_trigger_action_impact()
	_active_action = ""
	_action_resolved_anim = &""
	_consume_buffered_action()


func _trigger_action_impact() -> void:
	if _is_dead or (is_inside_tree() and get_tree().paused):
		return
	if _active_action.is_empty() or _action_hit_applied:
		return
	var serial := _action_serial
	var action := _active_action
	var dir := _action_dir
	_action_hit_applied = true
	if serial != _action_serial:
		return

	match action:
		"attack":
			_execute_basic_attack(dir)
		"skill_1":
			_execute_skill_1()
		"skill_2":
			_execute_skill_2()


func _execute_basic_attack(dir: Vector2) -> void:
	var arc_rad := deg_to_rad(attack_arc_deg)
	var arc_cos := cos(arc_rad * 0.5)
	if _combat != null:
		_combat.spawn_melee_slash(
			global_position + Vector2(0, -16),
			dir,
			attack_range * 0.92,
			arc_rad,
			Color(1.0, 0.85, 0.35)
		)

	if is_inside_tree():
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if not is_instance_valid(enemy) or enemy.get("_is_dead") or not enemy.has_method("take_damage"):
				continue
			var to_enemy: Vector2 = enemy.global_position - global_position
			var dist := to_enemy.length()
			if dist > attack_range:
				continue
			if dist <= 48.0 or to_enemy.normalized().dot(dir) >= arc_cos:
				var dmg_roll := _roll_damage(attack_damage)
				var hp_before: Variant = enemy.get("current_hp")
				var res: Variant = enemy.take_damage(dmg_roll["amount"], dmg_roll["crit"])
				var accepted: bool = (res is bool and res) or (res == null and hp_before != null and int(enemy.get("current_hp")) < int(hp_before))
				if accepted and _combat != null:
					_combat.spawn_hit_impact(enemy.global_position + Vector2(0, -34), Color(1.0, 0.88, 0.42), 0.58)


func _execute_skill_1() -> void:
	if _combat != null:
		_combat.spawn_ring_burst(global_position, skill1_radius, Color(0.98, 0.85, 0.32))
		_combat.add_screen_shake(4.5)

	if not is_inside_tree():
		return
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or enemy.get("_is_dead"):
			continue
		if enemy.global_position.distance_to(global_position) <= skill1_radius and enemy.has_method("take_damage"):
			var dmg_roll := _roll_damage(skill1_damage)
			var hp_before: Variant = enemy.get("current_hp")
			var res: Variant = enemy.take_damage(dmg_roll["amount"], dmg_roll["crit"])
			var accepted: bool = (res is bool and res) or (res == null and hp_before != null and int(enemy.get("current_hp")) < int(hp_before))
			if accepted and _combat != null:
				_combat.spawn_hit_impact(enemy.global_position + Vector2(0, -34), Color(1.0, 0.86, 0.35), 0.7)


func _execute_skill_2() -> void:
	var enemies := _get_enemies_in_range(skill2_range)
	if enemies.is_empty():
		if _combat != null:
			_combat.spawn_ring_burst(global_position, skill2_range * 0.45, Color(0.75, 0.55, 1.0))
		return

	if _combat != null:
		_combat.add_screen_shake(3.5)

	var strikes := mini(skill2_bolts, enemies.size())
	for i in range(strikes):
		var target: Node2D = enemies[i]
		if not is_instance_valid(target) or target.get("_is_dead"):
			continue
		var dmg_roll := _roll_damage(skill2_damage)
		var accepted := true
		if target.has_method("take_damage"):
			var hp_before: Variant = target.get("current_hp")
			var res: Variant = target.take_damage(dmg_roll["amount"], dmg_roll["crit"])
			accepted = (res is bool and res) or (res == null and hp_before != null and int(target.get("current_hp")) < int(hp_before))
		if accepted and _combat != null:
			_combat.spawn_ring_burst(target.global_position, 72.0, Color(0.75, 0.55, 1.0))
			_combat.spawn_hit_impact(target.global_position + Vector2(0, -36), Color(0.78, 0.62, 1.0), 0.72)


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


func take_damage(amount: int, _is_crit: bool = false) -> bool:
	if amount <= 0 or _is_dead or _invuln_timer > 0.0:
		return false
	_clear_input_buffer()
	_cancel_active_action()
	current_hp = maxi(0, current_hp - amount)
	_invuln_timer = 0.35
	_hurt_timer = 0.2
	_trigger_hit_flash()
	hp_changed.emit(current_hp, max_hp)
	if _combat != null:
		_combat.spawn_damage_number(global_position, amount, false, false, true, 112.0)
		_combat.add_screen_shake(5.0)
	if current_hp <= 0:
		_die()
	else:
		_play_anim("hurt", "", false, 1.0, true)
	return true


func heal(amount: int) -> void:
	if _is_dead or amount <= 0:
		return
	var prev := current_hp
	current_hp = mini(max_hp, current_hp + amount)
	var gained := current_hp - prev
	if gained > 0:
		hp_changed.emit(current_hp, max_hp)
		if _combat != null:
			_combat.spawn_damage_number(global_position, gained, false, true, false, 112.0)


func on_enemy_killed() -> void:
	if life_on_kill > 0:
		heal(life_on_kill)


func apply_upgrade(upgrade: Dictionary, heal_on_upgrade: bool = true) -> void:
	var stat := str(upgrade.get("stat", ""))
	var val := float(upgrade.get("value", 0.0))
	match stat:
		"attack_damage_mult":
			attack_damage *= (1.0 + val)
		"attack_cooldown_mult":
			attack_cooldown = maxf(0.06, attack_cooldown * val)
		"max_hp_bonus":
			max_hp += int(val)
			if heal_on_upgrade:
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
	_clear_input_buffer()
	_cancel_active_action()
	_is_dead = true
	_attack_held = false
	_dash_active_timer = 0.0
	_hurt_timer = 0.0
	velocity = Vector2.ZERO
	modulate.a = 1.0
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	if _sprite != null:
		_sprite.modulate = Color.WHITE
		_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	_play_anim("death", "", false, 1.0, true)
	died.emit()


func _trigger_hit_flash() -> void:
	if _sprite == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_sprite.modulate = Color(1.65, 1.35, 1.35)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_sprite, "modulate", Color.WHITE, 0.11)


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


func _resolve_action_anim(action: String, facing: String) -> StringName:
	if _sprite == null or _sprite.sprite_frames == null:
		return &""
	var frames := _sprite.sprite_frames
	var candidates: Array[StringName] = [
		StringName("%s_%s" % [action, facing]),
		StringName("%s_down" % action),
	]
	if action == "skill_1" or action == "skill_2":
		candidates.append(StringName("attack_%s" % facing))
		candidates.append(&"attack_down")
	candidates.append(&"default")
	for anim in candidates:
		if frames.has_animation(anim):
			return anim
	return &""


func _resolve_impact_frame(anim_name: StringName) -> int:
	if _sprite == null or _sprite.sprite_frames == null or anim_name == &"":
		return 0
	var frames := _sprite.sprite_frames
	if not frames.has_animation(anim_name):
		return 0
	var count := frames.get_frame_count(anim_name)
	if count <= 1:
		return 0
	if ACTION_IMPACT_FRAMES.has(anim_name):
		return clampi(int(ACTION_IMPACT_FRAMES[anim_name]), 0, count - 1)
	return clampi(roundi(float(count - 1) * 0.6), 0, count - 1)


func _update_animation(vel: Vector2, is_dashing: bool = false) -> void:
	if _is_dead:
		return
	if _hurt_timer > 0.0:
		_play_anim("hurt")
	elif is_dashing:
		if _sprite != null and _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(&"dash_right"):
			_play_anim("dash", "right", _dash_dir.x < 0.0)
		else:
			_play_anim("walk", "", false, 1.35)
	elif not _active_action.is_empty():
		return
	elif vel.length() > 15.0:
		var walk_speed_scale := clampf(vel.length() / 235.0, 0.85, 1.45)
		_play_anim("walk", "", false, walk_speed_scale)
	else:
		_play_anim("idle")


func _play_anim(anim_name: String, facing: String = "", flip_h: bool = false, speed_scale: float = 1.0, force_restart: bool = false) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if facing.is_empty():
		facing = _facing
		flip_h = _flip_h
	var full_name := StringName("%s_%s" % [anim_name, facing])
	var frames := _sprite.sprite_frames
	if not frames.has_animation(full_name):
		full_name = StringName("%s_down" % anim_name)
	if not frames.has_animation(full_name):
		if frames.has_animation(&"default"):
			full_name = &"default"
		else:
			_sprite.pause()
			return
	_play_resolved_anim(full_name, flip_h, speed_scale, force_restart)


func _play_resolved_anim(full_name: StringName, flip_h: bool, speed_scale: float = 1.0, force_restart: bool = false) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var frames := _sprite.sprite_frames
	if not frames.has_animation(full_name):
		return
	if frames == painted_animation_frames:
		_sprite.flip_h = String(full_name).ends_with("_right") and flip_h
	else:
		_sprite.flip_h = flip_h

	# Keep AnimatedSprite2D custom_speed at 1.0 and drive playback solely via speed_scale.
	var is_loop := frames.get_animation_loop(full_name)
	if force_restart or _sprite.animation != full_name or (is_loop and not _sprite.is_playing()):
		if force_restart:
			_sprite.stop()
			_sprite.frame = 0
		_sprite.speed_scale = speed_scale
		_sprite.play(full_name)
	elif is_loop:
		_sprite.speed_scale = speed_scale
