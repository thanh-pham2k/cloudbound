extends Node

func _ready() -> void:
	var scene_path := "res://scenes/main.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			scene_path = arg.substr(8)
	var main_scene: PackedScene = load(scene_path)
	var inst := main_scene.instantiate()
	add_child(inst)
	call_deferred("_capture")


func _capture() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var out_path := "res://assets/previews/gameplay_after.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_path = arg.substr(6)
	if img != null and not img.is_empty():
		img.save_png(ProjectSettings.globalize_path(out_path))
		print("Saved gameplay screenshot: ", out_path)
	get_tree().quit(0)
