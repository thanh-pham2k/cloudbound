extends SceneTree
## Headless structural & spatial validation for Hoa Qua Son Phase 2 Semantic Layout.

func _init() -> void:
	var packed := load("res://scenes/hoa_qua_son.tscn") as PackedScene
	if packed == null:
		printerr("FAIL: Could not load res://scenes/hoa_qua_son.tscn")
		quit(1)
		return

	var world := packed.instantiate() as HoaQuaSonWorld
	root.add_child(world)
	await process_frame

	var failures: Array[String] = []
	var boundary := PackedVector2Array(HoaQuaSonLayout.WALKABLE_BOUNDARY)

	if world.player == null:
		failures.append("Player node missing")
	elif world.player.get_node_or_null("Camera2D") == null:
		failures.append("Camera2D missing on Player")

	# Check all areas, NPCs, pickups, monsters, boss, and exit are inside walkable boundary
	for area in HoaQuaSonLayout.AREAS:
		if not Geometry2D.is_point_in_polygon(area["center"], boundary):
			failures.append("Area center outside boundary: %s" % area["id"])

	for npc in HoaQuaSonLayout.NPCS:
		if not Geometry2D.is_point_in_polygon(npc["pos"], boundary):
			failures.append("NPC outside boundary: %s" % npc["id"])

	for i in HoaQuaSonLayout.PEACH_PICKUPS.size():
		var p_pos: Vector2 = HoaQuaSonLayout.PEACH_PICKUPS[i]
		if not Geometry2D.is_point_in_polygon(p_pos, boundary):
			failures.append("Peach %d outside boundary" % i)
		var min_tree_dist := INF
		for t_pos in HoaQuaSonLayout.PEACH_TREES:
			min_tree_dist = minf(min_tree_dist, p_pos.distance_to(t_pos))
		if min_tree_dist > 55.0:
			failures.append("Peach %d is not under a peach tree (dist=%.1f)" % [i, min_tree_dist])
		if min_tree_dist < 24.0:
			failures.append("Peach %d overlaps tree trunk collider (dist=%.1f)" % [i, min_tree_dist])

	if not Geometry2D.is_point_in_polygon(HoaQuaSonLayout.SECRET_CHEST_POS, boundary):
		failures.append("Secret chest outside boundary")

	for m in HoaQuaSonLayout.MONSTERS:
		if not Geometry2D.is_point_in_polygon(m["pos"], boundary):
			failures.append("Monster outside boundary: %s" % m["id"])

	if not Geometry2D.is_point_in_polygon(HoaQuaSonLayout.BOSS["pos"], boundary):
		failures.append("Boss outside boundary")

	if not Geometry2D.is_point_in_polygon(HoaQuaSonLayout.BOSS_EXIT_POS, boundary):
		failures.append("Boss exit outside boundary")

	# Check main path & secret branch points are unobstructed by static props
	var prop_positions: Array[Vector2] = []
	for child in world.entities_root.get_children():
		if child is StaticBody2D:
			prop_positions.append(child.position)

	for pt in HoaQuaSonLayout.MAIN_PATH_POINTS:
		if not Geometry2D.is_point_in_polygon(pt, boundary):
			failures.append("Main path point outside boundary: %s" % str(pt))
		for ppos in prop_positions:
			if pt.distance_to(ppos) < 38.0:
				failures.append("Prop at %s too close to main path %s" % [str(ppos), str(pt)])

	for pt in HoaQuaSonLayout.SECRET_BRANCH_POINTS:
		if not Geometry2D.is_point_in_polygon(pt, boundary):
			failures.append("Secret path point outside boundary: %s" % str(pt))
		for ppos in prop_positions:
			if pt.distance_to(ppos) < 34.0:
				failures.append("Prop at %s too close to secret path %s" % [str(ppos), str(pt)])

	var enemies := get_nodes_in_group("enemies")
	var interactables := get_nodes_in_group("interactables")
	print("Validated HoaQuaSon: areas=%d enemies=%d interactables=%d props=%d" % [
		HoaQuaSonLayout.AREAS.size(), enemies.size(), interactables.size(), prop_positions.size()
	])

	if failures.size() > 0:
		for f in failures:
			printerr("FAIL: ", f)
		quit(1)
		return

	print("PASS: All 4 areas, secret branch, paths, colliders, player, NPCs, enemies, and boss exit validated.")
	quit(0)
