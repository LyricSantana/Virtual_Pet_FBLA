extends Node

# ==========================
# Item Database
# ==========================
var items = {
	"apple": {
		"name": "Apple",
		"restore": {"hunger": 20, "energy": 5},
		"uses": 5
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

# get an item definition safely
func get_item(item_id: String) -> Dictionary:
	if items.has(item_id):
		return items[item_id]
	return {}
