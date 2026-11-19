extends "res://tests/validate_survivor.gd"
## Normal-speed desktop fixtures for current summon effects, shop and result flows.

const CAPTURE_DIR := "res://docs/survivor/commander/"


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Use a graphical Godot run for this capture test.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	game = Scene.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	_click(Vector2(640, 538))
	_validate_assets()
	_validate_summon_assets()
	await _shot("available-shop")

	game.gold = 250
	game.hud.update_stats()
	for i in game.ROLE_ORDER.size():
		_click(ShopHud.summon_button_center(i))
	_check(game.army_count() == 5 and not paused, "Graphical shop buys five roles during combat")
	await create_timer(0.12).timeout
	await _shot("summoning-all")
	await create_timer(0.66).timeout
	_click(ShopHud.train_button_center())
	_check(game.training == 1, "Graphical train button upgrades the army")
	await _shot("training-all")
	await create_timer(0.62).timeout

	var tank := game.army[3]
	var healer := game.army[4]
	var hp := tank.hp
	game._damage(tank, 75)
	game._attack(healer, 1.1)
	_check(tank.hp > hp - roundi(75 * 0.65) and tank.hp < hp, "Live guard and healer events reduce net damage")
	_check(_effect_present("guard_dome") and _effect_present("heal_floor") and _effect_present("heal_plus"),
		"Guard and heal sprites are present in the rendered battlefield")
	await _shot("heal-and-guard")

	var enemy := game._spawn_enemy("boar", 2)
	enemy.position.y = 253.0
	for step in 16:
		game.elapsed += 1.0 / 60.0
		game._move_army(1.0 / 60.0)
		await process_frame
	_check(_formation_valid(), "Formation keeps its ranks while reinforcing")
	await _shot("reinforce-right")

	game.elapsed = game.BOSS_TIME
	game._spawn_waves(0.0)
	var boss := game.boss
	boss.position.y = 246
	game._begin_enemy_strike(boss, tank.position, false)
	game.hud.update_stats()
	await _shot("boss-windup")
	game._damage(boss, boss.hp)
	await _shot("victory")
	_check(game.state == game.State.VICTORY, "Boss death triggers Victory")
	_click(Vector2(520, 457))
	game._damage(game.hero, game.hero.hp)
	await _shot("defeat")
	_check(game.state == game.State.DEFEAT, "Fatal damage after Restart triggers Defeat")
	quit(int(failed))


func _effect_present(id: String) -> bool:
	for child in game._effects.get_children():
		if child is Sprite2D and child.texture != null and child.texture.resource_path.ends_with("/" + id + ".png"):
			return true
	return false
