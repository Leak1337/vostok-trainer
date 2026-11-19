extends RefCounted

const CONFIG_PATH := "user://VostokTrainerESP.cfg"
const BUILT_INS := {
	"Standard": {},
	"Quest": {"categories": {&"quest": true}, "options": {&"loot_overview": true}},
	"Waffen": {"categories": {&"weapons": true, &"ammo": true, &"attachments": true}},
	"Alles": {"options": {&"show_empty": true, &"loot_overview": true}},
}
const OPTIONS := [
	&"enemy_skeleton", &"enemy_lines", &"hide_enemy_distance", &"loot_overview",
	&"loot_lines", &"show_empty", &"rare_only", &"hide_loot_distance", &"search_only",
]
const DEFAULT_COLORS := {
	&"enemy": Color("ff8176"), &"loot": Color("80ebc8"), &"match": Color("52e3ef"),
}

var last: Dictionary = {}
var custom: Dictionary = {}

func read() -> void:
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_warning("[Vostok Trainer] ESP-Einstellungen konnten nicht geladen werden.")
		return
	var saved_last = config.get_value("esp", "last", {})
	var saved_custom = config.get_value("esp", "profiles", {})
	if saved_last is Dictionary:
		last = saved_last
	if saved_custom is Dictionary:
		for name in saved_custom:
			if name is String and not BUILT_INS.has(name) and saved_custom[name] is Dictionary:
				custom[name] = saved_custom[name]

func save() -> Error:
	var config := ConfigFile.new()
	config.set_value("esp", "last", last)
	config.set_value("esp", "profiles", custom)
	var pending := CONFIG_PATH + ".tmp"
	var error := config.save(pending)
	if error != OK:
		return error
	return DirAccess.rename_absolute(pending, CONFIG_PATH)
