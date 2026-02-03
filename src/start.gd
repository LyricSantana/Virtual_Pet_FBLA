extends Control

var startButton
var settingsButton
var petPanel
var start_panel
var catButton
var dogButton
var nameInput
var confirmButton
var errorLabel
var backButton
var settingsPanel
var settingsBackButton
var deleteButton

var chosen_species: String = ""

func _ready() -> void:
	gameManager.pause_game()
	# get nodes safely (paths are relative to this scene root)
	startButton   = get_node_or_null("startPanel/VBoxContainer/startButton")
	settingsButton = get_node_or_null("startPanel/VBoxContainer/settingsButton")
	petPanel   = get_node_or_null("petSelectPanel")
	start_panel = get_node_or_null("startPanel")
	catButton     = get_node_or_null("petSelectPanel/VBoxContainer/HBoxContainer/catButton")
	dogButton     = get_node_or_null("petSelectPanel/VBoxContainer/HBoxContainer/dogButton")
	nameInput  = get_node_or_null("petSelectPanel/VBoxContainer/nameInput")
	confirmButton = get_node_or_null("petSelectPanel/VBoxContainer/confirmButton")
	errorLabel = get_node_or_null("petSelectPanel/VBoxContainer/errorLabel")
	backButton = get_node_or_null("petSelectPanel/VBoxContainer/backButton")
	settingsPanel = get_node_or_null("CanvasLayer/settingsPanel")
	settingsBackButton = get_node_or_null("CanvasLayer/settingsPanel/settingsPopup/VBoxContainer/backButton")
	deleteButton = get_node_or_null("CanvasLayer/settingsPanel/settingsPopup/VBoxContainer/deleteButton")

	settingsPanel.visible = false

	# connect signals only if the nodes actually exist
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
	if errorLabel:
		errorLabel.text = ""
	if backButton:
		backButton.pressed.connect(_on_back_pressed)
	if settingsBackButton:
		settingsBackButton.pressed.connect(_on_settings_back_pressed)
	if deleteButton:
		deleteButton.pressed.connect(_on_delete_pressed)

	start_panel.visible = true
	petPanel.visible = true

func _on_start_pressed() -> void:
	if user_save_exists():
		saveLoadManager.loadGame()
		_change_to_game()
	else:
		_show_pet_select()


# TODO: add settings
func _on_settings_pressed() -> void:
	if settingsPanel.visible:
		settingsPanel.visible = false
	else:
		settingsPanel.visible = true
	return

func _show_pet_select() -> void:
	chosen_species = ""
	if nameInput:
		nameInput.text = ""
	if errorLabel:
		errorLabel.text = ""
	if petPanel:
		petPanel.visible = true
	start_panel.visible = false

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
	var pet_name := ""
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

func _on_back_pressed() -> void:
	start_panel.visible = true

func _create_new_save(species: String, pet_name: String) -> void:
	# start from defaults and apply choices
	saveLoadManager.resetData()
	saveLoadManager.playerData["current_pet"] = species
	saveLoadManager.playerData["name"] = pet_name
	saveLoadManager.playerData["day"] = 0
	saveLoadManager.clampValues(saveLoadManager.playerData)
	saveLoadManager.saveGame()


func _change_to_game() -> void:
	_show_pet_select()
	petPanel.visible = false
	gameManager.resume_game()

func user_save_exists() -> bool:
	return FileAccess.file_exists("user://player_save.json")

func _on_settings_back_pressed():
	settingsPanel.visible = false

func _on_delete_pressed():
	saveLoadManager.delete_user_file("player_save.json")
