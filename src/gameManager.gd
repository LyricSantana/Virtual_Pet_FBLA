## Game manager
# This file runs the game clock and pet stat decay.
# It also handles autosave and day changes.

extends Node

const dayLength: float = 60.0    # seconds in a full in-game day
const statTick: float = 5.0       # how often to update pet stats (seconds)
const saveTick: float = 30.0      # how often to auto-save (seconds)

var currentDay: int = 0
var secondsIntoDay: float = 0.0

# accumulators so we can handle variable frame rates neatly
var statAccumulator: float = 0.0
var saveAccumulator: float = 0.0

var timeScale: float = 1.0
var isPaused: bool = false

# signal emitted when a day finishes
signal dayPassed(newDay: int)

var statDecayRates: Dictionary = {
	"hunger": 3,
	"happiness": 2,
	"energy": 2,
	"health": 1,
	"cleanliness": 2
}

func _ready() -> void:
	# Initialize game time from saved data.
	pauseGame()
	currentDay = int(saveLoadManager.playerData.get("day", 0))


func _process(delta: float) -> void:
	# Tick time, stats, autosave, and day changes.
	if isPaused:
		return

	# scale delta so UI time controls can speed/slow things
	var scaledDelta: float = delta * timeScale

	secondsIntoDay += scaledDelta
	statAccumulator += scaledDelta
	saveAccumulator += scaledDelta

	# Stat updates: run once per tick, handle multiple ticks if needed.
	if statAccumulator >= statTick:
		var ticks: int = int(statAccumulator / statTick)
		statAccumulator -= ticks * statTick
		_updateStats(ticks)

	# Auto-save: same pattern as stats.
	if saveAccumulator >= saveTick:
		var saves: int = int(saveAccumulator / saveTick)
		saveAccumulator -= saves * saveTick
		# call save in a loop to be explicit (usually saves == 1)
		for i in range(saves):
			saveLoadManager.saveGame()

	# Advance day if we've passed a full day (can happen multiple times).
	while secondsIntoDay >= dayLength:
		secondsIntoDay -= dayLength
		_advanceDay()


func pauseGame() -> void:
	# Pause the game and scene tree.
	if isPaused:
		return
	isPaused = true
	# pause the whole scene tree so animations/physics stop — this is what Godot expects
	get_tree().paused = true

func resumeGame() -> void:
	# Resume the game and scene tree.
	if not isPaused:
		return
	isPaused = false
	get_tree().paused = false

func togglePause() -> void:
	# Toggle pause state.
	if isPaused:
		resumeGame()
	else:
		pauseGame()


func _updateStats(ticks: int) -> void:
	# Apply stat decay each tick.
	var pd: Dictionary = saveLoadManager.playerData
	var stats: Dictionary = pd.get("stats", {})

	# Update each stat by its decay rate * number of ticks
	for statName in stats.keys():
		var decayPerTick: int = int(statDecayRates.get(statName, 1))
		var oldVal = int(stats.get(statName, 100))
		var newVal = oldVal - decayPerTick * ticks
		stats[statName] = newVal
	pd["stats"] = stats

	# Ensure values are in their allowed ranges
	saveLoadManager.clampValues(pd)

	# push new data to pet manager so animation/thoughts update
	petManager.setPlayerData(pd)


func _advanceDay() -> void:
	# Move to the next day and notify listeners.
	currentDay += 1

	# write day into playerData if available
	saveLoadManager.playerData["day"] = currentDay

	# emit a signal so other nodes can react (achievements, daily events, UI)
	emit_signal("dayPassed", currentDay)

	# run end-of-day logic
	_onDayEnd()


func _onDayEnd() -> void:
	# Apply daily effects and persist them.
	var pd: Dictionary = saveLoadManager.playerData
	var stats: Dictionary = pd.get("stats", {})

	# Example daily rules:
	# - Hunger: pets get hungrier overnight (-10)
	# - Energy: overnight rest recovers some energy (+20)
	stats["hunger"] = max(int(stats.get("hunger", 0)) - 10, 0)
	stats["energy"] = min(int(stats.get("energy", 0)) + 20, 100)
	pd["stats"] = stats

	# clamp again and save
	saveLoadManager.clampValues(pd)
	saveLoadManager.saveGame()


func getSecondsIntoDay() -> int:
	# Return the integer part for UI clocks.
	return int(secondsIntoDay)

func allMax() -> void:
	# Debug helper: set all stats to 100 and save.
	var pd: Dictionary = saveLoadManager.playerData
	var stats: Dictionary = pd.get("stats", {})
	for key in stats.keys():
		stats[key] = 100
	pd["stats"] = stats
	saveLoadManager.saveGame()
