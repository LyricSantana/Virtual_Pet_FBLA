# itemDB.gd — refactored
# This is your central item database.
# All items, their names, restore values, and uses live here.
# Think of it like your pet store catalog.

extends Node

# -------------------------
# Item definitions
# -------------------------
var items = {
	"apple": {
		"name": "Apple",
		"restore": {"hunger": 20, "energy": 5}, # stats this item restores
		"uses": 5  # number of times you can use it before consuming
	},
	"toyBall": {
		"name": "Toy Ball",
		"restore": {"happiness": 15},
		"uses": 1
	},
	"medicine": {
		"name": "Medicine",
		"restore": {"health": 25},
		"uses": 1
	},
	"comfyBed": {
		"name": "Comfy Bed",
		"restore": {"energy": 40},
		"uses": 20
	}
}

# -------------------------
# Get an item definition safely
# Returns an empty dictionary if item_id not found
# -------------------------
func get_item(item_id: String) -> Dictionary:
	if items.has(item_id):
		return items[item_id]
	return {}  # safe fallback
