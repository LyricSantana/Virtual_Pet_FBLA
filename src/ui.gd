extends Control

@onready var day_label: Label = get_node("labels/dayLabel")

func _ready():
	_connect_buttons(self)

func _connect_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is TextureButton:
			child.pressed.connect(on_button_pressed.bind(child))
		_connect_buttons(child)

func _process(delta: float) -> void:
	if day_label:
		day_label.text = "Seconds:" + str(gameManager.get_seconds_into_day())

func on_button_pressed(button: TextureButton) -> void:
	match button.name:
		"feedButton":
			feed_pressed()
		"playButton":
			play_pressed()
		"restButton":
			rest_pressed()
		"vetButton":
			vet_pressed()
		"cleanButton":
			clean_pressed()
		"shopButton":
			shop_pressed()
		"settingsButton":
			settings_pressed()


func feed_pressed():
	print("Feed button was pressed")

func play_pressed():
	print("Play button was pressed")

func rest_pressed():
	print("Rest button was pressed")

func vet_pressed():
	print("Vet button was pressed")

func clean_pressed():
	print("Clean button was pressed")

func shop_pressed():
	print("Shop button was pressed")

func settings_pressed():
	print("Settings button was pressed")
