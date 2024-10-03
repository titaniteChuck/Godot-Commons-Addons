class_name Scene_Loader extends Node

signal load_progress(progress_in_percent: float)
signal load_complete(loaded_scene: Node)
signal load_failed
signal invalid_resource

@export var preloaded_resources: Array[PackedScene] = []

var _timer: Timer = Timer.new()
var _scenePath
var _is_loading := false

func _init() -> void:
	_timer.one_shot = false
	_timer.set_wait_time(0.1)
	_timer.timeout.connect(_monitor_load_status)
	add_child(_timer)

func load_async(scenePath: String) -> void:
	if _is_loading:
		printerr("SceneLoader is Already loading "+_scenePath+". Use await SceneLoader.load_complete")
		return

	if not ResourceLoader.exists(scenePath):
		printerr("Invalid scene path [%s]" % scenePath)
		return

	for resource_factory in preloaded_resources:
		if resource_factory.resource_path == scenePath:
			load_complete.emit(resource_factory.instantiate())
			return

	_is_loading = true
	_scenePath = scenePath
	ResourceLoader.load_threaded_request(scenePath)
	call_deferred("_launch_timer")

func load_sync(scenePath: String) -> PackedScene:
	if not ResourceLoader.exists(scenePath):
		printerr("Invalid scene path [%s]" % scenePath)
		return

	for resource_factory in preloaded_resources:
		if resource_factory.resource_path == scenePath:
			return resource_factory

	return load(scenePath)

func _launch_timer() -> void:
	_timer.start()

## internal - checks in on loading status - this can also be done with a while loop, but I found that ran too fast
## and ended up skipping over the loading display.
func _monitor_load_status() -> void:
	var load_progress_array = []
	var status = ResourceLoader.load_threaded_get_status(_scenePath, load_progress_array)
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE: _on_resource_invalid()
	elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: _on_load_in_progress(load_progress_array[0])
	elif status == ResourceLoader.THREAD_LOAD_FAILED: _on_load_failed()
	elif status == ResourceLoader.THREAD_LOAD_LOADED: _on_load_succeed()

func _on_resource_invalid():
	printerr("Invalid resource: '%s'" % [_scenePath])
	invalid_resource.emit()
	_cleanup()

func _on_load_failed():
	printerr("Failed loading resource: '%s'" % [_scenePath])
	load_failed.emit()
	_cleanup()

func _on_load_succeed():
	load_complete.emit(ResourceLoader.load_threaded_get(_scenePath).instantiate())
	_cleanup()

func _on_load_in_progress(progress_normalized: float):
	load_progress.emit(progress_normalized * 100)

func _cleanup():
	_timer.stop()
	_is_loading = false
