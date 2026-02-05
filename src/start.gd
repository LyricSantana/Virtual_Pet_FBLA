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
var settingsCanvas
var pm

# --- Shortcut to safely get nodes ---
func n(path: String) -> Node:
	return get_node_or_null(path)

func _ready() -> void:
	gameManager.pause_game()

	# --- Cache petManager safely ---
	if typeof(petManager) != TYPE_NIL:
		pm = petManager
	else:
		pm = get_tree().get_root().get_node_or_null("Main/pet/petAnimated")

	# --- Cache UI nodes ---
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
	settingsCanvas     = n("CanvasLayer")

	# --- Initial visibility ---
	if settingsPanel: settingsPanel.visible = false
	if petPanel: petPanel.visible = false
	if startPanel: startPanel.visible = true
	if settingsCanvas: settingsCanvas.visible = true

	# --- Connect button signals ---
	if startButton: startButton.pressed.connect(_on_start_pressed)
	if settingsButton: settingsButton.pressed.connect(_on_settings_pressed)
	if catButton: catButton.pressed.connect(_on_cat_pressed)
	if dogButton: dogButton.pressed.connect(_on_dog_pressed)
	if confirmButton: confirmButton.pressed.connect(_on_confirm_pressed)
	if backButton: backButton.pressed.connect(_on_back_pressed)
	if settingsBackButton: settingsBackButton.pressed.connect(_on_settings_back_pressed)
	if deleteButton: deleteButton.pressed.connect(_on_delete_pressed)

	if errorLabel: errorLabel.text = ""


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
		settingsPanel.visible = not settingsPanel.visible

func _show_pet_select() -> void:
	chosen_species = ""
	if nameInput: nameInput.text = ""
	if errorLabel: errorLabel.text = ""
	if petPanel: petPanel.visible = true
	if startPanel: startPanel.visible = false

func _on_cat_pressed() -> void:
	_select_species("cat")

func _on_dog_pressed() -> void:
	_select_species("dog")

func _select_species(spec: String) -> void:
	chosen_species = spec
	if catButton: catButton.modulate = Color(1,1,1) if spec == "cat" else Color(0.6,0.6,0.6)
	if dogButton: dogButton.modulate = Color(1,1,1) if spec == "dog" else Color(0.6,0.6,0.6)

func _on_confirm_pressed() -> void:
	var pet_name = nameInput.text.strip_edges() if nameInput else ""
	if pet_name == "":
		if errorLabel: errorLabel.text = "Please enter a name."
		return
	if chosen_species == "":
		if errorLabel: errorLabel.text = "Please pick a species."
		return

	_create_new_save(chosen_species, pet_name)
	_change_to_game()

	if pm and pm.has_method("set_player_data"):
		pm.set_player_data(saveLoadManager.playerData)


func _on_back_pressed() -> void:
	if startPanel: startPanel.visible = true
	if petPanel: petPanel.visible = false


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

func _change_to_game() -> void:
	if petPanel: petPanel.visible = false
	if startPanel: startPanel.visible = false
	gameManager.resume_game()

func user_save_exists() -> bool:
	return FileAccess.file_exists("user://player_save.json")

func _on_settings_back_pressed() -> void:
	if settingsPanel: settingsPanel.visible = false

func _on_delete_pressed() -> void:
	saveLoadManager.delete_user_file("player_save.json")
