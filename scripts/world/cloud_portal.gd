extends Area2D
class_name CloudPortal

signal entered

var _triggered: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 44.0
	col.shape = shape
	add_child(col)

	var gw_path := "res://assets/base/environment/architecture/arch_heaven_gateway_01.png"
	if ResourceLoader.exists(gw_path):
		var gw := Sprite2D.new()
		gw.texture = load(gw_path)
		gw.offset = Vector2(0, -76)
		add_child(gw)

	var sf := SpriteFrames.new()
	sf.add_animation("swirl")
	sf.set_animation_speed("swirl", 10.0)
	sf.set_animation_loop("swirl", true)
	for i in range(8):
		var fpath := "res://assets/base/vfx/vfx_heaven_portal_%02d.png" % i
		if ResourceLoader.exists(fpath):
			sf.add_frame("swirl", load(fpath))
	if sf.get_frame_count("swirl") > 0:
		var swirl := AnimatedSprite2D.new()
		swirl.sprite_frames = sf
		swirl.offset = Vector2(0, -42)
		swirl.play("swirl")
		add_child(swirl)

	var label := Label.new()
	label.text = "Cổng Thiên Giới"
	label.position = Vector2(-56, -138)
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
