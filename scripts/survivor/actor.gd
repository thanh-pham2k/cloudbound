extends Node2D

const ART := "res://assets/survivor/"
# Frame indexes follow the supplied sheets in row-major order.
const POSES := {
	"hero": {"idle": [0, 1, 2, 3], "move": [4, 5, 6, 7],
		"attack": [8, 9, 10], "hurt": [11], "dead": [11]},
	"monkey": {"idle": [0, 1, 2, 3], "move": [4, 5, 6, 7],
		"attack": [8, 9], "hurt": [10], "dead": [11]},
	"slime": {"idle": [0, 1], "move": [0, 1, 2, 3],
		"attack": [4, 5], "hurt": [6], "dead": [7]},
	"boar": {"idle": [0, 1], "move": [0, 1, 2, 3],
		"attack": [4, 5], "hurt": [6], "dead": [7]},
	"boss": {"idle": [0, 1], "move": [0, 1, 2, 3],
		"attack": [4, 5], "hurt": [6], "dead": [7]},
}
const HEIGHTS := {"hero": 102.0, "monkey": 67.0, "slime": 65.0, "boar": 78.0, "boss": 152.0}

var kind: String
var hp: int
var max_hp: int
var radius: float
var weapon_id: String
var cooldown := 0.0
var speed := 0.0
var attack_range := 0.0
var attack_damage := 0
var windup := 0.0
var strike_position := Vector2.ZERO
var gold_reward := 0
var xp_reward := 0
var slot := -1
var enemy_lane := -1
var strikes_rear_line := false

var _sprite := Sprite2D.new()
var _equipment := Sprite2D.new()
var _frames: Array[Texture2D] = []
var _size_scale: float
var _pose := "idle"
var _next_pose := "idle"
var _pose_time := 0.0
var _action_time := 0.0
var _hit_time := 0.0
var _death_time := 0.57
var _faces_left := false


func setup(actor_kind: String, health: int, foot_radius: float) -> void:
	kind = actor_kind
	hp = health
	max_hp = health
	radius = foot_radius
	var count := 12 if kind in ["hero", "monkey"] else 8
	for i in count:
		_frames.append(load(ART + "%s_%02d.png" % [kind, i]))
	_size_scale = HEIGHTS[kind] / _frames[0].get_height()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_sprite)
	add_child(_equipment)
	_equipment.hide()
	_render_frame(0)


func equip(id: String, art: Texture2D) -> void:
	weapon_id = id
	_equipment.texture = art
	_equipment.scale = Vector2.ONE * 31.0 / art.get_height()
	_equipment.show()


func face(x: float) -> void:
	if absf(x) > 8.0:
		_faces_left = x < 0.0


func move_pose(moving: bool) -> void:
	_next_pose = "move" if moving else "idle"


func attack_pose(duration: float) -> void:
	_action_time = duration
	_set_pose("attack", true)


func hurt(amount: int) -> void:
	hp = maxi(0, hp - amount)
	_hit_time = 0.17
	if hp == 0:
		_set_pose("dead")
		if kind == "hero":
			# The supplied Wukong sheet ends on a hit reaction.
			_sprite.rotation = -0.38 if _faces_left else 0.38


func _process(delta: float) -> void:
	_pose_time += delta
	_hit_time = maxf(0.0, _hit_time - delta)
	_action_time = maxf(0.0, _action_time - delta)
	if hp == 0:
		_death_time -= delta
		modulate.a = clampf(_death_time / 0.24, 0.0, 1.0)
		if _death_time <= 0.0:
			queue_free()
	elif _action_time == 0.0:
		_set_pose("hurt" if _hit_time > 0.0 else _next_pose)
	var frames: Array = POSES[kind][_pose]
	var index := int(_pose_time * (9.0 if _pose == "attack" else 7.0))
	index = mini(index, frames.size() - 1) if _pose == "attack" else index % frames.size()
	_render_frame(frames[index])
	queue_redraw()


func _set_pose(pose: String, restart: bool = false) -> void:
	if _pose != pose or restart:
		_pose = pose
		_pose_time = 0.0


func _render_frame(index: int) -> void:
	var art := _frames[index]
	var size := art.get_size() * _size_scale
	var direction := -1.0 if _faces_left else 1.0
	_sprite.texture = art
	_sprite.scale = Vector2.ONE * _size_scale
	_sprite.flip_h = _faces_left
	var frame_offset := 0.0
	if kind == "hero" and index in [9, 10]:
		frame_offset = 7.0 * direction
	_sprite.position = Vector2(frame_offset, -size.y * 0.5)
	_sprite.modulate = Color("#ffb6a0") if _hit_time > 0.0 else Color.WHITE
	_equipment.flip_h = _faces_left
	_equipment.position = Vector2(22.0 * direction, -20.0)
	_equipment.visible = _equipment.texture != null and hp > 0


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.40))
	draw_circle(Vector2.ZERO, radius * 1.28, Color(0.13, 0.24, 0.12, 0.26), true, -1, true)
	draw_set_transform(Vector2.ZERO)
	if hp > 0 and (kind == "monkey" or (kind in ["slime", "boar"] and hp < max_hp)):
		var width := radius * 2.0
		var top := -float(HEIGHTS[kind]) - 9.0
		draw_rect(Rect2(-width / 2.0, top, width, 5), Color("#37392b"))
		var fill := Color("#c9e97c") if kind == "monkey" else Color("#f29477")
		draw_rect(Rect2(1.0 - width / 2.0, top + 1.0, (width - 2.0) * hp / max_hp, 3), fill)
