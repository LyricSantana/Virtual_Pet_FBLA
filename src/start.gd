extends Control

var startButton
var settingsButton
var petPanel
var startPanel
var catButton
var dogButton
var nameInput
var confirmButton
var errorLabel
var backButton
var settingsPanel
var settingsBackButton
var deleteButton
var settingsCanvas

var chosen_species: String = ""

func _ready() -> void:
	gameManager.pause_game()

	startButton   = get_node_or_null("startPanel/VBoxContainer/startButton")
	settingsButton = get_node_or_null("startPanel/VBoxContainer/settingsButton")
	startPanel = get_node_or_null("startPanel")
	petPanel   = get_node_or_null("petSelectPanel")
	catButton     = get_node_or_null("petSelectPanel/VBoxContainer/HBoxContainer/catButton")
	dogButton     = get_node_or_null("petSelectPanel/VBoxContainer/HBoxContainer/dogButton")
	nameInput  = get_node_or_null("petSelectPanel/VBoxContainer/nameInput")
	confirmButton = get_node_or_null("petSelectPanel/VBoxContainer/confirmButton")
	errorLabel = get_node_or_null("petSelectPanel/VBoxContainer/errorLabel")
	backButton = get_node_or_null("petSelectPanel/VBoxContainer/backButton")
	settingsPanel = get_node_or_null("CanvasLayer/settingsPanel")
	settingsBackButton = get_node_or_null("CanvasLayer/settingsPanel/settingsPopup/VBoxContainer/backButton")
	deleteButton = get_node_or_null("CanvasLayer/settingsPanel/settingsPopup/VBoxContainer/deleteButton")
	settingsCanvas = get_node_or_null("CanvasLayer")

	# Correct initial visibility
	if settingsPanel:
		settingsPanel.visible = false
	if petPanel:
		petPanel.visible = false  # hide pet selection initially
	if startPanel:
		startPanel.visible = true  # show start screen
	if settingsCanvas:
		settingsCanvas.visible = true

	# connect button signals...
	if startButton:
		startButton.pressed.connect(_on_start_pressed)
	if settingsButton:
		settingsButton.pressed.connect(_on_settings_pressed)
	if catButton:
		catButton.pressed.connect(_on_cat_pressed)
	if dogButton:
		dogButton.pressed.connect(_on_dog_pressed)
	if confirmButton:
		confirmButton.pressed.connect(_on_confirm_pressed)
	if backButton:
		backButton.pressed.connect(_on_back_pressed)
	if settingsBackButton:
		settingsBackButton.pressed.connect(_on_settings_back_pressed)
	if deleteButton:
		deleteButton.pressed.connect(_on_delete_pressed)

	if errorLabel:
		errorLabel.text = ""

func _on_start_pressed() -> void:
	if user_save_exists():
		saveLoadManager.loadGame()
		var cur_pet_id: String = str(saveLoadManager.playerData.get("current_pet", ""))
		if cur_pet_id != "":
			# first, tell PetManager to load the pet node
			petManager.set_current_pet(cur_pet_id)
		_change_to_game()
		petManager.play_pet_animation(saveLoadManager.playerData["species"])
	else:
		_show_pet_select()

func _on_settings_pressed() -> void:
	if settingsPanel:
		settingsPanel.visible = not settingsPanel.visible

func _show_pet_select() -> void:
	chosen_species = ""
	if nameInput:
		nameInput.text = ""
	if errorLabel:
		errorLabel.text = ""
	if petPanel:
		petPanel.visible = true
	if startPanel:
		startPanel.visible = false

func _on_cat_pressed() -> void:
	chosen_species = "cat"
	_highlight_choice(catButton, dogButton)

func _on_dog_pressed() -> void:
	chosen_species = "dog"
	_highlight_choice(dogButton, catButton)

func _highlight_choice(selected: TextureButton, other: TextureButton) -> void:
	if selected:
		selected.modulate = Color(1,1,1)
	if other:
		other.modulate = Color(0.6,0.6,0.6)

func _on_confirm_pressed() -> void:
	var pet_name: String = ""
	if nameInput:
		pet_name = nameInput.text.strip_edges()

	if pet_name == "":
		if errorLabel:
			errorLabel.text = "Please enter a name."
		return
	if chosen_species == "":
		if errorLabel:
			errorLabel.text = "Please pick a species."
		return
	_create_new_save(chosen_species, pet_name)
	_change_to_game()
	if user_save_exists():
		petManager.play_pet_animation(saveLoadManager.playerData["species"])


func _on_back_pressed() -> void:
	if startPanel:
		startPanel.visible = true
	if petPanel:
		petPanel.visible = false

func _create_new_save(species_choice: String, pet_name: String) -> void:
	var defaults = saveLoadManager.loadJSON("res://src/defaultSave.json")
	var user_from_disk = saveLoadManager.loadJSON("user://player_save.json")
	saveLoadManager.playerData = saveLoadManager.mergeDicts(defaults, user_from_disk)

	saveLoadManager.playerData["inventories"] = saveLoadManager.playerData.get("inventories", {})
	saveLoadManager.playerData["inventories"]["pets"] = saveLoadManager.playerData["inventories"].get("pets", {})
	saveLoadManager.playerData["name"] = pet_name
	saveLoadManager.playerData["day"] = 0
	saveLoadManager.playerData["species"] = species_choice

	saveLoadManager.clampValues(saveLoadManager.playerData)
	saveLoadManager.saveGame()


func _change_to_game() -> void:
	if petPanel:
		petPanel.visible = false
	if startPanel:
		startPanel.visible = false
	gameManager.resume_game()

func user_save_exists() -> bool:
	return FileAccess.file_exists("user://player_save.json")

func _on_settings_back_pressed() -> void:
	if settingsPanel:
		settingsPanel.visible = false

func _on_delete_pressed() -> void:
	saveLoadManager.delete_user_file("player_save.json")
