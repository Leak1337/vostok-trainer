extends Node2D

const LootFilter = preload("LootFilter.gd")
const EnemySkeleton = preload("EnemySkeleton.gd")

enum Kind { ENEMY, PICKUP, CONTAINER }

const SCRIPTS := {
	"res://Scripts/AI": Kind.ENEMY,
	"res://Scripts/Pickup": Kind.PICKUP,
	"res://Scripts/LootContainer": Kind.CONTAINER,
}
const ENEMY_COLOR := Color("ff8176")
const LOOT_COLOR := Color("80ebc8")
const CONTAINER_COLOR := Color("9bd5ff")
const QUEST_COLOR := Color("ffda70")
const LABEL_BACKGROUND := Color(0.03, 0.06, 0.07, 0.90)
const MAX_MARKERS := 56

var enemy_distance: float
var loot_distance: float
var filter := LootFilter.new()

var _options: Dictionary[StringName, bool] = {}
var _targets: Dictionary[int, Dictionary] = {}
var _skeleton_links: Dictionary[int, PackedInt32Array] = {}
var _map: Node
var _quest_refresh := 0.0

func _ready() -> void:
	set_process(false)

func set_option(id: StringName, enabled: bool) -> void:
	var was_active := _active()
	_options[id] = enabled
	if id == &"rare_only":
		filter.rare_only = enabled
	if id in [&"loot_esp", &"container_esp"] and enabled:
		_quest_refresh = 0.0
	var active := _active()
	if active and not was_active:
		get_tree().node_added.connect(_consider)
		get_tree().node_removed.connect(_forget)
		_refresh_map()
	elif was_active and not active:
		get_tree().node_added.disconnect(_consider)
		get_tree().node_removed.disconnect(_forget)
		_targets.clear()
		_skeleton_links.clear()
		_map = null
	set_process(active)
	queue_redraw()

func _active() -> bool:
	return _options.get(&"enemy_esp", false) or _loot_active()

func _loot_active() -> bool:
	return _options.get(&"loot_esp", false) or _options.get(&"container_esp", false)

func _process(delta: float) -> void:
	_refresh_map()
	if _loot_active():
		_quest_refresh -= delta
		if _quest_refresh <= 0.0:
			_quest_refresh = 2.0
			var loader := get_node_or_null("/root/Loader")
			if loader and loader.has_method(&"LoadTaskNotes"):
				filter.set_task_notes(loader.call(&"LoadTaskNotes"))
	queue_redraw()

func _refresh_map() -> void:
	var current_map := get_node_or_null("/root/Map")
	if not is_instance_valid(_map) and current_map == null:
		return
	if current_map == _map:
		return
	_map = current_map
	_targets.clear()
	_skeleton_links.clear()
	_quest_refresh = 0.0
	if _map:
		for candidate in _map.find_children("*", "Node3D", true, false):
			_consider(candidate)

func _consider(node: Node) -> void:
	if node is not Node3D or not is_instance_valid(_map) or not _map.is_ancestor_of(node):
		return
	var script := node.get_script() as Script
	while script:
		var path := script.resource_path.get_basename()
		if SCRIPTS.has(path):
			_targets[node.get_instance_id()] = {"target": node, "kind": SCRIPTS[path]}
			return
		script = script.get_base_script()

func _forget(node: Node) -> void:
	var id := node.get_instance_id()
	if _targets.erase(id):
		_skeleton_links.erase(id)

func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or not is_instance_valid(_map):
		return
	var screen := get_viewport_rect()
	var markers := _collect_markers(camera, screen.grow(-10.0))
	var line_start := Vector2(screen.get_center().x, screen.end.y - 14.0)
	for marker in markers:
		var enemy: bool = marker.kind == Kind.ENEMY
		if _options.get(&"enemy_lines" if enemy else &"loot_lines", false):
			var color: Color = marker.color
			color.a = 0.56
			draw_line(line_start, marker.p, color, 1.25, true)
		if enemy and _options.get(&"enemy_skeleton", false):
			_draw_skeleton(camera, marker.target, marker.color)
	_draw_labels(markers)
	if _options.get(&"loot_overview", false):
		_draw_loot_overview(markers, screen)

func _collect_markers(camera: Camera3D, screen: Rect2) -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	for entry: Dictionary in _targets.values():
		var target: Node3D = entry.target
		if not is_instance_valid(target) or target.is_queued_for_deletion() or not target.is_visible_in_tree():
			continue
		var kind: Kind = entry.kind
		var origin := target.global_position
		var distance := camera.global_position.distance_to(origin)
		if distance > (enemy_distance if kind == Kind.ENEMY else loot_distance):
			continue
		origin.y += [1.85, 0.18, 0.45][kind]
		if camera.is_position_behind(origin):
			continue
		var point := camera.unproject_position(origin)
		if not screen.has_point(point):
			continue
		var info: Dictionary
		match kind:
			Kind.ENEMY: info = _enemy_info(target)
			Kind.PICKUP: info = _pickup_info(target)
			Kind.CONTAINER: info = _container_info(target)
		if info.is_empty():
			continue
		info.merge({"p": point, "distance": distance, "kind": kind, "target": target})
		markers.append(info)
	markers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.get("quest", false) != b.get("quest", false):
			return a.get("quest", false)
		return a.distance < b.distance
	)
	if markers.size() > MAX_MARKERS:
		markers.resize(MAX_MARKERS)
	return markers

func _enemy_info(target: Node3D) -> Dictionary:
	if not _options.get(&"enemy_esp", false) or target.get(&"dead") or not target.get(&"active"):
		return {}
	var variant: Resource = target.get(&"variant")
	if variant == null or (variant.get(&"faction") == 0 and not _options.get(&"show_nomads", false)):
		return {}
	return {"text": str(variant.get(&"name")), "color": ENEMY_COLOR}

func _pickup_info(target: Node3D) -> Dictionary:
	if not _options.get(&"loot_esp", false) or target.process_mode == Node.PROCESS_MODE_DISABLED:
		return {}
	var collision := target.get(&"collision") as CollisionShape3D
	if collision == null or collision.disabled:
		return {}
	var item := _item_info(target.get(&"slotData"))
	if item.is_empty():
		return {}
	item.color = QUEST_COLOR if item.quest else LOOT_COLOR
	return item

func _container_info(container: Node3D) -> Dictionary:
	if not _options.get(&"container_esp", false) or container.process_mode == Node.PROCESS_MODE_DISABLED:
		return {}
	if container.get(&"corpse"):
		var parent := container.get_parent()
		while parent and parent != _map:
			if &"variant" in parent and &"dead" in parent:
				if not parent.get(&"dead"):
					return {}
				break
			parent = parent.get_parent()
	var slots: Array = container.get(&"storage") if container.get(&"storaged") else container.get(&"loot")
	var details: Array[String] = []
	var quests: Array[String] = []
	for slot in slots:
		var item := _item_info(slot)
		if item.is_empty():
			continue
		if item.quest:
			quests.append(item.text)
		else:
			details.append(item.text)
	if details.is_empty() and quests.is_empty() and (not slots.is_empty() or not _options.get(&"show_empty", false)):
		return {}
	var title := str(container.get(&"containerName")).strip_edges()
	if title.is_empty():
		title = "Behälter"
	if container.get(&"locked"):
		title += " (verschlossen)"
	if slots.is_empty():
		title += " · leer"
	else:
		title += " · %d" % (details.size() + quests.size())
	quests.append_array(details)
	var has_quest := not quests.is_empty() and quests[0].begins_with("[Quest] ")
	return {"text": title, "color": QUEST_COLOR if has_quest else CONTAINER_COLOR, "quest": has_quest, "details": quests}

func _item_info(slot: Resource) -> Dictionary:
	if not slot:
		return {}
	var item := slot.get(&"itemData") as Resource
	if item == null:
		return {}
	var category := filter.category_of(item)
	if not filter.accepts(item, category):
		return {}
	var quest := category == &"quest"
	var title := ("[Quest] " if quest else "") + str(item.get(&"name"))
	if item.get(&"showAmount") and int(slot.get(&"amount")) > 1:
		title += " ×%d" % int(slot.get(&"amount"))
	return {"text": title, "quest": quest}

func _draw_skeleton(camera: Camera3D, target: Node3D, color: Color) -> void:
	var skeleton := target.get(&"skeleton") as Skeleton3D
	if not is_instance_valid(skeleton):
		return
	var id := target.get_instance_id()
	if not _skeleton_links.has(id):
		_skeleton_links[id] = EnemySkeleton.build_links(skeleton)
	var segments := EnemySkeleton.project_links(skeleton, _skeleton_links[id], camera)
	if not segments.is_empty():
		draw_multiline(segments, Color(0.02, 0.03, 0.04, 0.90), 3.5, true)
		draw_multiline(segments, color, 1.6, true)

func _title(marker: Dictionary) -> String:
	var hide_distance := &"hide_enemy_distance" if marker.kind == Kind.ENEMY else &"hide_loot_distance"
	return marker.text if _options.get(hide_distance, false) else "%s · %d m" % [marker.text, roundi(marker.distance)]

func _summary(details: Array, limit: int) -> String:
	var summary := ", ".join(details.slice(0, limit))
	if details.size() > limit:
		summary += " +%d" % (details.size() - limit)
	return summary

func _draw_labels(markers: Array[Dictionary]) -> void:
	var font := ThemeDB.fallback_font
	var occupied: Array[Rect2] = []
	for marker in markers:
		var text := _title(marker)
		var detail := _summary(marker.get("details", []), 2)
		var width := maxf(font.get_string_size(text, 0, -1, 15).x, font.get_string_size(detail, 0, -1, 13).x)
		width = minf(width, 360.0)
		var height := 22.0 if detail.is_empty() else 39.0
		var point: Vector2 = marker.p
		var box := Rect2(point.x - width * 0.5 - 5.0, point.y - height - 3.0, width + 10.0, height)
		if occupied.any(func(other: Rect2) -> bool: return other.intersects(box)):
			continue
		occupied.append(box)
		draw_rect(box, LABEL_BACKGROUND)
		draw_circle(point, 3.0, marker.color)
		draw_string(font, box.position + Vector2(5.0, 16.0), text, HORIZONTAL_ALIGNMENT_LEFT, width, 15, marker.color)
		if not detail.is_empty():
			draw_string(font, box.position + Vector2(5.0, 33.0), detail, HORIZONTAL_ALIGNMENT_LEFT, width, 13, marker.color)

func _draw_loot_overview(markers: Array[Dictionary], screen: Rect2) -> void:
	var focus := screen.grow_individual(-screen.size.x * 0.32, -screen.size.y * 0.28, -screen.size.x * 0.32, -screen.size.y * 0.28)
	var nearby := markers.filter(func(marker: Dictionary) -> bool: return marker.kind != Kind.ENEMY and focus.has_point(marker.p))
	if nearby.is_empty():
		return
	var center := screen.get_center()
	nearby.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return center.distance_squared_to(a.p) < center.distance_squared_to(b.p)
	)
	var font := ThemeDB.fallback_font
	var width := minf(390.0, screen.size.x * 0.40)
	var rows := mini(nearby.size(), 5)
	var detail_limit := clampi(int((screen.size.y - 265.0) / 17.0), 0, 10)
	var focused_details: Array = nearby[0].get("details", [])
	var detail_rows := mini(focused_details.size(), detail_limit)
	var top_left := Vector2(screen.end.x - width - 20.0, 56.0)
	draw_rect(Rect2(top_left, Vector2(width, rows * 30.0 + detail_rows * 17.0 + 32.0)), LABEL_BACKGROUND)
	draw_string(font, top_left + Vector2(12.0, 20.0), "Loot in Blickrichtung", HORIZONTAL_ALIGNMENT_LEFT, width - 24.0, 15, Color.WHITE)
	var row := top_left + Vector2(12.0, 43.0)
	for index in rows:
		var marker: Dictionary = nearby[index]
		var title := _title(marker)
		if index == 0 and focused_details.size() > detail_rows:
			title += " · +%d weitere" % (focused_details.size() - detail_rows)
		draw_string(font, row, title, HORIZONTAL_ALIGNMENT_LEFT, width - 24.0, 14, marker.color)
		row.y += 20.0
		if index == 0:
			for detail_index in detail_rows:
				var detail: String = focused_details[detail_index]
				var detail_color := QUEST_COLOR if detail.begins_with("[Quest] ") else LOOT_COLOR
				draw_string(font, row + Vector2(8.0, 0.0), detail, HORIZONTAL_ALIGNMENT_LEFT, width - 32.0, 13, detail_color)
				row.y += 17.0
		row.y += 10.0
