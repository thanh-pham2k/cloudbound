extends Node2D

## Isolated Godot 4 assembly test for Batch 01 (Ground & Platforms).
## Demonstrates 3x3 TileMapLayer grass & cloud/stone tiling, platform edges/corners,
## stone bridge between two platforms, and stone stairs.

const TILE_SIZE := 128


func _ready() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var tex_paths := [
		"res://assets/base/environment/ground/ground_jade_tile_01.png",
		"res://assets/base/environment/ground/ground_jade_tile_02.png",
		"res://assets/base/environment/ground/ground_cloud_tile_01.png",
		"res://assets/base/environment/ground/ground_rune_center_01.png",
	]

	for i in range(tex_paths.size()):
		var src := TileSetAtlasSource.new()
		src.texture = load(tex_paths[i])
		src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		src.create_tile(Vector2i(0, 0))
		tile_set.add_source(src, i)

	var layer := TileMapLayer.new()
	layer.tile_set = tile_set
	add_child(layer)

	# 1. Left island: 3x3 repeated grass tiles (source 0 & 1)
	for gy in range(3):
		for gx in range(3):
			var src_id := 1 if (gx == 1 and gy == 1) else 0
			layer.set_cell(Vector2i(gx, gy), src_id, Vector2i(0, 0))

	# 2. Right island: 3x3 repeated cloud/stone tiles (source 2 & center rune 3)
	for gy in range(3):
		for gx in range(5, 8):
			var src_id := 3 if (gx == 6 and gy == 1) else 2
			layer.set_cell(Vector2i(gx, gy), src_id, Vector2i(0, 0))

	# 3. Floating platform edges & corners below left island
	_add_sprite("res://assets/base/environment/platforms/platform_cloud_edge_01.png", Vector2(192, 416))
	_add_sprite("res://assets/base/environment/platforms/platform_cloud_corner_01.png", Vector2(64, 416))

	# 4. Stone bridge connecting left and right platforms
	_add_sprite("res://assets/base/environment/bridges/bridge_stone_01.png", Vector2(512, 192))

	# 5. Stone stairs below right platform
	_add_sprite("res://assets/base/environment/bridges/stairs_stone_01.png", Vector2(768, 416))

	var cam := Camera2D.new()
	cam.position = Vector2(500, 250)
	cam.zoom = Vector2(0.95, 0.95)
	add_child(cam)


func _add_sprite(res_path: String, pos: Vector2) -> void:
	var sp := Sprite2D.new()
	sp.texture = load(res_path)
	sp.position = pos
	add_child(sp)
