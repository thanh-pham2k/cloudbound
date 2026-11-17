class_name InteractableObject
extends Node2D
## Reusable interactable for NPCs, collectible peaches, reward chests, and boss exit.

signal interacted(item: InteractableObject, player: PlayerController)

@export var kind: String = "peach"  # "npc", "peach", "chest", "exit_arch"
@export var item_id: String = ""
@export var display_name: String = ""
@export var prompt_text: String = "[E] Tương tác"
@export var active: bool = true
@export var unlocked: bool = false

var _visual: IsoPlaceholder
var _marker_label: Label
var _quest_bubble: Sprite2D
var _reward_rays: Sprite2D


func _ready() -> void:
	add_to_group("interactables")
	_visual = IsoPlaceholder.new()
	match kind:
		"npc":
			_visual.kind = "elder_npc" if item_id == "elder_monkey" else "guide_npc"
			_visual.item_scale = 1.0
		"peach":
			_visual.kind = "peach"
			_visual.item_scale = 1.0
		"chest":
			_visual.kind = "chest"
			_visual.item_scale = 1.0
			_visual.state_active = not active
		"exit_arch":
			_visual.kind = "exit_arch"
			_visual.item_scale = 1.15
			_visual.state_active = unlocked
	add_child(_visual)

	if kind == "chest" or kind == "exit_arch":
		_reward_rays = Sprite2D.new()
		_reward_rays.texture = load("res://assets/sprites/concept/chest_reward_rays.png" if kind == "chest" else "res://assets/sprites/fx/fx_portal_glow.png")
		_reward_rays.scale = Vector2.ONE * (90.0 if kind == "chest" else 120.0) / _reward_rays.texture.get_width()
		_reward_rays.position = Vector2(0, -32)
		_reward_rays.show_behind_parent = true
		_reward_rays.visible = kind == "chest" or unlocked
		add_child(_reward_rays)
		move_child(_reward_rays, 0)

	if kind == "npc" and item_id == "elder_monkey":
		_quest_bubble = Sprite2D.new()
		_quest_bubble.texture = load("res://assets/sprites/concept/quest_bubble_available.png")
		_quest_bubble.scale = Vector2.ONE * 35.0 / _quest_bubble.texture.get_width()
		_quest_bubble.position = Vector2(0, -83)
		add_child(_quest_bubble)
		_marker_label = Label.new()
		_marker_label.text = "!"
		_marker_label.position = Vector2(-6, -58)
		_marker_label.add_theme_color_override("font_color", Color("#FBBF24"))
		_marker_label.add_theme_color_override("font_outline_color", Color("#1E293B"))
		_marker_label.add_theme_constant_override("outline_size", 4)
		_marker_label.add_theme_font_size_override("font_size", 20)
		add_child(_marker_label)
		_marker_label.visible = false


func can_interact() -> bool:
	return visible and active


func get_prompt_text() -> String:
	return prompt_text


func interact(player: PlayerController) -> void:
	if not can_interact():
		return
	interacted.emit(self, player)


func set_opened(opened: bool) -> void:
	if _reward_rays:
		_reward_rays.visible = not opened
	active = not opened
	if _visual:
		_visual.state_active = opened
		_visual.queue_redraw()


func set_unlocked(value: bool) -> void:
	if _reward_rays:
		_reward_rays.visible = value
	unlocked = value
	if _visual:
		_visual.state_active = unlocked
		_visual.queue_redraw()


func set_quest_marker(symbol: String) -> void:
	if _marker_label:
		_marker_label.text = symbol
		_marker_label.visible = symbol == "?"
	if _quest_bubble:
		_quest_bubble.visible = symbol == "!"
