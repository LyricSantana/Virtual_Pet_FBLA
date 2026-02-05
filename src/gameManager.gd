extends Node

# --- Timing constants ---
const DAY_LENGTH := 300.0        # full in-game day in seconds
const STAT_TICK := 5.0           # how often stats update (seconds)
const SAVE_TICK := 30.0          # auto-save interval (seconds)

# --- Game state ---
var current_day: int
var seconds_into_day: float = 0.0
var stat_accumulator: float = 0.0
var save_accumulator: float = 0.0
var time_scale: float = 1.0
var is_paused: bool = false

# signal for day passed
signal day_passed(new_day: int)

# --- Per-stat decay per STAT_TICK ---
var stat_decay_rates: Dictionary = {
	"hunger": 3,       # hunger decays faster
	"happiness": 2,
	"energy": 2,
	"health": 1,
	"cleanliness": 2
}

func _ready() -> void:
	current_day = saveLoadManager.playerData.get("day", 0)

func _process(delta: float) -> void:
	if is_paused:
		return

	var scaled_delta = delta * time_scale
	seconds_into_day += scaled_delta
	stat_accumulator += scaled_delta
	save_accumulator += scaled_delta

	# --- Stat tick updates ---
	if stat_accumulator >= STAT_TICK:
		var ticks = int(stat_accumulator / STAT_TICK)
		stat_accumulator -= ticks * STAT_TICK
		_update_stats(ticks)

	# --- Auto-save ---
	if save_accumulator >= SAVE_TICK:
		var ticks = int(save_accumulator / SAVE_TICK)
		save_accumulator -= ticks * SAVE_TICK
		saveLoadManager.saveGame()

	# --- Advance day if necessary ---
	while seconds_into_day >= DAY_LENGTH:
		seconds_into_day -= DAY_LENGTH
		_advance_day()


# --- Pause/resume ---
func pause_game() -> void:
	if is_paused:
		return
	is_paused = true
	get_tree().paused = true

func resume_game() -> void:
	if not is_paused:
		return
	is_paused = false
	get_tree().paused = false

func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


# --- Update player stats ---
func _update_stats(ticks: int) -> void:
	var pd = saveLoadManager.playerData
	if not pd.has("stats"):
		return

	for stat_name in pd["stats"].keys():
		var decay = stat_decay_rates.get(stat_name, 1)
		pd["stats"][stat_name] = pd["stats"].get(stat_name, 100) - decay * ticks

	saveLoadManager.clampValues(pd)

	# --- Update pet animation automatically ---
	if petManager and petManager.has_method("update_pet_animation"):
		petManager.set_player_data(pd)


# --- Daily progression ---
func _advance_day() -> void:
	current_day += 1
	saveLoadManager.playerData["day"] = current_day
	emit_signal("day_passed", current_day)
	_on_day_end()

func _on_day_end() -> void:
	var pd = saveLoadManager.playerData
	if not pd.has("stats"):
		return

	# Daily effects example: hunger drops, energy recovers
	pd["stats"]["hunger"] = max(pd["stats"].get("hunger", 0) - 10, 0)
	pd["stats"]["energy"] = min(pd["stats"].get("energy", 0) + 20, 100)

	saveLoadManager.clampValues(pd)
	saveLoadManager.saveGame()


# --- Utility ---
func get_seconds_into_day() -> int:
	return int(seconds_into_day)

func allMax() -> void:
	var pd = saveLoadManager.playerData
	if not pd.has("stats"):
		return
	for key in pd["stats"].keys():
		pd["stats"][key] = 100
	saveLoadManager.saveGame()
