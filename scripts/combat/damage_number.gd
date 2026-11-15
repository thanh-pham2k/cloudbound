extends Node2D
class_name DamageNumber

var text_value: String = "0"
var color: Color = Color.WHITE
var velocity: Vector2 = Vector2(0, -48)
var lifetime: float = 0.65
var _elapsed: float = 0.0
var _label: Label


func setup(amount: int, is_crit: bool = false, is_heal: bool = false, is_player_hit: bool = false) -> void:
	if is_heal:
		text_value = "+%d" % amount
		color = Color(0.45, 0.96, 0.55)
	elif is_player_hit:
		text_value = "-%d" % amount
		color = Color(1.0, 0.35, 0.35)
	elif is_crit:
		text_value = "%d!" % amount
		color = Color(1.0, 0.85, 0.25)
	else:
		text_value = "%d" % amount
		color = Color(0.95, 0.98, 1.0)
	velocity = Vector2(randf_range(-18.0, 18.0), -52.0)


func _ready() -> void:
	_label = Label.new()
	_label.text = text_value
	_label.modulate = color
	_label.position = Vector2(-24, -14)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.14, 0.9))
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)
	z_index = 100


func _process(delta: float) -> void:
	_elapsed += delta
	position += velocity * delta
	velocity.y += 30.0 * delta
	var t := clampf(_elapsed / lifetime, 0.0, 1.0)
	modulate.a = 1.0 - t * t
	if _elapsed >= lifetime:
		queue_free()
