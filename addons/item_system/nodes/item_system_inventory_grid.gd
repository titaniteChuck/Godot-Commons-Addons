@tool
class_name ItemSystem_InventoryGrid extends Container

@export var inventory: ItemSystem_Inventory:
	set(value):
		if inventory != value:
			inventory = value
			_read_model()
@export var ui_slots: Array[ItemSystem_InventorySlotControl2] = []

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

@export var columns: int:
	set(value):
		if columns != value:
			columns = value
			_refresh()


func _refresh():
	queue_sort()
	update_minimum_size()

func _ready() -> void:
	_init_slots()
	if not span_grid_controller:
		span_grid_controller = SpanGridController.new()
		add_child(span_grid_controller, true)
	span_grid_controller.columns = columns
	update_minimum_size()
	if span_grid_controller:
		span_grid_controller._handle_sort_children()


func _init_slots():
	if generate_slots and slots_parent:
		if not slot_factory:
			push_error("No slot factory defined")
			return
		for child in slots_parent.get_children():
			if child is Control:
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


func _find_slot_controls(node: Node = slots_parent) -> Array[ItemSystem_InventorySlotControl2]:
	var output: Array[ItemSystem_InventorySlotControl2] = []
	for child in node.get_children():
		if child is ItemSystem_InventorySlotControl2:
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

func _notification(what):
	match what:
		Container.NOTIFICATION_SORT_CHILDREN:
			_handle_sort_children()

@onready var span_grid_controller: SpanGridController = $SpanGridController
func _handle_sort_children():
	if span_grid_controller:
		span_grid_controller.columns = columns
		span_grid_controller._handle_sort_children()

func _get_minimum_size() -> Vector2:
	return span_grid_controller._get_minimum_size() if span_grid_controller else Vector2.ZERO

func can_insert_at(index: int, item: ItemSystem_Item) -> bool:
	var pos_in_grid: Vector2i = Vector2i(index % columns, index / columns)
	var span_size: Vector2i = Vector2i(item.slot_size.x, item.slot_size.y)
	if pos_in_grid.x + item.slot_size.x > columns:
		return false

	for ci in item.slot_size.x:
		for ri in item.slot_size.y:
			var existing: SpanGridController.Cell = span_grid_controller.grid.get_cell(pos_in_grid + Vector2i(ci, ri))
			if not existing:
				return false
			if  not existing.is_origin:
				return false
			var slot = existing.content as ItemSystem_InventorySlotControl2
			if slot.item_stack.item:
				return false

	return true
