@tool
class_name ItemSystem_ItemStack extends Resource

@export var item: ItemSystem_Item:
	set(value):
		if item != value:
			item = value
			if item:
				if not item.changed.is_connected(emit_changed):
					item.changed.connect(emit_changed)
				quantity = 1
			else:
				quantity = 0
			emit_changed()
@export var quantity := 0:
	set(value):
		if item == null:
			value = 0
		value = max(value, 0)
		if quantity != value:
			quantity = value
			emit_changed()

func equals(other: Variant) -> bool:
	if other == null or other is not ItemSystem_Item:
		return false

	return item.equals(other.item)

func has_item(candidate: ItemSystem_Item) -> bool:
	return item and item.equals(candidate)

func add_item(candidate: ItemSystem_Item, quantity_candidate: int) -> Error:
	var status: Error = OK
	if not item:
		item = candidate
		quantity = quantity_candidate
	elif has_item(candidate):
		quantity += quantity_candidate
	else:
		status = ERR_INVALID_DATA
	return status

func transfer(candidate: ItemSystem_ItemStack, remove_from_source := true) -> Error:
	var quantity_before: int = quantity
	var status: Error = add_item(candidate.item, candidate.quantity)
	if status == OK and remove_from_source:
		var quantity_taken = quantity - quantity_before
		candidate.quantity -= quantity_taken
	return status
