## Start screen controller
# This file runs the start menu and pet setup flow.
# It handles new saves and moving into the main game.

extends Control

var chosenSpecies: String = ""      # "cat" or "dog" or empty if none selected

@onready var startPanel = $startPanel
@onready var petPanel = $petSelectPanel
@onready var startButton = $startPanel/VBoxContainer/startButton
@onready var settingsButton = $startPanel/VBoxContainer/settingsButton
@onready var catButton = $petSelectPanel/VBoxContainer/HBoxContainer/catButton
@onready var dogButton = $petSelectPanel/VBoxContainer/HBoxContainer/dogButton
@onready var nameInput = $petSelectPanel/VBoxContainer/nameInput
@onready var confirmButton = $petSelectPanel/VBoxContainer/confirmButton
@onready var backButton = $petSelectPanel/VBoxContainer/backButton
@onready var errorLabel = $petSelectPanel/VBoxContainer/errorLabel
@onready var settingsPanel = $CanvasLayer/settingsPanel
@onready var settingsBackButton = $CanvasLayer/settingsPanel/settingsPopup/VBoxContainer/backButton
@onready var deleteButton = $CanvasLayer/settingsPanel/settingsPopup/VBoxContainer/deleteButton
@onready var quitButton = $CanvasLayer/settingsPanel/settingsPopup/VBoxContainer/quitButton

var petManagerRef               # petManager autoload
var uiNode
var startLayer

func _ready() -> void:
	# Cache nodes and autoloads.
	startLayer = get_parent()
	uiNode = get_tree().get_root().get_node("Main/UI")
	petManagerRef = petManager

	# Hide in-game UI while on start.
	uiNode.visible = false

	# Start screen default visibility
	startPanel.visible = true
	petPanel.visible = false
	settingsPanel.visible = false

	# Connect important buttons (assume nodes exist in scene structure)
	startButton.pressed.connect(_onStartPressed)
	settingsButton.pressed.connect(_onSettingsPressed)
	catButton.pressed.connect(func() -> void: _selectSpecies("cat"))
	dogButton.pressed.connect(func() -> void: _selectSpecies("dog"))
	confirmButton.pressed.connect(_onConfirmPressed)
	backButton.pressed.connect(_onBackPressed)
	settingsBackButton.pressed.connect(_onSettingsBackPressed)
	deleteButton.pressed.connect(_onDeletePressed)
	quitButton.pressed.connect(_onQuitPressed)

	_wireButtonLabelPress(startButton)
	_wireButtonLabelPress(settingsButton)
	_wireButtonLabelPress(catButton)
	_wireButtonLabelPress(dogButton)
	_wireButtonLabelPress(confirmButton)
	_wireButtonLabelPress(backButton)
	_wireButtonLabelPress(settingsBackButton)
	_wireButtonLabelPress(deleteButton)
	_wireButtonLabelPress(quitButton)

	# Make sure the species buttons look active by default
	_setSpeciesButtonsBright()

	# Clear any stale error text
	errorLabel.text = ""


func _wireButtonLabelPress(btn: TextureButton) -> void:
	# Keep text aligned with the pressed button offset.
	var label = _findButtonLabel(btn)
	btn.button_down.connect(func() -> void: _offsetButtonLabel(btn, true))
	btn.button_up.connect(func() -> void: _offsetButtonLabel(btn, false))
	btn.mouse_exited.connect(func() -> void: _offsetButtonLabel(btn, false))


func _findButtonLabel(btn: TextureButton) -> Label:
	# Find the first label inside a button.
	for child in btn.get_children():
		if child is Label:
			return child
	return null


func _offsetButtonLabel(btn: TextureButton, pressed: bool) -> void:
	# Nudge the label to match the button press animation.
	var label = _findButtonLabel(btn)
	if pressed or not label.has_meta("base_offsets"):
		label.set_meta("base_offsets", {
			"left": label.offset_left,
			"top": label.offset_top,
			"right": label.offset_right,
			"bottom": label.offset_bottom
		})
	var baseOffsets = label.get_meta("base_offsets")
	var basePressOffset = 2 if btn == startButton or btn == settingsButton else 4
	var pressOffset = basePressOffset if pressed else 0
	label.offset_left = float(baseOffsets["left"])
	label.offset_right = float(baseOffsets["right"])
	label.offset_top = float(baseOffsets["top"]) + pressOffset
	label.offset_bottom = float(baseOffsets["bottom"]) + pressOffset



func _onStartPressed() -> void:
	# Start game or show pet creation if no save.
	# If a user save exists, load and go straight into the game.
	# Otherwise show the pet creation screen.
	var loaded = saveLoadManager.loadGame()
	if loaded and _hasValidPetData(saveLoadManager.playerData):
		_changeToGame()
		petManagerRef.setPlayerData(saveLoadManager.playerData)
		return
	_showPetSelect()


func _onSettingsPressed() -> void:
	# Open settings panel.
	settingsPanel.visible = true



func _showPetSelect() -> void:
	# Open pet selection UI and reset inputs.
	chosenSpecies = ""
	nameInput.text = ""
	errorLabel.text = ""
	petPanel.visible = true
	startPanel.visible = false
	# ensure both buttons render bright on open (deferred is safest)
	call_deferred("_setSpeciesButtonsBright")


func _selectSpecies(spec: String) -> void:
	# Pick a species and update button visuals.
	chosenSpecies = spec
	# selected stays bright, other dims slightly
	_applySelectButton(catButton, spec == "cat")
	_applySelectButton(dogButton, spec == "dog")


func _applySelectButton(btn: Control, selected: bool) -> void:
	# Simple visual feedback for selection.
	# simple visual feedback: selected = white, else dimmed
	btn.modulate = Color(1, 1, 1, 1) if selected else Color(0.6, 0.6, 0.6, 1)


func _onConfirmPressed() -> void:
	# Confirm pet choice and create save.
	var petName = nameInput.text.strip_edges()
	var nameError = _validatePetName(petName)
	if nameError != "":
		errorLabel.text = nameError
		return
	if chosenSpecies == "":
		errorLabel.text = "Please pick a species."
		return

	_createNewSave(chosenSpecies, petName)
	_changeToGame()
	petManagerRef.setPlayerData(saveLoadManager.playerData)


func _onBackPressed() -> void:
	# Back out of pet creation.
	startPanel.visible = true
	petPanel.visible = false



func _createNewSave(speciesChoice: String, petName: String) -> void:
	# Create a new save using defaults, then set the pet info.
	# SaveLoadManager is expected to exist as an autoload.
	# We keep this function short: ask saveLoadManager to load existing save (it already knows defaults),
	# then overwrite the fields we need and save.
	# Reset to defaults so old stats do not carry over into a new save
	saveLoadManager.resetData()

	# Set starting values for the new pet
	var pd = saveLoadManager.playerData
	pd["inventories"] = pd.get("inventories", {})
	pd["inventories"]["pets"] = pd["inventories"].get("pets", {})
	pd["name"] = petName
	pd["day"] = 0
	pd["species"] = speciesChoice

	# Sanitize and persist
	saveLoadManager.clampValues(pd)
	saveLoadManager.saveGame()


func _changeToGame() -> void:
	# Move from start screen to game UI.
	# hide start UI and show main UI; resume game timer
	startLayer.visible = false
	startPanel.visible = false
	petPanel.visible = false
	uiNode.visible = true
	gameManager.resumeGame()


func _userSaveExists() -> bool:
	# Return true if a user save exists.
	return FileAccess.file_exists("user://player_save.json")


func _onSettingsBackPressed() -> void:
	# Close settings panel.
	settingsPanel.visible = false


func _onDeletePressed() -> void:
	# Delete the user save file.
	saveLoadManager.deleteUserFile("player_save.json")
	settingsPanel.visible = false


func _onQuitPressed() -> void:
	# Quit the game from the settings menu.
	get_tree().quit()


func onStartScreenPressed() -> void:
	# Return to the start screen from in-game UI.
	startLayer.visible = true
	uiNode.visible = false
	startPanel.visible = true
	petPanel.visible = false
	gameManager.pauseGame()


func _setSpeciesButtonsBright() -> void:
	# Brighten both species buttons.
	catButton.modulate = Color(1, 1, 1, 1)
	dogButton.modulate = Color(1, 1, 1, 1)


func _resetSpeciesButtons() -> void:
	# Dim both species buttons.
	catButton.modulate = Color(0.6, 0.6, 0.6, 1)
	dogButton.modulate = Color(0.6, 0.6, 0.6, 1)


func _validatePetName(petName: String) -> String:
	# Enforce simple name rules for input validation.
	var trimmed = petName.strip_edges()
	if trimmed.length() < 2 or trimmed.length() > 12:
		return "Name must be 2-12 characters."
	var regex = RegEx.new()
	regex.compile("^[A-Za-z ]+$")
	if regex.search(trimmed) == null:
		return "Use letters and spaces only."
	return ""


func _hasValidPetData(pd: Dictionary) -> bool:
	# Require a real name and species before starting the game.
	var species = str(pd.get("species", "")).strip_edges()
	if species != "cat" and species != "dog":
		return false
	var name = str(pd.get("name", "")).strip_edges()
	return _validatePetName(name) == ""
