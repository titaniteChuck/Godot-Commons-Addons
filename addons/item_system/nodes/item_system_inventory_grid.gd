@tool
class_name ItemSystem_InventoryGrid extends Container

@export var inventory: ItemSystem_Inventory:
	set(value):
		if inventory != value:
			inventory = value
			_read_model()


@export_subgroup("Inventory Layout")
@export var columns: int = 1:
	set(value):
		if columns != value:
			columns = value
			_refresh()

@export var allow_span_slots: bool = false:
	set(value):
		if allow_span_slots != value:
			allow_span_slots = value
			_refresh()

@export_subgroup("Inventory properties")
@export var drag_mode: ItemSystem_InventorySlotControl.DragMode = ItemSystem_InventorySlotControl.DragMode.HOLD
@export var stack_management: ItemSystem_InventorySlotControl.StackManagement = ItemSystem_InventorySlotControl.StackManagement.REMOVE_ON_DROP
@export var switch_enabled: bool = true
@export var slots_are_draggable: bool = true
@export var slots_are_droppable: bool = true

@export_subgroup("Slot Generation")
enum SlotManagement {FIND_IN_CHILDREN, ADD_MANUALLY, GENERATED}
@export var slot_management: SlotManagement = SlotManagement.FIND_IN_CHILDREN:
	set(value):
		if slot_management != value:
			slot_management = value
			notify_property_list_changed()
			_init_slots()
@export var slots_parent: Node = $".":
	set(value):
		if not value:
			return
		if slots_parent and slots_parent != value and is_instance_valid(slots_parent):
			for child in slots_parent.get_children():
				if child == value or child is not Control:
					continue
				slots_parent.remove_child(child)
				child.queue_free()
		slots_parent = value
		_init_slots()

@export var slots: Array[ItemSystem_InventorySlotControl] = []

@export var trigger_generate := false:
	set(value):
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


func _validate_property(property: Dictionary) -> void:
	var fields_to_filter: Array[String] = ["slots_parent", "slots", "slot_factory", "slot_min_size", "expand_slots", "show_in_tree", "trigger_generate"]
	var fields_to_show: Array[String] = []
	if slot_management == SlotManagement.GENERATED:
		fields_to_show = ["slots_parent", "slot_factory", "slot_min_size", "expand_slots", "show_in_tree", "trigger_generate"]
	elif slot_management == SlotManagement.ADD_MANUALLY:
		fields_to_show = ["slots"]
	elif slot_management == SlotManagement.FIND_IN_CHILDREN:
		fields_to_show = ["slots_parent"]
	if property.name in fields_to_filter and not property.name in fields_to_show:
		property.usage = PROPERTY_USAGE_NONE

func _refresh():
	span_grid_controller = get_children().filter(func(child): return child is SpanGridController).pop_front()
	if not span_grid_controller:
		span_grid_controller = SpanGridController.new()
		span_grid_controller.name = "SpanGridController"
		add_child(span_grid_controller, true)
	span_grid_controller.grid_node = self
	span_grid_controller.columns = columns
	span_grid_controller.treat_as_grid = true
	span_grid_controller.disable_spanning = not allow_span_slots
	queue_sort()
	update_minimum_size()

func _ready() -> void:
	_init_slots()
	_refresh()

func _get_configuration_warnings():
	var warnings = []
	var parent = get_parent()
	if slot_management == SlotManagement.GENERATED and not slot_factory:
		return ["Generated Mode: No slot factory provided."]
	if inventory.stacks.size() != slots.size():
		push_error("Inventory stacks / Control Slots don't match (%s / %s)" % [inventory.stacks.size(), slots.size()])

	return warnings

func _init_slots():
	slots.clear()
	if slot_management == SlotManagement.GENERATED and slot_factory and slots_parent and Engine.is_editor_hint():
		for child in slots_parent.get_children():
			if child is Control:
				slots_parent.remove_child(child)
				child.queue_free()

		if inventory:
			for inventory_stack in inventory.stacks:
				var new_slot = slot_factory.instantiate()
				slots_parent.add_child(new_slot, true)
				if show_in_tree:
					new_slot.owner = owner
				if expand_slots:
					new_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					new_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
				new_slot.custom_minimum_size = slot_min_size
		slots.assign(_find_slot_controls())

	if slot_management in [SlotManagement.GENERATED, SlotManagement.FIND_IN_CHILDREN]:
		slots.assign(_find_slot_controls())

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
		if inventory.stacks.size() != slots.size():
			push_error("Inventory stacks / Control Slots don't match (%s / %s)" % [inventory.stacks.size(), slots.size()])
			return

		for index in slots.size():
			var slot: ItemSystem_InventorySlotControl = slots[index]
			if slot:
				slot.item_stack = inventory.stacks[index]
				slot.inventory_control = self
				slot.drag_mode = drag_mode
				slot.stack_management = stack_management
				slot.is_draggable = slots_are_draggable
				slot.is_droppable = slots_are_droppable
				slot.switch_enabled = switch_enabled

	for index in slots.size():
		if slots[index]:
			slots[index].queue_redraw()

func _notification(what):
	match what:
		Container.NOTIFICATION_SORT_CHILDREN:
			_handle_sort_children()

var span_grid_controller: SpanGridController
func _handle_sort_children():
	if span_grid_controller:
		span_grid_controller.columns = columns
		span_grid_controller._handle_sort_children()

func _get_minimum_size() -> Vector2:
	return span_grid_controller._get_minimum_size() if span_grid_controller else Vector2.ZERO

func can_insert_at(index: int, item: ItemSystem_Item) -> bool:
	var pos_in_grid: Vector2i = Vector2i(index % columns, index / columns)
	var span_size: Vector2i = Vector2i(item.slot_size.x, item.slot_size.y) if allow_span_slots else Vector2i(1, 1)
	if pos_in_grid.x + span_size.x > columns:
		return false

	for ci in span_size.x:
		for ri in span_size.y:
			var existing: SpanGridController.Cell = span_grid_controller.grid.get_cell(pos_in_grid + Vector2i(ci, ri))
			if not existing:
				return false
			if  not existing.is_origin:
				return false
			var slot: ItemSystem_InventorySlotControl = existing.content as ItemSystem_InventorySlotControl
			if slot.item_stack.item:
				return false

	return true
