class_name TerrainBatch01
extends Node2D
## Terrain-only approved Organic S-Curve. No gameplay or prop scene is instantiated.
const DATA := "res://assets/blueprints/terrain_batch01/"
const ART := "res://assets/sprites/batch01/"
const BLEND := preload("res://scripts/shaders/terrain_repeat_blend.gdshader")
var layout: Dictionary
var camera: Camera2D
var terrain_size := Vector2.ZERO

func _ready() -> void:
	layout = JSON.parse_string(FileAccess.get_file_as_string(DATA + "layout.json"))
	terrain_size = Vector2(layout.size[0], layout.size[1])
	RenderingServer.set_default_clear_color(Color("b8d4e3"))
	_add_surface("Grass", "grass_fill", "land_mask")
	_add_surface("SecretNook", "grass_fill", "secret_nook_mask", null, Color(1.12,1.08,1.02,1.0))
	_add_surface("Path", "dirt_fill", "path_mask")
	# The purple regions of the approved plan remain flat rock boundary footprints.
	# Do not invent elevation or expand the approved silhouette with extruded walls.
	_add_surface("CliffBoundaries", "stone_fill", "cliff_mask")
	# Sample an inspected opaque native face crop; no resizing or mesh deformation.
	var face_atlas := load(ART + "cliff_straight.png") as Texture2D
	var face_image := face_atlas.get_image().get_region(Rect2i(0,238,414,24))
	var face_texture := ImageTexture.create_from_image(face_image)
	_add_surface("CliffRim", "", "boundary_rim_mask", face_texture)
	camera = Camera2D.new()
	camera.name = "TerrainCamera"
	camera.position = terrain_size * 0.5
	add_child(camera)
	_fit_camera()
	get_viewport().size_changed.connect(_fit_camera)

func _add_surface(node_name: String, tile: String, mask_name: String, texture: Texture2D = null, tint: Color = Color.WHITE) -> void:
	var quad := Polygon2D.new()
	quad.name = node_name
	quad.polygon = PackedVector2Array([Vector2.ZERO, Vector2(terrain_size.x,0),terrain_size,Vector2(0,terrain_size.y)])
	var material := ShaderMaterial.new()
	material.shader = BLEND
	var tex := texture if texture != null else load(ART + tile + ".png") as Texture2D
	material.set_shader_parameter("tile_texture", tex)
	material.set_shader_parameter("terrain_mask", load(DATA + mask_name + ".png"))
	material.set_shader_parameter("world_size", terrain_size)
	material.set_shader_parameter("tile_pixels", Vector2(tex.get_width(),tex.get_height()))
	material.set_shader_parameter("tile_scale", 0.5)
	material.set_shader_parameter("blend_fraction", 0.12)
	material.set_shader_parameter("tint", tint)
	quad.material = material
	add_child(quad)

func _fit_camera() -> void:
	var size := get_viewport_rect().size - Vector2(64,64)
	var factor := minf(size.x / terrain_size.x, size.y / terrain_size.y)
	camera.zoom = Vector2.ONE * factor
