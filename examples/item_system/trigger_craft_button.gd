extends Button
@export var ingredients_slots: ItemSystem_UI_InventorySlots
@export var results_slots: ItemSystem_UI_InventorySlots

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_trigger_craft)
	assert(ingredients_slots)
	assert(results_slots)
	pass # Replace with function body.

func _trigger_craft():
	var temp_result: Array[ItemSystem_ItemStack] = ItemSystem.RecipeService.craft_recipe(ingredients_slots.inventory, ingredients_slots.inventory.item_stacks)
	if not temp_result.is_empty():
		results_slots.inventory.add_item_stacks(temp_result)
