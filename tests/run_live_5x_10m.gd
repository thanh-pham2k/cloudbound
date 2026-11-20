extends "res://tests/validate_survivor.gd"
## Visible 10-minute (600s) live stress & visual QA test at 5x speed.
## Captures screenshots + telemetry (FPS, node/FX counts, formation, lane bounds,
## boss cadence, sprite texture validity) and flags anomalies.

const SPEED := 5.0
const TARGET_DURATION := 600.0
const WALL_WATCHDOG_MS := 240000

var _out_dir := "res://docs/survivor/qa_5x_10m"
var _original_ticks: int
var _original_max_steps: int


func _run() -> void:
	if DisplayServer.get_name() == "headless" or "--fixed-fps" in OS.get_cmdline_args():
		printerr("Launch run_live_5x_10m.gd in a visible window without --headless or --fixed-fps.")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir)) != OK:
		printerr("Unable to create capture directory " + _out_dir)
		quit(1)
		return

	_original_ticks = Engine.physics_ticks_per_second
	_original_max_steps = Engine.max_physics_steps_per_frame

	root.title = "Hoa Qua Son — Live 5x QA (10 Minutes)"
	root.grab_focus()
	game = Scene.instantiate()
	root.add_child(game)
	Engine.time_scale = 1.0
	await process_frame
	_click(Vector2(640, 538))
	_check(game.state == game.State.RUNNING, "Start Game opens the live battlefield")
	if failed:
		quit(1)
		return

	Engine.physics_ticks_per_second = int(_original_ticks * SPEED)
	Engine.max_physics_steps_per_frame = maxi(_original_max_steps, 30)
	Engine.time_scale = SPEED

	var wall_ms := Time.get_ticks_msec()
	var next_log := 60.0
	var shot_times := [60.0, 180.0, 300.0, 450.0, 595.0]
	var shot_idx := 0
	var shot_boss := false
	var boss_seen := false
	var boss_damaged := false
	var lanes_seen := {}
	var routes_ok := true
	var route_fail_sample := ""
	var formation_ok := true
	var formation_fail_sample := ""
	var known_y := {}
	var max_nodes := 0
	var max_enemies := 0
	var min_fps := 999.0
	var null_tex_count := 0
	var null_tex_sample := ""

	while game.state == game.State.RUNNING and game.elapsed < TARGET_DURATION and (Time.get_ticks_msec() - wall_ms) < WALL_WATCHDOG_MS:
		await physics_frame
		_shop_endless_10m()

		if not _formation_valid():
			if formation_ok:
				formation_fail_sample = "t=%.1fs hero=%s army=%d" % [game.elapsed, str(game.hero.position), game.army_count()]
			formation_ok = false

		var active_y := {}
		for foe in game.enemies:
			if not is_instance_valid(foe):
				continue
			var id := foe.get_instance_id()
			lanes_seen[foe.enemy_lane] = true
			if not game.field.in_lane(foe.position.x, foe.enemy_lane):
				if routes_ok:
					route_fail_sample = "t=%.1fs out_of_lane kind=%s lane=%d pos=%s" % [game.elapsed, foe.kind, foe.enemy_lane, str(foe.position)]
				routes_ok = false
			if known_y.has(id) and foe.position.y < float(known_y[id]) - 0.5:
				if routes_ok:
					route_fail_sample = "t=%.1fs moved_up kind=%s y=%.1f->%.1f" % [game.elapsed, foe.kind, float(known_y[id]), foe.position.y]
				routes_ok = false
			active_y[id] = foe.position.y
		known_y = active_y

		max_enemies = maxi(max_enemies, game.enemies.size())
		var total_nodes := _count_nodes(game)
		max_nodes = maxi(max_nodes, total_nodes)

		if is_instance_valid(game.boss):
			boss_seen = true
			if game.boss.hp < game.boss.max_hp:
				boss_damaged = true
			if not shot_boss and boss_damaged and game.boss.position.y > 140.0:
				shot_boss = true
				await _save_shot("5x_boss")

		if shot_idx < shot_times.size() and game.elapsed >= shot_times[shot_idx]:
			var label := "5x_%03ds" % int(shot_times[shot_idx])
			shot_idx += 1
			var bad := _find_null_texture(game)
			if bad != "":
				null_tex_count += 1
				if null_tex_sample == "":
					null_tex_sample = bad
			await _save_shot(label)

		if game.elapsed >= next_log:
			var fps := Engine.get_frames_per_second()
			if fps > 0.0:
				min_fps = minf(min_fps, fps)
			var wall_now := float(Time.get_ticks_msec() - wall_ms) / 1000.0
			print("LIVE5X_10M %.0fs (wall=%.1fs eff=%.2fx fps=%.0f) | Wave %d | HP=%d/%d | Gold=%d | Lvl=%d | Army=%d | Train=%d | Enemies=%d | Nodes=%d | Kills=%d | Bosses=%d" % [
				game.elapsed, wall_now, game.elapsed / maxf(0.1, wall_now), fps,
				game.wave, game.hero.hp, game.hero.max_hp, game.gold, game.level,
				game.army_count(), game.training, game.enemies.size(), total_nodes,
				game.kills, game.bosses_defeated])
			next_log += 60.0

	var wall_sec := float(Time.get_ticks_msec() - wall_ms) / 1000.0
	await _save_shot("5x_final")
	print("LIVE5X_10M SUMMARY state=%s | game=%.2fs | wall=%.2fs | eff=%.2fx | wave=%d | HP=%d/%d | kills=%d | bosses=%d | peak_army=%d | training=%d | max_enemies=%d | max_nodes=%d | min_fps=%.0f | null_tex=%d (%s)" % [
		game.State.keys()[game.state], game.elapsed, wall_sec, game.elapsed / maxf(0.1, wall_sec),
		game.wave, game.hero.hp, game.hero.max_hp, game.kills, game.bosses_defeated,
		game.peak_army, game.training, max_enemies, max_nodes, min_fps, null_tex_count, null_tex_sample])

	_check(game.state == game.State.RUNNING and game.elapsed >= TARGET_DURATION,
		"10m 5x Match: survived full 600s Endless Wave without early defeat or timeout (%.1fs)" % game.elapsed)
	_check(formation_ok, "10m 5x Match: formation stayed inside corridor (%s)" % formation_fail_sample)
	_check(routes_ok and lanes_seen.size() == 3, "10m 5x Match: 3-lane bounds & monotonic enemy routes (%s)" % route_fail_sample)
	_check(boss_seen and boss_damaged and game.bosses_defeated >= 2,
		"10m 5x Match: multiple bosses spawned and were defeated (bosses=%d)" % game.bosses_defeated)
	_check(null_tex_count == 0, "10m 5x Match: zero sprites with null textures (%s)" % null_tex_sample)
	_check(max_nodes < 1200, "10m 5x Match: bounded scene node count without FX/projectile leak (max_nodes=%d)" % max_nodes)

	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = _original_ticks
	Engine.max_physics_steps_per_frame = _original_max_steps
	await create_timer(0.5, true, false, true).timeout
	quit(int(failed))


var _role_cursor := 0


func _shop_endless_10m() -> void:
	# Balanced mixed-role army: rotate across all 5 roles so Tanks, Healers, Mages, Archers, and Staff all deploy.
	var roles := ["tank", "healer", "mage", "archer", "staff"]
	var desired_army := mini(60, 12 + game.wave * 5)
	if game.army_count() < desired_army:
		var role: String = roles[_role_cursor % roles.size()]
		if game.can_summon(role):
			_click(ShopHud.summon_button_center(game.ROLE_ORDER.find(role)))
			_role_cursor += 1
			return
	if game.can_train():
		_click(ShopHud.train_button_center())


func _count_nodes(node: Node) -> int:
	var n := 1
	for c in node.get_children():
		n += _count_nodes(c)
	return n


func _find_null_texture(node: Node) -> String:
	if node is Sprite2D and node.visible and (node as Sprite2D).texture == null:
		return str(node.get_path())
	for c in node.get_children():
		var hit := _find_null_texture(c)
		if hit != "":
			return hit
	return ""


func _save_shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := _out_dir.path_join(label + ".png")
	var ok := image != null and image.save_png(path) == OK
	print("CAPTURE  %s (%s)" % [path, "OK" if ok else "FAIL"])
	_check(ok, "Captured live screenshot " + label)
