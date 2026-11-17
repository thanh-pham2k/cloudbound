extends SceneTree
## Automated in-memory checks; uses action input and staged positions, not OS input.
var world: HoaQuaSonWorld
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame

func run() -> void:
	world = load("res://scenes/hoa_qua_son.tscn").instantiate()
	root.add_child(world)
	await process_frame
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	check(world.get_node_or_null("ConceptTerrain") != null,"Missing terrain")
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/concept/manifest.json"))
	check(manifest.size() == 30,"Expected 30 extracted source assets")
	for entry in manifest:
		check(load("res://assets/sprites/concept/"+entry.name+".png") is Texture2D,"Missing imported texture: "+entry.name)
	# Move with actual InputMap actions along every authored route segment.
	world.player.position = HoaQuaSonLayout.MAIN_PATH_POINTS[0]
	for route in [HoaQuaSonLayout.MAIN_PATH_POINTS,HoaQuaSonLayout.SECRET_BRANCH_POINTS]:
		world.player.position = route[0]
		for target in route:
			for frame in 360:
				var delta: Vector2 = target-world.player.position
				if delta.length() < 9:
					break
				for action in ["move_left","move_right","move_up","move_down"]:
					Input.action_release(action)
				if absf(delta.x)>5:
					Input.action_press("move_right" if delta.x>0 else "move_left")
				if absf(delta.y)>5:
					Input.action_press("move_down" if delta.y>0 else "move_up")
				await physics_frame
			check(world.player.position.distance_to(target)<15,"Blocked route at "+str(target))
			for action in ["move_left","move_right","move_up","move_down"]:
				Input.action_release(action)
	world.player.position = world.elder_npc.position+Vector2(0,45)
	await press("interact")
	check(world.quest_stage == 1,"E did not start quest")
	await press("interact")
	await press("dash")
	check(world.player._dash_cd > 0,"Dash action failed")
	# Defeat stationary enemies through the attack input path.
	for enemy in get_nodes_in_group("enemies"):
		if enemy.is_boss:
			continue
		await defeat(enemy)
	world.player.position = world.elder_npc.position+Vector2(0,45)
	await press("interact")
	check(world.quest_stage == 3,"Kill quest turn-in failed")
	await press("interact")
	for item in get_nodes_in_group("interactables"):
		if item.kind == "peach":
			world.player.position = item.position+Vector2(0,15)
			await press("interact")
	check(world.peaches_count == 5,"Peach input interactions failed")
	world.player.position = world.elder_npc.position+Vector2(0,45)
	await press("interact")
	check(world.quest_stage == 5,"Peach quest turn-in failed")
	await press("interact")
	for enemy in get_nodes_in_group("enemies"):
		if enemy.is_boss:
			await defeat(enemy)
	check(world.boss_defeated,"Boss defeat failed")
	check(world.boss_chest.visible and world.boss_chest.active,"Reward chest did not activate")
	check(world.boss_exit.unlocked and world.boss_exit._reward_rays.visible,"Exit glow did not unlock")
	await physics_frame
	check(world.boss_exit_blocker.disabled,"Exit collision remained locked")
	world.player.position = world.boss_chest.position+Vector2(0,25)
	await press("interact")
	check(not world.boss_chest.active and not world.boss_chest._reward_rays.visible,"Chest opened state failed")
	if failures.is_empty():
		print("PASS: 30 textures, both walking routes, E quests/pickups, K combat, dash, chest, gate glow and collision.")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: "+failure)
		quit(1)

func defeat(enemy: EnemyBase) -> void:
	world.player.position = enemy.position+Vector2(0,40)
	world.player.last_facing = Vector2.UP
	for i in 12:
		if not is_instance_valid(enemy) or enemy.is_dead:
			break
		world.player._attack_cd = 0
		await press("attack")
	await process_frame
