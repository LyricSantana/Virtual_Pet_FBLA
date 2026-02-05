extends Node2D

@onready var petNode = $petSprite

func _ready():
	if petNode.sprite_frames == null:
		push_error("SpriteFrames is NULL — scene binding broken")
		return

	print("Animations:", petNode.sprite_frames.get_animation_names())

func play_pet_animation(species: String) -> void:
	if petNode.sprite_frames == null:
		push_error("Cannot play animation, SpriteFrames null")
		return

	match species:
		"dog":
			petNode.play("dogNormal")
		"cat":
			petNode.play("catNormal")
		_:
			push_error("Unknown species: " + species)
