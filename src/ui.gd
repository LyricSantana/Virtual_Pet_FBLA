extends Control

func _ready():
	_connect_buttons(self)

func _connect_buttons(node: Node):
	for child in node.get_children():
		if child is TextureButton:
			child.pressed.connect(on_button_pressed.bind(child))
		_connect_buttons(child)

func on_button_pressed(button: TextureButton):
	match button.name:
		"feedButton":
			feedPressed()
		"playButton":
			playPressed()
		"restButton":
			restPressed()
		"vetButton":
			vetPressed()
		"cleanButton":
			cleanPressed()
		"shopButton":
			shopPressed()
		"settingsButton":
			settingsPressed()

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
	print("Settings Button was Pressed")
	
