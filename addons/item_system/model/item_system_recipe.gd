class_name ItemSystem_Recipe extends Resource

signal crafted
signal craft_failed

# TODO: With godot 4.4, to retest with typed dictionaries
@export var id := ""
@export var ingredients: Array[ItemSystem_ItemStack]
@export var results: Array[ItemSystem_ItemStack]
@export var consume_ingredients := true
@export var craft_time: float = 0

func can_be_crafted_with(to_evaluate: Array[ItemSystem_ItemStack]) -> bool:
	if not to_evaluate:
		return false
	to_evaluate = to_evaluate.filter(func(stack): return stack != null)
	if ingredients.size() != to_evaluate.size():
		return false
	return ingredients.all(func(from_recipe):
			return to_evaluate.any(func(from_input):
					return 	from_recipe.item.id == from_input.item.id and from_input.quantity >= from_recipe.quantity))

func execute_recipe() -> Array[ItemSystem_ItemStack]:
	var output: Array[ItemSystem_ItemStack] = []
	for item_stack in results:
		output.append(item_stack.duplicate())
	return output

func craft_recipe(inventory_src: ItemSystem_Inventory, inventory_dest = inventory_src) -> Error:
	var error = OK
	if check_for_enough_ingredients(inventory_src):
		if consume_ingredients:
			error = inventory_src.remove_items_in_bulk(ingredients)
		if error == OK:
			error = inventory_dest.add_stacks(results)
			if error == OK:
				crafted.emit()
			else:
				# revert operation
				inventory_src.add_stacks(ingredients)
	else:
		error = ERR_PARAMETER_RANGE_ERROR

	if error != OK:
		craft_failed.emit()

	return error

func check_for_enough_ingredients(inventory: ItemSystem_Inventory) -> bool:
	return inventory and ingredients.all(func(el): return el.quantity <= inventory.get_quantity(el.item))
