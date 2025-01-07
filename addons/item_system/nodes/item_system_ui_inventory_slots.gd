class_name ItemSystem_UI_InventorySlots extends Control

@export var inventory: ItemSystem_Inventory:
	set(value):
		if inventory != value:
			inventory = value
			_read_model()
@export var ui_slots: Array[ItemSystem_UI_ItemSlot] = []

@export var generate_slots := false
@export var slot_factory: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_slots()
	pass # Replace with function body.
	
func _init_slots():
	if not ui_slots:
		ui_slots = []
		ui_slots.assign(get_children().filter(func(child): return child is ItemSystem_UI_ItemSlot))
	
	
func _read_model():
	if not is_inside_tree(): await draw
	if inventory:
		if not inventory.changed.is_connected(queue_redraw):
			inventory.changed.connect(queue_redraw)
		for item in inventory.item_stacks:
			if item and not item.changed.is_connected(queue_redraw):
				item.changed.connect(queue_redraw)
		inventory.set_minimum_size(ui_slots.size())
		for index in range(ui_slots.size()):
			ui_slots[index].part_of_inventory = inventory
			ui_slots[index].slot_index = index
		queue_redraw()

func _draw():
	if not is_inside_tree(): await draw
	if ui_slots.is_empty() and generate_slots and slot_factory:
		for child in get_children():
			remove_child(child)
			child.queue_free()
		ui_slots.resize(inventory.item_stacks.size())
		for index in range(inventory.item_stacks.size()):
			ui_slots[index] = slot_factory.instantiate()
	for index in range(ui_slots.size()):
		ui_slots[index].part_of_inventory = inventory
		ui_slots[index].slot_index = index
		ui_slots[index].queue_redraw()
