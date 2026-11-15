extends Area2D
class_name CloudPortal

signal entered

var _time: float = 0.0
var _triggered: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 44.0
	col.shape = shape
	add_child(col)

	var label := Label.new()
	label.text = "Cổng Thiên Giới"
	label.position = Vector2(-56, -72)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.55))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.14, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)

	body_entered.connect(_on_body_entered)
	z_index = 5


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if body.is_in_group("player"):
		_triggered = true
		entered.emit()


func _draw() -> void:
	var pulse := 1.0 + sin(_time * 4.0) * 0.08
	draw_circle(Vector2.ZERO, 48.0 * pulse, Color(0.4, 0.92, 1.0, 0.22))
	draw_circle(Vector2.ZERO, 34.0 * pulse, Color(0.65, 0.95, 1.0, 0.45))
	draw_arc(Vector2.ZERO, 44.0 * pulse, 0.0, TAU, 48, Color(0.98, 0.86, 0.38, 0.92), 3.5)
	draw_circle(Vector2.ZERO, 16.0, Color(1.0, 1.0, 0.92, 0.85))
