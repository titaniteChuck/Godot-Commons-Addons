@tool
class_name SceneManager_TransitionData extends Resource

@export var type: Transition_Manager.OPERATION_TYPE = Transition_Manager.OPERATION_TYPE.LOAD:
	set(value):
		type = value
		notify_property_list_changed()

@export_group("What to unload")
@export var node_to_unload: NodePath = NodePath():
	set(value):
		node_to_unload = value
		notify_property_list_changed()

@export_group("What to load")
@export_file("PackedScene") var scene_path_to_load: String = "":
	set(value):
		scene_path_to_load = value
		notify_property_list_changed()

@export_subgroup("Where to load")
@export var load_into_path: NodePath = NodePath("/root"):
	set(value):
		if value != load_into_path:
			load_into_path = value
			notify_property_list_changed()
@export var load_into_position:int = -1

@export_subgroup("Transition to use")
@export var transition: Transition_Manager.TRANSITION_TYPE = Transition_Manager.TRANSITION_TYPE.NONE:
	set(value):
		transition = value
		notify_property_list_changed()
@export var transiton_duration := 0.3
@export var transition_tween_type := Tween.TransitionType.TRANS_SINE

# TRANSITION_TYPE = FADE
@export var fade_color: Color = Color.BLACK

# TRANSITION_TYPE = SLIDE
@export var slide_direction: Vector2i

# TRANSITION_TYPE = CUSTOM
@export var loading_screen: PackedScene
@export var anim_player_transition_name: String = ""

@export_group("Following transition")
@export var next_transition: SceneManager_TransitionData

func _get_property_list() -> Array[Dictionary]:
	var output: Array[Dictionary] = []

	return output

func _validate_property(property: Dictionary):
	if property.name in ["type", "Following transition", "next_transition"]: return

	var old_usage = property.usage

	property.usage = PROPERTY_USAGE_NO_EDITOR

	if type == Transition_Manager.OPERATION_TYPE.LOAD:
		if property.name in ["What to load", "scene_path_to_load"]:
			property.usage = old_usage

	elif type == Transition_Manager.OPERATION_TYPE.UNLOAD:
		if property.name in ["What to unload", "node_to_unload"]:
			property.usage = old_usage

	if scene_path_to_load:
		if property.name in ["scene_path_to_load"]:
			property.usage = old_usage

	if scene_path_to_load:
		if property.name in ["load_into_path", "load_into_position", "init_method"]:
			property.usage = old_usage

	if node_to_unload or scene_path_to_load:
		if property.name in ["Transition to use", "transition"]:
			property.usage = old_usage

		if transition == Transition_Manager.TRANSITION_TYPE.SLIDE:
			if property.name in ["transiton_duration", "transition_tween_type", "slide_direction"]:
				property.usage = old_usage
		if transition == Transition_Manager.TRANSITION_TYPE.FADE:
			if property.name in ["transiton_duration", "transition_tween_type", "fade_color"]:
				property.usage = old_usage
		if transition == Transition_Manager.TRANSITION_TYPE.CUSTOM:
			if property.name in ["loading_screen", "anim_player_transition_name"]:
				property.usage = old_usage

	pass

func equals(other: Variant):
	if not other or other is not SceneManager_TransitionData:
		return false
	other = other as SceneManager_TransitionData
	return type == other.type and\
			(node_to_unload == other.node_to_unload or scene_path_to_load == other.scene_path_to_load)
