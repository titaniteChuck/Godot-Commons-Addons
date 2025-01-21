@tool
class_name ItemSystem_ItemStack extends Resource

@export var item: ItemSystem_Item:
	set(value):
		if item != value:
			item = value
			if item:
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
		if value == 15:
			var catchme = true
		if quantity != value:
			quantity = value
			emit_changed()

func equals(other: Variant) -> bool:
	if other == null or other is not ItemSystem_Item:
		return false

	return item.equals(other.item)
