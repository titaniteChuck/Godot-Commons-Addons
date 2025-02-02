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
	_set_visibility_of_connected_slots(true)
	row_span = 1
	col_span = 1
	item_stack.item = null
	item_stack.quantity = 0
	pass


func _on_drag_success(data: ItemSystem_ItemStack):
	pass


func _on_drag_failure(data: ItemSystem_ItemStack):
	if data:
		item_stack.item = data.item
		item_stack.quantity = data.quantity


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


## Number of columns this container should span ower.
@export_range(1,1025) var col_span : int = 1 :
	set(value):
		col_span = value
		var parent = get_parent()
		if parent and parent is Container:
			parent.queue_sort()
		if parent and parent is Control:
			parent.update_minimum_size()
		update_configuration_warnings()


## Number of rows this container should span over.
@export_range(1,1025) var row_span : int = 1 :
	set(value):
		row_span = value
		var parent = get_parent()
		if parent and parent is Container:
			parent.queue_sort()
		if parent and parent is Control:
			parent.update_minimum_size()


# Check the cell configuration to give user feedback about most common errors.
func _get_configuration_warnings():
	var warnings = []
	var parent = get_parent()
	if parent:
		var table = parent as ItemSystem_InventoryGrid
		if !table:
			warnings.append("Parent should be a ItemSystem_InventoryGrid.")
		if table and col_span > table.columns:
			warnings.append("This cell dosn't fitt in parent table, as parent colums is less than the column span of this cell!")

	return warnings


# Hook into the sort child notification to place the child controls during sorting.
func _notification(what):
	match what:
		NOTIFICATION_SORT_CHILDREN:
			_handle_sort_children()


# Perform the shorting of the children of this control
func _handle_sort_children():
	for child in get_children():
		# Child should be of control type, to be able to adjust positions
		var control_child = child as Control
		if control_child == null:
			continue

		# Some more conditions where the child should not be adjusted
		if not control_child.is_visible_in_tree() || control_child.is_set_as_top_level():
			continue

		# Child fill the entire area of the cell
		fit_child_in_rect(control_child, Rect2(Vector2(), get_size()))


# Calculate the minimum size for this control
func _get_minimum_size() -> Vector2:
	for child in get_children():
		# Child should be of control type, to be able to adjust positions
		var control_child = child as Control
		if control_child == null:
			continue

		# Some more conditions where the child should not be adjusted
		if not control_child.is_visible_in_tree() || control_child.is_set_as_top_level():
			continue

		return control_child.get_combined_minimum_size()

	return Vector2()
