@tool
class_name ItemSystem_InventoryGridSlot extends ItemSystem_InventorySlotControl

@onready var spanning_cell_container: SpanningCellContainer = $".."

func _update_state():
	if item_stack and item_stack.item:
		spanning_cell_container.row_span = item_stack.item.slot_size.y
		spanning_cell_container.col_span = item_stack.item.slot_size.x
	super._update_state()


func _can_drop_data_delegate(_at_position:Vector2, data:Variant) -> bool:
	var output = super._can_drop_data_delegate(_at_position, data)
	data = data as DragAndDrop_Data
	var incoming_stack = data.data
	if output:
		if not (inventory_control and incoming_stack.item):
			return false
		var my_index_in_inventory: int = inventory_control.inventory.slots.find(item_stack)
		var grid_dimensions: Vector2i = Vector2i(inventory_control.columns, inventory_control.inventory.slots.size() / inventory_control.columns +1)
		var my_grid_coordinates: Vector2i = Vector2i(my_index_in_inventory % grid_dimensions.x, my_index_in_inventory / grid_dimensions.x)
		for x in incoming_stack.item.slot_size.x:
			for y in incoming_stack.item.slot_size.y:
				var neighbor_index_in_grid: Vector2i = my_grid_coordinates + Vector2i(x, y)
				var neighbor_index_in_inventory: int = (my_grid_coordinates.y + y) * grid_dimensions.x + my_grid_coordinates.x + x
				if neighbor_index_in_grid.x < 0 or neighbor_index_in_grid.x >= grid_dimensions.x or neighbor_index_in_grid.y < 0 or neighbor_index_in_grid.y >= grid_dimensions.y:
					return false
				if neighbor_index_in_inventory >= inventory_control.inventory.slots.size() or inventory_control.inventory.slots[neighbor_index_in_inventory].item:
					return false
		var catchme = true
	return output

func _on_drag_requested() -> void:
	item_stack.item = null
	item_stack.quantity = 0
	pass


func _on_drag_success(data: ItemSystem_ItemStack):
	pass


func _on_drag_failure(data: ItemSystem_ItemStack):
	if data:
		item_stack.item = data.item
		item_stack.quantity = data.quantity
