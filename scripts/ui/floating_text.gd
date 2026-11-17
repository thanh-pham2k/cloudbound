class_name FloatingText
extends Node2D
## Lightweight floating combat/reward popup that rises and fades out.

var text: String = ""
var color: Color = Color.WHITE
var _life: float = 0.75
var _max_life: float = 0.75


func setup(msg: String, col: Color = Color.WHITE) -> void:
	text = msg
	color = col


func _ready() -> void:
	z_index = 50
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(-60, -14)
	lbl.size = Vector2(120, 28)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color("#1E293B"))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.add_theme_font_size_override("font_size", 15)
	add_child(lbl)


func _process(delta: float) -> void:
	_life -= delta
	position.y -= 34.0 * delta
	modulate.a = clampf(_life / _max_life, 0.0, 1.0)
	if _life <= 0.0:
		queue_free()
