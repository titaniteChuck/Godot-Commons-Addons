extends Control

func _process(delta: float) -> void:
	#queue_redraw()
	pass

func _draw():
	var settings_size:Vector2 = Vector2(ProjectSettings.get(&"display/window/size/viewport_width"), ProjectSettings.get(&"display/window/size/viewport_height"))
	var real_size: Vector2 = DisplayServer.window_get_size()
	var size_factor: Vector2 = real_size / settings_size

	var control_window:Rect2 = get_rect()
	var texture_corners: PackedVector2Array = [
		(control_window.position) * size_factor,
		(control_window.position + control_window.size * Vector2.RIGHT) * size_factor,
		(control_window.end) * size_factor,
		(control_window.position + control_window.size * Vector2.DOWN) * size_factor
	]
	DisplayServer.window_set_mouse_passthrough(texture_corners)
