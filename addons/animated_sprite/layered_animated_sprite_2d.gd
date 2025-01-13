@tool
class_name LayeredAnimatedSprite2D extends Sprite2D

signal animation_changed
signal animation_finished
signal animation_looped
signal sprite_frames_changed

@export_subgroup("Animation")
@export var sprite_frames: Array[SpriteFrames]: set = set_sprite_frames, get = get_sprite_frames
@export_storage var animation: StringName: set = set_animation, get = get_animation
@export var speed_scale: float = 1.0 : set = set_speed_scale, get = get_speed_scale
@export_storage var autoplay: StringName: set = set_autoplay, get = get_autoplay

var _delegate := AnimatedSpriteDelegate.new()
var frame_progress: float : set = set_frame_progress, get = get_frame_progress

var _frame_changed_by_delegate := false

var delegate_frames: SpriteFrames

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	if sprite_frames:
		var temp_dict: Dictionary = {}
		for one_spriteframe in sprite_frames:
			for animation_name in one_spriteframe.get_animation_names():
				temp_dict[animation_name] = null
		properties.append({
			"name": "animation",
			"type": TYPE_STRING_NAME,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(temp_dict.keys()),
		})
		properties.append({
			"name": "autoplay",
			"type": TYPE_STRING_NAME,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(temp_dict.keys()),
		})
	return properties

func _ready() -> void:
	frame = 0
	frame_changed.connect(_on_frame_changed)
	_delegate.frame_changed.connect(_on_delegate_frame_changed)
	_delegate.animation_changed.connect(_on_animation_changed)
	_delegate.animation_finished.connect(animation_finished.emit)
	_delegate.animation_looped.connect(animation_looped.emit)
	_delegate.sprite_frames_changed.connect(_on_sprite_frames_changed)
	_delegate._ready()

func _process(delta: float) -> void:
	if _delegate:
		_delegate._process(delta)

func _on_sprite_frames_changed() -> void:
	queue_redraw()
	sprite_frames_changed.emit()


func _on_frame_changed():
	if _frame_changed_by_delegate:
		_frame_changed_by_delegate = false
	else:
		_delegate.frame = frame

func _on_delegate_frame_changed():
	_frame_changed_by_delegate = true
	hframes = _delegate.sprite_frames.get_frame_count(animation)
	frame = _delegate.frame
	queue_redraw()

func _on_animation_changed():
	queue_redraw()
	animation_changed.emit()

func _draw():
	if not is_inside_tree(): await ready
	for index in get_child_count():
		var layer_node: Sprite2D = get_child(index)
		if sprite_frames and sprite_frames[index] and sprite_frames[index].has_animation(animation):
			layer_node.texture = sprite_frames[index].get_frame_texture(animation, _delegate.frame)
		else:
			layer_node.texture = null

#region getters/setters
func set_animation(value: StringName) -> void:
	if not is_inside_tree(): await ready
	_delegate.set_animation(value)
	if not _delegate.sprite_frames and sprite_frames:
		_delegate.sprite_frames = sprite_frames.filter(func(el): return el.has_animation(animation)).front()

	hframes = _delegate.sprite_frames.get_frame_count(animation) if _delegate.sprite_frames else 1
	queue_redraw()

func get_animation() -> StringName:
	return _delegate.animation

func set_sprite_frames(new_frames: Array[SpriteFrames]) -> void:
	if not is_inside_tree(): await ready
	sprite_frames = new_frames
	texture = null
	self_modulate = Color.TRANSPARENT
	_delegate.sprite_frames = null
	if new_frames and new_frames.any(func(el): return el.has_animation(animation)):
		_delegate.sprite_frames = new_frames.filter(func(el): return el.has_animation(animation)).front()
	hframes = _delegate.sprite_frames.get_frame_count(animation) if _delegate.sprite_frames else 1
	notify_property_list_changed()
	for layer_index in sprite_frames.size():
		var layer_node: Sprite2D
		if layer_index < get_child_count(true):
			layer_node = get_child(layer_index)
		else:
			layer_node = Sprite2D.new()
			add_child(layer_node)
		_transfer_properties_to_child(layer_node)

	if not sprite_frames.is_empty():
		for too_much in range(sprite_frames.size(), get_child_count()):
			var child = get_child(too_much)
			if is_instance_valid(child):
				remove_child(child)
				child.queue_free()

	queue_redraw()

func _transfer_properties_to_child(node: Sprite2D):
	for prop in get_property_list():
		if prop.usage & (PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_GROUP | PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SUBGROUP | PROPERTY_USAGE_NEVER_DUPLICATE) == 0 :
			if prop.name not in ["name", "texture", "frame", "hframes", "vframes", "modulate", "self_modulate", "sprite_frames", "centered", "offset", "position", "unique_name_in_owner", "global_position"]:
				node.set(prop.name, get(prop.name))
	node.position = Vector2.ZERO

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
