extends Node

# paths for default save and user save
const DEFAULT_SAVE_PATH := "res://src/defaultSave.json"
const SAVE_PATH := "user://player_save.json"

# main memory for player data
var playerData: Dictionary = {}


func _ready() -> void:
	# load default save first
	playerData = loadJSON(DEFAULT_SAVE_PATH)


# load JSON from a file safely, returns empty dictionary if fails
func loadJSON(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("Could not open JSON: %s" % path)
		return {}

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	# handle different parse return types
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	elif typeof(parsed) == TYPE_OBJECT:
		# some Godot builds return object with .error and .result
		if parsed.error == OK and typeof(parsed.result) == TYPE_DICTIONARY:
			return parsed.result

	push_error("Failed to parse JSON from %s" % path)
	return {}


# public wrapper to load JSON



# save dictionary to JSON file
func saveJSON(path: String, data: Dictionary) -> bool:
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Could not open file for writing: %s" % path)
		return false
	file.store_string(json_string)
	file.close()
	return true


# merge default dictionary with user dictionary (user overrides defaults)
func mergeDicts(default: Dictionary, user: Dictionary) -> Dictionary:
	var result := {}
	# copy default values first
	for k in default.keys():
		result[k] = default[k]
	# override with user values
	for k in user.keys():
		if result.has(k) and typeof(result[k]) == TYPE_DICTIONARY and typeof(user[k]) == TYPE_DICTIONARY:
			result[k] = mergeDicts(result[k], user[k])
		else:
			result[k] = user[k]
	return result


# save current in-memory playerData to disk
func saveGame() -> bool:
	clampValues(playerData)  # make sure stats and numbers are valid
	if saveJSON(SAVE_PATH, playerData):
		print("Game saved to %s" % SAVE_PATH)
		return true
	push_error("Failed to save game.")
	return false


# load user save and merge with defaults
func loadGame() -> bool:
	var user_data := loadJSON(SAVE_PATH)
	if user_data.size() > 0:
		# merge defaults with user save
		playerData = mergeDicts(playerData, user_data)
		print("Loaded user save from %s" % SAVE_PATH)
		return true
	
	# if save missing, just use defaults
	print("Save missing or corrupted. Creating new user save from defaults.")
	saveJSON(SAVE_PATH, playerData)
	return false



# reset playerData to defaults and save
func resetData() -> void:
	playerData = loadJSON(DEFAULT_SAVE_PATH)
	saveJSON(SAVE_PATH, playerData)
	print("Data reset to defaults.")


# clamp numeric values in the dictionary
func clampValues(dict: Dictionary) -> void:
	for key in dict.keys():
		var v = dict[key]
		var t = typeof(v)
		if t == TYPE_INT or t == TYPE_FLOAT:
			dict[key] = max(0, v)  # clamp numbers >= 0
		elif t == TYPE_DICTIONARY:
			if key == "stats":  # clamp stats 0..100
				for stat_key in v.keys():
					var stat_val = v[stat_key]
					if typeof(stat_val) in [TYPE_INT, TYPE_FLOAT]:
						v[stat_key] = clamp(stat_val, 0, 100)
			clampValues(v)  # recursive call for nested dictionaries


# delete a file in user:// folder
func delete_user_file(file_name: String) -> void:
	var dir = DirAccess.open("user://")
	if not dir:
		print("Could not open user://")
		return
	var err = dir.remove(file_name)
	if err == OK:
		print("Deleted: user://%s" % file_name)
	else:
		print("Failed to delete user://%s (err %d)" % [file_name, err])
	