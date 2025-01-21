extends Node
@export var ingredients_slots: ItemSystem_InventoryControl
@export var results_slots: ItemSystem_InventoryControl
@export var trigger_button: Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	trigger_button.pressed.connect(_trigger_craft)
	assert(ingredients_slots)
	assert(results_slots)
	pass # Replace with function body.

func _trigger_craft():
	var recipe = ItemSystem.RecipeService.get_recipe_from_inventory(ingredients_slots.inventory)
	ItemSystem.RecipeService.craft_recipe(recipe, ingredients_slots.inventory)
