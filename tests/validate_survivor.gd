extends SceneTree
## Headless: Godot --headless --fixed-fps 60 --script tests/validate_survivor.gd
## GPU captures: Godot --fixed-fps 60 --resolution 1280x720 --script tests/validate_survivor.gd -- --capture

const Survivor := preload("res://scripts/survivor/match.gd")
const Formation := preload("res://scripts/survivor/army_formation.gd")
const ShopHud := preload("res://scripts/survivor/hud.gd")
const Scene := preload("res://scenes/monkey_army_survivor.tscn")

var game: Survivor
var capture := false
var failed := false
var peak_army := 0
var seen := {}
var shots := {}
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
	_check(game.state == game.State.MENU and not game.hero.visible, "Title hides the battlefield commander")
	_click(Vector2(640, 538))
	_check(game.state == game.State.RUNNING and game.hero.visible, "Start opens the battlefield")
	var at := game.hero.position
	_key(KEY_A)
	_key(KEY_RIGHT)
	await create_timer(0.30).timeout
	_check(game.hero.position == at and at == Vector2(640, game.COMMANDER_Y), "Commander stays at rear center")
	_click(Vector2(1231, 49))
	var frozen := game.elapsed
	await create_timer(0.20, true).timeout
	_check(game.state == game.State.PAUSED and paused and game.elapsed == frozen,
		"Manual pause freezes combat and shop purchases")
	_check(not game.summon("staff") and not game.train_army(), "Purchase endpoints refuse paused input")
	_click(Vector2(640, 362))
	_check(game.state == game.State.RUNNING and not paused, "Pause overlay resumes the match")
	var clear := true
	for prop: Array in game.field.PROPS:
		var half := float(prop[3]) * 0.5
		clear = clear and (float(prop[1]) + half <= game.field.PROTECTED.position.x
			or float(prop[1]) - half >= game.field.PROTECTED.end.x)
	_check(clear, "All scenery clears the combat corridor")
	_validate_semantic_plan()
	_validate_assets()
	_validate_summon_assets()
	var ground_tile := game.field._ground
	var height := float(ground_tile.material.get_shader_parameter("tile_pixels").y)
	var period := height * float(ground_tile.material.get_shader_parameter("tile_scale"))
	_check(ground_tile.polygon[0].y <= -period and ground_tile.polygon[2].y >= 720.0,
		"Recycled ground covers the viewport")

	game.start_game()
	game.set_physics_process(false)
	_validate_enemy_lanes()
	game.start_game()
	_validate_shop()
	_validate_combat_and_formation()
	game._damage(game.hero, 9999)
	_check(game.state == game.State.DEFEAT, "Zero Wukong HP opens Defeat")
	_click(Vector2(520, 457))
	_check(game.state == game.State.RUNNING and game.elapsed < 0.1 and game.gold == game.START_GOLD
		and game.training == 0 and game.level == 1 and game.army_count() == 0 and game.enemies.is_empty(),
		"Restart resets troops, training, wallet and waves")
	_validate_expanded_army()
	game.start_game()
	game.set_physics_process(true)
	await _play_full_run()


func _validate_shop() -> void:
	game.gold = 0
	game.hud.update_stats()
	_check(game.hud._role_buttons.staff.disabled and not game.summon("staff") and not game.summon("unknown"),
		"Unfunded and unknown purchases are rejected")
	game.gold = 250
	game.hud.update_stats()
	var paid := 0
	for i in game.ROLE_ORDER.size():
		var role: String = game.ROLE_ORDER[i]
		_click(ShopHud.summon_button_center(i))
		paid += game.ROLES[role].cost
	_check(game.army_count() == 5 and game.gold == 250 - paid and not paused,
		"All five role cards buy during combat at the listed prices")
	_check(not game.hud._role_buttons.staff.disabled, "Summon panel remains enabled at five troops")
	var staff := game.army[0]
	var previous_hp := staff.max_hp
	var trained_price := game.training_cost()
	_click(ShopHud.train_button_center())
	_check(staff.max_hp == previous_hp + 10 and game.training == 1 and game.gold == 250 - paid - trained_price,
		"Train button charges Gold and applies the live army upgrade")
	var slot_id := game.army[3].slot
	game._damage(game.army[3], 1000)
	game.summon("tank")
	_check(game.army[slot_id].max_hp == game.ROLES.tank.hp + 10 and game.army_count() == 5,
		"Replacements reuse vacant slots and inherit army training")
	game.gold = 150
	game.train_army()
	game.train_army()
	_check(game.training == game.MAX_TRAINING and not game.can_train(), "Training stops at the advertised cap")
	game.award(0, game.xp_needed())
	_check(game.level == 2 and game.state == game.State.RUNNING and not paused, "XP still levels up during combat")


func _validate_expanded_army() -> void:
	game.gold = 1000
	game.hud.update_stats()
	var clear := true
	for i in game.ARMY_CAP:
		_click(ShopHud.summon_button_center(game.ROLE_ORDER.find("staff")))
		clear = clear and game.army_count() == i + 1 and _formation_valid()
		# Continue summoning while the rank is still moving.
		for step in 12:
			game.elapsed += 1.0 / 60.0
			game._move_army(1.0 / 60.0)
			clear = clear and _formation_valid()
	for step in 90:
		game.elapsed += 1.0 / 60.0
		game._move_army(1.0 / 60.0)
		clear = clear and _formation_valid()
	var covered := {}
	for soldier in game.army:
		if is_instance_valid(soldier) and game.field.in_lane(soldier.position.x, soldier.assigned_lane):
			covered[soldier.assigned_lane] = true
	_check(clear and game.army_count() == 8 and covered.size() == 3,
		"Eight troops of the same role fit while summoning and redeploying across three lanes")
	var remaining := game.gold
	_check(game.hud._role_buttons.staff.disabled and not game.summon("staff") and game.gold == remaining,
		"Capacity blocks a ninth purchase without charging Gold")
	game._damage(game.army[1], 1000)
	_click(ShopHud.summon_button_center(game.ROLE_ORDER.find("staff")))
	_check(game.army[1] != null and game.army_count() == game.ARMY_CAP and _formation_valid(),
		"A full rank can replace a fallen troop while preserving spacing")


func _validate_combat_and_formation() -> void:
	var tank := game.army[3]
	var healer := game.army[4]
	var health := tank.hp
	game._damage(tank, 40)
	_check(tank.hp == health - 26, "Tank absorbs 35 percent of incoming damage")
	healer.position.x = tank.position.x
	game._attack(healer, 1.0)
	_check(tank.hp == health, "Healer repairs the injured tank and clamps at max HP")
	_check(_formation_valid(), "All troop types use their role rows and the shared body")
	var target := game._spawn_enemy("boar", 2)
	target.position.y = 236.0
	game._next_plan = 0.0
	var reinforced := false
	for i in 100:
		game.elapsed += 1.0 / 60.0
		game._move_army(1.0 / 60.0)
		reinforced = reinforced or tank.assigned_lane == 2 or game.army[0].assigned_lane == 2
		if not _formation_valid():
			_check(false, "Formation preserves clearance during redeployment")
			break
	_check(reinforced, "Frontline independently reinforces the threatened right lane")
	var archer := game.army[1]
	target.position = archer.position + Vector2(220.0, -90.0)
	var hp := target.hp
	game._attack(archer, 1.0)
	game._move_projectiles(1.0)
	_check(target.hp < hp, "Archer hits a target one lane-width away")
	var mage := game.army[2]
	target.position = mage.position + Vector2(-220, -60)
	var splash := game._spawn_enemy("slime", 0)
	splash.position = target.position + Vector2(-26, -35)
	game._attack(mage, 1.3)
	_check(splash.hp < splash.max_hp, "Mage hits an adjacent lane and splashes a second enemy")
	var staff := game.army[0]
	target.position = staff.position + Vector2(210.0, -65.0)
	splash.position = target.position + Vector2(0.0, -80.0)
	hp = target.hp
	game._attack(staff, 1.0)
	_check(target.hp == hp, "Staff does not hit beyond melee range")
	target.position = staff.position + Vector2(0.0, -85.0)
	game._attack(staff, 1.0)
	_check(target.hp < hp, "Staff hits a target in melee range")


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
		and game.gold == game.START_GOLD and game.xp == 0, "A regular rear-line breach costs HP without rewards")
	var boss := game._spawn_enemy("boss", 1)
	game.hero.position.x = 860.0
	boss.position.y = game.field.REAR_LINE_Y
	game._update_enemy(boss, allies, null, 0.016)
	var boss_wound_up := boss.windup > 0.0 and boss.strikes_rear_line
	hp = game.hero.hp
	game._update_enemy(boss, allies, null, 1.0)
	_check(boss_wound_up and boss.hp > 0 and game.hero.hp == hp - boss.attack_damage
		and boss.position.x == 640.0, "A boss at the rear line stays in lane and telegraphs its breach hits")


func _formation_valid() -> bool:
	if game.hero.position != Vector2(640, game.COMMANDER_Y):
		return false
	var occupied: Array[Rect2] = [Rect2(game.hero.position - Vector2(72, 105), Vector2(144, 117))]
	for slot in game.army.size():
		var monkey := game.army[slot]
		if monkey == null:
			continue
		if monkey.slot != slot or monkey.position.y != Formation.ROWS[monkey.formation_row]:
			return false
		var envelope := Rect2(monkey.position - Vector2(36, 78), Vector2(72, 86))
		if not game.field.PROTECTED.encloses(envelope):
			return false
		for other in occupied:
			if envelope.intersects(other):
				return false
		occupied.append(envelope)
	return true


func _play_full_run() -> void:
	var tick := 0.0
	var boss_seen := false
	while game.state == game.State.RUNNING and game.elapsed < 330.0:
		_formation_holds = _formation_holds and _formation_valid()
		_shop()
		peak_army = maxi(peak_army, game.army_count())
		for foe in game.enemies:
			_routes_hold = _routes_hold and game.field.in_lane(foe.position.x, foe.enemy_lane)
			boss_seen = boss_seen or foe.kind == "boss"
		if game.elapsed >= tick:
			print("RUN %.1fs | HP %d | Gold %d | level %d | troops %d | trained %d | kills %d | boss %s" % [
				game.elapsed, game.hero.hp, game.gold, game.level, game.army_count(), game.training, game.kills,
				str(game.boss.hp) if is_instance_valid(game.boss) else "–"])
			tick += 30.0
		if capture and game.elapsed > 50.0 and not shots.has("shop"):
			await _shot("shop")
		await process_frame
	_check(_formation_holds, "Formation stays spaced and Wukong stays in place throughout the match")
	_check(_routes_hold and boss_seen, "Enemy lane boundaries and boss scheduling remained intact")
	_check(game.state == game.State.VICTORY and game.elapsed >= 300.0,
		"Expanded formation can achieve Victory after the five-minute checkpoint")
	_check(peak_army == game.ARMY_CAP and game.training > 0 and game.kills > 20,
		"Natural economy supports the expanded army and training")
	print("MATCH %.2fs | %d kills | peak army %d | training %d" % [
		game.elapsed, game.kills, peak_army, game.training])
	if capture:
		await _shot("result")
	if game.state in [game.State.VICTORY, game.State.DEFEAT]:
		_click(Vector2(750, 455))
		_check(game.state == game.State.MENU, "Result Main Menu returns to title")
	quit(int(failed))


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


func _validate_summon_assets() -> void:
	var dir := "res://assets/survivor/summon/"
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "manifest.json"))
	var checked := 0
	for sheet: Dictionary in manifest.values():
		for frame: Dictionary in sheet.frames:
			var art := load(dir + frame.id + ".png") as Texture2D
			if art != null and art.get_size() == Vector2(frame.size[0], frame.size[1]):
				checked += 1
	_check(manifest.size() == 10 and checked == 104, "All 104 sprites from the ten summon sheets import at their recorded size")


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
	for role in ["staff", "archer", "tank", "mage", "healer"]:
		var present := false
		for soldier in game.army:
			present = present or (is_instance_valid(soldier) and soldier.role == role)
		if not present:
			if game.can_summon(role):
				_click(ShopHud.summon_button_center(game.ROLE_ORDER.find(role)))
			else:
				break
	if game.army_count() < game.ROLE_ORDER.size():
		return
	if game.can_train():
		_click(ShopHud.train_button_center())
	for role in ["staff", "archer", "tank"]:
		if game.can_summon(role):
			_click(ShopHud.summon_button_center(game.ROLE_ORDER.find(role)))


func _shot(name: String) -> void:
	shots[name] = true
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://docs/survivor/commander/%s.png" % name
	_check(image != null and image.save_png(path) == OK, "GPU capture: " + name)
