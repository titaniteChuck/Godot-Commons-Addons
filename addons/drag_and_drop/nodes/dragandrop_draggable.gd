class_name DragAndDrop_Draggable extends Control

signal drag_requested
signal drag_successful(dragged_data: Variant)
signal drag_failed(dragged_data: Variant)

var dragged_data: DragAndDrop_Data

func _ready():
	name = "DragAndDrop_Draggable"

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		visible = false
	if what == NOTIFICATION_DRAG_END:
		if dragged_data:
			if not get_viewport().gui_is_drag_successful():
				drag_failed.emit(dragged_data.data)
			dragged_data = null
		visible = true

func _get_drag_data(_at_position:Vector2) -> DragAndDrop_Data:
	drag_requested.emit()
	if dragged_data:
		dragged_data.emitter = self
		set_drag_preview(dragged_data.preview)
	return dragged_data

func trigger_force_drag() -> void:
	drag_requested.emit()
	if dragged_data:
		dragged_data.emitter = self
		force_drag(dragged_data, dragged_data.preview)

func set_drag_data(data: Variant, preview: Control):
	dragged_data = DragAndDrop_Data.new()
	dragged_data.emitter = self
	dragged_data.data = data
	dragged_data.preview = preview
	if dragged_data.preview:
		dragged_data.preview.name = "DragAndDrop_Preview_" + dragged_data.preview.name

func _drop_node_is_also_draggable() -> bool:
	return get_parent().get_children()\
						.any(func(child): return child is DragAndDrop_Droppable)

func _get_draggable_node_in_drop_node() -> DragAndDrop_Droppable:
	return get_parent().get_children()\
						.filter(func(child): return child is DragAndDrop_Droppable)[0]
