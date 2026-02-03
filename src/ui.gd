extends Control

var settingsPanel

func _ready():
	settingsPanel = get_node_or_null("settingsPanel")
	settingsPanel.visible = false
	# connect all the buttons when the scene loads
	_connect_buttons(self)
	# update the UI with the current stats and labels
	updateValues()

func updateValues():
	# get the current player data from the save manager
	var playerData = saveLoadManager.playerData
	
	# loop through all stats and update the corresponding progress bars
	var stats = playerData.get("stats", {})
	for stat_name in stats.keys():
		# assumes your TextureProgressBar is named like "hungerBar", "energyBar", etc.
		var bar = $statsPanel.get_node_or_null(stat_name + "Bar")
		if bar and bar is TextureProgressBar:
			bar.value = int(stats[stat_name])
	
	# update day and money labels
	$labels/dayLabel.text = "Days: " + str(int(playerData.get("day", 0)))
	$labels/moneyLabel.text = "Money: $" + str(int(playerData.get("money", 0)))
	$labels/nameLabel.text = "Name: " + str(playerData.get("name", "miso"))

func _connect_buttons(node: Node) -> void:
	# recursively connect all TextureButtons to on_button_pressed
	for child in node.get_children():
		if child is TextureButton:
			child.pressed.connect(on_button_pressed.bind(child))
		_connect_buttons(child)

func _process(delta: float) -> void:
	# refresh the UI every frame (so bars and labels match current playerData)
	updateValues()

func on_button_pressed(button: TextureButton) -> void:
	# handle which button got pressed
	match button.name:
		"feedButton": feedPressed()
		"playButton": playPressed()
		"restButton": restPressed()
		"vetButton": vetPressed()
		"cleanButton": cleanPressed()
		"shopButton": shopPressed()
		"settingsButton": settingsPressed()
		"backButton": backPressed()


# all the functions that get triggered when a button is pressed
func feedPressed():
	print("Feed button was pressed")

func playPressed():
	print("Play button was pressed")

func restPressed():
	print("Rest button was pressed")

func vetPressed():
	print("Vet button was pressed")

func cleanPressed():
	print("Clean button was pressed")

func shopPressed():
	print("Shop button was pressed")

func settingsPressed():
	print("Settings button was pressed")
	if settingsPanel.visible:
		settingsPanel.visible = false
	else:
		settingsPanel.visible = true

func backPressed():
	settingsPanel.visible = false