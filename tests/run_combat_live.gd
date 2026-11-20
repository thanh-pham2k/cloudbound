extends "res://tests/validate_survivor.gd"
## Visible live QA: Phase 1 tests all 5 monkey roles at normal 1x speed;
## Phase 2 simulates a complete 5-minute match at 5x speed and restores 1x speed.

const SPEED := 5.0
const MIN_DURATION := 300.0
const WATCHDOG_SECONDS := 335.0

var _out_dir := "res://docs/survivor/combat_qa"
var _phase_shots := {}
var _original_ticks: int
var _original_max_steps: int


func _run() -> void:
	if DisplayServer.get_name() == "headless" or "--fixed-fps" in OS.get_cmdline_args():
		printerr("Launch run_combat_live.gd in a visible window without --headless or --fixed-fps.")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir)) != OK:
		printerr("Unable to create capture directory " + _out_dir)
		quit(1)
		return

	_original_ticks = Engine.physics_ticks_per_second
	_original_max_steps = Engine.max_physics_steps_per_frame
	Engine.time_scale = 1.0

	root.title = "Hoa Qua Son — Combat QA (Phase 1: 1× All 5 Roles)"
	root.grab_focus()
	game = Scene.instantiate()
	root.add_child(game)
	Engine.time_scale = 1.0
	await process_frame
	_click(Vector2(640, 538))
	_check(game.state == game.State.RUNNING, "Start Game opens the live battlefield at 1×")
	if failed:
		quit(1)
		return

	await _phase_one_normal_speed()
	await _phase_two_full_match_5x()

	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = _original_ticks
	Engine.max_physics_steps_per_frame = _original_max_steps
	_check(Engine.time_scale == 1.0, "Engine.time_scale restored to 1.0 after live testing")
	await create_timer(1.5, true, false, true).timeout
	quit(int(failed))


func _phase_one_normal_speed() -> void:
	# Summon all 5 roles at 1x speed and observe real combat, weapon alignment, and hit feedback.
	game.gold = 300
	game.hud.update_stats()
	for i in game.ROLE_ORDER.size():
		_click(ShopHud.summon_button_center(i))
	_check(game.army_count() == 5 and Engine.time_scale == 1.0,
		"1× Showcase: summoned all 5 monkey roles at normal speed")
	# Let arrival animation settle
	await create_timer(0.85, false).timeout

	# Injure the Tank slightly so Healer actively casts at 1x speed
	var tank := game.army[3]
	if is_instance_valid(tank):
		game._damage(tank, 55)

	# Spawn a wave of enemies across all 3 lanes in range of Staff, Tank, Archer, Mage
	var e_left := game._spawn_enemy("boar", 0)
	e_left.position.y = 260.0
	var e_mid := game._spawn_enemy("boar", 1)
	e_mid.position.y = 255.0
	var e_right := game._spawn_enemy("boar", 2)
	e_right.position.y = 260.0
	var e_extra := game._spawn_enemy("slime", 1)
	e_extra.position.y = 215.0

	var start_ms := Time.get_ticks_msec()
	var shot_early := false
	var shot_mid := false
	var shot_late := false
	var role_attacked := {}
	var hit_flash_seen := false
	var heal_seen := false
	var tank_hp_after_hit := tank.hp if is_instance_valid(tank) else 0

	while Time.get_ticks_msec() - start_ms < 5200:
		await physics_frame
		for m in game.army:
			if is_instance_valid(m) and m.attack_count > 0:
				role_attacked[m.role] = true
		for foe in game.enemies:
			if is_instance_valid(foe) and foe.has_hit_flash():
				hit_flash_seen = true
		if is_instance_valid(tank) and tank.hp > tank_hp_after_hit:
			heal_seen = true
		var dt_ms := Time.get_ticks_msec() - start_ms
		if not shot_early and dt_ms >= 900:
			shot_early = true
			await _save_shot("1x_combat_early")
		elif not shot_mid and dt_ms >= 2200:
			shot_mid = true
			await _save_shot("1x_combat_mid")
		elif not shot_late and dt_ms >= 3600:
			shot_late = true
			await _save_shot("1x_combat_late")

	_check(role_attacked.size() == 5,
		"1× Showcase: all 5 roles executed Windup→Strike→Recovery attacks (%s)" % [role_attacked.keys()])
	_check(hit_flash_seen and heal_seen,
		"1× Showcase: verified hit flash feedback and Healer restoration at 1× speed")


func _phase_two_full_match_5x() -> void:
	root.title = "Hoa Qua Son — Combat QA (Phase 2: 5× Full 5-Minute Match)"
	game.start_game()
	await process_frame

	Engine.physics_ticks_per_second = int(_original_ticks * SPEED)
	Engine.max_physics_steps_per_frame = maxi(_original_max_steps, 30)
	Engine.time_scale = SPEED

	var wall_ms := Time.get_ticks_msec()
	var next_log := 60.0
	var shot_60 := false
	var shot_180 := false
	var shot_boss := false
	var boss_seen := false
	var boss_damaged := false
	var boss_enraged := false
	var peak := 0
	var lanes_seen := {}
	var routes_ok := true
	var formation_ok := true
	var known_y := {}

	while game.state == game.State.RUNNING and game.elapsed < WATCHDOG_SECONDS and (Time.get_ticks_msec() - wall_ms) < 95000:
		await physics_frame
		_shop()
		peak = maxi(peak, game.army_count())
		formation_ok = formation_ok and _formation_valid()
		var active_y := {}
		for foe in game.enemies:
			var id := foe.get_instance_id()
			lanes_seen[foe.enemy_lane] = true
			routes_ok = routes_ok and game.field.in_lane(foe.position.x, foe.enemy_lane)
			if known_y.has(id):
				routes_ok = routes_ok and foe.position.y >= float(known_y[id])
			active_y[id] = foe.position.y
		known_y = active_y

		if is_instance_valid(game.boss):
			boss_seen = true
			if game.boss.hp < game.boss.max_hp:
				boss_damaged = true
			if game.boss.hp * 2 < game.boss.max_hp:
				boss_enraged = true
			if not shot_boss and boss_damaged and game.boss.position.y > 140.0:
				shot_boss = true
				await _save_shot("5x_boss_combat")

		if not shot_60 and game.elapsed >= 60.0:
			shot_60 = true
			await _save_shot("5x_060s_multilane")
		if not shot_180 and game.elapsed >= 180.0:
			shot_180 = true
			await _save_shot("5x_180s_army8")
		if game.elapsed >= next_log:
			print("LIVE5X %.0fs | HP=%d | Gold=%d | Lvl=%d | Army=%d | Train=%d | Kills=%d | Boss=%s" % [
				game.elapsed, game.hero.hp, game.gold, game.level, game.army_count(), game.training, game.kills,
				str(game.boss.hp) if is_instance_valid(game.boss) else "—"])
			next_log += 60.0

	var wall_sec := float(Time.get_ticks_msec() - wall_ms) / 1000.0
	await _save_shot("5x_victory_result")
	print("LIVE5X RESULT %s | game=%.2fs | wall=%.2fs | eff=%.2fx | kills=%d | peak_army=%d | training=%d" % [
		game.State.keys()[game.state], game.elapsed, wall_sec, game.elapsed / maxf(0.1, wall_sec),
		game.kills, peak, game.training])

	_check(game.state == game.State.VICTORY and game.elapsed >= MIN_DURATION,
		"5× Match: reached 5-minute checkpoint and achieved Victory")
	_check(formation_ok and peak == game.ARMY_CAP and game.training == game.MAX_TRAINING,
		"5× Match: 8-monkey formation, spacing, and max training held throughout")
	_check(routes_ok and lanes_seen.size() == 3,
		"5× Match: multi-lane combat preserved all 3 lanes and monotonic enemy routes")
	_check(boss_seen and boss_damaged and boss_enraged,
		"5× Match: Boss spawned, entered enraged phase, and was defeated")

	# Verify Defeat state transition cleanly
	Engine.time_scale = 1.0
	game.start_game()
	await process_frame
	game._damage(game.hero, 9999)
	await process_frame
	_check(game.state == game.State.DEFEAT, "Defeat state triggers cleanly at zero Wukong HP")
	await _save_shot("1x_defeat_result")


func _save_shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := _out_dir.path_join(label + ".png")
	var ok := image != null and image.save_png(path) == OK
	_phase_shots[label] = ok
	print("CAPTURE  %s (%s)" % [path, "OK" if ok else "FAIL"])
	_check(ok, "Captured live screenshot " + label)
