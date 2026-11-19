extends Node

const EXTRA_CAPACITY_MULTIPLIER := 5.0
const INJURIES := [&"bleeding", &"fracture", &"burn", &"poisoning", &"rupture", &"headshot"]

var game_data: Resource
var _inventory: Node
var _original_capacity: float
var _boosted_capacity: float

func can_heal() -> bool:
	return can_update_player() and has_node("/root/Map/Core/Controller/Character")

func heal() -> void:
	if not can_heal():
		return
	game_data.set(&"health", 100.0)
	game_data.set(&"oxygen", 100.0)
	clear_injuries(get_node("/root/Map/Core/Controller/Character"))

func can_update_player() -> bool:
	return game_data != null and not game_data.get(&"isDead") and not game_data.get(&"isCaching") and not game_data.get(&"isTransitioning")

func clear_injuries(character: Node) -> void:
	for condition in INJURIES:
		if game_data.get(condition):
			character.call(String(condition).capitalize(), false)

func set_carry_boost(enabled: bool) -> void:
	if enabled:
		ensure_carry_boost()
	else:
		_restore_capacity(true)

func ensure_carry_boost() -> void:
	if is_instance_valid(_inventory) and _inventory.is_inside_tree():
		return
	_restore_capacity(false)
	if not can_update_player():
		return
	var inventory := get_node_or_null("/root/Map/Core/UI/Interface")
	if not inventory or not inventory.is_node_ready() or not (&"baseCarryWeight" in inventory) or not inventory.has_method(&"UpdateStats"):
		return
	_inventory = inventory
	_original_capacity = float(_inventory.get(&"baseCarryWeight"))
	_boosted_capacity = _original_capacity * EXTRA_CAPACITY_MULTIPLIER
	_inventory.set(&"baseCarryWeight", _boosted_capacity)
	_inventory.call(&"UpdateStats", true)

func _restore_capacity(refresh: bool) -> void:
	if is_instance_valid(_inventory) and is_equal_approx(float(_inventory.get(&"baseCarryWeight")), _boosted_capacity):
		_inventory.set(&"baseCarryWeight", _original_capacity)
		if refresh and _inventory.is_inside_tree() and can_update_player():
			_inventory.call(&"UpdateStats", true)
	_inventory = null

func _exit_tree() -> void:
	_restore_capacity(false)
