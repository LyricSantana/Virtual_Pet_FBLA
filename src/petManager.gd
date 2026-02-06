## Pet manager
# Controls pet animations and thought icons based on player stats.

extends Node2D

@onready var petNode: AnimatedSprite2D = $petSprite          # main pet sprite
@onready var thoughtIcon: TextureRect = $thought             # icon that shows pet's thoughts

var icons: Dictionary[String, Texture2D] = {}  # dictionary to store icons

var playerData: Dictionary = {}  # this will be updated by GameManager

func _ready() -> void:
	# Set up thought icons and animation layer.
	print("Available animations:", petNode.sprite_frames.get_animation_names())

	# make thought icon always render above
	thoughtIcon.visible = false
	thoughtIcon.z_index = 50
	thoughtIcon.process_mode = Node.PROCESS_MODE_ALWAYS

	# Preload all thought icons.
	icons = {
		"hungry": load("res://assets/sprites/thoughtIcons/hungryIcon.png"),
		"sad":    load("res://assets/sprites/thoughtIcons/sadIcon.png"),
		"tired":  load("res://assets/sprites/thoughtIcons/tiredIcon.png"),
		"sick":   load("res://assets/sprites/thoughtIcons/sickIcon.png"),
		"dirty":  load("res://assets/sprites/thoughtIcons/dirtyIcon.png")
	}


# Update player data and refresh visuals.
func setPlayerData(data: Dictionary) -> void:
	playerData = data
	updatePetAnimation()  # refresh visuals


# Update pet animation based on stats.
func updatePetAnimation() -> void:
	var stats = playerData.get("stats", {})
	var species: String = playerData.get("species", "dog")  # default to dog

	var animName = species + "Normal"
	var thoughtKey: String = ""  # which thought icon to show

	# Priority-based thoughts
	if stats.get("health", 100) <= 50:
		thoughtKey = "sick"
	elif stats.get("hunger", 100) <= 50:
		thoughtKey = "hungry"
	elif stats.get("happiness", 100) <= 40:
		thoughtKey = "sad"
	elif stats.get("energy", 100) <= 30:
		thoughtKey = "tired"
	elif stats.get("cleanliness", 100) <= 50:
		thoughtKey = "dirty"

	# Set animation and thought icon
	if thoughtKey != "":
		animName = species + "Thinking"
		thoughtIcon.texture = icons[thoughtKey]
		thoughtIcon.visible = true
	else:
		thoughtIcon.texture = null
		thoughtIcon.visible = false

	# Play animation safely
	if petNode.sprite_frames.has_animation(animName):
		petNode.play(animName)
	elif petNode.sprite_frames.has_animation(species + "Idle"):  # fallback to idle
		petNode.play(species + "Idle")
	elif petNode.sprite_frames.get_animation_names().size() > 0:
		petNode.play(petNode.sprite_frames.get_animation_names()[0])  # any animation available
	else:
		# no animations at all, do nothing
		pass


# Show or hide the thought icon.
func setThoughtVisible(input: bool):
	thoughtIcon.visible = input