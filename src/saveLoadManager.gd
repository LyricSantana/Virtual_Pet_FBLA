# This manager handles defaults, user saves, merging, clamping, and basic file I/O.
# It is careful about missing files and tries not to scream at the player if something's broken.

extends Node

# -------------------------
# Paths
# -------------------------
const DEFAULT_SAVE_PATH: String = "res://src/defaultSave.json"  # packaged defaults (read-only in exported game)
const SAVE_PATH: String = "user://player_save.json"             # writable user save location

# -------------------------
# In-memory player data
# -------------------------
var playerData: Dictionary = {}  # holds the merged active data we use at runtime

# -------------------------
# Ready: load defaults into memory so we have a baseline
# -------------------------
func _ready() -> void:
	# Load defaults first. We keep them in memory as the baseline for merging later.
	playerData = _safe_load_json(DEFAULT_SAVE_PATH)


# -------------------------
# Low-level JSON loader (safe)
# Returns a Dictionary or empty Dictionary on failure.
# Works with various Godot JSON return shapes.
# -------------------------
func _safe_load_json(path: String) -> Dictionary:
	# If file doesn't exist (common for user://), return empty dict
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("Could not open JSON at: %s" % path)
		return {}

	var text: String = file.get_as_text()
	file.close()

	# parse robustly — Godot may return an object/dict with .error and .result
	var parsed = JSON.parse_string(text)

	# If parse returns an object-like container with error/result
	if typeof(parsed) == TYPE_OBJECT:
		if parsed.error == OK and typeof(parsed.result) == TYPE_DICTIONARY:
			return parsed.result.duplicate(true)
		else:
			push_error("JSON parse error (%d) in %s" % [parsed.error, path])
			return {}

	# If parse returned a Dictionary directly (some builds), return it
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed.duplicate(true)

	# fallback — give an error and return empty
	push_error("Failed to parse JSON from %s" % path)
	return {}


# -------------------------
# Low-level JSON saver
# Writes a dictionary to a file. Returns true on success.
# -------------------------
func _safe_save_json(path: String, data: Dictionary) -> bool:
	var json_string: String = JSON.stringify(data, "\t")  # pretty-print for debugging
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Could not open file for writing: %s" % path)
		return false
	file.store_string(json_string)
	file.close()
	return true


# -------------------------
# Merge defaults with user_data
# Behavior:
# - Start from a deep copy of defaults
# - Keys present in user_data override defaults
# - If user supplies an empty Dictionary for a key, we treat that as "explicitly empty"
# - Recurses when both sides are dictionaries
# -------------------------
func mergeDicts(defaults: Dictionary, user_data: Dictionary) -> Dictionary:
	# copy defaults so we don't mutate the original table
	var result: Dictionary = defaults.duplicate(true)

	for key in user_data.keys():
		var uval = user_data[key]
		# if user provided a dictionary, handle recursively
		if typeof(uval) == TYPE_DICTIONARY:
			# explicit empty dict means "user cleared the defaults" — respect that
			if uval.size() == 0:
				result[key] = {}
				continue

			# if default also has a dict, merge them recursively
			if result.has(key) and typeof(result[key]) == TYPE_DICTIONARY:
				result[key] = mergeDicts(result[key], uval)
			else:
				# user provided a dict and default didn't — take user's copy
				result[key] = uval.duplicate(true)
		else:
			# primitives: user overrides default
			result[key] = uval

	return result


# -------------------------
# Save the current in-memory playerData to disk
# Returns true if saved successfully.
# -------------------------
func saveGame() -> bool:
	# make sure numeric fields obey constraints before writing
	clampValues(playerData)
	if _safe_save_json(SAVE_PATH, playerData):
		print("Game saved to %s" % SAVE_PATH)
		return true
	push_error("Failed to save game to %s" % SAVE_PATH)
	return false


# -------------------------
# Load user save and merge with defaults already in memory
# Returns true if a user save was loaded, false if no user save existed
# -------------------------
func loadGame() -> bool:
	var user_data: Dictionary = _safe_load_json(SAVE_PATH)
	if user_data.size() > 0:
		# merge current baseline (playerData) with user save — user overrides
		playerData = mergeDicts(playerData, user_data)
		print("Loaded user save from %s" % SAVE_PATH)
		return true

	# if user save missing, write the current defaults out so user has a file to edit later
	print("Save missing or corrupted. Creating new user save from defaults.")
	_safe_save_json(SAVE_PATH, playerData)
	return false


# -------------------------
# Reset to packaged defaults (danger: overwrites user save)
# -------------------------
func resetData() -> void:
	playerData = _safe_load_json(DEFAULT_SAVE_PATH)
	_safe_save_json(SAVE_PATH, playerData)
	print("Data reset to defaults.")


# -------------------------
# Clamp numeric values and sanitize nested dictionaries
# Rules:
# - For numeric values at top-level: clamp to >= 0 (no negative money, etc.)
# - For 'stats' dictionary: clamp each stat to 0..100
# - Recurses into nested dictionaries to enforce above rules
# -------------------------
func clampValues(dict: Dictionary) -> void:
	# Defensive: if someone passes null or a non-dict, bail
	if typeof(dict) != TYPE_DICTIONARY:
		return

	for key in dict.keys():
		var val = dict[key]
		var t = typeof(val)

		# Primitive numbers: ensure they're non-negative
		if t == TYPE_INT or t == TYPE_FLOAT:
			# top-level numeric fields shouldn't be negative; enforce it here
			dict[key] = max(0, val)

		elif t == TYPE_DICTIONARY:
			# Special case: clamp stats to 0..100
			if key == "stats":
				for stat_key in val.keys():
					var s = val[stat_key]
					if typeof(s) in [TYPE_INT, TYPE_FLOAT]:
						val[stat_key] = clamp(s, 0, 100)
			# Recurse for nested dictionaries
			clampValues(val)


# -------------------------
# Delete a file in the user:// folder (helper for reset/delete actions)
# -------------------------
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
