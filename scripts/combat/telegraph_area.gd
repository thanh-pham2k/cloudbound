extends Node2D
class_name TelegraphArea

signal triggered

enum ShapeType { CIRCLE, LINE, CAPSULE, PROJECTILE_FAN }

var painted_visuals := false
var shape_type: ShapeType = ShapeType.CIRCLE
var radius: float = 90.0
var line_end: Vector2 = Vector2.RIGHT * 240.0
var line_width: float = 44.0
var path_points: PackedVector2Array = PackedVector2Array()
var fan_dirs: Array[Vector2] = []
var fan_length: float = 300.0
var fan_width: float = 28.0
var duration: float = 0.7
var base_color: Color = Color(1.0, 0.28, 0.22)
var _elapsed: float = 0.0
var _done: bool = false
var aim_target: Node2D
var aim_origin: Node2D
var aim_direction := Vector2.DOWN


func setup_circle(pos: Vector2, rad: float, dur: float, col: Color = Color(1.0, 0.28, 0.22)) -> void:
	position = pos
	shape_type = ShapeType.CIRCLE
	radius = rad
	duration = maxf(dur, 0.05)
	base_color = col


func setup_line(start_pos: Vector2, dir: Vector2, length: float, width: float, dur: float, col: Color = Color(1.0, 0.35, 0.2)) -> void:
	position = start_pos
	shape_type = ShapeType.LINE
	var safe_dir := dir.normalized() if dir.length_squared() > 0.0001 else Vector2.DOWN
	line_end = safe_dir * length
	line_width = width
	duration = maxf(dur, 0.05)
	base_color = col


func setup_capsule(start_pos: Vector2, local_points: PackedVector2Array, rad: float, dur: float, col: Color = Color(1.0, 0.55, 0.15)) -> void:
	position = start_pos
	shape_type = ShapeType.CAPSULE
	path_points = local_points.duplicate()
	if path_points.is_empty():
		path_points.append(Vector2.ZERO)
	radius = rad
	duration = maxf(dur, 0.05)
	base_color = col


func setup_projectile_fan(start_pos: Vector2, dirs: Array[Vector2], length: float, width: float, dur: float, col: Color = Color(0.7, 0.4, 1.0)) -> void:
	position = start_pos
	shape_type = ShapeType.PROJECTILE_FAN
	fan_dirs = dirs.duplicate()
	fan_length = length
	fan_width = width
	duration = maxf(dur, 0.05)
	base_color = col


func cancel() -> void:
	if _done:
		return
	_done = true
	queue_free()


func contains_circle(world_pos: Vector2, entity_radius: float = 0.0) -> bool:
	var local_pos := to_local(world_pos)
	match shape_type:
		ShapeType.CIRCLE:
			return local_pos.length() <= radius + entity_radius
		ShapeType.CAPSULE:
			return _distance_to_polyline(local_pos, path_points) <= radius + entity_radius
		ShapeType.LINE:
			if line_end.length_squared() <= 0.0001:
				return local_pos.length() <= line_width * 0.5 + entity_radius
			var dir := line_end.normalized()
			var along := local_pos.dot(dir)
			if along < -entity_radius or along > line_end.length() + entity_radius:
				return false
			var perp := absf(local_pos.cross(dir))
			return perp <= line_width * 0.5 + entity_radius
		_:
			return false


static func polyline_contains_circle(origin: Vector2, local_points: PackedVector2Array, rad: float, world_pos: Vector2, entity_radius: float = 0.0) -> bool:
	return _distance_to_polyline(world_pos - origin, local_points) <= rad + entity_radius


static func _distance_to_polyline(pt: Vector2, pts: PackedVector2Array) -> float:
	if pts.is_empty():
		return INF
	if pts.size() == 1:
		return pt.distance_to(pts[0])
	var best := INF
	for i in range(pts.size() - 1):
		var closest := Geometry2D.get_closest_point_to_segment(pt, pts[i], pts[i + 1])
		best = minf(best, pt.distance_to(closest))
	return best


func _ready() -> void:
	z_index = -1


func _process(delta: float) -> void:
	if _done:
		return
	# Ranged attacks keep their original release-time targeting. Rotate the
	# warning with that aim, then release along these same displayed directions.
	if is_instance_valid(aim_target) and is_instance_valid(aim_origin):
		var desired := aim_target.global_position - aim_origin.global_position
		if desired.length_squared() > 0.001:
			desired = desired.normalized()
			if shape_type == ShapeType.LINE:
				line_end = desired * line_end.length()
			elif shape_type == ShapeType.PROJECTILE_FAN:
				var turn := aim_direction.angle_to(desired)
				for i in range(fan_dirs.size()):
					fan_dirs[i] = fan_dirs[i].rotated(turn)
			aim_direction = desired
	_elapsed += delta
	queue_redraw()
	if _elapsed >= duration:
		_done = true
		triggered.emit()
		queue_free()


func _draw() -> void:
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	match shape_type:
		ShapeType.CIRCLE:
			if painted_visuals:
				const RUNE := preload("res://assets/generated/combat_vfx/red_aoe_warning_sprite_frames.tres")
				var frame := RUNE.get_frame_texture(&"red_aoe_warning_fx", int(_elapsed * 12.0) % 6)
				var size := Vector2.ONE * 2.4 * radius
				draw_texture_rect(frame, Rect2(-size * 0.5, size),
					false, Color(1.0, 1.0, 1.0, 0.30 + 0.30 * progress))
			draw_circle(Vector2.ZERO, radius, Color(base_color.r, base_color.g, base_color.b, 0.16))
			draw_circle(Vector2.ZERO, radius * progress, Color(base_color.r, base_color.g, base_color.b, 0.32))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(base_color.r, base_color.g, base_color.b, 0.85), 2.5)
		ShapeType.LINE:
			_draw_lane(Vector2.ZERO, line_end, line_width, progress, true)
		ShapeType.CAPSULE:
			_draw_capsule(progress)
		ShapeType.PROJECTILE_FAN:
			for dir in fan_dirs:
				if dir.length_squared() > 0.0001:
					_draw_lane(Vector2.ZERO, dir.normalized() * fan_length, fan_width, progress, false)


func _draw_lane(start_pt: Vector2, end_pt: Vector2, width: float, progress: float, draw_outline_box: bool) -> void:
	if end_pt.length_squared() <= 0.0001:
		return
	var dir := end_pt.normalized()
	var perp := Vector2(-dir.y, dir.x) * (width * 0.5)
	if draw_outline_box:
		var pts := PackedVector2Array([start_pt - perp, start_pt + end_pt - perp, start_pt + end_pt + perp, start_pt + perp])
		draw_colored_polygon(pts, Color(base_color.r, base_color.g, base_color.b, 0.16))
		var fill_end := end_pt * progress
		var fill_pts := PackedVector2Array([start_pt - perp, start_pt + fill_end - perp, start_pt + fill_end + perp, start_pt + perp])
		draw_colored_polygon(fill_pts, Color(base_color.r, base_color.g, base_color.b, 0.26))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(base_color.r, base_color.g, base_color.b, 0.85), 2.5)
	else:
		# Open-ended projectile lane across the full projectile travel distance with smooth far taper.
		var near_end := end_pt * 0.45
		var near_col := Color(base_color.r, base_color.g, base_color.b, 0.16 + 0.14 * progress)
		var mid_col := Color(base_color.r, base_color.g, base_color.b, 0.10 + 0.10 * progress)
		var far_col := Color(base_color.r, base_color.g, base_color.b, 0.02)
		var near_pts := PackedVector2Array([start_pt - perp, start_pt + near_end - perp, start_pt + near_end + perp, start_pt + perp])
		var far_pts := PackedVector2Array([start_pt + near_end - perp, start_pt + end_pt - perp, start_pt + end_pt + perp, start_pt + near_end + perp])
		draw_polygon(near_pts, PackedColorArray([near_col, mid_col, mid_col, near_col]))
		draw_polygon(far_pts, PackedColorArray([mid_col, far_col, far_col, mid_col]))
		var fill_end := end_pt * progress
		var fill_pts := PackedVector2Array([start_pt - perp, start_pt + fill_end - perp, start_pt + fill_end + perp, start_pt + perp])
		draw_colored_polygon(fill_pts, Color(base_color.r, base_color.g, base_color.b, 0.18))
		draw_line(start_pt - perp, start_pt + near_end - perp, Color(base_color.r, base_color.g, base_color.b, 0.55), 1.5)
		draw_line(start_pt + near_end - perp, start_pt + end_pt - perp, Color(base_color.r, base_color.g, base_color.b, 0.22), 1.2)
		draw_line(start_pt + perp, start_pt + near_end + perp, Color(base_color.r, base_color.g, base_color.b, 0.55), 1.5)
		draw_line(start_pt + near_end + perp, start_pt + end_pt + perp, Color(base_color.r, base_color.g, base_color.b, 0.22), 1.2)
		draw_line(start_pt, start_pt + end_pt, Color(base_color.r, base_color.g, base_color.b, 0.42 + 0.35 * progress), 1.8)


func _draw_capsule(progress: float) -> void:
	if path_points.is_empty():
		return
	var fill_col := Color(base_color.r, base_color.g, base_color.b, 0.16)
	var prog_col := Color(base_color.r, base_color.g, base_color.b, 0.24)
	var edge_col := Color(base_color.r, base_color.g, base_color.b, 0.88)

	# Draw base swept corridor using segment quads + vertex circles
	for pt in path_points:
		draw_circle(pt, radius, fill_col)
	for i in range(path_points.size() - 1):
		var a := path_points[i]
		var b := path_points[i + 1]
		var seg := b - a
		if seg.length_squared() <= 0.0001:
			continue
		var perp := Vector2(-seg.y, seg.x).normalized() * radius
		draw_colored_polygon(PackedVector2Array([a - perp, b - perp, b + perp, a + perp]), fill_col)

	# Progress fill along the swept path
	var total_len := 0.0
	for i in range(path_points.size() - 1):
		total_len += path_points[i].distance_to(path_points[i + 1])
	var target_dist := total_len * progress
	var accum := 0.0
	draw_circle(path_points[0], radius * 0.92, prog_col)
	for i in range(path_points.size() - 1):
		var a := path_points[i]
		var b := path_points[i + 1]
		var seg_len := a.distance_to(b)
		if seg_len <= 0.0001:
			continue
		var seg_end := b
		var reached := false
		if accum + seg_len >= target_dist:
			seg_end = a.lerp(b, (target_dist - accum) / seg_len)
			reached = true
		var perp := Vector2(-(b - a).y, (b - a).x).normalized() * (radius * 0.92)
		draw_colored_polygon(PackedVector2Array([a - perp, seg_end - perp, seg_end + perp, a + perp]), prog_col)
		draw_circle(seg_end, radius * 0.92, prog_col)
		accum += seg_len
		if reached:
			break

	# Draw crisp outer capsule perimeter for single/multi-segment path
	if path_points.size() == 1:
		draw_arc(path_points[0], radius, 0.0, TAU, 40, edge_col, 2.5)
	else:
		var start_dir := (path_points[1] - path_points[0]).normalized()
		var end_idx := path_points.size() - 1
		var end_dir := (path_points[end_idx] - path_points[end_idx - 1]).normalized()
		var start_angle := start_dir.angle()
		var end_angle := end_dir.angle()
		draw_arc(path_points[0], radius, start_angle + PI * 0.5, start_angle + PI * 1.5, 20, edge_col, 2.5)
		draw_arc(path_points[end_idx], radius, end_angle - PI * 0.5, end_angle + PI * 0.5, 20, edge_col, 2.5)
		for i in range(path_points.size() - 1):
			var a := path_points[i]
			var b := path_points[i + 1]
			var seg := b - a
			if seg.length_squared() <= 0.0001:
				continue
			var perp := Vector2(-seg.y, seg.x).normalized() * radius
			draw_line(a - perp, b - perp, edge_col, 2.5)
			draw_line(a + perp, b + perp, edge_col, 2.5)
