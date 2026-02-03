extends Node

const DAY_LENGTH := 300.0 # seconds (5 minutes)

var current_day: int = saveLoadManager.playerData.get("day", 0)
var seconds_into_day: float = 0.0
var time_scale: float = 1.0
var is_paused: bool = false

signal day_passed(new_day: int)

func _process(delta: float) -> void:
	if is_paused:
		return

	seconds_into_day += delta * time_scale
	if seconds_into_day >= DAY_LENGTH:
		_advance_day()


func _advance_day() -> void:
	seconds_into_day = 0
	current_day += 1
	emit_signal("day_passed", current_day)
	_on_day_end()
	


func _on_day_end() -> void:
	# Example daily effects
	saveLoadManager.playerData["day"] = current_day
	saveLoadManager.playerData["hunger"] -= 10
	saveLoadManager.playerData["energy"] = min(
		saveLoadManager.playerData["energy"] + 20,
		100
	)

	saveLoadManager.saveGame()


func get_seconds_into_day() -> float:
	return seconds_into_day
