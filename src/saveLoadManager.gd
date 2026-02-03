extends Node

const DEFAULT_SAVE_PATH := "res://src/defaultSave.json" # this is the default save file that never changes
const SAVE_PATH := "user://player_save.json" # this is the save file for the player

var playerData: Dictionary = {} # this stores all the player's data


# TODO Remove resetData
func _ready() -> void:
	# load the default JSON first
	playerData = loadJSON(DEFAULT_SAVE_PATH)
	
func loadJSON(path: String) -> Dictionary:
	# load a json file and return it as a dictionary
	if not FileAccess.file_exists(path):
		return {} # return empty dictionary if file doesn't exist
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("Could not open JSON file: %s" % path)
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed # return parsed dictionary
	push_error("Failed to parse JSON from %s" % path)
	return {}	

func saveJSON(path: String, data: Dictionary) -> bool:
	# save a dictionary to a JSON file
	var json_string := JSON.stringify(data, "\t") # convert dictionary to JSON string with tabs
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Could not open file for writing: %s" % path)
		return false
	file.store_string(json_string)
	file.close()
	return true

func mergeDicts(default: Dictionary, user: Dictionary) -> Dictionary:
	# merge two dictionaries, user values overwrite defaults
	var result := {}
	for k in default.keys():
		result[k] = default[k] # start with all defaults
	for k in user.keys():
		# if both are dictionaries, merge recursively
		if result.has(k) and typeof(result[k]) == TYPE_DICTIONARY and typeof(user[k]) == TYPE_DICTIONARY:
			result[k] = mergeDicts(result[k], user[k])
		else:
			result[k] = user[k] # otherwise just take the user's value
	return result

func saveGame() -> bool:
	# saves the current player data to the user save file
	if saveJSON(SAVE_PATH, playerData):
		print("Game saved to %s" % SAVE_PATH)
		return true
	push_error("Failed to save game.")
	return false

func loadGame() -> bool:
	# loads the user save file and merges it with defaults
	var user_data := loadJSON(SAVE_PATH)
	if user_data.size() > 0:
		playerData = mergeDicts(playerData, user_data)
		print("Loaded user save from %s" % SAVE_PATH)
		return true
	# if the save doesn't exist or is corrupted, create a new one
	print("Save file missing or corrupted. Creating new user save from defaults.")
	saveJSON(SAVE_PATH, playerData)
	return false

func resetData() -> void:
	# resets the save file to defaults
	playerData = loadJSON(DEFAULT_SAVE_PATH)
	saveJSON(SAVE_PATH, playerData)
	print("Data reset to defaults.")


func clampValues(dict: Dictionary) -> void:
	# make sure all values are within safe ranges
	for key in dict.keys():
		if typeof(dict[key]) == TYPE_INT or typeof(dict[key]) == TYPE_FLOAT:
			# if it's stats, clamp them between 0 and 100
			if key == "stats" and typeof(dict[key]) == TYPE_DICTIONARY:
				clampValues(dict[key])
			elif key in playerData.get("stats", {}):
				dict[key] = clamp(dict[key], 0, 100)
			else:
				# other values like money or days can't be negative
				dict[key] = max(0, dict[key])
		elif typeof(dict[key]) == TYPE_DICTIONARY:
			# recursively clamp any nested dictionaries
			clampValues(dict[key])


func delete_user_file(file_name: String):
	var file_path = "user://" + file_name
	
	# Optional: Check if the file exists before attempting to delete
	if FileAccess.file_exists(file_path):
		var error = DirAccess.remove_absolute(file_path)
		if error == OK:
			print("Successfully deleted file: %s" % file_path)
		else:
			print("Failed to delete file: %s. Error code: %d" % [file_path, error])
	else:
		print("File not found: %s" % file_path)
