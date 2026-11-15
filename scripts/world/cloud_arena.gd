extends Node2D
class_name CloudArena

## Modular 2.5D Floating Cloud Island & Village arena built from B01/B02 128x128 tiles & props.
## Supports per-scene walkable geometry (multi-island + bridge rects or elliptical arenas)
## so visual and collision boundaries agree across all six scenes.

const TILE_SIZE := 128

@export_enum("mortal_realm", "stairway_clouds", "azure_outskirts", "azure_center", "boss_arena", "gate_of_heaven")
var scene_theme: String = "azure_outskirts"

@export var rx: float = 880.0
@export var ry: float = 480.0

var walkable_mode: String = "ellipse"
var walkable_rects: Array[Rect2] = []
var _pillar_positions: Array[Vector2] = []

var _terrain_root: Node2D
var _ground_layer: TileMapLayer
var _border_layer: TileMapLayer
var _deco_layer: Node2D
var _sky_rect: ColorRect


func configure(arena_rx: float, arena_ry: float) -> void:
	rx = arena_rx
	ry = arena_ry
	if is_inside_tree():
		_rebuild_visuals()
		_spawn_pillars()
	queue_redraw()


func _ready() -> void:
	_ensure_layers()
	_rebuild_visuals()
	_spawn_pillars()
	queue_redraw()


func _ensure_layers() -> void:
	if _terrain_root != null:
		return
	_sky_rect = ColorRect.new()
	_sky_rect.name = "SkyBackdrop"
	_sky_rect.color = Color(0.42, 0.72, 0.90, 1.0)
	_sky_rect.position = Vector2(-4000, -4000)
	_sky_rect.size = Vector2(8000, 8000)
	_sky_rect.z_index = -20
	_sky_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sky_rect)

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
	walkable_rects.clear()
	_pillar_positions.clear()

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

	match scene_theme:
		"mortal_realm":
			_build_mortal_realm()
		"stairway_clouds":
			_build_stairway_clouds()
		"azure_center":
			_build_azure_center()
		"boss_arena":
			_build_boss_arena()
		"gate_of_heaven":
			_build_gate_of_heaven()
		_:
			_build_azure_outskirts()


func _fill_rect_ground(min_x: int, max_x: int, min_y: int, max_y: int, src_id: int = -1) -> void:
	for gy in range(min_y, max_y + 1):
		for gx in range(min_x, max_x + 1):
			var sid := src_id if src_id >= 0 else (0 if ((gx + gy) & 1) == 0 else 1)
			_ground_layer.set_cell(Vector2i(gx, gy), sid, Vector2i(0, 0))


func _surround_cloud_border(min_x: int, max_x: int, min_y: int, max_y: int) -> void:
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


func _paint_stone_courtyard(cx0: int, cx1: int, cy0: int, cy1: int) -> void:
	for gy in range(cy0, cy1 + 1):
		for gx in range(cx0, cx1 + 1):
			_ground_layer.set_cell(Vector2i(gx, gy), 2, Vector2i(0, 0))
	for gx in range(cx0, cx1 + 1):
		_ground_layer.set_cell(Vector2i(gx, cy0 - 1), 6, Vector2i(0, 0))
		_ground_layer.set_cell(Vector2i(gx, cy1 + 1), 5, Vector2i(0, 0))
	for gy in range(cy0, cy1 + 1):
		_ground_layer.set_cell(Vector2i(cx0 - 1, gy), 8, Vector2i(0, 0))
		_ground_layer.set_cell(Vector2i(cx1 + 1, gy), 7, Vector2i(0, 0))
	_ground_layer.set_cell(Vector2i(cx0 - 1, cy0 - 1), 12, Vector2i(0, 0))
	_ground_layer.set_cell(Vector2i(cx1 + 1, cy0 - 1), 11, Vector2i(0, 0))
	_ground_layer.set_cell(Vector2i(cx0 - 1, cy1 + 1), 10, Vector2i(0, 0))
	_ground_layer.set_cell(Vector2i(cx1 + 1, cy1 + 1), 9, Vector2i(0, 0))


func _build_mortal_realm() -> void:
	_sky_rect.color = Color(0.55, 0.80, 0.94, 1.0)
	walkable_mode = "rects"
	rx = 640.0
	ry = 384.0
	_fill_rect_ground(-5, 4, -3, 2)
	# Stone village pathway leading east toward the gateway
	for gx in range(-2, 5):
		_ground_layer.set_cell(Vector2i(gx, 0), 2, Vector2i(0, 0))
	_surround_cloud_border(-5, 4, -3, 2)
	walkable_rects.append(Rect2(-5 * TILE_SIZE, -3 * TILE_SIZE, 10 * TILE_SIZE, 6 * TILE_SIZE))

	_add_deco("res://assets/base/environment/architecture/arch_village_house_01.png", Vector2(-360, -180))
	_add_deco("res://assets/base/environment/decorations/deco_peach_bonsai_01.png", Vector2(-520, -40))
	_add_deco("res://assets/base/environment/decorations/deco_peach_bonsai_01.png", Vector2(-140, -240))
	_add_deco("res://assets/base/environment/decorations/deco_green_tree_01.png", Vector2(220, -240))
	_add_deco("res://assets/base/environment/decorations/deco_wooden_fence_01.png", Vector2(-460, 220))
	_add_deco("res://assets/base/environment/decorations/deco_wooden_fence_01.png", Vector2(-332, 220))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(460, -60))
	_add_deco("res://assets/base/environment/architecture/arch_celestial_gate_01.png", Vector2(540, 20))


func _build_stairway_clouds() -> void:
	_sky_rect.color = Color(0.46, 0.75, 0.92, 1.0)
	walkable_mode = "rects"
	rx = 960.0
	ry = 320.0
	# Left floating island: gx in [-7..-2], gy in [-2..1]
	_fill_rect_ground(-7, -2, -2, 1)
	_surround_cloud_border(-7, -2, -2, 1)
	# Right floating island: gx in [2..7], gy in [-2..1]
	_fill_rect_ground(2, 7, -2, 1)
	_surround_cloud_border(2, 7, -2, 1)

	# Connected 3-segment stone bridge spanning gx in [-1..1] at y=0
	_add_deco("res://assets/base/environment/bridges/bridge_stone_entrance_01.png", Vector2(-64, 0), 2)
	_add_deco("res://assets/base/environment/bridges/bridge_stone_middle_01.png", Vector2(64, 0), 2)
	_add_deco("res://assets/base/environment/bridges/bridge_stone_exit_01.png", Vector2(192, 0), 2)
	_add_deco("res://assets/base/environment/bridges/stairs_stone_01.png", Vector2(576, 304))

	_add_deco("res://assets/base/environment/decorations/deco_peach_bonsai_01.png", Vector2(-760, -160))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(-740, 160))
	_add_deco("res://assets/base/environment/decorations/deco_green_tree_01.png", Vector2(820, -160))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(-200, -100))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(320, -100))

	# Exact walkable rects for left island, overlapping bridge, and right island
	walkable_rects.append(Rect2(-7 * TILE_SIZE, -2 * TILE_SIZE, 6 * TILE_SIZE, 4 * TILE_SIZE))
	walkable_rects.append(Rect2(-180, -48, 480, 96))
	walkable_rects.append(Rect2(2 * TILE_SIZE, -2 * TILE_SIZE, 6 * TILE_SIZE, 4 * TILE_SIZE))


func _build_azure_outskirts() -> void:
	_sky_rect.color = Color(0.42, 0.72, 0.90, 1.0)
	walkable_mode = "ellipse"
	rx = 768.0
	ry = 448.0
	_fill_rect_ground(-6, 5, -4, 3)
	_paint_stone_courtyard(-1, 0, -1, 0)
	_add_deco("res://assets/base/environment/ground/ground_rune_center_01.png", Vector2(0, 0))
	_surround_cloud_border(-6, 5, -4, 3)

	_add_deco("res://assets/base/environment/decorations/deco_peach_bonsai_01.png", Vector2(-640, -340))
	_add_deco("res://assets/base/environment/decorations/deco_green_tree_01.png", Vector2(640, -340))
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(-560, -290))
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(560, -290))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(-640, 320))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(640, 320))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(-500, 340))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(500, 340))
	_add_sky_backdrop()


func _build_azure_center() -> void:
	_sky_rect.color = Color(0.38, 0.68, 0.88, 1.0)
	walkable_mode = "ellipse"
	rx = 768.0
	ry = 448.0
	_fill_rect_ground(-6, 5, -4, 3)
	_paint_stone_courtyard(-3, 2, -2, 1)
	_add_deco("res://assets/base/environment/ground/ground_rune_center_01.png", Vector2(0, 0))
	_surround_cloud_border(-6, 5, -4, 3)

	_pillar_positions = [
		Vector2(-340, -160),
		Vector2(340, -160),
		Vector2(-340, 160),
		Vector2(340, 160),
	]
	_add_deco("res://assets/base/environment/decorations/deco_incense_brazier_01.png", Vector2(0, -240))
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(-560, 260))
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(560, 260))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(-520, -320))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(520, -320))
	_add_sky_backdrop()


func _build_boss_arena() -> void:
	_sky_rect.color = Color(0.28, 0.48, 0.72, 1.0)
	walkable_mode = "ellipse"
	rx = 896.0
	ry = 512.0
	_fill_rect_ground(-7, 6, -4, 3, 2)
	_add_deco("res://assets/base/environment/ground/ground_rune_center_01.png", Vector2(0, 0), -4)
	for i in range(8):
		var angle := float(i) * TAU / 8.0
		var ring_pos := Vector2(cos(angle) * 280.0, sin(angle) * 165.0)
		var tile_idx := (i % 9) + 1
		_add_deco("res://assets/base/environment/ground/ground_arena_tile_%02d.png" % tile_idx, ring_pos, -5)
	_surround_cloud_border(-7, 6, -4, 3)

	_pillar_positions = [
		Vector2(-560, -250),
		Vector2(560, -250),
		Vector2(-560, 250),
		Vector2(560, 250),
	]
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(-720, 0))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(720, 0))
	_add_sky_backdrop()


func _build_gate_of_heaven() -> void:
	_sky_rect.color = Color(0.58, 0.82, 0.96, 1.0)
	walkable_mode = "rects"
	rx = 512.0
	ry = 320.0
	_fill_rect_ground(-4, 3, -3, 2, 3)
	# Central carved stone path up to the Heavenly Gate
	for gy in range(-2, 3):
		_ground_layer.set_cell(Vector2i(-1, gy), 2, Vector2i(0, 0))
		_ground_layer.set_cell(Vector2i(0, gy), 2, Vector2i(0, 0))
	_surround_cloud_border(-4, 3, -3, 2)
	walkable_rects.append(Rect2(-4 * TILE_SIZE, -3 * TILE_SIZE, 8 * TILE_SIZE, 6 * TILE_SIZE))

	_add_deco("res://assets/base/environment/decorations/deco_peach_bonsai_01.png", Vector2(-360, -180))
	_add_deco("res://assets/base/environment/decorations/deco_peach_bonsai_01.png", Vector2(360, -180))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(-180, -80))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(180, -80))
	_add_deco("res://assets/base/props/prop_reward_chest_01.png", Vector2(-160, 60))
	_add_sky_backdrop()


func _add_sky_backdrop() -> void:
	_add_deco("res://assets/base/environment/decorations/bg_distant_island_01.png", Vector2(-880, -480), -30)
	_add_deco("res://assets/base/environment/decorations/bg_distant_island_01.png", Vector2(920, -450), -30)
	_add_deco("res://assets/base/environment/decorations/bg_cloud_bank_01.png", Vector2(-640, 520), -25)
	_add_deco("res://assets/base/environment/decorations/bg_cloud_bank_01.png", Vector2(640, 520), -25)


func _add_deco(res_path: String, pos: Vector2, z_ord: int = 0) -> void:
	if not ResourceLoader.exists(res_path):
		return
	var sp := Sprite2D.new()
	sp.texture = load(res_path)
	sp.position = pos
	sp.z_index = z_ord
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
	if walkable_mode == "rects" and not walkable_rects.is_empty():
		var best_pt := pos
		var best_d2 := INF
		for r in walkable_rects:
			var is_bridge := r.size.y < 140.0
			var mx := 0.0 if is_bridge else margin
			var my := minf(margin, r.size.y * 0.25) if is_bridge else margin
			var min_p := Vector2(r.position.x + mx, r.position.y + my)
			var max_p := Vector2(r.end.x - mx, r.end.y - my)
			var clamped := Vector2(clampf(pos.x, min_p.x, max_p.x), clampf(pos.y, min_p.y, max_p.y))
			var d2 := pos.distance_squared_to(clamped)
			if d2 < best_d2:
				best_d2 = d2
				best_pt = clamped
				if d2 <= 0.001:
					return clamped
		return best_pt

	var erx := maxf(rx - margin, 100.0)
	var ery := maxf(ry - margin, 100.0)
	var norm := Vector2(pos.x / erx, pos.y / ery)
	var len_sq := norm.length_squared()
	if len_sq > 1.0:
		norm = norm / sqrt(len_sq)
		return Vector2(norm.x * erx, norm.y * ery)
	return pos


func random_point_in_arena(min_dist_from_center: float = 0.0, max_ratio: float = 0.86) -> Vector2:
	if walkable_mode == "rects" and not walkable_rects.is_empty():
		var candidates: Array[Rect2] = []
		for r in walkable_rects:
			if r.size.y >= 160.0:
				candidates.append(r)
		if candidates.is_empty():
			candidates = walkable_rects
		for _i in range(16):
			var r: Rect2 = candidates[randi() % candidates.size()]
			var pad := 48.0
			var pt := Vector2(
				randf_range(r.position.x + pad, r.end.x - pad),
				randf_range(r.position.y + pad, r.end.y - pad)
			)
			if pt.length() >= min_dist_from_center:
				return pt
		return candidates[0].get_center()

	for _i in range(16):
		var angle := randf() * TAU
		var r := sqrt(randf()) * max_ratio
		var pt := Vector2(cos(angle) * rx * r, sin(angle) * ry * r)
		if pt.length() >= min_dist_from_center:
			return pt
	return Vector2(rx * 0.6, 0.0)
