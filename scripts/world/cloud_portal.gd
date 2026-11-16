extends Area2D
class_name CloudPortal

signal entered

var visual_scale := 1.0
var village_exit := false
var _triggered: bool = false


func _ready() -> void:
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

	var variant := "arch_celestial_gate_01" if village_exit else "arch_heaven_gateway_01"
	var gw_path := "res://assets/base/environment/architecture/%s.png" % variant
	if ResourceLoader.exists(gw_path):
		var gw := Sprite2D.new()
		gw.texture = load(gw_path)
		gw.offset = Vector2(0, -108)
		if not village_exit:
			var light := ShaderMaterial.new()
			light.shader = preload("res://scripts/world/prop_cleanup.gdshader")
			light.set_shader_parameter("roof_span", Vector2(0.46, 0.54))
			light.set_shader_parameter("portal_light", 0.24)
			gw.material = light
		visual.add_child(gw)

	var label := Label.new()
	label.text = "Thang Mây" if village_exit else "Cổng Thiên Giới"
	label.position = Vector2(-56, -155 * visual_scale)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.55))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.14, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)

	body_entered.connect(_on_body_entered)
	z_index = 5


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if body.is_in_group("player"):
		_triggered = true
		entered.emit()
