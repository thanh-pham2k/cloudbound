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
	_validate_combat_assets()
	_validate_vfx_pack_assets()
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
	# At Level 1, only Staff is unlocked; Mage and Healer must remain level-locked even with Gold.
	game.gold = 250
	game.hud.update_stats()
	_check(game.is_role_unlocked("staff") and not game.is_role_unlocked("mage") and not game.is_role_unlocked("healer")
		and not game.summon("mage") and not game.summon("healer"),
		"Higher-tier roles (Mage, Healer) stay locked until their required Commander level")
	# Level up to Lv 9 so all five roles unlock.
	game.level = 9
	game.hud.update_stats()
	var paid := 0
	for i in game.ROLE_ORDER.size():
		var role: String = game.ROLE_ORDER[i]
		var price: int = game.summon_cost(role)
		_click(ShopHud.summon_button_center(i))
		paid += price
	_check(game.army_count() == 5 and game.gold == 250 - paid and not paused,
		"All five role cards buy during combat once unlocked at their listed prices")
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
	# Dynamic summon pricing scales up above 5 active troops.
	game.gold = 1000
	game.hud.update_stats()
	var cost_at_5: int = game.summon_cost("staff")
	game.summon("staff")
	var cost_at_6: int = game.summon_cost("staff")
	_check(cost_at_6 > cost_at_5, "Summon cost scales dynamically above 5 troops (%d -> %d)" % [cost_at_5, cost_at_6])
	game._damage(game.army[5], 1000)
	_check(game.summon_cost("staff") == cost_at_5, "Summon cost drops back when troops fall")
	game.gold = 900
	game.train_army()
	game.train_army()
	game.train_army()
	_check(game.training == 4 and game.can_train(), "Training scales without an upper cap when funded")
	var prev_lvl := game.level
	game.award(0, game.xp_needed())
	_check(game.level == prev_lvl + 1 and game.state == game.State.RUNNING and not paused, "XP still levels up during combat")


func _validate_expanded_army() -> void:
	game.gold = 4000
	game.hud.update_stats()
	var clear := true
	for i in 12:
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
	_check(clear and game.army_count() == 12 and covered.size() == 3,
		"Unlimited summoning fits 12+ troops of the same role inside the corridor across three lanes")
	game._damage(game.army[1], 1000)
	_click(ShopHud.summon_button_center(game.ROLE_ORDER.find("staff")))
	_check(game.army[1] != null and game.army_count() == 12 and _formation_valid(),
		"A fallen troop slot is cleanly reused while preserving corridor bounds")


func _validate_combat_and_formation() -> void:
	var tank := game.army[3]
	var healer := game.army[4]
	var health := tank.hp
	game._damage(tank, 40)
	_check(tank.hp == health - 26, "Tank absorbs 35 percent of incoming damage")
	healer.position.x = tank.position.x
	game._attack(healer, 1.0)
	var healed_early := tank.hp != health - 26
	game._attack(healer, 0.25)
	_check(not healed_early and tank.hp == health, "Healer winds up then repairs the injured tank at impact frame")
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
	var arrow_early := not game._projectiles.is_empty()
	game._attack(archer, 0.20)
	var arrow_released := not game._projectiles.is_empty()
	game._move_projectiles(1.0)
	_check(not arrow_early and arrow_released and target.hp < hp,
		"Archer winds up, releases arrow at strike frame, and hits a target one lane-width away")
	var mage := game.army[2]
	target.position = mage.position + Vector2(-220, -60)
	var splash := game._spawn_enemy("slime", 0)
	splash.position = target.position + Vector2(-26, -35)
	game._attack(mage, 1.3)
	var mage_early := splash.hp < splash.max_hp
	game._attack(mage, 0.25)
	game._move_projectiles(1.0)
	_check(not mage_early and splash.hp < splash.max_hp,
		"Mage winds up, fires arcane orb on strike frame, and splashes a second enemy on arrival")
	var staff := game.army[0]
	target.position = staff.position + Vector2(210.0, -65.0)
	splash.position = target.position + Vector2(0.0, -80.0)
	hp = target.hp
	game._attack(staff, 1.0)
	game._attack(staff, 0.20)
	_check(target.hp == hp, "Staff does not hit beyond melee range")
	target.position = staff.position + Vector2(0.0, -85.0)
	game._attack(staff, 1.0)
	var staff_early := target.hp < hp
	game._attack(staff, 0.20)
	_check(not staff_early and target.hp < hp, "Staff winds up and deals damage on melee impact frame")


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
	follower.position.y = 329.0
	for step in 30:
		game._update_enemy(follower, allies, leader, 1.0 / 60.0)
	_check(absf(follower.position.x - game.field.LANES[0]) > 0.0
		and game.field.in_lane(follower.position.x, 0) and leader.position.y - follower.position.y >= 38.0,
		"Same-lane pack followers fan out horizontally to attack in groups")

	# A windup begun in lane 0 cannot follow Wukong out of lane 0.
	game.hero.position = Vector2(420, 430)
	leader.position = Vector2(420, 376)
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
	var crowded := game.army_count() > Formation.SOCKETS.size()
	var occupied: Array[Rect2] = [Rect2(game.hero.position - Vector2(72, 82), Vector2(144, 94))]
	for slot in game.army.size():
		var monkey := game.army[slot]
		if monkey == null:
			continue
		if monkey.slot != slot or absf(monkey.position.y - Formation.ROWS[monkey.formation_row]) > 20.0:
			return false
		var envelope := Rect2(monkey.position - Vector2(36, 62), Vector2(72, 68))
		if not game.field.PROTECTED.encloses(envelope):
			return false
		if not crowded:
			for other in occupied:
				if envelope.intersects(other):
					return false
			occupied.append(envelope)
	return true


func _play_full_run() -> void:
	var tick := 0.0
	var boss_seen := false
	while game.state == game.State.RUNNING and game.elapsed < 260.0:
		_formation_holds = _formation_holds and _formation_valid()
		_shop()
		peak_army = maxi(peak_army, game.army_count())
		for foe in game.enemies:
			_routes_hold = _routes_hold and game.field.in_lane(foe.position.x, foe.enemy_lane)
			boss_seen = boss_seen or foe.kind == "boss"
		if game.elapsed >= tick:
			print("RUN %.1fs | Wave %d | HP %d | Gold %d | level %d | troops %d | trained %d | kills %d | bosses %d" % [
				game.elapsed, game.wave, game.hero.hp, game.gold, game.level, game.army_count(), game.training, game.kills,
				game.bosses_defeated])
			tick += 45.0
		if capture and game.elapsed > 50.0 and not shots.has("shop"):
			await _shot("shop")
		await process_frame
	_check(_formation_holds, "Formation stays inside corridor and Wukong stays in place throughout Endless Waves")
	_check(_routes_hold and boss_seen, "Enemy lane boundaries and Wave 5 Boss scheduling remained intact")
	_check(game.state == game.State.RUNNING and game.wave >= 6 and game.bosses_defeated >= 1,
		"Endless Wave continues past Wave 5 Boss into Wave 6+")
	_check(peak_army > 8 and game.training > 0 and game.kills > 20,
		"Natural economy supports unlimited summoning (>8 monkeys) and training")
	print("ENDLESS %.2fs | Wave %d | %d kills | %d bosses | peak army %d | training %d" % [
		game.elapsed, game.wave, game.kills, game.bosses_defeated, peak_army, game.training])
	if capture:
		await _shot("result")
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


func _validate_combat_assets() -> void:
	var dir := "res://assets/survivor/combat/"
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "manifest.json"))
	var checked := 0
	for sheet: Dictionary in manifest.values():
		for frame: Dictionary in sheet.frames:
			var art := load(dir + frame.id + ".png") as Texture2D
			if art != null and art.get_size() == Vector2(frame.size[0], frame.size[1]):
				checked += 1
	_check(manifest.size() == 10 and checked == 92, "All 92 sprites from the ten combat sheets import at their recorded size")


func _validate_vfx_pack_assets() -> void:
	var dir := "res://assets/survivor/vfx/"
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "manifest.json"))
	var checked := 0
	var sheets: Dictionary = manifest.sheets
	for sheet: Dictionary in sheets.values():
		for frame: Dictionary in sheet.frames:
			var art := load(dir + frame.id + ".png") as Texture2D
			if art != null and art.get_size() == Vector2(frame.size[0], frame.size[1]):
				checked += 1
	_check(sheets.size() == 7 and checked == 80, "All 80 sprites from the seven new VFX sheets import at their recorded size")


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


var _shop_cursor := 0


func _shop() -> void:
	for role in ["staff", "archer", "tank", "mage", "healer"]:
		if not game.is_role_unlocked(role):
			continue
		var present := false
		for soldier in game.army:
			present = present or (is_instance_valid(soldier) and soldier.role == role)
		if not present:
			if game.can_summon(role):
				_click(ShopHud.summon_button_center(game.ROLE_ORDER.find(role)))
			return
	if game.can_train() and game.training < 1 + game.wave:
		_click(ShopHud.train_button_center())
		return
	var rotation := ["mage", "archer", "tank", "healer", "staff"]
	for step in rotation.size():
		var role: String = rotation[(_shop_cursor + step) % rotation.size()]
		if game.can_summon(role):
			_click(ShopHud.summon_button_center(game.ROLE_ORDER.find(role)))
			_shop_cursor = (_shop_cursor + step + 1) % rotation.size()
			return


func _shot(name: String) -> void:
	shots[name] = true
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://docs/survivor/commander/%s.png" % name
	_check(image != null and image.save_png(path) == OK, "GPU capture: " + name)
