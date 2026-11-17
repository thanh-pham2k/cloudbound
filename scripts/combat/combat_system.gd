extends Node2D
class_name CombatSystem

## Centralized spawner for projectiles, telegraphs, slash effects, and damage numbers.

var painted_visuals := false
var effects_container: Node2D
var camera: Camera2D
var _shake_strength: float = 0.0
var _recent_popups: Array[Dictionary] = []


func setup(container: Node2D, cam: Camera2D) -> void:
	effects_container = container
	camera = cam
	_recent_popups.clear()


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


func _to_effects_local(world_pos: Vector2) -> Vector2:
	return effects_container.to_local(world_pos) if effects_container != null else world_pos


func spawn_damage_number(pos: Vector2, amount: int, is_crit: bool = false, is_heal: bool = false, is_player_hit: bool = false, height_offset: float = 96.0) -> void:
	if effects_container == null or amount <= 0:
		return
	var local_pos := _to_effects_local(pos)
	var now := Time.get_ticks_msec() * 0.001
	var kept: Array[Dictionary] = []
	var cluster_count := 0
	for entry in _recent_popups:
		if now - float(entry["time"]) <= 0.35:
			kept.append(entry)
			if local_pos.distance_to(entry["pos"]) <= 52.0:
				cluster_count += 1
	_recent_popups = kept
	_recent_popups.append({"pos": local_pos, "time": now})

	var stagger := Vector2.ZERO
	if cluster_count > 0:
		var side := -1.0 if (cluster_count % 2 == 1) else 1.0
		var tier := int((cluster_count + 1) / 2)
		stagger = Vector2(side * (16.0 + float(tier - 1) * 10.0), -float(cluster_count) * 18.0)

	var dn := DamageNumber.new()
	dn.position = local_pos + Vector2(0.0, -height_offset) + stagger
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
	proj.setup(_to_effects_local(pos), vel, dmg, target_group, col, rad, life, is_crit, homing)
	effects_container.add_child(proj)
	return proj


func spawn_circle_telegraph(pos: Vector2, radius: float, duration: float, col: Color = Color(1.0, 0.28, 0.22)) -> TelegraphArea:
	var t := TelegraphArea.new()
	t.painted_visuals = painted_visuals
	t.setup_circle(_to_effects_local(pos), radius, duration, col)
	if effects_container != null:
		effects_container.add_child(t)
	return t


func spawn_line_telegraph(start_pos: Vector2, dir: Vector2, length: float, width: float, duration: float, col: Color = Color(1.0, 0.35, 0.2)) -> TelegraphArea:
	var t := TelegraphArea.new()
	t.setup_line(_to_effects_local(start_pos), dir, length, width, duration, col)
	if effects_container != null:
		effects_container.add_child(t)
	return t


func spawn_capsule_telegraph(world_points: PackedVector2Array, radius: float, duration: float, col: Color = Color(1.0, 0.55, 0.15)) -> TelegraphArea:
	var t := TelegraphArea.new()
	var origin_world := world_points[0] if not world_points.is_empty() else Vector2.ZERO
	var local_origin := _to_effects_local(origin_world)
	var local_pts := PackedVector2Array()
	for pt in world_points:
		local_pts.append(_to_effects_local(pt) - local_origin)
	t.setup_capsule(local_origin, local_pts, radius, duration, col)
	if effects_container != null:
		effects_container.add_child(t)
	return t


func spawn_projectile_fan_telegraph(start_pos: Vector2, dirs: Array[Vector2], length: float, width: float, duration: float, col: Color = Color(0.7, 0.4, 1.0)) -> TelegraphArea:
	var t := TelegraphArea.new()
	t.setup_projectile_fan(_to_effects_local(start_pos), dirs, length, width, duration, col)
	if effects_container != null:
		effects_container.add_child(t)
	return t


func spawn_hit_impact(pos: Vector2, col: Color = Color(0.75, 0.95, 1.0), scale_factor: float = 0.65) -> void:
	if effects_container == null:
		return
	var local_pos := _to_effects_local(pos)
	var burst := _RingBurstEffect.new()
	burst.painted_visuals = false
	burst.position = local_pos
	burst.max_radius = 36.0 * scale_factor
	burst.color = col
	burst.z_index = 20
	effects_container.add_child(burst)


func spawn_ring_burst(pos: Vector2, radius: float, col: Color = Color(0.45, 0.92, 1.0)) -> void:
	if effects_container == null:
		return
	var burst := _RingBurstEffect.new()
	burst.painted_visuals = painted_visuals
	burst.position = _to_effects_local(pos)
	burst.max_radius = radius
	burst.color = col
	burst.z_index = 12
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
		draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, a * 0.22))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(color.r, color.g, color.b, a * 0.9), 4.0)


func spawn_melee_slash(pos: Vector2, dir: Vector2, radius: float = 115.0, arc_rad: float = 2.2, col: Color = Color(1.0, 0.85, 0.35)) -> void:
	if effects_container == null:
		return
	var slash := _MeleeSlashEffect.new()
	slash.painted_visuals = painted_visuals
	slash.position = _to_effects_local(pos)
	slash.base_angle = dir.angle()
	slash.radius = radius
	slash.arc_rad = arc_rad
	slash.color = col
	slash.z_index = 15
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
		var start_a := base_angle - arc_rad * 0.5
		var end_a := base_angle + arc_rad * 0.5
		draw_arc(Vector2.ZERO, r, start_a, end_a, 24, Color(color.r, color.g, color.b, a * 0.95), 9.0)
		draw_arc(Vector2.ZERO, r * 0.82, start_a + 0.12, end_a - 0.12, 20, Color(1.0, 0.98, 0.82, a * 0.7), 4.0)
