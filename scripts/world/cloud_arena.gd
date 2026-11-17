extends Node2D
class_name CloudArena

## Builds the authored terrain and keeps movement on the playable surface.

const PaintedSprite := preload("res://scripts/world/painted_sprite.gd")
const IslandSurface := preload("res://scripts/world/island_surface.gd")

@export_enum("seamless_journey", "mortal_realm", "stairway_clouds", "azure_outskirts", "azure_center", "boss_arena", "gate_of_heaven")
var scene_theme: String = "seamless_journey"

@export var painted_visuals := false

@export var rx: float = 880.0
@export var ry: float = 480.0

var _island_outline := PackedVector2Array()
var _inset_outlines: Dictionary = {}
var _pillar_positions: Array[Vector2] = []

var _terrain_root: Node2D
var _deco_layer: Node2D
var _foreground_props: Node2D
var _sky_rect: TextureRect
var _sky_parallax: ParallaxBackground
var _sky_far_layer: ParallaxLayer
var _sky_mid_layer: ParallaxLayer
var _sky_atmo_layer: ParallaxLayer


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
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.46, 0.76, 0.94, 1.0), Color(0.76, 0.90, 0.98, 1.0)])
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill_from = Vector2(0.5, 0.0)
	grad_tex.fill_to = Vector2(0.5, 1.0)
	grad_tex.width = 64
	grad_tex.height = 256

	_sky_parallax = ParallaxBackground.new()
	_sky_parallax.layer = -10
	var sky_base := CanvasLayer.new()
	sky_base.layer = -11
	add_child(sky_base)
	_sky_rect = TextureRect.new()
	_sky_rect.name = "SkyBackdrop"
	_sky_rect.texture = grad_tex
	_sky_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sky_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_base.add_child(_sky_rect)
	_sky_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_sky_far_layer = ParallaxLayer.new()
	_sky_far_layer.motion_scale = Vector2(0.18, 0.12)
	_sky_parallax.add_child(_sky_far_layer)
	_sky_mid_layer = ParallaxLayer.new()
	_sky_mid_layer.motion_scale = Vector2(0.32, 0.22)
	_sky_parallax.add_child(_sky_mid_layer)
	_sky_atmo_layer = ParallaxLayer.new()
	_sky_atmo_layer.motion_scale = Vector2(0.45, 0.30)
	_sky_parallax.add_child(_sky_atmo_layer)
	add_child(_sky_parallax)

	_terrain_root = Node2D.new()
	_terrain_root.name = "ArenaVisuals"
	_terrain_root.z_index = -10
	add_child(_terrain_root)

	_deco_layer = Node2D.new()
	_deco_layer.name = "PerimeterDecorations"
	_terrain_root.add_child(_deco_layer)

	var sort_root := get_node_or_null("../YSort")
	if sort_root != null:
		_foreground_props = Node2D.new()
		_foreground_props.name = "IslandProps"
		_foreground_props.y_sort_enabled = true
		sort_root.add_child(_foreground_props)


func _rebuild_visuals() -> void:
	_ensure_layers()
	for layer in [_deco_layer, _sky_far_layer, _sky_mid_layer, _sky_atmo_layer]:
		for child in layer.get_children():
			layer.remove_child(child)
			child.queue_free()
	if _foreground_props != null:
		for prop in _foreground_props.get_children():
			_foreground_props.remove_child(prop)
			prop.queue_free()
	_island_outline.clear()
	_inset_outlines.clear()
	_pillar_positions.clear()

	match scene_theme:
		"seamless_journey":
			_build_seamless_journey()
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


func _add_surface(outline: PackedVector2Array, path: Curve2D,
		arena_radii: Vector2 = Vector2.ZERO, path_width: float = 70.0) -> void:
	var surface := IslandSurface.new()
	_deco_layer.add_child(surface)
	surface.build(outline, path, arena_radii, path_width)


func _make_iso_island(center: Vector2, radii: Vector2, steps: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps):
		var a := i * TAU / float(steps)
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	return pts


func _make_bridge_poly(a: Vector2, b: Vector2, half_width: float = 72.0) -> PackedVector2Array:
	var dir := (b - a).normalized()
	var perp := Vector2(-dir.y, dir.x) * half_width
	return PackedVector2Array([a - perp, b - perp, b + perp, a + perp])


func _build_seamless_journey() -> void:
	_sky_rect.modulate = Color(0.97, 0.99, 1.0)
	var zones := [
		{"center": Vector2(0, 0), "radii": Vector2(540, 310), "stone": Vector2.ZERO},
		{"center": Vector2(1450, -320), "radii": Vector2(640, 360), "stone": Vector2.ZERO},
		{"center": Vector2(2980, -700), "radii": Vector2(640, 360), "stone": Vector2(460, 250)},
		{"center": Vector2(4620, -1120), "radii": Vector2(720, 410), "stone": Vector2(540, 300)},
		{"center": Vector2(6120, -1480), "radii": Vector2(520, 300), "stone": Vector2(380, 210)},
	]
	var bridges := [
		[Vector2(470, -100), Vector2(890, -200)],
		[Vector2(1990, -450), Vector2(2430, -560)],
		[Vector2(3520, -830), Vector2(4000, -960)],
		[Vector2(5230, -1270), Vector2(5690, -1380)],
	]

	var merged := _make_iso_island(zones[0]["center"], zones[0]["radii"])
	for idx in range(zones.size()):
		var z: Dictionary = zones[idx]
		var z_poly := _make_iso_island(z["center"], z["radii"])
		var path := Curve2D.new()
		if idx < 2:
			path.add_point(z["center"] + Vector2(-z["radii"].x * 0.75, 40))
			path.add_point(z["center"] + Vector2(z["radii"].x * 0.75, -40))
		_add_surface(z_poly, path, z["stone"], 76.0)
		if idx > 0:
			var m1 := Geometry2D.merge_polygons(merged, z_poly)
			if not m1.is_empty():
				merged = m1[0]

	for b in bridges:
		var a_pt: Vector2 = b[0]
		var b_pt: Vector2 = b[1]
		var b_poly := _make_bridge_poly(a_pt, b_pt, 76.0)
		var m2 := Geometry2D.merge_polygons(merged, b_poly)
		if not m2.is_empty():
			merged = m2[0]
		var mid := (a_pt + b_pt) * 0.5
		_add_deco("res://assets/environment/bridge_stone_01/base.png", mid, 1.55)
		_add_deco("res://assets/props/lantern_01/base.png", a_pt + Vector2(-35, -75), 0.72)
		_add_deco("res://assets/props/lantern_01/base.png", b_pt + Vector2(35, 75), 0.72)

	_island_outline = merged

	# Zone 1: Làng Thanh Vân
	_add_deco("res://assets/environment/tree_peach_01/base.png", Vector2(-320, -130), 1.15)
	_add_deco("res://assets/environment/tree_green_01/base.png", Vector2(280, -160), 1.15)
	_add_deco("res://assets/environment/rock_moss_01/base.png", Vector2(-240, 150), 0.9)

	# Zone 2: Ngoại Vi Thanh Vân
	_add_deco("res://assets/environment/tree_green_01/base.png", Vector2(1150, -490), 1.2)
	_add_deco("res://assets/environment/tree_peach_01/base.png", Vector2(1740, -150), 1.15)
	_add_deco("res://assets/environment/rock_moss_01/base.png", Vector2(1380, -110), 0.95)
	_add_deco("res://assets/environment/rock_moss_01/base.png", Vector2(1690, -460), 0.85)

	# Zone 3 & Zone 4: Trụ Rune
	for c in [Vector2(2980, -700), Vector2(4620, -1120)]:
		_pillar_positions.append(c + Vector2(-310, -140))
		_pillar_positions.append(c + Vector2(310, -140))
		_pillar_positions.append(c + Vector2(-340, 140))
		_pillar_positions.append(c + Vector2(340, 140))

	# Zone 5: Cổng Thiên Giới & Rương thưởng
	_add_deco("res://assets/environment/tree_peach_01/base.png", Vector2(5880, -1610), 1.15)
	_add_deco("res://assets/props/chest_reward_01/base.png", Vector2(5980, -1420), 0.9)
	_add_sky_backdrop(true)


func _build_mortal_realm() -> void:
	_sky_rect.modulate = Color.WHITE
	rx = 640.0
	ry = 322.0
	_island_outline = PackedVector2Array([
		Vector2(-632, -148), Vector2(-480, -280), Vector2(-236, -318),
		Vector2(140, -303), Vector2(395, -263), Vector2(558, -169),
		Vector2(639, -32), Vector2(568, 132), Vector2(354, 257),
		Vector2(8, 310), Vector2(-303, 275), Vector2(-553, 162), Vector2(-660, 35),
	])
	var path := Curve2D.new()
	path.add_point(Vector2(-243, 279), Vector2.ZERO, Vector2(55, -84))
	path.add_point(Vector2(-30, 84), Vector2(-77, 30), Vector2(113, -39))
	path.add_point(Vector2(315, -98), Vector2(-105, 49))
	_add_surface(_island_outline, path, Vector2.ZERO, 111.0)
	_add_deco("res://assets/base/environment/architecture/arch_village_house_01.png", Vector2(-272, -45), 1.48)
	_add_deco("res://assets/base/environment/decorations/deco_peach_bonsai_01.png", Vector2(-487, -65), 1.27)
	_add_deco("res://assets/base/environment/decorations/deco_wooden_fence_01.png", Vector2(-396, 125))
	_add_deco("res://assets/base/environment/decorations/deco_wooden_fence_01.png", Vector2(334, 194))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(197, -92))
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(429, 98))
	_add_sky_backdrop()


func _build_stairway_clouds() -> void:
	_sky_rect.modulate = Color(0.95, 0.98, 1.0)
	rx = 710.0
	ry = 326.0
	# A single straight bridge strip overlaps both shorelines at the walkable surface.
	var left := PackedVector2Array([
		Vector2(-704, -82), Vector2(-552, -158), Vector2(-339, -135),
		Vector2(-197, -66), Vector2(-150, 26), Vector2(-175, 171),
		Vector2(-301, 276), Vector2(-536, 287), Vector2(-690, 179),
	])
	var right := PackedVector2Array([
		Vector2(143, -119), Vector2(277, -243), Vector2(492, -282),
		Vector2(657, -202), Vector2(723, -57), Vector2(621, 114),
		Vector2(456, 159), Vector2(224, 142), Vector2(144, 68),
	])
	const BRIDGE_ANGLE := -0.22
	var deck := Rect2(-230, -68, 470, 136)
	var bridge := PackedVector2Array([
		deck.position.rotated(BRIDGE_ANGLE), Vector2(deck.end.x, deck.position.y).rotated(BRIDGE_ANGLE),
		deck.end.rotated(BRIDGE_ANGLE), Vector2(deck.position.x, deck.end.y).rotated(BRIDGE_ANGLE),
	])
	var left_path := Curve2D.new()
	left_path.add_point(Vector2(-586, 136))
	left_path.add_point(Vector2(-175, 39))
	var right_path := Curve2D.new()
	right_path.add_point(Vector2(166, -37))
	right_path.add_point(Vector2(625, -135))
	_add_surface(left, left_path)
	_add_surface(right, right_path)
	var span := IslandSurface.new()
	_deco_layer.add_child(span)
	span.rotation = BRIDGE_ANGLE
	span.build_bridge(deck)
	var joined := Geometry2D.merge_polygons(left, bridge)
	assert(joined.size() == 1, "Bridge must meet the western island")
	var full := Geometry2D.merge_polygons(joined[0], right)
	assert(full.size() == 1, "Bridge must meet the eastern island")
	_island_outline = full[0]
	_add_deco("res://assets/base/environment/decorations/deco_peach_bonsai_01.png", Vector2(-484, -25), 1.22)
	_add_deco("res://assets/base/environment/decorations/deco_green_tree_01.png", Vector2(558, -134), 1.20)
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(-362, 221))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(377, 103))
	_add_sky_backdrop(true)


func _painted_prop(art: Texture2D, foot: Vector2, size_factor: float) -> void:
	var props := _foreground_props if _foreground_props != null else _deco_layer
	PaintedSprite.place(props, art, foot, size_factor, true)


func _build_azure_outskirts() -> void:
	_sky_rect.modulate = Color(0.96, 0.98, 1.0)
	_island_outline = PackedVector2Array([
		Vector2(-620, -225), Vector2(-510, -315), Vector2(-320, -349),
		Vector2(-107, -344), Vector2(95, -371), Vector2(319, -338),
		Vector2(534, -254), Vector2(636, -128), Vector2(649, 18),
		Vector2(570, 153), Vector2(401, 241), Vector2(235, 261),
		Vector2(60, 310), Vector2(-189, 319), Vector2(-404, 295),
		Vector2(-553, 222), Vector2(-631, 117), Vector2(-661, -33),
	])
	var path := Curve2D.new()
	path.add_point(Vector2(-585, 207), Vector2.ZERO, Vector2(117, 11))
	path.add_point(Vector2(-304, 126), Vector2(-77, 62), Vector2(91, -62))
	path.add_point(Vector2(11, 13), Vector2(-100, 22), Vector2(110, -23))
	path.add_point(Vector2(360, -83), Vector2(-85, 42), Vector2(84, -36))
	path.add_point(Vector2(585, -170), Vector2(-65, 21))

	_add_surface(_island_outline, path)
	_add_deco("res://assets/base/environment/decorations/deco_green_tree_01.png", Vector2(-425, -181), 1.39)
	_add_deco("res://assets/base/environment/decorations/deco_peach_bonsai_01.png", Vector2(-470, 173), 1.22)
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(-565, -130))
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(516, 135), 1.20)
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(262, -288), 0.9)
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(-274, 252), 1.18)
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(401, 193), 1.24)
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(-232, -270), 1.08)
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(459, -214), 0.85)
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(343, 212), 0.7)
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(-216, -247), 0.62)
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(132, -305), 0.59)
	_add_parallax_sprite(_sky_far_layer, "res://assets/base/environment/decorations/bg_distant_island_01.png", Vector2(134, 165), 0.73, 0.69)
	var cloud := "res://assets/base/environment/decorations/bg_cloud_bank_01.png"
	_add_parallax_sprite(_sky_mid_layer, cloud, Vector2(1070, 125), 2.5, 0.54)
	_add_parallax_sprite(_sky_mid_layer, cloud, Vector2(100, 370), 2.4, 0.75)
	_add_parallax_sprite(_sky_mid_layer, cloud, Vector2(980, 608), 3.2, 0.85)
	_add_parallax_sprite(_sky_atmo_layer, cloud, Vector2(348, 610), 3.1, 0.84)


func _build_azure_center() -> void:
	_sky_rect.modulate = Color(0.90, 0.95, 1.0)
	_build_courtyard(Vector2(580, 320))
	_pillar_positions = [Vector2(-330, -148), Vector2(330, -148),
		Vector2(-361, 149), Vector2(361, 149)]
	_add_deco("res://assets/base/environment/decorations/deco_green_tree_01.png", Vector2(-459, -88), 1.10)
	_add_deco("res://assets/base/environment/decorations/deco_peach_bonsai_01.png", Vector2(-449, 140), 1.05)
	_add_deco("res://assets/base/environment/decorations/deco_incense_brazier_01.png", Vector2(313, -60))
	_add_sky_backdrop()


func _build_courtyard(radii: Vector2) -> void:
	rx = radii.x
	ry = radii.y
	for index in range(36):
		var angle := index * TAU / 36.0
		var edge := Vector2.from_angle(angle) * radii
		_island_outline.append(edge * (1.0 + sin(angle * 7.0) * 0.025))
	_add_surface(_island_outline, null, radii - Vector2(50, 39))


func _build_boss_arena() -> void:
	_sky_rect.modulate = Color(0.91, 0.96, 1.0)
	_build_courtyard(Vector2(650, 362))
	_pillar_positions = [
		Vector2(-387, -199), Vector2(387, -199),
		Vector2(-425, 173), Vector2(425, 173),
	]
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(-543, 95))
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(500, 140))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(-190, 308))
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(320, 267))
	_add_sky_backdrop()


func _build_gate_of_heaven() -> void:
	_sky_rect.modulate = Color.WHITE
	rx = 455.0
	ry = 327.0
	_island_outline = PackedVector2Array([
		Vector2(-437, -104), Vector2(-365, -227), Vector2(-192, -304),
		Vector2(21, -327), Vector2(204, -308), Vector2(390, -232),
		Vector2(462, -91), Vector2(441, 57), Vector2(340, 167),
		Vector2(204, 250), Vector2(32, 285), Vector2(-174, 274),
		Vector2(-325, 210), Vector2(-427, 82),
	])
	var path := Curve2D.new()
	path.add_point(Vector2(-175, 280), Vector2.ZERO, Vector2(24, -80))
	path.add_point(Vector2(-89, 91), Vector2(-38, 67), Vector2(49, -79))
	path.add_point(Vector2(58, -208), Vector2(-11, 74))
	_add_surface(_island_outline, path, Vector2.ZERO, 115.0)
	_add_deco("res://assets/base/environment/decorations/deco_peach_bonsai_01.png", Vector2(-313, -121), 1.35)
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(-203, -65), 1.3)
	_add_deco("res://assets/base/environment/decorations/deco_cloud_lantern_01.png", Vector2(274, -157), 1.3)
	_add_deco("res://assets/base/props/prop_reward_chest_01.png", Vector2(-257, 82), 1.2)
	_add_deco("res://assets/base/environment/decorations/deco_cloud_rock_01.png", Vector2(260, 164), 1.35)
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(-283, 182))
	_add_deco("res://assets/base/environment/decorations/deco_bush_01.png", Vector2(321, 84))
	_add_sky_backdrop()


func _add_parallax_sprite(layer: ParallaxLayer, res_path: String, pos: Vector2, scale_val: float = 1.0, alpha: float = 1.0) -> void:
	if not ResourceLoader.exists(res_path):
		return
	var sp := Sprite2D.new()
	sp.texture = load(res_path)
	sp.position = pos
	sp.scale = Vector2(scale_val, scale_val)
	sp.modulate.a = alpha
	layer.add_child(sp)


func _add_sky_backdrop(center_island: bool = false) -> void:
	# ParallaxLayer coordinates are relative to viewport top-left (1280x720)
	# L1 — Far Islands (0.18, 0.12)
	if center_island:
		_add_parallax_sprite(_sky_far_layer, "res://assets/base/environment/decorations/bg_distant_island_01.png", Vector2(640, 140), 0.95, 0.95)
	else:
		_add_parallax_sprite(_sky_far_layer, "res://assets/base/environment/decorations/bg_distant_island_01.png", Vector2(150, 160), 0.85, 0.92)
		_add_parallax_sprite(_sky_far_layer, "res://assets/base/environment/decorations/bg_distant_island_01.png", Vector2(1130, 150), 0.80, 0.90)
	# L2 — Mid Cloud Banks (0.32, 0.22)
	_add_parallax_sprite(_sky_mid_layer, "res://assets/base/environment/decorations/bg_cloud_bank_01.png", Vector2(120, 460), 1.35, 0.88)
	_add_parallax_sprite(_sky_mid_layer, "res://assets/base/environment/decorations/bg_cloud_bank_01.png", Vector2(1160, 440), 1.35, 0.88)
	_add_parallax_sprite(_sky_mid_layer, "res://assets/base/environment/decorations/bg_cloud_bank_01.png", Vector2(360, 650), 1.5, 0.95)
	_add_parallax_sprite(_sky_mid_layer, "res://assets/base/environment/decorations/bg_cloud_bank_01.png", Vector2(920, 650), 1.5, 0.95)
	# L3 — Atmospheric Cloud Wisps (0.45, 0.30)
	_add_parallax_sprite(_sky_atmo_layer, "res://assets/base/environment/decorations/bg_cloud_bank_01.png", Vector2(260, 110), 1.6, 0.24)
	_add_parallax_sprite(_sky_atmo_layer, "res://assets/base/environment/decorations/bg_cloud_bank_01.png", Vector2(1020, 120), 1.6, 0.24)


const LEGACY_DECO_MAP := {
	"deco_green_tree_01.png": "res://assets/environment/tree_green_01/base.png",
	"deco_peach_bonsai_01.png": "res://assets/environment/tree_peach_01/base.png",
	"deco_cloud_rock_01.png": "res://assets/environment/rock_moss_01/base.png",
	"deco_cloud_lantern_01.png": "res://assets/props/lantern_01/base.png",
	"prop_reward_chest_01.png": "res://assets/props/chest_reward_01/base.png",
	"bridge_stone_01.png": "res://assets/environment/bridge_stone_01/base.png",
}


func _add_deco(res_path: String, pos: Vector2, scale_val: float = 1.0) -> void:
	var mapped := res_path
	var fname := res_path.get_file()
	if LEGACY_DECO_MAP.has(fname):
		mapped = LEGACY_DECO_MAP[fname]
	if not ResourceLoader.exists(mapped):
		return
	var sp := Sprite2D.new()
	sp.texture = load(mapped)
	sp.position = pos
	sp.scale = Vector2.ONE * scale_val
	if _foreground_props == null:
		_deco_layer.add_child(sp)
		return

	# Preserve the authored center while sorting at the visible ground contact.
	var height := sp.texture.get_height()
	var contact := height * 0.5 - (20 if height >= 192 else 14)
	sp.position.y += contact * scale_val
	sp.offset.y = -contact
	_foreground_props.add_child(sp)


func _spawn_pillars() -> void:
	var obstacles_node := get_node_or_null("../YSort/Obstacles")
	if obstacles_node == null:
		return
	for child in obstacles_node.get_children():
		child.queue_free()

	const PILLAR_TEX := preload("res://assets/props/pillar_rune_01/base.png")

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
		visual.texture = PILLAR_TEX
		visual.offset = Vector2(0, -86)
		pillar.add_child(visual)
		obstacles_node.add_child(pillar)


func clamp_to_arena(pos: Vector2, margin: float = 28.0) -> Vector2:
	if not _island_outline.is_empty():
		if not _inset_outlines.has(margin):
			_inset_outlines[margin] = Geometry2D.offset_polygon(_island_outline, -maxf(margin, 0.0))
		var insets: Array = _inset_outlines[margin]
		# Large clearance requests can close a bridge neck. Retain both islands.
		if insets.is_empty():
			insets = [_island_outline]
		var best := Vector2.ZERO
		var best_distance := INF
		for inset: PackedVector2Array in insets:
			if Geometry2D.is_point_in_polygon(pos, inset):
				return pos
			for index in range(inset.size()):
				var candidate := Geometry2D.get_closest_point_to_segment(pos, inset[index], inset[(index + 1) % inset.size()])
				var distance := pos.distance_squared_to(candidate)
				if distance < best_distance:
					best = candidate
					best_distance = distance
		return best

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
		if pt.length() >= min_dist_from_center and clamp_to_arena(pt, 48.0).is_equal_approx(pt):
			return pt
	return clamp_to_arena(Vector2(rx * 0.6, 0.0), 48.0)
