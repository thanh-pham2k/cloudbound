extends Node2D

const Actor := preload("res://scripts/survivor/actor.gd")
const Battlefield := preload("res://scripts/survivor/battlefield.gd")
const Hud := preload("res://scripts/survivor/hud.gd")
const DamageText := preload("res://scripts/ui/floating_text.gd")
const ART := "res://assets/survivor/"
const COMMANDER_Y := 638.0
const FORMATION := [
	Vector2(0, -226), Vector2(-75, -226), Vector2(75, -226),
	Vector2(-45, -114), Vector2(45, -114),
]
const RECRUIT_COST := 19
const BOSS_TIME := 278.0
const WEAPONS := {
	"hero": {"name": "Ruyi Staff", "art": "hero_staff", "damage": 33, "range": 147.0,
		"cooldown": 0.54, "kind": "melee", "cost": 0},
	"staff": {"name": "Wooden Staff", "art": "staff", "damage": 16, "range": 136.0,
		"cooldown": 0.86, "kind": "melee", "cost": 5},
	"bow": {"name": "Wooden Bow", "art": "bow", "damage": 16, "range": 324.0,
		"cooldown": 0.79, "kind": "ranged", "cost": 16},
	"magic": {"name": "Magic Staff", "art": "magic", "damage": 27, "range": 270.0,
		"cooldown": 1.18, "kind": "area", "cost": 23, "blast": 120.0},
}
# Health, advance speed, strike reach, damage, gold, XP, foot radius.
const ENEMIES := {
	"slime": [51, 82.0, 79.0, 9, 5, 10, 23.0],
	"boar": [91, 101.0, 88.0, 15, 8, 16, 30.0],
	"boss": [1150, 91.0, 120.0, 40, 45, 65, 56.0],
}
const LANE_ORDER := [1, 0, 2, 1, 2, 0, 2, 1, 0]

enum State { MENU, RUNNING, SHOP, PAUSED, VICTORY, DEFEAT }

var state := State.MENU
var elapsed := 0.0
var gold := 0
var xp := 0
var level := 1
var lane := 1
var wave := 1
var kills := 0
var hero: Actor
var boss: Actor
var army: Array[Actor] = []
var enemies: Array[Actor] = []
var field: Battlefield
var hud: Hud
var _actors: Node2D
var _effects: Node2D
var _play: Node2D
var _spawn_in := 0.82
var _spawn_count := 0
var _escort_in := 3.5
var _boss_sent := false
var _queued_shops := 0
var _pending_summons: Array[Vector2] = []
var _projectiles: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud = Hud.new()
	hud.game = self
	add_child(hud)
	_reset_field()
	_enter(State.MENU)


func _reset_field() -> void:
	# Dispose the previous round immediately so its tweens and effects cannot
	# continue behind a restarted round.
	if is_instance_valid(_play):
		remove_child(_play)
		_play.queue_free()
	_play = Node2D.new()
	_play.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_play)
	field = Battlefield.new()
	_play.add_child(field)
	_actors = Node2D.new()
	_actors.y_sort_enabled = true
	_play.add_child(_actors)
	_effects = Node2D.new()
	_effects.z_index = 3
	_play.add_child(_effects)
	hero = _new_actor("hero", 210, 26.0, Vector2(Battlefield.LANES[1], COMMANDER_Y))
	hero.weapon_id = "hero"
	boss = null
	army.clear()
	army.resize(FORMATION.size())
	enemies.clear()
	_projectiles.clear()
	_pending_summons.clear()
	elapsed = 0.0
	gold = 0
	xp = 0
	level = 1
	wave = 1
	kills = 0
	lane = 1
	_spawn_in = 0.82
	_spawn_count = 0
	_escort_in = 3.5
	_boss_sent = false
	_queued_shops = 0


func start_game() -> void:
	_reset_field()
	_enter(State.RUNNING)


func main_menu() -> void:
	_reset_field()
	_enter(State.MENU)


func resume() -> void:
	if state == State.SHOP and _queued_shops > 0:
		_queued_shops -= 1
		hud.show_shop()
	elif state in [State.PAUSED, State.SHOP]:
		_enter(State.RUNNING)


func pause_game() -> void:
	if state == State.RUNNING:
		_enter(State.PAUSED)


func _enter(next: State) -> void:
	state = next
	get_tree().paused = state in [State.SHOP, State.PAUSED]
	match state:
		State.MENU:
			hero.hide()
			hud.show_menu()
		State.RUNNING:
			hud.hide_overlay()
			for at in _pending_summons:
				_fx("summon", at + Vector2(0, -19), 108.0, 0.64)
			_pending_summons.clear()
		State.SHOP: hud.show_shop()
		State.PAUSED: hud.show_pause()
		State.VICTORY, State.DEFEAT: hud.show_result(state == State.VICTORY)
	hud.update_stats()


func _exit_tree() -> void:
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if state == State.RUNNING:
			pause_game()
		elif state in [State.SHOP, State.PAUSED]:
			resume()
		get_viewport().set_input_as_handled()
	elif state == State.RUNNING:
		if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
			lane = maxi(0, lane - 1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
			lane = mini(2, lane + 1)
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if state != State.RUNNING:
		return
	elapsed += delta
	field.scroll(delta)
	_move_army(delta)
	_spawn_waves(delta)
	_move_projectiles(delta)
	_attack(hero, delta)
	for monkey in army:
		if is_instance_valid(monkey):
			_attack(monkey, delta)
	var allies := _allies()
	var leaders: Array[Actor] = [null, null, null]
	for enemy in enemies:
		if state != State.RUNNING:
			break
		var column := enemy.enemy_lane
		_update_enemy(enemy, allies, leaders[column], delta)
		if enemy.hp > 0:
			leaders[column] = enemy
	# Breached units are retired without kills or rewards.
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].hp == 0:
			enemies.remove_at(i)
	if state == State.RUNNING and _queued_shops > 0:
		_queued_shops -= 1
		_enter(State.SHOP)
	hud.update_stats()


func _move_army(delta: float) -> void:
	var target_x: float = Battlefield.LANES[lane]
	var dx := target_x - hero.position.x
	hero.face(dx)
	hero.position.x = lerpf(hero.position.x, target_x, 1.0 - exp(-14.0 * delta))
	hero.move_pose(absf(dx) > 2.0)
	field.command_x = hero.position.x
	for monkey in army:
		if not is_instance_valid(monkey):
			continue
		monkey.face(dx)
		monkey.position = _formation_position(monkey.slot)
		monkey.move_pose(absf(dx) > 2.0)


func _formation_position(slot: int) -> Vector2:
	return hero.position + FORMATION[slot]


func _spawn_waves(delta: float) -> void:
	wave = mini(5, 1 + int(elapsed / 55.0))
	if elapsed >= BOSS_TIME:
		if not _boss_sent:
			_boss_sent = true
			boss = _spawn_enemy("boss", 1)
			field.warn(1)
			_fx("boss_alert", Vector2(640, 174), 92.0, 1.15)
		_escort_in -= delta
		if _escort_in <= 0.0:
			_spawn_enemy("boar", 0)
			_spawn_enemy("boar", 2)
			_escort_in += 8.0
		return
	_spawn_in -= delta
	if _spawn_in > 0.0:
		return
	var column: int = LANE_ORDER[_spawn_count % LANE_ORDER.size()]
	var boar := wave > 1 and (_spawn_count % maxi(2, 6 - wave)) == 0
	_spawn_enemy("boar" if boar else "slime", column)
	field.warn(column)
	if wave >= 3 and _spawn_count % (8 - wave) == 0:
		_spawn_enemy("boar" if wave >= 4 else "slime", (column + 1) % 3)
		if wave == 5 and _spawn_count % 6 == 0:
			_spawn_enemy("slime", (column + 2) % 3)
	_spawn_count += 1
	_spawn_in += [2.55, 2.25, 1.96, 1.72, 1.49][wave - 1]


func _spawn_enemy(kind: String, column: int) -> Actor:
	var data: Array = ENEMIES[kind]
	var position_on_entry := Vector2(Battlefield.LANES[column], -8.0)
	var hardening := 0
	if kind != "boss":
		hardening = (wave - 1) * (13 if kind == "boar" else 8)
	var enemy := _new_actor(kind, int(data[0]) + hardening, data[6], position_on_entry)
	enemy.enemy_lane = column
	enemy.speed = data[1]
	enemy.attack_range = data[2]
	enemy.attack_damage = data[3]
	enemy.gold_reward = data[4]
	enemy.xp_reward = data[5]
	enemies.append(enemy)
	return enemy


func _new_actor(kind: String, hp: int, radius: float, at: Vector2) -> Actor:
	var unit := Actor.new()
	unit.position = at
	unit.setup(kind, hp, radius)
	_actors.add_child(unit)
	return unit


func _update_enemy(enemy: Actor, allies: Array[Actor], leader: Actor, delta: float) -> void:
	enemy.cooldown = maxf(0.0, enemy.cooldown - delta)
	var column := enemy.enemy_lane
	var center: float = Battlefield.LANES[column]
	var is_boss := enemy.kind == "boss"
	if enemy.windup > 0.0:
		enemy.windup = maxf(0.0, enemy.windup - delta)
		if enemy.windup == 0.0:
			_enemy_strike(enemy, allies)
		return

	var target: Actor
	var nearest := INF
	for ally in allies:
		var depth := ally.position.y - enemy.position.y
		if ally.hp <= 0 or depth < 0.0 or depth > enemy.attack_range:
			continue
		if not Battlefield.in_lane(ally.position.x, column):
			continue
		var distance := enemy.position.distance_squared_to(ally.position)
		if distance < nearest:
			nearest = distance
			target = ally
	if target != null:
		enemy.move_pose(false)
		if enemy.cooldown == 0.0:
			enemy.face(target.position.x - enemy.position.x)
			_begin_enemy_strike(enemy, target.position, false)
		return

	if enemy.position.y >= Battlefield.REAR_LINE_Y:
		enemy.move_pose(false)
		if is_boss:
			if enemy.cooldown == 0.0:
				_begin_enemy_strike(enemy, Vector2(center, Battlefield.REAR_LINE_Y), true)
		else:
			_fx("ground_hit", Vector2(center, Battlefield.REAR_LINE_Y - 10), 84.0, 0.48)
			_damage(hero, enemy.attack_damage)
			enemy.hurt(enemy.hp)
		return

	var rage := 1.24 if is_boss and enemy.hp * 2 < enemy.max_hp else 1.0
	var next_y := minf(enemy.position.y + enemy.speed * rage * delta, Battlefield.REAR_LINE_Y)
	var preferred_x := center
	if leader != null:
		var spacing := 149.0 if leader.kind == "boss" else 75.0
		next_y = minf(next_y, maxf(enemy.position.y, leader.position.y - spacing))
		if leader.position.y - enemy.position.y < spacing + 30.0:
			preferred_x += -22.0 if leader.position.x >= center else 22.0
	var lane_drift := 8.0 if is_boss else 24.0
	enemy.position.x = move_toward(enemy.position.x,
		clampf(preferred_x, center - lane_drift, center + lane_drift), 48.0 * delta)
	enemy.move_pose(next_y > enemy.position.y)
	enemy.position.y = next_y


func _begin_enemy_strike(enemy: Actor, at: Vector2, rear_line: bool) -> void:
	enemy.windup = 0.87 if enemy.kind == "boss" else 0.41
	enemy.strike_position = at
	enemy.strikes_rear_line = rear_line
	enemy.attack_pose(enemy.windup + 0.17)
	_telegraph(at, _strike_radius(enemy), enemy.enemy_lane, enemy.windup)


func _strike_radius(enemy: Actor) -> float:
	return 105.0 if enemy.kind == "boss" else 48.0


func _enemy_strike(enemy: Actor, allies: Array[Actor]) -> void:
	var is_boss := enemy.kind == "boss"
	enemy.cooldown = 1.16 if is_boss and enemy.hp * 2 < enemy.max_hp else (1.63 if is_boss else 1.00)
	_fx("ground_hit" if is_boss else "impact", enemy.strike_position, 148.0 if is_boss else 43.0, 0.33)
	if enemy.strikes_rear_line:
		_damage(hero, enemy.attack_damage)
		return
	for ally in allies:
		if Battlefield.in_lane(ally.position.x, enemy.enemy_lane) and (
				ally.position.distance_to(enemy.strike_position) <= _strike_radius(enemy) + ally.radius * 0.28):
			_damage(ally, enemy.attack_damage)
			if state == State.DEFEAT:
				return


func _allies() -> Array[Actor]:
	var result: Array[Actor] = [hero]
	for monkey in army:
		if is_instance_valid(monkey):
			result.append(monkey)
	return result


func _closest(at: Vector2, candidates: Array[Actor], attack_range: float) -> Actor:
	var best: Actor
	var best_dist := INF
	for unit in candidates:
		if unit.hp <= 0:
			continue
		var distance_sq := at.distance_squared_to(unit.position)
		if distance_sq <= pow(attack_range + unit.radius * 0.55, 2) and distance_sq < best_dist:
			best = unit
			best_dist = distance_sq
	return best


func _attack(unit: Actor, delta: float) -> void:
	if state != State.RUNNING or unit.hp <= 0 or not WEAPONS.has(unit.weapon_id):
		return
	unit.cooldown = maxf(0.0, unit.cooldown - delta)
	if unit.cooldown > 0.0:
		return
	var weapon: Dictionary = WEAPONS[unit.weapon_id]
	var target := _closest(unit.position, enemies, weapon.range)
	if target == null:
		return
	unit.cooldown = weapon.cooldown
	var damage := int(weapon.damage) + (mini(level - 1, 12) * 2 if unit == hero else 0)
	unit.face(target.position.x - unit.position.x)
	unit.attack_pose(0.30)
	match weapon.kind:
		"melee":
			var slash_pos := unit.position.lerp(target.position, 0.64) + Vector2(0, -37)
			var slash := _fx("slash_large" if unit == hero else "slash_small", slash_pos,
				105.0 if unit == hero else 69.0, 0.27)
			slash.flip_h = target.position.x < unit.position.x
			_damage(target, damage)
		"ranged":
			var arrow := _sprite("arrow", unit.position + Vector2(0, -32), 38.0)
			_projectiles.append({"sprite": arrow, "target": target, "damage": damage,
				"destination": target.position + Vector2(0, -28)})
		"area":
			var impact := target.position
			_fx("magic_hit", impact + Vector2(0, -33), weapon.blast * 1.43, 0.47)
			for enemy in enemies.duplicate():
				if state == State.RUNNING and enemy.position.distance_to(impact) <= weapon.blast + enemy.radius * 0.3:
					_damage(enemy, damage)


func _move_projectiles(delta: float) -> void:
	for i in range(_projectiles.size() - 1, -1, -1):
		if state != State.RUNNING:
			break
		var arrow: Dictionary = _projectiles[i]
		var sprite: Sprite2D = arrow.sprite
		if is_instance_valid(arrow.target) and arrow.target.hp > 0:
			arrow.destination = arrow.target.position + Vector2(0, -28)
		var destination: Vector2 = arrow.destination
		sprite.rotation = (destination - sprite.position).angle() + PI * 0.25
		sprite.position = sprite.position.move_toward(destination, delta * 660.0)
		if sprite.position.is_equal_approx(destination):
			_projectiles.remove_at(i)
			sprite.queue_free()
			if is_instance_valid(arrow.target) and arrow.target.hp > 0:
				_damage(arrow.target, arrow.damage)


func _damage(unit: Actor, amount: int) -> void:
	if unit.hp <= 0:
		return
	unit.hurt(amount)
	var number := DamageText.new()
	number.setup(str(amount), Color("#ffedb3") if unit.gold_reward > 0 else Color("#ff9785"))
	number.position = unit.position + Vector2(0, -146 if unit.kind == "boss" else -62)
	_effects.add_child(number)
	if unit.hp > 0:
		return
	if unit == hero:
		_enter(State.DEFEAT)
	elif unit.slot >= 0:
		army[unit.slot] = null
	else:
		enemies.erase(unit)
		kills += 1
		award(unit.gold_reward, unit.xp_reward)
		_fx("gold", unit.position + Vector2(-12, -28), 23.0, 0.49, Vector2(-10, -45))
		_fx("xp", unit.position + Vector2(12, -26), 19.0, 0.51, Vector2(10, -50))
		if unit.kind == "boss":
			boss = null
			_enter(State.VICTORY)


func xp_needed() -> int:
	return 17 + level * 12


func award(coins: int, experience: int) -> void:
	gold += coins
	xp += experience
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		hero.max_hp += 3
		hero.hp = mini(hero.max_hp, hero.hp + 23)
		_queued_shops += 1


func army_count() -> int:
	return army.size() - army.count(null)


func can_recruit() -> bool:
	return state == State.SHOP and gold >= RECRUIT_COST and army.has(null)


func buy_monkey() -> bool:
	if not can_recruit():
		return false
	var slot := army.find(null)
	# A shop can open while a fallen monkey is still fading at this slot.
	for unit: Actor in _actors.get_children():
		if unit.slot == slot and unit.hp == 0:
			unit.hide()
			unit.queue_free()
	var at := _formation_position(slot)
	var monkey := _new_actor("monkey", 86 + mini(level, 10) * 4, 16.0, at)
	monkey.slot = slot
	army[slot] = monkey
	_equip(monkey, "staff")
	_pending_summons.append(at)
	gold -= RECRUIT_COST
	hud.update_stats()
	hud.show_shop(slot)
	return true


func can_equip(slot: int, id: String) -> bool:
	if state != State.SHOP or slot < 0 or slot >= army.size() or not WEAPONS.has(id) or id == "hero":
		return false
	var monkey := army[slot]
	return is_instance_valid(monkey) and monkey.hp > 0 and monkey.weapon_id != id and gold >= WEAPONS[id].cost


func buy_weapon(slot: int, id: String) -> bool:
	if not can_equip(slot, id):
		return false
	_equip(army[slot], id)
	gold -= WEAPONS[id].cost
	hud.update_stats()
	hud.show_shop(slot)
	return true


func _equip(monkey: Actor, id: String) -> void:
	monkey.cooldown = 0.0
	monkey.equip(id, load(ART + WEAPONS[id].art + ".png"))


func _sprite(id: String, at: Vector2, width: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(ART + id + ".png")
	sprite.position = at
	sprite.scale = Vector2.ONE * (width / sprite.texture.get_width())
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_effects.add_child(sprite)
	return sprite


func _fx(id: String, at: Vector2, width: float, life: float, drift := Vector2.ZERO) -> Sprite2D:
	var sprite := _sprite(id, at, width)
	var fade := sprite.create_tween().set_parallel()
	fade.tween_property(sprite, "modulate:a", 0.0, life)
	fade.tween_property(sprite, "position", at + drift, life)
	fade.chain().tween_callback(sprite.queue_free)
	return sprite


func _telegraph(at: Vector2, radius: float, column: int, life: float) -> void:
	var ring := Line2D.new()
	ring.position = at
	ring.width = 2.5
	ring.default_color = Color("#b94132")
	ring.antialiased = true
	var shape := PackedVector2Array()
	var lane_center: float = Battlefield.LANES[column] - at.x
	for step in 48:
		var point := Vector2.from_angle(TAU * float(step) / 48.0) * radius
		point.x = clampf(point.x, lane_center - Battlefield.LANE_HALF_WIDTH,
			lane_center + Battlefield.LANE_HALF_WIDTH)
		shape.append(point)
	ring.points = shape
	ring.closed = true
	_effects.add_child(ring)
	var fade := ring.create_tween()
	fade.tween_property(ring, "modulate:a", 0.25, life)
	fade.tween_callback(ring.queue_free)
