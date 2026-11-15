extends Node2D
class_name CloudArena

## 2.5D Isometric Floating Cloud Island arena with rune tiles, obstacles,
## boundary enforcement, and ambient drifting cloud wisps.

@export var rx: float = 880.0
@export var ry: float = 480.0

var _wisps: Array[Dictionary] = []
var _time: float = 0.0
var _pillar_positions: Array[Vector2] = [
	Vector2(-380, -160),
	Vector2(380, -160),
	Vector2(-380, 160),
	Vector2(380, 160),
]


func configure(arena_rx: float, arena_ry: float) -> void:
	rx = arena_rx
	ry = arena_ry
	queue_redraw()


func _ready() -> void:
	_init_wisps()
	_spawn_pillars()
	queue_redraw()


func _init_wisps() -> void:
	_wisps.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4201
	for i in range(18):
		_wisps.append({
			"pos": Vector2(rng.randf_range(-rx * 1.15, rx * 1.15), rng.randf_range(-ry * 1.15, ry * 1.15)),
			"speed": rng.randf_range(14.0, 32.0),
			"radius": rng.randf_range(26.0, 62.0),
			"alpha": rng.randf_range(0.08, 0.2),
		})


func _spawn_pillars() -> void:
	var obstacles_node := get_node_or_null("../YSort/Obstacles")
	if obstacles_node == null:
		return
	for child in obstacles_node.get_children():
		child.queue_free()

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

		var visual := _PillarVisual.new()
		pillar.add_child(visual)
		obstacles_node.add_child(pillar)


func _process(delta: float) -> void:
	_time += delta
	for w in _wisps:
		w["pos"].x += float(w["speed"]) * delta
		if w["pos"].x > rx * 1.25:
			w["pos"].x = -rx * 1.25
	queue_redraw()


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
	# Deep sky backdrop
	draw_rect(Rect2(-rx * 1.8, -ry * 1.8, rx * 3.6, ry * 3.6), Color(0.07, 0.11, 0.22, 1.0))

	# Underside cloud shadow / floating island thickness
	_draw_ellipse(Vector2(0, 42), rx * 1.02, ry * 1.02, Color(0.14, 0.22, 0.38, 0.9))
	_draw_ellipse(Vector2(0, 22), rx * 1.01, ry * 1.01, Color(0.72, 0.85, 0.96, 0.45))

	# Outer cloud rim puffs
	var puff_count := 36
	for i in range(puff_count):
		var a := (float(i) / puff_count) * TAU
		var bob := sin(_time * 1.3 + float(i)) * 3.0
		var p := Vector2(cos(a) * rx * 0.99, sin(a) * ry * 0.99 + bob)
		draw_circle(p, 52.0, Color(0.86, 0.94, 1.0, 0.32))

	# Main jade-stone cloud platform
	_draw_ellipse(Vector2.ZERO, rx, ry, Color(0.18, 0.27, 0.40, 1.0))
	_draw_ellipse(Vector2.ZERO, rx * 0.96, ry * 0.96, Color(0.22, 0.33, 0.48, 1.0))
	_draw_ellipse_outline(Vector2.ZERO, rx * 0.96, ry * 0.96, Color(0.95, 0.82, 0.42, 0.55), 3.0)

	# Isometric diamond tile grid inside the ellipse
	var step_x := 110.0
	var step_y := 55.0
	var cols := int(rx / step_x) + 1
	var rows := int(ry / step_y) + 1
	for gx in range(-cols, cols + 1):
		for gy in range(-rows, rows + 1):
			var center := Vector2(gx * step_x + (gy % 2) * (step_x * 0.5), gy * step_y)
			if (center.x * center.x) / (rx * rx * 0.88) + (center.y * center.y) / (ry * ry * 0.88) <= 1.0:
				var pts := PackedVector2Array([
					center + Vector2(0, -step_y * 0.48),
					center + Vector2(step_x * 0.48, 0),
					center + Vector2(0, step_y * 0.48),
					center + Vector2(-step_x * 0.48, 0),
				])
				draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.45, 0.68, 0.86, 0.14), 1.5)

	# Celestial center rune ring
	_draw_ellipse_outline(Vector2.ZERO, 210.0, 110.0, Color(0.98, 0.84, 0.40, 0.35), 2.5)
	_draw_ellipse_outline(Vector2.ZERO, 130.0, 68.0, Color(0.45, 0.90, 0.98, 0.3), 2.0)

	# Ambient drifting cloud wisps
	for w in _wisps:
		var wp: Vector2 = w["pos"]
		var wr: float = w["radius"]
		var wa: float = w["alpha"]
		draw_circle(wp, wr, Color(0.92, 0.97, 1.0, wa))
		draw_circle(wp + Vector2(wr * 0.55, 6), wr * 0.7, Color(0.92, 0.97, 1.0, wa * 0.8))


func _draw_ellipse(center: Vector2, erx: float, ery: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var segs := 64
	for i in range(segs):
		var a := (float(i) / segs) * TAU
		pts.append(center + Vector2(cos(a) * erx, sin(a) * ery))
	draw_colored_polygon(pts, col)


func _draw_ellipse_outline(center: Vector2, erx: float, ery: float, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	var segs := 64
	for i in range(segs + 1):
		var a := (float(i % segs) / segs) * TAU
		pts.append(center + Vector2(cos(a) * erx, sin(a) * ery))
	draw_polyline(pts, col, width)


class _PillarVisual extends Node2D:
	func _draw() -> void:
		# Shadow
		draw_circle(Vector2(0, 6), 30.0, Color(0.05, 0.08, 0.16, 0.45))
		# Stone base
		draw_rect(Rect2(-22, -46, 44, 52), Color(0.32, 0.42, 0.56, 1.0))
		draw_rect(Rect2(-22, -46, 44, 52), Color(0.75, 0.88, 0.98, 0.5), false, 2.0)
		# Golden cap & rune
		draw_rect(Rect2(-26, -54, 52, 12), Color(0.92, 0.76, 0.34, 1.0))
		draw_circle(Vector2(0, -22), 7.0, Color(0.42, 0.92, 1.0, 0.85))
