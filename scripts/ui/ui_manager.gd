extends CanvasLayer
class_name UIManager

signal upgrade_selected(upgrade: Dictionary)
signal restart_requested

@export var painted_visuals := false

const PaintedSprite := preload("res://scripts/world/painted_sprite.gd")

var _hp_bar: Range
var _hp_label: Label
var _exp_bar: Range
var _level_label: Label
var _wave_label: Label
var _dash_label: Label
var _s1_label: Label
var _s2_label: Label

var _boss_panel: Control
var _boss_name_label: Label
var _boss_hp_bar: Range

var _upgrade_overlay: ColorRect
var _upgrade_buttons: Array[Button] = []
var _current_choices: Array = []

var _pause_overlay: ColorRect
var _end_overlay: ColorRect
var _end_title: Label
var _end_desc: Label
var _is_game_ended: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if painted_visuals:
		_build_painted_hud()
	else:
		_build_hud()
		_build_boss_bar()
	_build_keyboard_hint()
	_build_upgrade_modal()
	_build_pause_modal()
	_build_end_modal()


func _unhandled_input(event: InputEvent) -> void:
	if _is_game_ended or _upgrade_overlay.visible:
		return
	if event.is_action_pressed("pause"):
		toggle_pause()


func _build_painted_hud() -> void:
	const PORTRAIT := preload("res://assets/processed/ui/monkey_hero_portrait.png")
	const METERS := preload("res://assets/processed/ui/hero_health_mana_bar.png")
	const BOSS := preload("res://assets/processed/ui/dragon_boss_health_bar.png")
	const BUTTONS: Array[Texture2D] = [
		preload("res://assets/processed/ui/ability_button_lower_left.png"),
		preload("res://assets/processed/ui/ability_button_top.png"),
		preload("res://assets/processed/ui/ability_button_lower_right.png"),
	]

	var layout := Control.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layout)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud_art(layout, METERS, Rect2(65, 9, 241, 100))
	_hud_art(layout, PORTRAIT, Rect2(15, 15, 72, 72))
	const METER_SCALE := 241.0 / 697.0
	var hp_region := Rect2(177, 84, 443, 39)
	var xp_region := Rect2(177, 148, 443, 32)
	_hp_bar = PaintedSprite.make_meter(METERS, hp_region, hp_region.size.x * METER_SCALE)
	_exp_bar = PaintedSprite.make_meter(METERS, xp_region, xp_region.size.x * METER_SCALE)
	_hp_bar.position = Vector2(65, 9) + hp_region.position * METER_SCALE
	_exp_bar.position = Vector2(65, 9) + xp_region.position * METER_SCALE
	layout.add_child(_hp_bar)
	layout.add_child(_exp_bar)
	_hp_label = _make_skill_pill("")
	_hp_label.position = Vector2(143, 33)
	layout.add_child(_hp_label)
	_level_label = _make_skill_pill("Lv. 1 · XP")
	_level_label.position = Vector2(143, 54)
	layout.add_child(_level_label)
	_wave_label = _make_skill_pill("")
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layout.add_child(_wave_label)
	_wave_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_wave_label.offset_left = -430
	_wave_label.offset_right = -20
	_wave_label.offset_top = 20

	var skill_row := Control.new()
	skill_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(skill_row)
	skill_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	skill_row.offset_top = -96
	skill_row.offset_bottom = -10
	_dash_label = _make_skill_pill("")
	_s1_label = _make_skill_pill("")
	_s2_label = _make_skill_pill("")
	var captions: Array[Label] = [_dash_label, _s1_label, _s2_label]
	var keys := ["Space", "K", "L"]
	for i in range(3):
		var slot := Control.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		skill_row.add_child(slot)
		slot.set_anchors_preset(Control.PRESET_CENTER_TOP)
		slot.offset_left = float(i - 1) * 206.0 - 103.0
		slot.offset_right = slot.offset_left + 206.0
		_hud_art(slot, BUTTONS[i], Rect2(77, 0, 52, 52))
		var key := _make_skill_pill(keys[i])
		key.position = Vector2(77, 15)
		key.size.x = 52
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(key)
		var caption := captions[i]
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.position.y = 57
		caption.size.x = 206
		slot.add_child(caption)
	update_cooldowns(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

	_boss_panel = Control.new()
	_boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(_boss_panel)
	_boss_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_panel.offset_left = -150
	_boss_panel.offset_right = 150
	_boss_panel.offset_top = 4
	_boss_panel.hide()
	_boss_hp_bar = PaintedSprite.make_meter(BOSS, Rect2(Vector2.ZERO, BOSS.get_size()), 300.0)
	_boss_panel.add_child(_boss_hp_bar)
	_boss_name_label = _make_skill_pill("")
	_boss_name_label.position = Vector2(56, 45)
	_boss_name_label.size.x = 224
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_panel.add_child(_boss_name_label)


func _hud_art(parent: Control, art: Texture2D, bounds: Rect2) -> void:
	var image := TextureRect.new()
	image.texture = art
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.position = bounds.position
	image.size = bounds.size
	parent.add_child(image)


func _build_hud() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(320, 0)
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var top_row := HBoxContainer.new()
	vbox.add_child(top_row)

	_level_label = Label.new()
	_level_label.text = "Lv. 1"
	_level_label.add_theme_font_size_override("font_size", 18)
	_level_label.add_theme_color_override("font_color", Color(0.98, 0.85, 0.35))
	top_row.add_child(_level_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	_wave_label = Label.new()
	_wave_label.text = "Đợt 1"
	_wave_label.add_theme_font_size_override("font_size", 15)
	_wave_label.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	top_row.add_child(_wave_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(300, 20)
	(_hp_bar as ProgressBar).show_percentage = false
	vbox.add_child(_hp_bar)

	_hp_label = Label.new()
	_hp_label.text = "HP: 120 / 120"
	_hp_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_hp_label)

	_exp_bar = ProgressBar.new()
	_exp_bar.custom_minimum_size = Vector2(300, 12)
	(_exp_bar as ProgressBar).show_percentage = false
	vbox.add_child(_exp_bar)

	# Bottom-center skill bar
	var skill_margin := MarginContainer.new()
	skill_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	skill_margin.offset_top = -46
	skill_margin.add_theme_constant_override("margin_bottom", 18)
	add_child(skill_margin)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 18)
	skill_margin.add_child(hbox)

	_dash_label = _make_skill_pill("[Space] Vân Bộ: Sẵn sàng")
	_s1_label = _make_skill_pill("[K] Lôi Quang Trảm: Sẵn sàng")
	_s2_label = _make_skill_pill("[L] Cửu Thiên Lạc Lôi: Sẵn sàng")
	hbox.add_child(_dash_label)
	hbox.add_child(_s1_label)
	hbox.add_child(_s2_label)


func _build_keyboard_hint() -> void:
	var hint := _make_skill_pill("WASD  Di chuyển    J  Tấn công    Esc  Tạm dừng")
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_left = 18
	hint.offset_top = -31


func _make_skill_pill(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.14, 0.95))
	lbl.add_theme_constant_override("outline_size", 4)
	return lbl


func _build_boss_bar() -> void:
	_boss_panel = PanelContainer.new()
	_boss_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_boss_panel.offset_left = 360
	_boss_panel.offset_right = -360
	_boss_panel.offset_top = 18
	_boss_panel.visible = false
	add_child(_boss_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_boss_panel.add_child(vbox)

	_boss_name_label = Label.new()
	_boss_name_label.text = "Thiên Lôi Tướng — Phase 1"
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name_label.add_theme_font_size_override("font_size", 16)
	_boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	vbox.add_child(_boss_name_label)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.custom_minimum_size = Vector2(0, 18)
	(_boss_hp_bar as ProgressBar).show_percentage = false
	vbox.add_child(_boss_hp_bar)


func _build_upgrade_modal() -> void:
	_upgrade_overlay = ColorRect.new()
	_upgrade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_upgrade_overlay.color = Color(0.03, 0.06, 0.12, 0.78)
	_upgrade_overlay.visible = false
	add_child(_upgrade_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_upgrade_overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "THĂNG CẤP! CHỌN 1 TRONG 3 NÂNG CẤP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.98, 0.85, 0.35))
	vbox.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	vbox.add_child(row)

	for i in range(3):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(250, 140)
		btn.pressed.connect(_on_upgrade_btn_pressed.bind(i))
		row.add_child(btn)
		_upgrade_buttons.append(btn)


func _build_pause_modal() -> void:
	_pause_overlay = ColorRect.new()
	_pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.color = Color(0.03, 0.06, 0.12, 0.75)
	_pause_overlay.visible = false
	add_child(_pause_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "TẠM DỪNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "Tiếp Tục (Esc)"
	resume_btn.custom_minimum_size = Vector2(220, 44)
	resume_btn.pressed.connect(toggle_pause)
	vbox.add_child(resume_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Chơi Lại"
	restart_btn.custom_minimum_size = Vector2(220, 44)
	restart_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		restart_requested.emit()
	)
	vbox.add_child(restart_btn)


func _build_end_modal() -> void:
	_end_overlay = ColorRect.new()
	_end_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_overlay.color = Color(0.03, 0.06, 0.12, 0.82)
	_end_overlay.visible = false
	add_child(_end_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	_end_title = Label.new()
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_end_title)

	_end_desc = Label.new()
	_end_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_desc.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_end_desc)

	var restart_btn := Button.new()
	restart_btn.text = "Chơi Lại"
	restart_btn.custom_minimum_size = Vector2(220, 48)
	restart_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		restart_requested.emit()
	)
	vbox.add_child(restart_btn)


func update_hp(cur: int, max_v: int) -> void:
	_hp_bar.max_value = max_v
	_hp_bar.value = cur
	_hp_label.text = "HP: %d / %d" % [cur, max_v]


func update_exp(cur: int, req: int, lvl: int) -> void:
	_exp_bar.max_value = req
	_exp_bar.value = cur
	_level_label.text = ("Lv. %d · XP" if painted_visuals else "Lv. %d") % lvl


func update_wave(_num: int, _total: int, label_text: String) -> void:
	_wave_label.text = label_text


func update_cooldowns(d_cd: float, _d_max: float, s1_cd: float, _s1_max: float, s2_cd: float, _s2_max: float) -> void:
	if painted_visuals:
		_dash_label.text = "Vân Bộ · %s" % _cooldown_text(d_cd)
		_s1_label.text = "Lôi Quang Trảm · %s" % _cooldown_text(s1_cd)
		_s2_label.text = "Cửu Thiên Lạc Lôi · %s" % _cooldown_text(s2_cd)
		return
	_dash_label.text = "[Space] Vân Bộ: %s" % ("Sẵn sàng" if d_cd <= 0.05 else "%.1fs" % d_cd)
	_s1_label.text = "[K] Lôi Quang Trảm: %s" % ("Sẵn sàng" if s1_cd <= 0.05 else "%.1fs" % s1_cd)
	_s2_label.text = "[L] Cửu Thiên Lạc Lôi: %s" % ("Sẵn sàng" if s2_cd <= 0.05 else "%.1fs" % s2_cd)


func _cooldown_text(remaining: float) -> String:
	return "Sẵn sàng" if remaining <= 0.05 else "%.1fs" % remaining


func show_boss_bar(boss_name: String, cur: int, max_v: int, phase: int = 1) -> void:
	_boss_panel.visible = true
	_boss_name_label.text = "%s — Phase %d" % [boss_name, phase]
	_boss_hp_bar.max_value = max_v
	_boss_hp_bar.value = cur


func update_boss_hp(cur: int, max_v: int) -> void:
	_boss_hp_bar.max_value = max_v
	_boss_hp_bar.value = cur
	if cur <= 0:
		_boss_panel.visible = false


func show_upgrade_choices(choices: Array) -> void:
	_current_choices = choices
	for i in range(_upgrade_buttons.size()):
		if i < choices.size():
			var upg: Dictionary = choices[i]
			_upgrade_buttons[i].text = "%s\n\n%s" % [upg.get("name", ""), upg.get("description", "")]
			_upgrade_buttons[i].visible = true
		else:
			_upgrade_buttons[i].visible = false
	_upgrade_overlay.visible = true
	get_tree().paused = true


func _on_upgrade_btn_pressed(idx: int) -> void:
	if idx < 0 or idx >= _current_choices.size():
		return
	var chosen: Dictionary = _current_choices[idx]
	_upgrade_overlay.visible = false
	get_tree().paused = false
	upgrade_selected.emit(chosen)


func toggle_pause() -> void:
	var next_paused := not get_tree().paused
	get_tree().paused = next_paused
	_pause_overlay.visible = next_paused


func show_victory() -> void:
	_is_game_ended = true
	get_tree().paused = true
	_end_title.text = "CHIẾN THẮNG! MỞ KHÓA TẦNG MÂY TIẾP THEO"
	_end_title.add_theme_color_override("font_color", Color(0.98, 0.86, 0.35))
	_end_desc.text = "Bạn đã đánh bại Thiên Lôi Tướng và bước vào Cổng Thiên Giới."
	_end_overlay.visible = true


func show_game_over() -> void:
	_is_game_ended = true
	get_tree().paused = true
	_end_title.text = "THẤT BẠI"
	_end_title.add_theme_color_override("font_color", Color(1.0, 0.38, 0.38))
	_end_desc.text = "Hành trình lên Thiên Giới tạm dừng tại đây."
	_end_overlay.visible = true
