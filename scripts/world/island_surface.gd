extends Node2D
## A repeatable terrain material, cliff segments and paving clipped to an authored shoreline.

const SURFACE := preload("res://scripts/world/island_surface.gdshader")
const GRASS_TEX := preload("res://assets/environment/tile_grass_01/base.png")
const STONE_TEX := preload("res://assets/environment/tile_stone_01/base.png")
const PATH_TEX := preload("res://assets/environment/tile_stone_01/base.png")
const CLIFF_TEX := preload("res://assets/environment/cliff_edge_01/base.png")

var _random := RandomNumberGenerator.new()


func build(outline: PackedVector2Array, path: Curve2D, arena_radii: Vector2 = Vector2.ZERO, path_width: float = 70.0) -> void:
	_random.seed = 319
	var bounds := _bounds(outline)
	var center := bounds.get_center()
	var foundation := PackedVector2Array()
	for point in outline:
		foundation.append(center + (point - center) * Vector2(0.83, 0.95) + Vector2(-12, 93))
	_polygon(foundation, Color(0.86, 0.85, 0.92), null, CLIFF_TEX, Vector2(0.75, 0.75))
	for index in range(outline.size()):
		var start := outline[index]
		var end := outline[(index + 1) % outline.size()]
		if end.x >= start.x:
			continue
		var panels := maxi(1, roundi(start.distance_to(end) / 65.0))
		for panel in range(panels):
			var a := start.lerp(end, float(panel) / panels)
			var b := start.lerp(end, float(panel + 1) / panels)
			var relative_x := absf(((a.x + b.x) * 0.5 - center.x) / (bounds.size.x * 0.5))
			var depth := 56.0 + (1.0 - relative_x) * 115.0 + _random.randf_range(-27, 20)
			var foot := (a + b) * 0.5 + Vector2(_random.randf_range(-42, -14), depth)
			var seam := b + Vector2(-18, depth * 0.72)
			_polygon(PackedVector2Array([a, b, seam, foot, a + Vector2(-18, depth * 0.62)]), Color.WHITE, null, CLIFF_TEX, Vector2(0.75, 0.75))
			_polygon(PackedVector2Array([a, a.lerp(b, 0.42), foot, a + Vector2(-18, depth * 0.62)]),
				Color(0.22, 0.24, 0.39, _random.randf_range(0.15, 0.37)))
	_polygon(outline, Color.WHITE, null, GRASS_TEX, Vector2(1.15, 1.15))
	if arena_radii != Vector2.ZERO:
		_build_courtyard(arena_radii)
	else:
		_pave(outline, path, path_width)
		_add_grass_details(outline, path)
	_add_rim(outline)



func build_bridge(deck: Rect2) -> void:
	_rectangle(Rect2(deck.position + Vector2(0, 6), deck.size + Vector2(0, 27)), Color("#646279"))
	_rectangle(Rect2(deck.position, deck.size + Vector2(0, 15)), Color("#a08b78"))
	_rectangle(deck, Color("#a08b78"))
	for row in range(4):
		var x := deck.position.x - (row & 1) * 29.0
		while x < deck.end.x:
			var slab := Rect2(x + 1, deck.position.y + row * 34.0 + 1, 56.0, 32.0)
			_rectangle(slab.intersection(deck), Color.WHITE, null, STONE_TEX, Vector2(1.1, 1.1))
			x += 58.0
	for y in [deck.position.y, deck.end.y]:
		_rectangle(Rect2(deck.position.x, y - 5, deck.size.x, 10), Color("#857466"))
		_rectangle(Rect2(deck.position.x, y - 11, deck.size.x, 7), Color.WHITE, null, STONE_TEX, Vector2(1.1, 1.1))
		for x in [deck.position.x + 14, deck.position.x + 151, deck.end.x - 151, deck.end.x - 14]:
			_rectangle(Rect2(x - 10, y - 26, 20, 33), Color("#a58d77"))
			_rectangle(Rect2(x - 12, y - 29, 24, 9), Color.WHITE, null, STONE_TEX, Vector2(1.1, 1.1))


func _rectangle(rect: Rect2, tint: Color, surface: ShaderMaterial = null, tex: Texture2D = null, tex_scale: Vector2 = Vector2.ONE) -> void:
	_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)]), tint, surface, tex, tex_scale)


func _build_courtyard(radii: Vector2) -> void:
	var edging := _ellipse_sector(radii, 0.0, TAU, 0.0, 1.04, 72)
	_polygon(edging, Color(0.88, 0.84, 0.80), null, PATH_TEX, Vector2(1.15, 1.15))
	for row in range(11):
		var outer := (row + 1) / 11.0
		var inner := row / 11.0
		var count := maxi(6, roundi(outer * 62.0))
		var step := TAU / count
		for column in range(count):
			var start := (column + (row & 1) * 0.5) * step
			var slab := _ellipse_sector(radii, start + 0.002, start + step - 0.002,
				inner + 0.002, outer - 0.003, 3)
			_polygon(slab, Color.WHITE, null, STONE_TEX, Vector2(1.15, 1.15))
			_polygon(slab, Color(0.36, 0.23, 0.20, _random.randf_range(0, 0.16)))
	for radius in [0.24, 0.26, 0.93, 0.96, 1.02]:
		var band := Line2D.new()
		band.points = _ellipse_sector(radii, 0.0, TAU, radius, radius, 72).slice(0, 73)
		band.width = 1.8 if radius < 1.0 else 3.0
		band.default_color = Color("#e4cfac")
		band.antialiased = true
		add_child(band)


func _ellipse_sector(radii: Vector2, start: float, end: float, inner: float,
		outer: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps + 1):
		var angle := lerpf(start, end, float(index) / steps)
		points.append(Vector2.from_angle(angle) * radii * outer)
	if is_zero_approx(inner):
		points.resize(points.size() - int(is_equal_approx(end - start, TAU)))
		if not is_equal_approx(end - start, TAU):
			points.append(Vector2.ZERO)
	else:
		for index in range(steps, -1, -1):
			var angle := lerpf(start, end, float(index) / steps)
			points.append(Vector2.from_angle(angle) * radii * inner)
	return points


func _add_rim(outline: PackedVector2Array) -> void:
	var moss := _material(Color("#526a2d"), Color("#a1b648"), Vector2(1.0, 1.8))
	for index in range(outline.size()):
		var start := outline[index]
		var end := outline[(index + 1) % outline.size()]
		if end.x >= start.x:
			continue
		var tufts := maxi(1, roundi(start.distance_to(end) / 15.0))
		var rim := PackedVector2Array([start, end])
		for tuft in range(tufts, 0, -1):
			var t := (float(tuft) - 0.5) / tufts
			var base := start.lerp(end, t)
			rim.append(base + Vector2(-3, _random.randf_range(4, 19)))
			rim.append(start.lerp(end, float(tuft - 1) / tufts) + Vector2(0, 2))
		_polygon(rim, Color.WHITE, moss)


func _material(low: Color, high: Color, grain_scale: Vector2) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SURFACE
	material.set_shader_parameter("low_color", low)
	material.set_shader_parameter("high_color", high)
	material.set_shader_parameter("grain_scale", grain_scale)
	return material


func _polygon(points: PackedVector2Array, tint: Color, surface: ShaderMaterial = null, tex: Texture2D = null, tex_scale: Vector2 = Vector2.ONE) -> void:
	var shape := Polygon2D.new()
	shape.polygon = points
	shape.color = tint
	shape.material = surface
	if tex != null:
		shape.texture = tex
		shape.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		shape.texture_scale = tex_scale
		shape.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	shape.antialiased = true
	add_child(shape)


func _pave(outline: PackedVector2Array, path: Curve2D, path_width: float) -> void:
	var bounds := _bounds(outline)
	for row in range(floori(bounds.position.y / 25.0), ceili(bounds.end.y / 25.0)):
		for column in range(floori(bounds.position.x / 53.0), ceili(bounds.end.x / 53.0)):
			var center := Vector2(column * 53.0 + (row & 1) * 26.0, row * 25.0)
			center += Vector2(_random.randf_range(-5, 5), _random.randf_range(-3, 3))
			if not Geometry2D.is_point_in_polygon(center, outline):
				continue
			if center.distance_to(path.get_closest_point(center)) > path_width * _random.randf_range(0.53, 1.0):
				continue
			var width := _random.randf_range(19, 28)
			var stone := PackedVector2Array([
				center + Vector2(-width, -5), center + Vector2(-width + 6, -12),
				center + Vector2(width - 5, _random.randf_range(-15, -8)), center + Vector2(width, -3),
				center + Vector2(width - 4, 9), center + Vector2(-width + 3, _random.randf_range(8, 14)),
			])
			for piece in Geometry2D.intersect_polygons(stone, outline):
				_polygon(piece, Color.WHITE, null, PATH_TEX, Vector2(1.1, 1.1))
				var highlight := PackedVector2Array([stone[0], stone[1], stone[2], stone[2] + Vector2(-5, 3), stone[1] + Vector2(2, 3)])
				for lip in Geometry2D.intersect_polygons(highlight, outline):
					_polygon(lip, Color(1.0, 0.96, 0.82, 0.32))


func _bounds(outline: PackedVector2Array) -> Rect2:
	var bounds := Rect2(outline[0], Vector2.ZERO)
	for point in outline:
		bounds = bounds.expand(point)
	return bounds


func _add_grass_details(outline: PackedVector2Array, path: Curve2D) -> void:
	var bounds := _bounds(outline)
	var details := MultiMeshInstance2D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(3.2, 1.9)
	details.multimesh = MultiMesh.new()
	details.multimesh.transform_format = MultiMesh.TRANSFORM_2D
	details.multimesh.use_colors = true
	details.multimesh.mesh = mesh
	var points := PackedVector2Array()
	for index in range(3400):
		var point := Vector2(_random.randf_range(bounds.position.x, bounds.end.x),
			_random.randf_range(bounds.position.y, bounds.end.y))
		if Geometry2D.is_point_in_polygon(point, outline) and point.distance_to(path.get_closest_point(point)) > 56.0:
			points.append(point)
	details.multimesh.instance_count = points.size()
	for index in range(points.size()):
		details.multimesh.set_instance_transform_2d(index, Transform2D(_random.randf_range(-0.7, 0.7), points[index]))
		var tint := Color("#f5e7a5") if index % 3 == 0 else Color("#6c853c")
		tint.a = _random.randf_range(0.19, 0.64)
		details.multimesh.set_instance_color(index, tint)
	add_child(details)
