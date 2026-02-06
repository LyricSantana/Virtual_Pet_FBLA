# start.gd — cleaned and simplified
# Lean, readable, and documented like a competent HS dev who actually ships things.

extends Control

# -------------------------
# Local state
# -------------------------
var chosen_species: String = ""      # "cat" or "dog" or empty if none selected

# -------------------------
# Node references (onready for scene binding)
# -------------------------
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

# references to autoloads or scene nodes (resolved at runtime)
var pm               # petManager (prefer autoload)
var ui_node
var start_layer

# -------------------------
# Minimal safety check helper
# -------------------------
func _ensure_manager(name: String) -> bool:
	if typeof(get_node("/root").has_node) == TYPE_NIL:
		# very defensive fallback (shouldn't happen)
		return false
	return true


# -------------------------
# Startup
# -------------------------
func _ready() -> void:
	# Cache some common nodes
	start_layer = get_parent()
	ui_node = get_tree().get_root().get_node_or_null("Main/UI")

	# Prefer autoload petManager; if not registered, try scene path
	if typeof(petManager) != TYPE_NIL:
		pm = petManager
	else:
		pm = get_tree().get_root().get_node_or_null("Main/pet")

	# Hide in-game UI while on start
	if ui_node:
		ui_node.visible = false

	# Start screen default visibility
	startPanel.visible = true
	petPanel.visible = false
	settingsPanel.visible = false

	# Connect important buttons (assume nodes exist in scene structure)
	startButton.pressed.connect(_on_start_pressed)
	settingsButton.pressed.connect(_on_settings_pressed)
	catButton.pressed.connect(func() -> void: _select_species("cat"))
	dogButton.pressed.connect(func() -> void: _select_species("dog"))
	confirmButton.pressed.connect(_on_confirm_pressed)
	backButton.pressed.connect(_on_back_pressed)
	settingsBackButton.pressed.connect(_on_settings_back_pressed)
	deleteButton.pressed.connect(_on_delete_pressed)

	# Make sure the species buttons look active by default
	_set_species_buttons_bright()

	# Clear any stale error text
	errorLabel.text = ""


# -------------------------
# Start / settings
# -------------------------
func _on_start_pressed() -> void:
	# If a user save exists, load and go straight into the game.
	# Otherwise show the pet creation screen.
	if FileAccess.file_exists("user://player_save.json"):
		if typeof(saveLoadManager) != TYPE_NIL and saveLoadManager.has_method("loadGame"):
			saveLoadManager.loadGame()
		_change_to_game()
		if pm and pm.has_method("set_player_data"):
			pm.set_player_data(saveLoadManager.playerData)
	else:
		_show_pet_select()


func _on_settings_pressed() -> void:
	settingsPanel.visible = true


# -------------------------
# Pet creation UI
# -------------------------
func _show_pet_select() -> void:
	chosen_species = ""
	nameInput.text = ""
	errorLabel.text = ""
	petPanel.visible = true
	startPanel.visible = false
	# ensure both buttons render bright on open (deferred is safest)
	call_deferred("_set_species_buttons_bright")


func _select_species(spec: String) -> void:
	chosen_species = spec
	# selected stays bright, other dims slightly
	_apply_select_button(catButton, spec == "cat")
	_apply_select_button(dogButton, spec == "dog")


func _apply_select_button(btn: Control, selected: bool) -> void:
	# simple visual feedback: selected = white, else dimmed
	btn.modulate = Color(1, 1, 1, 1) if selected else Color(0.6, 0.6, 0.6, 1)


func _on_confirm_pressed() -> void:
	var pet_name = nameInput.text.strip_edges()
	if pet_name == "":
		errorLabel.text = "Please enter a name."
		return
	if chosen_species == "":
		errorLabel.text = "Please pick a species."
		return

	_create_new_save(chosen_species, pet_name)
	_change_to_game()
	if pm and pm.has_method("set_player_data"):
		pm.set_player_data(saveLoadManager.playerData)


func _on_back_pressed() -> void:
	startPanel.visible = true
	petPanel.visible = false


# -------------------------
# Save / creation logic (compact)
# -------------------------
func _create_new_save(species_choice: String, pet_name: String) -> void:
	# SaveLoadManager is expected to exist as an autoload.
	# We keep this function short: ask saveLoadManager to load existing save (it already knows defaults),
	# then overwrite the fields we need and save.
	if typeof(saveLoadManager) == TYPE_NIL:
		push_error("saveLoadManager autoload missing — cannot create new save.")
		return

	# Ensure defaults are loaded and any user save merged
	# (loadGame is idempotent and will create a new user save from defaults if none exists)
	saveLoadManager.loadGame()

	# Set starting values for the new pet
	var pd = saveLoadManager.playerData
	pd["inventories"] = pd.get("inventories", {})
	pd["inventories"]["pets"] = pd["inventories"].get("pets", {})
	pd["name"] = pet_name
	pd["day"] = 0
	pd["species"] = species_choice

	# Sanitize and persist
	saveLoadManager.clampValues(pd)
	saveLoadManager.saveGame()


# -------------------------
# Scene transition
# -------------------------
func _change_to_game() -> void:
	# hide start UI and show main UI; resume game timer
	if start_layer:
		start_layer.visible = false
	startPanel.visible = false
	petPanel.visible = false
	if ui_node:
		ui_node.visible = true
	if typeof(gameManager) != TYPE_NIL:
		gameManager.resume_game()


# -------------------------
# Small helpers
# -------------------------
func _user_save_exists() -> bool:
	return FileAccess.file_exists("user://player_save.json")


func _on_settings_back_pressed() -> void:
	settingsPanel.visible = false


func _on_delete_pressed() -> void:
	# remove user save if present
	if FileAccess.file_exists("user://player_save.json"):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("player_save.json")


# Called by in-game UI to return to start screen
func onStartScreenPressed() -> void:
	if start_layer:
		start_layer.visible = true
	if ui_node:
		ui_node.visible = false
	startPanel.visible = true
	petPanel.visible = false
	if typeof(gameManager) != TYPE_NIL:
		gameManager.pause_game()


# -------------------------
# Visual helpers
# -------------------------
func _set_species_buttons_bright() -> void:
	catButton.modulate = Color(1, 1, 1, 1)
	dogButton.modulate = Color(1, 1, 1, 1)


func _reset_species_buttons() -> void:
	catButton.modulate = Color(0.6, 0.6, 0.6, 1)
	dogButton.modulate = Color(0.6, 0.6, 0.6, 1)
