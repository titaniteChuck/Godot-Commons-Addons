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
		if dragged_data: # usefull if drop does not end in a Droppable
			if not get_viewport().gui_is_drag_successful():
				drag_failed.emit(dragged_data.data)
			dragged_data = null
		visible = true

func _get_drag_data(_at_position:Vector2) -> DragAndDrop_Data:
	dragged_data = DragAndDrop_Data.new()
	dragged_data.emitter = self
	dragged_data.data = _get_drag_data_delegate.call()
	dragged_data.preview = _get_drag_preview_delegate.call()
	if dragged_data.preview:
		dragged_data.preview.name = "DragAndDrop_Preview_" + dragged_data.preview.name
	dragged_data.drop_complete.connect(drag_successful.emit.bind(dragged_data.data))
	dragged_data.drop_rejected.connect(_on_drop_rejected.bind(dragged_data))
	drag_requested.emit()
	if dragged_data:
		dragged_data.emitter = self
		set_drag_preview(dragged_data.preview)
	return dragged_data

func _on_drop_rejected(dragged_data: DragAndDrop_Data):
	drag_failed.emit(dragged_data.data)

var _get_drag_data_delegate: Callable = func() -> Variant:
	return get_parent()

var _get_drag_preview_delegate: Callable = func() -> Control:
	return null

func _emitter_is_also_droppable() -> bool:
	return get_parent().get_children()\
						.any(func(child): return child is DragAndDrop_Droppable)

func _get_draggable_node_in_drop_node() -> DragAndDrop_Droppable:
	return get_parent().get_children()\
						.filter(func(child): return child is DragAndDrop_Droppable)[0]
