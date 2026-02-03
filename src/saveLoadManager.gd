extends Node

const DEFAULT_SAVE_PATH := "res://src/defaultSave.json"
const SAVE_PATH := "user://player_save.json"

var player_data: Dictionary = {}

func _ready() -> void:
	# Load the default template first, then overlay any existing user save
	player_data = load_json_file(DEFAULT_SAVE_PATH)
	_load_game()


# --- File helpers ---------------------------------------------------------
func load_json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("Could not open JSON file: %s" % path)
		return {}
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	# If your runtime returns a Dictionary directly, the following check will work.
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	# If parse failed (or returned a different structure), warn and return empty dict
	push_error("Failed to parse JSON from %s. Result type: %s" % [path, typeof(parsed)])
	return {}


func _save_json_file(path: String, data: Dictionary) -> bool:
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Could not open file for writing: %s" % path)
		return false
	file.store_string(json_string)
	file.close()
	return true


func _merge_dicts(default: Dictionary, user: Dictionary) -> Dictionary:
	var result := {}
	for k in default.keys():
		result[k] = default[k]

	for k in user.keys():
		if result.has(k) and typeof(result[k]) == TYPE_DICTIONARY and typeof(user[k]) == TYPE_DICTIONARY:
			result[k] = _merge_dicts(result[k], user[k]) # recursive merge
		else:
			result[k] = user[k] # user overrides or new key
	return result


func save_game() -> bool:
	# Save current in-memory player_data to disk (JSON only).
	if _save_json_file(SAVE_PATH, player_data):
		print("Game saved to %s" % SAVE_PATH)
		return true
	else:
		push_error("Failed to save game.")
		return false


func _load_game() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var user_data := load_json_file(SAVE_PATH)
		if user_data.size() > 0:
			player_data = _merge_dicts(player_data, user_data)
			print("Loaded user save from %s" % SAVE_PATH)
			return true
		else:
			push_warning("User save exists but failed to parse; using defaults.")
			return false

	# No save found: create one from defaults
	print("Save file not found. Creating new user save from defaults.")
	_save_json_file(SAVE_PATH, player_data)
	return false


func reset_data() -> void:
	# Reset to the default template and overwrite the user save
	player_data = load_json_file(DEFAULT_SAVE_PATH)
	_save_json_file(SAVE_PATH, player_data)
	print("Data reset to defaults.")
