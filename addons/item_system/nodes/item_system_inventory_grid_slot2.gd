@tool
class_name ItemSystem_InventoryGridSlot2 extends ItemSystem_InventorySlotControl2

func _update_state() -> void:
	if item_stack and item_stack.item:
		row_span = item_stack.item.slot_size.y
		col_span = item_stack.item.slot_size.x
		_set_visibility_of_connected_slots(false)
	else:
		row_span = 1
		col_span = 1

	super._update_state()


func _can_drop_data_delegate(_at_position:Vector2, data:Variant) -> bool:
	var output = super._can_drop_data_delegate(_at_position, data)
	data = data as DragAndDrop_Data
	var incoming_stack = data.data
	if output:
		var slots_covered_by_item = _get_slots_covered_by_item(incoming_stack.item)
		if slots_covered_by_item.size() != incoming_stack.item.slot_size.x * incoming_stack.item.slot_size.y:
			return false
		for slot_covered_by_item in slots_covered_by_item:
			if not slot_covered_by_item or slot_covered_by_item.visible == false:
				return false
	return output


func _on_drag_requested() -> void:
	if drag_mode == DragMode.REMOVE_ON_DRAG:
		_set_visibility_of_connected_slots(true)
	super._on_drag_requested()
	pass

func _on_drag_success(data: ItemSystem_ItemStack):
	if drag_mode == DragMode.REMOVE_ON_DROP:
		_set_visibility_of_connected_slots(true)
	super._on_drag_success(data)

func _set_visibility_of_connected_slots(visible: bool) -> void:
	if not inventory_control or not item_stack.item:
		return
	var slots_covered_by_item = _get_slots_covered_by_item()
	slots_covered_by_item.pop_front()
	for slot_covered_by_item in slots_covered_by_item:
		slot_covered_by_item.visible = visible


func _get_slots_covered_by_item(item: ItemSystem_Item = item_stack.item) -> Array[ItemSystem_InventoryGridSlot2]:
	var output: Array[ItemSystem_InventoryGridSlot2] = []
	if not inventory_control or not item:
		return output
	var my_index_in_inventory: int = inventory_control.inventory.slots.find(item_stack)
	var grid_dimensions: Vector2i = Vector2i(inventory_control.slots_parent.columns, inventory_control.inventory.slots.size() / inventory_control.slots_parent.columns +1)
	var my_grid_coordinates: Vector2i = Vector2i(my_index_in_inventory % grid_dimensions.x, my_index_in_inventory / grid_dimensions.x)
	for x in item.slot_size.x:
		for y in item.slot_size.y:
			var neighbor_index_in_grid: Vector2i = my_grid_coordinates + Vector2i(x, y)
			var neighbor_index_in_inventory: int = (my_grid_coordinates.y + y) * grid_dimensions.x + my_grid_coordinates.x + x
			if neighbor_index_in_grid.x not in range(grid_dimensions.x) or neighbor_index_in_grid.y not in range(grid_dimensions.y):
				break
			if neighbor_index_in_inventory >= inventory_control.inventory.slots.size():
				break
			if not (x==0 and y==0) and inventory_control.inventory.slots[neighbor_index_in_inventory].item:
				break
			var new_append = inventory_control.slots_parent.get_children().filter(func(child): return child is ItemSystem_InventorySlotControl2)[neighbor_index_in_inventory]
			output.append(new_append)

	return output
