extends "res://tests/validate_survivor.gd"
## Native, normal-speed fixtures drive real animation and gameplay event handlers.

const OUT := "res://docs/survivor/polish/"
const POLISH_ART := "res://assets/survivor/polish/"

var _rendered := {}
var _fixture_motion := false


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Use a graphical Godot run for this capture test.")
		quit(1)
		return
	game = Scene.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	RenderingServer.frame_post_draw.connect(_collect)
	_click(Vector2(640, 538))
	await _hold(0.43)
	_fixture_motion = true
	_key(KEY_D)
	await _hold(0.48)
	_key(KEY_A)
	await _hold(0.49)
	_fixture_motion = false

	await _exercise_shop_and_formation()
	await _exercise_weapons()
	await _exercise_boss_and_results()

	RenderingServer.frame_post_draw.disconnect(_collect)
	_validate_manifest()
	quit(int(failed))


func _exercise_shop_and_formation() -> void:
	game._enter(game.State.SHOP)
	await _hold(0.16)
	await _save("shop-level")
	_click(Vector2(965, 580))
	await _hold(0.16)
	game._enter(game.State.SHOP)
	game.gold = 500
	game.hud.show_shop()
	_click(Vector2(305, 503))
	await _hold(0.15)
	await _save("shop-purchase")
	_click(Vector2(965, 580))
	await _hold(0.36)
	await _save("summon")
	await _hold(0.42)
	game._enter(game.State.SHOP)
	for slot in 4:
		_check(game.buy_monkey(), "Staged purchase fills slot %d" % (slot + 2))
	game.buy_weapon(1, "bow")
	game.buy_weapon(2, "magic")
	await _hold(0.15)
	await _save("shop-weapon")
	_click(Vector2(965, 580))
	await _hold(0.76)

	_fixture_motion = true
	# Drive a stable 60 Hz animation step under the regular input handler.
	_key(KEY_A)
	await _hold(0.13)
	await _save("commander-switch")
	await _hold(0.35)
	_key(KEY_D)
	await _hold(0.50)
	_fixture_motion = false
	_check(_formation_valid(), "Visual fixtures leave commander and five troops in their assigned slots")


func _exercise_weapons() -> void:
	var none: Array[Survivor.Actor] = []
	var slime := game._spawn_enemy("slime", 0)
	var boar := game._spawn_enemy("boar", 2)
	for foe in [slime, boar]:
		foe.position.y = 102.0
		game._update_enemy(foe, none, null, 0.04)
	await _hold(0.10)
	game.wave = 3
	var flank := game._spawn_enemy("slime", 1)
	await _hold(0.12)
	var center := game._spawn_enemy("boar", 1)
	for foe in [flank, center]:
		foe.position.y = 102.0
		game._update_enemy(foe, none, null, 0.04)
	await _hold(0.10)
	await _save("enemy-entry")

	slime.position.y = 579
	game._update_enemy(slime, none, null, 0.06)
	await _hold(0.12)
	await _save("lane-danger")
	game._begin_enemy_strike(flank, game.army[0].position, false)
	game._update_enemy(flank, [game.army[0]], null, 0.43)
	game._begin_enemy_strike(center, game.army[2].position, false)
	game._update_enemy(center, [game.army[2]], null, 0.43)
	await _hold(0.44)

	center.position = game.army[0].position + Vector2(5, -89)
	game._attack(game.army[0], 0.2)
	await _hold(0.15)
	await _save("staff-hit")
	await _hold(0.22)

	boar.position = game.army[1].position + Vector2(-151, -103)
	game._attack(game.army[1], 0.18)
	game._move_projectiles(0.16)
	await _hold(0.11)
	await _save("bow-volley")
	game._move_projectiles(0.6)
	await _hold(0.28)
	center.position = game.army[1].position + Vector2(-5, -102)
	game.army[1].cooldown = 0.0
	game._attack(game.army[1], 0.18)
	game._damage(center, center.hp)
	game._move_projectiles(0.6)

	flank.position = game.army[2].position + Vector2(37, -84)
	boar.position = flank.position + Vector2(46, -55)
	game._attack(game.army[2], 0.24)
	await _hold(0.15)
	await _save("area-magic")
	await _hold(0.32)
	game.army[2].cooldown = 0.0
	boar.position = game.army[2].position + Vector2(19, -86)
	game._attack(game.army[2], 0.24)
	await _hold(0.30)

	slime.position = Vector2(game.field.LANES[0], game.field.REAR_LINE_Y)
	game._update_enemy(slime, none, null, 0.002)
	game.enemies.erase(slime)
	game._damage(flank, flank.hp)
	await _hold(0.16)
	await _save("breach")
	await _hold(0.55)
	game._damage(game.army[4], 1000)
	boar.position = game.hero.position + Vector2(-45, -60)
	game._attack(game.hero, 0.2)
	await _hold(0.18)
	await _save("ruyi-strike")
	await _hold(0.50)


func _exercise_boss_and_results() -> void:
	var none: Array[Survivor.Actor] = []
	game.elapsed = game.BOSS_TIME
	var king := game._spawn_enemy("boss", 1)
	game.boss = king
	game.hud.update_stats()
	king.position.y = 102.0
	game._update_enemy(king, none, null, 0.04)
	await _hold(0.18)
	king.position.y = 317
	game._begin_enemy_strike(king, game.army[0].position, false)
	await _hold(0.26)
	await _save("boss-warning")
	game._update_enemy(king, [game.army[0]], null, 0.93)
	await _hold(0.15)
	await _save("boss-impact")
	await _hold(0.30)
	game._damage(king, king.hp - int(king.max_hp / 3.0))
	game._begin_enemy_strike(king, game.army[0].position, false)
	await _hold(0.16)
	await _save("boss-rage")
	game._update_enemy(king, none, null, 0.93)
	await _hold(0.33)
	game._damage(king, king.hp)
	await _hold(0.15)
	await _save("victory")
	_check(game.state == game.State.VICTORY, "Killing the Boar King plays Victory")
	await _hold(0.44)
	_click(Vector2(520, 457))
	_check(game.state == game.State.RUNNING and game.elapsed < 0.2, "Result Restart clears the fixture round")
	game.hero.position.x = 420
	game._damage(game.hero, game.hero.hp)
	await _hold(0.16)
	await _save("defeat")
	_check(game.state == game.State.DEFEAT, "Fatal commander hit plays Defeat")


func _hold(seconds: float) -> void:
	for tick in roundi(seconds * 60):
		if _fixture_motion:
			game.elapsed += 1.0 / 60.0
			game._move_army(1.0 / 60.0)
		if not paused:
			game.field.scroll(1.0 / 60.0)
		game.hud.update_stats()
		await process_frame


func _save(id: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image != null and image.save_png(OUT + id + ".png") == OK, "Captured " + id)


func _collect() -> void:
	_scan_textures(root)


func _scan_textures(node: Node) -> void:
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	if node is Sprite2D or node is TextureRect:
		var art: Texture2D = node.texture
		if art != null and node.modulate.a > 0.02 and art.resource_path.begins_with(POLISH_ART):
			if not node is Sprite2D or Rect2(-45, -45, 1370, 810).has_point(node.global_position):
				var name := art.resource_path.get_file().get_basename()
				_rendered[name] = int(_rendered.get(name, 0)) + 1
	for child in node.get_children():
		_scan_textures(child)


func _validate_manifest() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(POLISH_ART + "manifest.json"))
	var total := 0
	var integrated := 0
	var invalid: Array[String] = []
	var missing: Array[String] = []
	for sheet: Dictionary in manifest.values():
		for frame: Dictionary in sheet.frames:
			total += 1
			var name: String = frame.name
			var art := load(POLISH_ART + name + ".png") as Texture2D
			if art == null or art.get_size() != Vector2(frame.size[0], frame.size[1]):
				invalid.append(name)
			if frame.integrated:
				integrated += 1
				if not _rendered.has(name):
					missing.append(name)
	_check(manifest.size() == 14 and total == 132 and invalid.is_empty(),
		"All 132 named sprites import with the manifest dimensions")
	print("Rendered %d / %d integrated sprites. Missing: %s" % [integrated - missing.size(), integrated, missing])
	_check(missing.is_empty(), "Every integrated image appeared in a rendered gameplay or UI event")
	var file := FileAccess.open(OUT + "rendered-coverage.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"integrated": integrated, "frames_seen": _rendered, "missing": missing}, "\t", true) + "\n")
