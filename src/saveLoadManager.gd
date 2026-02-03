extends Node

const DEFAULT_SAVE_PATH := "res://src/defaultSave.json"
const SAVE_PATH := "user://player_save.json"

var playerData: Dictionary = {}

# Change data example:
# saveLoadManager.playerData["species"] = "dog"
# saveLoadManager.playerData["inventories"]["feed"] = "dog"

# default save:
# {
# 	"current_pet": "cat",
# 	"money": 0,
# 	"day": 0,
# 	"level": 1,
# 	"hunger": 100,
# 	"happiness": 100,
# 	"energy": 100,
# 	"health": 100,
# 	"cleanliness": 100
# }

func _ready() -> void:
	playerData = loadJSON(DEFAULT_SAVE_PATH)
	loadGame()



func loadJSON(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("Could not open JSON file: %s" % path)
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	push_error("Failed to parse JSON from %s. Result type: %s" % [path, typeof(parsed)])
	return {}


func saveJSON(path: String, data: Dictionary) -> bool:
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Could not open file for writing: %s" % path)
		return false
	file.store_string(json_string)
	file.close()
	return true



func mergeDicts(default: Dictionary, user: Dictionary) -> Dictionary:

	var result := {}
	for k in default.keys():
		result[k] = default[k]

	for k in user.keys():
		if result.has(k) and typeof(result[k]) == TYPE_DICTIONARY and typeof(user[k]) == TYPE_DICTIONARY:
			result[k] = mergeDicts(result[k], user[k])
		else:
			result[k] = user[k]
	return result


func saveGame() -> bool:
	if saveJSON(SAVE_PATH, playerData):
		print("Game saved to %s" % SAVE_PATH)
		return true
	else:
		push_error("Failed to save game.")
		return false


func loadGame() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var user_data := loadJSON(SAVE_PATH)
		if user_data.size() > 0:
			playerData = mergeDicts(playerData, user_data)
			print("Loaded user save from %s" % SAVE_PATH)
			return true
		else:
			push_warning("User save exists but failed to parse; using defaults.")
			return false

	print("Save file not found. Creating new user save from defaults.")
	saveJSON(SAVE_PATH, playerData)
	return false


func resetData() -> void:
	playerData = loadJSON(DEFAULT_SAVE_PATH)
	saveJSON(SAVE_PATH, playerData)
	print("Data reset to defaults.")