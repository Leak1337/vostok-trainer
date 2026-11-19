extends RefCounted

const CATEGORIES := {
	&"weapons": "Waffen & Granaten",
	&"ammo": "Munition & Magazine",
	&"attachments": "Waffenzubehör",
	&"food": "Essen & Trinken",
	&"medical": "Medizin",
	&"gear": "Kleidung & Ausrüstung",
	&"electronics": "Elektronik",
	&"keys": "Schlüssel",
	&"quest": "Quest-Gegenstände",
	&"other": "Sonstiges",
}

const FOLDERS := {
	"Weapons": &"weapons", "Grenades": &"weapons", "Knives": &"weapons",
	"Ammo": &"ammo", "Attachments": &"attachments",
	"Consumables": &"food", "Medical": &"medical",
	"Armor": &"gear", "Backpacks": &"gear", "Belts": &"gear",
	"Clothing": &"gear", "Helmets": &"gear", "Rigs": &"gear",
	"Electronics": &"electronics", "Keys": &"keys",
}

const ITEM_TYPES := {
	"weapon": &"weapons", "grenade": &"weapons", "knife": &"weapons",
	"ammo": &"ammo", "attachment": &"attachments", "attachments": &"attachments",
	"food": &"food", "drink": &"food", "consumable": &"food", "consumables": &"food",
	"medical": &"medical", "medicine": &"medical", "meds": &"medical",
	"armor": &"gear", "backpack": &"gear", "belt": &"gear", "clothing": &"gear",
	"helmet": &"gear", "rig": &"gear", "gear": &"gear",
	"electronics": &"electronics", "key": &"keys", "keys": &"keys",
}

var rare_only := false
var _disabled: Dictionary[StringName, bool] = {}
var _quest_items: Dictionary[String, bool] = {}


func set_category(category: StringName, enabled: bool) -> void:
	_disabled[category] = not enabled


func set_task_notes(notes: Array) -> void:
	_quest_items.clear()
	for task in notes:
		if not task is Resource or not (&"deliver" in task):
			continue
		for item in task.get(&"deliver"):
			if item is Resource:
				var file := str(item.get(&"file"))
				if not file.is_empty() and file != "<null>":
					_quest_items[file] = true


func category_of(item: Resource) -> StringName:
	var kind := str(item.get(&"type")).to_lower()
	if kind in ["quest", "task"] or _quest_items.has(str(item.get(&"file"))):
		return &"quest"
	if str(item.get(&"subtype")).to_lower() == "magazine":
		return &"ammo"
	var path := item.resource_path
	if path.begins_with("res://Items/"):
		var folder := path.get_slice("/", 3)
		if FOLDERS.has(folder):
			return FOLDERS[folder]
	return ITEM_TYPES.get(kind, &"other")


func accepts(item: Resource, category: StringName) -> bool:
	if _disabled.get(category, false):
		return false
	# Godot's game enum is Common, Rare, Legendary, Null.
	return not rare_only or category == &"quest" or item.get(&"rarity") in [1, 2]
