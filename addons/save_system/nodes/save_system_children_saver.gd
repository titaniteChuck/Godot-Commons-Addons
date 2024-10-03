class_name SaveSystem_ChildrenSaver extends Node

func _ready() -> void:
	SaveSystem.save_requested.connect(_on_save_requested)
	SaveSystem.load_requested.connect(_on_load_request)

func _on_save_requested():
	if is_inside_tree():
		SaveSystem.save_entity(get_path().get_concatenated_names()+":elements", get_children())

func _on_load_request():
	if is_inside_tree():
		var from_save = SaveSystem.load_entity(get_path().get_concatenated_names()+":elements")
		for child in get_children():
			remove_child(child)
			child.queue_free()
		for el in from_save:
			add_child(el)
