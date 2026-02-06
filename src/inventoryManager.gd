## Inventory manager
# Handles all inventory add/remove/get logic and keeps save data in sync.

extends Node


# Get or create the main inventories dictionary.
func _getInventories() -> Dictionary:
	saveLoadManager.playerData["inventories"] = saveLoadManager.playerData.get("inventories", {})
	return saveLoadManager.playerData["inventories"]


# Get or create one inventory by name.
func _getInventory(inventoryName: String) -> Dictionary:
	var inventories = _getInventories()
	inventories[inventoryName] = inventories.get(inventoryName, {})
	return inventories[inventoryName]


# Check if an inventory exists.
func hasInventory(inventoryName: String) -> bool:
	return _getInventories().has(inventoryName)


# Return how many of an item are in an inventory.
func getItemCount(inventoryName: String, itemId: String) -> int:
	var inventory = _getInventory(inventoryName)
	var entry = inventory.get(itemId, 0)
	if typeof(entry) == TYPE_DICTIONARY:
		return int(entry.get("count", 0))
	return int(entry)


# True if at least one of the item exists.
func hasItem(inventoryName: String, itemId: String) -> bool:
	return getItemCount(inventoryName, itemId) > 0


# Add items to an inventory.
func addItem(inventoryName: String, itemId: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	var inventory = _getInventory(inventoryName)
	var entry = inventory.get(itemId, 0)
	if typeof(entry) == TYPE_DICTIONARY:
		entry["count"] = int(entry.get("count", 0)) + amount
		inventory[itemId] = entry
	else:
		inventory[itemId] = int(entry) + amount
	saveLoadManager.saveGame()


# Remove items; returns true if removal happened.
func removeItem(inventoryName: String, itemId: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false

	var inventory = _getInventory(inventoryName)
	var entry = inventory.get(itemId, null)
	if entry == null:
		return false

	if typeof(entry) == TYPE_DICTIONARY:
		entry["count"] = int(entry.get("count", 0)) - amount
		if entry["count"] <= 0:
			inventory.erase(itemId)
		else:
			inventory[itemId] = entry
	else:
		var newCount = int(entry) - amount
		if newCount <= 0:
			inventory.erase(itemId)
		else:
			inventory[itemId] = newCount

	saveLoadManager.saveGame()
	return true


# Set item count directly.
func setItemCount(inventoryName: String, itemId: String, amount: int) -> void:
	var inventory = _getInventory(inventoryName)
	if amount <= 0:
		inventory.erase(itemId)
	else:
		inventory[itemId] = amount
	saveLoadManager.saveGame()


# Remove an item completely.
func clearItem(inventoryName: String, itemId: String) -> void:
	var inventory = _getInventory(inventoryName)
	inventory.erase(itemId)
	saveLoadManager.saveGame()


# Clear every item in an inventory.
func clearInventory(inventoryName: String) -> void:
	var inventory = _getInventory(inventoryName)
	inventory.clear()
	saveLoadManager.saveGame()


# Return a safe copy of one inventory.
func getInventory(inventoryName: String) -> Dictionary:
	return _getInventory(inventoryName).duplicate(true)


# Return a safe copy of all inventories.
func getAllInventories() -> Dictionary:
	return _getInventories().duplicate(true)


# Return the item IDs in an inventory.
func getInventoryItems(inventoryName: String) -> Array:
	return _getInventory(inventoryName).keys()
