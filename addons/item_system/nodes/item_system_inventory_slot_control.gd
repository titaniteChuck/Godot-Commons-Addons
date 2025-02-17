@tool
class_name ItemSystem_InventorySlotControl extends Control

signal double_clicked
signal item_name_changed(text: String)
signal item_texture_changed(texture: Texture2D)
signal item_quantity_changed(qtty: String)
signal is_impossible_drop_zone(is_impossible: bool)


@export_subgroup("Model")
@export var item_stack: ItemSystem_ItemStack:
	set(value):
		if item_stack != value:
			item_stack = value
			if item_stack and not item_stack.changed.is_connected(_update_state):
				item_stack.changed.connect(_update_state)
			_update_state()
@export var texture_placeholder: Texture2D

@export_subgroup("Slot features")
@export var is_draggable := true:
	set(value):
		is_draggable = value
		notify_property_list_changed()
enum StackManagement {REMOVE_ON_DROP, REMOVE_ON_DRAG}
@export var stack_management: StackManagement = StackManagement.REMOVE_ON_DROP
enum DragMode {HOLD, TOGGLE}
@export var drag_mode: DragMode = DragMode.HOLD

@export var is_droppable := true
@export var switch_enabled := true

@export_subgroup("Slot constraints")
@export var item_type: ItemSystem_Item.Type = ItemSystem_Item.Type.NONE
@export var item_subtype: ItemSystem_Item.SubType = ItemSystem_Item.SubType.NONE
@export var max_quantity: int = 0

func _validate_property(property: Dictionary) -> void:
	if not is_draggable and property.name == "stack_management":
		property.usage = PROPERTY_USAGE_NONE
	if not is_droppable and property.name == "switch_enabled":
		property.usage = PROPERTY_USAGE_NONE

var draggable: DragAndDrop_Draggable
var droppable: DragAndDrop_Droppable
var col_span: int:
	get: return item_stack.item.slot_size.x if item_stack and item_stack.item else 1
var row_span: int:
	get: return item_stack.item.slot_size.y if item_stack and item_stack.item else 1

var inventory_control: ItemSystem_InventoryGrid:
	set(value):
		if value != inventory_control:
			inventory_control = value
			_update_state()

var double_tap_wait_time: float = 0.3
var _last_action: String = ""

func _ready() -> void:
	if has_node("DragAndDrop_Draggable"):
		draggable = $DragAndDrop_Draggable
	if has_node("DragAndDrop_Droppable"):
		droppable = $DragAndDrop_Droppable
	if is_draggable and not draggable:
		draggable = DragAndDrop_Draggable.new()
		add_child(draggable)
		draggable.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		draggable.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if draggable:
		draggable._get_drag_data_delegate = _get_drag_data_delegate
		draggable._get_drag_preview_delegate = _get_drag_preview_delegate
		draggable.drag_requested.connect(_on_drag_requested)
		draggable.drag_successful.connect(_on_drag_success)
		draggable.drag_failed.connect(_on_drag_failure)
	if is_droppable and not droppable:
		droppable = DragAndDrop_Droppable.new()
		add_child(droppable)
		droppable.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		droppable.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if droppable:
		droppable._receive_data_delegate = _receive_data_delegate
		droppable._can_drop_data_delegate = _can_drop_data_delegate
		droppable.data_dropped.connect(_on_data_dropped)
	_update_state()


func _notification(what: int) -> void:
	if droppable:
		if what == NOTIFICATION_DRAG_BEGIN:
			call_deferred(&"_on_drag_begin_somewhere") # call_deferred to call _get_drag_data before the resolution of the DRAG_BEGIN event
		if what == NOTIFICATION_DRAG_END:
			is_impossible_drop_zone.emit(false)
		pass

func _on_drag_begin_somewhere():
	if get_viewport().gui_get_drag_data() is DragAndDrop_Data and get_viewport().gui_get_drag_data().data is ItemSystem_ItemStack:
		is_impossible_drop_zone.emit( not _can_drop_data_delegate(Vector2.ZERO, get_viewport().gui_get_drag_data()))

func _update_state() -> void:
	if not item_stack:
		return

	item_name_changed.emit(item_stack.item.name if item_stack.item else "")
	item_texture_changed.emit(item_stack.item.icon if item_stack.item else texture_placeholder)
	item_quantity_changed.emit(str(item_stack.quantity) if item_stack.item else "")
	pass


func _input(event: InputEvent) -> void:
	if draggable and draggable._is_dragging():
		if event.is_action_released(&"itemsystem_drag_all") or event.is_action_released(&"itemsystem_drag_half") or event.is_action_released(&"itemsystem_drag_one"):
			if draggable.is_force_dragging:
				# send a left click to cancel force_drag until godot 4.4 gui_cancel_drag()
				event = event.duplicate()
				event.button_index = MOUSE_BUTTON_LEFT
				Input.parse_input_event(event)
			draggable.trigger_force_drop()
			accept_event()
	pass

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not Rect2(Vector2.ZERO, size).has_point(event.position):
		return
	if not get_viewport().gui_is_dragging():
		if draggable:
			var should_hold: bool = event.is_action_pressed(&"itemsystem_drag_all") or event.is_action_pressed(&"itemsystem_drag_half") or event.is_action_pressed(&"itemsystem_drag_one")
			var should_toggle: bool = event.is_action_released(&"itemsystem_drag_all") or event.is_action_released(&"itemsystem_drag_half") or event.is_action_released(&"itemsystem_drag_one")
			var should_drag: bool = drag_mode == DragMode.HOLD and should_hold
			should_drag = should_drag or (drag_mode == DragMode.TOGGLE and should_toggle)
			if should_drag:
				draggable.trigger_force_drag()
				accept_event()
		if event.is_action_released(&"itemsystem_quickaction"):
			if _last_action == "itemsystem_quickaction":
				if draggable:
					draggable.cancel_force_drag()
				double_clicked.emit()
				accept_event()
			else:
				_last_action = "itemsystem_quickaction"
				get_tree().create_timer(double_tap_wait_time).timeout.connect(func(): _last_action = "")

# DragAndDrop support
#region Draggable

func _get_drag_data_delegate() -> Variant:
	var to_drag: ItemSystem_ItemStack = ItemSystem_ItemStack.new()
	if not item_stack.item:
		return null
	to_drag.item = item_stack.item
	if Input.is_action_just_pressed(&"itemsystem_drag_all") or Input.is_action_pressed(&"itemsystem_drag_all") or Input.is_action_just_released(&"itemsystem_drag_all"):
		to_drag.quantity = item_stack.quantity
	if Input.is_action_just_pressed(&"itemsystem_drag_half") or Input.is_action_pressed(&"itemsystem_drag_half") or Input.is_action_just_released(&"itemsystem_drag_half"):
		to_drag.quantity = floor(item_stack.quantity / 2)
	elif Input.is_action_just_pressed(&"itemsystem_drag_one") or Input.is_action_pressed(&"itemsystem_drag_one") or Input.is_action_just_released(&"itemsystem_drag_one"):
		to_drag.quantity = 1
	return to_drag

func _get_drag_preview_delegate() -> Control:
	var preview: ItemSystem_InventorySlotControl = duplicate(DUPLICATE_SCRIPTS + DUPLICATE_SIGNALS) as ItemSystem_InventorySlotControl
	preview.size = size
	preview.item_stack = _get_drag_data_delegate()
	preview._update_state()
	return preview


func _on_drag_requested(data: ItemSystem_ItemStack) -> void:
	if stack_management == StackManagement.REMOVE_ON_DRAG:
		item_stack.quantity -= data.quantity
		if item_stack.quantity == 0:
			item_stack.item = null # TODO if 0 is accepted, do not delete
	pass


func _on_drag_success(data: ItemSystem_ItemStack):
	if stack_management == StackManagement.REMOVE_ON_DROP:
		item_stack.quantity -= data.quantity
		if item_stack.quantity == 0:
			item_stack.item = null
	inventory_control._refresh()


func _on_drag_failure(data: ItemSystem_ItemStack):
	if data:
		if item_stack.quantity == 0:
			item_stack.item = data.item
			item_stack.quantity = data.quantity
		else:
			item_stack.item = data.item
			item_stack.quantity += data.quantity
#endregion Draggable

#region Droppable
func _on_data_dropped(data: DragAndDrop_Data) -> void:
	inventory_control._refresh()

func _can_drop_data(_at_position:Vector2, data:Variant) -> bool:
	if not droppable:
		return false
	# We are the one receiving the mouse event, so we transmit it to the draggable
	# If the draggable was the one with the mouse detection, we would not do this call
	return droppable._can_drop_data(_at_position, data)

func _can_drop_data_delegate(_at_position:Vector2, data: DragAndDrop_Data) -> bool:
	var incoming_stack = data.data as ItemSystem_ItemStack
	if not incoming_stack or not incoming_stack.item:
		return false
	if incoming_stack.item.equals(item_stack.item):
		return true
	if item_type != ItemSystem_Item.Type.NONE and incoming_stack.item.type != item_type:
		return false
	if item_subtype != ItemSystem_Item.SubType.NONE and incoming_stack.item.subtype != item_subtype:
		return false
	if not switch_enabled and item_stack.item:
		return false
	if switch_enabled and item_stack.item and not item_stack.item.equals(incoming_stack.item):
		return false
	if not inventory_control or not inventory_control.can_insert_at(inventory_control.inventory.stacks.find(item_stack), incoming_stack.item):
		return false
	return true


func _receive_data_delegate(_at_position: Vector2, data: DragAndDrop_Data) -> Error:
	var incoming_stack: ItemSystem_ItemStack = data.data as ItemSystem_ItemStack

	var error: Error = OK
	if not item_stack.item or incoming_stack.item.equals(item_stack.item):
		var current_quantity: int = item_stack.quantity
		var new_quantity: int = current_quantity + incoming_stack.quantity
		var total_quantity: int = incoming_stack.quantity + current_quantity
		if max_quantity > 0 and total_quantity > max_quantity:
			incoming_stack.quantity = total_quantity - max_quantity
			new_quantity = min(new_quantity, max_quantity)
			error = ERR_CANT_ACQUIRE_RESOURCE
		item_stack.item = incoming_stack.item
		item_stack.quantity = new_quantity
	elif switch_enabled:
		if data.emitter._emitter_is_also_droppable():
			var replace_with: ItemSystem_ItemStack = item_stack.duplicate()
			item_stack.item = incoming_stack.item
			item_stack.quantity = incoming_stack.quantity
			data.data = replace_with
		error = ERR_BUSY
	else:
		error = ERR_BUSY
	return error
#endregion Droppable
