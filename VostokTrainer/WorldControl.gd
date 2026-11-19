extends Node

const WEATHER := {
	"Neutral": "Klar", "Overcast": "Bewölkt", "Rain": "Regen", "Storm": "Sturm",
	"Fog": "Nebel", "Wind": "Wind", "Aurora": "Polarlicht",
}

var _frozen_simulation: Node
var _previous_rate: float

func simulation() -> Node:
	var sim := get_node_or_null("/root/Simulation")
	if sim and &"time" in sim and &"rate" in sim and &"weather" in sim and &"weatherTime" in sim:
		return sim
	return null

func available() -> bool:
	return has_node("/root/Map") and simulation() != null

func set_time(minutes: int) -> void:
	if available():
		var minutes_today := clampi(minutes, 0, 1439)
		var hours := floori(minutes_today / 60.0)
		simulation().set(&"time", float(hours * 100 + minutes_today % 60))

func set_weather(weather: String) -> void:
	if available() and WEATHER.has(weather):
		var sim := simulation()
		sim.set(&"weather", weather)
		sim.set(&"weatherTime", 600.0)

func set_clock_frozen(enabled: bool) -> void:
	if not enabled:
		_restore_rate()
	elif available() and not is_instance_valid(_frozen_simulation):
		_frozen_simulation = simulation()
		_previous_rate = float(_frozen_simulation.get(&"rate"))
		_frozen_simulation.set(&"rate", 0.0)

func _exit_tree() -> void:
	_restore_rate()

func _restore_rate() -> void:
	if is_instance_valid(_frozen_simulation) and _frozen_simulation.get(&"rate") == 0.0:
		_frozen_simulation.set(&"rate", _previous_rate)
	_frozen_simulation = null

static func display_minutes(value: float) -> int:
	var hour := floori(value / 100.0)
	var minute := int(value) % 100
	return ((hour + 1) % 24) * 60 if minute >= 60 else hour * 60 + minute
