extends Node2D

@onready var petNode: AnimatedSprite2D = $petSprite
@onready var thoughtIcon: TextureRect = $petSprite/thought  # TextureRect overlay for moods/icons

# Cache all thought icons
var icons: Dictionary = {}

var playerData: Dictionary = {}  # currently loaded player data

func _ready() -> void:
	if petNode.sprite_frames == null:
		push_error("SpriteFrames is NULL — scene binding broken")
		return

	print("Animations:", petNode.sprite_frames.get_animation_names())

	# Load all icons once
	icons = {
		"hungry": load("res://assets/sprites/thoughtIcons/hungryIcon.png"),
		"sad":    load("res://assets/sprites/thoughtIcons/sadIcon.png"),
		"tired":  load("res://assets/sprites/thoughtIcons/tiredIcon.png"),
		"sick":   load("res://assets/sprites/thoughtIcons/sickIcon.png"),
		"dirty":  load("res://assets/sprites/thoughtIcons/dirtyIcon.png")
	}

# --- Public API ---
func set_player_data(data: Dictionary) -> void:
	if data == null:
		push_error("set_player_data received null")
		return
	playerData = data
	update_pet_animation()

func update_pet_animation() -> void:
	if petNode.sprite_frames == null or playerData.size() == 0:
		return

	var stats = playerData.get("stats", {})
	var species = playerData.get("species", "dog")  # default species if missing

	var anim_name = species + "Normal"
	var thought_texture: Texture = null

	# --- Determine emotion/thought based on stats ---
	if stats.get("health", 100) <= 50:
		anim_name = species + "Thinking"
		thought_texture = icons.get("sick")
	elif stats.get("hunger", 100) <= 50:
		anim_name = species + "Thinking"
		thought_texture = icons.get("hungry")
	elif stats.get("happiness", 100) <= 40:
		anim_name = species + "Thinking"
		thought_texture = icons.get("sad")
	elif stats.get("energy", 100) <= 30:
		anim_name = species + "Thinking"
		thought_texture = icons.get("tired")
	elif stats.get("cleanliness", 100) <= 50:
		anim_name = species + "Thinking"
		thought_texture = icons.get("dirty")
	# else leave as Normal

	# --- Update thought icon overlay ---
	if thoughtIcon:
		thoughtIcon.texture = thought_texture

	# --- Play animation safely ---
	if petNode.sprite_frames.has_animation(anim_name):
		petNode.play(anim_name)
	else:
		# fallback to Normal animation if specific one is missing
		if petNode.sprite_frames.has_animation(species + "Normal"):
			petNode.play(species + "Normal")
		else:
			push_error("No valid animation found for species: " + species)

# Optional: play a specific animation manually
func play_pet_animation(animation: String) -> void:
	if petNode.sprite_frames == null:
		push_error("Cannot play animation, SpriteFrames null")
		return

	if petNode.sprite_frames.has_animation(animation):
		petNode.play(animation)
	else:
		push_error("Unknown animation: " + animation)
