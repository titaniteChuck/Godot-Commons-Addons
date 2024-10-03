@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("SceneManager", "autoload/scene_manager.tscn")

func _exit_tree() -> void:
	remove_autoload_singleton("SceneManager")