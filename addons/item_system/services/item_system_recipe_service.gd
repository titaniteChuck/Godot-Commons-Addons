class_name ItemSystem_RecipeService extends Node

signal recipe_crafted(recipe: ItemSystem_Recipe)
signal recipe_craft_failed(recipe: ItemSystem_Recipe)

@export var recipes: Array[ItemSystem_Recipe]

func check_for_enough_ingredients(inventory: ItemSystem_Inventory, recipe: ItemSystem_Recipe) -> bool:
	return inventory and recipe and recipe.ingredients.all(func(el): return el.quantity <= inventory.get_quantity(el.item))

func get_recipe_from_ingredients(ingredients: Array[ItemSystem_ItemStack]) -> Array[ItemSystem_Recipe]:
	return recipes.filter(func(rec: ItemSystem_Recipe) -> bool: return rec.can_be_crafted_with(ingredients))

func get_recipe_from_inventory(inventory: ItemSystem_Inventory) -> Array[ItemSystem_Recipe]:
	return get_recipe_from_ingredients(inventory.item_stacks)
