@tool
class_name ItemSystem_Item extends Resource

enum Rarity {NONE, COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}
enum Type {NONE, HELM, CHEST, SHOULDERS, ARMS, BRACERS, GLOVES, BELT, PANTS, BOOTS, NECKLACE, RING, CONSUMABLE, MAIN_HAND, OFF_HAND}
enum SubType {NONE}
@export var id: String
@export var name: String
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.NONE
@export var type: Type = Type.NONE
@export var weight: float = 0.0
@export var rotated: bool = false
@export var slot_size: Vector2i = Vector2i(1, 1):
	set(value):
		if value:
			value = Vector2i(max(value.x, 1), max(value.y, 1))
			slot_size = value
	get: return slot_size if not rotated else Vector2i(slot_size.y, slot_size.x)

func rarity_as_str() -> String:
	return Rarity.find_key(rarity)
func type_as_str() -> String:
	return Type.find_key(type)

func equals(other: Variant) -> bool:
	if other == null or other is not ItemSystem_Item:
		return false

	return id == other.id
