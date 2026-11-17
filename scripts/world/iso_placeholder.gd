class_name IsoPlaceholder
extends Node2D
## Draws Minimal Stylized 2.5D isometric placeholder shapes with crisp #1E293B outlines.

const L := preload("res://scripts/world/hoa_qua_son_layout.gd")
const P := L.PALETTE

@export var kind: String = "rock"
@export var item_scale: float = 1.0
@export var facing_dir: Vector2 = Vector2(1.0, 0.5)
@export var hit_flash: float = 0.0
@export var state_active: bool = false


func _draw() -> void:
	match kind:
		"spawn_disc":
			_draw_ellipse(Vector2.ZERO, 34.0 * item_scale, 18.0 * item_scale, P["stone_light"], true)
			_draw_ellipse(Vector2(0, -2), 22.0 * item_scale, 11.0 * item_scale, P["stone_dark"], false)
		"hut":
			_draw_hut(item_scale)
		"peach_tree":
			_draw_tree(item_scale, P["peach_pink"], P["peach_deep"])
		"green_tree":
			_draw_tree(item_scale, P["tree_green"], P["grass_dark"])
		"rock":
			_draw_rock(item_scale)
		"torch":
			_draw_torch(item_scale)
		"peach":
			_draw_peach(item_scale)
		"chest":
			_draw_chest(item_scale, state_active)
		"exit_arch":
			_draw_exit_arch(item_scale, state_active)
		"hero":
			_draw_hero(item_scale)
		"elder_npc":
			_draw_monkey_npc(item_scale, true)
		"guide_npc":
			_draw_monkey_npc(item_scale, false)
		"boar":
			_draw_boar(item_scale)
		"boss":
			_draw_boss(item_scale)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color, outline: bool = false) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := (float(i) / 24.0) * TAU
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)
	if outline:
		var closed := PackedVector2Array(pts)
		closed.append(pts[0])
		draw_polyline(closed, P["ink"], 2.0, true)


func _draw_poly(pts: PackedVector2Array, color: Color, outline: bool = true) -> void:
	draw_colored_polygon(pts, color)
	if outline:
		var closed := PackedVector2Array(pts)
		closed.append(pts[0])
		draw_polyline(closed, P["ink"], 2.0, true)


func _draw_hut(s: float) -> void:
	_draw_ellipse(Vector2(0, 6 * s), 56 * s, 28 * s, P["shadow"])
	# Left & right isometric walls
	_draw_poly(PackedVector2Array([
		Vector2(-46 * s, -4 * s), Vector2(0, 18 * s),
		Vector2(0, -28 * s), Vector2(-46 * s, -50 * s)
	]), P["wood_light"])
	_draw_poly(PackedVector2Array([
		Vector2(0, 18 * s), Vector2(46 * s, -4 * s),
		Vector2(46 * s, -50 * s), Vector2(0, -28 * s)
	]), P["wood_dark"])
	# Doorway
	_draw_poly(PackedVector2Array([
		Vector2(14 * s, 11 * s), Vector2(30 * s, 3 * s),
		Vector2(30 * s, -22 * s), Vector2(14 * s, -14 * s)
	]), P["ink"])
	# Pitched straw roof
	_draw_poly(PackedVector2Array([
		Vector2(-54 * s, -46 * s), Vector2(0, -22 * s),
		Vector2(54 * s, -46 * s), Vector2(0, -84 * s)
	]), P["roof_straw"])


func _draw_tree(s: float, light_col: Color, shade_col: Color) -> void:
	_draw_ellipse(Vector2(0, 4 * s), 34 * s, 17 * s, P["shadow"])
	_draw_poly(PackedVector2Array([
		Vector2(-7 * s, 2 * s), Vector2(7 * s, 2 * s),
		Vector2(5 * s, -36 * s), Vector2(-5 * s, -36 * s)
	]), P["wood_dark"])
	_draw_ellipse(Vector2(-12 * s, -48 * s), 24 * s, 20 * s, shade_col, true)
	_draw_ellipse(Vector2(12 * s, -46 * s), 22 * s, 18 * s, shade_col, true)
	_draw_ellipse(Vector2(0, -58 * s), 28 * s, 23 * s, light_col, true)


func _draw_rock(s: float) -> void:
	_draw_ellipse(Vector2(0, 4 * s), 28 * s, 14 * s, P["shadow"])
	_draw_poly(PackedVector2Array([
		Vector2(-24 * s, 2 * s), Vector2(0, 12 * s),
		Vector2(24 * s, 0), Vector2(16 * s, -24 * s),
		Vector2(-6 * s, -28 * s), Vector2(-22 * s, -12 * s)
	]), P["stone_dark"])
	_draw_poly(PackedVector2Array([
		Vector2(-22 * s, -12 * s), Vector2(-6 * s, -28 * s),
		Vector2(16 * s, -24 * s), Vector2(2 * s, -10 * s)
	]), P["stone_light"])


func _draw_torch(s: float) -> void:
	_draw_ellipse(Vector2(0, 4 * s), 14 * s, 7 * s, P["shadow"])
	_draw_poly(PackedVector2Array([
		Vector2(-10 * s, 2 * s), Vector2(10 * s, 2 * s),
		Vector2(8 * s, -24 * s), Vector2(-8 * s, -24 * s)
	]), P["stone_dark"])
	_draw_ellipse(Vector2(0, -32 * s), 9 * s, 11 * s, P["gold"], true)
	_draw_ellipse(Vector2(0, -31 * s), 5 * s, 7 * s, P["crimson"])


func _draw_peach(s: float) -> void:
	_draw_ellipse(Vector2(0, 4 * s), 13 * s, 7 * s, P["shadow"])
	_draw_ellipse(Vector2(0, -8 * s), 13 * s, 12 * s, Color(1.0, 0.92, 0.55, 0.35))
	_draw_ellipse(Vector2(0, -8 * s), 9 * s, 9 * s, P["peach_pink"], true)
	_draw_ellipse(Vector2(-3 * s, -11 * s), 3 * s, 3 * s, P["gold"])


func _draw_chest(s: float, opened: bool) -> void:
	_draw_ellipse(Vector2(0, 5 * s), 20 * s, 10 * s, P["shadow"])
	var body_col: Color = P["crimson"] if not opened else P["wood_dark"]
	_draw_poly(PackedVector2Array([
		Vector2(-16 * s, 2 * s), Vector2(16 * s, 2 * s),
		Vector2(16 * s, -14 * s), Vector2(-16 * s, -14 * s)
	]), body_col)
	var lid_y: float = -22.0 * s if not opened else -26.0 * s
	_draw_poly(PackedVector2Array([
		Vector2(-17 * s, -14 * s), Vector2(17 * s, -14 * s),
		Vector2(15 * s, lid_y), Vector2(-15 * s, lid_y)
	]), P["gold"])


func _draw_exit_arch(s: float, unlocked: bool) -> void:
	_draw_ellipse(Vector2(0, 6 * s), 48 * s, 22 * s, P["shadow"])
	_draw_poly(PackedVector2Array([
		Vector2(-42 * s, 2 * s), Vector2(-26 * s, 2 * s),
		Vector2(-26 * s, -68 * s), Vector2(-42 * s, -68 * s)
	]), P["stone_dark"])
	_draw_poly(PackedVector2Array([
		Vector2(26 * s, 2 * s), Vector2(42 * s, 2 * s),
		Vector2(42 * s, -68 * s), Vector2(26 * s, -68 * s)
	]), P["stone_dark"])
	_draw_poly(PackedVector2Array([
		Vector2(-48 * s, -66 * s), Vector2(48 * s, -66 * s),
		Vector2(38 * s, -84 * s), Vector2(-38 * s, -84 * s)
	]), P["stone_light"])
	var portal_col: Color = P["gold"] if unlocked else P["cliff_slate"]
	_draw_poly(PackedVector2Array([
		Vector2(-24 * s, 0), Vector2(24 * s, 0),
		Vector2(24 * s, -62 * s), Vector2(-24 * s, -62 * s)
	]), portal_col)


func _draw_hero(s: float) -> void:
	_draw_ellipse(Vector2(0, 2 * s), 16 * s, 8 * s, P["shadow"])
	var body_col: Color = P["gold"] if hit_flash <= 0.0 else Color.WHITE
	# Red scarf
	var scarf_dir := -facing_dir.normalized() * 14.0 * s
	draw_line(Vector2(0, -18 * s), Vector2(0, -18 * s) + scarf_dir, P["crimson"], 4.0 * s)
	# Body & head
	_draw_ellipse(Vector2(0, -13 * s), 10 * s, 12 * s, body_col, true)
	_draw_ellipse(Vector2(0, -28 * s), 10 * s, 10 * s, P["wood_light"], true)
	# Golden headband
	draw_line(Vector2(-9 * s, -32 * s), Vector2(9 * s, -32 * s), P["gold"], 3.0 * s)
	# Staff
	var staff_dir := facing_dir.normalized()
	draw_line(Vector2(-staff_dir.x * 14 * s, -14 * s - staff_dir.y * 8 * s), Vector2(staff_dir.x * 20 * s, -14 * s + staff_dir.y * 12 * s), P["crimson"], 3.5 * s)


func _draw_monkey_npc(s: float, is_elder: bool) -> void:
	_draw_ellipse(Vector2(0, 2 * s), 15 * s, 8 * s, P["shadow"])
	var robe_col: Color = P["wood_dark"] if is_elder else P["tree_green"]
	_draw_ellipse(Vector2(0, -13 * s), 10 * s, 12 * s, robe_col, true)
	_draw_ellipse(Vector2(0, -28 * s), 9.5 * s, 9.5 * s, P["wood_light"], true)
	if is_elder:
		# White beard & wooden staff
		_draw_poly(PackedVector2Array([
			Vector2(-5 * s, -22 * s), Vector2(5 * s, -22 * s), Vector2(0, -12 * s)
		]), Color.WHITE)
		draw_line(Vector2(13 * s, 0), Vector2(13 * s, -34 * s), P["wood_dark"], 3.0 * s)


func _draw_boar(s: float) -> void:
	_draw_ellipse(Vector2(0, 2 * s), 18 * s, 9 * s, P["shadow"])
	var col: Color = P["cliff_slate"] if hit_flash <= 0.0 else Color.WHITE
	_draw_ellipse(Vector2(0, -12 * s), 16 * s, 12 * s, col, true)
	# Tusks
	draw_line(Vector2(10 * s, -8 * s), Vector2(18 * s, -13 * s), P["path_cream"], 2.5 * s)
	draw_line(Vector2(-10 * s, -8 * s), Vector2(-18 * s, -13 * s), P["path_cream"], 2.5 * s)


func _draw_boss(s: float) -> void:
	_draw_ellipse(Vector2(0, 4 * s), 34 * s, 16 * s, P["shadow"])
	var col: Color = P["crimson"] if hit_flash <= 0.0 else Color.WHITE
	_draw_ellipse(Vector2(0, -26 * s), 24 * s, 26 * s, col, true)
	_draw_ellipse(Vector2(0, -52 * s), 17 * s, 16 * s, P["crimson"], true)
	# Gold crown & shoulder armor
	_draw_poly(PackedVector2Array([
		Vector2(-14 * s, -62 * s), Vector2(14 * s, -62 * s),
		Vector2(10 * s, -74 * s), Vector2(-10 * s, -74 * s)
	]), P["gold"])
	draw_line(Vector2(26 * s, 2 * s), Vector2(26 * s, -62 * s), P["gold"], 4.5 * s)
