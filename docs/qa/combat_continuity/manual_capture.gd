extends SceneTree

func _initialize() -> void:
	var observer := ManualCapture.new()
	root.add_child.call_deferred(observer)
	change_scene_to_file.call_deferred("res://scenes/scene_01_mortal_realm.tscn")

class ManualCapture extends Node:
	var capture_index := 0
	var last_scene := ""
	var trace: FileAccess
	var clip_index := 0
	var clip_frame := 0
	var recording_until := 0
	var next_capture := 0
	var capturing := false
	var last_combat_state := ""

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		DirAccess.make_dir_recursive_absolute("res://docs/qa/combat_continuity/runtime")
		trace = FileAccess.open("res://docs/qa/combat_continuity/runtime/manual_trace.jsonl", FileAccess.WRITE)

	func _process(_delta: float) -> void:
		var scene := get_tree().current_scene
		if scene != null and scene.scene_file_path != last_scene:
			last_scene = scene.scene_file_path
			var player := scene.get_node_or_null("YSort/Entities/Player")
			if player != null:
				var sprite = player.get("_sprite")
				if sprite != null:
					sprite.frame_changed.connect(_record.bind("player_frame_changed"))
			_record("scene_entered")
		if scene != null:
			var snapshot := _snapshot()
			var combat_state := JSON.stringify({"player": snapshot.get("player"), "enemies": snapshot.get("enemies"), "paused": snapshot["paused"]})
			if combat_state != last_combat_state:
				last_combat_state = combat_state
				_record("observed_state_change")
		if recording_until > Time.get_ticks_msec() and next_capture <= Time.get_ticks_msec() and not capturing:
			next_capture = Time.get_ticks_msec() + 83
			_capture_clip.call_deferred()

	func _input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_F9:
				clip_index += 1
				clip_frame = 0
				recording_until = Time.get_ticks_msec() + 3000
				_record("recording_started_" + str(clip_index))
			elif event.keycode == KEY_F12:
				_capture.call_deferred()
			else:
				_record("key_" + OS.get_keycode_string(event.keycode))

	func _snapshot() -> Dictionary:
		var scene := get_tree().current_scene
		var result := {"ticks_ms": Time.get_ticks_msec(), "paused": get_tree().paused, "scene": last_scene}
		if scene == null:
			return result
		var player := scene.get_node_or_null("YSort/Entities/Player")
		if player != null:
			result["player"] = {}
			for property in ["current_hp", "max_hp", "attack_damage", "attack_cooldown", "skill1_damage", "skill2_damage", "move_speed", "crit_chance", "life_on_kill", "_is_dead", "_active_action", "_action_hit_applied"]:
				result["player"][property] = player.get(property)
			result["player"]["position"] = [player.position.x, player.position.y]
			var sprite = player.get("_sprite")
			if sprite != null:
				result["player"]["animation"] = str(sprite.animation)
				result["player"]["frame"] = sprite.frame
				result["player"]["playing_speed"] = sprite.get_playing_speed()
		var prog := scene.get_node_or_null("ProgressionSystem")
		if prog != null:
			result["progression"] = prog.snapshot()
		var data := get_node_or_null("/root/GameData")
		if data != null:
			result["loot"] = data.loot_currency
			result["upgrades"] = data.selected_upgrades
		result["enemies"] = []
		for enemy in get_tree().get_nodes_in_group("enemy"):
			var actor_sprite = enemy.get("_sprite")
			result["enemies"].append({"id": enemy.get_instance_id(), "hp": enemy.current_hp, "position": [enemy.position.x, enemy.position.y], "animation": str(actor_sprite.animation), "frame": actor_sprite.frame})
		result["telegraphs"] = []
		result["popups"] = []
		var effects := scene.get_node_or_null("Effects")
		if effects != null:
			for child in effects.get_children():
				if child is TelegraphArea:
					result["telegraphs"].append({"shape": child.shape_type, "position": [child.global_position.x, child.global_position.y], "radius": child.radius, "elapsed": child._elapsed, "duration": child.duration})
				elif child is DamageNumber:
					result["popups"].append({"text": child.text_value, "position": [child.global_position.x, child.global_position.y], "alpha": child.modulate.a})
		return result

	func _record(event: String) -> void:
		if trace == null:
			return
		var state := _snapshot()
		state["event"] = event
		trace.store_line(JSON.stringify(state))
		trace.flush()

	func _capture() -> void:
		await RenderingServer.frame_post_draw
		capture_index += 1
		var path := "res://docs/qa/combat_continuity/runtime/%03d_%s.png" % [capture_index, last_scene.get_file().get_basename()]
		var status := get_viewport().get_texture().get_image().save_png(path)
		_record("capture_" + path + "_result_" + str(status))
		print("MANUAL_QA_CAPTURE ", path, " result=", status)

	func _capture_clip() -> void:
		capturing = true
		await RenderingServer.frame_post_draw
		var folder := "res://docs/qa/combat_continuity/runtime/clip_%02d" % clip_index
		DirAccess.make_dir_recursive_absolute(folder)
		var path := folder + "/frame_%03d.png" % clip_frame
		var status := get_viewport().get_texture().get_image().save_png(path)
		_record("clip_frame_%02d_%03d_result_%d" % [clip_index, clip_frame, status])
		clip_frame += 1
		capturing = false
