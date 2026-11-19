extends Node

const CATALOG_PATH := "res://Loot/LT_Master.tres"
const SLOT_DATA_PATH := "res://Scripts/SlotData.gd"
const MAX_SPAWN := 10

var game_data: Resource
var _catalog: Dictionary[String, Resource] = {}
var _loaded := false

func available() -> bool:
	return _inventory() != null

func catalog() -> Array[Resource]:
	if not _loaded:
		_loaded = true
		if ResourceLoader.exists(CATALOG_PATH):
			var table := load(CATALOG_PATH) as Resource
			if table and &"items" in table:
				for item in table.get(&"items"):
					if item == null or not item.get(&"tetris") is PackedScene:
						continue
					var file: String = item.get(&"file")
					if not file.is_empty():
						_catalog[file] = item
	var entries: Array[Resource] = []
	entries.assign(_catalog.values())
	entries.sort_custom(func(a: Resource, b: Resource) -> bool:
		return String(a.get(&"name")).nocasecmp_to(String(b.get(&"name"))) < 0
	)
	return entries

func add_items(file: String, count: int) -> int:
	var inventory := _inventory()
	if not inventory or not _catalog.has(file) or not ResourceLoader.exists(SLOT_DATA_PATH):
		return -1
	var slot_script := load(SLOT_DATA_PATH) as GDScript
	if not slot_script or not slot_script.can_instantiate():
		return -1
	var grid: Node = inventory.get(&"inventoryGrid")
	var item := _catalog[file]
	var added := 0
	for index in clampi(count, 1, MAX_SPAWN):
		var slot: Resource = slot_script.new()
		slot.set(&"itemData", item)
		if item.get(&"subtype") != "Magazine":
			slot.set(&"amount", maxi(int(item.get(&"defaultAmount")), 0))
		if not inventory.call(&"Create", slot, grid, false):
			break
		added += 1
	if added > 0:
		inventory.call(&"UpdateStats", true)
	return added

func _inventory() -> Node:
	if not game_data or game_data.get(&"isDead") or game_data.get(&"isCaching") or game_data.get(&"isTransitioning") or game_data.get(&"isOccupied"):
		return null
	var inventory := get_node_or_null("/root/Map/Core/UI/Interface")
	if inventory and inventory.is_node_ready() and inventory.has_method(&"Create") and inventory.has_method(&"UpdateStats"):
		if (&"inventoryGrid" in inventory and is_instance_valid(inventory.get(&"inventoryGrid"))
				and (not (&"itemDragged" in inventory) or not is_instance_valid(inventory.get(&"itemDragged")))):
			return inventory
	return null
