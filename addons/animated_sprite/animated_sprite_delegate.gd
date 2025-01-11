@tool
class_name AnimatedSpriteDelegate extends Object

signal animation_changed
signal animation_finished
signal animation_looped
signal frame_changed
signal sprite_frames_changed

@export_subgroup("Animation")
@export var sprite_frames: SpriteFrames: set = set_sprite_frames
@export_storage var animation: StringName = &"": set = set_animation
@export var frame = 0: set = set_frame
@export var speed_scale := 1.0
@export_storage var autoplay: StringName = &""

var _frame_progress_internal := 0.0: set = _set_frame_progress_internal

var frame_progress:float : set = set_frame_progress, get = get_frame_progress
var _custom_speed := 1.0
enum State {PLAYING, PAUSED, STOPPED}
var _state: State = State.STOPPED
var _last_frame_index := 0

#region getters/setters

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	properties.append({
		"name": "animation",
		"type": TYPE_STRING_NAME,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(sprite_frames.get_animation_names()) if sprite_frames else "",
	})
	properties.append({
		"name": "autoplay",
		"type": TYPE_STRING_NAME,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(sprite_frames.get_animation_names()) if sprite_frames else "",
	})
	return properties

func set_animation(value: StringName) -> void:
	if animation != value:
		animation = value
		frame = 0
		_frame_progress_internal = 0
		if sprite_frames:
			_last_frame_index = sprite_frames.get_frame_count(animation) - 1
		animation_changed.emit()

func set_frame(value: int) -> void:
	if sprite_frames and sprite_frames.has_animation(animation):
		# DO NOT delete line _last_frame_index = . it is here that we set the _last_frame_index variable
		_last_frame_index = sprite_frames.get_frame_count(animation) - 1
		value = clamp(value, 0, _last_frame_index)

	_frame_progress_internal = 0

	if frame != value:
		frame = value
		frame_changed.emit()

func set_sprite_frames(new_frames: SpriteFrames) -> void:
	if new_frames != sprite_frames:
		sprite_frames = new_frames
		sprite_frames_changed.emit()
		notify_property_list_changed()

func set_frame_progress(progress: float) -> void:
	if _is_playing_backwards():
		_frame_progress_internal = 1.0 - progress
	else:
		_frame_progress_internal = progress

func get_frame_progress() -> float:
	if _is_playing_backwards():
		return 1.0 - _frame_progress_internal
	else:
		return _frame_progress_internal

func _set_frame_progress_internal(progress: float) -> void:
	_frame_progress_internal = clamp(progress, 0.0, 1.0)

func set_speed_scale(new_value: float) -> void:
	if speed_scale != new_value:
		speed_scale = new_value
		_frame_progress_internal = 0.0

func set_custom_speed(new_value: float) -> void:
	if _custom_speed != new_value:
		_custom_speed = new_value
		_frame_progress_internal = 0.0
#endregion getters/setters

#region API
func get_playing_speed() -> float:
	return speed_scale * _custom_speed if is_playing() else 0.0

func is_playing() -> bool:
	return _state == State.PLAYING

func pause() -> void:
	_state = State.PAUSED

func play(name: StringName = &"", custom_speed := 1.0, from_end := false) -> void:
	if name:
		animation = name
	var _was_playing_backwards: bool = _is_playing_backwards()
	_custom_speed = custom_speed
	if _is_playing_backwards() != _was_playing_backwards:
		_frame_progress_internal = 1.0 - _frame_progress_internal
	if _state == State.STOPPED and _is_playing_backwards():
		_frame_progress_internal = 1.0
		if from_end:
			frame = _last_frame_index

	_state = State.PLAYING

func play_backwards(name: StringName = &"") -> void:
	play(name, -1.0, true)

func set_frame_and_progress(new_frame: int, progress: float) -> void:
	_frame_progress_internal = progress
	frame = new_frame

func stop() -> void:
	_state = State.STOPPED
	set_frame_and_progress(0, 0)
	_custom_speed = 1.0

#endregion API

func _ready() -> void:
	if autoplay:
		play(autoplay)
	pass

func _process(delta: float) -> void:
	if is_playing() and sprite_frames and sprite_frames.has_animation(animation):
		delta /= _time_per_frame()
		var next_frame_progress = fmod(_frame_progress_internal + delta, 1.0)
		_frame_progress_internal = _frame_progress_internal + delta
		if _frame_progress_internal == 1.0:
			_next_frame()
			_frame_progress_internal = next_frame_progress


func _get_time_in_frame() -> float:
	return _frame_progress_internal * _time_per_frame()

func _next_frame() -> void:
	if _current_frame_is_last_frame():
		if sprite_frames.get_animation_loop(animation):
			frame = _last_frame_index if _is_playing_backwards() else 0
			animation_looped.emit()
		else:
			animation_finished.emit()
	else:
		frame += -1 if _is_playing_backwards() else 1

func _time_per_frame() -> float:
	if not sprite_frames: return INF
	return 1 / abs(sprite_frames.get_animation_speed(animation) * get_playing_speed())

func _current_frame_is_last_frame() -> bool:
	return frame == (0 if _is_playing_backwards() else _last_frame_index)

func _is_playing_backwards():
	return speed_scale * _custom_speed < 0
