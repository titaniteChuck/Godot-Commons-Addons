class_name ItemSystem_RecipeService extends Node

signal recipe_crafted(recipe: ItemSystem_Recipe)
signal recipe_craft_failed(recipe: ItemSystem_Recipe)

@export var recipes: Array[ItemSystem_Recipe]

func check_for_enough_ingredients(inventory: ItemSystem_Inventory, recipe: ItemSystem_Recipe) -> bool:

	return inventory and recipe and recipe.ingredients.all(func(el): return el.quantity <= inventory.get_quantity(el.item))

func craft_recipe(recipe: ItemSystem_Recipe, inventory_src: ItemSystem_Inventory, inventory_dest = inventory_src) -> Error:
	var error = OK
	if check_for_enough_ingredients(inventory_src, recipe):
		if recipe.consume_ingredients:
			error = inventory_src.remove_items_in_bulk(recipe.ingredients)
		if error == OK:
			error = inventory_dest.add_item_stacks(recipe.execute_recipe())
			if error == OK:
				recipe_crafted.emit(recipe)
			else:
				# revert operation
				inventory_src.add_item_stacks(recipe.ingredients)
	else:
		error = ERR_PARAMETER_RANGE_ERROR
		
	if error != OK:
		recipe_craft_failed.emit(recipe)

	return error

func get_recipe_from_ingredients(ingredients: Array[ItemSystem_ItemStack]) -> Array[ItemSystem_Recipe]:
	return recipes.filter(func(rec: ItemSystem_Recipe) -> bool: return rec.can_be_crafted_with(ingredients))
