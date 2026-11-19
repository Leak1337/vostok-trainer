extends RefCounted

const Locale = preload("Locale.gd")
const CELL := Vector2(82.0, 56.0)
const FOCUS_RADIUS := 76.0

static func labels(markers: Array[Dictionary], focus: Vector2) -> Array[Dictionary]:
	var buckets: Dictionary[Vector2i, Array] = {}
	var layout: Array[Dictionary] = []
	for marker in markers:
		if marker.actor:
			layout.append(marker)
			continue
		var cell := Vector2i((Vector2(marker.p) / CELL).floor())
		if not buckets.has(cell):
			buckets[cell] = []
			layout.append({"bucket": cell})
		buckets[cell].append(marker)
	var font := ThemeDB.fallback_font
	for index in layout.size():
		if not layout[index].has("bucket"):
			continue
		var group: Array = buckets[layout[index].bucket]
		if group.size() == 1:
			layout[index] = group[0]
			continue
		var first: Dictionary = group[0]
		var center := Vector2.ZERO
		var quest_count := 0
		for marker: Dictionary in group:
			center += marker.p
			quest_count += int(marker.get("quest", false))
		center /= float(group.size())
		var title := Locale.text("%d Loot-Ziele") % group.size()
		if quest_count > 0:
			title += Locale.text(" · %d Quest") % quest_count
		var preview: Array[Dictionary] = []
		var width := font.get_string_size(title, 0, -1, 15).x
		if center.distance_squared_to(focus) <= FOCUS_RADIUS * FOCUS_RADIUS:
			for marker: Dictionary in group.slice(0, 5):
				preview.append({"text": marker.title, "color": marker.color})
				width = maxf(width, font.get_string_size(marker.title, 0, -1, 13).x)
			if group.size() > preview.size():
				preview.append({"text": Locale.text("+%d weitere") % (group.size() - preview.size()), "color": Color.WHITE})
		layout[index] = {"title": title, "p": center, "actor": false, "kind": first.kind,
			"color": first.color, "preview": preview, "width": minf(width, 360.0)}
	return layout
