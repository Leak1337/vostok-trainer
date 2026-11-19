extends Node

signal finished(result: String, moved: bool)

const RETURN_ID := -1
const POI_GROUPS := {
	&"Well": "Brunnen", &"Fire": "Feuerstelle", &"Radio": "Funkgerät", &"NomadSpot": "Nomadenplatz",
}

var game_data: Resource
var _targets: Dictionary[int, Dictionary] = {}
var _return_map_id := 0
var _return_point := Vector3.ZERO
var _pending_id := 0
var _pending_cross_map := false

func _ready() -> void:
	set_physics_process(false)

func targets() -> Array[Dictionary]:
	_targets.clear()
	var result: Array[Dictionary] = []
	var map := get_node_or_null("/root/Map")
	var player := _player()
	if not map or not player:
		return result
	if _return_map_id == map.get_instance_id():
		result.append({"id": RETURN_ID, "title": "Letzte Position", "kind": "Zurück", "cross": false,
			"locked": false, "distance": player.global_position.distance_to(_return_point)})
	for trader in get_tree().get_nodes_in_group(&"Trader"):
		if _within_map(map, trader) and trader.is_visible_in_tree() and &"traderData" in trader:
			var data := trader.get(&"traderData") as Resource
			if data:
				_add_target(result, trader, "Händler", String(data.get(&"name")), player)
	for collider in get_tree().get_nodes_in_group(&"Transition"):
		if not _within_map(map, collider):
			continue
		var gate := collider.owner as Node3D
		if _within_map(map, gate) and &"nextMap" in gate and gate.has_method(&"Interact"):
			var destination := String(gate.get(&"nextMap"))
			if not destination.is_empty():
				_add_target(result, gate, "Übergang", destination, player, true)
	for group: StringName in POI_GROUPS:
		var number := 0
		for point in get_tree().get_nodes_in_group(group):
			if _within_map(map, point) and point.is_visible_in_tree() and not _targets.has(point.get_instance_id()):
				number += 1
				_add_target(result, point, "POI", POI_GROUPS[group], player, false, number)
	return result

func request(id: int, cross_map: bool) -> void:
	_pending_id = id
	_pending_cross_map = cross_map
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	set_physics_process(false)
	var player := _player()
	var map := get_node_or_null("/root/Map")
	if not player or not map:
		finished.emit("Teleport ist gerade nicht verfügbar.", false)
		return
	if _pending_id == RETURN_ID and _return_map_id == map.get_instance_id() and not _pending_cross_map:
		_teleport(map, player, _return_point, true)
		return
	var entry: Dictionary = _targets.get(_pending_id, {})
	var target: Node3D = entry.target.get_ref() if not entry.is_empty() else null
	if not _within_map(map, target) or not target.is_visible_in_tree():
		finished.emit("Dieses Ziel ist nicht mehr verfügbar.", false)
		return
	if _pending_cross_map:
		if not entry.cross or target.get(&"locked"):
			finished.emit("Der Übergang ist verschlossen.", false)
			return
		game_data.set(&"isTransitioning", true)
		target.call(&"Interact")
		finished.emit("Kartenwechsel gestartet.", true)
		return
	var anchor: Node3D = target.get(&"spawn") as Node3D if entry.cross else null
	_teleport(map, player, anchor.global_position if is_instance_valid(anchor) else target.global_position, is_instance_valid(anchor))

func _within_map(map: Node, target: Node) -> bool:
	return is_instance_valid(target) and target is Node3D and map.is_ancestor_of(target)

func _add_target(result: Array[Dictionary], target: Node3D, kind: String, title: String, player: Node3D, cross := false, number := 0) -> void:
	var id := target.get_instance_id()
	if _targets.has(id):
		return
	_targets[id] = {"target": weakref(target), "cross": cross}
	result.append({"id": id, "kind": kind, "title": title, "number": number, "cross": cross,
		"locked": cross and target.get(&"locked"), "distance": player.global_position.distance_to(target.global_position)})

func _player() -> CharacterBody3D:
	if not game_data:
		return null
	for flag in [&"isDead", &"isCaching", &"isTransitioning", &"isOccupied", &"isSleeping", &"freeze", &"vehicle", &"decor"]:
		if flag in game_data and game_data.get(flag):
			return null
	return get_node_or_null("/root/Map/Core/Controller") as CharacterBody3D

func _teleport(map: Node, player: CharacterBody3D, anchor: Vector3, exact: bool) -> void:
	var landing = _find_landing(player, anchor, exact)
	if landing == null:
		finished.emit("Kein freier Landeplatz am Ziel gefunden.", false)
		return
	_return_map_id = map.get_instance_id()
	_return_point = player.global_position
	player.global_position = landing
	player.velocity = Vector3.ZERO
	if &"lastVelocity" in player:
		player.set(&"lastVelocity", Vector3.ZERO)
	if &"fallStartLevel" in player:
		player.set(&"fallStartLevel", player.global_position.y)
	if &"isFalling" in game_data:
		game_data.set(&"isFalling", false)
	if &"playerPosition" in game_data:
		game_data.set(&"playerPosition", player.global_position)
	player.reset_physics_interpolation()
	finished.emit("Teleportiert.", true)

func _find_landing(player: CharacterBody3D, anchor: Vector3, exact: bool) -> Variant:
	var shape_node := player.get_node_or_null("Stand") as CollisionShape3D
	if not shape_node or not shape_node.shape or not player.get_world_3d():
		return null
	var space := player.get_world_3d().direct_space_state
	var bounds := Transform3D(shape_node.global_basis, Vector3.ZERO) * shape_node.shape.get_debug_mesh().get_aabb()
	var offset := shape_node.global_position - player.global_position
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = player.collision_mask
	ray.exclude = [player.get_rid()]
	var overlap := PhysicsShapeQueryParameters3D.new()
	overlap.shape = shape_node.shape
	overlap.collision_mask = player.collision_mask
	overlap.exclude = ray.exclude
	var direction := player.global_position - anchor
	direction.y = 0.0
	direction = direction.normalized() if direction.length_squared() > 0.01 else Vector3.FORWARD
	var samples := PackedVector3Array([anchor]) if exact else PackedVector3Array()
	for radius in [2.2, 3.8]:
		for step in [0, 1, -1, 2, -2, 3, -3, 4]:
			samples.append(anchor + direction.rotated(Vector3.UP, step * PI / 4.0) * radius)
	for point in samples:
		ray.from = point + Vector3.UP * 1.4
		ray.to = point - Vector3.UP * 3.0
		var hit := space.intersect_ray(ray)
		if hit.is_empty() or hit.normal.y < 0.72 or hit.collider is RigidBody3D:
			continue
		var center: Vector3 = hit.position + Vector3.UP * (0.10 - bounds.position.y)
		overlap.transform = Transform3D(shape_node.global_basis, center)
		if space.intersect_shape(overlap, 1).is_empty():
			return center - offset
	return null
