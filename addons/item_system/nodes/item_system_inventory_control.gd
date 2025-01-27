@tool
class_name ItemSystem_InventoryControl extends Control

@export var inventory: ItemSystem_Inventory:
	set(value):
		if inventory != value:
			inventory = value
			_read_model()
@export var ui_slots: Array[ItemSystem_InventorySlotControl] = []

@export_subgroup("Slot Generation")
@export var generate_slots := false:
	set(value):
		generate_slots = value
		_init_slots()
@export var slots_parent: Node = $".":
	set(value):
		if not value:
			return
		if slots_parent and slots_parent != value and is_instance_valid(slots_parent):
			for child in slots_parent.get_children():
				if child == value:
					continue
				slots_parent.remove_child(child)
				child.queue_free()
		slots_parent = value
		_init_slots()
@export var slot_factory: PackedScene = preload("res://addons/item_system/nodes/item_system_inventory_slot_control.tscn")
@export var slot_min_size: Vector2 = Vector2.ZERO:
	set(value):
		slot_min_size = value
		_init_slots()
@export var expand_slots := true:
	set(value):
		expand_slots = value
		_init_slots()
@export var show_in_tree := true:
	set(value):
		show_in_tree = value
		_init_slots()

@export var can_speak := false

func _ready() -> void:
	_init_slots()


func _init_slots():
	if generate_slots and slots_parent:
		if not slot_factory:
			push_error("No slot factory defined")
			return
		for child in slots_parent.get_children():
			slots_parent.remove_child(child)
			child.queue_free()

		ui_slots.clear()
		if inventory:
			for inventory_stack in inventory.slots:
				var new_slot = slot_factory.instantiate()
				slots_parent.add_child(new_slot, true)
				if show_in_tree:
					new_slot.owner = owner
				if expand_slots:
					new_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					new_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
				new_slot.custom_minimum_size = slot_min_size
		ui_slots.assign(_find_slot_controls())


	elif not ui_slots:
		ui_slots = []
		ui_slots.assign(_find_slot_controls())

	queue_redraw()


func _find_slot_controls(node: Node = slots_parent) -> Array[ItemSystem_InventorySlotControl]:
	var output: Array[ItemSystem_InventorySlotControl] = []
	for child in node.get_children():
		if child is ItemSystem_InventorySlotControl:
			output.append(child)
		else:
			output.append_array(_find_slot_controls(child))
	return output


func _read_model():
	_init_slots()
	if inventory:
		if not inventory.changed.is_connected(_init_slots):
			inventory.changed.connect(_init_slots)
		queue_redraw()


func _draw():
	if inventory:
		if inventory.slots.size() != ui_slots.size():
			push_error("Inventory stacks / Control Slots don't match (%s / %s)" % [inventory.slots.size(), ui_slots.size()])
			return

		for index in ui_slots.size():
			if ui_slots[index]:
				ui_slots[index].item_stack = inventory.slots[index]
				ui_slots[index].inventory_control = self

	for index in ui_slots.size():
		if ui_slots[index]:
			ui_slots[index].queue_redraw()
