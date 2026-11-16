extends RefCounted

## Placement helpers for native-size cutouts. Actor artwork shares the body's foot origin.

static func place(parent: Node2D, art: Texture2D, origin: Vector2,
		scale_factor: float, grounded: bool = false) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = art
	sprite.position = origin
	sprite.scale = Vector2.ONE * scale_factor
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if grounded:
		sprite.offset.y = 2.0 - art.get_height() * 0.5
	parent.add_child(sprite)
	return sprite


static func set_actor_pose(sprite: AnimatedSprite2D, art: Texture2D, height: float) -> void:
	var frames := SpriteFrames.new()
	frames.add_frame(&"default", art)
	sprite.sprite_frames = frames
	sprite.offset = Vector2(0.0, 2.0 - art.get_height() * 0.5)
	sprite.scale = Vector2.ONE * height / art.get_height()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


static func make_meter(art: Texture2D, region: Rect2, width: float) -> TextureProgressBar:
	var texture := AtlasTexture.new()
	texture.atlas = art
	texture.region = region
	texture.filter_clip = true
	var meter := TextureProgressBar.new()
	meter.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	meter.texture_under = texture
	meter.texture_progress = texture
	meter.tint_under = Color(0.28, 0.25, 0.24)
	meter.scale = Vector2.ONE * width / region.size.x
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return meter
