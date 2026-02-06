# ui.gd — cleaned and Godot 4 compatible
# UI controller for the in-game HUD and popups.
# Clear, explicit, and free of ternary operators.

extends Control

# -------------------------
# Node bindings (scene paths)
# -------------------------
@onready var popupPanel = $popupPanel
@onready var changeNameButton = $labels/nameBox/changeNameButton
@onready var changeName = $popupPanel/changeName
@onready var errorLabel = $popupPanel/changeName/errorLabel
@onready var changeNameInput = $popupPanel/changeName/changeNameInput
@onready var settingsPopup = $popupPanel/settingsPopup
@onready var startScreenButton = $popupPanel/settingsPopup/startScreenButton

@onready var inventoryPanel = $popupPanel/inventoryPanel
@onready var inv_close_button = $popupPanel/inventoryPanel/VBoxContainer/invCloseButton
@onready var inv_list = $popupPanel/inventoryPanel/VBoxContainer/ScrollContainer/invList
var current_inventory_name: String = "feed"

const ITEM_THEME_PATH: String = "res://assets/themes/inventory_theme.tres"
var item_theme: Theme = null

# Autoload / scene managers (resolved once at ready)
var gm               # gameManager
var slm              # saveLoadManager
var inv_manager      # inventoryManager
var item_db          # itemDB
var pet_manager      # petManager
var start_scene      # start scene node reference (optional)

# -------------------------
# Startup
# -------------------------
func _ready() -> void:
	# resolve common managers — prefer autoloads, fallback to scene nodes
	if typeof(gameManager) != TYPE_NIL:
		gm = gameManager
	else:
		gm = get_tree().get_root().get_node_or_null("Main/gameManager")

	if typeof(saveLoadManager) != TYPE_NIL:
		slm = saveLoadManager
	else:
		slm = get_tree().get_root().get_node_or_null("Main/saveLoadManager")

	if typeof(inventoryManager) != TYPE_NIL:
		inv_manager = inventoryManager
	else:
		inv_manager = get_tree().get_root().get_node_or_null("Main/inventoryManager")

	if typeof(itemDB) != TYPE_NIL:
		item_db = itemDB
	else:
		item_db = get_tree().get_root().get_node_or_null("Main/itemDB")

	if typeof(petManager) != TYPE_NIL:
		pet_manager = petManager
	else:
		pet_manager = get_tree().get_root().get_node_or_null("Main/pet")

	start_scene = get_tree().get_root().get_node_or_null("Main/start")
	if start_scene == null:
		start_scene = get_tree().get_root().get_node_or_null("Main/startLayer/start")

	# initial visibility (explicit)
	if popupPanel != null:
		popupPanel.visible = false
	if changeName != null:
		changeName.visible = false
	if inventoryPanel != null:
		inventoryPanel.visible = false
	if settingsPopup != null:
		settingsPopup.visible = false

	# connect UI buttons safely
	if inv_close_button != null:
		inv_close_button.pressed.connect(_on_inv_close_pressed)
	if startScreenButton != null:
		startScreenButton.pressed.connect(_on_start_screen_pressed)

	# connect every TextureButton under this Control to a single handler recursively
	_connect_buttons(self)

	# initial populate
	updateValues()

	# optional theme
	if FileAccess.file_exists(ITEM_THEME_PATH):
		item_theme = load(ITEM_THEME_PATH)


# -------------------------
# Connect buttons recursively
# -------------------------
func _connect_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is TextureButton:
			# bind(child) will pass the button node into on_button_pressed when called
			child.pressed.connect(on_button_pressed.bind(child))
		# recurse into children regardless of type (safe)
		_connect_buttons(child)


# -------------------------
# Update UI values
# -------------------------
func _process(delta: float) -> void:
	updateValues()


func updateValues() -> void:
	# Need saveLoadManager to read playerData
	if slm == null:
		return

	var playerData: Dictionary = slm.playerData
	var stats: Dictionary = playerData.get("stats", {})

	for stat_name in stats.keys():
		var bar = $statsPanel.get_node_or_null(stat_name + "Bar")
		if bar != null and bar is TextureProgressBar:
			bar.value = int(stats[stat_name])

	var day_node = $labels.get_node_or_null("dayLabel")
	if day_node != null:
		day_node.text = "Days: " + str(int(playerData.get("day", 0)))

	var money_node = $labels.get_node_or_null("moneyLabel")
	if money_node != null:
		money_node.text = "Money: $" + str(int(playerData.get("money", 0)))

	var name_node = $labels.get_node_or_null("nameBox/nameLabel")
	if name_node != null:
		name_node.text = "Name: " + str(playerData.get("name", "Pet"))


# -------------------------
# Unified button handler
# -------------------------
func on_button_pressed(button: TextureButton) -> void:
	var name = button.name
	match name:
		"feedButton":
			open_inventory("feed")
		"playButton":
			open_inventory("play")
		"restButton":
			open_inventory("rest")
		"vetButton":
			open_inventory("vet")
		"cleanButton":
			open_inventory("clean")
		"shopButton":
			_on_shop_pressed()
		"settingsButton":
			settingsPressed()
		"backButton":
			backPressed()
		"changeNameButton":
			changeNamePressed()
		"submitNameButton":
			changePetName()
		"quitButton":
			quitPressed()
		"startScreenButton":
			goToStartPressed()
		"inventoryButton":
			open_inventory("feed")
		_:
			# ignore unknown buttons
			pass


# -------------------------
# Popups & settings
# -------------------------
func showPopup() -> void:
	if popupPanel != null:
		popupPanel.visible = true

func settingsPressed() -> void:
	showPopup()
	if gm != null:
		gm.pause_game()
	if settingsPopup != null:
		settingsPopup.visible = true
	if pet_manager != null and pet_manager.has_method("set_thought_visible"):
		pet_manager.set_thought_visible(false)


func backPressed() -> void:
	if popupPanel != null:
		popupPanel.visible = false
	if changeName != null:
		changeName.visible = false
	if inventoryPanel != null:
		inventoryPanel.visible = false
	if settingsPopup != null:
		settingsPopup.visible = false

	if gm != null:
		gm.resume_game()
	if pet_manager != null and pet_manager.has_method("set_thought_visible"):
		pet_manager.set_thought_visible(true)


func changeNamePressed() -> void:
	showPopup()
	if changeName != null:
		changeName.visible = true
	if gm != null:
		gm.pause_game()


func changePetName() -> void:
	var pet_name: String = ""
	if changeNameInput != null:
		pet_name = changeNameInput.text.strip_edges()

	if pet_name == "":
		if errorLabel != null:
			errorLabel.text = "Please enter a name."
		return

	if slm != null:
		slm.playerData["name"] = pet_name
		slm.saveGame()

	if changeNameInput != null:
		changeNameInput.text = ""
	if changeName != null:
		changeName.visible = false
	if popupPanel != null:
		popupPanel.visible = false
	if gm != null:
		gm.resume_game()


# -------------------------
# Action helpers
# -------------------------
func _on_shop_pressed() -> void:
	if gm != null and gm.has_method("allMax"):
		gm.allMax()


func quitPressed() -> void:
	if slm != null:
		slm.saveGame()
	get_tree().quit()


func goToStartPressed() -> void:
	if slm != null:
		slm.saveGame()
	if popupPanel != null:
		popupPanel.visible = false
	if changeName != null:
		changeName.visible = false

	if start_scene != null and start_scene.has_method("onStartScreenPressed"):
		start_scene.onStartScreenPressed()
	else:
		var s = get_tree().get_root().get_node_or_null("Main/start")
		if s != null and s.has_method("onStartScreenPressed"):
			s.onStartScreenPressed()


# -------------------------
# Inventory UI
# -------------------------
func open_inventory(inv_name: String = "feed") -> void:
	current_inventory_name = inv_name
	if popupPanel != null:
		popupPanel.visible = true
	if inventoryPanel != null:
		inventoryPanel.visible = true
	_populate_inventory_list()
	if gm != null:
		gm.pause_game()
	if pet_manager != null and pet_manager.has_method("set_thought_visible"):
		pet_manager.set_thought_visible(false)


func _on_inv_close_pressed() -> void:
	if inventoryPanel != null:
		inventoryPanel.visible = false
	if popupPanel != null:
		popupPanel.visible = false
	if gm != null:
		gm.resume_game()
	if pet_manager != null and pet_manager.has_method("set_thought_visible"):
		pet_manager.set_thought_visible(true)




func _populate_inventory_list() -> void:
	# clear old rows
	for child in inv_list.get_children():
		child.queue_free()

	# common font resource
	var font_path := "res://assets/fonts/pixelFont.ttf"
	var font_res = null
	if FileAccess.file_exists(font_path):
		font_res = load(font_path)

	# prefer inventoryManager
	var inv: Dictionary = {}
	if inv_manager and inv_manager.has_method("getInventory"):
		inv = inv_manager.getInventory(current_inventory_name)
	elif slm:
		inv = slm.playerData.get("inventories", {}).get(current_inventory_name, {})
	else:
		var label := Label.new()
		label.text = "Empty"
		if font_res != null:
			var empty_theme := Theme.new()
			empty_theme.set_font("font", "Label", font_res)
			label.theme = empty_theme
		inv_list.add_child(label)
		return

	# empty inventory
	if inv.size() == 0:
		var label := Label.new()
		label.text = "Empty"
		if font_res != null:
			var empty_theme := Theme.new()
			empty_theme.set_font("font", "Label", font_res)
			label.theme = empty_theme
		inv_list.add_child(label)
		return

	# --- Prepare themes for rows ---
	var label_theme = null
	var button_theme = null
	if font_res != null:
		label_theme = Theme.new()
		label_theme.set_font("font", "Label", font_res)
		button_theme = Theme.new()
		button_theme.set_font("font", "Button", font_res)

	# populate items
	for item_id in inv.keys():
		var raw = inv[item_id]
		var item_def = null
		if item_db and item_db.has_method("get_item"):
			item_def = item_db.get_item(item_id)
		else:
			item_def = {"name": item_id, "restore": {}, "uses": 1}

		var item_data: Dictionary
		if typeof(raw) == TYPE_DICTIONARY:
			item_data = raw
		else:
			item_data = {"count": int(raw), "uses": item_def.get("uses", 1)}

		_create_inventory_row(item_id, item_data, item_def, label_theme, button_theme)


func _create_inventory_row(item_id: String, item_data: Dictionary, item_def: Dictionary, label_theme, button_theme) -> void:
	var row = HBoxContainer.new()
	row.name = "row_" + item_id

	var display_name = item_def.get("name", item_id)
	var uses_left = item_data.get("uses", item_def.get("uses", 1))
	var count = item_data.get("count", 1)
	var restore_stats: Dictionary = item_def.get("restore", {})

	var stats_text = ""
	for stat_name in restore_stats.keys():
		stats_text += "%s +%d  " % [stat_name.capitalize(), int(restore_stats[stat_name])]

	var name_label = Label.new()
	name_label.text = "%s (x%d, uses left: %d)  %s" % [display_name, count, uses_left, stats_text]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if label_theme != null:
		name_label.theme = label_theme
	row.add_child(name_label)

	var use_btn = Button.new()
	use_btn.text = "Use"
	if button_theme != null:
		use_btn.theme = button_theme
	use_btn.pressed.connect(func() -> void: _on_use_item(item_id))
	row.add_child(use_btn)

	var drop_btn = Button.new()
	drop_btn.text = "Drop"
	if button_theme != null:
		drop_btn.theme = button_theme
	drop_btn.pressed.connect(func() -> void: _on_drop_item(item_id))
	row.add_child(drop_btn)

	inv_list.add_child(row)


func _on_use_item(item_id: String) -> void:
	# Prefer inventoryManager methods when available
	if inv_manager != null and inv_manager.has_method("getInventory"):
		# Work on a direct reference via saveLoadManager
		if slm == null:
			return
		var inv_ref = slm.playerData.get("inventories", {}).get(current_inventory_name, {})
		if not inv_ref.has(item_id):
			return
		var raw = inv_ref[item_id]

		var item_def = {}
		if item_db != null and item_db.has_method("get_item"):
			item_def = item_db.get_item(item_id)

		var item_data = {}
		if typeof(raw) == TYPE_DICTIONARY:
			item_data = raw
		else:
			item_data = {"count": int(raw), "uses": item_def.get("uses", 1)}

		var effects = item_def.get("restore", item_def.get("effects", {}))
		if slm != null and slm.playerData.has("stats"):
			for stat in effects.keys():
				var change = int(effects[stat])
				var old = int(slm.playerData["stats"].get(stat, 0))
				slm.playerData["stats"][stat] = clamp(old + change, 0, 100)

		item_data["uses"] = int(item_data.get("uses", 1)) - 1
		if item_data["uses"] <= 0:
			# drop one count via manager if possible
			if inv_manager != null and inv_manager.has_method("removeItem"):
				inv_manager.removeItem(current_inventory_name, item_id, 1)
			else:
				if item_data.has("count"):
					item_data["count"] = int(item_data["count"]) - 1
				if item_data.get("count", 0) <= 0:
					inv_ref.erase(item_id)
				else:
					item_data["uses"] = item_def.get("uses", 1)
					inv_ref[item_id] = item_data
		else:
			inv_ref[item_id] = item_data

		if slm != null:
			slm.saveGame()

	else:
		# fallback direct mutation
		if slm == null:
			return
		var inv_ref = slm.playerData.get("inventories", {}).get(current_inventory_name, {})
		if not inv_ref.has(item_id):
			return
		var raw = inv_ref[item_id]

		var item_def = {}
		if item_db != null and item_db.has_method("get_item"):
			item_def = item_db.get_item(item_id)

		var item_data = {}
		if typeof(raw) == TYPE_DICTIONARY:
			item_data = raw
		else:
			item_data = {"count": int(raw), "uses": item_def.get("uses", 1)}

		var effects = item_def.get("restore", item_def.get("effects", {}))
		if slm.playerData.has("stats"):
			for stat in effects.keys():
				var change = int(effects[stat])
				var old = int(slm.playerData["stats"].get(stat, 0))
				slm.playerData["stats"][stat] = clamp(old + change, 0, 100)

		item_data["uses"] = int(item_data.get("uses", 1)) - 1
		if item_data["uses"] <= 0:
			item_data["count"] = int(item_data.get("count", 0)) - 1
			if item_data["count"] > 0:
				item_data["uses"] = item_def.get("uses", 1)
			else:
				inv_ref.erase(item_id)
		else:
			inv_ref[item_id] = item_data

		slm.playerData["inventories"][current_inventory_name] = inv_ref
		if slm != null:
			slm.saveGame()

	# refresh UI
	open_inventory(current_inventory_name)


func _on_drop_item(item_id: String) -> void:
	# prefer inventoryManager API
	if inv_manager != null and inv_manager.has_method("removeItem"):
		inv_manager.removeItem(current_inventory_name, item_id)
	else:
		if slm == null:
			return
		var inv_ref = slm.playerData.get("inventories", {}).get(current_inventory_name, {})
		if inv_ref.has(item_id):
			inv_ref.erase(item_id)
			slm.playerData["inventories"][current_inventory_name] = inv_ref
			slm.saveGame()

	_populate_inventory_list()


# -------------------------
# Start screen hook
# -------------------------
func _on_start_screen_pressed() -> void:
	if start_scene != null and start_scene.has_method("onStartScreenPressed"):
		start_scene.onStartScreenPressed()
	else:
		var s = get_tree().get_root().get_node_or_null("Main/start")
		if s != null and s.has_method("onStartScreenPressed"):
			s.onStartScreenPressed()
		else:
			push_warning("start scene method not found.")
