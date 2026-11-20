extends RefCounted

const ART := "res://assets/survivor/polish/"
const SUMMON_TIME := 0.72
const SEQUENCE_PIVOT := Vector2(224, 340)
const MAX_ACTIVE_FX := 72

static var _textures := {}


static func texture(id: String) -> Texture2D:
	if not _textures.has(id):
		var path := "res://assets/survivor/" + id if (
			id.begins_with("summon/") or id.begins_with("combat/") or id.begins_with("vfx/")) else ART + id
		_textures[id] = load(path + ".png")
	return _textures[id] as Texture2D


static func swap(sprite: Sprite2D, id: String, width: float) -> void:
	sprite.texture = texture(id)
	sprite.scale = Vector2.ONE * width / sprite.texture.get_width()


static func sprite(parent: Node, id: String, at: Vector2, width: float) -> Sprite2D:
	var node := Sprite2D.new()
	node.name = "FX_" + id.get_file()
	node.position = at
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	swap(node, id, width)
	parent.add_child(node, true)
	return node


static func _trim_transient_fx(parent: Node) -> void:
	if parent.get_child_count() < MAX_ACTIVE_FX:
		return
	for child in parent.get_children():
		if child is Sprite2D and child.has_meta("transient_fx") and not child.is_queued_for_deletion():
			child.queue_free()
			return


static func burst(parent: Node, id: String, at: Vector2, width: float, life: float,
		drift := Vector2.ZERO, opacity := 1.0, scale_from := 0.88, scale_to := 1.06, spin := 0.0) -> Sprite2D:
	_trim_transient_fx(parent)
	var node := sprite(parent, id, at, width)
	node.set_meta("transient_fx", true)
	var base_scale := node.scale
	node.scale = base_scale * scale_from
	node.modulate.a = opacity
	var tween := node.create_tween().set_parallel()
	tween.tween_property(node, "modulate:a", 0.0, life).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(node, "scale", base_scale * scale_to, life).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if drift != Vector2.ZERO:
		tween.tween_property(node, "position", at + drift, life).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if not is_zero_approx(spin):
		tween.tween_property(node, "rotation", node.rotation + spin, life)
	tween.chain().tween_callback(node.queue_free)
	return node


static func summon_sequence(parent: Node, id: String, at: Vector2, width: float) -> Sprite2D:
	var node := sprite(parent, id + "_00", at, width)
	node.offset = node.texture.get_size() * 0.5 - SEQUENCE_PIVOT
	var tween := node.create_tween()
	for frame in range(1, 8):
		tween.tween_interval(SUMMON_TIME / 8.0)
		tween.tween_callback(_sequence_frame.bind(node, id, frame))
	tween.tween_interval(SUMMON_TIME / 8.0)
	tween.tween_callback(node.queue_free)
	return node


static func sequence(parent: Node, ids: Array, at: Vector2, width: float, life: float,
		drift := Vector2.ZERO, opacity := 1.0, angle := 0.0, flip_h := false,
		scale_from := 0.92, scale_to := 1.08) -> Sprite2D:
	_trim_transient_fx(parent)
	var node := sprite(parent, str(ids[0]), at, width)
	node.set_meta("transient_fx", true)
	node.modulate.a = opacity
	node.rotation = angle
	node.flip_h = flip_h
	var step := life / float(maxi(1, ids.size()))
	var tween := node.create_tween()
	for i in range(1, ids.size()):
		var frac := float(i) / float(maxi(1, ids.size() - 1))
		var target_w := lerpf(width * scale_from, width * scale_to, frac)
		tween.tween_interval(step)
		tween.tween_callback(_swap_frame.bind(node, str(ids[i]), target_w))
	tween.tween_property(node, "modulate:a", 0.0, step).set_ease(Tween.EASE_IN)
	tween.tween_callback(node.queue_free)
	if drift != Vector2.ZERO:
		var move := node.create_tween()
		move.tween_property(node, "position", at + drift, life)
	return node


static func _swap_frame(node: Sprite2D, id: String, width: float) -> void:
	if is_instance_valid(node):
		swap(node, id, width)


static func _sequence_frame(node: Sprite2D, id: String, frame: int) -> void:
	node.texture = texture("%s_%02d" % [id, frame])
