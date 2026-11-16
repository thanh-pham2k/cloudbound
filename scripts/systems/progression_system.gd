extends Node
class_name ProgressionSystem

signal exp_changed(current_exp: int, required_exp: int, level: int)
signal level_up_choices_ready(choices: Array)

var level: int = 1
var current_exp: int = 0
var required_exp: int = 50
var _pending_level_ups: int = 0
var _is_choosing: bool = false


func reset() -> void:
	level = 1
	current_exp = 0
	required_exp = 50
	_pending_level_ups = 0
	_is_choosing = false
	exp_changed.emit(current_exp, required_exp, level)


func snapshot() -> Dictionary:
	return {
		"level": level,
		"exp": current_exp,
		"required_exp": required_exp,
		"pending_level_ups": _pending_level_ups,
	}


func restore(state: Dictionary) -> void:
	level = maxi(1, int(state.get("level", 1)))
	current_exp = maxi(0, int(state.get("exp", 0)))
	required_exp = maxi(1, int(state.get("required_exp", 50)))
	_pending_level_ups = maxi(0, int(state.get("pending_level_ups", 0)))
	_is_choosing = false
	exp_changed.emit(current_exp, required_exp, level)
	_try_present_choices()


func add_exp(amount: int) -> void:
	if amount <= 0:
		return
	current_exp += amount
	while current_exp >= required_exp:
		current_exp -= required_exp
		level += 1
		required_exp = int(round(50.0 * pow(1.28, float(level - 1))))
		_pending_level_ups += 1
	exp_changed.emit(current_exp, required_exp, level)
	_try_present_choices()


func _try_present_choices() -> void:
	if _is_choosing or _pending_level_ups <= 0:
		return
	var pool: Array = GameData.upgrades_data.duplicate(true)
	if pool.is_empty():
		_pending_level_ups = 0
		return
	pool.shuffle()
	var choices := pool.slice(0, mini(3, pool.size()))
	_is_choosing = true
	level_up_choices_ready.emit(choices)


func on_upgrade_chosen(upgrade: Dictionary, player: Node) -> void:
	if player != null and player.has_method("apply_upgrade"):
		player.apply_upgrade(upgrade)
	_pending_level_ups = max(0, _pending_level_ups - 1)
	_is_choosing = false
	_try_present_choices()
