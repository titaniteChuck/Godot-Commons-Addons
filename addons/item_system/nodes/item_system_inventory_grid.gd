@tool
class_name ItemSystem_InventoryGrid extends ItemSystem_InventoryControl

@export var columns := 1
@export_group("Theme Override Constants","theme_")
@export_range(0,1024) var theme_h_separation = 5
@export_range(0,1024) var theme_v_separation = 5
@export_group("")
@export_group("Node")
@export var foreground_grid: SpanningTableContainer:
	set(value): slots_parent = foreground_grid
	get: return slots_parent

func _ready() -> void:
	super._ready()
	assert(foreground_grid)
	#for child in foreground_grid.get_children():
		#foreground_grid.remove_child(child)
		#child.queue_free()

func _draw():
	super._draw()
	if inventory:
		for index in inventory.slots.size():
			if foreground_grid.get_child(index) is SpanningCellContainer:
				if inventory.slots[index].item and (foreground_grid.get_child(index) is SpanningCellContainer):
					(foreground_grid.get_child(index) as SpanningCellContainer).row_span = inventory.slots[index].item.slot_size.y
					(foreground_grid.get_child(index) as SpanningCellContainer).col_span = inventory.slots[index].item.slot_size.x
				else:
					(foreground_grid.get_child(index) as SpanningCellContainer).row_span = 1
					(foreground_grid.get_child(index) as SpanningCellContainer).col_span = 1
		_deactivate_connected_slots()

func _deactivate_connected_slots() -> void:
	for child in slots_parent.get_children():
		child.visible = true
	for slot_index in inventory.slots.size():
		var item_stack = inventory.slots[slot_index]
		if not item_stack.item:
			continue
		var grid_dimensions: Vector2i = Vector2i(columns, inventory.slots.size() / columns +1)
		var my_grid_coordinates: Vector2i = Vector2i(slot_index % grid_dimensions.x, slot_index / grid_dimensions.x)
		for x in item_stack.item.slot_size.x:
			for y in item_stack.item.slot_size.y:
				if x == 0 and y == 0:
					continue
				var neighbor_index_in_grid: Vector2i = my_grid_coordinates + Vector2i(x, y)
				var neighbor_index_in_inventory: int = (my_grid_coordinates.y + y) * grid_dimensions.x + my_grid_coordinates.x + x
				if neighbor_index_in_grid.x > grid_dimensions.x or neighbor_index_in_grid.y > grid_dimensions.y:
					break
				if neighbor_index_in_inventory >= inventory.slots.size() or inventory.slots[neighbor_index_in_inventory].item:
					break
				slots_parent.get_child(neighbor_index_in_inventory).visible = false
