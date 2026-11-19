extends CanvasLayer

signal setting_changed(id: StringName, enabled: bool)
signal distance_changed(category: StringName, meters: float)
signal loot_category_changed(category: StringName, enabled: bool)
signal search_changed(query: String, watchlist: String, matches_only: bool)
signal marker_color_changed(category: StringName, color: Color)
signal close_requested

const LootFilter = preload("LootFilter.gd")
const EspProfiles = preload("EspProfiles.gd")
const DEFAULT_DISTANCE := 150.0

var _screen: Control
var _switches: Dictionary[StringName, CheckButton] = {}
var _first_switch: CheckButton
var _sliders: Dictionary[StringName, HSlider] = {}
var _categories: Dictionary[StringName, CheckBox] = {}
var _color_pickers: Dictionary[StringName, ColorPickerButton] = {}
var _query: LineEdit
var _watchlist: TextEdit
var _profile_picker: OptionButton
var _profile_name: LineEdit
var _profile_status: Label
var _profiles := EspProfiles.new()
var _save_timer: Timer
var _restoring := false
var _dirty := false


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
	panel.custom_minimum_size.x = 680
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
		panel.custom_minimum_size.x = minf(680.0, _screen.size.x - 24.0)
		tabs.custom_minimum_size.y = clampf(_screen.size.y - 176.0, 150.0, 490.0)
	)
	panel.custom_minimum_size.x = minf(680.0, _screen.size.x - 24.0)
	tabs.custom_minimum_size.y = clampf(_screen.size.y - 176.0, 150.0, 490.0)
	var player := _make_tab(tabs, "Spieler")
	_add_switch(player, &"stamina", "Unbegrenzte Ausdauer")
	_add_switch(player, &"ammo", "Unbegrenzte Munition", "Die Waffe muss zuerst geladen sein.")
	_add_switch(player, &"godmode", "Godmode", "Schützt vor Schaden und hält Gesundheit und Sauerstoff voll.")
	_add_switch(player, &"needs", "Energie und Flüssigkeit auffüllen")
	_add_switch(player, &"night_vision", "Nachtsicht", "Hellt dunkle Bildbereiche auf und färbt das Bild grün.")

	var enemy := _make_tab(tabs, "Personen-ESP")
	_add_switch(enemy, &"enemy_esp", "Gegner anzeigen")
	_add_switch(enemy, &"trader_esp", "Händler anzeigen")
	_add_switch(enemy, &"npc_esp", "Andere NPCs anzeigen", "Markiert aktive Nomaden und die Katze.")
	_add_switch(enemy, &"enemy_skeleton", "Skelett anzeigen", "Zeichnet die aktuellen Knochenpositionen der KI.")
	_add_switch(enemy, &"enemy_lines", "Linien zu Personen und NPCs")
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
	_add_search(_make_tab(tabs, "Item-Suche"))
	_add_profiles(_make_tab(tabs, "Profile"))
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
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.4
	_save_timer.timeout.connect(flush_preferences)
	add_child(_save_timer)
	hide()


func open() -> void:
	show()
	if _first_switch.is_visible_in_tree():
		_first_switch.grab_focus()


func disable_option(id: StringName, reason: String) -> void:
	_switches[id].disabled = true
	_switches[id].tooltip_text = reason

func restore_preferences() -> void:
	_profiles.read()
	_list_profiles()
	_apply_profile(_profiles.last)

func flush_preferences() -> void:
	if not _dirty:
		return
	var error := _profiles.save()
	_dirty = error != OK
	if error != OK:
		push_warning("[Vostok Trainer] ESP-Einstellungen konnten nicht gespeichert werden (Fehler %d)." % error)
		if is_instance_valid(_profile_status):
			_profile_status.text = "Speichern fehlgeschlagen."

func _exit_tree() -> void:
	flush_preferences()

func _add_switch(parent: BoxContainer, id: StringName, title: String, hint := "") -> void:
	var toggle := CheckButton.new()
	toggle.name = id
	toggle.text = title
	toggle.tooltip_text = hint
	toggle.custom_minimum_size.y = 30
	toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggle.toggled.connect(func(enabled: bool) -> void:
		if id == &"search_only":
			_search_updated()
		else:
			setting_changed.emit(id, enabled)
			if id in EspProfiles.OPTIONS:
				_queue_save()
	)
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
	_sliders[category] = slider
	var readout := Label.new()
	readout.name = String(category) + "DistanceValue"
	readout.custom_minimum_size.x = 54
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	readout.text = "%d m" % int(slider.value)
	row.add_child(readout)
	slider.value_changed.connect(func(meters: float) -> void:
		readout.text = "%d m" % int(meters)
		distance_changed.emit(category, meters)
		_queue_save()
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
		filter.toggled.connect(func(enabled: bool) -> void:
			loot_category_changed.emit(category, enabled)
			_queue_save()
		)
		parent.add_child(filter)
		_categories[category] = filter
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


func _add_search(parent: VBoxContainer) -> void:
	var label := Label.new()
	label.text = "Itemname oder ID suchen"
	parent.add_child(label)
	_query = LineEdit.new()
	_query.name = "ItemQuery"
	_query.placeholder_text = "z. B. Bandage oder Makarov"
	_query.max_length = 96
	_query.clear_button_enabled = true
	_query.text_changed.connect(func(_value: String) -> void: _search_updated())
	parent.add_child(_query)
	var watch_label := Label.new()
	watch_label.text = "Merkliste · pro Zeile oder mit Komma trennen"
	parent.add_child(watch_label)
	_watchlist = TextEdit.new()
	_watchlist.name = "ItemWatchlist"
	_watchlist.placeholder_text = "z. B. Schlüssel, Tourniquet"
	_watchlist.custom_minimum_size.y = 116
	_watchlist.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_watchlist.text_changed.connect(_search_updated)
	parent.add_child(_watchlist)
	_add_switch(parent, &"search_only", "Nur Suchtreffer und Merkliste anzeigen")
	var hint := Label.new()
	hint.text = "Aktiviere Bodenloot oder Behälter im Loot-ESP. Treffer erscheinen auch bei ausgefilterten Kategorien. Die Merkliste berücksichtigt bis zu 24 Begriffe und 512 Zeichen."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(hint)

func _add_profiles(parent: VBoxContainer) -> void:
	var label := Label.new()
	label.text = "Gespeichertes ESP-Profil laden"
	parent.add_child(label)
	var load_row := HBoxContainer.new()
	parent.add_child(load_row)
	_profile_picker = OptionButton.new()
	_profile_picker.name = "EspProfiles"
	_profile_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_row.add_child(_profile_picker)
	var load_button := Button.new()
	load_button.name = "LoadEspProfile"
	load_button.text = "Laden"
	load_button.pressed.connect(_load_selected_profile)
	load_row.add_child(load_button)
	var save_row := HBoxContainer.new()
	parent.add_child(save_row)
	_profile_name = LineEdit.new()
	_profile_name.name = "EspProfileName"
	_profile_name.placeholder_text = "Name für eigenes Profil"
	_profile_name.max_length = 40
	_profile_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_row.add_child(_profile_name)
	var save_button := Button.new()
	save_button.name = "SaveEspProfile"
	save_button.text = "Speichern"
	save_button.pressed.connect(_save_named_profile)
	save_row.add_child(save_button)
	_profile_status = Label.new()
	_profile_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_profile_status.text = "Deine letzten ESP-Einstellungen und die Merkliste werden automatisch gespeichert."
	parent.add_child(_profile_status)
	parent.add_child(HSeparator.new())
	_add_color_picker(parent, &"enemy", "Gegnerfarbe")
	_add_color_picker(parent, &"loot", "Farbe für gewöhnlichen Loot")
	_add_color_picker(parent, &"match", "Farbe für Suchtreffer")

func _add_color_picker(parent: VBoxContainer, id: StringName, text: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var picker := ColorPickerButton.new()
	picker.name = String(id) + "MarkerColor"
	picker.custom_minimum_size = Vector2(88.0, 30.0)
	picker.edit_alpha = false
	picker.color = EspProfiles.DEFAULT_COLORS[id]
	picker.color_changed.connect(func(color: Color) -> void:
		marker_color_changed.emit(id, color)
		_queue_save()
	)
	row.add_child(picker)
	_color_pickers[id] = picker

func _list_profiles(selected := "Standard") -> void:
	_profile_picker.clear()
	var names := _profiles.custom.keys()
	names.sort()
	for name in EspProfiles.BUILT_INS.keys() + names:
		var index := _profile_picker.item_count
		_profile_picker.add_item(name)
		if name == selected:
			_profile_picker.select(index)

func _load_selected_profile() -> void:
	var name := _profile_picker.get_item_text(_profile_picker.selected)
	var state: Dictionary = EspProfiles.BUILT_INS.get(name, _profiles.custom.get(name, {}))
	_apply_profile(state, false)
	_queue_save()
	_profile_status.text = "%s geladen." % name

func _save_named_profile() -> void:
	var name := _profile_name.text.strip_edges()
	if name.is_empty() or EspProfiles.BUILT_INS.has(name):
		_profile_status.text = "Gib einen eigenen Profilnamen ein."
		return
	_profiles.last = _capture_profile()
	_profiles.custom[name] = _capture_profile(false)
	_dirty = true
	flush_preferences()
	if not _dirty:
		_list_profiles(name)
		_profile_status.text = "%s gespeichert." % name

func _apply_profile(state: Dictionary, restore_search := true) -> void:
	_restoring = true
	var options: Dictionary = state.get("options", {}) if state.get("options") is Dictionary else {}
	var categories: Dictionary = state.get("categories", {}) if state.get("categories") is Dictionary else {}
	var colors: Dictionary = state.get("colors", {}) if state.get("colors") is Dictionary else {}
	for id in EspProfiles.OPTIONS:
		if id != &"search_only" or restore_search:
			_switches[id].button_pressed = bool(options.get(id, false))
	for category in _categories:
		_categories[category].button_pressed = bool(categories.get(category, not state.has("categories")))
	for category in _sliders:
		var distance = state.get(String(category) + "_distance", DEFAULT_DISTANCE)
		_sliders[category].value = float(distance) if distance is float or distance is int else DEFAULT_DISTANCE
	for id in _color_pickers:
		var saved_color = colors.get(id, EspProfiles.DEFAULT_COLORS[id])
		_color_pickers[id].color = saved_color if saved_color is Color else EspProfiles.DEFAULT_COLORS[id]
		marker_color_changed.emit(id, _color_pickers[id].color)
	if restore_search:
		_query.text = str(state.get("query", "")).left(96)
		_watchlist.text = str(state.get("watchlist", "")).left(512)
		search_changed.emit(_query.text, _watchlist.text, _switches[&"search_only"].button_pressed)
	_restoring = false

func _capture_profile(include_search := true) -> Dictionary:
	var options: Dictionary = {}
	var categories: Dictionary = {}
	var colors: Dictionary = {}
	for id in EspProfiles.OPTIONS:
		if id != &"search_only" or include_search:
			options[id] = _switches[id].button_pressed
	for id in _categories:
		categories[id] = _categories[id].button_pressed
	for id in _color_pickers:
		colors[id] = _color_pickers[id].color
	var state := {
		"options": options, "categories": categories, "colors": colors,
		"enemy_distance": _sliders[&"enemy"].value, "loot_distance": _sliders[&"loot"].value,
	}
	if include_search:
		state["query"] = _query.text
		state["watchlist"] = _watchlist.text.left(512)
	return state

func _search_updated() -> void:
	if not _restoring:
		search_changed.emit(_query.text, _watchlist.text, _switches[&"search_only"].button_pressed)
		_queue_save()

func _queue_save() -> void:
	if _restoring or not is_instance_valid(_save_timer):
		return
	_profiles.last = _capture_profile()
	_dirty = true
	_save_timer.start()

func _reset() -> void:
	for toggle in _switches.values():
		toggle.button_pressed = false
