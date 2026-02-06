## Pet manager
# This file controls the pet sprite, animation, and thought bubbles.
# It reads player stats and shows how the pet feels.

extends Node2D

@onready var petNode: AnimatedSprite2D = $petSprite          # main pet sprite
@onready var thoughtIcon: TextureRect = $thought             # icon that shows pet's thoughts

var icons: Dictionary[String, Texture2D] = {}  # dictionary to store icons

var playerData: Dictionary = {}  # this will be updated by GameManager
var thoughtsSuppressed := false
var thoughtBaseOffsets: Dictionary = {}
var thoughtBaseDx: float = 0.0
var thoughtBaseWidth: float = 0.0
var petBasePos: Vector2
var walkOffsetX: float = 0.0
var walkDir: int = 1
var walkMinX: float = 0.0
var walkMaxX: float = 0.0
var currentSpecies: String = "dog"
var dirChangeTimer: float = 0.0
var nextDirChange: float = 0.0
var walkPaused: bool = false
var pauseTimer: float = 0.0

const catThoughtOffset := Vector2(-6, 7)
const dogThoughtOffset := Vector2(-2, 0)
const mirrorThoughtNudgeX := 12.0
const walkRange: float = 360
const walkSpeed: float = 18.0
const walkDirChangeMin: float = 2.0
const walkDirChangeMax: float = 5.0
const walkPauseMin: float = 1.5
const walkPauseMax: float = 3.5
const walkPauseChance: float = 0.35
const criticalStatThreshold: int = 25
const criticalStatCount: int = 3

func _ready() -> void:
	# Set up thought icons and animation layer.
	print("Available animations:", petNode.sprite_frames.get_animation_names())

	# make thought icon always render above
	thoughtIcon.visible = false
	thoughtIcon.z_index = 50
	thoughtIcon.process_mode = Node.PROCESS_MODE_ALWAYS
	petBasePos = petNode.position
	walkMinX = petBasePos.x - (walkRange * 0.5)
	walkMaxX = petBasePos.x + (walkRange * 0.5)
	randomize()
	nextDirChange = randf_range(walkDirChangeMin, walkDirChangeMax)
	set_process(true)
	thoughtBaseOffsets = {
		"left": thoughtIcon.offset_left,
		"top": thoughtIcon.offset_top,
		"right": thoughtIcon.offset_right,
		"bottom": thoughtIcon.offset_bottom
	}
	thoughtBaseWidth = float(thoughtBaseOffsets["right"]) - float(thoughtBaseOffsets["left"])
	var baseCenterX = float(thoughtBaseOffsets["left"]) + (thoughtBaseWidth * 0.5)
	thoughtBaseDx = baseCenterX - petBasePos.x

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
	currentSpecies = species
	_applyThoughtOffset(species)

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
		thoughtIcon.visible = not thoughtsSuppressed
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


func _process(delta: float) -> void:
	# Simple left-right walk across the screen.
	if _isCriticalState():
		walkPaused = true
		pauseTimer = 0.0
		return
	if walkPaused:
		pauseTimer -= delta
		if pauseTimer <= 0.0:
			walkPaused = false
			pauseTimer = 0.0
			dirChangeTimer = 0.0
			nextDirChange = randf_range(walkDirChangeMin, walkDirChangeMax)
		return
	dirChangeTimer += delta
	if dirChangeTimer >= nextDirChange:
		dirChangeTimer = 0.0
		nextDirChange = randf_range(walkDirChangeMin, walkDirChangeMax)
		if randf() < walkPauseChance:
			walkPaused = true
			pauseTimer = randf_range(walkPauseMin, walkPauseMax)
			return
		walkDir = -1 if randf() < 0.5 else 1
	var step = walkSpeed * delta * float(walkDir)
	var nextX = petNode.position.x + step
	if nextX < walkMinX:
		nextX = walkMinX
		walkDir = 1
	elif nextX > walkMaxX:
		nextX = walkMaxX
		walkDir = -1
	petNode.position.x = nextX
	walkOffsetX = nextX - petBasePos.x
	petNode.flip_h = walkDir < 0
	_applyThoughtOffset(currentSpecies)


func _isCriticalState() -> bool:
	# Stop movement when several stats are critically low.
	var stats: Dictionary = playerData.get("stats", {})
	var lowCount = 0
	for statName in stats.keys():
		if int(stats.get(statName, 100)) <= criticalStatThreshold:
			lowCount += 1
	return lowCount >= criticalStatCount


func _applyThoughtOffset(species: String) -> void:
	# Keep the thought bubble aligned to the pet sprite.
	var offset = catThoughtOffset if species == "cat" else dogThoughtOffset
	var baseDx = -thoughtBaseDx if petNode.flip_h else thoughtBaseDx
	var mirrorNudge = mirrorThoughtNudgeX if petNode.flip_h else 0.0
	var centerX = petNode.position.x + baseDx + offset.x + mirrorNudge
	var left = centerX - (thoughtBaseWidth * 0.5)
	var right = centerX + (thoughtBaseWidth * 0.5)
	var top = float(thoughtBaseOffsets["top"]) + offset.y
	var bottom = float(thoughtBaseOffsets["bottom"]) + offset.y
	thoughtIcon.offset_left = round(left)
	thoughtIcon.offset_right = round(right)
	thoughtIcon.offset_top = round(top)
	thoughtIcon.offset_bottom = round(bottom)


# Show or hide the thought icon.
func setThoughtVisible(isVisible: bool):
	# Toggle the thought bubble directly.
	thoughtIcon.visible = isVisible


func setThoughtSuppressed(suppressed: bool) -> void:
	# Hide or show the thought bubble during popups.
	thoughtsSuppressed = suppressed
	if suppressed:
		thoughtIcon.visible = false
	else:
		updatePetAnimation()