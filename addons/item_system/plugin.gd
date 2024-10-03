@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("ItemSystem", "autoload/item_system.tscn")

func _exit_tree() -> void:
	remove_autoload_singleton("ItemSystem")
