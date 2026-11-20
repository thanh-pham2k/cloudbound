extends CanvasLayer

const Polish := preload("res://scripts/survivor/polish.gd")
const ART := "res://assets/survivor/"
const INK := Color("#382a20")
const CREAM := Color("#fff1ce")
const MUTED := Color("#5c533b")
const GOLD := Color("#edc267")
const LIGHT := Color("#fff9e8")

var game
var _root := Control.new()
var _status := Control.new()
var _overlay: Control
var _health: ProgressBar
var _experience: ProgressBar
var _boss_health: ProgressBar
var _boss_card: Panel
var _boss_portrait: TextureRect
var _boss_name: Label
var _boss_portrait_look := "default"
var _health_text: Label
var _xp_text: Label
var _time_text: Label
var _wave_text: Label
var _gold_text: Label
var _army_text: Label
const SUMMON_PANEL := Rect2(22, 646, 1236, 68)
const CARD_START := 174.0
const CARD_SPACING := 165.0
const CARD_WIDTH := 156.0
const TRAIN_X := 1004.0

var _summon_panel: Panel
var _summon_capacity: Label
var _role_buttons := {}
var _role_frames := {}
var _train_button: Button
var _train_label: Label
var _train_price: Label
var _receipt: Sprite2D
var _gold_receipt: Sprite2D
var _xp_receipt: Sprite2D


func _ready() -> void:
	add_child(_root)
	_root.size = Vector2(1280, 720)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_status)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hero_card := _panel(_status, Rect2(18, 18, 278, 82), CREAM, Color("#bd8c4b"), 17)
	_pic(hero_card, "heart", Rect2(12, 13, 27, 27))
	_health = _bar(hero_card, Rect2(46, 40, 216, 13), Color("#dc7354"))
	_health_text = _label(hero_card, Rect2(46, 12, 118, 24), "", 15)
	_experience = _bar(hero_card, Rect2(46, 61, 216, 7), Color("#72a954"))
	_xp_text = _label(hero_card, Rect2(142, 12, 120, 24), "", 12, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)

	# Keep the clock/wave panel in the left margin (x <= 296) so it never covers the 3-lane combat corridor (x >= 306).
	var clock := _panel(_status, Rect2(18, 110, 278, 60), CREAM, Color("#bd8c4b"), 15)
	_time_text = _label(clock, Rect2(14, 4, 102, 52), "", 26, INK, HORIZONTAL_ALIGNMENT_LEFT)
	_wave_text = _label(clock, Rect2(106, 6, 160, 48), "", 14, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)

	# Keep top-right HUD panels in the right margin (x >= 980) outside the combat corridor (x <= 974).
	var team := _panel(_status, Rect2(980, 18, 224, 60), CREAM, Color("#bd8c4b"), 17)
	_pic(team, "gold_icon", Rect2(12, 13, 33, 33))
	_gold_text = _label(team, Rect2(50, 0, 68, 60), "", 20)
	_pic(team, "army_icon", Rect2(120, 12, 44, 35))
	_army_text = _label(team, Rect2(168, 0, 50, 60), "", 20)

	var pause := _button(_status, Rect2(1214, 24, 47, 47), "", game.pause_game)
	pause.tooltip_text = "Pause (Esc)"
	pause.focus_mode = Control.FOCUS_NONE
	_pic(pause, "pause_icon", Rect2(2, 2, 43, 43))

	_boss_card = _panel(_status, Rect2(980, 88, 282, 56), CREAM, Color("#a6553a"), 15)
	_boss_portrait = _pic(_boss_card, "boss_alert", Rect2(8, 6, 44, 42))
	_boss_name = _label(_boss_card, Rect2(56, 4, 214, 24), "BOAR KING", 15, INK)
	_boss_health = _bar(_boss_card, Rect2(56, 33, 214, 10), Color("#cc5347"))
	_build_summon_panel()


func update_stats() -> void:
	_status.visible = game.state != game.State.MENU
	_health.max_value = game.hero.max_hp
	_health.value = game.hero.hp
	_health_text.text = "HP  %d / %d" % [game.hero.hp, game.hero.max_hp]
	_experience.max_value = game.xp_needed()
	_experience.value = game.xp
	_xp_text.text = "Lv %d   ·   %d/%d XP" % [game.level, game.xp, game.xp_needed()]
	_time_text.text = _time()
	_wave_text.text = ("BOSS · WAVE %d" if is_instance_valid(game.boss) else "ENDLESS · WAVE %d") % game.wave
	_gold_text.text = str(game.gold)
	_army_text.text = "%d" % game.army_count()
	_update_summon_panel()
	_boss_card.visible = is_instance_valid(game.boss)
	if _boss_card.visible:
		var look: String = game.boss.appearance
		if look != _boss_portrait_look:
			_boss_portrait_look = look
			_boss_name.text = game.boss_display_name().to_upper()
			_boss_portrait.texture = load(ART + "boss_alert.png") if look.is_empty() else (
				game.boss._enemy_clips.get_frame_texture("idle", 0))
		_boss_health.max_value = game.boss.max_hp
		_boss_health.value = game.boss.hp


func clear_match_fx() -> void:
	for child in _status.get_children():
		if child is Sprite2D:
			_status.remove_child(child)
			child.queue_free()
	_gold_receipt = null
	_xp_receipt = null
	if is_instance_valid(_receipt):
		_receipt.hide()
		_receipt.queue_free()
	_receipt = null


func reward_received(coins: bool) -> void:
	if not _status.visible:
		return
	if coins:
		if not is_instance_valid(_gold_receipt):
			_gold_receipt = Polish.burst(_status, "gold_collect", Vector2(967, 50), 28.0, 0.36, Vector2(0, -11), 0.83)
	elif not is_instance_valid(_xp_receipt):
		_xp_receipt = Polish.burst(_status, "xp_collect", Vector2(216, 89), 24.0, 0.38, Vector2(0, -8), 0.8)


func purchase_feedback(role: String) -> void:
	if is_instance_valid(_receipt):
		_receipt.hide()
		_receipt.queue_free()
	var training_purchase := role == "training"
	var index: int = game.ROLE_ORDER.find(role)
	var x := TRAIN_X + 175.0 if training_purchase else CARD_START + CARD_SPACING * index + 130.0
	var icon := "upgrade_confirm" if training_purchase else "purchase_success"
	_receipt = Polish.burst(_summon_panel, "summon/" + icon, Vector2(x, 13), 39.0, 0.62,
		Vector2(0, -25), 0.96)


static func summon_button_center(index: int) -> Vector2:
	return SUMMON_PANEL.position + Vector2(CARD_START + index * CARD_SPACING + CARD_WIDTH * 0.5, 34)


static func train_button_center() -> Vector2:
	return SUMMON_PANEL.position + Vector2(TRAIN_X + 112, 34)


func _build_summon_panel() -> void:
	_summon_panel = _panel(_status, SUMMON_PANEL, Color("#fff1ce"), Color("#9b703c"), 15)
	_pic(_summon_panel, "summon/tray", Rect2(10, 4, 149, 36))
	_label(_summon_panel, Rect2(17, 10, 133, 22), "Summon", 18, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_pic(_summon_panel, "summon/status_army", Rect2(24, 44, 18, 16))
	_summon_capacity = _label(_summon_panel, Rect2(44, 43, 98, 18), "", 13, MUTED)
	_summon_capacity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for index in game.ROLE_ORDER.size():
		var role: String = game.ROLE_ORDER[index]
		var profile: Dictionary = game.ROLES[role]
		var at := Rect2(CARD_START + index * CARD_SPACING, 7, CARD_WIDTH, 54)
		var button := _button(_summon_panel, at, "", game.summon.bind(role), true)
		button.tooltip_text = profile.hint
		_role_buttons[role] = button
		_role_frames[role] = _pic(button, "summon/card", Rect2(4, 3, 43, 48))
		_pic(button, "summon/portrait_" + role, Rect2(7, 5, 38, 43))
		_label(button, Rect2(51, 5, 96, 22), profile.name, 16)
		_label(button, Rect2(51, 29, 94, 18), "%d Gold" % profile.cost, 13, MUTED)
		_pic(button, "summon/role_" + role, Rect2(125, 31, 20, 18))
	_train_button = _button(_summon_panel, Rect2(TRAIN_X, 7, 223, 54), "", game.train_army, true)
	_train_button.tooltip_text = "Train all current and future monkeys"
	_pic(_train_button, "summon/status_upgrade", Rect2(9, 6, 42, 42))
	_train_label = _label(_train_button, Rect2(58, 5, 158, 22), "", 16)
	_train_price = _label(_train_button, Rect2(58, 29, 158, 18), "", 13, MUTED)


func _update_summon_panel() -> void:
	_summon_panel.visible = game.state in [game.State.RUNNING, game.State.PAUSED]
	_summon_capacity.text = "%d active" % game.army_count()
	for role in _role_buttons:
		var button: Button = _role_buttons[role]
		var enabled: bool = game.can_summon(role)
		var frame: TextureRect = _role_frames[role]
		button.disabled = not enabled
		frame.texture = Polish.texture("summon/card" if enabled else "summon/card_disabled")
		for child in button.get_children():
			if child is TextureRect and child != frame:
				child.modulate.a = 1.0 if enabled else 0.61
	_train_button.disabled = not game.can_train()
	_train_label.text = "Train army · Lv %d" % game.training
	_train_price.text = "%d Gold" % game.training_cost()


func _time() -> String:
	var seconds := int(game.elapsed)
	return "%02d:%02d" % [int(seconds / 60.0), seconds % 60]


func hide_overlay() -> void:
	if is_instance_valid(_overlay):
		_root.remove_child(_overlay)
		_overlay.queue_free()
		_overlay = null


func _modal(bounds: Rect2, shade := Color(0.12, 0.19, 0.12, 0.57)) -> Panel:
	hide_overlay()
	var dim := ColorRect.new()
	dim.color = shade
	dim.size = Vector2(1280, 720)
	_root.add_child(dim)
	_overlay = dim
	return _panel(dim, bounds, CREAM, Color("#b8874b"), 29)


func show_menu() -> void:
	_status.hide()
	var panel := _modal(Rect2(384, 132, 512, 456), Color(0.12, 0.19, 0.12, 0.30))
	_pic(panel, "title", Rect2(105, -76, 302, 179))
	_label(panel, Rect2(29, 20, 454, 34), "HOA QUẢ SƠN", 25, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_label(panel, Rect2(16, 111, 480, 56), "Monkey Army Survivor", 36, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_pic(panel, "polish/wukong_00", Rect2(183, 183, 146, 131))
	_label(panel, Rect2(18, 327, 476, 31), "Summon monkeys to defend all three lanes.", 19, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var play := _button(panel, Rect2(126, 381, 260, 51), "Start Game", game.start_game, true)
	play.grab_focus()


func show_pause() -> void:
	var panel := _modal(Rect2(427, 234, 426, 250))
	_pic(panel, "pause_icon", Rect2(185, -35, 56, 56))
	_label(panel, Rect2(12, 36, 402, 55), "Paused", 36, INK, HORIZONTAL_ALIGNMENT_CENTER)
	var resume := _button(panel, Rect2(90, 104, 246, 48), "Resume", game.resume, true)
	_button(panel, Rect2(48, 177, 156, 46), "Restart", game.start_game)
	_button(panel, Rect2(222, 177, 156, 46), "Main Menu", game.main_menu)
	resume.grab_focus()


func show_result(won: bool) -> void:
	var panel := _modal(Rect2(374, 209, 532, 304))
	_pic(panel, "victory" if won else "defeat", Rect2(168, -85, 196, 126))
	_label(panel, Rect2(14, 43, 504, 67), "Victory" if won else "Defeat", 49, INK, HORIZONTAL_ALIGNMENT_CENTER)
	var effects := ["victory_burst", "victory_petals", "victory_spark", "victory_flare"] if won else (
		["defeat_break", "defeat_smoke", "defeat_beam", "defeat_petals"])
	var positions := [Vector2(-48, 78), Vector2(594, 104), Vector2(-29, 245), Vector2(561, 245)]
	for i in effects.size():
		var drift := Vector2(-14 if i % 2 == 0 else 14, -32 if won else 20)
		Polish.burst(panel, effects[i], positions[i], 82.0 - i * 6, 1.55 + i * 0.13, drift, 0.86)
	var summary: String = "%s defeated" % game.boss_display_name() if won else (
		"Reached Wave %d  ·  %d bosses defeated" % [game.wave, game.bosses_defeated])
	_label(panel, Rect2(14, 115, 504, 29), summary, 22, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_label(panel, Rect2(14, 159, 504, 29), "%s   ·   %d kills   ·   Lv %d   ·   Peak %d" % [
		_time(), game.kills, game.level, game.peak_army],
		18, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var restart := _button(panel, Rect2(51, 222, 204, 49), "Restart", game.start_game, true)
	_button(panel, Rect2(277, 222, 204, 49), "Main Menu", game.main_menu)
	restart.grab_focus()


func _panel(parent: Control, rect: Rect2, color: Color, border: Color, corner: int) -> Panel:
	var panel := Panel.new()
	_place(panel, rect)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := _style(color, border, corner)
	style.shadow_size = 4
	style.shadow_color = Color(0.16, 0.13, 0.06, 0.22)
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _style(color: Color, border: Color, corner: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(corner)
	return style


func _button(parent: Control, rect: Rect2, text: String, action: Callable, primary := false) -> Button:
	var button := Button.new()
	_place(button, rect)
	button.text = text
	button.pressed.connect(action)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var color := GOLD if primary else Color("#f7e6bb")
	var border := Color("#a8743f")
	button.add_theme_stylebox_override("normal", _style(color, border, 12))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.22), border, 12))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.10), border, 12))
	button.add_theme_stylebox_override("disabled", _style(Color("#e8dfca"), Color("#c8bda1"), 12))
	var focus := _style(Color.TRANSPARENT, Color("#557542"), 12)
	focus.set_expand_margin_all(3)
	button.add_theme_stylebox_override("focus", focus)
	for key in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(key, INK)
	button.add_theme_color_override("font_disabled_color", Color("#655b4e"))
	button.add_theme_font_size_override("font_size", 19)
	parent.add_child(button)
	return button


func _label(parent: Control, rect: Rect2, text: String, fontsize: int, color := INK,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", fontsize)
	label.add_theme_color_override("font_color", color)
	if color == LIGHT:
		label.add_theme_color_override("font_outline_color", Color("#395231"))
		label.add_theme_constant_override("outline_size", 5)
	_place(label, rect)
	parent.add_child(label)
	return label


func _pic(parent: Control, art: String, rect: Rect2) -> TextureRect:
	var img := TextureRect.new()
	img.texture = load(ART + art + ".png")
	img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(img, rect)
	parent.add_child(img)
	return img


func _bar(parent: Control, rect: Rect2, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _style(Color("#705238"), Color("#705238"), 5))
	bar.add_theme_stylebox_override("fill", _style(fill, fill, 5))
	_place(bar, rect)
	parent.add_child(bar)
	return bar


func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
