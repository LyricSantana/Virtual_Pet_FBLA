## Main UI controller
# This file drives the HUD, popups, and shop/inventory screens.
# It also handles reports, chores, and settings.

extends Control

# Node bindings (scene paths)
@onready var popupPanel = $popupPanel
@onready var changeNameButton = $labels/nameBox/changeNameButton
@onready var changeName = $popupPanel/changeNamePanel/vBoxContainer/submitNameButton
@onready var changeNamePanel = $popupPanel/changeNamePanel
@onready var errorLabel = $popupPanel/changeNamePanel/vBoxContainer/errorLabel
@onready var changeNameInput = $popupPanel/changeNamePanel/vBoxContainer/changeNameInput
@onready var settingsPopup = $popupPanel/settingsPopup
@onready var startScreenButton = $popupPanel/settingsPopup/startScreenButton

# Settings controls (from scene)
@onready var timeScaleSlider = $popupPanel/settingsPopup/settingsContainer/timeScaleBox/timeScaleSlider
@onready var timeScaleLabel = $popupPanel/settingsPopup/settingsContainer/timeScaleBox/timeScaleLabel
@onready var autoSaveToggle = $popupPanel/settingsPopup/settingsContainer/autoSaveToggle

@onready var settingsContainer = $popupPanel/settingsPopup/settingsContainer

@onready var helpButton = $labels/quickButtons/helpButton
@onready var reportButton = $labels/quickButtons/reportButton
@onready var choreButton = $labels/quickButtons/choreButton

@onready var inventoryPanel = $popupPanel/inventoryPanel
@onready var invCloseButton = $popupPanel/inventoryPanel/VBoxContainer/invCloseButton
@onready var invList = $popupPanel/inventoryPanel/VBoxContainer/ScrollContainer/invList

@onready var totalExpenseLabel = $popupPanel/shopPanel/expensesTotalLabel  # adjust if path differs

@onready var shopCloseButton = $popupPanel/shopPanel/closeButton
@onready var shopMoneyLabel = $popupPanel/shopPanel/moneyLabel
@onready var shopPanel = $popupPanel/shopPanel

@onready var helpPanel = $popupPanel/helpPanel
@onready var helpCloseButton = $popupPanel/helpPanel/helpVBox/helpCloseButton
@onready var helpTextLabel = $popupPanel/helpPanel/helpVBox/helpTextLabel

@onready var reportPanel = $popupPanel/reportPanel
@onready var reportCloseButton = $popupPanel/reportPanel/reportVBox/reportCloseButton
@onready var reportStatsLabel = $popupPanel/reportPanel/reportVBox/reportStatsLabel
@onready var reportBreakdownLabel = $popupPanel/reportPanel/reportVBox/reportBreakdownLabel
@onready var reportSavingsLabel = $popupPanel/reportPanel/reportVBox/reportSavingsLabel
@onready var reportRecentList = $popupPanel/reportPanel/reportVBox/reportScroll/reportRecentList

@onready var chorePanel = $popupPanel/chorePanel
@onready var choreCloseButton = $popupPanel/chorePanel/choreVBox/choreCloseButton
@onready var choreInfoLabel = $popupPanel/chorePanel/choreVBox/choreInfoLabel
@onready var choreList = $popupPanel/chorePanel/choreVBox/choreScroll/choreList

@onready var messageLabel = $popupPanel/messageLabel
@onready var clockLabel = $labels/clockLabel
@onready var toastLabel = $toastLabel
@onready var backGround = $backGround

var itemTheme: Theme

# --- Font size constants (tweak these)
const inventoryItemFontSize: int = 10
const inventoryButtonFontSize: int = 10

const nameMinLen: int = 2
const nameMaxLen: int = 12
const expenseLogLimit: int = 200
const weeklyLimitDefault: int = 120
const savingsGoalDefault: int = 100
const choreSavingsRate: float = 0.2
const dailyChoreCount: int = 3
const choreTapMin: int = 6
const choreTapMax: int = 20
const choreTapScale: float = 1.5
const criticalStatThreshold: int = 25
const criticalStatCount: int = 3
const criticalChoreRewardMultiplier: float = 0.5
const criticalChoreTapMultiplier: float = 1.5
const backgroundTexturePaths := [
	"res://assets/backgrounds/day.png",
	"res://assets/backgrounds/sunset.png",
	"res://assets/backgrounds/night.png",
	"res://assets/backgrounds/sunrise.png"
]

const chores: Array = [
	{"id": "makeBed", "label": "Make your bed", "reward": 6},
	{"id": "study", "label": "Study 15 minutes", "reward": 8},
	{"id": "dishes", "label": "Help with dishes", "reward": 10},
	{"id": "trash", "label": "Take out trash", "reward": 7},
	{"id": "laundry", "label": "Fold laundry", "reward": 9},
	{"id": "vacuum", "label": "Vacuum a room", "reward": 9},
	{"id": "petRefill", "label": "Refill pet water", "reward": 5},
	{"id": "desk", "label": "Clean your desk", "reward": 6},
	{"id": "notes", "label": "Review notes", "reward": 7},
	{"id": "walk", "label": "Take a short walk", "reward": 6}
]

# Shop section order for tabs
const shopSections: Array = ["feed", "play", "rest", "vet", "clean"]

# Autoload / scene managers
var gameManagerRef
var saveLoadManagerRef
var inventoryManagerRef
var itemDb
var petManagerRef
var startScene
var pixelFontRes = null

# Shop data
var shopItems: Dictionary = {
	"feed": [
		{"id":"petFood", "price":5},
		{"id":"veggieMix", "price":8},
		{"id":"heartyStew", "price":18},
		{"id":"beefJerky", "price":12, "species":"dog"},
		{"id":"tunaTreat", "price":12, "species":"cat"}
	],
	"play": [
		{"id":"toyBall", "price":10},
		{"id":"laserPointer", "price":20},
		{"id":"tugRope", "price":14},
		{"id":"squeakyBone", "price":16, "species":"dog"},
		{"id":"featherWand", "price":16, "species":"cat"}
	],
	"rest": [
		{"id":"cozyBlanket", "price":12},
		{"id":"comfyBed", "price":30},
		{"id":"deluxeBed", "price":50},
		{"id":"dogCushion", "price":28, "species":"dog"},
		{"id":"catCave", "price":28, "species":"cat"}
	],
	"vet": [
		{"id":"medicine", "price":25},
		{"id":"bandageWrap", "price":12},
		{"id":"vetVisit", "price":30},
		{"id":"calmingSpray", "price":15},
		{"id":"fleaShampoo", "price":18}
	],
	"clean": [
		{"id":"petWipes", "price":8},
		{"id":"deodorizer", "price":10},
		{"id":"bubbleBath", "price":20},
		{"id":"nailTrimmer", "price":12},
		{"id":"earCleaner", "price":14}
	]
}

# runtime references for shop UI


var shopLists := {}
var shopTabContainer
var currentInventoryName: String = "feed"

var currentShopSection: String = "feed"
var choreTapProgress: Dictionary = {}
var lastChoreNotifyDay: int = -1
var toastTimer: Timer
var backgroundTextures: Array = []
var currentBackgroundPhase: int = -1

# Startup
func _ready() -> void:
	# Set up references, buttons, and initial UI state.
	# resolve managers
	gameManagerRef = gameManager
	saveLoadManagerRef = saveLoadManager
	inventoryManagerRef = inventoryManager
	itemDb = itemDB
	petManagerRef = petManager

	startScene = get_tree().get_root().get_node("Main/startLayer/start")

	# initial visibility
	popupPanel.visible = false
	changeName.visible = false
	changeNamePanel.visible = false
	inventoryPanel.visible = false
	settingsPopup.visible = false
	shopPanel.visible = false
	helpPanel.visible = false
	reportPanel.visible = false
	chorePanel.visible = false
	messageLabel.visible = false
	toastLabel.visible = false

	# connect buttons
	invCloseButton.pressed.connect(_onInvClosePressed)
	startScreenButton.pressed.connect(_onStartScreenPressed)
	helpButton.pressed.connect(openHelp)
	reportButton.pressed.connect(openReport)
	choreButton.pressed.connect(openChores)
	helpCloseButton.pressed.connect(closeHelp)
	reportCloseButton.pressed.connect(closeReport)
	choreCloseButton.pressed.connect(closeChores)

	# connect all TextureButtons recursively
	_connectButtons(self)

	updateValues()
	_ensureEconomyData()

	# optional theme
	pixelFontRes = load("res://assets/fonts/pixelFont.ttf")

	# ensure shop panel exists or map nodes
	_ensureShopPanel()
	gameManagerRef.dayPassed.connect(_onDayPassed)
	
	# Setup settings controls
	_setupSettingsUI()
	
	# Load saved settings
	_loadSettings()

	_loadBackgrounds()
	_updateBackground(true)

	toastTimer = Timer.new()
	toastTimer.one_shot = true
	add_child(toastTimer)
	toastTimer.timeout.connect(_onToastTimeout)


# Connect buttons recursively
func _connectButtons(node: Node) -> void:
	# Hook up TextureButtons so clicks go to one handler.
	for child in node.get_children():
		if child is TextureButton:
			# bind the child and pass it into handler
			child.pressed.connect(onButtonPressed.bind(child))
			_wireButtonLabelPress(child)
		# recurse into children
		_connectButtons(child)


func _wireButtonLabelPress(btn: TextureButton) -> void:
	# Keep text aligned with the pressed button offset.
	var label = _findButtonLabel(btn)
	if label == null:
		return
	if not label.has_meta("base_pos"):
		label.set_meta("base_pos", label.position)
	btn.button_down.connect(func() -> void: _offsetButtonLabel(btn, true))
	btn.button_up.connect(func() -> void: _offsetButtonLabel(btn, false))
	btn.mouse_exited.connect(func() -> void: _offsetButtonLabel(btn, false))


func _findButtonLabel(btn: TextureButton) -> Label:
	# Find the first label inside a button.
	for child in btn.get_children():
		if child is Label:
			return child
	return null


func _offsetButtonLabel(btn: TextureButton, pressed: bool) -> void:
	# Nudge the label to match the button press animation.
	var label = _findButtonLabel(btn)
	if label == null:
		return
	var basePos = label.get_meta("base_pos") if label.has_meta("base_pos") else label.position
	label.position = basePos + (Vector2(0, 4) if pressed else Vector2.ZERO)


# Setup settings UI with signal connections
func _setupSettingsUI() -> void:
	# Connect settings control signals
	timeScaleSlider.value_changed.connect(_onTimeScaleChanged)
	autoSaveToggle.toggled.connect(_onAutoSaveToggled)
	

# Settings handlers
func _onTimeScaleChanged(value: float) -> void:
	# Update game speed and save the setting.
	gameManagerRef.timeScale = value
	timeScaleLabel.text = "Game Speed: %.1fx" % value
	# Save setting
	saveLoadManagerRef.playerData["timeScale"] = value


func _onAutoSaveToggled(enabled: bool) -> void:
	# Store auto-save preference
	saveLoadManagerRef.playerData["autoSaveEnabled"] = enabled
	saveLoadManagerRef.saveGame()



func _loadSettings() -> void:
	# Load saved settings from player data
	var pd = saveLoadManagerRef.playerData
	
	# Load time scale
	if pd.has("timeScale"):
		var scale = float(pd.get("timeScale", 1.0))
		timeScaleSlider.value = scale
		gameManagerRef.timeScale = scale
	
	# Load auto-save preference
	if pd.has("autoSaveEnabled"):
		var enabled = bool(pd.get("autoSaveEnabled", true))
		autoSaveToggle.button_pressed = enabled
	

# Update UI values
func _process(delta: float) -> void:
	# Keep UI values updated every frame.
	updateValues()
	_updateClock()
	_updateBackground()


func updateValues() -> void:
	# Refresh labels and bars from saved player data.
	var playerData: Dictionary = saveLoadManagerRef.playerData
	var stats: Dictionary = playerData.get("stats", {})

	for statName in stats.keys():
		var bar = $statsPanel.get_node(statName + "Bar")
		bar.value = int(stats[statName])

	var dayNode = $labels.get_node_or_null("dayLabel")
	dayNode.text = "Days: " + str(int(playerData.get("day", 0)))

	var moneyNode = $labels.get_node_or_null("moneyLabel")
	moneyNode.text = "Money: $" + str(int(playerData.get("money", 0)))

	var nameNode = $labels.get_node_or_null("nameBox/nameLabel")
	nameNode.text = "Name: " + str(playerData.get("name", "Pet"))

	# shop headers (if present and visible)
	if shopPanel.visible:
		shopMoneyLabel.text = "Money: $" + str(int(playerData.get("money", 0)))
		totalExpenseLabel.text = "Expenses: $" + str(int(playerData.get("careExpenses", 0)))


# Button handler
func onButtonPressed(button: TextureButton) -> void:
	# Route button clicks based on the button name.
	match button.name:
		"feedButton":
			openInventory("feed")
		"playButton":
			openInventory("play")
		"restButton":
			openInventory("rest")
		"vetButton":
			openInventory("vet")
		"cleanButton":
			openInventory("clean")
		"shopButton":
			_onShopPressed()
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
			openInventory("feed")
		_:
			# ignore unknown buttons
			pass


# Popups & settings
func showPopup() -> void:
	# Show the main popup panel.
	popupPanel.visible = true
	_setThoughtSuppressed(true)


func _setThoughtSuppressed(suppressed: bool) -> void:
	# Hide or show the pet thought bubble when popups are open.
	petManagerRef.setThoughtSuppressed(suppressed)

func settingsPressed() -> void:
	# Open settings and pause the game.
	showPopup()
	gameManagerRef.pauseGame()
	settingsPopup.visible = true
	_setThoughtSuppressed(true)


func backPressed() -> void:
	# Close all popups and resume gameplay if a popup paused the game.
	var shouldResume = settingsPopup.visible or helpPanel.visible or reportPanel.visible or chorePanel.visible or changeNamePanel.visible
	
	popupPanel.visible = false
	changeName.visible = false
	changeNamePanel.visible = false
	inventoryPanel.visible = false
	settingsPopup.visible = false
	shopPanel.visible = false
	helpPanel.visible = false
	reportPanel.visible = false
	chorePanel.visible = false
	messageLabel.visible = false

	# Resume if any pausing popup was open
	if shouldResume:
		gameManagerRef.resumeGame()
	_setThoughtSuppressed(false)


func changeNamePressed() -> void:
	# Open the change name popup.
	showPopup()
	changeNamePanel.visible = true
	changeName.visible = true
	gameManagerRef.pauseGame()


func changePetName() -> void:
	# Save a new pet name from the input field.
	var petName: String = ""
	petName = changeNameInput.text.strip_edges()

	var nameError = _validatePetName(petName)
	if nameError != "":
		errorLabel.text = nameError
		return

	saveLoadManagerRef.playerData["name"] = petName
	saveLoadManagerRef.saveGame()

	changeNameInput.text = ""
	changeName.visible = false
	popupPanel.visible = false
	changeNamePanel.visible = false
	gameManagerRef.resumeGame()


func _validatePetName(petName: String) -> String:
	# Enforce simple name rules for input validation.
	var trimmed = petName.strip_edges()
	if trimmed.length() < nameMinLen or trimmed.length() > nameMaxLen:
		return "Name must be %d-%d characters." % [nameMinLen, nameMaxLen]
	var regex = RegEx.new()
	regex.compile("^[A-Za-z ]+$")
	if regex.search(trimmed) == null:
		return "Use letters and spaces only."
	return ""





func _showMessage(text: String) -> void:
	# Show a short message in the popup area.
	messageLabel.text = text
	messageLabel.visible = true


func _showToast(text: String, seconds: float = 2.5) -> void:
	# Show a short message for a few seconds.
	toastLabel.text = text
	toastLabel.visible = true
	toastTimer.stop()
	toastTimer.start(seconds)


func _onToastTimeout() -> void:
	# Hide the toast label after the timer ends.
	toastLabel.visible = false


func _updateClock() -> void:
	# Update the on-screen time label.
	var dayLength = float(gameManagerRef.dayLength)
	if dayLength <= 0.0:
		return
	var seconds = float(gameManagerRef.getSecondsIntoDay())
	var dayFraction = clamp(seconds / dayLength, 0.0, 0.999)
	var slot = int(floor(dayFraction * 96.0))
	var minutes = slot * 15
	var hours = int(minutes / 60)
	var mins = int(minutes % 60)
	clockLabel.text = "Time: %02d:%02d" % [hours, mins]


func _loadBackgrounds() -> void:
	# Load background textures for different times of day.
	backgroundTextures.clear()
	for path in backgroundTexturePaths:
		backgroundTextures.append(load(path))


func _updateBackground(force: bool = false) -> void:
	# Pick the correct background based on the in-game clock.
	var dayLength = float(gameManagerRef.dayLength)
	if dayLength <= 0.0:
		return
	var seconds = float(gameManagerRef.getSecondsIntoDay())
	var dayFraction = clamp(seconds / dayLength, 0.0, 0.999)
	var slot = int(floor(dayFraction * 96.0))
	var minutes = slot * 15
	var hours = int(minutes / 60)
	var phase = 0
	if hours < 6:
		phase = 3 # sunrise
	elif hours < 18:
		phase = 0 # day
	elif hours < 21:
		phase = 1 # sunset
	else:
		phase = 2 # night
	if not force and phase == currentBackgroundPhase:
		return
	currentBackgroundPhase = phase
	backGround.texture = backgroundTextures[phase]


func _ensureEconomyData() -> void:
	# Guarantee required economy keys exist in player data.
	var pd = saveLoadManagerRef.playerData
	if not pd.has("expenses"):
		pd["expenses"] = []
	if not pd.has("weeklyLimit"):
		pd["weeklyLimit"] = weeklyLimitDefault
	if not pd.has("savingsGoal"):
		pd["savingsGoal"] = savingsGoalDefault
	if not pd.has("savingsSaved"):
		pd["savingsSaved"] = 0
	if not pd.has("chores"):
		pd["chores"] = {"lastDay": -1, "done": [], "available": []}
	elif typeof(pd["chores"]) == TYPE_DICTIONARY:
		if not pd["chores"].has("available"):
			pd["chores"]["available"] = []


func _warnIfNearWeeklyLimit() -> void:
	# Warn the player as the weekly spending cap fills.
	var pd = saveLoadManagerRef.playerData
	var weeklyLimit = int(pd.get("weeklyLimit", weeklyLimitDefault))
	if weeklyLimit <= 0:
		messageLabel.visible = false
		return
	var weekTotal = _sumTransactions("expense", 7)
	if weekTotal >= weeklyLimit:
		_showMessage("Weekly budget limit reached: $%d/$%d." % [weekTotal, weeklyLimit])
	elif weekTotal >= int(weeklyLimit * 0.8):
		_showMessage("Weekly budget almost full: $%d/$%d." % [weekTotal, weeklyLimit])
	else:
		messageLabel.visible = false


func _logTransaction(kind: String, category: String, itemId: String, amount: int, tag: String = "") -> void:
	# Log expenses and income for reports.
	var pd = saveLoadManagerRef.playerData
	var expenses: Array = pd.get("expenses", [])
	var entry = {
		"day": int(pd.get("day", 0)),
		"sec": int(gameManagerRef.getSecondsIntoDay()),
		"kind": kind,
		"category": category,
		"item": itemId,
		"amount": amount,
		"tag": tag
	}
	expenses.append(entry)
	if expenses.size() > expenseLogLimit:
		expenses.pop_front()
	pd["expenses"] = expenses


func _sumTransactions(kind: String, daysBack: int) -> int:
	# Sum expenses or income for a trailing time window.
	var pd = saveLoadManagerRef.playerData
	var today = int(pd.get("day", 0))
	var total = 0
	for entry in pd.get("expenses", []):
		if str(entry.get("kind", "expense")) != kind:
			continue
		var day = int(entry.get("day", 0))
		if today - day < daysBack:
			total += int(entry.get("amount", 0))
	return total


func _buildCategoryBreakdown(daysBack: int) -> Dictionary:
	# Aggregate expenses by category for reporting.
	var pd = saveLoadManagerRef.playerData
	var today = int(pd.get("day", 0))
	var totals: Dictionary = {}
	for entry in pd.get("expenses", []):
		if str(entry.get("kind", "expense")) != "expense":
			continue
		var day = int(entry.get("day", 0))
		if today - day >= daysBack:
			continue
		var category = str(entry.get("category", "other"))
		totals[category] = int(totals.get(category, 0)) + int(entry.get("amount", 0))
	return totals


func _refreshReport() -> void:
	# Update report text and recent activity list.
	_ensureEconomyData()
	var pd = saveLoadManagerRef.playerData
	var todayExpense = _sumTransactions("expense", 1)
	var todayIncome = _sumTransactions("income", 1)
	var weekExpense = _sumTransactions("expense", 7)
	var weekIncome = _sumTransactions("income", 7)
	var weeklyLimit = int(pd.get("weeklyLimit", weeklyLimitDefault))
	reportStatsLabel.text = "Today: -$%d  +$%d | Week: -$%d  +$%d | Limit: $%d" % [
		todayExpense, todayIncome, weekExpense, weekIncome, weeklyLimit
	]

	var breakdown = _buildCategoryBreakdown(7)
	var parts: Array = []
	for category in breakdown.keys():
		parts.append("%s $%d" % [category.capitalize(), int(breakdown[category])])
	if parts.size() == 0:
		parts.append("No expenses yet")
	reportBreakdownLabel.text = "Breakdown: " + ", ".join(parts)

	var savingsSaved = int(pd.get("savingsSaved", 0))
	var savingsGoal = int(pd.get("savingsGoal", savingsGoalDefault))
	var percent = 0
	if savingsGoal > 0:
		percent = int(round(100.0 * float(savingsSaved) / float(savingsGoal)))
	reportSavingsLabel.text = "Savings: $%d / $%d (%d%%)" % [savingsSaved, savingsGoal, percent]

	_refreshRecentList()


func _refreshRecentList() -> void:
	# Show the last few transactions for the demo report.
	for child in reportRecentList.get_children():
		child.queue_free()
	var pd = saveLoadManagerRef.playerData
	var entries: Array = pd.get("expenses", [])
	var startIndex = max(0, entries.size() - 6)
	for i in range(entries.size() - 1, startIndex - 1, -1):
		var e = entries[i]
		var kind = str(e.get("kind", "expense"))
		var sign = "-" if kind == "expense" else "+"
		var label = Label.new()
		label.text = "Day %d: %s$%d %s" % [
			int(e.get("day", 0)),
			sign,
			int(e.get("amount", 0)),
			str(e.get("item", ""))
		]
		label.add_theme_font_override("font", pixelFontRes)
		label.add_theme_font_size_override("font_size", 10)
		reportRecentList.add_child(label)


func _getNeedsTag(section: String) -> String:
	# Tag essential vs optional spending for reports.
	if section == "feed" or section == "vet" or section == "clean":
		return "need"
	return "want"


func _canUseItem(effects: Dictionary) -> bool:
	# Block usage if all positive effects are wasted.
	var stats: Dictionary = saveLoadManagerRef.playerData.get("stats", {})
	var hasPositive = false
	for stat in effects.keys():
		var delta = int(effects[stat])
		if delta > 0:
			hasPositive = true
			if int(stats.get(stat, 0)) < 100:
				return true
	return not hasPositive


func openHelp() -> void:
	# Open the help panel.
	showPopup()
	helpPanel.visible = true
	gameManagerRef.pauseGame()
	_setThoughtSuppressed(true)


func closeHelp() -> void:
	# Close help and resume gameplay.
	backPressed()


func openReport() -> void:
	# Open the care report.
	showPopup()
	reportPanel.visible = true
	_refreshReport()
	gameManagerRef.pauseGame()
	_setThoughtSuppressed(true)


func closeReport() -> void:
	# Close report and resume gameplay.
	backPressed()


func openChores() -> void:
	# Open chores for earning coins.
	showPopup()
	chorePanel.visible = true
	_refreshChorePanel()
	gameManagerRef.pauseGame()
	_setThoughtSuppressed(true)


func closeChores() -> void:
	# Close chores and resume gameplay.
	backPressed()


func _resetChoresIfNewDay() -> void:
	# Clear daily chore completion when the day changes.
	var pd = saveLoadManagerRef.playerData
	var choresData = pd.get("chores", {"lastDay": -1, "done": [], "available": []})
	var today = int(pd.get("day", 0))
	if int(choresData.get("lastDay", -1)) != today:
		choresData["lastDay"] = today
		choresData["done"] = []
		choresData["available"] = _rollDailyChores()
		choreTapProgress.clear()
		_notifyNewChores(today, choresData["available"].size())
	elif int(choresData.get("available", []).size()) == 0:
		choresData["available"] = _rollDailyChores()
		choreTapProgress.clear()
		_notifyNewChores(today, choresData["available"].size())
	pd["chores"] = choresData


func _notifyNewChores(today: int, count: int) -> void:
	# Show a short message when new chores appear.
	if count <= 0:
		return
	if today == lastChoreNotifyDay:
		return
	lastChoreNotifyDay = today
	_showToast("New chores available!")


func _onDayPassed(_newDay: int) -> void:
	# Ensure chores refresh and notify when a new day starts.
	_resetChoresIfNewDay()
	if chorePanel.visible:
		_refreshChorePanel()


func _getChoreTapTarget(chore: Dictionary) -> int:
	# Higher reward chores take more taps.
	var reward = int(chore.get("reward", 0))
	var target = clamp(int(round(float(reward) * choreTapScale)), choreTapMin, choreTapMax)
	if _isCriticalStats():
		target = int(ceil(float(target) * criticalChoreTapMultiplier))
	return target


func _rollDailyChores() -> Array:
	# Pick a random set of chores for the day.
	var ids: Array = []
	for chore in chores:
		ids.append(str(chore.get("id", "")))
	ids.shuffle()
	var count = min(dailyChoreCount, ids.size())
	return ids.slice(0, count)


func _getChoreById(choreId: String) -> Dictionary:
	# Find a chore definition by id.
	for chore in chores:
		if str(chore.get("id", "")) == choreId:
			return chore
	return {}


func _truncateText(text: String, maxLen: int) -> String:
	# Keep button labels from forcing extra width.
	if text.length() <= maxLen:
		return text
	return text.substr(0, max(0, maxLen - 3)) + "..."


func _countLowStats(threshold: int) -> int:
	# Count stats at or below the low threshold.
	var stats: Dictionary = saveLoadManagerRef.playerData.get("stats", {})
	var lowCount = 0
	for statName in stats.keys():
		if int(stats.get(statName, 100)) <= threshold:
			lowCount += 1
	return lowCount


func _isCriticalStats() -> bool:
	# Critical state when several stats are too low.
	return _countLowStats(criticalStatThreshold) >= criticalStatCount


func _getAdjustedChoreReward(chore: Dictionary) -> int:
	# Reduce payout when the pet is in a critical state.
	var reward = int(chore.get("reward", 0))
	if _isCriticalStats():
		return max(1, int(round(float(reward) * criticalChoreRewardMultiplier)))
	return reward


func _refreshChorePanel() -> void:
	# Populate chore buttons and status.
	_ensureEconomyData()
	_resetChoresIfNewDay()
	for child in choreList.get_children():
		child.queue_free()
	var choresData: Dictionary = saveLoadManagerRef.playerData.get("chores", {})
	var done: Array = choresData.get("done", [])
	var available: Array = choresData.get("available", [])
	# Drop progress for chores no longer available
	for key in choreTapProgress.keys():
		if not available.has(key):
			choreTapProgress.erase(key)
	for choreId in available:
		var chore = _getChoreById(str(choreId))
		if chore.is_empty():
			continue
		var btn = Button.new()
		var tapsRequired = _getChoreTapTarget(chore)
		var tapsDone = int(choreTapProgress.get(str(choreId), 0))
		var reward = _getAdjustedChoreReward(chore)
		var shortLabel = _truncateText(str(chore.get("label", "Chore")), 20)
		btn.text = "%s  +$%d\n%d/%d" % [shortLabel, reward, tapsDone, tapsRequired]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 0)
		btn.add_theme_font_override("font", pixelFontRes)
		btn.add_theme_font_size_override("font_size", 12)
		if done.has(chore.get("id", "")):
			btn.disabled = true
		btn.pressed.connect(func() -> void: _onChoreTap(chore))
		choreList.add_child(btn)

	if available.size() == 0:
		choreInfoLabel.text = "No chores today."
	elif done.size() >= available.size():
		choreInfoLabel.text = "All chores completed today."
	else:
		choreInfoLabel.text = "Tap a chore to work toward it. (%d/%d)" % [done.size(), available.size()]
	if _isCriticalStats() and available.size() > 0:
		choreInfoLabel.text += " \nLow stats make chores harder and pay less."


func _onChoreTap(chore: Dictionary) -> void:
	# Progress a chore by tapping its button.
	_ensureEconomyData()
	_resetChoresIfNewDay()
	var pd = saveLoadManagerRef.playerData
	var choresData = pd.get("chores", {"lastDay": -1, "done": [], "available": []})
	var done: Array = choresData.get("done", [])
	var available: Array = choresData.get("available", [])
	var choreId = str(chore.get("id", ""))
	if choreId == "" or not available.has(choreId):
		_showMessage("This chore is not available today.")
		return
	if done.has(choreId):
		_showMessage("Chore already done today.")
		return
	var target = _getChoreTapTarget(chore)
	var current = int(choreTapProgress.get(choreId, 0)) + 1
	choreTapProgress[choreId] = current
	choreInfoLabel.text = "Working on %s: %d/%d taps" % [str(chore.get("label", "Chore")), current, target]
	if current >= target:
		choreTapProgress.erase(choreId)
		_completeChore(chore)
		return
	_refreshChorePanel()


func _completeChore(chore: Dictionary) -> void:
	# Award coins for a chore and log it.
	_ensureEconomyData()
	_resetChoresIfNewDay()
	var pd = saveLoadManagerRef.playerData
	var choresData = pd.get("chores", {"lastDay": -1, "done": [], "available": []})
	var done: Array = choresData.get("done", [])
	var available: Array = choresData.get("available", [])
	var choreId = str(chore.get("id", ""))
	if not available.has(choreId):
		_showMessage("This chore is not available today.")
		return
	if done.has(choreId):
		_showMessage("Chore already done today.")
		return
	if choreId != "":
		done.append(choreId)
		choresData["done"] = done
		pd["chores"] = choresData

	var reward = _getAdjustedChoreReward(chore)
	var savingsCut = int(round(float(reward) * choreSavingsRate))
	var cashGain = reward - savingsCut
	var money = int(pd.get("money", 0))
	var savings = int(pd.get("savingsSaved", 0))
	pd["money"] = money + cashGain
	pd["savingsSaved"] = savings + savingsCut

	_logTransaction("income", "chore", str(chore.get("label", "Chore")), reward, "need")
	saveLoadManagerRef.saveGame()
	_showMessage("Chore complete! +$%d ($%d to savings)." % [reward, savingsCut])
	_refreshChorePanel()
	updateValues()


# Action helpers
func _onShopPressed() -> void:
	# Open the shop to the default section.
	openShop("feed")


func quitPressed() -> void:
	# Save game data and quit.
	saveLoadManagerRef.saveGame()
	get_tree().quit()


func goToStartPressed() -> void:
	# Save and go back to the start screen.
	saveLoadManagerRef.saveGame()
	popupPanel.visible = false
	changeName.visible = false
	helpPanel.visible = false
	reportPanel.visible = false
	chorePanel.visible = false
	messageLabel.visible = false

	startScene.onStartScreenPressed()


# Inventory UI
func openInventory(inventoryName: String = "feed") -> void:
	# Show inventory for the chosen category.
	currentInventoryName = inventoryName
	popupPanel.visible = true
	inventoryPanel.visible = true
	_populateInventoryList()
	# Don't pause - inventory can be used during gameplay
	_setThoughtSuppressed(true)


func _onInvClosePressed() -> void:
	# Close inventory.
	inventoryPanel.visible = false
	popupPanel.visible = false
	messageLabel.visible = false
	# Don't resume - game wasn't paused
	_setThoughtSuppressed(false)


func _populateInventoryList() -> void:
	# Fill the inventory list UI from saved data.
	# clear children
	for child in invList.get_children():
		child.queue_free()
	# use cached font
	var fontRes = pixelFontRes

	# get inventory
	var inv: Dictionary = inventoryManagerRef.getInventory(currentInventoryName)

	if inv.size() == 0:
		var label = Label.new()
		label.text = "Empty"
		# apply font and size overrides directly on label
		label.add_theme_font_override("font", fontRes)
		label.add_theme_font_size_override("font_size", inventoryItemFontSize)
		invList.add_child(label)
		return

	var labelTheme = Theme.new()
	labelTheme.set_font("font", "Label", fontRes)
	var buttonTheme = Theme.new()
	buttonTheme.set_font("font", "Button", fontRes)

	for itemId in inv.keys():
		var raw = inv[itemId]
		var itemDef = itemDb.getItem(itemId)

		var itemData: Dictionary
		if typeof(raw) == TYPE_DICTIONARY:
			itemData = raw
		else:
			itemData = {"count": int(raw), "uses": itemDef.get("uses", 1)}

		_createInventoryRow(itemId, itemData, itemDef, labelTheme, buttonTheme)


func _createInventoryRow(itemId: String, itemData: Dictionary, itemDef: Dictionary, labelTheme, buttonTheme) -> void:
	# Build one row with item info and buttons.
	var row = HBoxContainer.new()
	row.name = "row_" + itemId

	var displayName = itemDef.get("name", itemId)
	var usesLeft = itemData.get("uses", itemDef.get("uses", 1))
	var count = itemData.get("count", 1)
	var restoreStats: Dictionary = itemDef.get("restore", {})

	var statsText = ""
	for statName in restoreStats.keys():
		statsText += "%s +%d  " % [statName.capitalize(), int(restoreStats[statName])]

	var nameLabel = Label.new()
	nameLabel.text = "%s (x%d, uses left: %d)  %s" % [displayName, count, usesLeft, statsText]
	nameLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nameLabel.theme = labelTheme
	nameLabel.add_theme_font_size_override("font_size", inventoryItemFontSize)

	row.add_child(nameLabel)

	var useButton = Button.new()
	useButton.text = "Use"
	useButton.theme = buttonTheme
	useButton.add_theme_font_size_override("font_size", inventoryButtonFontSize)

	useButton.pressed.connect(func() -> void: _onUseItem(itemId))
	row.add_child(useButton)

	var dropButton = Button.new()
	dropButton.text = "Drop"
	dropButton.theme = buttonTheme
	dropButton.add_theme_font_size_override("font_size", inventoryButtonFontSize)

	dropButton.pressed.connect(func() -> void: _onDropItem(itemId))
	row.add_child(dropButton)

	invList.add_child(row)


func _onUseItem(itemId: String) -> void:
	# Use one item and apply its effects.
	# prefer inventoryManager
	var invRef = saveLoadManagerRef.playerData.get("inventories", {}).get(currentInventoryName, {})
	if not invRef.has(itemId):
		return
	var raw = invRef[itemId]

	var itemDef = itemDb.getItem(itemId)

	var itemData = {}
	if typeof(raw) == TYPE_DICTIONARY:
		itemData = raw
	else:
		itemData = {"count": int(raw), "uses": itemDef.get("uses", 1)}

	var effects = itemDef.get("restore", itemDef.get("effects", {}))
	if not _canUseItem(effects):
		_showMessage("No need to use this right now.")
		return
	var appliedParts: Array = []
	for stat in effects.keys():
		var change = int(effects[stat])
		var old = int(saveLoadManagerRef.playerData["stats"].get(stat, 0))
		var newValue = clamp(old + change, 0, 100)
		saveLoadManagerRef.playerData["stats"][stat] = newValue
		var delta = newValue - old
		if delta != 0:
			var sign = "+" if delta > 0 else ""
			appliedParts.append("%s %s%d" % [str(stat).capitalize(), sign, delta])
	if appliedParts.size() > 0:
		_showToast(", ".join(appliedParts))

	itemData["uses"] = int(itemData.get("uses", 1)) - 1
	if itemData["uses"] <= 0:
		inventoryManagerRef.removeItem(currentInventoryName, itemId, 1)
	else:
		invRef[itemId] = itemData

	saveLoadManagerRef.saveGame()

	# refresh
	openInventory(currentInventoryName)


func _onDropItem(itemId: String) -> void:
	# Remove an item from the inventory.
	inventoryManagerRef.removeItem(currentInventoryName, itemId)

	_populateInventoryList()


# Shop UI creation & helpers
func _ensureShopPanel() -> void:
	# Cache shop UI nodes and item list containers.
	# do not create a complex runtime layout here; we map existing TSCN structure if present
	shopPanel = popupPanel.get_node("shopPanel")
	# make sure we have references to header labels and close button
	shopPanel.visible = false
	shopMoneyLabel = shopPanel.get_node("moneyLabel")
	totalExpenseLabel = shopPanel.get_node("expensesTotalLabel")
	shopCloseButton = shopPanel.get_node("closeButton")
	shopCloseButton.pressed.connect(closeShop)

	# map TabContainer item lists (common TSCN structure)
	shopTabContainer = shopPanel.get_node("TabContainer")
	shopLists.clear()
	# expecting tabs named feedTab, playTab, restTab, vetTab, cleanTab each containing itemList
	shopTabContainer.tab_changed.connect(_onShopTabChanged)
	for sectionName in shopSections:
		var tabNode = shopTabContainer.get_node(sectionName + "Tab")
		var listNode = tabNode.get_node("itemList")
		shopLists[sectionName] = listNode
	# fallback: single list path
	if shopLists.size() == 0:
		var single = shopPanel.get_node("VBoxContainer/ScrollContainer/itemList")
		shopLists["feed"] = single


# Shop open/close
func openShop(section: String = "feed") -> void:
	# Show the shop.
	currentShopSection = section
	popupPanel.visible = true
	shopPanel.visible = true
	_ensureEconomyData()
	populateShopItems(section)
	# Don't pause - shop can be used during gameplay
	_setThoughtSuppressed(true)
	_warnIfNearWeeklyLimit()
func _onShopTabChanged(tabIndex: int) -> void:
	# Switch shop list when the user changes tabs.
	if tabIndex >= 0 and tabIndex < shopSections.size():
		currentShopSection = shopSections[tabIndex]
		populateShopItems(currentShopSection)



func closeShop() -> void:
	# Close the shop.
	shopPanel.visible = false
	popupPanel.visible = false
	messageLabel.visible = false
	# Don't resume - game wasn't paused
	_setThoughtSuppressed(false)


func populateShopItems(section: String) -> void:
	# Fill the shop list for a section with buy buttons.
	# choose list
	var target = null
	if shopLists.has(section):
		target = shopLists[section]
	elif shopLists.has("feed"):
		target = shopLists["feed"]
	if target == null:
		return

	# clear children
	for child in target.get_children():
		child.queue_free()

	if not shopItems.has(section):
		var lbl = Label.new()
		lbl.text = "No items"
		target.add_child(lbl)
		return

	# font/theme
	var fontRes = pixelFontRes

	var labelTheme = Theme.new()
	labelTheme.set_font("font", "Label", fontRes)
	var buttonTheme = Theme.new()
	buttonTheme.set_font("font", "Button", fontRes)

	var species = str(saveLoadManagerRef.playerData.get("species", ""))
	var filteredItems: Array = []
	for itemDict in shopItems[section]:
		# Skip items that are only for a specific species
		if itemDict.has("species") and itemDict["species"] != species:
			continue
		filteredItems.append(itemDict)

	# Sort by price low to high
	filteredItems.sort_custom(func(a, b):
		return int(a.get("price", 0)) < int(b.get("price", 0))
	)

	if filteredItems.size() == 0:
		var emptyLabel = Label.new()
		emptyLabel.text = "No items"
		target.add_child(emptyLabel)
		return

	for itemDict in filteredItems:
		var id = itemDict.get("id", "")
		var price = int(itemDict.get("price", 0))
		var itemDef = itemDb.getItem(id)
		var restoreStats: Dictionary = itemDef.get("restore", {})
		var statsParts: Array = []
		for statName in restoreStats.keys():
			var value = int(restoreStats[statName])
			var sign = "+" if value >= 0 else ""
			statsParts.append("%s %s%d" % [statName.capitalize(), sign, value])
		var usesText = "uses: %d" % int(itemDef.get("uses", 1))
		var statsText = "No stats" if statsParts.size() == 0 else ", ".join(statsParts)

		var row = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = "%s — $%d | %s | %s" % [itemDef.get("name", id), price, statsText, usesText]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.theme = labelTheme
		# set font size override on the label if available
		lbl.add_theme_font_size_override("font_size", inventoryItemFontSize)
		row.add_child(lbl)
		var buyButton = Button.new()
		buyButton.text = "Buy"
		buyButton.theme = buttonTheme
		buyButton.add_theme_font_size_override("font_size", inventoryButtonFontSize)
		# bind item id, price, and the explicit section so buy action knows target inventory
		buyButton.pressed.connect(_buyShopItem.bind(id, price, section))
		row.add_child(buyButton)

		target.add_child(row)

	# update headers
	shopMoneyLabel.text = "Money: $" + str(int(saveLoadManagerRef.playerData.get("money", 0)))
	totalExpenseLabel.text = "Expenses: $" + str(int(saveLoadManagerRef.playerData.get("careExpenses", 0)))


# Buy item
func _buyShopItem(itemId: String, price: int, section: String) -> void:
	# Spend money, add the item, and refresh UI.
	# defensive checks
	_ensureEconomyData()

	var money = int(saveLoadManagerRef.playerData.get("money", 0))
	if money < price:
		_showMessage("Not enough money.")
		return

	var weeklyLimit = int(saveLoadManagerRef.playerData.get("weeklyLimit", weeklyLimitDefault))
	var weekTotal = _sumTransactions("expense", 7)
	if weeklyLimit > 0 and (weekTotal + price) > weeklyLimit:
		_showMessage("Weekly budget limit reached. Try chores or wait for a new week.")
		return

	# deduct money
	saveLoadManagerRef.playerData["money"] = money - price

	# totals
	saveLoadManagerRef.playerData["totalSpent"] = int(saveLoadManagerRef.playerData.get("totalSpent", 0)) + price
	if section == "feed" or section == "play" or section == "vet" or section == "clean":
		saveLoadManagerRef.playerData["careExpenses"] = int(saveLoadManagerRef.playerData.get("careExpenses", 0)) + price

	_logTransaction("expense", section, itemId, price, _getNeedsTag(section))

	# add to inventory (prefer inventory manager)
	# pass the explicit section so the item goes into the correct inventory bucket
	inventoryManagerRef.addItem(section, itemId, 1)

	# persist
	saveLoadManagerRef.saveGame()

	_showMessage("Purchased " + itemId + " for $" + str(price) + ".")

	populateShopItems(section)
	if inventoryPanel.visible:
		_populateInventoryList()
	updateValues()


# Start screen
func _onStartScreenPressed() -> void:
	# Forward to the start screen handler.
	startScene.onStartScreenPressed()
