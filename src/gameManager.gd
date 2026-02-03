extends Node

# TODO: change day length
# how many seconds a full in-game day lasts (5 minutes)
const DAY_LENGTH := 10.0

# how often stats automatically change (in seconds)
const STAT_TICK := 5.0


# keep track of the current day and how far we are into it
var current_day: int
var seconds_into_day: float = 0.0

# counts time for stat updates
var stat_accumulator: float = 0.0

# lets us speed up or slow down time if needed
var time_scale: float = 1.0

# if true, time stops and the game is frozen
var is_paused: bool = false


# lets other scripts know when a day has passed
signal day_passed(new_day: int)


func _ready() -> void:
	# load the current day from the save safely
	if saveLoadManager.playerData.has("day"):
		current_day = saveLoadManager.playerData["day"]
	else:
		current_day = 0
		saveLoadManager.playerData["day"] = 0


func _process(delta: float) -> void:
	# do nothing if the game is paused
	if is_paused:
		return

	# apply time scaling (for speed-up or slow-down later)
	var scaled_delta := delta * time_scale

	# advance time
	seconds_into_day += scaled_delta
	stat_accumulator += scaled_delta

	# update stats every STAT_TICK seconds
	if stat_accumulator >= STAT_TICK:
		# handle multiple ticks in case of lag
		var ticks := int(stat_accumulator / STAT_TICK)
		stat_accumulator -= ticks * STAT_TICK
		_update_stats(ticks)

	# check if one or more full days passed
	while seconds_into_day >= DAY_LENGTH:
		seconds_into_day -= DAY_LENGTH
		_advance_day()


# pauses the entire game (time, physics, animations, etc.)
func pause_game() -> void:
	if is_paused:
		return

	is_paused = true
	get_tree().paused = true


# resumes the game after being paused
func resume_game() -> void:
	if not is_paused:
		return

	is_paused = false
	get_tree().paused = false


# simple helper for toggling pause on/off
func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


# decreases stats over time
func _update_stats(ticks: int) -> void:
	var pd = saveLoadManager.playerData

	# make sure stats exist before touching them
	if not pd.has("stats"):
		return

	# decrease each stat once per tick
	for key in pd["stats"].keys():
		pd["stats"][key] -= 5 * ticks

	# clamp stats to valid ranges
	saveLoadManager.clampValues(pd)

	# save so progress isn't lost
	saveLoadManager.saveGame()


# moves the game forward by one day
func _advance_day() -> void:
	current_day += 1
	saveLoadManager.playerData["day"] = current_day

	# tell other systems a new day started
	emit_signal("day_passed", current_day)

	# apply daily effects
	_on_day_end()


# runs effects that happen once per day
func _on_day_end() -> void:
	var pd = saveLoadManager.playerData

	if not pd.has("stats"):
		return

	# example daily effects
	pd["stats"]["hunger"] -= 10
	pd["stats"]["energy"] = min(pd["stats"]["energy"] + 20, 100)

	# keep everything in range and save
	saveLoadManager.clampValues(pd)
	saveLoadManager.saveGame()


# returns how many seconds have passed in the current day
func get_seconds_into_day() -> int:
	return int(seconds_into_day)


# debug helper: max out all stats instantly
func allMax() -> void:
	var pd = saveLoadManager.playerData

	if not pd.has("stats"):
		return

	for key in pd["stats"].keys():
		pd["stats"][key] = 100

	saveLoadManager.saveGame()
