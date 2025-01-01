class_name ItemSystem_UI_ItemSlot extends Button

@export var item_texture: TextureRect
@export var item_name: Label
@export var item_quantity: Label
@export var part_of_inventory: ItemSystem_Inventory
#TODO implement can_receive(item_stack) with max_stack
@export var max_item_in_stack := 0
@export var is_draggable := true
@export var is_droppable := true
@export var switch_enabled := true

@export var slot_index: int = -1:
	set(value):
		if slot_index != value:
			slot_index = value
			_read_model()

var draggable: DragAndDrop_Draggable
var droppable: DragAndDrop_Droppable

func _ready() -> void:
	if is_draggable:
		draggable = DragAndDrop_Draggable.new()
		add_child(draggable)
		draggable.drag_requested.connect(_on_drag_requested)
		draggable.drag_successful.connect(_on_drag_success)
		draggable.drag_failed.connect(_on_drag_failure)
	if is_droppable:
		droppable = DragAndDrop_Droppable.new()
		add_child(droppable)
		droppable.data_dropped.connect(_receive_drag_data)
	_update_ui()

func get_slot_item() -> ItemSystem_ItemStack:
	return part_of_inventory.item_stacks[slot_index] if part_of_inventory else null

func _read_model():
	assert(part_of_inventory)
	part_of_inventory.changed.connect(_update_ui)
	_update_ui()

func _update_ui():
	if not is_inside_tree(): 
		await ready
	var slot_item: ItemSystem_ItemStack = get_slot_item()
	if item_name:
		item_name.text = slot_item.item.id if slot_item else ""
	if item_texture:
		item_texture.texture = slot_item.item.texture2D if slot_item else null
	if item_quantity:
		item_quantity.text = str(get_slot_item().quantity) if slot_item else ""

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
func _receive_drag_data(data: DragAndDrop_Data) -> void:
	if data.data is not ItemSystem_ItemStack: 
		droppable.reject_drop()
		return
	var incoming_stack = data.data as ItemSystem_ItemStack
	var error := OK
	if not get_slot_item():
		part_of_inventory.add_item_stack(incoming_stack, slot_index)
	elif incoming_stack.item.equals(get_slot_item().item):
		part_of_inventory.add_item_stack(incoming_stack, slot_index)
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
