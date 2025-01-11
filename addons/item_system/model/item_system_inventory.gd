class_name ItemSystem_Inventory extends Resource

@export var item_stacks: Array[ItemSystem_ItemStack] = []:
	set(value):
		if item_stacks != value:
			item_stacks = value
			emit_changed()

func add_item_stacks(array: Array[ItemSystem_ItemStack], index := -1) -> Error:
	var error := OK
	for stack in array:
		error = add_item_stack(stack)
		if error != OK:
			break
	return error

func add_item_stack(new_stack: ItemSystem_ItemStack, index := -1) -> Error:
	var error := OK
	var stacks_with_this_item: Array[ItemSystem_ItemStack] = item_stacks.filter(func(my_stack): return my_stack and my_stack.item.equals(new_stack.item))
	if index != -1: # insert at a specific index is asked
		if item_stacks[index] == null:
			item_stacks[index] = new_stack # if slot is empty, ok
		elif item_stacks[index].item.equals(new_stack.item):
			item_stacks[index].quantity += new_stack.quantity # if slot not empty but same item, ok
		else:
			error = ERR_CANT_ACQUIRE_RESOURCE
	elif  not stacks_with_this_item.is_empty():
		stacks_with_this_item[0].quantity += new_stack.quantity
	else:
		index = _first_empty_index()
		if index == -1: # inventory full, no empty slot
			error = ERR_CANT_ACQUIRE_RESOURCE
		else:
			item_stacks[index] = new_stack

	if error == OK:
		emit_changed()

	return error

func inventory_is_full():
	return _first_empty_index() == -1

func _first_empty_index() -> int:
	return item_stacks.find(null)

func set_minimum_size(size: int) -> void:
	if size > item_stacks.size():
		item_stacks.resize(size)

func add_item(item: ItemSystem_Item, quantity := 1, index := _first_empty_index()) -> Error:
	var new_stack := ItemSystem_ItemStack.new()
	new_stack.item = item
	new_stack.quantity = quantity
	return add_item_stack(new_stack, index)

func remove_items_in_bulk(ingredients: Array[ItemSystem_ItemStack]) -> Error:

	if ingredients.any(func(el): el.quantity > get_quantity(el.item)):
		return ERR_PARAMETER_RANGE_ERROR

	var stacks_to_remove: Array[ItemSystem_ItemStack] = []
	for ingredient_to_remove in ingredients:
		var remaining_qty_to_remove := ingredient_to_remove.quantity

		for my_stack in item_stacks.filter(func(el): return el and el.item.equals(ingredient_to_remove.item)):
			my_stack.quantity -= remaining_qty_to_remove
			if my_stack.quantity <= 0:
				stacks_to_remove.append(my_stack)
				remaining_qty_to_remove = abs(my_stack.quantity)
			if remaining_qty_to_remove == 0:
				break

	for stack_to_remove in stacks_to_remove:
		remove_at(item_stacks.find(stack_to_remove))

	emit_changed()
	return OK

func get_quantity(item: ItemSystem_Item):
	var quantity := 0
	for my_stack in item_stacks.filter(func(stack: ItemSystem_ItemStack): return stack and stack.item.equals(item)):
		quantity += my_stack.quantity
	return quantity

func remove_at(index: int):
	if item_stacks.size() >= index:
		var _emit_changed :=  item_stacks[index]
		item_stacks[index] = null
		if _emit_changed:
			emit_changed()
