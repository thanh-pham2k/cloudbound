extends Node

var enemies_data: Dictionary = {}
var boss_data: Dictionary = {}
var skills_data: Dictionary = {}
var upgrades_data: Array = []
var floors_data: Array = []


func _ready() -> void:
	load_all()


func load_all() -> void:
	var enemies_json := _read_json("res://data/enemies.json")
	enemies_data = enemies_json.get("enemies", {})
	boss_data = enemies_json.get("boss", {})

	skills_data = _read_json("res://data/skills.json")
	var upgrades_json := _read_json("res://data/upgrades.json")
	upgrades_data = upgrades_json.get("upgrades", [])

	var floors_json := _read_json("res://data/floors.json")
	floors_data = floors_json.get("floors", [])


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("GameData: Missing JSON file: " + path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("GameData: Failed to open JSON file: " + path)
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameData: Invalid JSON dictionary in: " + path)
		return {}
	return parsed


func get_enemy_config(enemy_id: String) -> Dictionary:
	return enemies_data.get(enemy_id, {})


func get_boss_config() -> Dictionary:
	return boss_data


func get_skill_config(skill_id: String) -> Dictionary:
	return skills_data.get(skill_id, {})


func get_floor_config(index: int = 0) -> Dictionary:
	if index >= 0 and index < floors_data.size():
		return floors_data[index]
	return {}
