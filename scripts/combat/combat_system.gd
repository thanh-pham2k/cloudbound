extends Node2D
class_name CombatSystem

## Centralized spawner for projectiles, telegraphs, slash effects, and damage numbers.

var painted_visuals := false
var effects_container: Node2D
var camera: Camera2D
var _shake_strength: float = 0.0


func setup(container: Node2D, cam: Camera2D) -> void:
	effects_container = container
	camera = cam


func _process(delta: float) -> void:
	if camera != null and _shake_strength > 0.1:
		camera.offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
		_shake_strength = lerpf(_shake_strength, 0.0, clampf(delta * 12.0, 0.0, 1.0))
	elif camera != null and camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO


func add_screen_shake(strength: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)


func spawn_damage_number(pos: Vector2, amount: int, is_crit: bool = false, is_heal: bool = false, is_player_hit: bool = false) -> void:
	if effects_container == null:
		return
	var dn := DamageNumber.new()
	dn.position = pos + Vector2(0, -34)
	dn.setup(amount, is_crit, is_heal, is_player_hit)
	effects_container.add_child(dn)


func spawn_projectile(
	pos: Vector2,
	vel: Vector2,
	dmg: int,
	target_group: String,
	col: Color = Color(0.5, 0.95, 1.0),
	rad: float = 9.0,
	life: float = 1.8,
	is_crit: bool = false,
	homing: Node2D = null
) -> GameProjectile:
	if effects_container == null:
		return null
	var proj := GameProjectile.new()
	proj.painted_visuals = painted_visuals
	proj.setup(pos, vel, dmg, target_group, col, rad, life, is_crit, homing)
	effects_container.add_child(proj)
	return proj


func spawn_circle_telegraph(pos: Vector2, radius: float, duration: float, col: Color = Color(1.0, 0.28, 0.22)) -> TelegraphArea:
	var t := TelegraphArea.new()
	t.painted_visuals = painted_visuals
	t.setup_circle(pos, radius, duration, col)
	if effects_container != null:
		effects_container.add_child(t)
	return t


func spawn_line_telegraph(start_pos: Vector2, dir: Vector2, length: float, width: float, duration: float, col: Color = Color(1.0, 0.35, 0.2)) -> TelegraphArea:
	var t := TelegraphArea.new()
	t.setup_line(start_pos, dir, length, width, duration, col)
	if effects_container != null:
		effects_container.add_child(t)
	return t


func spawn_ring_burst(pos: Vector2, radius: float, col: Color = Color(0.45, 0.92, 1.0)) -> void:
	if effects_container == null:
		return
	var burst := _RingBurstEffect.new()
	burst.painted_visuals = painted_visuals
	burst.position = pos
	burst.max_radius = radius
	burst.color = col
	effects_container.add_child(burst)


class _RingBurstEffect extends Node2D:
	var painted_visuals := false
	var max_radius: float = 140.0
	var color: Color = Color(0.45, 0.92, 1.0)
	var _elapsed: float = 0.0
	var _duration: float = 0.28

	func _process(delta: float) -> void:
		_elapsed += delta
		queue_redraw()
		if _elapsed >= _duration:
			queue_free()

	func _draw() -> void:
		var t := clampf(_elapsed / _duration, 0.0, 1.0)
		var r := lerpf(24.0, max_radius, t)
		var a := 1.0 - t
		if painted_visuals:
			const BURST := preload("res://assets/processed/vfx/cyan_ground_burst.png")
			var size := BURST.get_size() * (2.0 * r / BURST.get_width())
			draw_texture_rect(BURST, Rect2(Vector2(-size.x * 0.5, -size.y * 0.72), size),
				false, Color(1.0, 1.0, 1.0, a * 0.78))
		draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, a * 0.22))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(color.r, color.g, color.b, a * 0.9), 4.0)


func spawn_melee_slash(pos: Vector2, dir: Vector2, radius: float = 115.0, arc_rad: float = 2.2, col: Color = Color(1.0, 0.85, 0.35)) -> void:
	if effects_container == null:
		return
	var slash := _MeleeSlashEffect.new()
	slash.painted_visuals = painted_visuals
	slash.position = pos
	slash.base_angle = dir.angle()
	slash.radius = radius
	slash.arc_rad = arc_rad
	slash.color = col
	effects_container.add_child(slash)


class _MeleeSlashEffect extends Node2D:
	var painted_visuals := false
	var base_angle: float = 0.0
	var radius: float = 115.0
	var arc_rad: float = 2.2
	var color: Color = Color(1.0, 0.85, 0.35)
	var _elapsed: float = 0.0
	var _duration: float = 0.18

	func _process(delta: float) -> void:
		_elapsed += delta
		queue_redraw()
		if _elapsed >= _duration:
			queue_free()

	func _draw() -> void:
		var t := clampf(_elapsed / _duration, 0.0, 1.0)
		var a := 1.0 - t
		var r := lerpf(radius * 0.65, radius, t)
		if painted_visuals:
			const SLASH := preload("res://assets/generated/combat_vfx/golden_staff_slash_sprite_frames.tres")
			var frame := SLASH.get_frame_texture(&"golden_staff_slash_fx", mini(int(t * 6.0), 5))
			var size := Vector2.ONE * 1.65 * r
			draw_set_transform(Vector2.ZERO, base_angle + PI)
			draw_texture_rect(frame, Rect2(Vector2(-r, -size.y * 0.5), size),
				false, Color(1.0, 1.0, 1.0, a))
			draw_set_transform(Vector2.ZERO)
		var start_a := base_angle - arc_rad * 0.5
		var end_a := base_angle + arc_rad * 0.5
		draw_arc(Vector2.ZERO, r, start_a, end_a, 24, Color(color.r, color.g, color.b, a * 0.95), 9.0)
		draw_arc(Vector2.ZERO, r * 0.82, start_a + 0.12, end_a - 0.12, 20, Color(1.0, 0.98, 0.82, a * 0.7), 4.0)
