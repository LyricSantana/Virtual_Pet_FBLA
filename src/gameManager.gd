extends Node

# how long a full in-game day lasts in seconds (5 minutes)
const DAY_LENGTH := 300.0

# how often stats automatically change (seconds)
const STAT_TICK := 5.0

# how often the game auto-saves (seconds)
const SAVE_TICK := 30.0

# current day and seconds passed in the day
var current_day: int
var seconds_into_day: float = 0.0

# accumulators for ticking stats and saving
var stat_accumulator: float = 0.0
var save_accumulator: float = 0.0

# speed control for time (1.0 = normal speed)
var time_scale: float = 1.0

# whether the game is paused
var is_paused: bool = false

# signal emitted whenever a day passes
signal day_passed(new_day: int)


func _ready() -> void:
	# initialize current day from save, default 0
	if saveLoadManager.playerData.has("day"):
		current_day = int(saveLoadManager.playerData["day"])
	else:
		current_day = 0
		saveLoadManager.playerData["day"] = current_day


func _process(delta: float) -> void:
	# do nothing while paused
	if is_paused:
		return

	# scale delta by time speed
	var scaled_delta = delta * time_scale
	seconds_into_day += scaled_delta
	stat_accumulator += scaled_delta
	save_accumulator += scaled_delta

	# handle stat updates (support multiple ticks if lagged)
	if stat_accumulator >= STAT_TICK:
		var ticks = int(stat_accumulator / STAT_TICK)
		stat_accumulator -= ticks * STAT_TICK
		_update_stats(ticks)

	# handle auto-save
	if save_accumulator >= SAVE_TICK:
		var ticks = int(save_accumulator / SAVE_TICK)
		save_accumulator -= ticks * SAVE_TICK
		saveLoadManager.saveGame()
		print(ticks)

	# advance day if enough time has passed
	while seconds_into_day >= DAY_LENGTH:
		seconds_into_day -= DAY_LENGTH
		_advance_day()


# pause the whole game using engine pause
func pause_game() -> void:
	if is_paused:
		return
	is_paused = true
	get_tree().paused = true


# resume the game
func resume_game() -> void:
	if not is_paused:
		return
	is_paused = false
	get_tree().paused = false


# toggle pause state
func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


# update stats each tick
func _update_stats(ticks: int) -> void:
	var pd = saveLoadManager.playerData
	if not pd.has("stats"):
		return

	# decrease global player stats
	for key in pd["stats"].keys():
		pd["stats"][key] = pd["stats"].get(key, 0) - (5 * ticks)

	# decrease stats for the current pet
	var pet_id = pd.get("current_pet", "")
	if pet_id != "":
		var pet = petManager.get_pet(pet_id)
		if pet:
			for stat_key in pet["stats"].keys():
				pet["stats"][stat_key] = clamp(pet["stats"].get(stat_key, 0) - (5 * ticks), 0, 100)

	# clamp all global stats to valid ranges
	saveLoadManager.clampValues(pd)


# advance the day by 1
func _advance_day() -> void:
	current_day += 1
	saveLoadManager.playerData["day"] = current_day
	emit_signal("day_passed", current_day)
	_on_day_end()


# apply daily effects at the end of the day
func _on_day_end() -> void:
	var pd = saveLoadManager.playerData
	if not pd.has("stats"):
		return

	# example global effects: hunger decreases, energy recovers
	pd["stats"]["hunger"] = pd["stats"].get("hunger", 0) - 10
	pd["stats"]["energy"] = min(pd["stats"].get("energy", 0) + 20, 100)

	# effects for the current pet
	var pet_id = pd.get("current_pet", "")
	if pet_id != "":
		var pet = petManager.get_pet(pet_id)
		if pet:
			pet["stats"]["hunger"] = max(pet["stats"].get("hunger", 0) - 5, 0)
			pet["stats"]["energy"] = min(pet["stats"].get("energy", 0) + 10, 100)

	saveLoadManager.clampValues(pd)
	saveLoadManager.saveGame()


# return how many whole seconds have passed in the current day
func get_seconds_into_day() -> int:
	return int(seconds_into_day)


# debug helper: fill every stat to max (100)
func allMax() -> void:
	var pd = saveLoadManager.playerData
	if not pd.has("stats"):
		return
	for key in pd["stats"].keys():
		pd["stats"][key] = 100
	saveLoadManager.saveGame()
