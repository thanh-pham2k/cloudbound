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

	if kind == "npc" and item_id == "elder_monkey":
		_marker_label = Label.new()
		_marker_label.text = "!"
		_marker_label.position = Vector2(-6, -58)
		_marker_label.add_theme_color_override("font_color", Color("#FBBF24"))
		_marker_label.add_theme_color_override("font_outline_color", Color("#1E293B"))
		_marker_label.add_theme_constant_override("outline_size", 4)
		_marker_label.add_theme_font_size_override("font_size", 20)
		add_child(_marker_label)


func can_interact() -> bool:
	return visible and active


func get_prompt_text() -> String:
	return prompt_text


func interact(player: PlayerController) -> void:
	if not can_interact():
		return
	interacted.emit(self, player)


func set_opened(opened: bool) -> void:
	active = not opened
	if _visual:
		_visual.state_active = opened
		_visual.queue_redraw()


func set_unlocked(value: bool) -> void:
	unlocked = value
	if _visual:
		_visual.state_active = unlocked
		_visual.queue_redraw()


func set_quest_marker(symbol: String) -> void:
	if _marker_label:
		_marker_label.text = symbol
		_marker_label.visible = not symbol.is_empty()
