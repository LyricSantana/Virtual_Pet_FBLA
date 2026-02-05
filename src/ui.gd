extends Control

# ==========================
# UI NODES
# ==========================
var popupPanel
var changeNameButton
var changeName
var errorLabel 
var changeNameInput
var settingsPopup
var startScreenButton  # "Return to Start Screen" button

var inventoryPanel
var inv_close_button
var inv_list
var current_inventory_name: String = "feed"

const ITEM_THEME_PATH := "res://assets/themes/inventory_theme.tres"
var item_theme: Theme = null


func _ready() -> void:
	popupPanel = get_node_or_null("popupPanel")
	changeNameButton = get_node_or_null("labels/nameBox/changeNameButton")
	changeName = get_node_or_null("popupPanel/changeName")
	errorLabel = get_node_or_null("popupPanel/changeName/errorLabel")
	changeNameInput = get_node_or_null("popupPanel/changeName/changeNameInput")
	settingsPopup = get_node_or_null("popupPanel/settingsPopup")

	if settingsPopup:
		startScreenButton = settingsPopup.get_node_or_null("startScreenButton")
		if startScreenButton:
			startScreenButton.pressed.connect(startScreen.onStartScreenPressed)

	inventoryPanel = get_node_or_null("popupPanel/inventoryPanel")
	inv_close_button = get_node_or_null("popupPanel/inventoryPanel/VBoxContainer/invCloseButton")
	inv_list = get_node_or_null("popupPanel/inventoryPanel/VBoxContainer/ScrollContainer/invList")

	if popupPanel:
		popupPanel.visible = false
	if changeName:
		changeName.visible = false
	if inventoryPanel:
		inventoryPanel.visible = false
	if settingsPopup:
		settingsPopup.visible = false

	if inv_close_button:
		inv_close_button.pressed.connect(_on_inv_close_pressed)

	_connect_buttons(self)

	updateValues()

	if FileAccess.file_exists(ITEM_THEME_PATH):
		item_theme = load(ITEM_THEME_PATH)



func updateValues() -> void:
	var playerData = saveLoadManager.playerData
	var stats = playerData.get("stats", {})

	for stat_name in stats.keys():
		var bar = $statsPanel.get_node_or_null(stat_name + "Bar")
		if bar and bar is TextureProgressBar:
			bar.value = int(stats[stat_name])

	$labels/dayLabel.text = "Days: " + str(int(playerData.get("day", 0)))
	$labels/moneyLabel.text = "Money: $" + str(int(playerData.get("money", 0)))
	$labels/nameBox/nameLabel.text = "Name: " + str(playerData.get("name", "Pet"))



func _connect_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is TextureButton:
			child.pressed.connect(on_button_pressed.bind(child))
		_connect_buttons(child)

func _process(delta: float) -> void:
	updateValues()

func on_button_pressed(button: TextureButton) -> void:
	match button.name:
		"feedButton": feedPressed()
		"playButton": playPressed()
		"restButton": restPressed()
		"vetButton": vetPressed()
		"cleanButton": cleanPressed()
		"shopButton": shopPressed()
		"settingsButton": settingsPressed()
		"backButton": backPressed()
		"changeNameButton": changeNamePressed()
		"submitNameButton": changePetName()
		"quitButton": quitPressed()
		"startScreenButton": goToStartPressed()



func showPopup():
	if popupPanel:
		popupPanel.visible = true

func settingsPressed() -> void:
	showPopup()
	gameManager.pause_game()
	if settingsPopup:
		settingsPopup.visible = true
	if petManager and petManager.has_method("set_thought_visible"):
		petManager.set_thought_visible(false)

func backPressed() -> void:
	if popupPanel:
		popupPanel.visible = false
	if changeName:
		changeName.visible = false
	if inventoryPanel:
		inventoryPanel.visible = false
	if settingsPopup:
		settingsPopup.visible = false
	
	gameManager.resume_game()
	if petManager and petManager.has_method("set_thought_visible"):
		petManager.set_thought_visible(true)

func changeNamePressed():
	showPopup()
	if changeName:
		changeName.visible = true
	gameManager.pause_game()

func changePetName():
	var pet_name := ""
	if changeNameInput:
		pet_name = changeNameInput.text.strip_edges()

	if pet_name == "":
		if errorLabel:
			errorLabel.text = "Please enter a name."
		return

	saveLoadManager.playerData["name"] = pet_name
	saveLoadManager.saveGame()

	if changeNameInput:
		changeNameInput.text = ""
	if changeName:
		changeName.visible = false
	if popupPanel:
		popupPanel.visible = false
	gameManager.resume_game()



func feedPressed() -> void:
	open_inventory("feed")  

func playPressed() -> void:
	open_inventory("play")  

func restPressed() -> void:
	open_inventory("rest")  

func vetPressed() -> void:
	open_inventory("vet") 

func cleanPressed() -> void:
	open_inventory("clean")  

func shopPressed() -> void:
	gameManager.allMax()


# ==========================
# QUIT / START
# ==========================
func quitPressed() -> void:
	saveLoadManager.saveGame()
	get_tree().quit()

func goToStartPressed() -> void:
	saveLoadManager.saveGame()
	if popupPanel:
		popupPanel.visible = false
	if changeName:
		changeName.visible = false
	startScreen.onStartScreenPressed()


# ==========================
# INVENTORY FUNCTIONS
# ==========================
func open_inventory(inv_name: String = "feed") -> void:
	current_inventory_name = inv_name
	if popupPanel:
		popupPanel.visible = true
	if inventoryPanel:
		inventoryPanel.visible = true
	_populate_inventory_list()
	gameManager.pause_game()
	if petManager and petManager.has_method("set_thought_visible"):
		petManager.set_thought_visible(false)

func _on_inv_close_pressed() -> void:
	if inventoryPanel:
		inventoryPanel.visible = false
	if popupPanel:
		popupPanel.visible = false
	gameManager.resume_game()
	if petManager and petManager.has_method("set_thought_visible"):
		petManager.set_thought_visible(true)


func _populate_inventory_list() -> void:
	if inv_list == null:
		return
	# Clear old rows
	for child in inv_list.get_children():
		child.queue_free()

	# Get inventory dictionary
	var inv = inventoryManager.getInventory(current_inventory_name)

	if inv.size() == 0:
		var label = Label.new()
		label.text = "Empty"

		var font = load("res://assets/fonts/pixelFont.ttf")
		var label_theme := Theme.new()
		label_theme.set_font("font", "Label", font)
		label.theme = label_theme

		inv_list.add_child(label)
		return


	# Populate items
	for item_id in inv.keys():
		var raw = inv[item_id]
		var item_def = itemDB.get_item(item_id)

		var item_data: Dictionary
		if typeof(raw) == TYPE_DICTIONARY:
			item_data = raw
		else:
			# If it's just a number, convert to dictionary
			item_data = {
				"count": int(raw),
				"uses": item_def.get("uses", 1)
			}

		_create_inventory_row(item_id, item_data)


func _create_inventory_row(item_id: String, item_data: Dictionary) -> void:
	if inv_list == null:
		return

	var h = HBoxContainer.new()
	h.name = "row_" + item_id

	var item_def = itemDB.get_item(item_id)
	var display_name = item_def.get("name", item_id)
	var uses_left = item_data.get("uses", item_def.get("uses", 1))
	var count = item_data.get("count", 1)
	var restore_stats: Dictionary = item_def.get("restore", {})

	# Build stats text
	var stats_text = ""
	for stat_name in restore_stats.keys():
		stats_text += "%s +%d  " % [stat_name.capitalize(), int(restore_stats[stat_name])]

	# --- Load font once ---
	var font = load("res://assets/fonts/pixelFont.ttf")  # your TTF file

	# --- Create Label theme ---
	var label_theme := Theme.new()
	label_theme.set_font("font", "Label", font)

	# Name label
	var name_label = Label.new()
	name_label.text = "%s (x%d, uses left: %d)  %s" % [display_name, count, uses_left, stats_text]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.theme = label_theme  # apply font
	h.add_child(name_label)

	# --- Create Button theme ---
	var button_theme := Theme.new()
	button_theme.set_font("font", "Button", font)

	# Use button
	var use_btn = Button.new()
	use_btn.text = "Use"
	use_btn.theme = button_theme
	use_btn.pressed.connect(func() -> void:
		_on_use_item(item_id)
	)
	h.add_child(use_btn)

	# Drop button
	var drop_btn = Button.new()
	drop_btn.text = "Drop"
	drop_btn.theme = button_theme
	drop_btn.pressed.connect(func() -> void:
		_on_drop_item(item_id)
	)
	h.add_child(drop_btn)

	inv_list.add_child(h)


func _on_use_item(item_id: String) -> void:
	var inv_name = current_inventory_name
	var inv = saveLoadManager.playerData["inventories"].get(inv_name, {})
	if not inv.has(item_id):
		return

	var item_data = inv[item_id]
	var item_def = itemDB.get_item(item_id)

	# normalize
	if typeof(item_data) != TYPE_DICTIONARY:
		item_data = {"count": int(item_data), "uses": item_def.get("uses", 1)}
		inv[item_id] = item_data

	# apply effects (use "restore" as key)
	for stat in item_def.get("restore", {}):
		var change = int(item_def["restore"][stat])
		var old = int(saveLoadManager.playerData["stats"].get(stat, 0))
		saveLoadManager.playerData["stats"][stat] = clamp(old + change, 0, 100)

	# reduce uses
	item_data["uses"] -= 1
	if item_data["uses"] <= 0:
		item_data["count"] -= 1
		if item_data["count"] > 0:
			item_data["uses"] = item_def.get("uses", 1)
		else:
			inv.erase(item_id)  # remove completely

	# save directly to user save
	saveLoadManager.playerData["inventories"][inv_name] = inv
	saveLoadManager.saveGame()
	open_inventory(inv_name)

func _on_drop_item(item_id: String) -> void:
	var inv_name = current_inventory_name
	inventoryManager.removeItem(inv_name, item_id)
	_populate_inventory_list()
