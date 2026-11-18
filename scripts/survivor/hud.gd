extends CanvasLayer

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
var _health_text: Label
var _xp_text: Label
var _time_text: Label
var _wave_text: Label
var _gold_text: Label
var _army_text: Label
var _selected := 0


func _ready() -> void:
	add_child(_root)
	_root.size = Vector2(1280, 720)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_status)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hero_card := _panel(_status, Rect2(24, 22, 328, 83), CREAM, Color("#bd8c4b"), 17)
	_pic(hero_card, "heart", Rect2(13, 13, 29, 29))
	_health = _bar(hero_card, Rect2(52, 41, 258, 13), Color("#dc7354"))
	_health_text = _label(hero_card, Rect2(52, 12, 258, 24), "", 17)
	_experience = _bar(hero_card, Rect2(52, 63, 258, 7), Color("#72a954"))
	_xp_text = _label(hero_card, Rect2(52, 12, 258, 24), "", 13, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)

	var clock := _panel(_status, Rect2(544, 22, 192, 73), CREAM, Color("#bd8c4b"), 17)
	_time_text = _label(clock, Rect2(0, 5, 192, 34), "", 29, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_wave_text = _label(clock, Rect2(0, 39, 192, 23), "", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	var team := _panel(_status, Rect2(937, 22, 260, 62), CREAM, Color("#bd8c4b"), 17)
	_pic(team, "gold_icon", Rect2(14, 13, 35, 35))
	_gold_text = _label(team, Rect2(58, 0, 64, 62), "", 21)
	_pic(team, "army_icon", Rect2(133, 12, 49, 37))
	_army_text = _label(team, Rect2(192, 0, 58, 62), "", 21)

	var pause := _button(_status, Rect2(1208, 25, 47, 47), "", game.pause_game)
	pause.tooltip_text = "Pause (Esc)"
	pause.focus_mode = Control.FOCUS_NONE
	_pic(pause, "pause_icon", Rect2(2, 2, 43, 43))

	_boss_card = _panel(_status, Rect2(937, 97, 316, 57), CREAM, Color("#a6553a"), 15)
	_pic(_boss_card, "boss_alert", Rect2(9, 6, 47, 44))
	_label(_boss_card, Rect2(60, 4, 241, 25), "BOAR KING", 16, INK)
	_boss_health = _bar(_boss_card, Rect2(60, 34, 241, 10), Color("#cc5347"))
	_label(_status, Rect2(26, 681, 340, 25), "A / D or  ← / →   Move     ·     Esc   Pause", 15, LIGHT)


func update_stats() -> void:
	_status.visible = game.state != game.State.MENU
	_health.max_value = game.hero.max_hp
	_health.value = game.hero.hp
	_health_text.text = "HP  %d / %d" % [game.hero.hp, game.hero.max_hp]
	_experience.max_value = game.xp_needed()
	_experience.value = game.xp
	_xp_text.text = "Lv %d   ·   %d/%d XP" % [game.level, game.xp, game.xp_needed()]
	_time_text.text = _time()
	_wave_text.text = "BOSS ENCOUNTER" if game.elapsed >= game.BOSS_TIME else "WAVE %d / 5" % game.wave
	_gold_text.text = str(game.gold)
	_army_text.text = "%d / 5" % game.army_count()
	_boss_card.visible = is_instance_valid(game.boss)
	if _boss_card.visible:
		_boss_health.max_value = game.boss.max_hp
		_boss_health.value = game.boss.hp


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
	_pic(panel, "hero_00", Rect2(183, 183, 146, 131))
	_label(panel, Rect2(18, 327, 476, 31), "Raise your army and defeat the Boar King.", 19, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
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
	var summary := "Boar King defeated" if won else "Sun Wukong fell"
	_label(panel, Rect2(14, 115, 504, 29), summary, 22, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_label(panel, Rect2(14, 159, 504, 29), "%s   ·   %d enemies defeated   ·   Level %d" % [_time(), game.kills, game.level],
		18, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var restart := _button(panel, Rect2(51, 222, 204, 49), "Restart", game.start_game, true)
	_button(panel, Rect2(277, 222, 204, 49), "Main Menu", game.main_menu)
	restart.grab_focus()


func show_shop(slot := -1) -> void:
	if slot >= 0:
		_selected = slot
	elif game.army[_selected] == null:
		for i in game.army.size():
			if game.army[i] != null:
				_selected = i
				break
	var panel := _modal(Rect2(171, 128, 938, 496))
	_pic(panel, "shop_icon", Rect2(29, 19, 56, 56))
	_label(panel, Rect2(100, 18, 552, 41), "Level %d · Army Shop" % game.level, 32)
	_label(panel, Rect2(101, 63, 600, 24), "Recruit a monkey or equip a weapon on the selected ally.", 17, MUTED)
	var wallet := _panel(panel, Rect2(740, 30, 167, 44), Color("#f4dda4"), Color("#cfaa64"), 12)
	_pic(wallet, "gold_icon", Rect2(10, 7, 28, 29))
	_label(wallet, Rect2(49, 0, 112, 44), "%d Gold" % game.gold, 18)

	_label(panel, Rect2(31, 109, 167, 42), "Army  %d / 5" % game.army_count(), 19)
	for i in game.army.size():
		var ally = game.army[i]
		var text := "Slot %d\nEmpty" % (i + 1)
		if ally != null:
			text = "Slot %d\n%s" % [i + 1, game.WEAPONS.get(ally.weapon_id, {}).get("name", "Unarmed")]
		var button := _button(panel, Rect2(200 + i * 143, 105, 133, 51), text, show_shop.bind(i),
			i == _selected and ally != null)
		button.disabled = ally == null
		button.add_theme_font_size_override("font_size", 14)

	_shop_card(panel, 0, "monkey_00", "Recruit Monkey", "Comes with a\nWooden Staff", game.RECRUIT_COST,
		game.can_recruit(), game.buy_monkey, "Army full" if game.army_count() == 5 else "Need more Gold")
	_shop_card(panel, 1, "staff", "Wooden Staff", "Quick melee strikes", game.WEAPONS.staff.cost,
		game.can_equip(_selected, "staff"), game.buy_weapon.bind(_selected, "staff"), _weapon_status("staff"))
	_shop_card(panel, 2, "bow", "Wooden Bow", "Long-range arrows", game.WEAPONS.bow.cost,
		game.can_equip(_selected, "bow"), game.buy_weapon.bind(_selected, "bow"), _weapon_status("bow"))
	_shop_card(panel, 3, "magic", "Magic Staff", "Area damage", game.WEAPONS.magic.cost,
		game.can_equip(_selected, "magic"), game.buy_weapon.bind(_selected, "magic"), _weapon_status("magic"))
	var next := _button(panel, Rect2(681, 428, 226, 47), "Continue", game.resume, true)
	_label(panel, Rect2(32, 428, 596, 47), "Unspent Gold carries forward. Weapons replace the selected ally’s gear.", 15, MUTED)
	next.grab_focus()


func _weapon_status(id: String) -> String:
	var monkey = game.army[_selected]
	if monkey == null:
		return "Recruit an ally"
	return "Equipped" if monkey.weapon_id == id else "Need more Gold"


func _shop_card(parent: Control, index: int, image: String, title: String, detail: String,
		cost: int, available: bool, action: Callable, unavailable: String) -> void:
	var card := _panel(parent, Rect2(30 + index * 222, 174, 211, 235), Color("#fff7df"), Color("#d7b57b"), 17)
	_pic(card, image, Rect2(62, 14, 87, 87))
	_label(card, Rect2(5, 101, 201, 31), title, 19, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_label(card, Rect2(5, 135, 201, 44), detail, 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var buy := _button(card, Rect2(12, 181, 187, 40), "Buy · %d Gold" % cost if available else "%s · %d" % [unavailable, cost],
		action, available)
	buy.disabled = not available
	buy.add_theme_font_size_override("font_size", 14)


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


func _pic(parent: Control, art: String, rect: Rect2) -> void:
	var img := TextureRect.new()
	img.texture = load(ART + art + ".png")
	img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(img, rect)
	parent.add_child(img)


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
