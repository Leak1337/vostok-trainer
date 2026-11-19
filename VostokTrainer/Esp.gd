extends Node2D

const AI_SCRIPT := "res://Scripts/AI"
const PICKUP_SCRIPT := "res://Scripts/Pickup"
const ENEMY_COLOR := Color("ff8176")
const LOOT_COLOR := Color("80ebc8")
const NOMAD_FACTION := 0
const ENEMY_BOUNDS := AABB(Vector3(-0.36, 0.0, -0.36), Vector3(0.72, 1.85, 0.72))
const LOOT_BOUNDS := AABB(Vector3(-0.19, -0.06, -0.19), Vector3(0.38, 0.35, 0.38))
const MAX_MARKERS := 56

var distance_limit: float
var show_boxes := false
var show_lines := false

var _show_enemies := false
var _show_loot := false
var _targets: Dictionary[int, Node3D] = {}
var _map: Node


func _ready() -> void:
	set_process(false)


func set_modes(enemies: bool, loot: bool) -> void:
	var was_enabled := _show_enemies or _show_loot
	_show_enemies = enemies
	_show_loot = loot
	var enabled := enemies or loot
	if enabled and not was_enabled:
		get_tree().node_added.connect(_consider)
		get_tree().node_removed.connect(_forget)
		_refresh_map()
	elif was_enabled and not enabled:
		get_tree().node_added.disconnect(_consider)
		get_tree().node_removed.disconnect(_forget)
		_targets.clear()
		_map = null
	set_process(enabled)
	queue_redraw()


func _process(_delta: float) -> void:
	_refresh_map()
	queue_redraw()


func _refresh_map() -> void:
	var current_map := get_node_or_null("/root/Map")
	if not is_instance_valid(_map) and current_map == null:
		return
	if current_map == _map:
		return
	_map = current_map
	_targets.clear()
	if _map:
		for candidate in _map.find_children("*", "Node3D", true, false):
			_consider(candidate)


func _consider(node: Node) -> void:
	if node is not Node3D or not is_instance_valid(_map) or not _map.is_ancestor_of(node):
		return
	var script := node.get_script() as Script
	while script:
		var path := script.resource_path.get_basename()
		if path == AI_SCRIPT or path == PICKUP_SCRIPT:
			_targets[node.get_instance_id()] = node
			return
		script = script.get_base_script()


func _forget(node: Node) -> void:
	_targets.erase(node.get_instance_id())


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or not is_instance_valid(_map):
		return
	var screen := get_viewport_rect()
	var markers := _collect_markers(camera, screen.grow(-10.0))
	var line_start := Vector2(screen.get_center().x, screen.end.y - 14.0)
	for marker in markers:
		if show_lines:
			var line_color: Color = marker.color
			line_color.a = 0.56
			draw_line(line_start, marker.p, line_color, 1.25, true)
		if show_boxes:
			var bounds := _project_box(camera, marker.target, marker.enemy)
			if bounds.has_area():
				draw_rect(bounds, Color(0.02, 0.03, 0.04, 0.85), false, 3.0, true)
				draw_rect(bounds, marker.color, false, 1.25, true)
	_draw_labels(markers)


func _collect_markers(camera: Camera3D, screen: Rect2) -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	for target: Node3D in _targets.values():
		if not is_instance_valid(target) or target.is_queued_for_deletion() or not target.is_visible_in_tree():
			continue
		var enemy: bool = &"variant" in target
		var origin := target.global_position
		var distance := camera.global_position.distance_to(origin)
		if distance > distance_limit:
			continue
		var title: String
		var color: Color
		if enemy:
			if not _show_enemies or target.get(&"dead") or not target.get(&"active"):
				continue
			var variant: Resource = target.get(&"variant")
			if variant == null or variant.get(&"faction") == NOMAD_FACTION:
				continue
			title = str(variant.get(&"name"))
			color = ENEMY_COLOR
			origin.y += 1.85
		else:
			if not _show_loot or target.process_mode == Node.PROCESS_MODE_DISABLED:
				continue
			var collision: CollisionShape3D = target.get(&"collision")
			var slot: Resource = target.get(&"slotData")
			if collision == null or collision.disabled or slot == null:
				continue
			var item: Resource = slot.get(&"itemData")
			if item == null:
				continue
			title = str(item.get(&"name"))
			color = LOOT_COLOR
			origin.y += 0.18
		if camera.is_position_behind(origin):
			continue
		var point := camera.unproject_position(origin)
		if screen.has_point(point):
			markers.append({"p": point, "distance": distance, "text": title, "color": color, "target": target, "enemy": enemy})
	markers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance)
	if markers.size() > MAX_MARKERS:
		markers.resize(MAX_MARKERS)
	return markers


func _project_box(camera: Camera3D, target: Node3D, enemy: bool) -> Rect2:
	var bounds := ENEMY_BOUNDS if enemy else LOOT_BOUNDS
	var transform_3d := Transform3D(Basis.IDENTITY, target.global_position)
	if not enemy and &"mesh" in target:
		var mesh := target.get(&"mesh") as MeshInstance3D
		if is_instance_valid(mesh) and mesh.mesh:
			bounds = mesh.get_aabb()
			transform_3d = mesh.global_transform
	var top_left := Vector2(INF, INF)
	var bottom_right := Vector2(-INF, -INF)
	for index in range(8):
		var corner := transform_3d * bounds.get_endpoint(index)
		if camera.is_position_behind(corner):
			return Rect2()
		var point := camera.unproject_position(corner)
		top_left = top_left.min(point)
		bottom_right = bottom_right.max(point)
	var center := (top_left + bottom_right) * 0.5
	var size := (bottom_right - top_left).max(Vector2(9.0, 9.0))
	return Rect2(center - size * 0.5, size).grow(2.0).intersection(get_viewport_rect())


func _draw_labels(markers: Array[Dictionary]) -> void:
	var font := ThemeDB.fallback_font
	var occupied: Array[Rect2] = []
	for marker in markers:
		var text := "%s · %d m" % [marker.text, roundi(marker.distance)]
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var point: Vector2 = marker.p
		var box := Rect2(point.x - width * 0.5 - 5.0, point.y - 25.0, width + 10.0, 22.0)
		if occupied.any(func(other: Rect2) -> bool: return other.intersects(box)):
			continue
		occupied.append(box)
		draw_rect(box, Color(0.03, 0.06, 0.07, 0.86))
		draw_circle(point, 3.0, marker.color)
		draw_string(font, box.position + Vector2(5.0, 16.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, marker.color)
