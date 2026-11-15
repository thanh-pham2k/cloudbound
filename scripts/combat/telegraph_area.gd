extends Node2D
class_name TelegraphArea

signal triggered

enum ShapeType { CIRCLE, LINE }

var shape_type: ShapeType = ShapeType.CIRCLE
var radius: float = 90.0
var line_end: Vector2 = Vector2.RIGHT * 240.0
var line_width: float = 44.0
var duration: float = 0.7
var base_color: Color = Color(1.0, 0.28, 0.22)
var _elapsed: float = 0.0
var _done: bool = false


func setup_circle(pos: Vector2, rad: float, dur: float, col: Color = Color(1.0, 0.28, 0.22)) -> void:
	position = pos
	shape_type = ShapeType.CIRCLE
	radius = rad
	duration = maxf(dur, 0.05)
	base_color = col


func setup_line(start_pos: Vector2, dir: Vector2, length: float, width: float, dur: float, col: Color = Color(1.0, 0.35, 0.2)) -> void:
	position = start_pos
	shape_type = ShapeType.LINE
	line_end = dir.normalized() * length
	line_width = width
	duration = maxf(dur, 0.05)
	base_color = col


func _ready() -> void:
	z_index = -1


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	queue_redraw()
	if _elapsed >= duration:
		_done = true
		triggered.emit()
		queue_free()


func _draw() -> void:
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	if shape_type == ShapeType.CIRCLE:
		draw_circle(Vector2.ZERO, radius, Color(base_color.r, base_color.g, base_color.b, 0.16))
		draw_circle(Vector2.ZERO, radius * progress, Color(base_color.r, base_color.g, base_color.b, 0.32))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(base_color.r, base_color.g, base_color.b, 0.85), 2.5)
	else:
		var dir := line_end.normalized()
		var perp := Vector2(-dir.y, dir.x) * (line_width * 0.5)
		var pts := PackedVector2Array([-perp, line_end - perp, line_end + perp, perp])
		draw_colored_polygon(pts, Color(base_color.r, base_color.g, base_color.b, 0.2 + 0.25 * progress))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(base_color.r, base_color.g, base_color.b, 0.85), 2.5)
