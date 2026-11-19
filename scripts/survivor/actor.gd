extends Node2D

const EnemyLooks := preload("res://scripts/survivor/enemy_looks.gd")
const Polish := preload("res://scripts/survivor/polish.gd")
const SUMMON_ART := "res://assets/survivor/summon/"
const ART := "res://assets/survivor/"
# Frame indexes follow the supplied sheets in row-major order.
const POSES := {
	"hero": {"idle": [0, 3, 8], "move": [4, 7], "attack": [1, 2, 3],
		"command": [5, 6], "cheer": [10], "hurt": [9], "dead": [11]},
	"monkey": {"idle": [0, 7], "move": [0, 7], "attack": [2, 9, 7],
		"release": [2, 9, 7], "cast": [4, 5, 8], "cheer": [6, 11], "hurt": [1, 10], "dead": [3]},
	"slime": {"idle": [0, 1], "move": [0, 1, 2, 3],
		"attack": [4, 5], "hurt": [6], "dead": [7]},
	"boar": {"idle": [0, 1], "move": [0, 1, 2, 3],
		"attack": [4, 5], "hurt": [6], "dead": [7]},
	"boss": {"idle": [0, 1], "move": [0, 1, 2, 3],
		"attack": [4, 5], "hurt": [6], "dead": [7]},
}
const HEIGHTS := {"hero": 102.0, "monkey": 67.0, "slime": 65.0, "boar": 78.0, "boss": 152.0}

var kind: String
var appearance: String
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
var role := ""
var role_icon: Texture2D
var formation_row := -1
var goal_x := 0.0
var assigned_lane := -1
var enemy_lane := -1
var strikes_rear_line := false

var _sprite := Sprite2D.new()
var _equipment := Sprite2D.new()
var _frames: Array[Texture2D] = []
var _enemy_clips: SpriteFrames
var _art_faces_left := false
var _lift := 0.0
var _size_scale: float
var _pose := "idle"
var _next_pose := "idle"
var _pose_time := 0.0
var _action_time := 0.0
var _hit_time := 0.0
var _death_time := 0.57
var _faces_left := false
var _entry: Sprite2D
var _entry_time := 0.0


func setup(actor_kind: String, health: int, foot_radius: float, look := "") -> void:
	kind = actor_kind
	appearance = look
	hp = health
	max_hp = health
	radius = foot_radius
	if not appearance.is_empty():
		_enemy_clips = EnemyLooks.clips(appearance)
		_size_scale = 0.5
		_art_faces_left = appearance in EnemyLooks.LEFT_FACING
		_faces_left = _art_faces_left
		_lift = 6.0 if appearance in EnemyLooks.FLOATING else 0.0
	else:
		var count := 12 if kind in ["hero", "monkey"] else 8
		for i in count:
			match kind:
				"hero": _frames.append(Polish.texture("wukong_%02d" % i))
				"monkey": _frames.append(load(SUMMON_ART + "unit_%02d.png" % i))
				_: _frames.append(load(ART + "%s_%02d.png" % [kind, i]))
		_size_scale = HEIGHTS[kind] / _frames[0].get_height()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_sprite)
	add_child(_equipment)
	_equipment.hide()
	_render_frame()


func equip(id: String, art: Texture2D) -> void:
	weapon_id = id
	_equipment.texture = art
	_equipment.scale = Vector2.ONE * minf(31.0 / art.get_height(), 31.0 / art.get_width())
	_equipment.show()


func face(x: float) -> void:
	if absf(x) > 8.0:
		_faces_left = x < 0.0


func move_pose(moving: bool) -> void:
	_next_pose = "move" if moving else "idle"


func attack_pose(duration: float) -> void:
	_action_time = duration
	var pose := "attack"
	if kind == "monkey":
		if weapon_id == "bow":
			pose = "release"
		elif weapon_id in ["magic", "heal"]:
			pose = "cast"
	_set_pose(pose, true)


func command_pose() -> void:
	if _action_time == 0.0:
		_action_time = 0.20
		_set_pose("command", true)


func celebrate() -> void:
	_action_time = 2.1
	_set_pose("cheer", true)


func arrive() -> void:
	_entry_time = Polish.SUMMON_TIME
	_entry = Polish.summon_sequence(self, "arrival", Vector2(0, -2), 92.0)
	_entry.modulate.a = 0.72
	_sprite.modulate.a = 0.15
	_equipment.hide()


func has_hit_flash() -> bool:
	return _hit_time > 0.0


func hurt(amount: int) -> void:
	hp = maxi(0, hp - amount)
	_hit_time = 0.17
	if kind in ["hero", "monkey"]:
		_action_time = 0.0
	if hp == 0:
		_set_pose("dead")
		_entry_time = 0.0
		if is_instance_valid(_entry):
			_entry.hide()
			_entry.queue_free()


func _process(delta: float) -> void:
	_pose_time += delta
	_entry_time = maxf(0.0, _entry_time - delta)
	_hit_time = maxf(0.0, _hit_time - delta)
	_action_time = maxf(0.0, _action_time - delta)
	if hp == 0:
		_death_time -= delta
		modulate.a = clampf(_death_time / 0.24, 0.0, 1.0)
		if _death_time <= 0.0:
			queue_free()
	elif _action_time == 0.0:
		_set_pose("hurt" if _hit_time > 0.0 else _next_pose)
	_render_frame()
	queue_redraw()


func _set_pose(pose: String, restart: bool = false) -> void:
	if _pose != pose or restart:
		_pose = pose
		_pose_time = 0.0


func _animation_frame(count: int, rate: float, looping: bool) -> int:
	var index := int(_pose_time * rate)
	return index % count if looping else mini(index, count - 1)


func _render_frame() -> void:
	var art: Texture2D
	if _enemy_clips != null:
		var index := _animation_frame(_enemy_clips.get_frame_count(_pose),
			_enemy_clips.get_animation_speed(_pose), _enemy_clips.get_animation_loop(_pose))
		art = _enemy_clips.get_frame_texture(_pose, index)
	else:
		var poses: Array = POSES[kind][_pose]
		var rate := 6.0 if _pose == "idle" else (9.0 if _pose == "move" else 11.0)
		art = _frames[poses[_animation_frame(poses.size(), rate, _pose in ["idle", "move"])]]
	var size := art.get_size() * _size_scale
	var direction := -1.0 if _faces_left else 1.0
	_sprite.texture = art
	_sprite.scale = Vector2.ONE * _size_scale
	_sprite.flip_h = _faces_left != _art_faces_left
	var reveal := clampf(1.0 - _entry_time / 0.40, 0.0, 1.0)
	if hp > 0 and _pose in ["attack", "release", "cast"]:
		reveal = maxf(reveal, 0.72)
	if is_instance_valid(_entry):
		_entry.flip_h = _faces_left
		_entry.modulate.a = 0.70 * _entry_time / Polish.SUMMON_TIME
	var lift := _lift if hp > 0 else 0.0
	if kind == "monkey":
		lift -= 3.0 * _size_scale
		if _pose == "move":
			lift += absf(sin(_pose_time * 19.0)) * 3.0
	_sprite.position = Vector2(0.0, -size.y * 0.5 - (1.0 - reveal) * 8.0 - lift)
	_sprite.modulate = Color("#ffb6a0") if _hit_time > 0.0 else Color.WHITE
	_sprite.modulate.a = lerpf(0.15, 1.0, reveal)
	_equipment.flip_h = _faces_left
	var hands := Vector2(19, -29) if _pose in ["attack", "release", "cast"] else Vector2(20, -21)
	_equipment.position = Vector2(hands.x * direction, hands.y)
	_equipment.modulate.a = reveal
	_equipment.visible = _equipment.texture != null and hp > 0 and reveal > 0.25


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.40))
	draw_circle(Vector2.ZERO, radius * 1.28, Color(0.13, 0.24, 0.12, 0.26), true, -1, true)
	draw_set_transform(Vector2.ZERO)
	if role_icon != null and hp > 0:
		draw_texture_rect(role_icon, Rect2(17, -79, 16, 16), false, Color(1, 1, 1, 0.86))
	if hp > 0 and (kind == "monkey" or (kind in ["slime", "boar"] and hp < max_hp)):
		var width := radius * 2.0
		var top := -float(HEIGHTS[kind]) - 9.0
		draw_rect(Rect2(-width / 2.0, top, width, 5), Color("#37392b"))
		var fill := Color("#c9e97c") if kind == "monkey" else Color("#f29477")
		draw_rect(Rect2(1.0 - width / 2.0, top + 1.0, (width - 2.0) * hp / max_hp, 3), fill)
