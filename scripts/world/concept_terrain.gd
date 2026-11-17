class_name ConceptTerrain
extends Node2D
## Textured surfaces clipped to the semantic walkable boundary; scenery has no collision.
const L = preload("res://scripts/world/hoa_qua_son_layout.gd")
const BASE = "res://assets/sprites/concept/"

func _ready() -> void:
	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([Vector2(-3000,-3000),Vector2(6000,-3000),Vector2(6000,3000),Vector2(-3000,3000)])
	sky.color = Color("b8d4e3")
	sky.z_index = -40
	add_child(sky)
	var boundary := PackedVector2Array(L.WALKABLE_BOUNDARY)
	for x in range(-650,3000,550):
		sprite("distant_mountain_layer",Vector2(x,-470-x*0.42),850,-32)
	surface(boundary,"terrain_grass_fill",-10,1.2)
	for route in [L.MAIN_PATH_POINTS,L.SECRET_BRANCH_POINTS]:
		var width := 47.0 if route == L.SECRET_BRANCH_POINTS else 66.0
		for shape in Geometry2D.offset_polyline(PackedVector2Array(route),width,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):
			for clipped in Geometry2D.intersect_polygons(shape,boundary):
				surface(clipped,"terrain_dirt_fill",-8,1.3)
	for area in [Vector3(30,-25,190),Vector3(1175,-280,90),Vector3(1465,-815,205)]:
		var points := ellipse(Vector2(area.x,area.y),Vector2(area.z,area.z*0.6))
		for clipped in Geometry2D.intersect_polygons(points,boundary):
			surface(clipped,"terrain_dirt_fill",-7,1.3)
	surface(ellipse(Vector2(2200,-1100),Vector2(260,145)),"cave_floor_fill",-6,1.0)
	# Continuous textured rock faces follow the exact semantic edge.
	for i in 16:
		var a: Vector2 = boundary[i]
		var b: Vector2 = boundary[(i+1)%boundary.size()]
		var wall := Polygon2D.new()
		wall.polygon = PackedVector2Array([a+Vector2(0,-8),b+Vector2(0,-8),b+Vector2(0,215),a+Vector2(0,215)])
		var length := a.distance_to(b)*1.3
		wall.uv = PackedVector2Array([Vector2(0,0),Vector2(length,0),Vector2(length,256),Vector2(0,256)])
		wall.texture = load(BASE+"cliff_face_strip.png")
		wall.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		wall.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		wall.z_index = -12
		add_child(wall)
	for pos in L.WATERFALLS:
		sprite("waterfall_long",pos+Vector2(0,130),65,-5,Vector2(1,1.7))
		sprite("waterfall_crest",pos+Vector2(0,12),95,-4)
		sprite("waterfall_mist",pos+Vector2(0,270),120,-4)
	for pos in [Vector2(-220,300),Vector2(360,220),Vector2(1120,120),Vector2(1730,-360),Vector2(2460,-700)]:
		sprite("cloud_bank",pos,400,-3).modulate.a = 0.8
	var rng := RandomNumberGenerator.new()
	rng.seed = 5005
	for i in 70:
		var point := Vector2(rng.randf_range(-260,2400),rng.randf_range(-1250,120))
		if Geometry2D.is_point_in_polygon(point,boundary) and point.distance_to(Vector2(2200,-1100)) > 290.0:
			sprite("flower_daisy_cluster",point, rng.randf_range(22,32),-2)
	for tree in L.PEACH_TREES:
		sprite("petal_scatter",tree+Vector2(5,8),64,-2)
	# Authored curve/fork sprites remain available; semantic path polygons control this winding route.
	sprite("stream_extension",L.BRIDGE_POS+Vector2(5,5),155,-3)

func surface(points: PackedVector2Array, asset: String, depth: int, uv_scale: float) -> void:
	var poly := Polygon2D.new()
	poly.polygon = points
	var coords := PackedVector2Array()
	for point in points:
		coords.append(point*uv_scale)
	poly.uv = coords
	poly.texture = load(BASE+asset+".png")
	poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	poly.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	poly.z_index = depth
	add_child(poly)

func sprite(asset: String, pos: Vector2, width: float, depth: int, stretch: Vector2 = Vector2.ONE) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load(BASE+asset+".png")
	sp.position = pos
	sp.scale = Vector2.ONE*width/sp.texture.get_width()*stretch
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sp.z_index = depth
	add_child(sp)
	return sp

func ellipse(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 64:
		var angle := TAU*i/64.0
		points.append(center+Vector2(cos(angle),sin(angle))*radius)
	return points

func mark_boss_cleared() -> void:
	var path := Line2D.new()
	path.points = PackedVector2Array([L.BOSS_CHEST_POS, L.BOSS_EXIT_POS])
	path.width = 3.0
	path.default_color = Color(1.0, 0.8, 0.3, 0.65)
	path.z_index = -1
	add_child(path)
