@tool
class_name ItemSystem_InventoryControl extends Control

@export var inventory: ItemSystem_Inventory:
	set(value):
		if inventory != value:
			inventory = value
			_read_model()
@export var ui_slots: Array[ItemSystem_InventorySlotControl] = []
@export var generate_slots := false
@export var slot_factory: PackedScene = preload("res://addons/item_system/nodes/item_system_inventory_slot_control.tscn")

func _ready() -> void:
	_init_slots()

func _init_slots():
	if not ui_slots:
		ui_slots = []
		ui_slots.assign(get_children().filter(func(child): return child is ItemSystem_InventorySlotControl))

func _read_model():
	if inventory:
		if generate_slots and slot_factory:
			for child in ui_slots:
				remove_child(child)
				child.queue_free()
		queue_redraw()

func _draw():
	if inventory:
		if not ui_slots and generate_slots and slot_factory:
			for index in inventory.slots.size():
				ui_slots[index] = slot_factory.instantiate()

		if inventory.slots.size() != ui_slots.size():
			push_error("Inventory stacks / Control Slots don't match (%s / %s)" % [inventory.slots.size(), ui_slots.size()])
			return

		for index in ui_slots.size():
			ui_slots[index].item_stack = inventory.slots[index]

	for index in ui_slots.size():
		ui_slots[index].queue_redraw()
