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

const ITEM_THEME_PATH: String = "res://assets/themes/inventory_theme.tres"
var itemTheme: Theme

# --- Font size constants (tweak these)
const INVENTORY_ITEM_FONT_SIZE: int = 10
const INVENTORY_BUTTON_FONT_SIZE: int = 10

const NAME_MIN_LEN: int = 2
const NAME_MAX_LEN: int = 12
const EXPENSE_LOG_LIMIT: int = 200
const WEEKLY_LIMIT_DEFAULT: int = 120
const SAVINGS_GOAL_DEFAULT: int = 100
const CHORE_SAVINGS_RATE: float = 0.2
const DAILY_CHORE_COUNT: int = 3

const CHORES: Array = [
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
const SHOP_SECTIONS: Array = ["feed", "play", "rest", "vet", "clean"]

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

# Startup
func _ready() -> void:
	# Set up references, buttons, and initial UI state.
	# resolve managers
	if typeof(gameManager) != TYPE_NIL:
		gameManagerRef = gameManager
	else:
		gameManagerRef = get_tree().get_root().get_node_or_null("Main/gameManager")

	if typeof(saveLoadManager) != TYPE_NIL:
		saveLoadManagerRef = saveLoadManager
	else:
		saveLoadManagerRef = get_tree().get_root().get_node_or_null("Main/saveLoadManager")

	if typeof(inventoryManager) != TYPE_NIL:
		inventoryManagerRef = inventoryManager
	else:
		inventoryManagerRef = get_tree().get_root().get_node_or_null("Main/inventoryManager")

	if typeof(itemDB) != TYPE_NIL:
		itemDb = itemDB
	else:
		itemDb = get_tree().get_root().get_node_or_null("Main/itemDB")

	if typeof(petManager) != TYPE_NIL:
		petManagerRef = petManager
	else:
		petManagerRef = get_tree().get_root().get_node_or_null("Main/pet")

	startScene = get_tree().get_root().get_node_or_null("Main/start")
	if startScene == null:
		startScene = get_tree().get_root().get_node_or_null("Main/startLayer/start")

	# initial visibility
	popupPanel.visible = false
	changeName.visible = false
	inventoryPanel.visible = false
	settingsPopup.visible = false
	helpPanel.visible = false
	reportPanel.visible = false
	chorePanel.visible = false
	messageLabel.visible = false

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
	_setHelpText()

	# optional theme
	if FileAccess.file_exists(ITEM_THEME_PATH):
		itemTheme = load(ITEM_THEME_PATH)

	if FileAccess.file_exists("res://assets/fonts/pixelFont.ttf"):
		pixelFontRes = load("res://assets/fonts/pixelFont.ttf")

	# ensure shop panel exists or map nodes
	_ensureShopPanel()


# Connect buttons recursively
func _connectButtons(node: Node) -> void:
	# Hook up TextureButtons so clicks go to one handler.
	for child in node.get_children():
		if child is TextureButton:
			# bind the child and pass it into handler
			child.pressed.connect(onButtonPressed.bind(child))
		# recurse into children
		_connectButtons(child)


# Update UI values
func _process(delta: float) -> void:
	# Keep UI values updated every frame.
	updateValues()


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

func settingsPressed() -> void:
	# Open settings and pause the game.
	showPopup()
	gameManagerRef.pauseGame()
	settingsPopup.visible = true
	petManagerRef.setThoughtVisible(false)


func backPressed() -> void:
	# Close all popups and resume gameplay.
	popupPanel.visible = false
	changeName.visible = false
	inventoryPanel.visible = false
	settingsPopup.visible = false
	shopPanel.visible = false
	helpPanel.visible = false
	reportPanel.visible = false
	chorePanel.visible = false
	messageLabel.visible = false

	gameManagerRef.resumeGame()
	petManagerRef.setThoughtVisible(true)


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
	if trimmed.length() < NAME_MIN_LEN or trimmed.length() > NAME_MAX_LEN:
		return "Name must be %d-%d characters." % [NAME_MIN_LEN, NAME_MAX_LEN]
	var regex = RegEx.new()
	regex.compile("^[A-Za-z ]+$")
	if regex.search(trimmed) == null:
		return "Use letters and spaces only."
	return ""


func _setHelpText() -> void:
	# Centralize the help copy so it is easy to edit later.
	if helpTextLabel == null:
		return
	helpTextLabel.text = "Core stats: Hunger, Energy, Cleanliness, Health, Happiness (0-100).\n
		Time passes and stats slowly drop. Low stats change the pet's mood/thoughts.\n
		Care actions: Use items from Feed, Play, Rest, Vet, Clean to restore stats.\n
		Items cost money. Purchases add to Expenses and count toward a weekly limit.\n
		Chores earn money once per day; part of each reward goes to Savings.\n
		Reports show today/week totals, category breakdown, and savings progress."


func _showMessage(text: String) -> void:
	# Show a short message in the popup area.
	if messageLabel == null:
		return
	messageLabel.text = text
	messageLabel.visible = true


func _ensureEconomyData() -> void:
	# Guarantee required economy keys exist in player data.
	if saveLoadManagerRef == null:
		return
	var pd = saveLoadManagerRef.playerData
	if not pd.has("expenses"):
		pd["expenses"] = []
	if not pd.has("weeklyLimit"):
		pd["weeklyLimit"] = WEEKLY_LIMIT_DEFAULT
	if not pd.has("savingsGoal"):
		pd["savingsGoal"] = SAVINGS_GOAL_DEFAULT
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
	var weeklyLimit = int(pd.get("weeklyLimit", WEEKLY_LIMIT_DEFAULT))
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
		"sec": int(gameManagerRef.getSecondsIntoDay()) if gameManagerRef else 0,
		"kind": kind,
		"category": category,
		"item": itemId,
		"amount": amount,
		"tag": tag
	}
	expenses.append(entry)
	if expenses.size() > EXPENSE_LOG_LIMIT:
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
	var weeklyLimit = int(pd.get("weeklyLimit", WEEKLY_LIMIT_DEFAULT))
	if reportStatsLabel != null:
		reportStatsLabel.text = "Today: -$%d  +$%d | Week: -$%d  +$%d | Limit: $%d" % [
			todayExpense, todayIncome, weekExpense, weekIncome, weeklyLimit
		]

	var breakdown = _buildCategoryBreakdown(7)
	var parts: Array = []
	for category in breakdown.keys():
		parts.append("%s $%d" % [category.capitalize(), int(breakdown[category])])
	if parts.size() == 0:
		parts.append("No expenses yet")
	if reportBreakdownLabel != null:
		reportBreakdownLabel.text = "Breakdown: " + ", ".join(parts)

	var savingsSaved = int(pd.get("savingsSaved", 0))
	var savingsGoal = int(pd.get("savingsGoal", SAVINGS_GOAL_DEFAULT))
	var percent = 0
	if savingsGoal > 0:
		percent = int(round(100.0 * float(savingsSaved) / float(savingsGoal)))
	if reportSavingsLabel != null:
		reportSavingsLabel.text = "Savings: $%d / $%d (%d%%)" % [savingsSaved, savingsGoal, percent]

	_refreshRecentList()


func _refreshRecentList() -> void:
	# Show the last few transactions for the demo report.
	if reportRecentList == null:
		return
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
		if pixelFontRes:
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
	petManagerRef.setThoughtVisible(false)


func closeHelp() -> void:
	# Close help and resume gameplay.
	backPressed()


func openReport() -> void:
	# Open the care report.
	showPopup()
	reportPanel.visible = true
	_refreshReport()
	gameManagerRef.pauseGame()
	petManagerRef.setThoughtVisible(false)


func closeReport() -> void:
	# Close report and resume gameplay.
	backPressed()


func openChores() -> void:
	# Open chores for earning coins.
	showPopup()
	chorePanel.visible = true
	_refreshChorePanel()
	gameManagerRef.pauseGame()
	petManagerRef.setThoughtVisible(false)


func closeChores() -> void:
	# Close chores and resume gameplay.
	backPressed()


func _resetChoresIfNewDay() -> void:
	# Clear daily chore completion when the day changes.
	var pd = saveLoadManagerRef.playerData
	var chores = pd.get("chores", {"lastDay": -1, "done": [], "available": []})
	var today = int(pd.get("day", 0))
	if int(chores.get("lastDay", -1)) != today:
		chores["lastDay"] = today
		chores["done"] = []
		chores["available"] = _rollDailyChores()
	elif int(chores.get("available", []).size()) == 0:
		chores["available"] = _rollDailyChores()
	pd["chores"] = chores


func _rollDailyChores() -> Array:
	# Pick a random set of chores for the day.
	var ids: Array = []
	for chore in CHORES:
		ids.append(str(chore.get("id", "")))
	ids.shuffle()
	var count = min(DAILY_CHORE_COUNT, ids.size())
	return ids.slice(0, count)


func _getChoreById(choreId: String) -> Dictionary:
	# Find a chore definition by id.
	for chore in CHORES:
		if str(chore.get("id", "")) == choreId:
			return chore
	return {}


func _refreshChorePanel() -> void:
	# Populate chore buttons and status.
	_ensureEconomyData()
	_resetChoresIfNewDay()
	for child in choreList.get_children():
		child.queue_free()
	var choresData: Dictionary = saveLoadManagerRef.playerData.get("chores", {})
	var done: Array = choresData.get("done", [])
	var available: Array = choresData.get("available", [])
	for choreId in available:
		var chore = _getChoreById(str(choreId))
		if chore.is_empty():
			continue
		var btn = Button.new()
		btn.text = "%s (+$%d)" % [str(chore.get("label", "Chore")), int(chore.get("reward", 0))]
		if pixelFontRes:
			btn.add_theme_font_override("font", pixelFontRes)
			btn.add_theme_font_size_override("font_size", 12)
		if done.has(chore.get("id", "")):
			btn.disabled = true
		btn.pressed.connect(func() -> void: _completeChore(chore))
		choreList.add_child(btn)

	if choreInfoLabel != null:
		if available.size() == 0:
			choreInfoLabel.text = "No chores today."
		elif done.size() >= available.size():
			choreInfoLabel.text = "All chores completed today."
		else:
			choreInfoLabel.text = "Complete chores to earn money and savings. (%d/%d)" % [done.size(), available.size()]


func _completeChore(chore: Dictionary) -> void:
	# Award coins for a chore and log it.
	_ensureEconomyData()
	_resetChoresIfNewDay()
	var pd = saveLoadManagerRef.playerData
	var chores = pd.get("chores", {"lastDay": -1, "done": [], "available": []})
	var done: Array = chores.get("done", [])
	var available: Array = chores.get("available", [])
	var choreId = str(chore.get("id", ""))
	if not available.has(choreId):
		_showMessage("This chore is not available today.")
		return
	if done.has(choreId):
		_showMessage("Chore already done today.")
		return
	if choreId != "":
		done.append(choreId)
		chores["done"] = done
		pd["chores"] = chores

	var reward = int(chore.get("reward", 0))
	var savingsCut = int(round(float(reward) * CHORE_SAVINGS_RATE))
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
	gameManagerRef.pauseGame()
	petManagerRef.setThoughtVisible(false)


func _onInvClosePressed() -> void:
	# Close inventory and resume gameplay.
	inventoryPanel.visible = false
	popupPanel.visible = false
	messageLabel.visible = false
	gameManagerRef.resumeGame()
	petManagerRef.setThoughtVisible(true)


func _populateInventoryList() -> void:
	# Fill the inventory list UI from saved data.
	# clear children
	for child in invList.get_children():
		child.queue_free()
	# load font if available
	var fontRes = null
	if FileAccess.file_exists("res://assets/fonts/pixelFont.ttf"):
		fontRes = load("res://assets/fonts/pixelFont.ttf")

	# get inventory
	var inv: Dictionary = inventoryManagerRef.getInventory(currentInventoryName)

	if inv.size() == 0:
		var label = Label.new()
		label.text = "Empty"
		if fontRes:
			# apply font and size overrides directly on label
			label.add_theme_font_override("font", fontRes)
			label.add_theme_font_size_override("font_size", INVENTORY_ITEM_FONT_SIZE)
		invList.add_child(label)
		return

	var labelTheme = null
	var buttonTheme = null
	if fontRes:
		labelTheme = Theme.new()
		labelTheme.set_font("font", "Label", fontRes)
		buttonTheme = Theme.new()
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
	if labelTheme:
		nameLabel.theme = labelTheme
	else:
		# if no theme, still try to apply font resource & size directly (attempt)
		if FileAccess.file_exists("res://assets/fonts/pixelFont.ttf"):
			var f = load("res://assets/fonts/pixelFont.ttf")
			nameLabel.add_theme_font_override("font", f)
			nameLabel.add_theme_font_size_override("font_size", INVENTORY_ITEM_FONT_SIZE)
	# always set size override if possible
	if FileAccess.file_exists("res://assets/fonts/pixelFont.ttf"):
		var f2 = load("res://assets/fonts/pixelFont.ttf")
		nameLabel.add_theme_font_override("font", f2)
		nameLabel.add_theme_font_size_override("font_size", INVENTORY_ITEM_FONT_SIZE)

	row.add_child(nameLabel)

	var useButton = Button.new()
	useButton.text = "Use"
	if buttonTheme:
		useButton.theme = buttonTheme
	else:
		if FileAccess.file_exists("res://assets/fonts/pixelFont.ttf"):
			var fb = load("res://assets/fonts/pixelFont.ttf")
			useButton.add_theme_font_override("font", fb)
			useButton.add_theme_font_size_override("font_size", INVENTORY_BUTTON_FONT_SIZE)
	# ensure size override if theme present
	if FileAccess.file_exists("res://assets/fonts/pixelFont.ttf"):
		var fb2 = load("res://assets/fonts/pixelFont.ttf")
		useButton.add_theme_font_override("font", fb2)
		useButton.add_theme_font_size_override("font_size", INVENTORY_BUTTON_FONT_SIZE)

	useButton.pressed.connect(func() -> void: _onUseItem(itemId))
	row.add_child(useButton)

	var dropButton = Button.new()
	dropButton.text = "Drop"
	if buttonTheme:
		dropButton.theme = buttonTheme
	else:
		if FileAccess.file_exists("res://assets/fonts/pixelFont.ttf"):
			var fb3 = load("res://assets/fonts/pixelFont.ttf")
			dropButton.add_theme_font_override("font", fb3)
			dropButton.add_theme_font_size_override("font_size", INVENTORY_BUTTON_FONT_SIZE)
	# ensure size override if theme present
	if FileAccess.file_exists("res://assets/fonts/pixelFont.ttf"):
		var fb4 = load("res://assets/fonts/pixelFont.ttf")
		dropButton.add_theme_font_override("font", fb4)
		dropButton.add_theme_font_size_override("font_size", INVENTORY_BUTTON_FONT_SIZE)

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
	if saveLoadManagerRef.playerData.has("stats"):
		for stat in effects.keys():
			var change = int(effects[stat])
			var old = int(saveLoadManagerRef.playerData["stats"].get(stat, 0))
			saveLoadManagerRef.playerData["stats"][stat] = clamp(old + change, 0, 100)

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
	if popupPanel == null:
		return

	var existing = popupPanel.get_node_or_null("shopPanel")
	if existing and existing is Panel:
		shopPanel = existing
	else:
		# do not create a complex runtime layout here; we map existing TSCN structure if present
		shopPanel = existing
	# make sure we have references to header labels and close button
	if shopPanel != null:
		shopPanel.visible = false
		shopMoneyLabel = shopPanel.get_node_or_null("moneyLabel")
		totalExpenseLabel = shopPanel.get_node_or_null("expensesTotalLabel")
		shopCloseButton = shopPanel.get_node_or_null("closeButton")
		if shopCloseButton != null:
			shopCloseButton.pressed.connect(closeShop)

		# map TabContainer item lists (common TSCN structure)
		shopTabContainer = shopPanel.get_node_or_null("TabContainer")
		shopLists.clear()
		# expecting tabs named feedTab, playTab, restTab, vetTab, cleanTab each containing itemList
		if shopTabContainer != null:
			shopTabContainer.tab_changed.connect(_onShopTabChanged)
			for sectionName in SHOP_SECTIONS:
				var tabNode = shopTabContainer.get_node_or_null(sectionName + "Tab")
				if tabNode != null:
					var listNode = tabNode.get_node_or_null("itemList")
					if listNode != null and listNode is VBoxContainer:
						shopLists[sectionName] = listNode
		# fallback: single list path
		if shopLists.size() == 0:
			var single = shopPanel.get_node_or_null("VBoxContainer/ScrollContainer/itemList")
			if single != null and single is VBoxContainer:
				shopLists["feed"] = single


# Shop open/close
func openShop(section: String = "feed") -> void:
	# Show the shop and pause gameplay.
	currentShopSection = section
	popupPanel.visible = true
	shopPanel.visible = true
	_ensureEconomyData()
	populateShopItems(section)
	gameManagerRef.pauseGame()
	petManagerRef.setThoughtVisible(false)
	_warnIfNearWeeklyLimit()
func _onShopTabChanged(tabIndex: int) -> void:
	# Switch shop list when the user changes tabs.
	if tabIndex >= 0 and tabIndex < SHOP_SECTIONS.size():
		currentShopSection = SHOP_SECTIONS[tabIndex]
		populateShopItems(currentShopSection)



func closeShop() -> void:
	# Close the shop and resume gameplay.
	shopPanel.visible = false
	popupPanel.visible = false
	messageLabel.visible = false
	gameManagerRef.resumeGame()
	petManagerRef.setThoughtVisible(true)


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
	var fontRes = null
	if FileAccess.file_exists("res://assets/fonts/pixelFont.ttf"):
		fontRes = load("res://assets/fonts/pixelFont.ttf")

	var labelTheme = null
	var buttonTheme = null
	if fontRes:
		labelTheme = Theme.new()
		labelTheme.set_font("font", "Label", fontRes)
		buttonTheme = Theme.new()
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
		var itemDef = {}
		if itemDb != null and itemDb.has_method("getItem"):
			itemDef = itemDb.getItem(id)
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
		if labelTheme:
			lbl.theme = labelTheme
			# set font size override on the label if available
			lbl.add_theme_font_size_override("font_size", INVENTORY_ITEM_FONT_SIZE)
		else:
			if fontRes:
				lbl.add_theme_font_override("font", fontRes)
				lbl.add_theme_font_size_override("font_size", INVENTORY_ITEM_FONT_SIZE)
		row.add_child(lbl)
		var buyButton = Button.new()
		buyButton.text = "Buy"
		if buttonTheme:
			buyButton.theme = buttonTheme
			buyButton.add_theme_font_size_override("font_size", INVENTORY_BUTTON_FONT_SIZE)
		else:
			if fontRes:
				buyButton.add_theme_font_override("font", fontRes)
				buyButton.add_theme_font_size_override("font_size", INVENTORY_BUTTON_FONT_SIZE)
		# bind item id, price, and the explicit section so buy action knows target inventory
		buyButton.pressed.connect(_buyShopItem.bind(id, price, section))
		row.add_child(buyButton)

		target.add_child(row)

	# update headers
	if shopMoneyLabel != null:
		shopMoneyLabel.text = "Money: $" + str(int(saveLoadManagerRef.playerData.get("money", 0)))
	if totalExpenseLabel != null:
		totalExpenseLabel.text = "Expenses: $" + str(int(saveLoadManagerRef.playerData.get("careExpenses", 0)))


# Buy item
func _buyShopItem(itemId: String, price: int, section: String) -> void:
	# Spend money, add the item, and refresh UI.
	# defensive checks
	if saveLoadManagerRef == null:
		push_warning("saveLoadManagerRef missing; cannot complete purchase.")
		return

	_ensureEconomyData()

	var money = int(saveLoadManagerRef.playerData.get("money", 0))
	if money < price:
		_showMessage("Not enough money.")
		return

	var weeklyLimit = int(saveLoadManagerRef.playerData.get("weeklyLimit", WEEKLY_LIMIT_DEFAULT))
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
	if inventoryManagerRef != null and inventoryManagerRef.has_method("addItem"):
		# pass the explicit section so the item goes into the correct inventory bucket
		inventoryManagerRef.addItem(section, itemId, 1)
	else:
		# fallback: write into playerData inventories directly and handle numeric/dict entries
		var invs = saveLoadManagerRef.playerData.get("inventories", {})
		if not invs.has(section):
			invs[section] = {}
		var inv = invs[section]
		if inv.has(itemId):
			var entry = inv[itemId]
			if typeof(entry) == TYPE_DICTIONARY:
				entry["count"] = int(entry.get("count", 0)) + 1
				inv[itemId] = entry
			else:
				inv[itemId] = int(entry) + 1
		else:
			# determine uses from itemDb if available
			var uses = 1
			if itemDb != null and itemDb.has_method("getItem"):
				var def = itemDb.getItem(itemId)
				uses = int(def.get("uses", 1))
			if uses > 1:
				inv[itemId] = {"count": 1, "uses": uses}
			else:
				inv[itemId] = 1
		saveLoadManagerRef.playerData["inventories"] = invs

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
