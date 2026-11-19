extends RefCounted

const PATH := "user://VostokTrainerWaypoints.cfg"

var _maps: Dictionary = {}

func load_waypoints() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		var saved = config.get_value("waypoints", "maps", {})
		if saved is Dictionary:
			_maps = saved

func points(map_key: String) -> Dictionary:
	var saved = _maps.get(map_key)
	var result: Dictionary = {}
	if saved is Dictionary:
		for name in saved:
			if name is String and saved[name] is Vector3 and saved[name].is_finite():
				result[name] = saved[name]
	return result

func update(map_key: String, points_on_map: Dictionary) -> bool:
	var next := _maps.duplicate()
	if points_on_map.is_empty():
		next.erase(map_key)
	else:
		next[map_key] = points_on_map
	var config := ConfigFile.new()
	config.set_value("waypoints", "maps", next)
	if config.save(PATH + ".tmp") != OK or DirAccess.rename_absolute(PATH + ".tmp", PATH) != OK:
		return false
	_maps = next
	return true
