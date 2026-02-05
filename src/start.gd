extends Control

var chosen_species: String = ""

# --- Cached nodes ---
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
var pm

# --- Scene roots / helpers ---
var start_layer         # CanvasLayer in Main.tscn that contains this start instance
var main_node
var ui_node

# --- Shortcut to safely get nodes ---
func n(path: String) -> Node:
	return get_node_or_null(path)


func _ready() -> void:
	# pause while on start screen
	gameManager.pause_game()

	# cache Main and UI
	main_node = get_tree().get_root().get_node_or_null("Main")
	if main_node:
		ui_node = main_node.get_node_or_null("UI")

	# start_layer should be this node's parent in Main.tscn
	start_layer = get_parent()

	# petManager (autoload or node)
	if typeof(petManager) != TYPE_NIL:
		pm = petManager
	else:
		if main_node:
			pm = main_node.get_node_or_null("pet/petAnimated")

	# --- Cache UI nodes local to this start scene ---
	startButton        = n("startPanel/VBoxContainer/startButton")
	settingsButton     = n("startPanel/VBoxContainer/settingsButton")
	startPanel         = n("startPanel")
	petPanel           = n("petSelectPanel")
	catButton          = n("petSelectPanel/VBoxContainer/HBoxContainer/catButton")
	dogButton          = n("petSelectPanel/VBoxContainer/HBoxContainer/dogButton")
	nameInput          = n("petSelectPanel/VBoxContainer/nameInput")
	confirmButton      = n("petSelectPanel/VBoxContainer/confirmButton")
	errorLabel         = n("petSelectPanel/VBoxContainer/errorLabel")
	backButton         = n("petSelectPanel/VBoxContainer/backButton")
	settingsPanel      = n("CanvasLayer/settingsPanel")
	settingsBackButton = n("CanvasLayer/settingsPanel/settingsPopup/VBoxContainer/backButton")
	deleteButton       = n("CanvasLayer/settingsPanel/settingsPopup/VBoxContainer/deleteButton")

	# If any of those panels were created as top-level in the scene,
	# force them to be non-top-level so they follow start_layer visibility.
	if startPanel:
		startPanel.set_as_top_level(false)
	if petPanel:
		petPanel.set_as_top_level(false)

	# --- Initial visibility ---
	# ensure start layer is visible and in-game UI hidden
	if start_layer:
		start_layer.visible = true
	if startPanel:
		startPanel.visible = true
	if petPanel:
		petPanel.visible = false
	if ui_node:
		ui_node.visible = false
	# hide local settings popup by default
	if settingsPanel:
		settingsPanel.visible = false

	# --- Connect button signals safely ---
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


# --- Button callbacks ---
func _on_start_pressed() -> void:
	if user_save_exists():
		saveLoadManager.loadGame()
		_change_to_game()
		if pm and pm.has_method("set_player_data"):
			pm.set_player_data(saveLoadManager.playerData)
	else:
		_show_pet_select()


func _on_settings_pressed() -> void:
	if settingsPanel:
		settingsPanel.visible = true


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
	_select_species("cat")


func _on_dog_pressed() -> void:
	_select_species("dog")


func _select_species(spec: String) -> void:
	chosen_species = spec
	if catButton:
		catButton.modulate = Color(1, 1, 1) if spec == "cat" else Color(0.6, 0.6, 0.6)
	if dogButton:
		dogButton.modulate = Color(1, 1, 1) if spec == "dog" else Color(0.6, 0.6, 0.6)


func _on_confirm_pressed() -> void:
	var pet_name = nameInput.text.strip_edges() if nameInput else ""
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

	if pm and pm.has_method("set_player_data"):
		pm.set_player_data(saveLoadManager.playerData)


func _on_back_pressed() -> void:
	if startPanel:
		startPanel.visible = true
	if petPanel:
		petPanel.visible = false


# --- Save logic ---
func _create_new_save(species_choice: String, pet_name: String) -> void:
	var defaults = saveLoadManager.loadJSON("res://src/defaultSave.json")
	var user_data = saveLoadManager.loadJSON("user://player_save.json")
	saveLoadManager.playerData = saveLoadManager.mergeDicts(defaults, user_data)

	var pd = saveLoadManager.playerData
	pd["inventories"] = pd.get("inventories", {})
	pd["inventories"]["pets"] = pd["inventories"].get("pets", {})
	pd["name"] = pet_name
	pd["day"] = 0
	pd["species"] = species_choice

	saveLoadManager.clampValues(pd)
	saveLoadManager.saveGame()


# --- Switch from start screen into game ---
func _change_to_game() -> void:
	# hide the whole start layer so nothing from start remains visible
	if start_layer:
		start_layer.visible = false
	else:
		# fallback if parent isn't the CanvasLayer
		if startPanel:
			startPanel.hide()
		if petPanel:
			petPanel.hide()

	# ensure the panels are not top-level and explicitly hide them
	if startPanel:
		startPanel.set_as_top_level(false)
		startPanel.hide()
	if petPanel:
		petPanel.set_as_top_level(false)
		petPanel.hide()

	# show in-game UI
	if ui_node:
		ui_node.visible = true

	# resume the game
	gameManager.resume_game()


func user_save_exists() -> bool:
	return FileAccess.file_exists("user://player_save.json")


func _on_settings_back_pressed() -> void:
	if settingsPanel:
		settingsPanel.visible = false


func _on_delete_pressed() -> void:
	saveLoadManager.delete_user_file("player_save.json")


# --- Return to Start Screen (call this from UI) ---
func onStartScreenPressed() -> void:
	# show start layer and panels
	if start_layer:
		start_layer.visible = true
	else:
		visible = true

	if startPanel:
		startPanel.set_as_top_level(false)
		startPanel.visible = true
	if petPanel:
		petPanel.set_as_top_level(false)
		petPanel.visible = false

	# hide in-game UI
	if ui_node:
		ui_node.visible = false

	# pause while on start screen
	gameManager.pause_game()
