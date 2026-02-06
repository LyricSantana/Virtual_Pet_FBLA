# gameManager.gd — refactored
# I'm a highschooler who actually tested this in the cafeteria lab.
# This file manages time, stat ticks, autosave, and day progression.

extends Node

# -------------------------
# Timing constants (tweak if demo too slow/fast)
# -------------------------
const DAY_LENGTH: float = 300.0    # seconds in a full in-game day
const STAT_TICK: float = 5.0       # how often to update pet stats (seconds)
const SAVE_TICK: float = 30.0      # how often to auto-save (seconds)

# -------------------------
# Game state
# -------------------------
var current_day: int = 0
var seconds_into_day: float = 0.0

# accumulators so we can handle variable frame rates neatly
var _stat_accumulator: float = 0.0
var _save_accumulator: float = 0.0

var time_scale: float = 1.0
var is_paused: bool = false

# signal emitted when a day finishes
signal day_passed(new_day: int)

# -------------------------
# Default per-stat decay per STAT_TICK
# -------------------------
var stat_decay_rates: Dictionary = {
	"hunger": 3,
	"happiness": 2,
	"energy": 2,
	"health": 1,
	"cleanliness": 2
}

# -------------------------
# Ready
# -------------------------
func _ready() -> void:
	# Try to pull the day from saved data if available.
	# If saveLoadManager isn't present as an autoload, this will fail silently.
	if typeof(saveLoadManager) != TYPE_NIL and saveLoadManager.playerData.has("day"):
		current_day = int(saveLoadManager.playerData.get("day", 0))
	# otherwise leave current_day = 0, which is fine for new games


# -------------------------
# Frame tick — handle time passing
# -------------------------
func _process(delta: float) -> void:
	if is_paused:
		return

	# scale delta so UI time controls can speed/slow things
	var scaled_delta: float = delta * time_scale

	seconds_into_day += scaled_delta
	_stat_accumulator += scaled_delta
	_save_accumulator += scaled_delta

	# --- Stat updates: run once per STAT_TICK, but handle multiple ticks if needed ---
	if _stat_accumulator >= STAT_TICK:
		var ticks: int = int(_stat_accumulator / STAT_TICK)
		_stat_accumulator -= ticks * STAT_TICK
		_update_stats(ticks)

	# --- Auto-save: same pattern as stats ---
	if _save_accumulator >= SAVE_TICK:
		var saves: int = int(_save_accumulator / SAVE_TICK)
		_save_accumulator -= saves * SAVE_TICK
		# call save in a loop to be explicit (usually saves == 1)
		for i in saves:
			if typeof(saveLoadManager) != TYPE_NIL:
				saveLoadManager.saveGame()

	# --- Advance day if we've passed a full day (can happen multiple times) ---
	while seconds_into_day >= DAY_LENGTH:
		seconds_into_day -= DAY_LENGTH
		_advance_day()


# -------------------------
# Pause controls
# -------------------------
func pause_game() -> void:
	if is_paused:
		return
	is_paused = true
	# pause the whole scene tree so animations/physics stop — this is what Godot expects
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


# -------------------------
# Stat updates (runs every STAT_TICK)
# -------------------------
func _update_stats(ticks: int) -> void:
	# quick safety: make sure saveLoadManager exists and has playerData
	if typeof(saveLoadManager) == TYPE_NIL:
		return
	var pd: Dictionary = saveLoadManager.playerData
	if not pd.has("stats"):
		return

	# Update each stat by its decay rate * number of ticks
	for stat_name in pd["stats"].keys():
		var decay_per_tick: int = int(stat_decay_rates.get(stat_name, 1))
		var old_val = int(pd["stats"].get(stat_name, 100))
		var new_val = old_val - decay_per_tick * ticks
		pd["stats"][stat_name] = new_val

	# Ensure values are in their allowed ranges
	saveLoadManager.clampValues(pd)

	# push new data to pet manager so animation/thoughts update
	if typeof(petManager) != TYPE_NIL and petManager.has_method("set_player_data"):
		petManager.set_player_data(pd)


# -------------------------
# Day progression
# -------------------------
func _advance_day() -> void:
	current_day += 1

	# write day into playerData if available
	if typeof(saveLoadManager) != TYPE_NIL:
		saveLoadManager.playerData["day"] = current_day

	# emit a signal so other nodes can react (achievements, daily events, UI)
	emit_signal("day_passed", current_day)

	# run end-of-day logic
	_on_day_end()


func _on_day_end() -> void:
	# Apply daily effects and persist them. Keep changes simple and obvious.
	if typeof(saveLoadManager) == TYPE_NIL:
		return
	var pd: Dictionary = saveLoadManager.playerData
	if not pd.has("stats"):
		return

	# Example daily rules:
	# - Hunger: pets get hungrier overnight (-10)
	# - Energy: overnight rest recovers some energy (+20)
	pd["stats"]["hunger"] = max(int(pd["stats"].get("hunger", 0)) - 10, 0)
	pd["stats"]["energy"] = min(int(pd["stats"].get("energy", 0)) + 20, 100)

	# clamp again and save
	saveLoadManager.clampValues(pd)
	saveLoadManager.saveGame()


# -------------------------
# Utility helpers
# -------------------------
func get_seconds_into_day() -> int:
	# return the integer part — useful for UIs showing a clock
	return int(seconds_into_day)

# debug / testing helper — set all stats to max and save
func allMax() -> void:
	if typeof(saveLoadManager) == TYPE_NIL:
		return
	var pd: Dictionary = saveLoadManager.playerData
	if not pd.has("stats"):
		return
	for key in pd["stats"].keys():
		pd["stats"][key] = 100
	saveLoadManager.saveGame()
