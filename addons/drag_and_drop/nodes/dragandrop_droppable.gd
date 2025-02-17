class_name DragAndDrop_Droppable extends Control

signal drag_is_hovering(data: DragAndDrop_Data)
signal drag_stopped_hovering
signal data_dropped(data: DragAndDrop_Data)

var debug: bool = true
var receive_drag_data

func _ready():
	name = "DragAndDrop_Droppable"

func _can_drop_data(_at_position:Vector2, data:Variant) -> bool:
	var can_receive = true
	data = data as DragAndDrop_Data
	if not data:
		can_receive = false
	elif get_parent() == data.emitter.get_parent():
		can_receive = true
	else:
		can_receive = _can_drop_data_delegate.call(_at_position, data)
	return can_receive


var _can_drop_data_delegate: Callable = func(_at_position: Vector2, data: DragAndDrop_Data) -> bool:
	return true
var _receive_data_delegate: Callable = func(_at_position: Vector2, data: DragAndDrop_Data) -> bool:
	return true

func _drop_data(_at_position:Vector2, data: Variant) -> void:
	if debug: print("Droppable._drop_data")
	data = data as DragAndDrop_Data
	data.receiver = self
	if data.receiver.get_parent() == data.emitter.get_parent():
		data.drop_rejected.emit()
		return

	data_dropped.emit(data)
	if _receive_data_delegate.call(_at_position, data) == OK:
		data.drop_complete.emit()
	else:
		data.drop_rejected.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		visible = true
	if what == NOTIFICATION_DRAG_END:
		visible = false
