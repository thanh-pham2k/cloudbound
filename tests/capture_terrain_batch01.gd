extends SceneTree
## Native GPU capture + structure assertions. No player or other gameplay object.
const SCENE := preload("res://scenes/hoa_qua_son_terrain.tscn")
const DOC := "res://docs/terrain-batch01/"

func _initialize() -> void:
	call_deferred("capture")

func frame_image(viewport: Viewport, path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png(path)
	assert(error == OK, "Could not save screenshot: " + path)

func capture() -> void:
	var scene := SCENE.instantiate()
	scene.get_node("Nature").free()
	scene.get_node("Village").free()
	root.add_child(scene)
	await process_frame
	assert(scene.get_child_count() == 6, "Terrain should contain five material layers + one camera only")
	for child in scene.get_children():
		assert(child is Polygon2D or child is Camera2D, "Non-terrain object added")
		if child is Polygon2D:
			assert(child.material.get_shader_parameter("tile_scale") == 0.5, "Inconsistent tile scale")
	for name in ["grass_fill","dirt_fill","grass_dirt_edge","path_corner","path_t_junction","cliff_straight","cliff_outer_corner","cliff_inner_corner","stone_fill"]:
		var tex := load("res://assets/sprites/batch01/"+name+".png") as Texture2D
		assert(tex != null and tex.get_size() == Vector2(414,414), "Wrong extraction size: " + name)
	await frame_image(root, DOC+"terrain-overview.png")
	scene.camera.zoom = Vector2.ONE*1.25
	scene.camera.position = Vector2(720,760)
	await frame_image(root, DOC+"secret-junction.png")
	scene.camera.position = Vector2(740,240)
	await frame_image(root, DOC+"north-cliffs.png")
	# Exact source-pixel viewport permits independent silhouette/coverage comparison.
	var native := SubViewport.new()
	native.name = "NativeValidationViewport"
	native.size = Vector2i(1254,1254)
	native.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(native)
	var exact := SCENE.instantiate()
	exact.get_node("Nature").free()
	exact.get_node("Village").free()
	native.add_child(exact)
	await process_frame
	exact.camera.zoom = Vector2.ONE
	await frame_image(native, DOC+"terrain-native.png")
	print("PASS: 9 native assets, five uniformly scaled terrain layers, no gameplay objects; 4 GPU captures saved.")
	quit(0)
