extends Node2D

const LootFilter = preload("LootFilter.gd")
const EnemySkeleton = preload("EnemySkeleton.gd")
const EspProfiles = preload("EspProfiles.gd")

enum Kind { AI, PICKUP, CONTAINER, TRADER, CAT, GATHERING_NOMAD }

const SCRIPTS := {
	"res://Scripts/AI": Kind.AI,
	"res://Scripts/Pickup": Kind.PICKUP,
	"res://Scripts/LootContainer": Kind.CONTAINER,
	"res://Scripts/Trader": Kind.TRADER,
	"res://Scripts/Cat": Kind.CAT,
	"res://Scripts/NomadAnim": Kind.GATHERING_NOMAD,
}
const MARKER_HEIGHTS := [1.85, 0.18, 0.45, 1.75, 0.48, 1.4]
const TRADER_COLOR := Color("6ce8f6")
const NPC_COLOR := Color("b6ed92")
const CONTAINER_COLOR := Color("9bd5ff")
const QUEST_COLOR := Color("ffda70")
const WEAPON_COLOR := Color("ffac72")
const RARE_COLOR := Color("86beff")
const LEGENDARY_COLOR := Color("f2a0ff")
const LABEL_BACKGROUND := Color(0.03, 0.06, 0.07, 0.90)
const MAX_MARKERS := 56
const MAX_CANDIDATES := 96
const SCAN_INTERVAL := 0.10
const RARITY_LABELS := {
	LootFilter.Rarity.COMMON: "Gewöhnlich",
	LootFilter.Rarity.RARE: "Selten",
	LootFilter.Rarity.LEGENDARY: "Legendär",
}

var enemy_distance: float
var loot_distance: float
var filter := LootFilter.new()
var _marker_colors := EspProfiles.DEFAULT_COLORS.duplicate()

var _options: Dictionary[StringName, bool] = {}
var _targets: Dictionary[int, Dictionary] = {}
var _skeleton_links: Dictionary[int, PackedInt32Array] = {}
var _candidates: Array[Dictionary] = []
var _map: Node
var _quest_refresh := 0.0
var _scan_delay := 0.0

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
		_candidates.clear()
		_map = null
	set_process(active)
	invalidate_targets()
	queue_redraw()

func set_loot_category(category: StringName, enabled: bool) -> void:
	filter.set_category(category, enabled)
	invalidate_targets()

func set_search(query: String, watchlist: String, matches_only: bool) -> void:
	filter.set_search(query, watchlist, matches_only)
	invalidate_targets()

func set_marker_color(category: StringName, color: Color) -> void:
	_marker_colors[category] = color
	invalidate_targets()

func invalidate_targets() -> void:
	_scan_delay = 0.0

func _active() -> bool:
	return _options.get(&"enemy_esp", false) or _options.get(&"trader_esp", false) or _options.get(&"npc_esp", false) or _loot_active()

func _loot_active() -> bool:
	return _options.get(&"loot_esp", false) or _options.get(&"container_esp", false)

func _process(delta: float) -> void:
	var had_candidates := not _candidates.is_empty()
	_scan_delay -= delta
	_quest_refresh -= delta
	if _scan_delay <= 0.0:
		_scan_delay = SCAN_INTERVAL
		_refresh_map()
		if _loot_active() and _quest_refresh <= 0.0:
			_quest_refresh = 2.0
			var loader := get_node_or_null("/root/Loader")
			if loader and loader.has_method(&"LoadTaskNotes"):
				filter.set_task_notes(loader.call(&"LoadTaskNotes"))
		var camera := get_viewport().get_camera_3d()
		if camera and is_instance_valid(_map):
			_scan_targets(camera, get_viewport_rect().grow(96.0))
		else:
			_candidates.clear()
	if had_candidates or not _candidates.is_empty():
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
	_candidates.clear()
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
		if _options.get(&"enemy_lines" if marker.actor else &"loot_lines", false):
			var color: Color = marker.color
			color.a = 0.56
			draw_line(line_start, marker.p, color, 1.25, true)
		if marker.kind == Kind.AI and _options.get(&"enemy_skeleton", false):
			_draw_skeleton(camera, marker.target, marker.color, marker.distance)
	_draw_labels(markers)
	if _options.get(&"loot_overview", false):
		_draw_loot_overview(markers, screen)

func _scan_targets(camera: Camera3D, screen: Rect2) -> void:
	_candidates.clear()
	var position := camera.global_position
	var npc_enabled: bool = _options.get(&"npc_esp", false)
	var ai_enabled: bool = _options.get(&"enemy_esp", false) or npc_enabled
	var enabled: Array[bool] = [ai_enabled, _options.get(&"loot_esp", false), _options.get(&"container_esp", false),
		_options.get(&"trader_esp", false), npc_enabled, npc_enabled]
	for id in _targets:
		var entry: Dictionary = _targets[id]
		var kind: Kind = entry.kind
		if not enabled[kind]:
			continue
		var target: Node3D = entry.target
		if not is_instance_valid(target) or target.is_queued_for_deletion() or not target.is_visible_in_tree():
			continue
		var actor := kind != Kind.PICKUP and kind != Kind.CONTAINER
		var origin := target.global_position
		var limit := enemy_distance if actor else loot_distance
		var distance_squared := position.distance_squared_to(origin)
		if distance_squared > limit * limit:
			continue
		origin.y += MARKER_HEIGHTS[kind]
		if camera.is_position_behind(origin):
			continue
		var point := camera.unproject_position(origin)
		if not screen.has_point(point):
			continue
		var info: Dictionary = {}
		match kind:
			Kind.AI: info = _ai_info(target)
			Kind.PICKUP: info = _pickup_info(target)
			Kind.CONTAINER: info = _container_info(target)
			Kind.TRADER: info = _trader_info(target)
			Kind.GATHERING_NOMAD: info = _nomad_info(target)
			Kind.CAT:
				var cat_data := target.get(&"gameData") as Resource
				if not cat_data or not cat_data.get(&"catDead"):
					info = {"text": "Katze", "color": NPC_COLOR}
		if info.is_empty():
			continue
		info.merge({"p": point, "distance": sqrt(distance_squared), "actor": actor, "kind": kind, "target": target})
		_candidates.append(info)
	_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.get("matched", false) != b.get("matched", false):
			return a.get("matched", false)
		if a.get("quest", false) != b.get("quest", false):
			return a.get("quest", false)
		return a.distance < b.distance
	)
	if _candidates.size() > MAX_CANDIDATES:
		_candidates.resize(MAX_CANDIDATES)
	var font := ThemeDB.fallback_font
	for info in _candidates:
		info["title"] = _title(info)
		var contents: Array = info.get("details", [])
		var preview := contents.slice(0, 2)
		var width := font.get_string_size(info.title, 0, -1, 15).x
		for item: Dictionary in preview:
			width = maxf(width, font.get_string_size(item.text, 0, -1, 13).x)
		info["preview"] = preview
		info["width"] = minf(width, 360.0)

func _collect_markers(camera: Camera3D, screen: Rect2) -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	for marker in _candidates:
		var target: Node3D = marker.target
		if not is_instance_valid(target) or not target.is_visible_in_tree() or target.is_queued_for_deletion():
			continue
		var origin: Vector3 = target.global_position + Vector3.UP * MARKER_HEIGHTS[marker.kind]
		if camera.is_position_behind(origin):
			continue
		var point := camera.unproject_position(origin)
		if screen.has_point(point):
			marker.p = point
			markers.append(marker)
			if markers.size() == MAX_MARKERS:
				break
	return markers

func _ai_info(target: Node3D) -> Dictionary:
	if target.get(&"dead") or not target.get(&"active"):
		return {}
	var variant: Resource = target.get(&"variant")
	if variant == null:
		return {}
	if variant.get(&"faction") == 0:
		if not _options.get(&"npc_esp", false):
			return {}
		return _nomad_info(target)
	if not _options.get(&"enemy_esp", false):
		return {}
	return {"text": str(variant.get(&"name")), "color": _marker_colors[&"enemy"]}

func _nomad_info(target: Node3D) -> Dictionary:
	var nickname := str(target.get(&"nickname")).strip_edges()
	return {"text": "Nomade" if nickname.is_empty() else "Nomade · " + nickname, "color": NPC_COLOR}

func _trader_info(target: Node3D) -> Dictionary:
	var data := target.get(&"traderData") as Resource
	if not data:
		return {}
	return {"text": "Händler · " + str(data.get(&"name")), "color": TRADER_COLOR}

func _pickup_info(target: Node3D) -> Dictionary:
	if not _options.get(&"loot_esp", false) or target.process_mode == Node.PROCESS_MODE_DISABLED:
		return {}
	var collision := target.get(&"collision") as CollisionShape3D
	if collision == null or collision.disabled:
		return {}
	return _item_info(target.get(&"slotData"))

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
	var details: Array[Dictionary] = []
	var quests: Array[Dictionary] = []
	for slot in slots:
		var item := _item_info(slot)
		if item.is_empty():
			continue
		if item.quest:
			quests.append(item)
		else:
			details.append(item)
	if details.is_empty() and quests.is_empty() and (filter.search_only or not slots.is_empty() or not _options.get(&"show_empty", false)):
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
	var has_quest := not quests.is_empty()
	quests.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.priority > b.priority)
	details.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.priority > b.priority)
	quests.append_array(details)
	var matched := quests.any(func(item: Dictionary) -> bool: return item.matched)
	if matched:
		title = "[Treffer] " + title
	var color: Color = QUEST_COLOR if has_quest else _marker_colors[&"match"] if matched else CONTAINER_COLOR
	return {"text": title, "color": color, "quest": has_quest, "matched": matched, "details": quests}

func _item_info(slot: Resource) -> Dictionary:
	if not slot:
		return {}
	var item := slot.get(&"itemData") as Resource
	if item == null:
		return {}
	var category := filter.category_of(item)
	var match_kind := filter.match_item(item)
	var matched := match_kind != &""
	if not matched and (filter.search_only or not filter.accepts(item, category)):
		return {}
	var quest := category == &"quest"
	var title := ("[Quest] " if quest else "") + str(item.get(&"name"))
	if matched:
		title = ("[Merkliste] " if match_kind == &"watch" else "[Suche] ") + title
	if item.get(&"showAmount") and int(slot.get(&"amount")) > 1:
		title += " ×%d" % int(slot.get(&"amount"))
	var rarity = item.get(&"rarity")
	title += " · %s" % RARITY_LABELS.get(rarity, "Ohne Seltenheit")
	var color: Color = _marker_colors[&"loot"]
	var priority := 0
	if quest:
		color = QUEST_COLOR
		priority = 5 if matched else 4
	elif matched:
		color = _marker_colors[&"match"]
		priority = 4
	elif rarity == LootFilter.Rarity.LEGENDARY:
		color = LEGENDARY_COLOR
		priority = 3
	elif rarity == LootFilter.Rarity.RARE:
		color = RARE_COLOR
		priority = 2
	elif category == &"weapons":
		color = WEAPON_COLOR
		priority = 1
	return {"text": title, "quest": quest, "matched": matched, "color": color, "priority": priority}

func _draw_skeleton(camera: Camera3D, target: Node3D, color: Color, distance: float) -> void:
	var skeleton := target.get(&"skeleton") as Skeleton3D
	if not is_instance_valid(skeleton):
		return
	var id := target.get_instance_id()
	if not _skeleton_links.has(id):
		_skeleton_links[id] = EnemySkeleton.build_links(skeleton)
	var segments := EnemySkeleton.project_links(skeleton, _skeleton_links[id], camera)
	if not segments.is_empty():
		var width := EnemySkeleton.line_width(distance)
		if distance < 32.0:
			draw_multiline(segments, Color(0.02, 0.03, 0.04, 0.68), width + 0.85, true)
		draw_multiline(segments, color, width, true)

func _title(marker: Dictionary) -> String:
	var hide_distance := &"hide_enemy_distance" if marker.actor else &"hide_loot_distance"
	return marker.text if _options.get(hide_distance, false) else "%s · %d m" % [marker.text, roundi(marker.distance)]

func _draw_labels(markers: Array[Dictionary]) -> void:
	var font := ThemeDB.fallback_font
	var occupied: Array[Rect2] = []
	for marker in markers:
		var text: String = marker.title
		var preview: Array = marker.preview
		var width: float = marker.width
		var height := 22.0 + 17.0 * preview.size()
		var point: Vector2 = marker.p
		var box := Rect2(point.x - width * 0.5 - 5.0, point.y - height - 3.0, width + 10.0, height)
		if occupied.any(func(other: Rect2) -> bool: return other.intersects(box)):
			continue
		occupied.append(box)
		draw_rect(box, LABEL_BACKGROUND)
		draw_circle(point, 3.0, marker.color)
		draw_string(font, box.position + Vector2(5.0, 16.0), text, HORIZONTAL_ALIGNMENT_LEFT, width, 15, marker.color)
		for index in preview.size():
			var item: Dictionary = preview[index]
			var row := box.position + Vector2(5.0, 33.0 + index * 17.0)
			draw_string(font, row, item.text, HORIZONTAL_ALIGNMENT_LEFT, width, 13, item.color)

func _draw_loot_overview(markers: Array[Dictionary], screen: Rect2) -> void:
	var focus := screen.grow_individual(-screen.size.x * 0.32, -screen.size.y * 0.28, -screen.size.x * 0.32, -screen.size.y * 0.28)
	var nearby := markers.filter(func(marker: Dictionary) -> bool: return not marker.actor and focus.has_point(marker.p))
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
		var title: String = marker.title
		if index == 0 and focused_details.size() > detail_rows:
			title += " · +%d weitere" % (focused_details.size() - detail_rows)
		draw_string(font, row, title, HORIZONTAL_ALIGNMENT_LEFT, width - 24.0, 14, marker.color)
		row.y += 20.0
		if index == 0:
			for detail_index in detail_rows:
				var detail: Dictionary = focused_details[detail_index]
				draw_string(font, row + Vector2(8.0, 0.0), detail.text, HORIZONTAL_ALIGNMENT_LEFT, width - 32.0, 13, detail.color)
				row.y += 17.0
		row.y += 10.0
