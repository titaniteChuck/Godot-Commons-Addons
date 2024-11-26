@tool
class_name AnimatedSpriteControl extends TextureRect

signal animation_changed
signal animation_finished
signal animation_looped
signal frame_changed
signal sprite_frames_changed

@export_subgroup("Animation")
@export var sprite_frames: SpriteFrames: set = set_sprite_frames, get = get_sprite_frames
@export_storage var animation: StringName: set = set_animation, get = get_animation
@export var frame: int = 0: set = set_frame, get = get_frame
@export var speed_scale: float = 1.0 : set = set_speed_scale, get = get_speed_scale
@export_storage var autoplay: StringName: set = set_autoplay, get = get_autoplay

@export_subgroup("Offset")
@export var center := true
@export var offset := Vector2(0, 0)

var _delegate := AnimatedSpriteDelegate.new()
var frame_progress: float : set = set_frame_progress, get = get_frame_progress

func _get_property_list() -> Array[Dictionary]:
	return _delegate._get_property_list()

func _init() -> void:
	frame = 0

func _ready() -> void:
	frame = 0
	_delegate.animation_changed.connect(_on_animation_changed)
	_delegate.animation_finished.connect(animation_finished.emit)
	_delegate.animation_looped.connect(animation_looped.emit)
	_delegate.frame_changed.connect(_on_frame_changed)
	_delegate.sprite_frames_changed.connect(_on_sprite_frames_changed)
	_delegate._ready()
	_update_ui()

func _process(delta: float) -> void:
	if _delegate:
		_delegate._process(delta)

func _on_sprite_frames_changed() -> void:
	_update_ui()
	sprite_frames_changed.emit()

func _on_animation_changed():
	_update_ui()
	frame_changed.emit()
	
func _on_frame_changed():
	_update_ui()
	animation_changed.emit()

func _update_ui():
	if not is_inside_tree(): await ready
	if sprite_frames and sprite_frames.has_animation(animation):
		texture = sprite_frames.get_frame_texture(animation, _delegate.frame)
	else:
		texture = null
	if not center:
		position = offset

#region getters/setters
func set_animation(value: StringName) -> void:
	_delegate.set_animation(value)
func get_animation() -> StringName:
	return _delegate.animation
func set_frame(new_frame: int) -> void:
	_delegate.set_frame(new_frame)
func get_frame() -> int:
	return _delegate.frame
func set_sprite_frames(new_frames: SpriteFrames) -> void:
	_delegate.set_sprite_frames(new_frames)
	notify_property_list_changed()
func get_sprite_frames() -> SpriteFrames:
	return _delegate.sprite_frames
func set_speed_scale(value: float) -> void:
	_delegate.speed_scale = value
func get_speed_scale() -> float:
	return _delegate.speed_scale
func set_autoplay(value: StringName) -> void:
	_delegate.autoplay = value
func get_autoplay() -> StringName:
	return _delegate.autoplay
func set_frame_progress(value: float) -> void:
	_delegate.frame_progress = value
func get_frame_progress() -> float:
	return _delegate.frame_progress
#endregion getters/setters

#region API
func get_playing_speed() -> float:
	return _delegate.get_playing_speed()
func is_playing() -> bool:
	return _delegate.is_playing()
func pause() -> void:
	_delegate.pause()
func play(name: StringName =&"", custom_speed := 1.0, from_end := false) -> void:
	_delegate.play(name, custom_speed, from_end)
func play_backwards(name: StringName = &"") -> void:
	_delegate.play_backwards(name)
func set_frame_and_progress(new_frame: int, progress: float) -> void:
	_delegate.set_frame_and_progress(new_frame, progress)
func stop() -> void:
	_delegate.stop()
#endregion API
