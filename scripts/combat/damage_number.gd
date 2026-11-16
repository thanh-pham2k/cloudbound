extends Node2D
class_name DamageNumber

var text_value: String = "0"
var color: Color = Color.WHITE
var velocity: Vector2 = Vector2(0, -56)
var lifetime: float = 0.68
var _font_size: int = 17
var _start_scale: float = 1.15
var _elapsed: float = 0.0
var _label: Label


func setup(amount: int, is_crit: bool = false, is_heal: bool = false, is_player_hit: bool = false) -> void:
	if is_heal:
		text_value = "+%d" % amount
		color = Color(0.42, 0.96, 0.55)
		_font_size = 17
		_start_scale = 1.15
		lifetime = 0.72
	elif is_player_hit:
		text_value = "-%d" % amount
		color = Color(1.0, 0.34, 0.34)
		_font_size = 18
		_start_scale = 1.2
		lifetime = 0.72
	elif is_crit:
		text_value = "%d!" % amount
		color = Color(1.0, 0.86, 0.22)
		_font_size = 23
		_start_scale = 1.42
		lifetime = 0.86
	else:
		text_value = "%d" % amount
		color = Color(0.96, 0.98, 1.0)
		_font_size = 17
		_start_scale = 1.12
		lifetime = 0.68
	velocity = Vector2(randf_range(-10.0, 10.0), -62.0 if is_crit else -54.0)


func _ready() -> void:
	_label = Label.new()
	_label.text = text_value
	_label.modulate = color
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(110, 32)
	_label.position = Vector2(-55, -16)
	_label.add_theme_font_size_override("font_size", _font_size)
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.14, 0.95))
	_label.add_theme_constant_override("outline_size", 5 if _font_size >= 22 else 4)
	add_child(_label)
	z_index = 100
	z_as_relative = false
	scale = Vector2.ONE * _start_scale


func _process(delta: float) -> void:
	_elapsed += delta
	position += velocity * delta
	velocity.x = lerpf(velocity.x, 0.0, clampf(delta * 6.0, 0.0, 1.0))
	velocity.y = lerpf(velocity.y, -14.0, clampf(delta * 4.5, 0.0, 1.0))
	var t := clampf(_elapsed / lifetime, 0.0, 1.0)
	var scale_t := clampf(_elapsed / 0.14, 0.0, 1.0)
	var ease_out := 1.0 - pow(1.0 - scale_t, 3.0)
	scale = Vector2.ONE * lerpf(_start_scale, 1.0, ease_out)
	var fade_t := clampf((t - 0.45) / 0.55, 0.0, 1.0)
	modulate.a = 1.0 - (fade_t * fade_t * (3.0 - 2.0 * fade_t))
	if _elapsed >= lifetime:
		queue_free()
