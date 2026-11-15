extends Node2D
## Isolated B01 assembly inspection only. Not part of the main gameplay scene.
## Shows two floating islands (jade grass & stone), connected platform rims,
## a 4-module stone bridge, and stone stairs.

const CELL := 128
const GROUND := "res://assets/base/environment/ground/"
const PLATFORMS := "res://assets/base/environment/platforms/"
const BRIDGES := "res://assets/base/environment/bridges/"

var _load_warnings: Array[String] = []


func _ready() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(CELL, CELL)
	var surface_names := ["ground_jade_tile_01.png", "ground_jade_tile_02.png", "ground_stone_tile_01.png", "ground_rune_center_01.png"]
	for idx in range(surface_names.size()):
		var texture: Texture2D = load(GROUND + surface_names[idx])
		if texture == null:
			_load_warnings.append("Missing ground: " + surface_names[idx])
			continue
		var source := TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(CELL, CELL)
		source.create_tile(Vector2i.ZERO)
		tile_set.add_source(source, idx)

	var surface := TileMapLayer.new()
	surface.name = "RepeatableTerrain"
	surface.tile_set = tile_set
	add_child(surface)

	# Two 3x3 islands separated by four tile widths (rims + 2-tile bridge span).
	# Island A: tile origins 0..2 (jade grass), Island B: tile origins 7..9 (stone).
	for y in range(3):
		for x in range(3):
			surface.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
			surface.set_cell(Vector2i(x + 7, y), 2, Vector2i.ZERO)
	surface.set_cell(Vector2i(8, 1), 3, Vector2i.ZERO)
	surface.set_cell(Vector2i(1, 1), 1, Vector2i.ZERO)

	# Platform edges & corners around Island A (0..2) and Island B (7..9)
	for x in range(3):
		_add_sprite_if_available(PLATFORMS + "platform_cloud_edge_north_01.png", Vector2(x * CELL + 64, -64), "LeftNorth")
		_add_sprite_if_available(PLATFORMS + "platform_cloud_edge_south_01.png", Vector2(x * CELL + 64, 3 * CELL + 64), "LeftSouth")
		_add_sprite_if_available(PLATFORMS + "platform_cloud_edge_north_01.png", Vector2((x + 7) * CELL + 64, -64), "RightNorth")
		_add_sprite_if_available(PLATFORMS + "platform_cloud_edge_south_01.png", Vector2((x + 7) * CELL + 64, 3 * CELL + 64), "RightSouth")
	for y in range(3):
		_add_sprite_if_available(PLATFORMS + "platform_cloud_edge_west_01.png", Vector2(-64, y * CELL + 64), "LeftWest")
		_add_sprite_if_available(PLATFORMS + "platform_cloud_edge_east_01.png", Vector2(3 * CELL + 64, y * CELL + 64), "LeftEast")
		_add_sprite_if_available(PLATFORMS + "platform_cloud_edge_west_01.png", Vector2(7 * CELL - 64, y * CELL + 64), "RightWest")
		_add_sprite_if_available(PLATFORMS + "platform_cloud_edge_east_01.png", Vector2(10 * CELL + 64, y * CELL + 64), "RightEast")
	for entry in [
		["nw", Vector2(-64, -64)], ["ne", Vector2(3 * CELL + 64, -64)],
		["sw", Vector2(-64, 3 * CELL + 64)], ["se", Vector2(3 * CELL + 64, 3 * CELL + 64)],
		["nw", Vector2(7 * CELL - 64, -64)], ["ne", Vector2(10 * CELL + 64, -64)],
		["sw", Vector2(7 * CELL - 64, 3 * CELL + 64)], ["se", Vector2(10 * CELL + 64, 3 * CELL + 64)],
	]:
		_add_sprite_if_available(PLATFORMS + "platform_cloud_corner_%s_01.png" % entry[0], entry[1], "Corner")

	# 4-module stone bridge connecting Island A (x=3) to Island B (x=6) on top of rims
	var bridge_names := [
		"bridge_stone_entrance_01.png",
		"bridge_stone_middle_01.png",
		"bridge_stone_extension_01.png",
		"bridge_stone_exit_01.png",
	]
	for b_idx in range(bridge_names.size()):
		_add_sprite(BRIDGES + bridge_names[b_idx], Vector2((3 + b_idx) * CELL + 64, 1.5 * CELL), "Bridge_%d" % b_idx, 2)

	# Stone stairs on south side of Island B
	_add_sprite(BRIDGES + "stairs_stone_01.png", Vector2(8.5 * CELL, 3.5 * CELL), "Stairs", 2)

	var camera := Camera2D.new()
	camera.position = Vector2(5 * CELL, 1.5 * CELL)
	camera.zoom = Vector2(0.72, 0.72)
	camera.enabled = true
	add_child(camera)

	if not _load_warnings.is_empty():
		for issue in _load_warnings:
			push_warning("B01 REVIEW_REQUIRED: " + issue)
	if "--screenshot" in OS.get_cmdline_user_args():
		call_deferred("_capture_frame")


func _add_sprite(path: String, location: Vector2, name_hint: String, z_ord: int = 0) -> void:
	var texture: Texture2D = load(path)
	if texture == null:
		_load_warnings.append("Missing sprite: " + path)
		return
	var sprite := Sprite2D.new()
	sprite.name = name_hint
	sprite.texture = texture
	sprite.position = location
	sprite.z_index = z_ord
	add_child(sprite)


func _add_sprite_if_available(path: String, location: Vector2, name_hint: String) -> void:
	if ResourceLoader.exists(path):
		_add_sprite(path, location, name_hint)
	else:
		_load_warnings.append("Revised module not delivered: " + path)


func _capture_frame() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var frame := get_viewport().get_texture().get_image()
	if frame == null or frame.is_empty():
		push_error("Screenshot capture unavailable in this render mode")
		get_tree().quit(2)
		return
	var path := "res://assets/previews/b01_godot_assembly_actual.png"
	var error := frame.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Could not save actual Godot screenshot: " + str(error))
		get_tree().quit(2)
		return
	print("Godot screenshot saved: " + path)
	get_tree().quit(0)
