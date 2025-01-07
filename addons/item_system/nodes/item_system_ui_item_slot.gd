class_name ItemSystem_UI_ItemSlot extends PanelContainer

signal pressed

@export var texture_node: TextureRect
@export var name_node: Label
@export var quantity_node: Label
@export var button_node: Button:
	set(value):
		button_node = value
		if button_node:
			button_node.pressed.connect(pressed.emit)
@export var part_of_inventory: ItemSystem_Inventory
#TODO implement can_receive(item_stack) with max_stack
@export var max_item_in_stack := 0
@export var is_draggable := true
@export var is_droppable := true
@export var switch_enabled := true

@export var item_type: ItemSystem_Item.Type = ItemSystem_Item.Type.NONE
@export var item_subtype: ItemSystem_Item.SubType = ItemSystem_Item.SubType.NONE

@export var texture_placeholder: Texture2D

@export var slot_index: int = -1:
	set(value):
		if slot_index != value:
			slot_index = value
			_read_model()

var draggable: DragAndDrop_Draggable
var droppable: DragAndDrop_Droppable

func _ready() -> void:
	var parent = button_node if button_node else self # to have press + drag, draggable should be a child of button, to propgate up
	if is_draggable:
		draggable = DragAndDrop_Draggable.new()
		draggable.mouse_filter = Control.MOUSE_FILTER_PASS
		parent.add_child(draggable)
		draggable.size = size
		draggable.set_anchors_preset(Control.PRESET_FULL_RECT)
		draggable.drag_requested.connect(_on_drag_requested)
		draggable.drag_successful.connect(_on_drag_success)
		draggable.drag_failed.connect(_on_drag_failure)
	if is_droppable:
		droppable = DragAndDrop_Droppable.new()
		droppable.mouse_filter = Control.MOUSE_FILTER_PASS
		parent.add_child(droppable)
		droppable.size = size
		droppable.set_anchors_preset(Control.PRESET_FULL_RECT)
		droppable.data_dropped.connect(_receive_drag_data)
		droppable._can_drop_data_overridable = _can_drop_data_overridable

func get_slot_item() -> ItemSystem_ItemStack:
	return part_of_inventory.item_stacks[slot_index] if part_of_inventory and slot_index < part_of_inventory.item_stacks.size() else null

func has_slot_item() -> bool:
	var slot_stack = get_slot_item()
	if slot_stack == null:
		return false
	return slot_stack.item != null

func _read_model():
	assert(part_of_inventory)
	part_of_inventory.changed.connect(queue_redraw)
	queue_redraw()

func _draw():
	var has_item: bool = has_slot_item()
	if name_node:
		name_node.text = get_slot_item().item.name if has_item else ""
	if texture_node:
		texture_node.texture = get_slot_item().item.texture2D if has_item else texture_placeholder
	if quantity_node:
		quantity_node.text = str(get_slot_item().quantity) if has_item else ""

func _get_drag_preview() -> Control:
	var preview = duplicate(true)
	preview.size = size
	return preview
	

# DragAndDrop support
# Draggable
func _on_drag_requested() -> void:
	if not get_slot_item():
		return
	var data = get_slot_item().duplicate()
	draggable.set_drag_data(data, _get_drag_preview())
	part_of_inventory.remove_at(slot_index)

func _on_drag_success(data: ItemSystem_ItemStack):
	pass

func _on_drag_failure(data: ItemSystem_ItemStack):
	if data:
		part_of_inventory.add_item_stack(data, slot_index)

# Droppable
func _can_drop_data_overridable(_at_position: Vector2, data: DragAndDrop_Data) -> bool:
	if data.data is not ItemSystem_ItemStack: 
		return false
	var incoming_stack = data.data as ItemSystem_ItemStack
	if item_type != ItemSystem_Item.Type.NONE and incoming_stack.item.type != item_type:
		return false
	if item_subtype != ItemSystem_Item.SubType.NONE and incoming_stack.item.subtype != item_subtype:
		return false
	return true
		
func _receive_drag_data(data: DragAndDrop_Data) -> void:
	if data.data is not ItemSystem_ItemStack: 
		droppable.reject_drop()
		return
	var incoming_stack = data.data as ItemSystem_ItemStack
	if item_type != ItemSystem_Item.Type.NONE and incoming_stack.item.type != item_type:
		droppable.reject_drop()
		return
	if item_subtype != ItemSystem_Item.SubType.NONE and incoming_stack.item.subtype != item_subtype:
		droppable.reject_drop()
		return
	var error := OK
	if not get_slot_item() or incoming_stack.item.equals(get_slot_item().item):
		var current_quantity = part_of_inventory.get_quantity(incoming_stack.item)
		var total_quantity = incoming_stack.quantity + current_quantity
		if max_item_in_stack > 0 and total_quantity > max_item_in_stack:
			# only add what's needed to reach the limit
			incoming_stack.quantity = max_item_in_stack - current_quantity
		part_of_inventory.add_item_stack(incoming_stack.duplicate(), slot_index)
		if max_item_in_stack > 0 and total_quantity > max_item_in_stack:
			# Fail the drop operation with what was not added to the stack
			incoming_stack.quantity = total_quantity - max_item_in_stack
			error = ERR_CANT_ACQUIRE_RESOURCE
	elif switch_enabled:
		if data.emitter._drop_node_is_also_draggable():
			data.data = get_slot_item()
			part_of_inventory.remove_at(slot_index)
			part_of_inventory.add_item_stack(incoming_stack, slot_index)
		error = ERR_BUSY
	else:
		error = ERR_BUSY
		
	if error != OK:
		droppable.reject_drop()
