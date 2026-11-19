extends Node

const Menu = preload("Menu.gd")
const Esp = preload("Esp.gd")
const NightVision = preload("NightVision.gd")
const WorldControl = preload("WorldControl.gd")
const GAME_DATA_PATH := "res://Resources/GameData.tres"

var _lib
var _data: Resource
var _menu: Menu
var _esp: Esp
var _night_vision: NightVision
var _world: WorldControl
var _settings: Dictionary[StringName, bool] = {}
var _previous_pause := false
var _previous_mouse := Input.MOUSE_MODE_VISIBLE
var _closing_with_escape := false
var _ammo_before := -1
var _feeding_round := false
var _condition_before: Variant


func _ready() -> void:
	_lib = Engine.get_meta(&"RTVModLib", null)
	if not is_instance_valid(_lib) or not _lib.has_method(&"hook"):
		push_warning("[Vostok Trainer] Metro Mod Loader fehlt.")
		return
	if ResourceLoader.exists(GAME_DATA_PATH):
		_data = load(GAME_DATA_PATH) as Resource
	if not _data or not ("bodyStamina" in _data and "armStamina" in _data and "health" in _data):
		push_warning("[Vostok Trainer] Spielerdaten fehlen in diesem Build.")
		return

	process_mode = Node.PROCESS_MODE_ALWAYS
	_menu = Menu.new()
	_menu.setting_changed.connect(_set_option)
	_menu.close_requested.connect(_close_menu)
	add_child(_menu)
	var overlay := CanvasLayer.new()
	overlay.layer = 90
	add_child(overlay)
	_esp = Esp.new()
	_esp.enemy_distance = Menu.DEFAULT_DISTANCE
	_esp.loot_distance = Menu.DEFAULT_DISTANCE
	overlay.add_child(_esp)
	_menu.distance_changed.connect(_set_esp_distance)
	_menu.loot_category_changed.connect(_esp.set_loot_category)
	_menu.search_changed.connect(_esp.set_search)
	_menu.marker_color_changed.connect(_esp.set_marker_color)
	_night_vision = NightVision.new()
	add_child(_night_vision)
	_world = WorldControl.new()
	add_child(_world)
	_menu.time_requested.connect(_world.set_time)
	_menu.weather_requested.connect(_world.set_weather)
	_menu.restore_preferences()

	_lib.hook("character-_physics_process-post", _update_vitals)
	_lib.hook("weaponrig-fireevent-pre", _before_shot)
	_lib.hook("weaponrig-fireevent-post", _after_shot)
	if _lib.hook("weaponrig-malfunction", _block_malfunction) < 0:
		_menu.disable_option(&"no_jam", "Ein anderer Mod belegt den Ladehemmungs-Hook.")
	else:
		_lib.hook("weaponrig-fireinput-pre", _clear_jam)
	var damage_hooks := [
		_lib.hook("character-weapondamage", _block_damage_two_args),
		_lib.hook("character-explosiondamage", _block_damage),
		_lib.hook("character-burndamage", _block_damage_one_arg),
		_lib.hook("character-poisondamage", _block_damage_one_arg),
		_lib.hook("character-razordamage", _block_damage_one_arg),
		_lib.hook("character-falldamage", _block_damage_one_arg),
		_lib.hook("character-death", _block_damage),
	]
	if -1 in damage_hooks:
		_menu.disable_option(&"godmode", "Ein anderer Mod belegt einen Schadens-Hook.")
	print("[Vostok Trainer] F6 öffnet das Menü.")


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or _menu == null:
		return
	if key.keycode == KEY_F6:
		get_viewport().set_input_as_handled()
		if key.pressed and not key.echo:
			if _menu.visible:
				_close_menu()
			else:
				_previous_pause = get_tree().paused
				_previous_mouse = Input.mouse_mode
				get_tree().paused = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				_menu.update_world(_world.simulation() if _world.available() else null)
				_menu.open()
	elif key.keycode == KEY_ESCAPE and (_menu.visible or _closing_with_escape):
		get_viewport().set_input_as_handled()
		if not key.pressed:
			_closing_with_escape = false
		elif not key.echo and _menu.visible:
			_closing_with_escape = true
			_close_menu()


func _close_menu() -> void:
	if _menu.visible:
		_menu.flush_preferences()
		_menu.hide()
		get_tree().paused = _previous_pause
		Input.mouse_mode = _previous_mouse


func _set_option(id: StringName, enabled: bool) -> void:
	_settings[id] = enabled
	match id:
		&"night_vision":
			_night_vision.set_enabled(enabled)
		&"freeze_clock":
			_world.set_clock_frozen(enabled)
		&"stamina", &"ammo", &"godmode", &"needs", &"no_jam", &"no_wear":
			pass
		_:
			_esp.set_option(id, enabled)


func _set_esp_distance(category: StringName, meters: float) -> void:
	if category == &"enemy":
		_esp.enemy_distance = meters
	else:
		_esp.loot_distance = meters
	_esp.invalidate_targets()


func _update_vitals(_delta: float) -> void:
	if _data.get(&"isDead") or _data.get(&"isTransitioning") or _data.get(&"isCaching"):
		return
	if _settings.get(&"stamina", false):
		_data.set(&"bodyStamina", 100.0)
		_data.set(&"armStamina", 100.0)
	if _settings.get(&"needs", false):
		_data.set(&"energy", 100.0)
		_data.set(&"hydration", 100.0)
	if _settings.get(&"godmode", false):
		_data.set(&"health", 100.0)
		_data.set(&"oxygen", 100.0)
		var character: Node = _lib._caller
		for condition in [&"bleeding", &"fracture", &"burn", &"poisoning", &"rupture", &"headshot"]:
			if _data.get(condition):
				character.call(String(condition).capitalize(), false)


func _block_damage() -> void:
	if _settings.get(&"godmode", false) and not _data.get(&"isDead"):
		_lib.skip_super()


func _block_damage_one_arg(_value) -> void:
	_block_damage()


func _block_damage_two_args(_damage, _penetration) -> void:
	_block_damage()


func _before_shot() -> void:
	_ammo_before = -1
	_feeding_round = false
	_condition_before = null
	var infinite_ammo: bool = _settings.get(&"ammo", false)
	var preserve_condition: bool = _settings.get(&"no_wear", false)
	if (not infinite_ammo and not preserve_condition) or _data.get(&"isDead"):
		return
	var weapon = _lib._caller
	if not weapon.slotData or not weapon.slotData.chamber or weapon.fireTimer < weapon.fireRate:
		return
	if preserve_condition:
		_condition_before = weapon.slotData.condition
	if not infinite_ammo:
		return
	_ammo_before = weapon.slotData.amount
	var action: String = weapon.data.weaponAction
	_feeding_round = action != "Manual" and action != "Single"
	if _feeding_round:
		# Keep a round available for the vanilla chambering logic, even on the last shot.
		weapon.slotData.amount += 1


func _after_shot() -> void:
	if _ammo_before < 0 and _condition_before == null:
		return
	var weapon = _lib._caller
	var slot = weapon.slotData
	if _condition_before != null:
		slot.condition = _condition_before
		_condition_before = null
	if _ammo_before < 0:
		return
	var fired: bool = weapon.fireTimer == 0.0 and slot.state != "Jammed"
	if _feeding_round or not fired:
		slot.amount = _ammo_before
	elif weapon.data.weaponAction == "Manual":
		# The normal manual chambering action still applies.
		slot.amount = maxi(_ammo_before, 1)
	else:
		weapon.CasingEject()
		slot.casing = false
		slot.chamber = true
		slot.amount = _ammo_before
		weapon.slideLocked = false
		weapon.hammerLocked = weapon.data.hammerLock
	_ammo_before = -1
	weapon.UpdateBullets()


func _clear_jam() -> void:
	if _settings.get(&"no_jam", false):
		var slot = _lib._caller.slotData
		if slot and slot.state == "Jammed":
			slot.state = ""


func _block_malfunction() -> bool:
	if _settings.get(&"no_jam", false):
		_lib.skip_super()
	return false
