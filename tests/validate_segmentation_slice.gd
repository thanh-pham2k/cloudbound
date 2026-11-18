extends SceneTree
## Programmatic InputMap traversal and interaction; no user saves touched.
var scene: SegmentationSlice
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame

func move_to(target: Vector2) -> void:
	for frame in 400:
		var delta: Vector2 = target-scene.player.position
		if delta.length()<8:
			break
		for action in ["move_left","move_right","move_up","move_down"]:
			Input.action_release(action)
		if absf(delta.x)>4:
			Input.action_press("move_right" if delta.x>0 else "move_left")
		if absf(delta.y)>4:
			Input.action_press("move_down" if delta.y>0 else "move_up")
		await physics_frame
	for action in ["move_left","move_right","move_up","move_down"]:
		Input.action_release(action)
	check(scene.player.position.distance_to(target)<14,"Blocked traversal to "+str(target))

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func run() -> void:
	scene = load("res://scenes/segmentation_slice.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	check(scene.blueprint.instances.size()==39,"Unexpected instance count")
	for entry in scene.blueprint.instances:
		if entry.kind != "waterfall":
			check(Geometry2D.is_point_in_polygon(scene.world_point(entry.anchor),scene.land),"Anchor outside plateau: "+entry.id)
	# Walk from spawn to NPC, begin the pilot quest, then traverse the full route.
	await move_to(scene.world_point([126,389]))
	await press("interact")
	check(scene.quest_started,"E did not start the quest")
	for target in scene.route:
		await move_to(target)
	# Return down the actual path rather than teleporting between route points.
	for i in range(scene.route.size()-1,-1,-1):
		await move_to(scene.route[i])
	# Each pickup is approached through the open space beside its tree.
	var approaches := [ [[209,326],[218,307],[210,285],[193,287]], [[240,291],[247,301]], [[280,260],[280,278]] ]
	for i in 3:
		for target in scene.route:
			await move_to(target)
			if target.distance_to(scene.world_point(approaches[i][0]))<5:
				break
		for target in approaches[i]:
			await move_to(scene.world_point(target))
		await press("interact")
		check(not scene.items["peach_%d" % i].active,"Pickup inaccessible: %d" % i)
		for j in range(approaches[i].size()-1,-1,-1):
			await move_to(scene.world_point(approaches[i][j]))
		# Reset only location between independent route checks, retaining quest state.
		scene.player.position = scene.world_point(scene.blueprint.spawn)
	check(scene.peaches==3,"Expected three collected peaches")
	# Verify footprint collision, and that the plateau boundary blocks outward movement.
	var hut: Node2D = scene.entities_root.get_node("hut_main")
	scene.player.position = hut.position+Vector2(0,70)
	Input.action_press("move_up")
	for frame in 50:
		await physics_frame
	Input.action_release("move_up")
	check(scene.player.position.y >= hut.position.y+35,"Player walked through hut footprint")
	scene.player.position = scene.world_point([300,253])
	Input.action_press("move_up")
	for frame in 90:
		await physics_frame
	Input.action_release("move_up")
	check(Geometry2D.is_point_in_polygon(scene.player.position,scene.land),"Player escaped plateau")
	scene.player.position = scene.world_point(scene.blueprint.spawn)
	await key(KEY_F1)
	check(scene.overview and scene.camera.get_parent()==scene,"F1 overview failed")
	await key(KEY_F3)
	check(scene._debug_layer.visible,"F3 blueprint failed")
	await key(KEY_F1)
	check(not scene.overview and scene.camera.get_parent()==scene.player,"F1 return failed")
	await key(KEY_F2)
	check(current_scene is HoaQuaSonWorld,"F2 did not open original scene")
	await key(KEY_F2)
	check(current_scene is SegmentationSlice,"F2 did not return to pilot")
	if failures.is_empty():
		print("PASS: 39 anchors, both-way route traversal, NPC + 3 pickups, F1/F3 overlays, F2 scene switching.")
		quit(0)
	else:
		for message in failures:
			printerr("FAIL: "+message)
		quit(1)
