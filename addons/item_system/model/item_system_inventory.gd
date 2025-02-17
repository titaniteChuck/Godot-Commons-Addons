@tool
class_name ItemSystem_Inventory extends Resource

@export var stacks: Array[ItemSystem_ItemStack] = []:
	set(value):
		if stacks != value:
			stacks = value
			if stacks:
				for i in stacks.size():
					if stacks[i] == null:
						stacks[i] = ItemSystem_ItemStack.new()
			emit_changed()

func add_stacks(array: Array[ItemSystem_ItemStack], index := -1) -> Error:
	var error := OK
	for stack in array:
		error = add_stack(stack)
		if error != OK:
			break
	return error

func add_stack(new_stack: ItemSystem_ItemStack, index := -1) -> Error:
	var error := ERR_CANT_ACQUIRE_RESOURCE
	var stacks_with_this_item: Array[ItemSystem_ItemStack] = stacks.filter(func(my_stack): return my_stack.item and my_stack.item.equals(new_stack.item))
	if index != -1: # insert at a specific index is asked
		error = stacks[index].transfer(new_stack)
	elif not stacks_with_this_item.is_empty():
		stacks_with_this_item[0].quantity += new_stack.quantity #TODO ignores stack_size
	else:
		index = _first_empty_index()
		if index != -1:
			stacks[index].item = new_stack.item
			stacks[index].quantity = new_stack.quantity
			error = OK

	if error == OK:
		emit_changed()

	return error

func inventory_is_full() -> bool:
	return _first_empty_index() == -1

func _first_empty_index() -> int:
	for index in stacks.size():
		if stacks[index].item == null:
			return index
	return -1

func add_item(item: ItemSystem_Item, quantity := 1, index := _first_empty_index()) -> Error:
	var new_stack := ItemSystem_ItemStack.new()
	new_stack.item = item
	new_stack.quantity = quantity
	return add_stack(new_stack, index)

func remove_items_in_bulk(stacks: Array[ItemSystem_ItemStack]) -> Error:
	if stacks.any(func(el): el.quantity > get_quantity(el.item)):
		return ERR_PARAMETER_RANGE_ERROR

	for ingredient_to_remove in stacks:
		var remaining_qty_to_remove := ingredient_to_remove.quantity

		for my_stack in stacks.filter(func(el): return el and el.item and el.item.equals(ingredient_to_remove.item)):
			my_stack.quantity -= remaining_qty_to_remove
			if my_stack.quantity < remaining_qty_to_remove:
				my_stack.item = null
				my_stack.quantity = 0
				remaining_qty_to_remove = remaining_qty_to_remove - my_stack.quantity
			if remaining_qty_to_remove == 0:
				break

	emit_changed()
	return OK

func get_quantity(item: ItemSystem_Item) -> int:
	return stacks.reduce(func(qtty, stack): return qtty + (stack.quantity if stack.has_item(item) else 0))
