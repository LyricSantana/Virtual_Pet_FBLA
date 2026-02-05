extends Node2D

@onready var petNode: AnimatedSprite2D = $petSprite
@onready var thoughtIcon: TextureRect = $thought   # <-- sibling, not child of sprite

# Cache all thought icons
var icons: Dictionary[String, Texture2D] = {}

var playerData: Dictionary = {}

func _ready() -> void:
	if petNode.sprite_frames == null:
		push_error("SpriteFrames is NULL — scene binding broken")
		return

	print("Animations:", petNode.sprite_frames.get_animation_names())

	# Ensure thought icon renders correctly
	thoughtIcon.visible = false
	thoughtIcon.z_index = 50
	thoughtIcon.process_mode = Node.PROCESS_MODE_ALWAYS

	# Preload icons
	icons = {
		"hungry": load("res://assets/sprites/thoughtIcons/hungryIcon.png"),
		"sad":    load("res://assets/sprites/thoughtIcons/sadIcon.png"),
		"tired":  load("res://assets/sprites/thoughtIcons/tiredIcon.png"),
		"sick":   load("res://assets/sprites/thoughtIcons/sickIcon.png"),
		"dirty":  load("res://assets/sprites/thoughtIcons/dirtyIcon.png")
	}

func set_player_data(data: Dictionary) -> void:
	if data == null or data.is_empty():
		push_error("set_player_data received invalid data")
		return
	print("Thought:", thoughtIcon.texture, " visible:", thoughtIcon.visible)
	playerData = data
	update_pet_animation()


func update_pet_animation() -> void:
	if playerData.is_empty():
		return

	var stats = playerData.get("stats", {})
	var species: String = playerData.get("species", "dog")

	var anim_name := species + "Normal"
	var thought_key: String = ""

	# Priority-based thoughts
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

	# Thinking vs normal
	if thought_key != "":
		anim_name = species + "Thinking"
		thoughtIcon.texture = icons[thought_key]
		thoughtIcon.visible = true
	else:
		thoughtIcon.texture = null
		thoughtIcon.visible = false

	# Play animation safely
	if petNode.sprite_frames.has_animation(anim_name):
		petNode.play(anim_name)
	else:
		petNode.play(species + "Normal")

func set_thought_visible(isVisible: bool) -> void:
	if thoughtIcon:
		thoughtIcon.visible = isVisible
