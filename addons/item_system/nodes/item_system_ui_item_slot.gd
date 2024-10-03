class_name ItemSystem_UI_ItemSlot extends Control

signal pressed

@export var part_of_inventory: ItemSystem_Inventory
#TODO implement can_receive(item_stack) with max_stack
@export var max_item_in_stack := 0
@export var is_draggable := true
@export var is_droppable := true

var slot_index: int = -1:
	set(value):
		if slot_index != value:
			slot_index = value
			_read_model()


@onready var item_texture: TextureRect = %ItemTexture
@onready var item_name: Label = %ItemName
@onready var item_quantity: Label = %ItemQuantity
@onready var button: Button = %Button

var draggable: DragAndDrop_Draggable
var droppable: DragAndDrop_Droppable

func _ready() -> void:
	if button:
		button.pressed.connect(pressed.emit)
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
	if not is_inside_tree(): return
	if get_slot_item():
		item_name.text = get_slot_item().item.id
		item_texture.texture = get_slot_item().item.texture2D
		item_quantity.text = str(get_slot_item().quantity)
	else:
		item_name.text = ""
		item_texture.texture = null
		item_quantity.text = ""

# DragAndDrop support
# Draggable
func _on_drag_requested() -> void:
	if not get_slot_item():
		return
	var data = get_slot_item().duplicate()
	var preview = $Slot_Parent.duplicate(true)
	preview.size = size
	draggable.set_drag_data(data, preview)
	part_of_inventory.remove_at(slot_index)

func _on_drag_success(data: ItemSystem_ItemStack):
	pass

func _on_drag_failure(data: ItemSystem_ItemStack):
	if data:
		part_of_inventory.add_item_stack(data, slot_index)

# Droppable
@export var switch_enabled := true
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
