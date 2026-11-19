extends RefCounted

const ART := "res://assets/survivor/polish/"
const SUMMON_TIME := 0.72
const SEQUENCE_PIVOT := Vector2(224, 340)

static var _textures := {}


static func texture(id: String) -> Texture2D:
	if not _textures.has(id):
		var path := "res://assets/survivor/" + id if id.begins_with("summon/") else ART + id
		_textures[id] = load(path + ".png")
	return _textures[id] as Texture2D


static func swap(sprite: Sprite2D, id: String, width: float) -> void:
	sprite.texture = texture(id)
	sprite.scale = Vector2.ONE * width / sprite.texture.get_width()


static func sprite(parent: Node, id: String, at: Vector2, width: float) -> Sprite2D:
	var node := Sprite2D.new()
	node.name = "FX_" + id
	node.position = at
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	swap(node, id, width)
	parent.add_child(node, true)
	return node


static func burst(parent: Node, id: String, at: Vector2, width: float, life: float,
		drift := Vector2.ZERO, opacity := 1.0) -> Sprite2D:
	var node := sprite(parent, id, at, width)
	node.modulate.a = opacity
	var tween := node.create_tween().set_parallel()
	tween.tween_property(node, "modulate:a", 0.0, life).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(node, "position", at + drift, life)
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


static func _sequence_frame(node: Sprite2D, id: String, frame: int) -> void:
	node.texture = texture("%s_%02d" % [id, frame])
