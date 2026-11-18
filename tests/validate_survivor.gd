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
const FORMATION_SHOTS := ["formation-left", "gameplay", "formation-right"]
var _seconds_logged := 0
var _clock := 0.0
var _enemy_routes := {}
var _routes_hold := true
var _formation_holds := true


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
	_check(game.state == game.State.MENU and not game.hero.visible,
		"Project opens at main menu with the battlefield commander hidden")
	_click(Vector2(640, 538))
	_check(game.state == game.State.RUNNING and game.hero.visible,
		"Start button starts the match and shows the commander through GUI input")
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

	_validate_enemy_lanes()
	game.start_game()
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
	var fallen := game.army[3]
	var previous_slot := fallen.position
	var survivor_id := game.army[4].get_instance_id()
	game._damage(fallen, 1000)
	_check(game.army_count() == 4 and game.buy_monkey() and game.army_count() == 5
		and game.army[3] != fallen and game.army[3].slot == 3
		and game.army[3].position == previous_slot and game.army[4].get_instance_id() == survivor_id
		and not fallen.visible,
		"Replacement fills the same vacant slot without moving survivors")
	game.resume()
	await _validate_formation_switches()

	var arrow_user := game.army[0]
	var magic_user := game.army[1]
	var cross := game._spawn_enemy("boar", 2)
	cross.position = Vector2(game.field.LANES[2], arrow_user.position.y)
	game._attack(arrow_user, 0.1)
	game._move_projectiles(0.5)
	_check(cross.hp < cross.max_hp, "Bow travels to and damages a target in the adjacent lane")
	cross.hurt(cross.hp)
	game.enemies.erase(cross)
	var magic_target := game._spawn_enemy("boar", 0)
	magic_target.position = Vector2(game.field.LANES[0], magic_user.position.y)
	var splash := game._spawn_enemy("boar", 0)
	splash.position = magic_target.position + Vector2(0, -100)
	game._attack(magic_user, 0.1)
	_check(magic_target.hp < magic_target.max_hp and splash.hp < splash.max_hp,
		"Magic targets the adjacent lane and damages a second enemy there")

	var melee := game.army[4]
	var durable := game._spawn_enemy("boar", 2)
	durable.position = Vector2(game.field.LANES[2], melee.position.y - 70)
	game.enemies.assign([durable])
	game._attack(melee, 0.1)
	_check(durable.hp == durable.max_hp, "Wooden Staff cannot reach a distant adjacent-lane target")
	var flank := game.army[2]
	durable.position.y = flank.position.y
	game._attack(flank, 0.1)
	_check(durable.hp < durable.max_hp, "Wooden Staff can hit across the lane boundary when in reach")
	durable.position = melee.position + Vector2(0, -55)
	var hp := durable.hp
	melee.weapon_id = ""
	game._attack(melee, 0.1)
	_check(durable.hp == hp, "Missing equipped weapon is safe")
	game._equip(melee, "staff")
	game._attack(melee, 0.1)
	_check(durable.hp < hp, "Wooden Staff attacks within melee range")
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


func _validate_enemy_lanes() -> void:
	var allies: Array[Survivor.Actor] = [game.hero]
	var centered := true
	var fixed_route := true
	for column in game.field.LANES.size():
		for kind in ["slime", "boar", "boss"]:
			var enemy := game._spawn_enemy(kind, column)
			var center: float = game.field.LANES[column]
			centered = centered and enemy.enemy_lane == column and enemy.position == Vector2(center, -8)
			# Tempt a chase by putting the only defender in the adjacent lane.
			game.hero.position = Vector2(game.field.LANES[(column + 1) % 3], 473.0)
			for step in 180:
				game._update_enemy(enemy, allies, null, 1.0 / 60.0)
				fixed_route = fixed_route and is_equal_approx(enemy.position.x, center)
			fixed_route = fixed_route and enemy.position.y > 225 and enemy.windup == 0.0
	_check(centered, "Slimes, boars and the boss spawn on each assigned lane center")
	_check(fixed_route, "Every enemy type advances down its own lane with an ally beside it in another lane")
	var leader := game._spawn_enemy("boar", 0)
	var follower := game._spawn_enemy("slime", 0)
	leader.position.y = 367.0
	follower.position.y = 292.0
	for step in 30:
		game._update_enemy(follower, allies, leader, 1.0 / 60.0)
	_check(absf(follower.position.x - game.field.LANES[0]) > 0.0
		and game.field.in_lane(follower.position.x, 0) and leader.position.y - follower.position.y >= 75.0,
		"Same-lane followers separate locally and queue behind the leader")

	# A windup begun in lane 0 cannot follow Wukong out of lane 0.
	game.hero.position = Vector2(420, 430)
	leader.position = Vector2(420, 350)
	var hp := game.hero.hp
	game._update_enemy(leader, allies, null, 0.016)
	var wound_up := leader.windup > 0.0
	game.hero.position.x = 531.0
	game._update_enemy(leader, allies, null, 0.5)
	_check(wound_up and game.hero.hp == hp, "A lane strike stays in its original lane")
	leader.position.y = game.field.REAR_LINE_Y
	game._update_enemy(leader, allies, null, 0.016)
	_check(leader.hp == 0 and game.hero.hp == hp - leader.attack_damage
		and game.gold == 0 and game.xp == 0, "A regular rear-line breach costs HP without rewards")
	var boss := game._spawn_enemy("boss", 1)
	game.hero.position.x = 860.0
	boss.position.y = game.field.REAR_LINE_Y
	game._update_enemy(boss, allies, null, 0.016)
	var boss_wound_up := boss.windup > 0.0 and boss.strikes_rear_line
	hp = game.hero.hp
	game._update_enemy(boss, allies, null, 1.0)
	_check(boss_wound_up and boss.hp > 0 and game.hero.hp == hp - boss.attack_damage
		and boss.position.x == 640.0, "A boss at the rear line stays in lane and telegraphs its breach hits")


func _validate_formation_switches() -> void:
	var valid := _formation_valid()
	var started_in_flight := false
	for command in [KEY_LEFT, KEY_RIGHT, KEY_RIGHT, KEY_LEFT]:
		var before := game.hero.position.x
		_key(command)
		for frame in 25:
			await physics_frame
			valid = valid and _formation_valid()
			if not is_equal_approx(game.hero.position.x, before) and (
					absf(game.hero.position.x - game.field.LANES[game.lane]) > 5.0):
				started_in_flight = true
		valid = valid and absf(game.hero.position.x - game.field.LANES[game.lane]) < 2.0
	_check(started_in_flight and valid,
		"All five slots follow commands together, stay in front and keep visual clearance at every sampled step")


func _formation_valid() -> bool:
	# Conservative envelopes include all supplied poses, held weapons and HP bars.
	var occupied: Array[Rect2] = [Rect2(game.hero.position - Vector2(70, 104), Vector2(140, 116))]
	for slot in game.army.size():
		var monkey := game.army[slot]
		if monkey == null:
			continue
		if monkey.slot != slot or monkey.position != game._formation_position(slot) or monkey.position.y >= game.hero.position.y:
			return false
		var envelope := Rect2(monkey.position - Vector2(36, 77), Vector2(72, 85))
		if not game.field.PROTECTED.encloses(envelope):
			return false
		for other in occupied:
			if envelope.intersects(other):
				return false
		occupied.append(envelope)
	return true


func _play_full_run() -> void:
	while game.state in [game.State.RUNNING, game.State.SHOP] and game.elapsed < 330.0:
		_control_army()
		_formation_holds = _formation_holds and _formation_valid()
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
				var id := foe.get_instance_id()
				var last: Vector2 = _enemy_routes.get(id, Vector2(foe.enemy_lane, foe.position.y))
				_routes_hold = _routes_hold and foe.enemy_lane == int(last.x) and foe.position.y >= last.y
				_routes_hold = _routes_hold and game.field.in_lane(foe.position.x, foe.enemy_lane)
				_enemy_routes[id] = Vector2(foe.enemy_lane, foe.position.y)
			if capture:
				var name: String = FORMATION_SHOTS[game.lane]
				var settled := absf(game.hero.position.x - game.field.LANES[game.lane]) < 2.0
				if game.elapsed > 95.0 and game.elapsed < game.BOSS_TIME and (
						settled and game.army_count() == 5 and not shots.has(name) and game.enemies.size() >= 3):
					await _shot(name)
				if is_instance_valid(game.boss) and game.boss.position.y >= 234 and game.boss.hp <= game.boss.max_hp * 0.87 and not shots.has("boss"):
					await _shot("boss")
		if int(game.elapsed) / 30 > _seconds_logged / 30:
			_seconds_logged = int(game.elapsed)
			print("RUN  %.1fs | HP %d | Gold %d | level %d | army %d | kills %d | boss %s" % [
				game.elapsed, game.hero.hp, game.gold, game.level, game.army_count(),
				game.kills, str(game.boss.hp) if is_instance_valid(game.boss) else "—"])
		await process_frame
	_check(_routes_hold, "All scheduled enemies retained their lane and never moved upward in the full match")
	_check(_formation_holds, "Live formation stayed in front of Wukong and collision-free throughout the full match")
	_check(seen.has("slime") and seen.has("boar") and seen.has("boss"), "Scheduled waves spawned slime, boar and Boar King")
	_check(game.kills > 25 and shops > 3 and spent > 0 and peak_army >= 3,
		"Natural match progressed through kills, level-up shops, Gold purchases and army growth")
	_check(game.state == game.State.VICTORY and game.elapsed >= game.BOSS_TIME and game.elapsed <= 315.0,
		"Full match reaches Victory through the scheduled Boar King encounter")
	print("MATCH %.2fs | %d kills | %d shops | peak army %d | %d Gold spent" % [
		game.elapsed, game.kills, shops, peak_army, spent])
	if capture and game.state == game.State.VICTORY:
		await _shot("victory")
		_check(FORMATION_SHOTS.all(func(name): return shots.has(name)) and shots.has("shop") and shots.has("boss"),
			"Formation in all three lanes, shop and boss PNGs were captured")
	if game.state in [game.State.VICTORY, game.State.DEFEAT]:
		_click(Vector2(750, 455))
		await process_frame
		_check(game.state == game.State.MENU, "Result Main Menu returns to title")
	if not capture:
		if game.state != game.State.MENU:
			game.main_menu()
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


func _control_army(step := -1.0) -> void:
	if game.state != game.State.RUNNING:
		return
	_clock += Engine.time_scale / 60.0 if step < 0.0 else step
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
	var desired: int = target.enemy_lane
	if is_instance_valid(game.boss) and game.boss.windup > 0.0 and not game.boss.strikes_rear_line:
		if game.lane == game.boss.enemy_lane:
			desired = 0 if game.boss.strike_position.x >= game.field.LANES[1] else 2
		else:
			desired = game.lane
	if target.position.y > game.hero.position.y and target != game.boss:
		desired = game.lane
	if desired != game.lane:
		_key(KEY_LEFT if desired < game.lane else KEY_RIGHT)


func _shot(name: String) -> void:
	shots[name] = true
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://docs/survivor/%s.png" % name
	_check(image != null and image.save_png(path) == OK, "GPU capture: " + name)
