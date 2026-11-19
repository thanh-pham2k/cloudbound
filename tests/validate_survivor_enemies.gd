extends "res://tests/validate_survivor.gd"
## Use --capture to see all supplied enemies in an actual Godot viewport.

const Looks := preload("res://scripts/survivor/enemy_looks.gd")
const OUT := "res://docs/survivor/enemies/"


func _run() -> void:
	game = Scene.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	game.start_game()
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Looks.ART + "manifest.json"))
	_validate_atlases(manifest)
	_validate_wave_looks(manifest)
	_validate_bosses()
	if capture:
		await _capture_roster(manifest)
	quit(int(failed))


func _validate_atlases(manifest: Dictionary) -> void:
	var valid := true
	var frame_total := 0
	for id: String in manifest:
		var data: Dictionary = manifest[id]
		var frames := Looks.clips(id)
		var region_count := {}
		for pose: String in ["idle", "move", "attack", "hurt", "dead"]:
			var indexes: Array = data.clips[pose]
			valid = valid and frames != null and frames.get_frame_count(pose) == indexes.size()
			if not valid:
				break
			for i in indexes.size():
				var expected: Array = data.frames[int(indexes[i])].region
				var frame := frames.get_frame_texture(pose, i) as AtlasTexture
				valid = valid and frame != null and frame.region == Rect2(
					expected[0], expected[1], expected[2], expected[3])
				if frame != null:
					region_count[frame.region.position] = true
		valid = valid and region_count.size() == data.frames.size()
		frame_total += region_count.size()
	_check(valid and manifest.size() == 27 and frame_total == 252,
		"All five clips, their order and all 252 atlas regions match the 27-sheet manifest")


func _validate_wave_looks(manifest: Dictionary) -> void:
	var seen_looks := {}
	var correct := true
	for second in int(game.BOSS_TIME):
		game.elapsed = float(second)
		game._spawn_waves(1.0)
		for enemy in game.enemies:
			var data: Array = game.ENEMIES[enemy.kind]
			correct = correct and enemy.position.x == game.field.LANES[enemy.enemy_lane]
			correct = correct and enemy.speed == data[1] and enemy.attack_damage == data[3]
			correct = correct and enemy.gold_reward == data[4] and enemy.xp_reward == data[5]
			if not enemy.appearance.is_empty():
				var spec: Dictionary = manifest[enemy.appearance]
				seen_looks[enemy.appearance] = true
				correct = correct and enemy.kind == ("slime" if spec.tier == "light" else "boar")
				if enemy.appearance in Looks.ELITES:
					correct = correct and game.wave >= 4
			enemy.queue_free()
		game.enemies.clear()
	_check(correct and seen_looks.size() == 23,
		"Existing waves reach all 23 regular and elite looks without changing enemy lane or profile")


func _validate_bosses() -> void:
	for id: String in ["boar_king"] + Looks.BOSSES.keys():
		game.boss_appearance = id
		game.start_game()
		game.elapsed = game.BOSS_TIME
		game._spawn_waves(0.0)
		game.hud.update_stats()
		var king := game.boss
		var look := "" if id == "boar_king" else id
		var correct := king != null and king.kind == "boss" and king.appearance == look
		correct = correct and king.enemy_lane == 1 and king.position.x == 640.0 and king.hp == 1150
		correct = correct and game.hud._boss_name.text == game.boss_display_name().to_upper()
		game._damage(king, king.hp)
		_check(correct and game.state == game.State.VICTORY and game.gold == game.START_GOLD + 45,
			"Scheduled %s finale uses the boss profile, title, reward and Victory" % game.boss_display_name())
	game.boss_appearance = "boar_king"


func _capture_roster(manifest: Dictionary) -> void:
	var names := manifest.keys()
	for page in 3:
		game.start_game()
		game.hero.hide()
		var cast: Array[Survivor.Actor] = []
		for slot in 9:
			var id: String = names[page * 9 + slot]
			var data: Dictionary = manifest[id]
			var kind := "slime" if data.tier == "light" else ("boar" if data.tier == "heavy" else "boss")
			var center := Vector2(game.field.LANES[slot % 3], 214 + floori(slot / 3.0) * 196)
			var unit := game._new_actor(kind, 100, game.ENEMIES[kind][6], center, id)
			cast.append(unit)
			var title := Label.new()
			title.position = center + Vector2(-102, 16)
			title.size = Vector2(204, 24)
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title.text = id.replace("_", " ").capitalize()
			title.add_theme_font_size_override("font_size", 15)
			title.add_theme_color_override("font_color", Color("#3c3c26"))
			game._play.add_child(title)
		for unit in cast:
			unit.move_pose(true)
		await create_timer(0.28).timeout
		await RenderingServer.frame_post_draw
		var path := "roster-%d.png" % (page + 1)
		_check(root.get_texture().get_image().save_png(OUT + path) == OK, "Rendered " + path)
		for unit in cast:
			unit.attack_pose(0.70)
		await create_timer(0.29).timeout
		await RenderingServer.frame_post_draw
		path = "actions-%d.png" % (page + 1)
		_check(root.get_texture().get_image().save_png(OUT + path) == OK, "Rendered " + path)
