extends Control

# UI nodes
var popupPanel
var changeNameButton
var changeName
var errorLabel 
var changeNameInput

func _ready() -> void:
	# get references to UI elements
	popupPanel = get_node_or_null("popupPanel")
	changeNameButton = get_node_or_null("labels/nameBox/changeNameButton")
	changeName = get_node_or_null("popupPanel/changeName")
	errorLabel = get_node_or_null("popupPanel/changeName/errorLabel")
	changeNameInput = get_node_or_null("popupPanel/changeName/changeNameInput")

	# hide popups at start
	if popupPanel:
		popupPanel.visible = false
	if changeName:
		changeName.visible = false

	# connect all buttons recursively
	_connect_buttons(self)
	# populate initial values
	updateValues()

# update UI elements with latest player data
func updateValues() -> void:
	var playerData = saveLoadManager.playerData

	# update all stat bars dynamically
	var stats = playerData.get("stats", {})
	for stat_name in stats.keys():
		var bar = $statsPanel.get_node_or_null(stat_name + "Bar")
		if bar and bar is TextureProgressBar:
			bar.value = int(stats[stat_name])

	# update labels
	$labels/dayLabel.text = "Days: " + str(int(playerData.get("day", 0)))
	$labels/moneyLabel.text = "Money: $" + str(int(playerData.get("money", 0)))
	$labels/nameBox/nameLabel.text = "Name: " + str(playerData.get("name", "Pet"))

# recursively connect all TextureButton children to the same handler
func _connect_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is TextureButton:
			child.pressed.connect(on_button_pressed.bind(child))
		_connect_buttons(child)

func _process(delta: float) -> void:
	# update UI every frame so it's always in sync
	updateValues()

# handle any button pressed
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

# show the main popup panel
func showPopup():
	if popupPanel:
		popupPanel.visible = true

# button handlers
func feedPressed() -> void:
	print("Feed button was pressed")

func playPressed() -> void:
	print("Play button was pressed")

func restPressed() -> void:
	print("Rest button was pressed")

func vetPressed() -> void:
	print("Vet button was pressed")

func cleanPressed() -> void:
	print("Clean button was pressed")

func shopPressed() -> void:
	print("Shop button was pressed")

# open settings popup
func settingsPressed() -> void:
	showPopup()

# close popups and resume game
func backPressed() -> void:
	if popupPanel:
		popupPanel.visible = false
	if changeName:
		changeName.visible = false
	gameManager.resume_game()

# open change name popup and pause game
func changeNamePressed():
	showPopup()
	if changeName:
		changeName.visible = true
	gameManager.pause_game()

# submit new pet name
func changePetName():
	var pet_name := ""
	if changeNameInput:
		# get text and remove spaces
		pet_name = changeNameInput.text.strip_edges()

	# check if name is empty
	if pet_name == "":
		if errorLabel:
			errorLabel.text = "Please enter a name."
		return

	# save new name and reset UI
	saveLoadManager.playerData["name"] = pet_name
	saveLoadManager.saveGame()
	if changeNameInput:
		changeNameInput.text = ""
	if changeName:
		changeName.visible = false
	if popupPanel:
		popupPanel.visible = false
	gameManager.resume_game()