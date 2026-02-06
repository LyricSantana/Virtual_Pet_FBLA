# petManager.gd — refactored
# This node handles your pet sprite, animations, and thought icons.
# It updates visuals based on player stats (hunger, energy, happiness, etc.)

extends Node2D

# -------------------------
# Node references
# -------------------------
@onready var petNode: AnimatedSprite2D = $petSprite          # main pet sprite
@onready var thoughtIcon: TextureRect = $thought             # icon that shows pet's thoughts

# -------------------------
# Preloaded thought icons
# -------------------------
var icons: Dictionary[String, Texture2D] = {}  # dictionary to store icons

# -------------------------
# Player data reference
# -------------------------
var playerData: Dictionary = {}  # this will be updated by GameManager

# -------------------------
# Ready: initialize icons and setup
# -------------------------
func _ready() -> void:
	# check sprite frames exist
	if petNode.sprite_frames == null:
		push_error("SpriteFrames missing! Scene broken?")
		return

	print("Available animations:", petNode.sprite_frames.get_animation_names())

	# make thought icon always render above
	thoughtIcon.visible = false
	thoughtIcon.z_index = 50
	thoughtIcon.process_mode = Node.PROCESS_MODE_ALWAYS

	# preload all thought icons
	icons = {
		"hungry": load("res://assets/sprites/thoughtIcons/hungryIcon.png"),
		"sad":    load("res://assets/sprites/thoughtIcons/sadIcon.png"),
		"tired":  load("res://assets/sprites/thoughtIcons/tiredIcon.png"),
		"sick":   load("res://assets/sprites/thoughtIcons/sickIcon.png"),
		"dirty":  load("res://assets/sprites/thoughtIcons/dirtyIcon.png")
	}

# -------------------------
# Update player data
# Called whenever stats change
# -------------------------
func set_player_data(data: Dictionary) -> void:
	if data == null or data.is_empty():
		push_error("Invalid player data received")
		return

	playerData = data
	update_pet_animation()  # refresh visuals

# -------------------------
# Update pet animation based on stats
# -------------------------
func update_pet_animation() -> void:
	if playerData.is_empty():
		return

	var stats = playerData.get("stats", {})
	var species: String = playerData.get("species", "dog")  # default to dog

	var anim_name = species + "Normal"
	var thought_key: String = ""  # which thought icon to show

	# -------------------------
	# Priority-based thoughts (highest to lowest)
	# -------------------------
	if stats.get("health", 100) <= 50:
		thought_key = "sick"
	elif stats.get("hunger", 100) <= 50:
		thought_key = "hungry"
	elif stats.get("happiness", 100) <= 40:
		thought_key = "sad"
	elif stats.get("energy", 100) <= 30:
		thought_key = "tired"
	elif stats.get("cleanliness", 100) <= 50:
		thought_key = "dirty"

	# -------------------------
	# Set animation and thought icon
	# -------------------------
	if thought_key != "":
		anim_name = species + "Thinking"
		thoughtIcon.texture = icons[thought_key]
		thoughtIcon.visible = true
	else:
		thoughtIcon.texture = null
		thoughtIcon.visible = false

	# play animation safely
	if petNode.sprite_frames.has_animation(anim_name):
		petNode.play(anim_name)
	else:
		petNode.play(species + "Normal")  # fallback

# -------------------------
# Utility to manually show/hide thought icon
# -------------------------
func set_thought_visible(isVisible: bool) -> void:
	if thoughtIcon:
		thoughtIcon.visible = isVisible
