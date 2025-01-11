class_name ItemSystem_Item extends Resource

enum Rarity {NONE, COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}
enum Type {NONE, HELM, CHEST, SHOULDERS, ARMS, BRACERS, GLOVES, BELT, PANTS, BOOTS, NECKLACE, RING, CONSUMABLE, MAIN_HAND, OFF_HAND}
enum SubType {NONE}
@export var id: String
@export var name: String
@export var texture2D: Texture2D
@export var rarity: Rarity = Rarity.NONE
@export var type: Type = Type.NONE

func rarity_as_str() -> String:
	return Rarity.find_key(rarity)
func type_as_str() -> String:
	return Type.find_key(type)

func equals(other: Variant) -> bool:
	if other == null or other is not ItemSystem_Item:
		return false

	return id == other.id
