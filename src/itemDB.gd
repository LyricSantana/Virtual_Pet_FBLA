## Item database
# This file holds the shop item list and their effects.
# Other scripts read this to show names, prices, and stat changes.

extends Node

var itemCatalog = {
	"petFood": {
		"name": "Pet Food",
		"restore": {"hunger": 20, "energy": 5}, # stats this item restores
		"uses": 1  # number of times you can use it before consuming
	},
	"veggieMix": {
		"name": "Veggie Mix",
		"restore": {"hunger": 25, "energy": 10},
		"uses": 3
	},
	"heartyStew": {
		"name": "Hearty Stew",
		"restore": {"hunger": 45, "energy": 20, "health": 5},
		"uses": 2
	},
	"beefJerky": {
		"name": "Beef Jerky",
		"restore": {"hunger": 30, "happiness": 5},
		"uses": 3
	},
	"tunaTreat": {
		"name": "Tuna Treat",
		"restore": {"hunger": 28, "happiness": 8},
		"uses": 3
	},
	"toyBall": {
		"name": "Toy Ball",
		"restore": {"happiness": 15},
		"uses": 1
	},
	"laserPointer": {
		"name": "Laser Pointer",
		"restore": {"happiness": 25, "energy": -5},
		"uses": 5
	},
	"featherWand": {
		"name": "Feather Wand",
		"restore": {"happiness": 22},
		"uses": 4
	},
	"squeakyBone": {
		"name": "Squeaky Bone",
		"restore": {"happiness": 24},
		"uses": 4
	},
	"tugRope": {
		"name": "Tug Rope",
		"restore": {"happiness": 18, "energy": -3},
		"uses": 6
	},
	"medicine": {
		"name": "Medicine",
		"restore": {"health": 25},
		"uses": 1
	},
	"bandageWrap": {
		"name": "Bandage Wrap",
		"restore": {"health": 18},
		"uses": 3
	},
	"vetVisit": {
		"name": "Vet Visit",
		"restore": {"health": 35, "energy": 10},
		"uses": 1
	},
	"calmingSpray": {
		"name": "Calming Spray",
		"restore": {"happiness": 10, "health": 10},
		"uses": 5
	},
	"fleaShampoo": {
		"name": "Flea Shampoo",
		"restore": {"health": 12, "cleanliness": 20},
		"uses": 2
	},
	"comfyBed": {
		"name": "Comfy Bed",
		"restore": {"energy": 40},
		"uses": 20
	},
	"cozyBlanket": {
		"name": "Cozy Blanket",
		"restore": {"energy": 18, "happiness": 8},
		"uses": 10
	},
	"deluxeBed": {
		"name": "Deluxe Bed",
		"restore": {"energy": 60, "health": 5},
		"uses": 25
	},
	"catCave": {
		"name": "Cat Cave",
		"restore": {"energy": 30, "happiness": 12},
		"uses": 15
	},
	"dogCushion": {
		"name": "Dog Cushion",
		"restore": {"energy": 32, "happiness": 10},
		"uses": 15
	},
	"bubbleBath": {
		"name": "Bubble Bath",
		"restore": {"cleanliness": 40, "happiness": 5},
		"uses": 2
	},
	"petWipes": {
		"name": "Pet Wipes",
		"restore": {"cleanliness": 15},
		"uses": 5
	},
	"deodorizer": {
		"name": "Deodorizer",
		"restore": {"cleanliness": 22},
		"uses": 4
	},
	"nailTrimmer": {
		"name": "Nail Trimmer",
		"restore": {"cleanliness": 12, "health": 5},
		"uses": 6
	},
	"earCleaner": {
		"name": "Ear Cleaner",
		"restore": {"cleanliness": 18, "health": 8},
		"uses": 4
	}
}

# Get an item definition by id.
func getItem(itemId: String) -> Dictionary:
	return itemCatalog.get(itemId, {})
