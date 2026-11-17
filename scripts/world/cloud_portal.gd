extends Area2D
class_name CloudPortal

signal entered

var visual_scale := 1.0
var village_exit := false
var painted_visuals := false
var heaven_gate := false
var arm_delay: float = 0.0
var _arm_timer: float = 0.0
var _triggered: bool = false


func _ready() -> void:
	_arm_timer = maxf(0.0, arm_delay)
	collision_layer = 0
	collision_mask = 2

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 44.0
	col.shape = shape
	add_child(col)

	var visual := Node2D.new()
	visual.scale = Vector2.ONE * visual_scale
	add_child(visual)

	const PAINTED := preload("res://scripts/world/painted_sprite.gd")
	const GATE := preload("res://assets/props/gate_heaven_01/base.png")
	PAINTED.place(visual, GATE, Vector2.ZERO, 0.72, true)

	var label := Label.new()
	label.text = "Thang Mây" if village_exit else "Cổng Thiên Giới"
	var label_height := 155.0
	if painted_visuals:
		label_height = 240.0 if heaven_gate else 165.0
	label.position = Vector2(-56, -label_height * visual_scale)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.55))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.14, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)

	body_entered.connect(_on_body_entered)
	z_index = 5


func _physics_process(delta: float) -> void:
	if _triggered:
		return
	if _arm_timer > 0.0:
		_arm_timer = maxf(0.0, _arm_timer - delta)
		if _arm_timer > 0.0:
			return
		for body in get_overlapping_bodies():
			_on_body_entered(body)
			if _triggered:
				return


func _on_body_entered(body: Node) -> void:
	if _triggered or _arm_timer > 0.0:
		return
	if body.is_in_group("player") and not body.get("_is_dead"):
		_triggered = true
		entered.emit()
