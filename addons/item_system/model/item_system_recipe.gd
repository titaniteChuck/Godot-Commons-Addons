class_name ItemSystem_Recipe extends Resource

# TODO: With godot 4.4, to retest with typed dictionaries
@export var ingredients: Array[ItemSystem_ItemStack]
@export var results: Array[ItemSystem_ItemStack]
@export var consume_ingredients := true

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
