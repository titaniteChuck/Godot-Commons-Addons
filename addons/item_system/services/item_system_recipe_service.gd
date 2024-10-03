class_name ItemSystem_RecipeService extends Node

signal recipe_crafted(recipe: ItemSystem_Recipe)

@export var recipes: Array[ItemSystem_Recipe]

func craft_recipe(inventory: ItemSystem_Inventory, ingredients: Array[ItemSystem_ItemStack]) -> Array[ItemSystem_ItemStack]:
	var output: Array[ItemSystem_ItemStack] = []
	var matching_recipes: Array[ItemSystem_Recipe] = recipes.filter(func(rec: ItemSystem_Recipe) -> bool: return rec.can_be_crafted_with(ingredients))
	if not matching_recipes.is_empty():
		var selected_recipe = matching_recipes[0]
		if (selected_recipe.consume_ingredients == false) or inventory.remove_items_in_bulk(selected_recipe.ingredients) == OK:
			output = selected_recipe.execute_recipe()
			recipe_crafted.emit(selected_recipe)
	return output
