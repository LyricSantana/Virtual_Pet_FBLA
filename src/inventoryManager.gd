# inventoryManager.gd — refactored
# This handles ALL the player's inventories: add/remove/set/clear/get.
# Think of it as your digital backpack manager. Pretty much everything your pet owns passes through here.

extends Node

# -------------------------
# Helper: get all top-level inventories
# -------------------------
func _get_inventories() -> Dictionary:
	# make sure playerData has an 'inventories' dictionary
	if not saveLoadManager.playerData.has("inventories"):
		saveLoadManager.playerData["inventories"] = {}
	return saveLoadManager.playerData["inventories"]


# -------------------------
# Helper: get a specific inventory by name
# -------------------------
func _get_inventory(inventory_name: String) -> Dictionary:
	var invs = _get_inventories()
	if not invs.has(inventory_name):
		invs[inventory_name] = {}  # auto-create if missing
	# return reference so changes modify the actual playerData
	return invs[inventory_name]


# -------------------------
# Check if inventory exists
# -------------------------
func hasInventory(inventory_name: String) -> bool:
	return _get_inventories().has(inventory_name)


# -------------------------
# Get number of a specific item in an inventory
# -------------------------
func getItemCount(inventory_name: String, item_id: String) -> int:
	var inventory = _get_inventory(inventory_name)
	return int(inventory.get(item_id, 0))


# -------------------------
# Check if inventory has at least 1 of an item
# -------------------------
func hasItem(inventory_name: String, item_id: String) -> bool:
	return getItemCount(inventory_name, item_id) > 0


# -------------------------
# Add items to an inventory
# -------------------------
func addItem(inventory_name: String, item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return  # don't add negative stuff
	var inventory = _get_inventory(inventory_name)
	inventory[item_id] = inventory.get(item_id, 0) + amount
	saveLoadManager.saveGame()


# -------------------------
# Remove items from inventory
# returns true if successful, false if not enough items
# -------------------------
func removeItem(inventory_name: String, item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false

	var inventory = _get_inventory(inventory_name)
	if not inventory.has(item_id):
		return false

	var entry = inventory[item_id]

	if typeof(entry) == TYPE_DICTIONARY:
		# modern format: subtract from 'count'
		entry["count"] = int(entry.get("count", 0)) - amount
		if entry["count"] <= 0:
			inventory.erase(item_id)
	else:
		# legacy numeric format
		var new_count = int(entry) - amount
		if new_count <= 0:
			inventory.erase(item_id)
		else:
			inventory[item_id] = new_count

	saveLoadManager.saveGame()
	return true


# -------------------------
# Overwrite item count directly
# -------------------------
func setItemCount(inventory_name: String, item_id: String, amount: int) -> void:
	var inventory = _get_inventory(inventory_name)
	if amount <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = amount
	saveLoadManager.saveGame()


# -------------------------
# Clear an item completely
# -------------------------
func clearItem(inventory_name: String, item_id: String) -> void:
	var inventory = _get_inventory(inventory_name)
	inventory.erase(item_id)
	saveLoadManager.saveGame()


# -------------------------
# Clear all items from an inventory
# -------------------------
func clearInventory(inventory_name: String) -> void:
	var inventory = _get_inventory(inventory_name)
	inventory.clear()
	saveLoadManager.saveGame()


# -------------------------
# Get a copy of an inventory (safe for UI)
# -------------------------
func getInventory(inventory_name: String) -> Dictionary:
	return _get_inventory(inventory_name).duplicate(true)


# -------------------------
# Get all inventories (safe copy)
# -------------------------
func getAllInventories() -> Dictionary:
	return _get_inventories().duplicate(true)


# -------------------------
# Return all item IDs in an inventory (useful for UI loops)
# -------------------------
func getInventoryItems(inventory_name: String) -> Array:
	return _get_inventory(inventory_name).keys()
