class_name Scene_Manager extends Node

#region ####################### Transition Manager ################################
signal transition_finished(caller_node: Variant, data: SceneManager_TransitionData)
signal node_loaded(data: SceneManager_TransitionData, node: Node)

var transition_manager: Transition_Manager

func play_transition(caller_node: Node, data: SceneManager_TransitionData) -> void:
	await transition_manager.play_transition(caller_node, data)
#endregion

#region ####################### Scene Loader ################################
signal load_progress(progress_in_percent: float)
signal load_complete(loaded_scene: Node)
signal load_failed
signal invalid_resource

var scene_loader: Scene_Loader

func load_async(scenePath: String) -> void:
	return scene_loader.load_async(scenePath)
	
func load_sync(scenePath: String) -> PackedScene:
	return scene_loader.load_sync(scenePath)
#endregion

func _ready():
	scene_loader = get_node("Scene_Loader")
	if not scene_loader:
		scene_loader = Scene_Loader.new()
	scene_loader.load_progress.connect(load_progress.emit)
	scene_loader.load_complete.connect(load_complete.emit)
	scene_loader.load_failed.connect(load_failed.emit)
	scene_loader.invalid_resource.connect(invalid_resource.emit)
		
		
	transition_manager = get_node("Transition_Manager")
	if not transition_manager:
		transition_manager = Transition_Manager.new()
	
	transition_manager.transition_finished.connect(transition_finished.emit)
	transition_manager.node_loaded.connect(node_loaded.emit)
