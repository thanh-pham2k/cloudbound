extends "res://tests/validate_survivor.gd"
## Visible, real-time QA. Run without --headless or --fixed-fps.

const SPEED := 5.0
const MIN_DURATION := 300.0
const WATCHDOG_SECONDS := 330.0
const SAMPLE_RATE := 15.0

var _output := "res://docs/survivor/commander/live"
var _frames_dir := ""
var _requested: Array[String] = []
var _wall_ms := 0
var _next_log := 30
var _next_shot := 60
var _video_frame := 0
var _video_ok := true
var _gold_before := 0
var _total_xp_before := 0
var _kills_before := 0
var _known_enemies := {}
var _economy_ok := true
var _shop_ok := true
var _recruits := 0
var _replacements := 0
var _upgrades := 0
var _roles_seen := {}
var _transactions := 0
var _occupied_slots := {}
var _defended := {}
var _enemy_lanes := {}
var _last_orders := {}
var _order_cadence_ok := true
var _boss_seen := false
var _boss_damaged := false
var _original_ticks: int
var _original_max_steps: int


func _run() -> void:
	if DisplayServer.get_name() == "headless" or "--fixed-fps" in OS.get_cmdline_args() or "--write-movie" in OS.get_cmdline_args():
		printerr("Launch this runner in a visible window with Godot's real-time clock.")
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
		elif arg.begins_with("--frames="):
			_frames_dir = arg.trim_prefix("--frames=")
	for dir in [_output, _frames_dir]:
		if not dir.is_empty() and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir)) != OK:
			printerr("Unable to create capture directory " + dir)
			quit(1)
			return

	root.title = "Hoa Qua Son — Live QA (5×)"
	root.grab_focus()
	game = Scene.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	_click(Vector2(640, 538))
	_check(game.state == game.State.RUNNING, "Start Game opens the live battlefield")
	if failed:
		quit(1)
		return
	_requested.append("000s")
	await RenderingServer.frame_post_draw
	_capture_frame()

	_original_ticks = Engine.physics_ticks_per_second
	_original_max_steps = Engine.max_physics_steps_per_frame
	Engine.physics_ticks_per_second = int(_original_ticks * SPEED)
	Engine.max_physics_steps_per_frame = maxi(_original_max_steps, 30)
	Engine.time_scale = SPEED
	_wall_ms = Time.get_ticks_msec()
	RenderingServer.frame_post_draw.connect(_capture_frame)
	_gold_before = game.gold
	_print_state(0)
	print("LIVE  %.1f× | %s | %d physics ticks/s | %.5f simulated seconds/tick" % [
		Engine.time_scale, DisplayServer.get_name(), Engine.physics_ticks_per_second,
		Engine.time_scale / Engine.physics_ticks_per_second])
	game.set_physics_process(true)

	while game.state in [game.State.RUNNING, game.State.PAUSED] and (
			game.elapsed < WATCHDOG_SECONDS and Time.get_ticks_msec() - _wall_ms < 90000):
		await physics_frame
		_observe_step()
		if game.state == game.State.PAUSED:
			game.resume()
		if game.state == game.State.RUNNING:
			_handle_shop()

	var wall := float(Time.get_ticks_msec() - _wall_ms) / 1000.0
	var resolved := game.state in [game.State.VICTORY, game.State.DEFEAT]
	if resolved:
		_requested.append("result")
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = _original_ticks
	Engine.max_physics_steps_per_frame = _original_max_steps
	root.title = "Hoa Qua Son — Live QA Result"
	_print_state(int(game.elapsed))
	print("RESULT  %s | game=%.3fs | wall=%.3fs | effective=%.3fx | kills=%d | transactions=%d | recruits=%d | replacements=%d | upgrades=%d" % [
		game.State.keys()[game.state], game.elapsed, wall, game.elapsed / wall,
		game.kills, _transactions, _recruits, _replacements, _upgrades])
	_check(game.state == game.State.VICTORY and game.elapsed >= MIN_DURATION, "Reached 300 seconds and earned Victory")
	_check(_defended.size() == 3 and _formation_holds and peak_army == game.ARMY_CAP and _order_cadence_ok,
		"Smart AI covered all lanes with clear spacing, rate-limited orders and a fixed commander")
	_check(_routes_hold and seen.size() == 3 and _enemy_lanes.size() == 3,
		"Scheduled slimes, boars and boss spawned across three lanes and kept their routes")
	_check(_boss_seen and _boss_damaged and resolved, "Boss appeared, took damage and the fight resolved")
	_check(_economy_ok and game.kills > 0 and game.level > 1, "Gold and XP match killed enemies and level thresholds")
	_check(_shop_ok and _roles_seen.size() == 5 and _upgrades == game.MAX_TRAINING,
		"Bottom shop charges exact prices for all five roles and all training tiers")
	_check(Engine.time_scale == 1.0, "Engine.time_scale restored to 1.0")
	await create_timer(2.0, true, false, true).timeout
	RenderingServer.frame_post_draw.disconnect(_capture_frame)
	for name in ["000s", "060s", "120s", "180s", "240s", "300s", "summon", "upgrade", "boss", "result"]:
		_check(shots.has(name), "Saved rendered screenshot " + name)
	if not _frames_dir.is_empty():
		_check(_video_ok and _video_frame > 0, "Recorded %d frames of the live window at %.0f FPS" % [
			_video_frame, SAMPLE_RATE])
	quit(int(failed))


func _observe_step() -> void:
	for unit in game.army:
		if not is_instance_valid(unit):
			continue
		if unit.assigned_lane >= 0 and game.field.in_lane(unit.position.x, unit.assigned_lane):
			_defended[unit.assigned_lane] = true
		var troop_id := unit.get_instance_id()
		var last: Array = _last_orders.get(troop_id, [unit.assigned_lane, -INF])
		if unit.assigned_lane != last[0]:
			_order_cadence_ok = _order_cadence_ok and game.elapsed - last[1] >= Formation.REVIEW_SECONDS - 0.02
			last = [unit.assigned_lane, game.elapsed]
		_last_orders[troop_id] = last
	_formation_holds = _formation_holds and _formation_valid()
	var active := {}
	for foe in game.enemies:
		var id := foe.get_instance_id()
		seen[foe.kind] = true
		_enemy_lanes[foe.enemy_lane] = true
		if _known_enemies.has(id):
			var previous: Array = _known_enemies[id]
			_routes_hold = _routes_hold and foe.enemy_lane == previous[0] and foe.position.y >= previous[1]
		else:
			_routes_hold = _routes_hold and foe.position.y <= -5.0
		_routes_hold = _routes_hold and game.field.in_lane(foe.position.x, foe.enemy_lane)
		active[id] = [foe.enemy_lane, foe.position.y, foe.gold_reward, foe.xp_reward, foe.kind]
	_validate_rewards(active)
	_known_enemies = active

	if is_instance_valid(game.boss):
		_boss_seen = true
		if not _boss_damaged and game.boss.hp < game.boss.max_hp:
			_boss_damaged = true
			_requested.append("boss")
	while game.elapsed >= float(_next_log) and _next_log <= MIN_DURATION:
		_print_state(_next_log)
		_next_log += 30
	while game.elapsed >= float(_next_shot) and _next_shot <= MIN_DURATION:
		_requested.append("%03ds" % _next_shot)
		_next_shot += 60


func _validate_rewards(active: Dictionary) -> void:
	var expected := Vector3i.ZERO
	var at_rear: Array[Vector3i] = []
	for id in _known_enemies:
		if active.has(id):
			continue
		var previous: Array = _known_enemies[id]
		var reward := Vector3i(1, previous[2], previous[3])
		if previous[1] >= game.field.REAR_LINE_Y and previous[4] != "boss":
			at_rear.append(reward)
		else:
			expected += reward
	var total_xp := game.xp
	for past_level in range(1, game.level):
		total_xp += 17 + past_level * 12
	var actual := Vector3i(game.kills - _kills_before, game.gold - _gold_before, total_xp - _total_xp_before)
	# A unit touching the rear line can be killed by combat or retire as a breach.
	var possible := {expected: true}
	for reward in at_rear:
		for sum_before: Vector3i in possible.keys():
			possible[sum_before + reward] = true
	if not possible.has(actual) and _economy_ok:
		print("ECONOMY MISMATCH  t=%.3f expected=%s actual=%s" % [game.elapsed, possible.keys(), actual])
		_economy_ok = false
	_kills_before = game.kills
	_gold_before = game.gold
	_total_xp_before = total_xp


func _handle_shop() -> void:
	var before_gold := game.gold
	var before_training := game.training
	var before_slots := game.army.duplicate()
	_shop()
	var recruited := 0
	var expected := 0
	if game.training > before_training:
		expected += 32 + 26 * before_training
		_upgrades += 1
		if _upgrades == 1:
			_requested.append("upgrade")
	for slot in game.army.size():
		var soldier := game.army[slot]
		if soldier == null or soldier == before_slots[slot]:
			continue
		expected += game.ROLES[soldier.role].cost
		_roles_seen[soldier.role] = true
		recruited += 1
		_replacements += int(_occupied_slots.has(slot))
		_occupied_slots[slot] = true
	if expected == 0:
		return
	_recruits += recruited
	if _recruits == recruited:
		_requested.append("summon")
	_transactions += 1
	peak_army = maxi(peak_army, game.army_count())
	_shop_ok = _shop_ok and before_gold - game.gold == expected and _formation_valid() and not paused
	_gold_before = game.gold
	print("SHOP  %.3fs | gold=%d→%d | summoned=%d | training=%d | army=%d" % [
		game.elapsed, before_gold, game.gold, recruited, game.training, game.army_count()])


func _print_state(mark: int) -> void:
	print("STATE %03ds | game=%.3fs | HP=%d/%d | Gold=%d | XP=%d/%d | Level=%d | Monkeys=%d/%d | Training=%d | Kills=%d | Boss=%s" % [
		mark, game.elapsed, game.hero.hp, game.hero.max_hp, game.gold, game.xp, game.xp_needed(),
		game.level, game.army_count(), game.ARMY_CAP, game.training, game.kills,
		str(game.boss.hp) if is_instance_valid(game.boss) else "—"])


func _capture_frame() -> void:
	var due := _video_frame
	if not _frames_dir.is_empty() and _wall_ms > 0:
		due = 1 + int((Time.get_ticks_msec() - _wall_ms) * SAMPLE_RATE / 1000.0)
	if _requested.is_empty() and due <= _video_frame:
		return
	var image := root.get_texture().get_image()
	if image == null:
		return
	for name in _requested:
		var path := _output.path_join(name + ".png")
		if image.save_png(path) == OK:
			shots[name] = true
			print("CAPTURE  %s at %.3fs" % [path, game.elapsed])
	_requested.clear()
	if due > _video_frame:
		image.resize(854, 480, Image.INTERPOLATE_BILINEAR)
		var bytes := image.save_jpg_to_buffer(0.80)
		while _video_frame < due:
			var path := _frames_dir.path_join("%05d.jpg" % _video_frame)
			var frame := FileAccess.open(path, FileAccess.WRITE)
			_video_ok = _video_ok and frame != null
			if frame != null:
				frame.store_buffer(bytes)
			_video_frame += 1
