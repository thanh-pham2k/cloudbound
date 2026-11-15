extends Node2D
class_name CloudArena

## 2.5D Floating Cloud Island arena built from B01/B02 modular 128x128 tiles & props,
## preserving arena collision, movement boundaries, and spawn logic.

const TILE_SIZE := 128

@export var rx: float = 880.0
@export var ry: float = 480.0

var _pillar_positions: Array[Vector2] = [
	Vector2(-380, -160),
	Vector2(380, -160),
	Vector2(-380, 160),
	Vector2(380, 160),
]

var _terrain_root: Node2D
var _ground_layer: TileMapLayer
var _border_layer: TileMapLayer
var _deco_layer: Node2D


func configure(arena_rx: float, arena_ry: float) -> void:
	rx = arena_rx
	ry = arena_ry
	if is_inside_tree():
		_rebuild_visuals()
	queue_redraw()


func _ready() -> void:
	z_index = -10
	_ensure_layers()
	_rebuild_visuals()
	_spawn_pillars()
	queue_redraw()


func _ensure_layers() -> void:
	if _terrain_root != null:
		return
	var sky := ColorRect.new()
	sky.name = "SkyBackdrop"
	sky.color = Color(0.42, 0.72, 0.90, 1.0)
	sky.position = Vector2(-4000, -4000)
	sky.size = Vector2(8000, 8000)
	sky.z_index = -20
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)

	_terrain_root = Node2D.new()
	_terrain_root.name = "ArenaVisuals"
	_terrain_root.z_index = -10
	add_child(_terrain_root)

	_border_layer = TileMapLayer.new()
	_border_layer.name = "IslandBorderLayer"
	_terrain_root.add_child(_border_layer)

	_ground_layer = TileMapLayer.new()
	_ground_layer.name = "GroundTileLayer"
	_terrain_root.add_child(_ground_layer)

	_deco_layer = Node2D.new()
	_deco_layer.name = "PerimeterDecorations"
	_terrain_root.add_child(_deco_layer)


func _build_tileset(paths: Array[String]) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in range(paths.size()):
		if not ResourceLoader.exists(paths[i]):
			continue
		var src := TileSetAtlasSource.new()
		src.texture = load(paths[i])
		src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		src.create_tile(Vector2i(0, 0))
		ts.add_source(src, i)
	return ts


func _rebuild_visuals() -> void:
	_ensure_layers()
	_ground_layer.clear()
	_border_layer.clear()
	for c in _deco_layer.get_children():
		c.queue_free()

	var ground_paths: Array[String] = [
		"res://assets/base/environment/ground/ground_jade_tile_01.png",            # 0
		"res://assets/base/environment/ground/ground_jade_tile_02.png",            # 1
		"res://assets/base/environment/ground/ground_stone_tile_01.png",           # 2
		"res://assets/base/environment/ground/ground_cloud_tile_01.png",           # 3
		"res://assets/base/environment/ground/ground_rune_center_01.png",          # 4
		"res://assets/base/environment/ground/ground_grass_stone_edge_north_01.png", # 5
		"res://assets/base/environment/ground/ground_grass_stone_edge_south_01.png", # 6
		"res://assets/base/environment/ground/ground_grass_stone_edge_west_01.png",  # 7
		"res://assets/base/environment/ground/ground_grass_stone_edge_east_01.png",  # 8
		"res://assets/base/environment/ground/ground_grass_stone_outer_nw_01.png",   # 9
		"res://assets/base/environment/ground/ground_grass_stone_outer_ne_01.png",   # 10
		"res://assets/base/environment/ground/ground_grass_stone_outer_sw_01.png",   # 11
		"res://assets/base/environment/ground/ground_grass_stone_outer_se_01.png",   # 12
	]
	_ground_layer.tile_set = _build_tileset(ground_paths)

	var border_paths: Array[String] = [
		"res://assets/base/environment/platforms/platform_cloud_edge_north_01.png", # 0
		"res://assets/base/environment/platforms/platform_cloud_edge_south_01.png", # 1
		"res://assets/base/environment/platforms/platform_cloud_edge_west_01.png",  # 2
		"res://assets/base/environment/platforms/platform_cloud_edge_east_01.png",  # 3
		"res://assets/base/environment/platforms/platform_cloud_corner_nw_01.png",  # 4
		"res://assets/base/environment/platforms/platform_cloud_corner_ne_01.png",  # 5
		"res://assets/base/environment/platforms/platform_cloud_corner_sw_01.png",  # 6
		"res://assets/base/environment/platforms/platform_cloud_corner_se_01.png",  # 7
		"res://assets/base/environment/platforms/platform_cloud_underside_01.png",  # 8
	]
	_border_layer.tile_set = _build_tileset(border_paths)

	var half_cols := maxi(3, int(ceil(rx / float(TILE_SIZE))))
	var half_rows := maxi(2, int(ceil(ry / float(TILE_SIZE))))
	var min_x := -half_cols
	var max_x := half_cols - 1
	var min_y := -half_rows
	var max_y := half_rows - 1

	# Fill main floating island floor with B01 jade grass + central carved stone courtyard
	for gy in range(min_y, max_y + 1):
		for gx in range(min_x, max_x + 1):
			var src_id := 0 if ((gx + gy) & 1) == 0 else 1
			# Central 4x2 stone courtyard (stone base everywhere inside)
			if gx >= -2 and gx <= 1 and gy >= -1 and gy <= 0:
				src_id = 2
			elif gx == -3 and gy == -1:
				src_id = 12 # outer_se: grass top-left, stone bottom-right
			elif gx == 2 and gy == -1:
				src_id = 11 # outer_sw: grass top-right, stone bottom-left
			elif gx == -3 and gy == 0:
				src_id = 10 # outer_ne: stone top-right, grass bottom-left
			elif gx == 2 and gy == 0:
				src_id = 9  # outer_nw: stone top-left, grass bottom-right
			elif gy == -2 and gx >= -2 and gx <= 1:
				src_id = 6  # grass top, stone bottom
			elif gy == 1 and gx >= -2 and gx <= 1:
				src_id = 5  # stone top, grass bottom
			elif gx == -3 and gy >= -1 and gy <= 0:
				src_id = 8  # grass left, stone right
			elif gx == 2 and gy >= -1 and gy <= 0:
				src_id = 7  # stone left, grass right
			_ground_layer.set_cell(Vector2i(gx, gy), src_id, Vector2i(0, 0))

	# Center rune medallion layered cleanly on top of stone courtyard
	_add_deco("res://assets/base/environment/ground/ground_rune_center_01.png", Vector2(0, 0))

	# Surround island with B01 cloud platform edges, corners, and underside thickness
	for gx in range(min_x, max_x + 1):
		_border_layer.set_cell(Vector2i(gx, min_y - 1), 0, Vector2i(0, 0))
		_border_layer.set_cell(Vector2i(gx, max_y + 1), 1, Vector2i(0, 0))
		_border_layer.set_cell(Vector2i(gx, max_y + 2), 8, Vector2i(0, 0))
	for gy in range(min_y, max_y + 1):
		_border_layer.set_cell(Vector2i(min_x - 1, gy), 2, Vector2i(0, 0))
		_border_layer.set_cell(Vector2i(max_x + 1, gy), 3, Vector2i(0, 0))
	_border_layer.set_cell(Vector2i(min_x - 1, min_y - 1), 4, Vector2i(0, 0))
	_border_layer.set_cell(Vector2i(max_x + 1, min_y - 1), 5, Vector2i(0, 0))
	_border_layer.set_cell(Vector2i(min_x - 1, max_y + 1), 6, Vector2i(0, 0))
	_border_layer.set_cell(Vector2i(max_x + 1, max_y + 1), 7, Vector2i(0, 0))

	# Stone bridge on east edge & stone stairs on south edge
	var east_x := float((max_x + 1) * TILE_SIZE)
	_add_deco("res://assets/base/environment/bridges/bridge_stone_entrance_01.png", Vector2(east_x + 64, 0))
	_add_deco("res://assets/base/environment/bridges/bridge_stone_middle_01.png", Vector2(east_x + 192, 0))
	_add_deco("res://assets/base/environment/bridges/bridge_stone_exit_01.png", Vector2(east_x + 320, 0))
	_add_deco("res://assets/base/environment/bridges/stairs_stone_01.png", Vector2(0, float((max_y + 1) * TILE_SIZE) + 48))

	# Sparse perimeter props (lanterns, peach trees, rocks) outside combat center
	var corner_x := float(max_x * TILE_SIZE) - 16.0
	var corner_y := float(max_y * TILE_SIZE) - 16.0
	_add_deco("res://assets/base/environment/decorations/deco_peach_bonsai_01.png", Vector2(-corner_x, -corner_y))
	_add_deco("res://assets/base/environment/decorations/deco_peach_bonsai_01.png", Vector2(corner_x, -corner_y))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(-corner_x + 96, corner_y))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(corner_x - 96, corner_y))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(-corner_x, corner_y))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(corner_x, corner_y))


func _add_deco(res_path: String, pos: Vector2) -> void:
	if not ResourceLoader.exists(res_path):
		return
	var sp := Sprite2D.new()
	sp.texture = load(res_path)
	sp.position = pos
	_deco_layer.add_child(sp)


func _spawn_pillars() -> void:
	var obstacles_node := get_node_or_null("../YSort/Obstacles")
	if obstacles_node == null:
		return
	for child in obstacles_node.get_children():
		child.queue_free()

	var pillar_tex: Texture2D = null
	var pillar_path := "res://assets/base/environment/architecture/arch_jade_pillar_01.png"
	if ResourceLoader.exists(pillar_path):
		pillar_tex = load(pillar_path)

	for p_pos in _pillar_positions:
		var pillar := StaticBody2D.new()
		pillar.position = p_pos
		pillar.collision_layer = 1
		pillar.collision_mask = 0

		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 28.0
		col.shape = shape
		pillar.add_child(col)

		var visual := Sprite2D.new()
		visual.texture = pillar_tex
		visual.offset = Vector2(0, -76)
		pillar.add_child(visual)
		obstacles_node.add_child(pillar)


func clamp_to_arena(pos: Vector2, margin: float = 28.0) -> Vector2:
	var erx := maxf(rx - margin, 100.0)
	var ery := maxf(ry - margin, 100.0)
	var norm := Vector2(pos.x / erx, pos.y / ery)
	var len_sq := norm.length_squared()
	if len_sq > 1.0:
		norm = norm / sqrt(len_sq)
		return Vector2(norm.x * erx, norm.y * ery)
	return pos


func random_point_in_arena(min_dist_from_center: float = 0.0, max_ratio: float = 0.86) -> Vector2:
	for _i in range(16):
		var angle := randf() * TAU
		var r := sqrt(randf()) * max_ratio
		var pt := Vector2(cos(angle) * rx * r, sin(angle) * ry * r)
		if pt.length() >= min_dist_from_center:
			return pt
	return Vector2(rx * 0.6, 0.0)


func _draw() -> void:
	pass
