extends SceneTree
## Headless: Godot --headless --fixed-fps 60 --script tests/validate_survivor.gd
## GPU captures: Godot --fixed-fps 60 --resolution 1280x720 --script tests/validate_survivor.gd -- --capture

const Survivor := preload("res://scripts/survivor/match.gd")
const Scene := preload("res://scenes/monkey_army_survivor.tscn")

var game: Survivor
var capture := false
var failed := false
var shops := 0
var spent := 0
var peak_army := 0
var seen := {}
var shots := {}
var _seconds_logged := 0
var _clock := 0.0


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	_run.call_deferred()


func _check(ok: bool, description: String) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", description])
	failed = failed or not ok


func _key(code: int) -> void:
	var key := InputEventKey.new()
	key.keycode = code
	key.physical_keycode = code
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()


func _click(at: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = down
		root.push_input(event, true)


func _run() -> void:
	game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	_check(game.state == game.State.MENU, "Project opens at main menu")
	_click(Vector2(640, 538))
	_check(game.state == game.State.RUNNING, "Start button starts the match through GUI input")
	if game.state != game.State.RUNNING:
		quit(1)
		return
	_check(game.lane == 1 and game.hero.position.x == 640.0, "Wukong starts in center lane")
	_key(KEY_LEFT)
	await process_frame
	_check(game.lane == 0, "Left arrow selects left lane")
	await create_timer(0.30).timeout
	_check(game.hero.position.x > 420.0 and game.hero.position.x < 428.0, "Lane movement interpolates to left lane")
	_key(KEY_D)
	await process_frame
	_check(game.lane == 1, "D selects the center lane")
	_key(KEY_RIGHT)
	await process_frame
	_check(game.lane == 2, "Right arrow selects right lane")
	_key(KEY_RIGHT)
	await process_frame
	_check(game.lane == 2, "Right boundary clamps lane index")
	_key(KEY_A)
	await process_frame
	_check(game.lane == 1, "A selects the center lane")
	_click(Vector2(1231, 49))
	await process_frame
	_check(game.state == game.State.PAUSED and paused, "HUD pause button pauses the SceneTree")
	var frozen := game.elapsed
	var ground := game.field.distance
	await create_timer(0.2, true).timeout
	_check(game.elapsed == frozen and game.field.distance == ground, "Pause freezes match and scrolling")
	_click(Vector2(640, 362))
	await process_frame
	_check(game.state == game.State.RUNNING and not paused, "Pause screen Resume restores gameplay")
	_check(game.field.PROTECTED.encloses(Rect2(394, 0, 492, 720)), "All three lanes fit in the protected corridor")
	var clear := true
	for prop: Array in game.field.PROPS:
		var half := float(prop[3]) * 0.5
		clear = clear and (float(prop[1]) + half <= game.field.PROTECTED.position.x
			or float(prop[1]) - half >= game.field.PROTECTED.end.x)
	_check(clear, "Every tree, rock and prop envelope clears the combat corridor")
	_validate_semantic_plan()
	_validate_assets()
	var ground_tile := game.field._ground
	var height := float(ground_tile.material.get_shader_parameter("tile_pixels").y)
	var period := height * float(ground_tile.material.get_shader_parameter("tile_scale"))
	_check(ground_tile.polygon[0].y <= -period and ground_tile.polygon[2].y >= 720.0,
		"Terrain polygon covers the viewport across the entire recycling period")

	game._enter(game.State.SHOP)
	_check(not game.buy_monkey() and game.gold == 0, "Recruit blocks insufficient Gold")
	_check(not game.buy_weapon(0, "bow"), "Weapon purchase blocks an empty slot")
	game.gold = 250
	game.hud.show_shop()
	_click(Vector2(308, 503))
	var all_bought := game.army_count() == 1
	for i in 4:
		all_bought = game.buy_monkey() and all_bought
	_check(all_bought and game.army_count() == 5 and game.gold == 155, "Five recruits charge exactly 19 Gold each")
	_check(not game.buy_monkey() and game.gold == 155, "Full army blocks a sixth recruit without charging")
	_check(not game.buy_weapon(0, "missing") and not game.buy_weapon(0, "staff")
		and not game.buy_weapon(-1, "bow"), "Unknown weapon, equipped weapon and invalid slot are rejected")
	_click(Vector2(437, 256))
	_click(Vector2(750, 503))
	_click(Vector2(570, 256))
	_click(Vector2(971, 503))
	_check(game.army[0].weapon_id == "bow" and game.army[1].weapon_id == "magic" and game.gold == 116,
		"Shop slot selection and weapon buttons equip correctly and charge exact costs")
	game.gold = 0
	_check(not game.buy_weapon(0, "magic") and game.army[0].weapon_id == "bow", "Unaffordable weapon preserves equipped item")
	game.gold = 116
	game._damage(game.army[3], 1000)
	_check(game.army_count() == 4 and game.buy_monkey() and game.army_count() == 5,
		"Fallen monkey frees its slot for replacement")
	game.resume()

	var arrow_user := game.army[0]
	var magic_user := game.army[1]
	var x := arrow_user.position.x
	var cross := game._spawn_enemy("boar", 1)
	cross.position = Vector2(x + 220, arrow_user.position.y)
	game._attack(arrow_user, 0.1)
	game._move_projectiles(0.5)
	_check(cross.hp < cross.max_hp, "Bow travels to and damages a target a lane-width away")
	cross.position = magic_user.position + Vector2(185, -40)
	var splash := game._spawn_enemy("boar", 1)
	splash.position = cross.position + Vector2(90, 0)
	game._attack(magic_user, 0.1)
	_check(splash.hp < splash.max_hp, "Magic damages a second nearby enemy")
	var melee := game.army[2]
	var durable := game._spawn_enemy("boar", 1)
	durable.position = melee.position + Vector2(-220, 0)
	game.enemies.assign([durable])
	game._attack(melee, 0.1)
	_check(durable.hp == durable.max_hp, "Wooden Staff cannot reach a target a lane-width away")
	durable.position = melee.position + Vector2(-55, 0)
	melee.weapon_id = ""
	game._attack(melee, 0.1)
	_check(durable.hp == durable.max_hp, "Missing equipped weapon is safe")
	game._equip(melee, "staff")
	game._attack(melee, 0.1)
	_check(durable.hp < durable.max_hp, "Wooden Staff attacks within melee range")
	game._damage(game.hero, 9999)
	_check(game.state == game.State.DEFEAT, "Zero Wukong HP opens Defeat")
	_click(Vector2(520, 457))
	await process_frame
	_check(game.state == game.State.RUNNING and game.elapsed < 0.1 and game.gold == 0
		and game.level == 1 and game.army_count() == 0 and game.enemies.is_empty()
		and game.hero.hp == game.hero.max_hp and game.lane == 1,
		"Result Restart resets health, inventory, time, lane and waves")
	if capture:
		Engine.time_scale = 4.0
	await _play_full_run()


func _play_full_run() -> void:
	while game.state in [game.State.RUNNING, game.State.SHOP] and game.elapsed < 330.0:
		_control_army()
		if game.state == game.State.SHOP:
			shops += 1
			var coins := game.gold
			if shops == 1:
				_check(paused and game.level > 1 and coins > 0 and game.elapsed > 0.0,
					"Real enemy deaths reward XP and Gold and automatically open a paused shop")
			if capture and game.army_count() > 0 and game.can_recruit() and not shots.has("shop"):
				await _shot("shop")
			_shop()
			spent += coins - game.gold
			peak_army = maxi(peak_army, game.army_count())
			_click(Vector2(965, 580))
			if game.state != game.State.RUNNING:
				_check(false, "Shop Continue resumes play")
				quit(1)
				return
		if game.state == game.State.RUNNING:
			for foe in game.enemies:
				seen[foe.kind] = true
			if capture:
				if game.elapsed > 119.0 and not shots.has("gameplay") and game.enemies.size() >= 3 and game.enemies[0].position.y > 285.0:
					await _shot("gameplay")
				if is_instance_valid(game.boss) and game.boss.position.y >= 234 and game.boss.hp <= game.boss.max_hp * 0.87 and not shots.has("boss"):
					await _shot("boss")
		if int(game.elapsed) / 30 > _seconds_logged / 30:
			_seconds_logged = int(game.elapsed)
			print("RUN  %.1fs | HP %d | Gold %d | level %d | army %d | kills %d | boss %s" % [
				game.elapsed, game.hero.hp, game.gold, game.level, game.army_count(),
				game.kills, str(game.boss.hp) if is_instance_valid(game.boss) else "—"])
		await process_frame
	_check(seen.has("slime") and seen.has("boar") and seen.has("boss"), "Scheduled waves spawned slime, boar and Boar King")
	_check(game.kills > 25 and shops > 3 and spent > 0 and peak_army >= 3,
		"Natural match progressed through kills, level-up shops, Gold purchases and army growth")
	_check(game.state == game.State.VICTORY and game.elapsed >= game.BOSS_TIME and game.elapsed <= 330.0,
		"Full match reaches Victory through the scheduled Boar King encounter")
	print("MATCH %.2fs | %d kills | %d shops | peak army %d | %d Gold spent" % [
		game.elapsed, game.kills, shops, peak_army, spent])
	if capture and game.state == game.State.VICTORY:
		await _shot("victory")
		_check(shots.has("gameplay") and shots.has("shop") and shots.has("boss"),
			"Gameplay, shop and boss PNGs were captured")
	if game.state in [game.State.VICTORY, game.State.DEFEAT]:
		_click(Vector2(750, 455))
		await process_frame
		_check(game.state == game.State.MENU, "Result Main Menu returns to title")
	if not capture:
		await _play_idle_run()
	quit(int(failed))


func _play_idle_run() -> void:
	_click(Vector2(640, 538))
	var hit := false
	while game.state in [game.State.RUNNING, game.State.SHOP] and game.elapsed < 330.0:
		if game.state == game.State.SHOP:
			_click(Vector2(965, 580))
		hit = hit or game.hero.hp < game.hero.max_hp
		await process_frame
	_check(hit and game.state == game.State.DEFEAT and game.army_count() == 0,
		"Scheduled enemies deal damage and can defeat a stationary player who skips purchases")
	print("IDLE %.2fs | %s" % [game.elapsed, game.State.keys()[game.state]])


func _validate_assets() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/survivor/manifest.json"))
	var checked := 0
	for sheet: Dictionary in manifest.values():
		for frame: Dictionary in sheet.frames:
			var art := load("res://assets/survivor/%s.png" % frame.name) as Texture2D
			var rect: Array = frame.source_rect
			if art != null and art.get_width() == rect[2] and art.get_height() == rect[3]:
				checked += 1
	_check(manifest.size() == 15 and checked == 141, "All 141 extracted cells import at their recorded native sizes")


func _validate_semantic_plan() -> void:
	var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/blueprints/semantic_palette.json"))
	var palette := {}
	for entry: Dictionary in registry.classes:
		palette[entry.name] = Color(entry.hex)
	var image := Image.create(1280, int(game.field.PROP_PERIOD), false, Image.FORMAT_RGB8)
	image.fill(palette.grass)
	var corridor := Rect2i(int(game.field.PROTECTED.position.x), 0,
		int(game.field.PROTECTED.size.x), image.get_height())
	image.fill_rect(corridor, palette.path)
	var valid := true
	for prop: Array in game.field.PROPS:
		var id: String = prop[0]
		var semantic_class := ""
		if id.begins_with("peach"):
			semantic_class = "tree_peach"
		elif id.begins_with("green"):
			semantic_class = "tree_green"
		elif id == "rock":
			semantic_class = "rock"
		if semantic_class.is_empty():
			continue
		var center := Vector2i(prop[1], prop[2])
		var radius := 15 if id == "rock" else 12
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if x * x + y * y <= radius * radius:
					var point := center + Vector2i(x, y)
					valid = valid and not corridor.has_point(point) and image.get_pixelv(point) == palette.grass
					image.set_pixelv(point, palette[semantic_class])
	_check(valid, "Canonical semantic plan has isolated edge footprints and a continuous combat corridor")
	if capture:
		_check(image.save_png("res://docs/survivor/semantic-plan.png") == OK, "Exported canonical semantic plan")


func _shop() -> void:
	while game.can_recruit() and (game.army_count() < 2 or game.gold >= 28 or game.elapsed > 245.0):
		game.buy_monkey()
	for i in game.army.size():
		if game.army[i] != null and game.army[i].weapon_id == "staff":
			var preferred := "magic" if i % 2 == 1 else "bow"
			game.buy_weapon(i, preferred)


func _control_army() -> void:
	if game.state != game.State.RUNNING:
		return
	_clock += Engine.time_scale / 60.0
	if _clock < 0.12:
		return
	_clock = 0.0
	var target = game.boss
	if not is_instance_valid(target):
		var best := INF
		for foe in game.enemies:
			var score: float = absf(foe.position.y - game.hero.position.y) + absf(foe.position.x - game.hero.position.x) * 0.36
			if score < best:
				best = score
				target = foe
	if not is_instance_valid(target) or target.position.y < 136.0:
		return
	var desired := game.lane
	var best_score := INF
	for i in 3:
		var at := Vector2(game.field.LANES[i], game.hero.position.y)
		var score: float = absf(at.x - target.position.x) + absf(game.lane - i) * 40.0
		for foe in game.enemies:
			if foe.windup > 0.0 and at.distance_to(foe.strike_position) < game._strike_radius(foe) + 17.0:
				score += 360.0
		if score < best_score:
			best_score = score
			desired = i
	if desired != game.lane:
		_key(KEY_LEFT if desired < game.lane else KEY_RIGHT)


func _shot(name: String) -> void:
	shots[name] = true
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://docs/survivor/%s.png" % name
	_check(image != null and image.save_png(path) == OK, "GPU capture: " + name)
