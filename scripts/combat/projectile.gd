extends Area2D
class_name GameProjectile

var painted_visuals := false
var velocity: Vector2 = Vector2.ZERO
var damage: int = 10
var is_crit: bool = false
var target_group: String = "enemy"
var max_lifetime: float = 2.0
var radius: float = 9.0
var color: Color = Color(0.5, 0.95, 1.0)
var homing_target: Node2D = null
var homing_speed: float = 0.0
var _elapsed: float = 0.0
var _hit := false


func setup(
	pos: Vector2,
	vel: Vector2,
	dmg: int,
	tgt_group: String,
	col: Color = Color(0.5, 0.95, 1.0),
	rad: float = 9.0,
	life: float = 1.8,
	crit: bool = false,
	homing: Node2D = null
) -> void:
	position = pos
	velocity = vel
	damage = dmg
	target_group = tgt_group
	color = col
	radius = rad
	max_lifetime = life
	is_crit = crit
	homing_target = homing
	homing_speed = vel.length()


func _ready() -> void:
	var col_shape := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius + 4.0
	col_shape.shape = shape
	add_child(col_shape)

	collision_layer = 0
	collision_mask = 2 | 4
	body_entered.connect(_on_body_entered)
	z_index = 20
	queue_redraw()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= max_lifetime:
		queue_free()
		return

	if homing_target != null and is_instance_valid(homing_target):
		var desired := (homing_target.global_position - global_position).normalized() * homing_speed
		velocity = velocity.lerp(desired, clampf(delta * 8.0, 0.0, 1.0))

	position += velocity * delta
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _hit or not body.is_in_group(target_group) or not body.has_method("take_damage"):
		return
	_hit = true
	body.take_damage(damage, is_crit)
	if painted_visuals:
		const IMPACT := preload("res://assets/generated/combat_vfx/cyan_impact_sprite_frames.tres")
		var effect := AnimatedSprite2D.new()
		effect.sprite_frames = IMPACT
		effect.position = position
		effect.scale = Vector2.ONE * radius / 18.0
		effect.z_index = z_index
		effect.animation_finished.connect(effect.queue_free)
		get_parent().add_child.call_deferred(effect)
		effect.play(&"cyan_impact_fx")
	queue_free()


func _draw() -> void:
	if painted_visuals:
		const COMET := preload("res://assets/generated/combat_vfx/cyan_projectile_sprite_frames.tres")
		var frame := COMET.get_frame_texture(&"cyan_projectile_fx", int(_elapsed * 14.0) % 6)
		var size := Vector2.ONE * radius * 7.0
		draw_set_transform(Vector2.ZERO, velocity.angle())
		draw_texture_rect(frame, Rect2(Vector2(-size.x * 0.72, -size.y * 0.5), size),
			false, Color.WHITE.lerp(color, 0.32))
		return
	draw_circle(Vector2.ZERO, radius * 1.4, Color(color.r, color.g, color.b, 0.35))
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.45, Color.WHITE)
