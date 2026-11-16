extends SceneTree

const WUKONG_FRAMES := "res://assets/animations/wukong/wukong_sprite_frames.tres"


func _initialize() -> void:
	var generated := "res://assets/generated/"
	var pack := {
		WUKONG_FRAMES: {"walk_up":8,"walk_right":8,"attack_down":6,"attack_up":6,"attack_right":6,"skill_1_down":6,"skill_2_down":6,"dash_right":6,"hurt_down":4,"death_down":8},
		generated + "enemies/spirit/spirit_sprite_frames.tres": {"idle_down":4,"walk_down":6,"attack_down":6,"hurt_down":4,"death_down":6},
		generated + "enemies/caster/caster_sprite_frames.tres": {"idle_down":4,"walk_down":6,"cast_down":6,"hurt_down":4,"death_down":6},
		generated + "enemies/boar/boar_sprite_frames.tres": {"idle_down":4,"walk_down":8,"axe_attack_down":6,"hurt_down":4,"death_down":8},
		generated + "enemies/golem/golem_sprite_frames.tres": {"idle_down":4,"heavy_walk_down":8,"stone_punch_down":6,"hurt_down":4,"death_down":8},
		generated + "enemies/guardian/guardian_sprite_frames.tres": {"idle_down":6,"heavy_walk_down":8,"ground_slam_down":8,"cyan_rune_special_down":8,"hurt_down":4,"death_down":8},
	}
	for name in ["cyan_projectile","red_aoe_warning","cyan_impact","golden_staff_slash","portal_swirl"]:
		pack[generated + "combat_vfx/%s_sprite_frames.tres" % name] = {name + "_fx": 8 if name == "portal_swirl" else 6}
	for name in ["health","loot"]:
		pack[generated + "pickups/%s_orb_sprite_frames.tres" % name] = {"orb_idle":6}
	var count := 0
	for path: String in pack:
		var frames := load(path) as SpriteFrames
		if frames == null:
			push_error("Missing SpriteFrames " + path)
			quit(1)
			return
		var dimensions := Vector2(208,176)
		if "/combat_vfx/" in path:
			dimensions = Vector2(128,128)
		elif "/pickups/" in path:
			dimensions = Vector2(64,64)
		for name: String in pack[path]:
			var loop := name.begins_with("idle") or "walk_" in name or name in ["orb_idle","cyan_projectile_fx","red_aoe_warning_fx","portal_swirl_fx"]
			if not frames.has_animation(name) or frames.get_frame_count(name) != pack[path][name] or frames.get_animation_loop(name) != loop:
				push_error("Unexpected animation settings: %s in %s" % [name,path])
				quit(1)
				return
			for index in range(pack[path][name]):
				var frame := frames.get_frame_texture(name,index) as AtlasTexture
				if frame == null or frame.atlas == null or frame.get_size() != (Vector2(256, 176) if name in ["attack_right", "attack_up"] else dimensions):
					push_error("Unexpected atlas dimensions: %s frame %d" % [name,index])
					quit(1)
					return
			count += 1
	print("PASS: %d requested animations, %d SpriteFrames resources" % [count,pack.size()])
	quit(0 if _verify_scene_chain() else 1)

func _verify_scene_chain() -> bool:
	var order := [
		"scene_01_mortal_realm", "scene_02_stairway_clouds", "scene_03_azure_outskirts",
		"scene_04_azure_center", "scene_05_boss_arena", "scene_06_gate_of_heaven",
	]
	var path := str(ProjectSettings.get_setting("application/run/main_scene"))
	for name: String in order:
		if path != "res://scenes/%s.tscn" % name:
			push_error("Unexpected scene destination: %s (expected %s)" % [path, name])
			return false
		var packed := load(path) as PackedScene
		if packed == null:
			return false
		var scene := packed.instantiate()
		var player := scene.get_node_or_null("YSort/Entities/Player")
		var frames: SpriteFrames
		if player != null:
			frames = player.get("painted_animation_frames") as SpriteFrames
		var next_path := str(scene.get("next_scene_path"))
		scene.free()
		if frames == null or frames.resource_path != WUKONG_FRAMES:
			push_error("Missing shared Wukong SpriteFrames: " + path)
			return false
		path = next_path
	if not path.is_empty():
		push_error("The final scene has a destination: " + path)
		return false
	print("PASS: six player bindings, launch scene, and five portal destinations")
	return true
