extends Node2D

const EnemyLooks := preload("res://scripts/survivor/enemy_looks.gd")
const Polish := preload("res://scripts/survivor/polish.gd")
const Actor := preload("res://scripts/survivor/actor.gd")
const Battlefield := preload("res://scripts/survivor/battlefield.gd")
const Army := preload("res://scripts/survivor/army_formation.gd")
const Hud := preload("res://scripts/survivor/hud.gd")
const DamageText := preload("res://scripts/ui/floating_text.gd")
const ART := "res://assets/survivor/"
const COMMANDER_Y := 632.0
const DEFAULT_SPEED := 1.0
const START_GOLD := 44
const MAX_TRAINING := 3
const WAVE_DURATION := 45.0
const BOSS_INTERVAL_WAVES := 5
const BOSS_ROTATION := ["boar_king", "ancient_treant", "nine_tailed_fox", "bull_demon_king", "golden_dragon"]
const ROLE_ORDER := ["staff", "archer", "mage", "tank", "healer"]
const ROLES := {
	"staff": {"name":"Staff", "cost":15, "unlock_level":1, "hp":112, "rank":0, "weapon":"staff", "hint":"Frontline melee"},
	"archer": {"name":"Archer", "cost":22, "unlock_level":2, "hp":96, "rank":1, "weapon":"bow", "hint":"Long-range arrows"},
	"mage": {"name":"Mage", "cost":26, "unlock_level":6, "hp":98, "rank":1, "weapon":"magic", "hint":"Area damage"},
	"tank": {"name":"Tank", "cost":20, "unlock_level":4, "hp":168, "rank":0, "weapon":"shield", "hint":"Frontline guard, 35% damage reduction"},
	"healer": {"name":"Healer", "cost":21, "unlock_level":9, "hp":100, "rank":2, "weapon":"heal", "hint":"Restores injured monkeys"},
}
const WEAPONS := {
	"staff": {"art":"staff", "elite":"staff", "damage":16, "range":136.0,
		"cooldown":0.86, "kind":"melee", "windup":0.14, "strike":0.11, "recovery":0.12},
	"bow": {"art":"bow", "elite":"elite_bow", "damage":16, "range":324.0,
		"cooldown":0.79, "kind":"ranged", "windup":0.15, "strike":0.10, "recovery":0.12},
	"magic": {"art":"mage_staff", "elite":"elite_staff", "damage":27, "range":270.0,
		"cooldown":1.18, "kind":"area", "blast":120.0, "windup":0.20, "strike":0.12, "recovery":0.14},
	"shield": {"art":"shield", "elite":"elite_shield", "damage":12, "range":126.0,
		"cooldown":0.97, "kind":"melee", "windup":0.16, "strike":0.12, "recovery":0.12},
	"heal": {"art":"healer_staff", "elite":"healer_staff", "damage":18, "range":322.0,
		"cooldown":1.30, "kind":"heal", "windup":0.18, "strike":0.12, "recovery":0.14},
}
const MELEE_SLASH_FRAMES := [
	"vfx/melee_spark_00", "vfx/melee_arc_01", "vfx/melee_arc_02", "vfx/melee_arc_03",
]
const MELEE_SLAM_FRAMES := [
	"vfx/melee_slam_00", "vfx/melee_heavy_arc", "vfx/melee_impact_star",
]
const MELEE_COMBO_FRAMES := [
	"vfx/melee_thrust", "vfx/melee_cross_slash", "vfx/melee_combo_burst",
]
const MAGIC_CHARGE_FRAMES := [
	"vfx/magic_charge_00", "vfx/magic_charge_01", "vfx/magic_charge_02",
]
const MAGIC_IMPACT_FRAMES := [
	"vfx/magic_aoe_00", "vfx/magic_aoe_01", "vfx/magic_aoe_02", "vfx/magic_aoe_03",
]
const BOSS_TELEGRAPH_FRAMES := [
	"vfx/boss_ring_00", "vfx/boss_ring_01", "vfx/boss_pillar_charge",
]
const ENEMY_DEFEAT_FRAMES := [
	"vfx/enemy_defeat_puff_00", "vfx/enemy_defeat_puff_01",
]
const HEAL_CAST_FRAMES := [
	"vfx/heal_ring_rise", "vfx/heal_cross_leaf", "vfx/heal_burst_cross",
]
# Health, advance speed, strike reach, damage, gold, XP, foot radius.
const ENEMIES := {
	"slime": [55, 86.0, 56.0, 10, 5, 8, 23.0],
	"boar": [98, 105.0, 64.0, 16, 7, 13, 30.0],
	"boss": [1350, 94.0, 96.0, 44, 40, 55, 56.0],
}
const LANE_ORDER := [1, 0, 2, 1, 2, 0, 2, 1, 0]

enum State { MENU, RUNNING, PAUSED, VICTORY, DEFEAT }

## Select another finale using the same boss rules and timing.
@export_enum("boar_king", "ancient_treant", "nine_tailed_fox", "bull_demon_king", "golden_dragon")
var boss_appearance: String = "boar_king"

var state := State.MENU
var elapsed := 0.0
var gold := 0
var xp := 0
var level := 1
var training := 0
var wave := 1
var kills := 0
var bosses_defeated := 0
var peak_army := 0
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
var _last_boss_wave := 0
var _light_looks := 0
var _heavy_looks := 0
var _elite_looks := 0
var _next_plan := 0.0
var _projectiles: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = DEFAULT_SPEED
	hud = Hud.new()
	hud.game = self
	add_child(hud)
	_reset_field()
	_enter(State.MENU)


func _reset_field() -> void:
	hud.clear_match_fx()
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
	boss = null
	army.clear()
	enemies.clear()
	_projectiles.clear()
	_next_plan = 0.0
	elapsed = 0.0
	gold = START_GOLD
	xp = 0
	level = 1
	wave = 1
	kills = 0
	bosses_defeated = 0
	peak_army = 0
	training = 0
	_spawn_in = 0.82
	_spawn_count = 0
	_escort_in = 3.5
	_last_boss_wave = 0
	_light_looks = 0
	_heavy_looks = 0
	_elite_looks = 0


func start_game() -> void:
	_reset_field()
	_enter(State.RUNNING)


func main_menu() -> void:
	_reset_field()
	_enter(State.MENU)


func resume() -> void:
	if state == State.PAUSED:
		_enter(State.RUNNING)


func pause_game() -> void:
	if state == State.RUNNING:
		_enter(State.PAUSED)


func _enter(next: State) -> void:
	state = next
	get_tree().paused = state == State.PAUSED
	match state:
		State.MENU:
			hero.hide()
			hud.show_menu()
		State.RUNNING: hud.hide_overlay()
		State.PAUSED: hud.show_pause()
		State.VICTORY, State.DEFEAT:
			if state == State.VICTORY:
				hero.celebrate()
				for monkey in army:
					if is_instance_valid(monkey):
						monkey.celebrate()
			hud.show_result(state == State.VICTORY)
	hud.update_stats()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if state == State.RUNNING:
			pause_game()
		elif state == State.PAUSED:
			resume()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if state != State.RUNNING:
		return
	elapsed += delta
	field.scroll(delta)
	_spawn_waves(delta)
	_move_army(delta)
	_move_projectiles(delta)
	for monkey in army:
		if is_instance_valid(monkey):
			_attack(monkey, delta)
	var allies := _allies()
	var lane_enemies: Array = [[], [], []]
	for enemy in enemies:
		if state != State.RUNNING:
			break
		var column := enemy.enemy_lane
		_update_enemy(enemy, allies, lane_enemies[column], delta)
		if enemy.hp > 0:
			lane_enemies[column].append(enemy)
	# Breached units are retired without kills or rewards.
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].hp == 0:
			enemies.remove_at(i)
	hud.update_stats()


func _move_army(delta: float) -> void:
	if elapsed >= _next_plan:
		_next_plan = elapsed + Army.REVIEW_SECONDS
		var reinforced := Army.plan(army, Army.pressure(enemies))
		for column: int in reinforced:
			_fx("summon/ai_reinforce", Vector2(Battlefield.LANES[column], 582), 36.0, 0.48,
				Vector2(0, -13), 0.7)
			_fx("vfx/dust_redeploy", Vector2(Battlefield.LANES[column], 545), 54.0, 0.34,
				Vector2(0, -4), 0.65)
	var weight := 1.0 - exp(-5.8 * delta)
	var uncrowded := army_count() <= Army.SOCKETS.size()
	for monkey in army:
		if not is_instance_valid(monkey):
			continue
		var dx := monkey.goal_x - monkey.position.x
		monkey.face(dx)
		monkey.position.x = lerpf(monkey.position.x, monkey.goal_x, weight)
		if uncrowded:
			monkey.position.y = Army.ROWS[monkey.formation_row]
		monkey.move_pose(absf(dx) > 2.0)
	if uncrowded:
		_rebalance_uncrowded_formation()


func _rebalance_uncrowded_formation() -> void:
	for row in Army.ROWS.size():
		var rank: Array[Actor] = []
		for monkey in army:
			if is_instance_valid(monkey) and monkey.formation_row == row:
				rank.append(monkey)
		if rank.is_empty():
			continue
		for monkey in rank:
			monkey.position.y = Army.ROWS[row]
		if rank.size() <= 1:
			continue
		rank.sort_custom(func(a: Actor, b: Actor): return a.position.x < b.position.x)
		for i in range(1, rank.size()):
			var min_x := rank[i - 1].position.x + Army.GAP
			if rank[i].position.x < min_x:
				rank[i].position.x = minf(min_x, Army.RIGHT)
		for i in range(rank.size() - 2, -1, -1):
			var max_x := rank[i + 1].position.x - Army.GAP
			if rank[i].position.x > max_x:
				rank[i].position.x = maxf(max_x, Army.LEFT)


func _spawn_waves(delta: float) -> void:
	wave = 1 + int(elapsed / WAVE_DURATION)
	if wave % BOSS_INTERVAL_WAVES == 0 and wave > _last_boss_wave and not is_instance_valid(boss):
		_last_boss_wave = wave
		var boss_tier := maxi(1, wave / BOSS_INTERVAL_WAVES)
		boss_appearance = BOSS_ROTATION[(boss_tier - 1) % BOSS_ROTATION.size()]
		boss = _spawn_enemy("boss", 1)
		_escort_in = 2.2

	if is_instance_valid(boss):
		_escort_in -= delta
		if _escort_in <= 0.0:
			var tier := maxi(1, wave / BOSS_INTERVAL_WAVES)
			var escort_pack := mini(8, 2 + tier * 2)
			_spawn_pack(0, escort_pack, true)
			_spawn_pack(2, escort_pack, true)
			if tier >= 2:
				_spawn_pack(1, mini(6, tier * 2), true)
			_escort_in += maxf(2.0, 4.8 - float(tier) * 0.5)
		return

	_spawn_in -= delta
	if _spawn_in > 0.0:
		return
	var column: int = LANE_ORDER[_spawn_count % LANE_ORDER.size()]
	# Escalate pack sizes and multi-lane pressure rapidly across Endless Waves.
	var primary_pack := mini(12, 2 + wave)
	var heavy_pack := wave >= 2 and (_spawn_count % maxi(1, 4 - mini(wave, 3))) == 0
	_spawn_pack(column, primary_pack, heavy_pack)
	if wave >= 2:
		var side_pack := mini(10, 1 + int(float(wave) * 0.85))
		_spawn_pack((column + 1) % 3, side_pack, wave >= 3)
	if wave >= 3:
		var third_pack := mini(9, 1 + int(float(wave - 1) * 0.75))
		_spawn_pack((column + 2) % 3, third_pack, wave >= 4)
	_spawn_count += 1
	_spawn_in += maxf(0.85, 2.85 - float(wave - 1) * 0.22)


func _spawn_pack(column: int, count: int, include_boars: bool) -> void:
	var offsets := [-78.0, -39.0, 0.0, 39.0, 78.0]
	for i in count:
		if enemies.size() >= 90:
			return
		var boar_chance := include_boars and (i == 0 or (wave >= 3 and i % 2 == 0) or (wave >= 7 and i % 3 != 1))
		var kind := "boar" if boar_chance else "slime"
		var spread_x: float = offsets[i % offsets.size()] if count > 1 else 0.0
		var stagger_y := -8.0 - float(int(i / 5.0)) * 30.0
		_spawn_enemy(kind, column, spread_x, stagger_y)


func _spawn_enemy(kind: String, column: int, offset_x := 0.0, start_y := -8.0) -> Actor:
	var data: Array = ENEMIES[kind]
	var center: float = Battlefield.LANES[column]
	var clamped_x := clampf(center + offset_x, center - Battlefield.LANE_HALF_WIDTH + 18.0,
		center + Battlefield.LANE_HALF_WIDTH - 18.0)
	var position_on_entry := Vector2(clamped_x, start_y)
	var hp_bonus := 0
	var dmg_bonus := 0
	var gold_bonus := 0
	var xp_bonus := 0
	if kind == "boss":
		var tier := maxi(1, wave / BOSS_INTERVAL_WAVES)
		hp_bonus = roundi(float(data[0]) * (pow(1.85, float(tier - 1)) - 1.0))
		dmg_bonus = (tier - 1) * 28 + (tier - 1) * (tier - 1) * 10
		gold_bonus = (tier - 1) * 15
		xp_bonus = (tier - 1) * 25
	else:
		var late := maxf(0.0, float(wave - 4))
		hp_bonus = (wave - 1) * (24 if kind == "boar" else 14) + int(pow(late, 1.72) * 15.0)
		dmg_bonus = (wave - 1) * 2 + int(pow(maxf(0.0, float(wave - 5)), 1.45) * 2.2)
	var look := _next_enemy_look(kind)
	var enemy := _new_actor(kind, int(data[0]) + hp_bonus, data[6], position_on_entry, look)
	enemy.enemy_lane = column
	enemy.speed = float(data[1]) * minf(1.85, 1.0 + maxf(0.0, float(wave - 2)) * 0.065)
	enemy.attack_range = data[2]
	enemy.attack_damage = int(data[3]) + dmg_bonus
	var reward_scale := 1.0 if kind == "boss" else maxf(0.32, 1.0 / (1.0 + maxf(0.0, float(wave - 5)) * 0.16))
	enemy.gold_reward = maxi(1, roundi(float(int(data[4]) + gold_bonus) * reward_scale))
	enemy.xp_reward = maxi(2, roundi(float(int(data[5]) + xp_bonus) * reward_scale))
	enemies.append(enemy)
	field.warn(column, ("warning_boss" if look.is_empty() else "warning_red") if kind == "boss" else (
		"warning_orange" if kind == "boar" else ("warning_gold" if wave >= 3 else "warning_green")))
	return enemy


func _next_enemy_look(kind: String) -> String:
	match kind:
		"boss":
			return boss_appearance if EnemyLooks.BOSSES.has(boss_appearance) else ""
		"slime":
			var look: String = EnemyLooks.LIGHT[_light_looks % EnemyLooks.LIGHT.size()]
			_light_looks += 1
			return look
	if wave >= 4:
		var look: String = EnemyLooks.ELITES[_elite_looks % EnemyLooks.ELITES.size()]
		_elite_looks += 1
		return look
	var look: String = EnemyLooks.HEAVY[_heavy_looks % EnemyLooks.HEAVY.size()]
	_heavy_looks += 1
	return look


func boss_display_name() -> String:
	return EnemyLooks.BOSSES.get(boss_appearance, "Boar King")


func _new_actor(kind: String, hp: int, radius: float, at: Vector2, look := "") -> Actor:
	var unit := Actor.new()
	unit.position = at
	unit.setup(kind, hp, radius, look)
	_actors.add_child(unit)
	return unit


func _update_enemy(enemy: Actor, allies: Array[Actor], ahead_in_lane, delta: float) -> void:
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
	var approach_target: Actor
	var nearest_ahead := INF
	for ally in allies:
		var depth := ally.position.y - enemy.position.y
		if ally.hp <= 0 or depth < -14.0:
			continue
		if not Battlefield.in_lane(ally.position.x, column):
			continue
		var distance := enemy.position.distance_squared_to(ally.position)
		if depth >= 0.0 and depth <= 220.0 and distance < nearest_ahead:
			nearest_ahead = distance
			approach_target = ally
		var reach := enemy.attack_range + ally.radius * 0.4
		if depth <= reach and distance <= reach * reach and distance < nearest:
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
			_fx("warning_breach", Vector2(center, Battlefield.REAR_LINE_Y - 14), 57.0, 0.54)
			_fx("staff_dust", Vector2(center, Battlefield.REAR_LINE_Y), 70.0, 0.35, Vector2.ZERO, 0.54)
			_damage(hero, enemy.attack_damage)
			enemy.hurt(enemy.hp)
		return

	var rage := 1.24 if is_boss and enemy.hp * 2 < enemy.max_hp else 1.0
	var next_y := minf(enemy.position.y + enemy.speed * rage * delta, Battlefield.REAR_LINE_Y)
	var preferred_x := enemy.position.x if not is_boss else center
	if not is_boss and approach_target != null:
		preferred_x = approach_target.position.x
	var peers: Array = []
	if ahead_in_lane is Array:
		peers = ahead_in_lane
	elif ahead_in_lane != null:
		peers = [ahead_in_lane]
	for other: Actor in peers:
		if not is_instance_valid(other) or other.hp <= 0:
			continue
		var dx := enemy.position.x - other.position.x
		var dy := other.position.y - enemy.position.y
		var min_y_gap := 125.0 if other.kind == "boss" else 38.0
		if absf(dx) < 42.0 and dy >= 0.0:
			next_y = minf(next_y, maxf(enemy.position.y, other.position.y - min_y_gap))
			if dy < min_y_gap + 28.0 and not is_boss:
				preferred_x += -28.0 if other.position.x >= center else 28.0
	var lane_drift := 8.0 if is_boss else 76.0
	enemy.position.x = move_toward(enemy.position.x,
		clampf(preferred_x, center - lane_drift, center + lane_drift), 62.0 * delta)
	enemy.move_pose(next_y > enemy.position.y)
	if enemy.position.y < 103.0 and next_y >= 103.0:
		var entry := {"boss": "boss_entry", "boar": "enemy_entry" if wave <= 2 else "boar_entry", "slime": "slime_entry"}
		_fx(entry[enemy.kind], Vector2(enemy.position.x, next_y), 108.0 if is_boss else 70.0,
			0.49, Vector2(0, 14), 0.7)
	if enemy.position.y < 580.0 and next_y >= 580.0:
		field.warn(column, "warning_red")
		_fx("danger_ping", Vector2(center, 650), 45.0, 0.55, Vector2.ZERO, 0.68)
	enemy.position.y = next_y


func _begin_enemy_strike(enemy: Actor, at: Vector2, rear_line: bool) -> void:
	enemy.windup = 0.87 if enemy.kind == "boss" else 0.41
	enemy.strike_position = at
	enemy.strikes_rear_line = rear_line
	enemy.attack_pose(enemy.windup + 0.17)
	_telegraph(at, _strike_radius(enemy), enemy.enemy_lane, enemy.windup)
	if enemy.kind == "boss":
		var warning := Polish.sequence(_effects, BOSS_TELEGRAPH_FRAMES, at, 154.0, enemy.windup,
			Vector2.ZERO, 0.84, 0.0, false, 0.88, 1.12)
		warning.z_as_relative = false
		warning.z_index = -1
		_fx("vfx/boss_danger_alert", at + Vector2(0, -42), 78.0, enemy.windup * 0.85,
			Vector2(0, -10), 0.90)


func _boss_tier() -> int:
	return maxi(1, wave / BOSS_INTERVAL_WAVES)


func _strike_radius(enemy: Actor) -> float:
	if enemy.kind == "boss":
		return 105.0 + float(_boss_tier() - 1) * 24.0
	return 48.0


func _enemy_strike(enemy: Actor, allies: Array[Actor]) -> void:
	var is_boss := enemy.kind == "boss"
	var tier := _boss_tier() if is_boss else 1
	var enraged := is_boss and enemy.hp * 2 < enemy.max_hp
	var base_cd := (1.16 if enraged else 1.63) if is_boss else 1.00
	enemy.cooldown = maxf(0.70, base_cd - float(tier - 1) * 0.14) if is_boss else base_cd
	var strike_dmg := roundi(float(enemy.attack_damage) * (1.25 if enraged else 1.0))
	if is_boss:
		enemy.hit_stop(0.05)
		if enraged:
			_fx("vfx/boss_flame_sweep", enemy.strike_position + Vector2(0, -16), 174.0, 0.44, Vector2.ZERO, 0.90)
			_fx("vfx/boss_boulder_burst", enemy.strike_position + Vector2(0, -18), 156.0, 0.46, Vector2(0, -8), 0.88)
			var crack := _fx("vfx/boss_magma_crack", enemy.strike_position + Vector2(0, 4), 160.0, 0.68, Vector2.ZERO, 0.78)
			crack.z_as_relative = false
			crack.z_index = -1
		else:
			_fx("vfx/boss_slam_spike", enemy.strike_position + Vector2(0, -20), 152.0, 0.36, Vector2.ZERO, 0.90)
			_fx("vfx/boss_shock_ripple", enemy.strike_position + Vector2(0, 4), 186.0, 0.42, Vector2.ZERO, 0.78)
			_fx("vfx/boss_dust_cloud", enemy.strike_position + Vector2(0, 8), 150.0, 0.48, Vector2(0, -6), 0.72)
	else:
		_fx("vfx/dust_land_small" if enemy.kind == "boar" else "combat/hit_light",
			enemy.strike_position, 44.0 if enemy.kind == "boar" else 30.0, 0.24, Vector2.ZERO, 0.72)
	if enemy.strikes_rear_line:
		_damage(hero, strike_dmg, "combat/hit_heavy_crit" if is_boss else "combat/hit_spark", Vector2(0, 10))
		return
	var cross_lane_cleave := is_boss and tier >= 2
	for ally in allies:
		if (cross_lane_cleave or Battlefield.in_lane(ally.position.x, enemy.enemy_lane)) and (
				ally.position.distance_to(enemy.strike_position) <= _strike_radius(enemy) + ally.radius * 0.28):
			_damage(ally, strike_dmg, "combat/hit_heavy_crit" if is_boss else "combat/hit_spark",
				Vector2(0, 12 if is_boss else 7))
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
	var weapon: Dictionary = WEAPONS[unit.weapon_id]
	unit.cooldown = maxf(0.0, unit.cooldown - delta)
	if unit.pending_attack:
		unit.windup = maxf(0.0, unit.windup - delta)
		if unit.windup <= 0.0:
			_execute_monkey_strike(unit, weapon)
		return
	if unit.cooldown > 0.0:
		return
	if weapon.kind == "heal":
		var patient := _find_heal_target(unit, weapon)
		if patient == null:
			return
		_begin_monkey_attack(unit, weapon, patient, int(weapon.damage) + training * 2)
		return
	var target := _closest(unit.position, enemies, weapon.range)
	if target == null:
		return
	var damage := int(weapon.damage) + training * 3
	_begin_monkey_attack(unit, weapon, target, damage)


func _begin_monkey_attack(unit: Actor, weapon: Dictionary, target: Actor, amount: int) -> void:
	var windup_sec := float(weapon.windup)
	var strike_sec := float(weapon.strike)
	var recovery_sec := float(weapon.recovery)
	var variation := unit.attack_count
	unit.attack_count += 1
	unit.cooldown = float(weapon.cooldown)
	unit.windup = windup_sec
	unit.pending_attack = true
	unit.pending_target = target
	unit.pending_damage = amount
	unit.pending_variation = variation
	unit.face(target.position.x - unit.position.x)
	unit.begin_attack(unit.role, windup_sec, strike_sec, recovery_sec, variation)
	# Subtle windup telegraph VFX at weapon tip for casters and archers.
	if weapon.kind == "area":
		Polish.sequence(_effects, MAGIC_CHARGE_FRAMES, unit.weapon_tip_position(), 40.0, windup_sec,
			Vector2.ZERO, 0.84, 0.0, false, 0.78, 1.14)
	elif weapon.kind == "heal":
		_fx("vfx/heal_sparkle", unit.weapon_tip_position(), 30.0, windup_sec, Vector2(0, -6), 0.78)
	elif weapon.kind == "ranged" and training >= 2:
		_fx("vfx/bow_charge_star", unit.weapon_tip_position(), 26.0, windup_sec, Vector2.ZERO, 0.72)


func _execute_monkey_strike(unit: Actor, weapon: Dictionary) -> void:
	unit.pending_attack = false
	if state != State.RUNNING or unit.hp <= 0:
		return
	if weapon.kind == "heal":
		var patient: Actor = unit.pending_target if is_instance_valid(unit.pending_target) else null
		if patient == null or patient.hp <= 0 or patient.hp >= patient.max_hp:
			patient = _find_heal_target(unit, weapon)
		if patient == null:
			return
		_apply_heal(unit, patient, unit.pending_damage)
		return

	var target: Actor = unit.pending_target if is_instance_valid(unit.pending_target) else null
	if target == null or target.hp <= 0:
		target = _closest(unit.position, enemies, weapon.range)
	if target == null:
		return
	var damage := unit.pending_damage
	var variation := unit.pending_variation % 3
	unit.face(target.position.x - unit.position.x)
	var dir_vec := (target.position - unit.position).normalized()
	if dir_vec == Vector2.ZERO:
		dir_vec = Vector2(0, -1)

	match weapon.kind:
		"melee":
			var slash_pos := unit.position.lerp(target.position, 0.68) + Vector2(0, -34)
			var tank := unit.role == "tank"
			if tank:
				_fx("vfx/dust_ring_impact", target.position + Vector2(0, -2), 58.0, 0.28, Vector2.ZERO, 0.72)
				var sweep := _fx("combat/hit_sweep", slash_pos + Vector2(0, -4), 60.0, 0.22, Vector2.ZERO, 0.82)
				sweep.flip_h = target.position.x < unit.position.x
				unit.hit_stop(0.045)
				target.hit_stop(0.045)
				if not target.has_hit_flash():
					Polish.burst(_effects, "vfx/enemy_stun_stars",
						target.position + Vector2(0, -56 if target.kind != "boss" else -128),
						44.0, 0.42, Vector2(0, -8), 0.86, 0.80, 1.05, 0.9)
				_damage(target, damage, "combat/hit_shards", dir_vec * 14.0)
			else:
				var flip := target.position.x < unit.position.x
				if variation == 1:
					Polish.sequence(_effects, MELEE_SLAM_FRAMES, slash_pos, 84.0, 0.24, Vector2.ZERO, 0.90, 0.0, flip)
					_fx("vfx/dust_land_heavy", target.position + Vector2(0, -2), 54.0, 0.30, Vector2(0, -4), 0.72)
				elif variation == 2:
					Polish.sequence(_effects, MELEE_COMBO_FRAMES, slash_pos, 78.0, 0.24, Vector2.ZERO, 0.90, 0.0, flip)
				else:
					Polish.sequence(_effects, MELEE_SLASH_FRAMES, slash_pos, 78.0, 0.22, Vector2.ZERO, 0.88, 0.0, flip)
				unit.hit_stop(0.035 if variation != 1 else 0.048)
				target.hit_stop(0.035 if variation != 1 else 0.048)
				var hit_fx := "combat/hit_burst" if (variation == 1 or training >= 2) else "combat/hit_spark"
				_damage(target, damage, hit_fx, dir_vec * (13.0 if variation == 1 else 9.5))
		"ranged":
			var origin := unit.weapon_tip_position()
			var release_id := "vfx/bow_power_ring" if training >= 2 else "vfx/bow_release_burst"
			var release := _fx(release_id, origin, 38.0 if training >= 2 else 34.0, 0.16, Vector2.ZERO, 0.84)
			release.rotation = (target.position - origin).angle()
			var arrow_id := "vfx/arrow_volley_trail" if (training >= 2 and variation == 1) else "vfx/arrow_trail_00"
			var arrow := Polish.sprite(_effects, arrow_id, origin, 38.0)
			_projectiles.append({
				"kind": "arrow",
				"sprite": arrow,
				"target": target,
				"damage": damage,
				"destination": target.position + Vector2(0, -28),
				"speed": 730.0,
				"age": 0.0,
				"stage": 0,
				"trained": training >= 2,
				"volley": training >= 2 and variation == 1,
			})
		"area":
			var origin := unit.weapon_tip_position()
			_fx("vfx/magic_cast_pillar", unit.position + Vector2(0, -14), 52.0, 0.24, Vector2(0, -8), 0.72)
			var orb_id := "vfx/magic_comet_02" if variation == 2 else "vfx/magic_bolt_00"
			var orb := Polish.sprite(_effects, orb_id, origin, 48.0 if variation == 2 else 42.0)
			_projectiles.append({
				"kind": "magic",
				"sprite": orb,
				"target": target,
				"damage": damage,
				"blast": float(weapon.blast),
				"destination": target.position + Vector2(0, -22),
				"speed": 700.0,
				"age": 0.0,
				"stage": 0,
				"comet": variation == 2,
			})


func _find_heal_target(unit: Actor, weapon: Dictionary) -> Actor:
	var target: Actor
	var worst := 1.0
	for ally in army:
		if not is_instance_valid(ally) or ally.hp <= 0 or ally.position.distance_to(unit.position) > weapon.range:
			continue
		var ratio := float(ally.hp) / ally.max_hp
		if ratio < worst - 0.045:
			target = ally
			worst = ratio
	return target


func _apply_heal(unit: Actor, target: Actor, raw_amount: int) -> void:
	var amount := mini(target.max_hp - target.hp, raw_amount)
	if amount <= 0:
		return
	target.hp += amount
	unit.face(target.position.x - unit.position.x)
	if unit.attack_count % 2 == 0:
		Polish.sequence(_effects, HEAL_CAST_FRAMES, target.position + Vector2(0, -20), 74.0, 0.44,
			Vector2(0, -10), 0.86)
	else:
		_fx("vfx/heal_wave_plus", target.position + Vector2(0, -10), 76.0, 0.46, Vector2(0, -10), 0.84)
		_fx("vfx/heal_pillar_leaf", target.position + Vector2(0, -24), 62.0, 0.44, Vector2(0, -14), 0.76)
	var number := DamageText.new()
	number.setup("+%d" % amount, Color("#d9ffad"))
	number.position = target.position + Vector2(0, -69)
	_effects.add_child(number)


func _move_projectiles(delta: float) -> void:
	for i in range(_projectiles.size() - 1, -1, -1):
		if state != State.RUNNING:
			break
		var proj: Dictionary = _projectiles[i]
		if not is_instance_valid(proj.sprite):
			_projectiles.remove_at(i)
			continue
		var sprite: Sprite2D = proj.sprite
		var pkind: String = proj.get("kind", "arrow")
		proj.age = float(proj.age) + delta
		if is_instance_valid(proj.target) and proj.target.hp > 0:
			proj.destination = proj.target.position + Vector2(0, -28 if pkind == "arrow" else -22)
		var destination: Vector2 = proj.destination
		var to_dest := destination - sprite.position
		var move_dir := to_dest.normalized()
		if move_dir == Vector2.ZERO:
			move_dir = Vector2(0, -1)
		sprite.rotation = to_dest.angle()
		if pkind == "arrow" and not proj.get("volley", false):
			var desired := 2 if proj.age > 0.11 else (1 if proj.age > 0.045 else 0)
			if desired != int(proj.stage):
				proj.stage = desired
				Polish.swap(sprite, "vfx/arrow_trail_%02d" % desired, 46.0 if desired == 2 else 40.0)
		elif pkind == "magic" and not proj.get("comet", false) and int(proj.stage) == 0 and proj.age > 0.06:
			proj.stage = 1
			Polish.swap(sprite, "vfx/magic_lance_01", 52.0)
		sprite.position = sprite.position.move_toward(destination, delta * float(proj.get("speed", 680.0)))
		if sprite.position.is_equal_approx(destination):
			_projectiles.remove_at(i)
			sprite.queue_free()
			if pkind == "magic":
				var impact_pt := destination + Vector2(0, 12)
				var blast := float(proj.get("blast", 120.0))
				Polish.sequence(_effects, MAGIC_IMPACT_FRAMES, impact_pt, blast * 1.32, 0.36,
					Vector2.ZERO, 0.88, 0.0, false, 0.86, 1.14)
				var damaged := 0
				for enemy: Actor in enemies.duplicate():
					if state == State.RUNNING and is_instance_valid(enemy) and enemy.hp > 0 and (
							enemy.position.distance_to(impact_pt) <= blast + enemy.radius * 0.3):
						var kb := (enemy.position - impact_pt).normalized()
						if kb == Vector2.ZERO:
							kb = Vector2(0, -1)
						if damaged == 0:
							enemy.hit_stop(0.035)
							Polish.burst(_effects, "vfx/enemy_daze_swirl",
								enemy.position + Vector2(0, -52 if enemy.kind != "boss" else -120),
								40.0, 0.38, Vector2(0, -6), 0.78, 0.82, 1.08, 1.2)
						_damage(enemy, int(proj.damage), "combat/hit_spark" if damaged == 0 else "combat/hit_light", kb * 10.0)
						damaged += 1
			else:
				if is_instance_valid(proj.target) and proj.target.hp > 0:
					var hit_seq := ["vfx/arrow_hit_spark", "vfx/arrow_hit_shatter"] if proj.get("trained", false) else [
						"vfx/arrow_hit_spark", "vfx/arrow_hit_burst"]
					Polish.sequence(_effects, hit_seq, destination, 46.0, 0.22, Vector2.ZERO, 0.88)
					_damage(proj.target, int(proj.damage), "", move_dir * 7.5)
				else:
					_fx("vfx/arrow_miss_dust", destination + Vector2(0, 18), 46.0, 0.28, Vector2.ZERO, 0.74)


func _damage(unit: Actor, amount: int, effect := "combat/hit_spark", knockback := Vector2.ZERO) -> void:
	if unit.hp <= 0:
		return
	if unit.role == "tank":
		amount = maxi(1, roundi(float(amount) * 0.65))
		if not unit.has_hit_flash():
			_fx("vfx/guard_blue_dome", unit.position + Vector2(0, -24), 76.0, 0.32, Vector2.ZERO, 0.74)
			_fx("vfx/guard_blue_shield", unit.position + Vector2(0, -48), 32.0, 0.34, Vector2(0, -10), 0.84)
	var fresh_hit := not unit.has_hit_flash()
	var was_calm := unit.hp * 2 >= unit.max_hp
	unit.hurt(amount)
	if knockback != Vector2.ZERO and unit.hp > 0:
		var scale_kb := 0.35 if unit.kind == "boss" else (0.55 if unit.role == "tank" else 1.0)
		unit.apply_knockback(knockback * scale_kb)
	if fresh_hit and effect != "":
		var chosen := effect
		if unit.gold_reward == 0:
			chosen = "vfx/enemy_heavy_hurt" if amount >= 30 else "vfx/enemy_hurt_flash"
		elif chosen == "combat/hit_spark" and amount >= 32:
			chosen = "vfx/enemy_heavy_hurt"
		_fx(chosen, unit.position + Vector2(0, -28 if unit.kind != "boss" else -81),
			44.0 if unit.kind != "boss" else 60.0, 0.22, Vector2(0, -6), 0.84)
		if unit.appearance in ["poison_toad", "slime_splitter"]:
			_fx("vfx/enemy_poison_cloud", unit.position + Vector2(0, -24), 48.0, 0.34, Vector2(0, -10), 0.74)
	if unit.kind == "boss" and was_calm and unit.hp > 0 and unit.hp * 2 < unit.max_hp:
		_fx("vfx/boss_rage_pillar", unit.position + Vector2(0, -46), 165.0, 0.70, Vector2(0, -12), 0.88)
		_fx("vfx/boss_nova_burst", unit.position + Vector2(0, -10), 192.0, 0.50, Vector2.ZERO, 0.84)
	var number := DamageText.new()
	number.setup(str(amount), Color("#ffedb3") if unit.gold_reward > 0 else Color("#ff9785"))
	number.position = unit.position + Vector2(0, -146 if unit.kind == "boss" else -62)
	_effects.add_child(number)
	if unit.hp > 0:
		return
	if unit == hero:
		_enter(State.DEFEAT)
	elif unit.slot >= 0:
		Polish.sequence(_effects, ENEMY_DEFEAT_FRAMES, unit.position + Vector2(0, -12), 54.0, 0.36, Vector2(0, -8), 0.76)
		army[unit.slot] = null
		_next_plan = 0.0
		if army_count() <= Army.SOCKETS.size():
			_rebalance_uncrowded_formation()
		hud.update_stats()
	else:
		enemies.erase(unit)
		kills += 1
		award(unit.gold_reward, unit.xp_reward)
		Polish.sequence(_effects, ENEMY_DEFEAT_FRAMES, unit.position + Vector2(0, -14),
			140.0 if unit.kind == "boss" else 74.0, 0.42, Vector2(0, -10), 0.82)
		if unit.kind in ["boar", "boss"]:
			_fx("vfx/enemy_defeat_beam", unit.position + Vector2(0, -28),
				126.0 if unit.kind == "boss" else 56.0, 0.44, Vector2(0, -14), 0.78)
		_reward_fx(unit.position + Vector2(-12, -28), true)
		_reward_fx(unit.position + Vector2(12, -26), false)
		if unit.kind == "boss":
			boss = null
			bosses_defeated += 1
			hero.hp = mini(hero.max_hp, hero.hp + 30)
			_fx("vfx/boss_nova_burst", unit.position + Vector2(0, -30), 148.0, 0.68, Vector2(0, -16), 0.90)
			_fx("vfx/support_buff_dome", hero.position + Vector2(0, -24), 92.0, 0.58, Vector2.ZERO, 0.78)


func _reward_fx(at: Vector2, coins: bool) -> void:
	var reward := "gold" if coins else "xp"
	var width := 21.0 if coins else 18.0
	var node := Polish.sprite(_effects, reward + "_drop", at, width)
	var fly := node.create_tween()
	fly.tween_property(node, "position", at + Vector2(0, -20), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fly.tween_callback(Polish.swap.bind(node, reward + "_trail", width * 1.6))
	var destination := Vector2(980, 52) if coins else Vector2(232, 89)
	fly.tween_property(node, "position", destination, 0.43).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fly.tween_callback(hud.reward_received.bind(coins))
	fly.tween_callback(node.queue_free)


func xp_needed() -> int:
	return 22 + level * 15


func award(coins: int, experience: int) -> void:
	gold += coins
	xp += experience
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		hero.max_hp += 3
		hero.hp = mini(hero.max_hp, hero.hp + 15)
		_fx("summon/upgrade_level", hero.position + Vector2(0, -35), 71.0, 0.55, Vector2.ZERO, 0.6)
		for role in ROLE_ORDER:
			if int(ROLES[role].unlock_level) == level:
				hud.unlock_feedback(role)


func army_count() -> int:
	return army.size() - army.count(null)


func is_role_unlocked(role: String) -> bool:
	return ROLES.has(role) and level >= int(ROLES[role].unlock_level)


func summon_cost(role: String) -> int:
	if not ROLES.has(role):
		return 0
	var base := int(ROLES[role].cost)
	var excess := maxi(0, army_count() - 5)
	if excess == 0:
		return base
	var surcharge := roundi(float(excess) * 1.8 + float(excess * excess) * 0.22)
	return base + surcharge


func can_summon(role: String) -> bool:
	return state == State.RUNNING and is_role_unlocked(role) and gold >= summon_cost(role)


func summon(role: String) -> bool:
	if not can_summon(role):
		return false
	var slot := army.find(null)
	if slot < 0:
		slot = army.size()
		army.append(null)
	for unit: Actor in _actors.get_children():
		if unit.slot == slot and unit.hp == 0:
			unit.hide()
			unit.queue_free()
	var profile: Dictionary = ROLES[role]
	var at := Army.arrival(profile.rank, army, Army.pressure(enemies))
	var monkey := _new_actor("monkey", int(profile.hp) + training * 10, 16.0, at)
	monkey.slot = slot
	monkey.role = role
	monkey.role_icon = Polish.texture("summon/role_" + role)
	monkey.formation_row = profile.rank
	monkey.goal_x = at.x
	for column in Battlefield.LANES.size():
		if Battlefield.in_lane(at.x, column):
			monkey.assigned_lane = column
	var price := summon_cost(role)
	army[slot] = monkey
	peak_army = maxi(peak_army, army_count())
	_equip(monkey, profile.weapon)
	gold -= price
	monkey.arrive()
	var ring := Polish.summon_sequence(_effects, "summon", at, 85.0)
	ring.z_as_relative = false
	ring.z_index = -1
	_fx("vfx/dust_summon_beam", at + Vector2(0, -18), 86.0, 0.48, Vector2.ZERO, 0.72)
	hero.command_pose()
	hud.purchase_feedback(role)
	hud.update_stats()
	return true


func training_cost() -> int:
	return 30 + 25 * training + 5 * training * training


func can_train() -> bool:
	return state == State.RUNNING and army_count() > 0 and gold >= training_cost()


func train_army() -> bool:
	if not can_train():
		return false
	gold -= training_cost()
	training += 1
	var shown := 0
	for soldier in army:
		if not is_instance_valid(soldier):
			continue
		soldier.max_hp += 10
		soldier.hp = mini(soldier.max_hp, soldier.hp + 15)
		_equip(soldier, soldier.weapon_id)
		if shown < 10:
			var effect := "vfx/heal_sprout_glow" if soldier.role == "healer" else (
				"vfx/support_shield_up" if soldier.role == "tank" else "vfx/heal_ribbon_rise")
			_fx(effect, soldier.position + Vector2(0, -20), 66.0, 0.62, Vector2(0, -10), 0.74)
			shown += 1
	_fx("vfx/support_buff_dome", hero.position + Vector2(0, -22), 92.0, 0.64, Vector2.ZERO, 0.76)
	hud.purchase_feedback("training")
	hud.update_stats()
	return true


func _equip(monkey: Actor, id: String) -> void:
	var weapon: Dictionary = WEAPONS[id]
	monkey.equip(id, Polish.texture("summon/" + (weapon.elite if training >= 2 else weapon.art)))


func _fx(id: String, at: Vector2, width: float, life: float, drift := Vector2.ZERO,
		opacity := 1.0) -> Sprite2D:
	return Polish.burst(_effects, id, at, width, life, drift, opacity)


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
