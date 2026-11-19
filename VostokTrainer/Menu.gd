extends CanvasLayer

signal setting_changed(id: StringName, enabled: bool)
signal distance_changed(meters: float)
signal close_requested

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
	panel.custom_minimum_size.x = 440
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
	content.add_child(HSeparator.new())

	_add_switch(content, &"stamina", "Unbegrenzte Ausdauer")
	_add_switch(content, &"ammo", "Unbegrenzte Munition", "Die Waffe muss zuerst geladen sein.")
	_add_switch(content, &"godmode", "Godmode", "Schützt vor Schaden und hält Gesundheit und Sauerstoff voll.")
	_add_switch(content, &"needs", "Energie und Flüssigkeit auffüllen")
	_add_switch(content, &"night_vision", "Nachtsicht", "Hellt dunkle Bildbereiche auf und färbt das Bild grün.")
	content.add_child(HSeparator.new())
	_add_switch(content, &"enemy_esp", "Gegner-ESP", "Markiert aktive Gegner.")
	_add_switch(content, &"loot_esp", "Gegenstands-ESP", "Markiert lose Gegenstände.")
	var styles := HBoxContainer.new()
	styles.add_theme_constant_override(&"separation", 18)
	content.add_child(styles)
	_add_switch(styles, &"esp_boxes", "Boxen", "Zeigt einen Rahmen um markierte Ziele.")
	_add_switch(styles, &"esp_lines", "Linien", "Zieht Linien von der unteren Bildschirmmitte zu markierten Zielen.")
	_add_distance_slider(content)
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


func _add_distance_slider(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	parent.add_child(row)
	var caption := Label.new()
	caption.text = "ESP-Distanz"
	row.add_child(caption)
	var slider := HSlider.new()
	slider.name = "EspDistance"
	slider.min_value = 10.0
	slider.max_value = 400.0
	slider.step = 5.0
	slider.value = DEFAULT_DISTANCE
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.tooltip_text = "Gemeinsame Reichweite für Gegner- und Gegenstands-ESP."
	row.add_child(slider)
	var readout := Label.new()
	readout.name = "DistanceValue"
	readout.custom_minimum_size.x = 54
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	readout.text = "%d m" % int(slider.value)
	row.add_child(readout)
	slider.value_changed.connect(func(meters: float) -> void:
		readout.text = "%d m" % int(meters)
		distance_changed.emit(meters)
	)


func _reset() -> void:
	for toggle in _switches.values():
		toggle.button_pressed = false
