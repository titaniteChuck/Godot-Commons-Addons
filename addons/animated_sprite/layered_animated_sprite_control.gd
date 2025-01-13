@tool
class_name LayeredAnimatedSpriteControl extends TextureRect

signal animation_changed
signal animation_finished
signal animation_looped
signal frame_changed
signal sprite_frames_changed

@export_subgroup("Animation")
@export var sprite_frames: Array[SpriteFrames]: set = set_sprite_frames, get = get_sprite_frames
@export_storage var animation: StringName: set = set_animation, get = get_animation
@export var frame: int = 0: set = set_frame, get = get_frame
@export var speed_scale: float = 1.0 : set = set_speed_scale, get = get_speed_scale
@export_storage var autoplay: StringName: set = set_autoplay, get = get_autoplay

@export_subgroup("Offset")
@export var centered := true
@export var offset := Vector2(0, 0)

var _delegate := AnimatedSpriteDelegate.new()
var frame_progress: float : set = set_frame_progress, get = get_frame_progress

func _get_property_list() -> Array[Dictionary]:
	return _delegate._get_property_list()

func _init() -> void:
	frame = 0

func _ready() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	frame = 0
	_delegate.animation_changed.connect(_on_animation_changed)
	_delegate.animation_finished.connect(animation_finished.emit)
	_delegate.animation_looped.connect(animation_looped.emit)
	_delegate.frame_changed.connect(_on_frame_changed)
	_delegate.sprite_frames_changed.connect(_on_sprite_frames_changed)
	_delegate._ready()
	queue_redraw()

func _process(delta: float) -> void:
	if _delegate:
		_delegate._process(delta)

func _on_sprite_frames_changed() -> void:
	queue_redraw()
	sprite_frames_changed.emit()

func _on_frame_changed():
	queue_redraw()
	frame_changed.emit()

func _on_animation_changed():
	queue_redraw()
	animation_changed.emit()

func _draw():
	if not is_inside_tree(): await ready
	#if get_child_count() != sprite_frames.size():
		#set_sprite_frames(sprite_frames)
	for index in get_child_count():
		if sprite_frames and sprite_frames[index] and sprite_frames[index].has_animation(animation):
			get_child(index).texture = sprite_frames[index].get_frame_texture(animation, _delegate.frame)
		else:
			get_child(index).texture = null
	if not centered:
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
func set_sprite_frames(new_frames: Array[SpriteFrames]) -> void:
	sprite_frames = new_frames
	if sprite_frames.is_empty():
		_delegate.set_sprite_frames(null)
	else:
		_delegate.set_sprite_frames(sprite_frames[0])
	if Engine.is_editor_hint():
		notify_property_list_changed()
	for layer_index in sprite_frames.size():
		var layer_node: TextureRect
		if layer_index < get_child_count():
			layer_node = get_child(layer_index)
		else:
			layer_node = TextureRect.new()
			#layer_node.name = layer.resource_name
			add_child(layer_node)
		for prop in get_property_list():
			if prop.usage & (PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_GROUP | PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SUBGROUP | PROPERTY_USAGE_NEVER_DUPLICATE) == 0 :
				if prop.name not in ["name", "texture", "frame", "self_modulate", "sprite_frames", "centered", "offset", "position", "unique_name_in_owner", "global_position"]:
					layer_node.set(prop.name, get(prop.name))
		layer_node.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer_node.position = Vector2.ZERO

	for too_much in range(sprite_frames.size(), get_child_count()):
		var child = get_child(too_much)
		if is_instance_valid(child):
			remove_child(child)
			child.queue_free()

	queue_redraw()

func get_sprite_frames() -> Array[SpriteFrames]:
	return sprite_frames
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
