class_name DragAndDrop_Draggable extends Control

signal drag_requested(dragged_data: Variant)
signal drag_successful(dragged_data: Variant)
signal drag_failed(dragged_data: Variant)

var dragged_data: DragAndDrop_Data
var is_force_dragging: bool = false

func _ready():
	name = "DragAndDrop_Draggable"
	dragged_data = DragAndDrop_Data.new()
	dragged_data.emitter = self
	dragged_data.drop_complete.connect(_on_drop_successfull.bind(dragged_data))
	dragged_data.drop_rejected.connect(_on_drop_rejected.bind(dragged_data))


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		visible = false
	if what == NOTIFICATION_DRAG_END:
		if dragged_data.data and not is_force_dragging: # usefull if drop does not end in a Droppable
			if not get_viewport().gui_is_drag_successful():
				_on_drop_rejected(dragged_data)

func _is_dragging():
	return dragged_data.data != null

func _end_drag() -> void:
	dragged_data.data = null
	dragged_data.preview = null
	dragged_data.receiver = null
	is_force_dragging = false
	visible = true
	if is_instance_valid(dragged_data.preview):
		dragged_data.preview.queue_free()

func _get_drag_data(_at_position:Vector2) -> DragAndDrop_Data:
	var drag_data: Array[Variant] = _get_drag_data_delegate.call()
	dragged_data.data = drag_data.get(0)
	dragged_data.preview = drag_data.get(1)
	if dragged_data.preview:
		set_drag_preview(dragged_data.preview)
	drag_requested.emit(dragged_data.data)
	return dragged_data if dragged_data.data else null

func trigger_force_drag() -> void:
	var drag_data: Array[Variant] = _get_drag_data_delegate.call()
	dragged_data.data = drag_data.get(0)
	if dragged_data.data:
		dragged_data.preview = drag_data.get(1)
		drag_requested.emit(dragged_data.data)
		is_force_dragging = true

func trigger_force_drop() -> void:
	var hovered_control: Control = get_viewport().gui_get_hovered_control()
	if hovered_control:
		var hovered_droppable: DragAndDrop_Droppable = _look_for_droppable()
		if hovered_droppable and hovered_droppable._can_drop_data(hovered_droppable.position, dragged_data):
			hovered_droppable._drop_data(hovered_droppable.position, dragged_data)
		else:
			dragged_data.drop_rejected.emit()
	else:
		dragged_data.drop_rejected.emit()
	get_viewport().gui_cancel_drag()

func cancel_force_drag() -> void:
	if _is_dragging():
		dragged_data.drop_rejected.emit()
		_end_drag()

func _look_for_droppable() -> DragAndDrop_Droppable:
	var output: DragAndDrop_Droppable = null
	var hovered_control: Control = get_viewport().gui_get_hovered_control()
	if not hovered_control:
		return output
	if hovered_control is DragAndDrop_Droppable:
		output = hovered_control
	else:
		var as_a_child: Node = hovered_control.get_children().filter(func(child): return child is DragAndDrop_Droppable).pop_front()
		if as_a_child is DragAndDrop_Droppable:
			output = as_a_child
		else:
			var as_a_sibling: Node = hovered_control.get_parent().get_children().filter(func(child): return child is DragAndDrop_Droppable).pop_front()
			if as_a_sibling is DragAndDrop_Droppable:
				output = as_a_sibling
	return output

func _process(delta: float) -> void:
	if is_force_dragging:
		force_drag(dragged_data, dragged_data.preview.duplicate() if dragged_data.preview else null)

func _on_drop_successfull(successful_data: DragAndDrop_Data):
	drag_successful.emit(successful_data.data)
	if dragged_data == successful_data:
		_end_drag()

func _on_drop_rejected(dragged_data: DragAndDrop_Data):
	drag_failed.emit(dragged_data.data)
	_end_drag()

var _get_drag_data_delegate: Callable = func() -> Array[Variant]:
	return [get_parent(), null]

func _emitter_is_also_droppable() -> bool:
	return get_parent().get_children()\
						.any(func(child): return child is DragAndDrop_Droppable)

func _get_draggable_node_in_drop_node() -> DragAndDrop_Droppable:
	return get_parent().get_children()\
						.filter(func(child): return child is DragAndDrop_Droppable).get(0)
