class_name DragAndDrop_Data extends Object

signal drop_complete
signal drop_rejected

var emitter: DragAndDrop_Draggable
var receiver: DragAndDrop_Droppable
var data: Variant
var preview: Control

func duplicate() -> DragAndDrop_Data:
	var output: DragAndDrop_Data = DragAndDrop_Data.new()
	output.emitter = data.emitter
	output.receiver = data.receiver
	output.preview = data.preview
	output.data = data
	return output
