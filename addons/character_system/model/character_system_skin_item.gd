@tool
class_name CharacterSystem_SkinItem extends ItemSystem_Item

@export_subgroup("SkinItem")
signal color_changed

@export var frames_bg: SpriteFrames
@export var frames_fg: SpriteFrames
@export var modulate: Color = Color.WHITE:
	set(value):
		if value != modulate:
			modulate = value
			color_changed.emit()
@export var layer: LAYER

enum LAYER {HEAD, BODY, HAIR, HAT, BEARD, TORSO, PANTS, SHOES, MAINHAND, OFFHAND}
