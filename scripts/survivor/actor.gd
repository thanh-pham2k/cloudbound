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
# Role-specific full-costume combat sequences from assets/survivor/combat/ (4 frames: ready, windup, strike, recovery).
const MONKEY_ATTACKS := {
	"staff": [
		["combat/staff_00", "combat/staff_01", "combat/staff_02", "combat/staff_03"],
		["combat/staff_04", "combat/staff_05", "combat/staff_06", "combat/staff_07"],
		["combat/staff_08", "combat/staff_09", "combat/staff_10", "combat/staff_11"],
	],
	"archer": [
		["combat/archer_00", "combat/archer_01", "combat/archer_02", "combat/archer_03"],
		["combat/archer_04", "combat/archer_05", "combat/archer_06", "combat/archer_07"],
	],
	"mage": [
		["combat/mage_00", "combat/mage_01", "combat/mage_02", "combat/mage_03"],
		["combat/mage_04", "combat/mage_05", "combat/mage_06", "combat/mage_07"],
	],
	"tank": [
		["combat/tank_04", "combat/tank_05", "combat/tank_06", "combat/tank_07"],
	],
	"healer": [
		["combat/healer_00", "combat/healer_01", "combat/healer_02", "combat/healer_03"],
		["combat/healer_04", "combat/healer_05", "combat/healer_06", "combat/healer_07"],
	],
}
const MONKEY_ROLE_POSES := {
	"staff": {
		"idle": ["combat/staff_00", "combat/staff_04"],
		"move": ["combat/staff_08", "combat/staff_11"],
		"cheer": ["combat/staff_05"],
		"hurt": ["combat/staff_01"],
		"dead": ["combat/staff_01"],
	},
	"archer": {
		"idle": ["combat/archer_00", "combat/archer_08"],
		"move": ["combat/archer_09", "combat/archer_10"],
		"cheer": ["combat/archer_11"],
		"hurt": ["combat/archer_04"],
		"dead": ["combat/archer_04"],
	},
	"mage": {
		"idle": ["combat/mage_00", "combat/mage_08"],
		"move": ["combat/mage_10", "combat/mage_09"],
		"cheer": ["combat/mage_11"],
		"hurt": ["combat/mage_08"],
		"dead": ["combat/mage_08"],
	},
	"tank": {
		"idle": ["combat/tank_00", "combat/tank_04"],
		"move": ["combat/tank_04", "combat/tank_05"],
		"cheer": ["combat/tank_01"],
		"hurt": ["combat/tank_02"],
		"dead": ["combat/tank_02"],
	},
	"healer": {
		"idle": ["combat/healer_00", "combat/healer_04"],
		"move": ["combat/healer_00", "combat/healer_07"],
		"cheer": ["combat/healer_03", "combat/healer_06"],
		"hurt": ["combat/healer_05"],
		"dead": ["combat/healer_05"],
	},
}
const TANK_GUARD := ["combat/tank_01", "combat/tank_02", "combat/tank_03"]
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

# Monkey Windup -> Strike -> Recovery pending combat state.
var pending_attack := false
var pending_target: Node2D
var pending_damage := 0
var pending_variation := 0
var attack_count := 0

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
var _hit_stop_time := 0.0
var _knockback_offset := Vector2.ZERO
var _death_time := 0.57
var _faces_left := false
var _entry: Sprite2D
var _entry_time := 0.0

var _attack_clip: Array = []
var _attack_windup := 0.14
var _attack_strike := 0.11
var _attack_recovery := 0.12
var _attack_phase := ""
var _attack_variation := 0
var _guard_time := 0.0


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
	var target_px := 35.0 if id in ["staff", "magic", "heal"] else 33.0
	_equipment.scale = Vector2.ONE * minf(target_px / art.get_height(), target_px / art.get_width())
	_equipment.show()


func face(x: float) -> void:
	if absf(x) > 8.0:
		_faces_left = x < 0.0


func move_pose(moving: bool) -> void:
	_next_pose = "move" if moving else "idle"


func begin_attack(role_name: String, windup_sec: float, strike_sec: float, recovery_sec: float, variation: int) -> void:
	_attack_windup = windup_sec
	_attack_strike = strike_sec
	_attack_recovery = recovery_sec
	_attack_variation = variation
	_action_time = windup_sec + strike_sec + recovery_sec
	_guard_time = 0.0
	if kind == "monkey" and MONKEY_ATTACKS.has(role_name):
		var clips: Array = MONKEY_ATTACKS[role_name]
		_attack_clip = clips[variation % clips.size()]
	else:
		_attack_clip = []
	var pose := "attack"
	if kind == "monkey":
		if weapon_id == "bow":
			pose = "release"
		elif weapon_id in ["magic", "heal"]:
			pose = "cast"
	_attack_phase = "windup"
	_set_pose(pose, true)


func attack_pose(duration: float) -> void:
	_attack_clip = []
	_attack_phase = ""
	_action_time = duration
	var pose := "attack"
	if kind == "monkey":
		if weapon_id == "bow":
			pose = "release"
		elif weapon_id in ["magic", "heal"]:
			pose = "cast"
	_set_pose(pose, true)


func guard_pose() -> void:
	if kind == "monkey" and role == "tank" and hp > 0 and _action_time <= 0.0:
		_guard_time = 0.28
		_pose_time = 0.0


func command_pose() -> void:
	if _action_time == 0.0:
		_action_time = 0.20
		_set_pose("command", true)


func celebrate() -> void:
	_attack_clip = []
	_attack_phase = ""
	_action_time = 2.1
	_set_pose("cheer", true)


func arrive() -> void:
	_entry_time = Polish.SUMMON_TIME
	_entry = Polish.summon_sequence(self, "arrival", Vector2(0, -2), 92.0)
	_entry.modulate.a = 0.72
	_sprite.modulate.a = 0.15
	_equipment.hide()


func hit_stop(duration: float) -> void:
	_hit_stop_time = maxf(_hit_stop_time, duration)


func apply_knockback(impulse: Vector2) -> void:
	_knockback_offset = (_knockback_offset + impulse).limit_length(18.0)


func has_hit_flash() -> bool:
	return _hit_time > 0.0


func weapon_tip_position() -> Vector2:
	var direction := -1.0 if _faces_left else 1.0
	var base: Vector2 = _weapon_transform().origin
	var reach := Vector2(12.0 * direction, -8.0)
	if weapon_id == "bow":
		reach = Vector2(10.0 * direction, -2.0)
	elif weapon_id in ["magic", "heal"]:
		reach = Vector2(8.0 * direction, -14.0)
	return position + base + reach


func hurt(amount: int) -> void:
	hp = maxi(0, hp - amount)
	_hit_time = 0.18
	if kind == "hero":
		_action_time = 0.0
	elif kind == "monkey":
		if role == "tank" and hp > 0:
			guard_pose()
		elif not pending_attack:
			_action_time = 0.0
	if hp == 0:
		pending_attack = false
		_attack_clip = []
		_attack_phase = ""
		_set_pose("dead")
		_entry_time = 0.0
		if is_instance_valid(_entry):
			_entry.hide()
			_entry.queue_free()


func _process(delta: float) -> void:
	if _hit_stop_time > 0.0:
		_hit_stop_time = maxf(0.0, _hit_stop_time - delta)
		_render_frame()
		queue_redraw()
		return
	_pose_time += delta
	_entry_time = maxf(0.0, _entry_time - delta)
	_hit_time = maxf(0.0, _hit_time - delta)
	_guard_time = maxf(0.0, _guard_time - delta)
	_action_time = maxf(0.0, _action_time - delta)
	_knockback_offset = _knockback_offset.lerp(Vector2.ZERO, 1.0 - exp(-18.0 * delta))
	if hp == 0:
		_death_time -= delta
		modulate.a = clampf(_death_time / 0.24, 0.0, 1.0)
		if _death_time <= 0.0:
			queue_free()
	elif _action_time == 0.0:
		_attack_clip = []
		_attack_phase = ""
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


func _current_monkey_combat_texture() -> Texture2D:
	if _guard_time > 0.0 and _action_time <= 0.0 and role == "tank":
		var p := 1.0 - clampf(_guard_time / 0.28, 0.0, 1.0)
		var idx := 0 if p < 0.20 else (1 if p < 0.72 else 2)
		return Polish.texture(TANK_GUARD[idx])
	if not _attack_clip.is_empty() and _action_time > 0.0:
		if _pose_time < _attack_windup:
			_attack_phase = "windup"
			var idx := 0 if _pose_time < _attack_windup * 0.35 else 1
			return Polish.texture(str(_attack_clip[idx]))
		elif _pose_time < _attack_windup + _attack_strike:
			_attack_phase = "strike"
			return Polish.texture(str(_attack_clip[2]))
		_attack_phase = "recovery"
		return Polish.texture(str(_attack_clip[3]))
	if MONKEY_ROLE_POSES.has(role):
		var role_poses: Dictionary = MONKEY_ROLE_POSES[role]
		var pose_key := _pose if role_poses.has(_pose) else "idle"
		var frames: Array = role_poses[pose_key]
		var rate := 5.0 if pose_key == "idle" else 8.0
		return Polish.texture(str(frames[_animation_frame(frames.size(), rate, pose_key in ["idle", "move"])]))
	return null


func _weapon_transform() -> Dictionary:
	var direction := -1.0 if _faces_left else 1.0
	var pos := Vector2(19.0, -21.0)
	var deg := 0.0
	var scale_mult := 1.0
	var behind := false

	if _guard_time > 0.0 and role == "tank":
		pos = Vector2(21.0, -25.0)
		deg = -8.0
		scale_mult = 1.14
	elif _action_time > 0.0 and _pose in ["attack", "release", "cast"]:
		var phase := _attack_phase if not _attack_phase.is_empty() else "strike"
		match weapon_id:
			"staff":
				if _attack_variation == 1:
					# Overhead slam
					if phase == "windup":
						pos = Vector2(3.0, -56.0)
						deg = -84.0
					elif phase == "strike":
						pos = Vector2(26.0, -14.0)
						deg = 70.0
						scale_mult = 1.12
					else:
						pos = Vector2(18.0, -20.0)
						deg = 24.0
				elif _attack_variation == 2:
					# Power thrust
					if phase == "windup":
						pos = Vector2(-10.0, -25.0)
						deg = -12.0
						behind = true
					elif phase == "strike":
						pos = Vector2(31.0, -25.0)
						deg = 8.0
						scale_mult = 1.10
					else:
						pos = Vector2(20.0, -22.0)
						deg = 4.0
				else:
					# Horizontal slash
					if phase == "windup":
						pos = Vector2(-11.0, -30.0)
						deg = -56.0
						behind = true
					elif phase == "strike":
						pos = Vector2(27.0, -27.0)
						deg = 44.0
						scale_mult = 1.12
					else:
						pos = Vector2(18.0, -22.0)
						deg = 14.0
			"bow":
				if phase == "windup":
					pos = Vector2(18.0, -28.0)
					deg = -8.0
					scale_mult = 0.96
				elif phase == "strike":
					pos = Vector2(25.0, -30.0)
					deg = 5.0
					scale_mult = 1.08
				else:
					pos = Vector2(19.0, -24.0)
					deg = 0.0
			"magic":
				if phase == "windup":
					pos = Vector2(14.0, -39.0)
					deg = -22.0
					scale_mult = 1.06
				elif phase == "strike":
					pos = Vector2(25.0, -35.0)
					deg = 18.0
					scale_mult = 1.12
				else:
					pos = Vector2(18.0, -26.0)
					deg = 4.0
			"shield":
				if phase == "windup":
					pos = Vector2(7.0, -25.0)
					deg = -24.0
				elif phase == "strike":
					pos = Vector2(28.0, -24.0)
					deg = 16.0
					scale_mult = 1.15
				else:
					pos = Vector2(19.0, -22.0)
					deg = 0.0
			"heal":
				if phase == "windup":
					pos = Vector2(12.0, -36.0)
					deg = -18.0
				elif phase == "strike":
					pos = Vector2(23.0, -42.0)
					deg = 12.0
					scale_mult = 1.10
				else:
					pos = Vector2(18.0, -28.0)
					deg = 2.0
	elif _pose == "move":
		pos.y += sin(_pose_time * 19.0) * 2.0
		deg = sin(_pose_time * 19.0) * 5.0

	return {
		"origin": Vector2(pos.x * direction, pos.y),
		"rotation": deg_to_rad(deg * direction),
		"scale_mult": scale_mult,
		"behind": behind,
	}


func _render_frame() -> void:
	var art: Texture2D
	var combat_art: Texture2D
	if kind == "monkey":
		combat_art = _current_monkey_combat_texture()
	if combat_art != null:
		art = combat_art
	elif _enemy_clips != null:
		var index := _animation_frame(_enemy_clips.get_frame_count(_pose),
			_enemy_clips.get_animation_speed(_pose), _enemy_clips.get_animation_loop(_pose))
		art = _enemy_clips.get_frame_texture(_pose, index)
	else:
		var poses: Array = POSES[kind][_pose]
		var rate := 6.0 if _pose == "idle" else (9.0 if _pose == "move" else 11.0)
		art = _frames[poses[_animation_frame(poses.size(), rate, _pose in ["idle", "move"])]]

	var draw_scale := _size_scale
	if combat_art != null:
		draw_scale = HEIGHTS["monkey"] / float(art.get_height())
	var size := art.get_size() * draw_scale
	var direction := -1.0 if _faces_left else 1.0
	_sprite.texture = art
	var stretch := Vector2.ONE
	if _hit_time > 0.11:
		stretch = Vector2(1.08, 0.93)
	elif combat_art != null and _attack_phase == "strike":
		stretch = Vector2(1.06, 0.96)
	_sprite.scale = Vector2.ONE * draw_scale * stretch
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
	var lunge := Vector2.ZERO
	if combat_art != null and _attack_phase == "strike" and weapon_id in ["staff", "shield"]:
		lunge = Vector2(5.0 * direction, -2.0)
	_sprite.position = Vector2(0.0, -size.y * 0.5 - (1.0 - reveal) * 8.0 - lift) + _knockback_offset + lunge
	if _hit_time > 0.11:
		_sprite.modulate = Color(1.75, 1.32, 1.15, 1.0)
	elif _hit_time > 0.0:
		_sprite.modulate = Color("#ffb6a0")
	else:
		_sprite.modulate = Color.WHITE
	_sprite.modulate.a = lerpf(0.15, 1.0, reveal)

	var has_baked_weapon := kind == "monkey" and MONKEY_ROLE_POSES.has(role)
	if _equipment.texture != null and not has_baked_weapon:
		var wt := _weapon_transform()
		var target_px := 35.0 if weapon_id in ["staff", "magic", "heal"] else 33.0
		var base_s := minf(target_px / _equipment.texture.get_height(), target_px / _equipment.texture.get_width())
		_equipment.flip_h = _faces_left
		_equipment.position = wt.origin + _knockback_offset + lunge
		_equipment.rotation = wt.rotation
		_equipment.scale = Vector2.ONE * base_s * float(wt.scale_mult)
		_equipment.z_index = -1 if wt.behind else 1
		_equipment.modulate.a = reveal
		_equipment.visible = hp > 0 and reveal > 0.25
	else:
		_equipment.visible = false


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
