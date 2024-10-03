class_name ItemSystem_ItemStack extends Resource

@export var item: ItemSystem_Item:
	set(value):
		if item != value:
			item = value
			emit_changed()
@export var quantity := 1:
	set(value):
		if quantity != value:
			quantity = value
			emit_changed()

func equals(other: Variant) -> bool:
	if other == null or other is not ItemSystem_Item:
		return false
	
	return item.equals(other.item)
