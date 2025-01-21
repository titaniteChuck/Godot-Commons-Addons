extends Button
@export var ingredients_slots: ItemSystem_InventoryControl
@export var results_slots: ItemSystem_InventoryControl
@export var known_recipes: Array[ItemSystem_Recipe] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_trigger_craft)
	pass # Replace with function body.

func _trigger_craft():
	var matching_recipes: Array[ItemSystem_Recipe] = get_recipe_from_ingredients(ingredients_slots.inventory.slots)
	if not matching_recipes.is_empty():
		matching_recipes[0].craft_recipe(ingredients_slots.inventory, results_slots.inventory)

func get_recipe_from_ingredients(ingredients: Array[ItemSystem_ItemStack]) -> Array[ItemSystem_Recipe]:
	return known_recipes.filter(func(rec: ItemSystem_Recipe) -> bool: return rec.can_be_crafted_with(ingredients))
