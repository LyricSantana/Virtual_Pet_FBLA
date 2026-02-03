extends Node


# Internal helpers
func _get_inventories() -> Dictionary:
	return saveLoadManager.playerData.get("inventories", {})


func _get_inventory(inventory_name: String) -> Dictionary:
	var inventories = _get_inventories()

	if not inventories.has(inventory_name):
		# Auto-create inventory if it doesn't exist
		inventories[inventory_name] = {}

	return inventories[inventory_name]


# Check if an inventory exists
func hasInventory(inventory_name: String) -> bool:
	return _get_inventories().has(inventory_name)


# Get quantity of an item (safe)
func getItemCount(inventory_name: String, item_id: String) -> int:
	var inventory = _get_inventory(inventory_name)
	return inventory.get(item_id, 0)


# Check if item exists (count > 0)
func hasItem(inventory_name: String, item_id: String) -> bool:
	return getItemCount(inventory_name, item_id) > 0


# Add item(s) to an inventory
func addItem(inventory_name: String, item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return

	var inventory = _get_inventory(inventory_name)
	inventory[item_id] = inventory.get(item_id, 0) + amount
	saveLoadManager.saveGame()


# Remove item(s) from an inventory
func removeItem(inventory_name: String, item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false

	var inventory = _get_inventory(inventory_name)

	if not inventory.has(item_id):
		return false

	inventory[item_id] -= amount

	if inventory[item_id] <= 0:
		inventory.erase(item_id)

	saveLoadManager.saveGame()
	return true


# Set item count directly (overwrites)
func setItemCount(inventory_name: String, item_id: String, amount: int) -> void:
	var inventory = _get_inventory(inventory_name)

	if amount <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = amount

	saveLoadManager.saveGame()


# Remove an item completely
func clearItem(inventory_name: String, item_id: String) -> void:
	var inventory = _get_inventory(inventory_name)
	inventory.erase(item_id)
	saveLoadManager.saveGame()


# Clear an entire inventory
func clearInventory(inventory_name: String) -> void:
	var inventory = _get_inventory(inventory_name)
	inventory.clear()
	saveLoadManager.saveGame()


# Get a COPY of an inventory (safe for UI)
func getInventory(inventory_name: String) -> Dictionary:
	return _get_inventory(inventory_name).duplicate(true)


# Get all inventories
func getAllInventories() -> Dictionary:
	return _get_inventories().duplicate(true)


# Loop helper (useful for UI)
func getInventoryItems(inventory_name: String) -> Array:
	var inventory = _get_inventory(inventory_name)
	return inventory.keys()
