@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("SaveSystem", "res://addons/save_system/autoload/save_system.tscn")
	pass


func _exit_tree() -> void:
	remove_autoload_singleton("SaveSystem")
	pass
