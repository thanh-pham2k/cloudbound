extends Node

var _failures: Array[String] = []


func _ready() -> void:
	await _run_all()


func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_failures.append(msg)
		printerr("[FAIL] ", msg)
	else:
		print("[PASS] ", msg)


func _run_all() -> void:
	await get_tree().process_frame
	await _test_game_data()
	await _test_sprite_frames()
	await _test_arena_clamp()
	await _test_progression_and_upgrades()
	await _test_enemy_and_boss_lifecycle()

	if _failures.is_empty():
		print("ALL TESTS PASSED!")
		get_tree().quit(0)
	else:
		printerr("TESTS FAILED: ", _failures.size())
		get_tree().quit(1)


func _test_game_data() -> void:
	var gd := get_tree().root.get_node_or_null("GameData")
	_assert(gd != null, "GameData autoload exists")
	_assert(gd.enemies_data.has("melee") and gd.enemies_data.has("ranged") and gd.enemies_data.has("tank"), "GameData has melee, ranged, tank enemies")
	_assert(not gd.boss_data.is_empty(), "GameData has boss config")
	_assert(gd.upgrades_data.size() >= 3, "GameData has >= 3 upgrades")
	_assert(gd.floors_data.size() >= 1, "GameData has >= 1 floor")


func _test_sprite_frames() -> void:
	var chars := ["player_hero", "enemy_melee", "enemy_ranged", "enemy_tank", "boss_thunder_warden"]
	for c in chars:
		var path := "res://assets/generated/sprites/%s/%s_sprite_frames.tres" % [c, c]
		var res := load(path)
		_assert(res is SpriteFrames, "SpriteFrames loads: " + c)
		if res is SpriteFrames:
			var sf := res as SpriteFrames
			_assert(sf.has_animation("idle_down") and sf.has_animation("walk_right") and sf.has_animation("attack_down") and sf.has_animation("death_down"), "SpriteFrames has core animations: " + c)


func _test_arena_clamp() -> void:
	var arena := CloudArena.new()
	arena.configure(880.0, 480.0)
	var clamped := arena.clamp_to_arena(Vector2(2000, 2000), 28.0)
	_assert(clamped.x < 880.0 and clamped.y < 480.0, "CloudArena clamps out-of-bounds coordinates")
	arena.free()


func _test_progression_and_upgrades() -> void:
	var prog := ProgressionSystem.new()
	var state := {"choices": []}
	prog.level_up_choices_ready.connect(func(choices: Array) -> void:
		state["choices"] = choices
	)
	prog.reset()
	prog.add_exp(55)
	_assert(prog.level == 2, "ProgressionSystem levels up at 50 EXP")
	_assert(state["choices"].size() == 3, "ProgressionSystem presents 3 upgrade choices")

	var player := PlayerController.new()
	var base_dmg := player.attack_damage
	player.apply_upgrade({"stat": "attack_damage_mult", "value": 0.25})
	_assert(player.attack_damage > base_dmg, "PlayerController apply_upgrade increases attack damage")
	player.free()
	prog.free()


func _test_enemy_and_boss_lifecycle() -> void:
	var enemy := EnemyBase.new()
	enemy.setup("melee", null, null, null)
	add_child(enemy)
	var state := {"died_exp": 0, "p2": false, "boss_died": false}
	enemy.died.connect(func(exp_r: int, _p: Vector2) -> void:
		state["died_exp"] = exp_r
	)
	enemy.take_damage(9999)
	_assert(int(state["died_exp"]) > 0, "EnemyBase emits died with EXP reward on lethal damage")

	var boss := BossController.new()
	boss.setup(null, null, null)
	add_child(boss)
	boss.phase_changed.connect(func(p: int) -> void:
		if p == 2:
			state["p2"] = true
	)
	boss.died.connect(func(_e: int, _p: Vector2) -> void:
		state["boss_died"] = true
	)
	boss.take_damage(int(boss.max_hp * 0.6))
	_assert(bool(state["p2"]), "BossController transitions to Phase 2 at <= 50% HP")
	boss._state = BossController.BossState.CHASE
	boss.take_damage(boss.max_hp)
	_assert(bool(state["boss_died"]), "BossController emits died when HP reaches 0")
	await get_tree().create_timer(0.8).timeout
