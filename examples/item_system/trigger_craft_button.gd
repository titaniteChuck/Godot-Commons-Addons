extends Button
@export var ingredients_slots: ItemSystem_InventoryControl
@export var results_slots: ItemSystem_InventoryControl
@export var quickaccess_slots: ItemSystem_InventoryControl
@export var known_recipes: Array[ItemSystem_Recipe] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_trigger_craft)
	for slot in ingredients_slots.ui_slots:
		slot.double_clicked.connect(_move_between_inventories.bind(slot.item_stack, quickaccess_slots.inventory))
	for slot in results_slots.ui_slots:
		slot.double_clicked.connect(_move_between_inventories.bind(slot.item_stack, quickaccess_slots.inventory))
	for slot in quickaccess_slots.ui_slots:
		slot.double_clicked.connect(_move_between_inventories.bind(slot.item_stack, ingredients_slots.inventory))
	pass # Replace with function body.

func _move_between_inventories(item_stack: ItemSystem_ItemStack, dest: ItemSystem_Inventory):
	if dest.add_stack(item_stack) == OK:
		item_stack.item = null

func _trigger_craft():
	var matching_recipes: Array[ItemSystem_Recipe] = get_recipe_from_ingredients(ingredients_slots.inventory.slots)
	if not matching_recipes.is_empty():
		matching_recipes[0].craft_recipe(ingredients_slots.inventory, results_slots.inventory)

func get_recipe_from_ingredients(ingredients: Array[ItemSystem_ItemStack]) -> Array[ItemSystem_Recipe]:
	return known_recipes.filter(func(rec: ItemSystem_Recipe) -> bool: return rec.can_be_crafted_with(ingredients))
