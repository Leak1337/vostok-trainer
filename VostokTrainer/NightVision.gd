extends CanvasLayer

const ShaderEffect = preload("NightVision.gdshader")


func _ready() -> void:
	layer = 80
	var capture := BackBufferCopy.new()
	capture.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(capture)

	var surface := ColorRect.new()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var effect := ShaderMaterial.new()
	effect.shader = ShaderEffect
	surface.material = effect
	add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_enabled(false)


func set_enabled(enabled: bool) -> void:
	set_process(enabled)
	if enabled:
		_process(0.0)
	else:
		hide()


func _process(_delta: float) -> void:
	visible = has_node("/root/Map") and get_viewport().get_camera_3d() != null
