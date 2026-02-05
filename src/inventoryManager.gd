extends Node

# helpers for managing inventories
# uses saveLoadManager.playerData


# get top-level inventories dictionary, create if missing
func _get_inventories() -> Dictionary:
	if not saveLoadManager.playerData.has("inventories"):
		saveLoadManager.playerData["inventories"] = {}
	return saveLoadManager.playerData["inventories"]


# get a specific inventory, auto-create it if missing
func _get_inventory(inventory_name: String) -> Dictionary:
	var invs = _get_inventories()
	if not invs.has(inventory_name):
		invs[inventory_name] = {}
	# Return a reference to the **actual dictionary** in playerData, not a copy
	return invs[inventory_name]


# check if an inventory exists
func hasInventory(inventory_name: String) -> bool:
	return _get_inventories().has(inventory_name)


# get how many of a certain item exist in an inventory
func getItemCount(inventory_name: String, item_id: String) -> int:
	var inventory = _get_inventory(inventory_name)
	return int(inventory.get(item_id, 0))


# check if inventory has at least one of an item
func hasItem(inventory_name: String, item_id: String) -> bool:
	return getItemCount(inventory_name, item_id) > 0


# add items to an inventory, amount defaults to 1
func addItem(inventory_name: String, item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	var inventory = _get_inventory(inventory_name)
	inventory[item_id] = inventory.get(item_id, 0) + amount
	saveLoadManager.saveGame()


# remove items from inventory, returns true if successful
func removeItem(inventory_name: String, item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var inventory = _get_inventory(inventory_name)
	if not inventory.has(item_id):
		return false

	var entry = inventory[item_id]

	if typeof(entry) == TYPE_DICTIONARY:
		# subtract from "count"
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



# set an item's count directly (overwrites existing count)
func setItemCount(inventory_name: String, item_id: String, amount: int) -> void:
	var inventory = _get_inventory(inventory_name)
	if amount <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = amount
	saveLoadManager.saveGame()


# remove an item completely from an inventory
func clearItem(inventory_name: String, item_id: String) -> void:
	var inventory = _get_inventory(inventory_name)
	inventory.erase(item_id)
	saveLoadManager.saveGame()


# remove all items from an inventory
func clearInventory(inventory_name: String) -> void:
	var inventory = _get_inventory(inventory_name)
	inventory.clear()
	saveLoadManager.saveGame()


# get a deep copy of an inventory so UI can use it safely
func getInventory(inventory_name: String) -> Dictionary:
	return _get_inventory(inventory_name).duplicate(true)


# get a deep copy of all inventories
func getAllInventories() -> Dictionary:
	return _get_inventories().duplicate(true)


# get a list of item IDs in an inventory (good for UI loops)
func getInventoryItems(inventory_name: String) -> Array:
	var inventory = _get_inventory(inventory_name)
	return inventory.keys()
