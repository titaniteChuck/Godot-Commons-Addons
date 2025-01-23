@tool
class_name ItemSystem_InventorySlotControl extends Button

signal quick_move_requested

@export var item_stack: ItemSystem_ItemStack:
	set(value):
		if item_stack != value:
			item_stack = value
			if item_stack and not item_stack.changed.is_connected(_update_state):
				item_stack.changed.connect(_update_state)
			_update_state()

@export var quantity_node: Label
@export var max_item_in_stack := 0
@export var is_draggable := true
@export var is_droppable := true
@export var switch_enabled := true

@export var item_type: ItemSystem_Item.Type = ItemSystem_Item.Type.NONE
@export var item_subtype: ItemSystem_Item.SubType = ItemSystem_Item.SubType.NONE

@export var texture_placeholder: Texture2D
@export var display_item_name := true:
	set(value):
		display_item_name = value
		_update_state()

var draggable: DragAndDrop_Draggable
var droppable: DragAndDrop_Droppable

var inventory_control: ItemSystem_InventoryControl:
	set(value):
		inventory_control = value
		_update_state()

func _ready() -> void:
	if is_draggable:
		draggable = DragAndDrop_Draggable.new()
		add_child(draggable)
		draggable._get_drag_data_delegate = func(): return item_stack.duplicate()
		draggable._get_drag_preview_delegate = func(): var preview = duplicate(true) ; preview.size = size ; return preview
		draggable.drag_requested.connect(_on_drag_requested)
		draggable.drag_successful.connect(_on_drag_success)
		draggable.drag_failed.connect(_on_drag_failure)
	if is_droppable:
		droppable = DragAndDrop_Droppable.new()
		add_child(droppable)
		droppable.data_dropped.connect(_receive_data_delegate)
		droppable._receive_data_delegate = _receive_data_delegate
		droppable._can_drop_data_delegate = _can_drop_data_delegate
	_update_state()


func _notification(what: int) -> void:
	if droppable:
		if what == NOTIFICATION_DRAG_BEGIN:
			disabled = not droppable._can_drop_data(Vector2.ZERO, get_viewport().gui_get_drag_data())
		if what == NOTIFICATION_DRAG_END:
			disabled = false


func _update_state():
	if not item_stack:
		return
	if quantity_node:
		quantity_node.text = str(item_stack.quantity) if item_stack.item else ""
	icon = item_stack.item.icon if item_stack.item else texture_placeholder
	text = item_stack.item.name if item_stack.item and display_item_name else ""
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		quick_move_requested.emit()


# DragAndDrop support
# Draggable
func _get_drag_data(_at_position:Vector2) -> DragAndDrop_Data:
	if not item_stack.item:
		return
	# We are the one receiving the mouse event, so we transmit it to the draggable
	# If the draggable was the one with the mouse detection, we would not do this call
	return draggable._get_drag_data(_at_position)


func _on_drag_requested() -> void:
	pass


func _on_drag_success(data: ItemSystem_ItemStack):
	item_stack.item = null
	item_stack.quantity = 0


func _on_drag_failure(data: ItemSystem_ItemStack):
	if data:
		item_stack.item = data.item
		item_stack.quantity = data.quantity


# Droppable
func _can_drop_data(_at_position:Vector2, data:Variant) -> bool:
	if not droppable:
		return false
	# We are the one receiving the mouse event, so we transmit it to the draggable
	# If the draggable was the one with the mouse detection, we would not do this call
	return droppable._can_drop_data(_at_position, data)


func _drop_data(_at_position:Vector2, data: Variant) -> void:
	if droppable:
		droppable._drop_data(_at_position, data)


func _can_drop_data_delegate(_at_position:Vector2, data:Variant) -> bool:
	var incoming_stack = data.data as ItemSystem_ItemStack
	if item_type != ItemSystem_Item.Type.NONE and incoming_stack.item.type != item_type:
		return false
	if item_subtype != ItemSystem_Item.SubType.NONE and incoming_stack.item.subtype != item_subtype:
		return false
	if not switch_enabled and item_stack and item_stack.item:
		return false
	if switch_enabled and item_stack and item_stack.item and not item_stack.item.equals(incoming_stack.item):
		return false
	return true


func _receive_data_delegate(_at_position: Vector2, data: Variant) -> Error:
	if data.data is not ItemSystem_ItemStack:
		return ERR_INVALID_DATA
	var incoming_stack = data.data as ItemSystem_ItemStack
	if item_type != ItemSystem_Item.Type.NONE and incoming_stack.item.type != item_type:
		return ERR_INVALID_DATA
	if item_subtype != ItemSystem_Item.SubType.NONE and incoming_stack.item.subtype != item_subtype:
		return ERR_INVALID_DATA

	var error := OK
	if not item_stack.item or incoming_stack.item.equals(item_stack.item):
		var current_quantity = item_stack.quantity
		var new_quantity = current_quantity + incoming_stack.quantity
		var total_quantity = incoming_stack.quantity + current_quantity
		if max_item_in_stack > 0 and total_quantity > max_item_in_stack:
			incoming_stack.quantity = total_quantity - max_item_in_stack
			new_quantity = min(new_quantity, max_item_in_stack)
			error = ERR_CANT_ACQUIRE_RESOURCE
		item_stack.item = incoming_stack.item
		item_stack.quantity = new_quantity
	elif switch_enabled:
		if data.emitter._emitter_is_also_droppable():
			var replace_with = item_stack.duplicate()
			item_stack.item = incoming_stack.item
			item_stack.quantity = incoming_stack.quantity
			data.data = replace_with
		error = ERR_BUSY
	else:
		error = ERR_BUSY

	return error
