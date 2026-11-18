class_name SegmentationSlice
extends Node2D
## Editable semantic pilot: all region geometry and prop anchors come from blueprint.json.
const BLUEPRINT_PATH := "res://assets/blueprints/segmentation_slice/blueprint.json"
const ART := "res://assets/sprites/concept/"
var blueprint: Dictionary
var player: PlayerController
var entities_root: Node2D
var camera: Camera2D
var land: PackedVector2Array
var route: PackedVector2Array
var items: Dictionary = {}
var quest_started := false
var peaches := 0
var overview := false
var debug_visible := false
var _debug_layer: Node2D
var _status: Label
var _prompt: Label
var _message := "Gặp Trưởng Lão rồi khám phá đường lên Rừng Đào."

func _ready() -> void:
	blueprint = JSON.parse_string(FileAccess.get_file_as_string(BLUEPRINT_PATH))
	land = world_polygon(blueprint.surfaces[0].polygon)
	route = world_polygon(blueprint.route)
	_build_terrain()
	_build_boundary()
	entities_root = Node2D.new()
	entities_root.name = "Entities"
	entities_root.y_sort_enabled = true
	add_child(entities_root)
	for entry in blueprint.instances:
		_build_instance(entry)
	player = PlayerController.new()
	player.position = world_point(blueprint.spawn)
	player.spawn_position = player.position
	entities_root.add_child(player)
	player._visual.item_scale = 0.86
	# Reapply scale when using the same animation frame.
	player._visual._last_tex_path = ""
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.zoom = Vector2.ONE * 0.92
	player.add_child(camera)
	_build_hud()
	_build_debug()

func world_point(point: Array) -> Vector2:
	return (Vector2(point[0],point[1])-Vector2(blueprint.origin[0],blueprint.origin[1])) * float(blueprint.units_per_pixel)

func world_polygon(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(world_point(point))
	return result

func _build_terrain() -> void:
	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([Vector2(-2500,-2500),Vector2(3500,-2500),Vector2(3500,2000),Vector2(-2500,2000)])
	sky.color = Color("b8d4e3")
	sky.z_index = -40
	add_child(sky)
	for x in [-650,200,1050]:
		_sprite("distant_mountain_layer",Vector2(x,-480),1150,-30)
	for region in blueprint.surfaces:
		_surface(world_polygon(region.polygon),"terrain_grass_fill" if region.kind == "grass" else "terrain_dirt_fill",-10 if region.kind == "grass" else -8)
	# Derive a continuous front cliff from the same contour used by collision.
	var first := 0
	for i in land.size():
		if land[i].x > land[first].x:
			first = i
	var u := 0.0
	for i in range(first,land.size()):
		var a := land[i]
		var b := land[(i+1)%land.size()]
		var face := Polygon2D.new()
		var height_a := 180.0+clampf(-a.y*0.10,0,90)
		var height_b := 180.0+clampf(-b.y*0.10,0,90)
		face.polygon = PackedVector2Array([a+Vector2(0,-2),b+Vector2(0,-2),b+Vector2(0,height_b),a+Vector2(0,height_a)])
		var next_u := u+a.distance_to(b)*1.1
		face.uv = PackedVector2Array([Vector2(u,0),Vector2(next_u,0),Vector2(next_u,256),Vector2(u,256)])
		face.texture = load(ART+"cliff_face_strip.png")
		face.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		face.z_index = -12
		add_child(face)
		u = next_u
	for point in [[25,460],[110,491],[240,470],[354,388]]:
		_sprite("cloud_bank",world_point(point),360,-3).modulate.a = 0.8
	# Petals follow tree feet, rather than covering the walking route at random.
	for entry in blueprint.instances:
		if entry.kind == "peach_tree":
			_sprite("petal_scatter",world_point(entry.anchor)+Vector2(0,4),65,-5)
	for point in [[61,432],[152,425],[224,390],[295,346],[169,328],[287,281]]:
		_sprite("flower_daisy_cluster",world_point(point),24,-4)

func _surface(points: PackedVector2Array, asset: String, depth: int) -> void:
	var poly := Polygon2D.new()
	poly.polygon = points
	var uv := PackedVector2Array()
	for point in points:
		uv.append(point*1.15)
	poly.uv = uv
	poly.texture = load(ART+asset+".png")
	poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	poly.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	poly.z_index = depth
	add_child(poly)

func _sprite(asset: String, pos: Vector2, width: float, depth: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(ART+asset+".png")
	sprite.position = pos
	sprite.scale = Vector2.ONE*width/sprite.texture.get_width()
	sprite.z_index = depth
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	return sprite

func _build_boundary() -> void:
	var boundary := StaticBody2D.new()
	boundary.name = "PlateauBoundary"
	boundary.collision_layer = 2
	boundary.collision_mask = 0
	var shape := CollisionPolygon2D.new()
	shape.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	shape.polygon = land
	boundary.add_child(shape)
	add_child(boundary)

func _build_instance(entry: Dictionary) -> void:
	var pos := world_point(entry.anchor)
	if entry.kind == "waterfall":
		var water := _sprite("waterfall_long",pos+Vector2(0,96),54,-5)
		water.scale.y = 220.0 / water.texture.get_height()
		_sprite("waterfall_crest",pos-Vector2(0,40),95,-4)
		_sprite("waterfall_mist",pos+Vector2(0,205),110,-4)
		return
	if entry.kind in ["npc","peach"]:
		var item := InteractableObject.new()
		item.kind = entry.kind
		item.item_id = entry.id
		item.position = pos
		item.display_name = "Khỉ Trưởng Lão" if entry.kind == "npc" else "Đào Tiên"
		item.prompt_text = "[E] Nói chuyện với Trưởng Lão" if entry.kind == "npc" else "[E] Nhặt Đào Tiên"
		item.interacted.connect(_on_interacted)
		entities_root.add_child(item)
		items[entry.id] = item
		return
	var parent: Node2D
	if entry.role == "obstacle":
		var body := StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(entry.footprint[0],entry.footprint[1])*float(blueprint.units_per_pixel)*2
		col.shape = shape
		body.add_child(col)
		parent = body
	else:
		parent = Node2D.new()
	parent.name = entry.id
	parent.position = pos
	var visual := IsoPlaceholder.new()
	visual.kind = entry.kind
	var cfg: Dictionary = IsoPlaceholder.SPRITE_MAP[entry.kind]
	visual.item_scale = float(entry.height)*float(blueprint.units_per_pixel)/float(cfg.height)
	parent.add_child(visual)
	entities_root.add_child(parent)

func _on_interacted(item: InteractableObject, actor: PlayerController) -> void:
	if item.kind == "npc":
		quest_started = true
		item.set_quest_marker("" if peaches >= 3 else "?")
		_message = "Đã thu đủ đào! Bạn có thể tiếp tục so sánh bố cục bằng F1/F3." if peaches >= 3 else "Trưởng Lão: Hãy tìm 3 Đào Tiên dưới gốc cây trong rừng."
	elif item.kind == "peach":
		if not quest_started:
			_message = "Hãy nói chuyện với Trưởng Lão trước."
			return
		peaches += 1
		item.active = false
		item.visible = false
		actor.heal(25)
		_message = "Đào Tiên: %d/3. %s" % [peaches,"Quay lại Trưởng Lão." if peaches >= 3 else "Tiếp tục men theo đường lên rừng."]

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	var panel := PanelContainer.new()
	panel.position = Vector2(16,14)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09,0.14,0.19,0.90)
	style.set_content_margin_all(12)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel",style)
	hud.add_child(panel)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size",16)
	panel.add_child(_status)
	_prompt = Label.new()
	_prompt.position = Vector2(0,666)
	_prompt.size = Vector2(1280,36)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_constant_override("outline_size",5)
	_prompt.add_theme_color_override("font_outline_color",Color("172533"))
	hud.add_child(_prompt)

func _process(_delta: float) -> void:
	_status.text = "THỬ BỐ CỤC THEO PHÂN VÙNG • Làng Khỉ → Rừng Đào\nF1: Toàn cảnh | F3: Blueprint | F2: Scene cũ (reset)\nWASD: Đi | Space: Lướt | E: Tương tác • Đào %d/3" % peaches
	var hint := player.get_nearest_interactable_prompt()
	_prompt.text = hint if not hint.is_empty() else _message

func _build_debug() -> void:
	_debug_layer = Node2D.new()
	_debug_layer.name = "BlueprintOverlay"
	_debug_layer.z_index = 80
	add_child(_debug_layer)
	for region in blueprint.surfaces:
		var fill := Polygon2D.new()
		fill.polygon = world_polygon(region.polygon)
		fill.color = Color(0.2,0.9,0.4,0.14) if region.kind == "grass" else Color(1.0,0.65,0.1,0.22)
		_debug_layer.add_child(fill)
	for region in blueprint.height_regions:
		var rise := Polygon2D.new()
		rise.polygon = world_polygon(region.polygon)
		rise.color = Color(0.6,0.35,1.0,0.12)
		_debug_layer.add_child(rise)
	var line := Line2D.new()
	line.points = route
	line.width = 3
	line.default_color = Color.CYAN
	_debug_layer.add_child(line)
	for entry in blueprint.instances:
		var anchor := Line2D.new()
		var p := world_point(entry.anchor)
		anchor.points = PackedVector2Array([p-Vector2(6,0),p+Vector2(6,0),p,p-Vector2(0,6),p+Vector2(0,6)])
		anchor.width = 2
		anchor.default_color = Color.MAGENTA
		_debug_layer.add_child(anchor)
		if entry.role == "obstacle":
			var bounds := Line2D.new()
			var size := Vector2(entry.footprint[0],entry.footprint[1])*float(blueprint.units_per_pixel)
			bounds.points = PackedVector2Array([p-size,p+Vector2(size.x,-size.y),p+size,p+Vector2(-size.x,size.y),p-size])
			bounds.width = 2
			bounds.default_color = Color(1,0.3,0.3,0.8)
			_debug_layer.add_child(bounds)
	_debug_layer.visible = false

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F1:
		overview = not overview
		camera.reparent(self if overview else player)
		camera.position = Vector2(230,-200) if overview else Vector2.ZERO
		camera.zoom = Vector2.ONE*(0.70 if overview else 0.92)
		camera.reset_smoothing()
	elif event.keycode == KEY_F3:
		debug_visible = not debug_visible
		_debug_layer.visible = debug_visible
	elif event.keycode == KEY_F2:
		get_tree().change_scene_to_file("res://scenes/hoa_qua_son.tscn")
