# PetManager.gd
# Singleton to manage pets and play animations
# Godot 4 (GDScript) - fully reloads correct template on game load

extends Node2D
class_name PetManager

var player_data: Dictionary = {}
const PET_INVENTORY_KEY: String = "pets"
const SAVE_PATH: String = "user://player_save.json"

var current_pet_node: AnimatedSprite2D = null
var current_pet_id: String = ""

# ----------------------
# internal helpers
# ----------------------
func _get_player_data() -> Dictionary:
	if Engine.has_singleton("saveLoadManager") and typeof(saveLoadManager) != TYPE_NIL:
		return saveLoadManager.playerData
	return player_data

func _ensure_inventories(pd: Dictionary) -> void:
	if not pd.has("inventories"):
		pd["inventories"] = {}
	if not (pd["inventories"] as Dictionary).has(PET_INVENTORY_KEY):
		(pd["inventories"] as Dictionary)[PET_INVENTORY_KEY] = {}

func _sync_to_saveload(pd: Dictionary) -> void:
	if Engine.has_singleton("saveLoadManager") and typeof(saveLoadManager) != TYPE_NIL:
		saveLoadManager.playerData = pd

# ----------------------
# id generation
# ----------------------
func generate_pet_id() -> String:
	var pd: Dictionary = _get_player_data()
	_ensure_inventories(pd)
	var pets: Dictionary = pd["inventories"][PET_INVENTORY_KEY] as Dictionary
	var i: int = 0
	while true:
		var id: String = _to_base36(i)
		if not pets.has(id):
			return id
		i += 1
	return "0"

func _to_base36(n: int) -> String:
	var chars: String = "0123456789abcdefghijklmnopqrstuvwxyz"
	if n == 0:
		return "0"
	var result: String = ""
	var x: int = n
	while x > 0:
		var idx: int = x % 36
		result = chars[idx] + result
		x = x / 36
	return result

# ----------------------
# templates / stats
# ----------------------
func _get_template_stats(template: String) -> Dictionary:
	var templates: Dictionary = {
		"starter_cat": {"hunger": 100, "happiness": 100, "energy": 100, "health": 100, "cleanliness": 100},
		"starter_dog": {"hunger": 100, "happiness": 100, "energy": 100, "health": 100, "cleanliness": 100}
	}
	return templates.get(template, {"hunger": 100, "happiness": 100, "energy": 100, "health": 100, "cleanliness": 100})

# ----------------------
# pet CRUD
# ----------------------
func create_pet(template: String, name: String = "", extra_stats: Dictionary = {}) -> String:
	if template == "":
		push_error("PetManager.create_pet: empty template provided")
		return ""

	var pd = _get_player_data()
	_ensure_inventories(pd)
	var pets: Dictionary = pd["inventories"][PET_INVENTORY_KEY] as Dictionary

	var id: String = generate_pet_id()
	var base_stats = _get_template_stats(template).duplicate(true)
	for k in extra_stats.keys():
		base_stats[k] = extra_stats[k]

	var pet: Dictionary = {
		"id": id,
		"template": template,
		"name": (name if name != "" else template),
		"level": 1,
		"acquired_day": pd.get("day", 0),
		"stats": base_stats,
		"extra": {}
	}

	pets[id] = pet
	pd["inventories"][PET_INVENTORY_KEY] = pets
	player_data = pd
	_sync_to_saveload(pd)

	if Engine.has_singleton("saveLoadManager") and typeof(saveLoadManager) != TYPE_NIL:
		saveLoadManager.playerData["inventories"] = pd["inventories"]
		saveLoadManager.saveGame()

	return id

func get_pet(pet_id: String) -> Dictionary:
	var pd = _get_player_data()
	var pets: Dictionary = pd.get("inventories", {}).get(PET_INVENTORY_KEY, {}) as Dictionary
	return pets.get(pet_id, {})

func set_current_pet(pet_id: String) -> bool:
	var pd = _get_player_data()
	_ensure_inventories(pd)
	var pets: Dictionary = pd["inventories"][PET_INVENTORY_KEY] as Dictionary
	if not pets.has(pet_id):
		return false

	pd["current_pet"] = pet_id
	current_pet_id = pet_id
	_sync_to_saveload(pd)
	if Engine.has_singleton("saveLoadManager") and typeof(saveLoadManager) != TYPE_NIL:
		saveLoadManager.playerData["current_pet"] = pet_id
		saveLoadManager.saveGame()
	player_data = pd

	_load_pet_node_from_template(pet_id)
	return true

# ----------------------
# template resolution / animation
# ----------------------
func _resolve_template(pet_template: String) -> String:
	# always trust the argument first
	if pet_template != "":
		return pet_template

	# fallback: read current pet's template
	var pd = _get_player_data()
	var current_id: String = str(pd.get("current_pet", ""))
	if current_id != "":
		var pet = get_pet(current_id)
		if pet.has("template"):
			return str(pet["template"])
	return ""  # no default, do not guess cat

func changePetAnimation(pet_template: String = "") -> void:
	call_deferred("_changePetAnimationDeferred", pet_template)

func _changePetAnimationDeferred(pet_template: String) -> void:
	var template_name = _resolve_template(pet_template)
	if template_name == "":
		print("PetManager.changePetAnimation: no valid template, skipping animation")
		return
	_play_pet_animation(template_name)

func _play_pet_animation(template_name: String) -> void:
	if not current_pet_node:
		call_deferred("_play_pet_animation", template_name)
		return

	var anim_map = {"starter_cat": "catNormal", "starter_dog": "dogNormal"}
	var anim_name: String = anim_map.get(template_name, "")
	if anim_name == "":
		push_warning("No animation mapping for template: %s" % template_name)
		return

	if current_pet_node is AnimatedSprite2D:
		current_pet_node.play(anim_name)

# ----------------------
# pet node instantiation
# ----------------------
func _load_pet_node_from_template(pet_id: String) -> void:
	var pet = get_pet(pet_id)
	if not pet.has("template"):
		return
	var template_name: String = str(pet["template"])

	# If you already have a pet node, just play the correct animation
	if current_pet_node:
		_play_pet_animation(template_name)

# ----------------------
# starter pet creation
# ----------------------
func create_starter_pet(chosen_template: String) -> String:
	if chosen_template == "":
		push_error("PetManager.create_starter_pet: template required")
		return ""

	var pd = _get_player_data()
	_ensure_inventories(pd)
	var pets: Dictionary = pd["inventories"][PET_INVENTORY_KEY] as Dictionary

	var existing_current: String = str(pd.get("current_pet", ""))
	if existing_current != "" and pets.has(existing_current):
		_load_pet_node_from_template(existing_current)
		return existing_current

	if pets.size() == 0:
		var starter_name = "Buddy" if chosen_template == "starter_dog" else "Mochi"
		var id: String = create_pet(chosen_template, starter_name)
		pd["current_pet"] = id
		current_pet_id = id
		_sync_to_saveload(pd)
		if Engine.has_singleton("saveLoadManager") and typeof(saveLoadManager) != TYPE_NIL:
			saveLoadManager.playerData["current_pet"] = id
			saveLoadManager.saveGame()
		player_data = pd
		_load_pet_node_from_template(id)  # loads correct pet immediately
		return id

	return str(pd.get("current_pet", ""))

# ----------------------
# save/load
# ----------------------
func save_player(path: String = SAVE_PATH) -> void:
	var pd = _get_player_data()
	var json_text: String = JSON.stringify(pd)
	var f = FileAccess.open(path, FileAccess.ModeFlags.WRITE)
	if not f:
		push_error("PetManager.save_player: Cannot open file")
		return
	f.store_string(json_text)
	f.close()

func load_player(path: String = SAVE_PATH) -> void:
	if not FileAccess.file_exists(path):
		return
	var f = FileAccess.open(path, FileAccess.ModeFlags.READ)
	if not f:
		push_error("PetManager.load_player: Cannot open file")
		return
	var text: String = f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_OBJECT and parsed.error == OK and typeof(parsed.result) == TYPE_DICTIONARY:
		player_data = parsed.result
	elif typeof(parsed) == TYPE_DICTIONARY:
		player_data = parsed
	else:
		push_error("PetManager.load_player: parse error %s" % str(parsed.error))

	var current_id: String = str(player_data.get("current_pet", ""))
	if current_id != "":
		current_pet_id = current_id
		call_deferred("_load_pet_node_from_template", current_id)
