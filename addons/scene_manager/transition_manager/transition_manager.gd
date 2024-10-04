class_name Transition_Manager extends Node

signal node_loaded(data: SceneManager_TransitionData, node: Node)
signal transition_finished(caller_node: Variant, data: SceneManager_TransitionData)

var _loading_screen:LoadingScreen	## internal - reference to loading screen instance

enum TRANSITION_TYPE {NONE,SLIDE,FADE, CUSTOM}
enum OPERATION_TYPE {LOAD, UNLOAD}

@export var default_root_path := "/"

var _transition_queue: Array[SceneManager_TransitionData] = []
func _ready():
	transition_finished.connect(_end_animation)
	pass

#region ####################### Main lifecycle ################################
func play_transition(caller_node: Node, data: SceneManager_TransitionData) -> void:
	if not _should_process(caller_node, data):
		return
	await _play_transition(caller_node, data, data)

func _play_transition(caller_node: Node, data: SceneManager_TransitionData, original_object: SceneManager_TransitionData) -> void:
	if not _should_process(caller_node, data):
		return

	_transition_queue.append(data)

	if data.type == OPERATION_TYPE.LOAD:
		await play_load(caller_node, data, original_object)
	if data.type == OPERATION_TYPE.UNLOAD:
		await play_unload(caller_node, data)

	transition_finished.emit(caller_node, data)
	
	if data.next_transition:
		await _play_transition(caller_node, data.next_transition, original_object)
	

func _should_process(caller_node: Node, data: SceneManager_TransitionData) -> bool:
	if not (is_instance_valid(caller_node) and is_instance_valid(data)):
		return false
	for data_in_queue in _transition_queue:
		if data_in_queue.equals(data):
			return false
	return true

func _end_animation(caller_node: Variant, data: SceneManager_TransitionData) -> void:
	#if is_instance_valid(caller_node) and caller_node != get_tree().root and data.next_transition == null:
		#caller_node.get_parent().remove_child(caller_node)
		#caller_node.queue_free()
	if data.type == OPERATION_TYPE.UNLOAD:
		var node_to_unload = caller_node.get_node(data.node_to_unload)
		if is_instance_valid(node_to_unload) and node_to_unload != get_tree().root:
			node_to_unload.get_parent().remove_child(node_to_unload)
			node_to_unload.queue_free()

	_transition_queue.remove_at(_transition_queue.find(data))
	
#endregion

#region ####################### LOAD methods ################################
func play_load(caller_node: Node, data: SceneManager_TransitionData, original_object: SceneManager_TransitionData) -> Node:
	var node_to_load = _init_loaded_scene(caller_node, data)
	node_loaded.emit(original_object, node_to_load)
	match data.transition:
		TRANSITION_TYPE.NONE: pass
		TRANSITION_TYPE.SLIDE: await slide_in(node_to_load, data.slide_direction, data.transiton_duration, data.transition_tween_type)
		TRANSITION_TYPE.FADE: await fade_in(node_to_load, data.transiton_duration, data.transition_tween_type, data.fade_color)
		TRANSITION_TYPE.CUSTOM: pass
	return node_to_load

func _init_loaded_scene(caller_node: Node, data: SceneManager_TransitionData) -> Node:
	var load_into = _get_load_into(caller_node, data)

	var node_to_load = SceneManager.load_sync(data.scene_path_to_load).instantiate() as Node
	load_into.add_child(node_to_load)
	if data.load_into_position >= 0:
		load_into.move_child(node_to_load, clamp(data.load_into_position, 0, load_into.get_child_count()))
	return node_to_load

func _get_load_into(caller_node: Node, data: SceneManager_TransitionData) -> Node:
	var load_into: Node
	if data.load_into_path.is_absolute():
		load_into = get_node(data.load_into_path)
	else:
		load_into = caller_node.get_node(data.load_into_path)
	return load_into

#endregion

#region ####################### UNLOAD methods ################################
func play_unload(caller_node: Node, data: SceneManager_TransitionData) -> void:
	var node_to_unload = caller_node.get_node(data.node_to_unload)
	if is_instance_valid(node_to_unload) and node_to_unload != get_tree().root:
		match data.transition:
			TRANSITION_TYPE.NONE: pass
			TRANSITION_TYPE.SLIDE: await slide_out(node_to_unload, data.slide_direction, data.transiton_duration, data.transition_tween_type)
			TRANSITION_TYPE.FADE: await fade_out(node_to_unload, data.transiton_duration, data.transition_tween_type, data.fade_color)
			TRANSITION_TYPE.CUSTOM: pass
#endregion


func _display_loading_screen(data: SceneManager_TransitionData):
	if data.loading_screen:
		_loading_screen = data.loading_screen.instantiate()
		if not _loading_screen is LoadingScreen:
			push_warning("Provided loading screen does not inherit of the class LoadingScreen provided by this package. ignoring")
			return
		get_tree().root.add_child(_loading_screen)
		_loading_screen.start_transition(data.custom_transition_name, data.transition_duration / 2)
		await _loading_screen.loadingscreen_visible

#region ####################### Animation utils ################################
func slide_in(node: Node, direction: Vector2i, animation_duration: float = 1.0,  tween_function: Tween.TransitionType = Tween.TRANS_SINE):
	var start_position: Vector2 = get_viewport().get_visible_rect().size * Vector2(direction)
	var final_position: Vector2 = Vector2.ZERO
	if node is Control:
		start_position = Vector2(node.size) * Vector2(-direction)
		final_position = node.position
	await _slide(node, start_position, final_position, animation_duration, tween_function)
	
func slide_out(node: Node, direction: Vector2i, animation_duration: float = 1.0,  tween_function: Tween.TransitionType = Tween.TRANS_SINE):
	var final_position: Vector2 = get_viewport().get_visible_rect().size * Vector2(-direction)
	var start_position: Vector2 = Vector2.ZERO
	if node is Control:
		final_position = Vector2(node.size) * Vector2(direction)
		start_position = node.position
		
	await _slide(node, start_position, final_position, animation_duration, tween_function)
	
func _slide(node: Node, start_pos: Variant, end_pos: Variant, animation_duration: float = 1.0,  tween_function: Tween.TransitionType = Tween.TRANS_SINE):
	var nodes_to_animate: Array[Node] = _get_all_canvaslayers(node)
	
	if node is not CanvasLayer:
		nodes_to_animate.append(node)
	
	for to_animate in nodes_to_animate:
		var property = "position"
		var is_last_element = to_animate == nodes_to_animate.back()
		if to_animate is CanvasLayer:
			property = "offset"
		to_animate.set(property, start_pos)
		var tween:Tween = get_tree().create_tween()
		tween.tween_property(to_animate, property, end_pos, animation_duration).set_trans(tween_function)
		if is_last_element:
			await tween.finished

	
func tween_to_position(node: Node, final_position: Variant, animation_duration: float = 1.0,  tween_function: Tween.TransitionType = Tween.TRANS_SINE):
	var tween:Tween = get_tree().create_tween()
	tween.tween_property(node, "position", final_position, animation_duration).set_trans(tween_function)
	await tween.finished

func fade_out(node: Node, tween_duration := 1.0, tween_function := Tween.TRANS_SINE, fade_color := Color.BLACK):
	await _fade(node, Color.WHITE, fade_color, tween_duration, tween_function)

func fade_in(node: Node, tween_duration := 1.0, tween_function := Tween.TRANS_SINE, fade_color := Color.BLACK):
	await _fade(node, fade_color, Color.WHITE, tween_duration, tween_function)

func _fade(node: Node, start_color:= Color.WHITE, end_color := Color.BLACK, tween_duration := 1.0, tween_function := Tween.TRANS_SINE):
	var nodes_to_animate: Array[Node] = _get_all_canvaslayers(node)
	
	if node is not CanvasLayer:
		nodes_to_animate.append(node)
	
	var _temp_screens: Array[CanvasModulate]
	for to_animate in nodes_to_animate:
		var property = "modulate"
		var is_last_element = to_animate == nodes_to_animate.back()
		if to_animate is CanvasLayer:
			var _temp_screen = CanvasModulate.new()
			_temp_screen.name = "SceneManager_CanvasModulate"
			_temp_screens.append(_temp_screen)
			to_animate.add_child(_temp_screen)
			to_animate = _temp_screen
			property = "color"
		to_animate.set(property, start_color)
		var tween:Tween = get_tree().create_tween()
		tween.tween_property(to_animate, property, end_color, tween_duration).set_trans(tween_function)
		if is_last_element:
			await tween.finished

	for to_remove in _temp_screens:
		if is_instance_valid(to_remove) and to_remove != get_tree().root:
			to_remove.get_parent().remove_child(to_remove)
			to_remove.queue_free()

func _get_all_canvaslayers(parent: Node) -> Array[Node]:
	var output: Array[Node] = []
	if is_instance_valid(parent):
		if parent is CanvasLayer:
			output.append(parent)
		for child in parent.get_children():
			output.append_array(_get_all_canvaslayers(child))
	return output

#endregion
