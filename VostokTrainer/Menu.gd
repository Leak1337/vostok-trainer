extends CanvasLayer

signal setting_changed(id: StringName, enabled: bool)
signal distance_changed(category: StringName, meters: float)
signal loot_category_changed(category: StringName, enabled: bool)
signal close_requested

const LootFilter = preload("LootFilter.gd")
const DEFAULT_DISTANCE := 150.0

var _screen: Control
var _switches: Dictionary[StringName, CheckButton] = {}
var _first_switch: CheckButton


func _ready() -> void:
	layer = 100
	_screen = ColorRect.new()
	_screen.color = Color(0.025, 0.04, 0.045, 0.76)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_screen)
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 520
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("151e21")
	surface.border_color = Color("3b5558")
	surface.set_border_width_all(1)
	surface.set_corner_radius_all(12)
	surface.content_margin_left = 24
	surface.content_margin_right = 24
	surface.content_margin_top = 20
	surface.content_margin_bottom = 20
	panel.add_theme_stylebox_override(&"panel", surface)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override(&"separation", 7)
	panel.add_child(content)
	var title := Label.new()
	title.text = "Vostok Trainer"
	title.add_theme_font_size_override(&"font_size", 27)
	title.add_theme_color_override(&"font_color", Color("d9f4ec"))
	content.add_child(title)
	var tabs := TabContainer.new()
	content.add_child(tabs)
	_screen.resized.connect(func() -> void:
		panel.custom_minimum_size.x = minf(520.0, _screen.size.x - 24.0)
		tabs.custom_minimum_size.y = clampf(_screen.size.y - 176.0, 150.0, 490.0)
	)
	panel.custom_minimum_size.x = minf(520.0, _screen.size.x - 24.0)
	tabs.custom_minimum_size.y = clampf(_screen.size.y - 176.0, 150.0, 490.0)
	var player := _make_tab(tabs, "Spieler")
	_add_switch(player, &"stamina", "Unbegrenzte Ausdauer")
	_add_switch(player, &"ammo", "Unbegrenzte Munition", "Die Waffe muss zuerst geladen sein.")
	_add_switch(player, &"godmode", "Godmode", "Schützt vor Schaden und hält Gesundheit und Sauerstoff voll.")
	_add_switch(player, &"needs", "Energie und Flüssigkeit auffüllen")
	_add_switch(player, &"night_vision", "Nachtsicht", "Hellt dunkle Bildbereiche auf und färbt das Bild grün.")

	var enemy := _make_tab(tabs, "Gegner-ESP")
	_add_switch(enemy, &"enemy_esp", "Gegner anzeigen")
	_add_switch(enemy, &"enemy_skeleton", "Skelett anzeigen", "Zeichnet die aktuellen Knochenpositionen der KI.")
	_add_switch(enemy, &"enemy_lines", "Linien zu Gegnern")
	_add_switch(enemy, &"show_nomads", "Nomaden anzeigen")
	_add_switch(enemy, &"hide_enemy_distance", "Entfernung ausblenden")
	_add_distance_slider(enemy, &"enemy")

	var loot := _make_tab(tabs, "Loot-ESP")
	_add_switch(loot, &"loot_esp", "Lose Gegenstände anzeigen")
	_add_switch(loot, &"container_esp", "Behälter und Lager anzeigen", "Zeigt den erzeugten Inhalt auch vor dem Öffnen.")
	_add_switch(loot, &"loot_overview", "Loot in Blickrichtung auflisten", "Zeigt Ziele nahe der Bildschirmmitte gesammelt an.")
	_add_switch(loot, &"loot_lines", "Linien zu Loot und Behältern")
	_add_switch(loot, &"show_empty", "Leere Behälter anzeigen")
	_add_switch(loot, &"rare_only", "Nur seltenen und legendären Loot anzeigen")
	_add_switch(loot, &"hide_loot_distance", "Entfernung ausblenden")
	_add_distance_slider(loot, &"loot")
	_add_loot_categories(_make_tab(tabs, "Loot-Filter"))
	content.add_child(HSeparator.new())

	var actions := HBoxContainer.new()
	content.add_child(actions)
	var reset := Button.new()
	reset.text = "Alles ausschalten"
	reset.pressed.connect(_reset)
	actions.add_child(reset)
	actions.add_spacer(false)
	var close := Button.new()
	close.text = "Schließen  [F6]"
	close.pressed.connect(close_requested.emit)
	actions.add_child(close)
	hide()


func open() -> void:
	show()
	if _first_switch.is_visible_in_tree():
		_first_switch.grab_focus()


func disable_option(id: StringName, reason: String) -> void:
	_switches[id].disabled = true
	_switches[id].tooltip_text = reason


func _add_switch(parent: BoxContainer, id: StringName, title: String, hint := "") -> void:
	var toggle := CheckButton.new()
	toggle.name = id
	toggle.text = title
	toggle.tooltip_text = hint
	toggle.custom_minimum_size.y = 30
	toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggle.toggled.connect(func(enabled: bool) -> void: setting_changed.emit(id, enabled))
	parent.add_child(toggle)
	_switches[id] = toggle
	if _first_switch == null:
		_first_switch = toggle


func _make_tab(tabs: TabContainer, tab_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	tabs.add_child(scroll)
	var margins := MarginContainer.new()
	margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in [&"margin_top", &"margin_bottom", &"margin_left", &"margin_right"]:
		margins.add_theme_constant_override(side, 10)
	scroll.add_child(margins)
	var body := VBoxContainer.new()
	body.add_theme_constant_override(&"separation", 6)
	margins.add_child(body)
	return body


func _add_distance_slider(parent: VBoxContainer, category: StringName) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	parent.add_child(row)
	var caption := Label.new()
	caption.text = "ESP-Distanz"
	row.add_child(caption)
	var slider := HSlider.new()
	slider.name = String(category) + "Distance"
	slider.min_value = 10.0
	slider.max_value = 400.0
	slider.step = 5.0
	slider.value = DEFAULT_DISTANCE
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.tooltip_text = "Maximale Reichweite dieser ESP-Kategorie."
	row.add_child(slider)
	var readout := Label.new()
	readout.name = String(category) + "DistanceValue"
	readout.custom_minimum_size.x = 54
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	readout.text = "%d m" % int(slider.value)
	row.add_child(readout)
	slider.value_changed.connect(func(meters: float) -> void:
		readout.text = "%d m" % int(meters)
		distance_changed.emit(category, meters)
	)


func _add_loot_categories(parent: VBoxContainer) -> void:
	var hint := Label.new()
	hint.text = "Gilt für Bodenloot und Behälterinhalte.\nQuest markiert Gegenstände aus deinen notierten Aufgaben."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(hint)
	var filters: Array[CheckBox] = []
	for category: StringName in LootFilter.CATEGORIES:
		var filter := CheckBox.new()
		filter.name = category
		filter.text = LootFilter.CATEGORIES[category]
		filter.button_pressed = true
		filter.toggled.connect(func(enabled: bool) -> void: loot_category_changed.emit(category, enabled))
		parent.add_child(filter)
		filters.append(filter)
	var actions := HBoxContainer.new()
	parent.add_child(actions)
	for enable in [true, false]:
		var button := Button.new()
		button.text = "Alle" if enable else "Keine"
		button.pressed.connect(func() -> void:
			for filter in filters:
				filter.button_pressed = enable
		)
		actions.add_child(button)


func _reset() -> void:
	for toggle in _switches.values():
		toggle.button_pressed = false
