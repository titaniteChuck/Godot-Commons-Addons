class_name ItemSystem_Item extends Resource

@export var id: String
@export var name: String
@export var texture2D: Texture2D

func equals(other: Variant) -> bool:
	if other == null or other is not ItemSystem_Item:
		return false
	
	return id == other.id
