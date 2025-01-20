@tool
class_name CharacterSystem_Skin extends Resource

##sets up the draw_order in the foreground order. it ends up with (n-1).bg (n-2).bg ... (n-2).fg (n-1).fg
@export var draw_order: Array[CharacterSystem_SkinItem.LAYER] = [
	CharacterSystem_SkinItem.LAYER.BODY,
	CharacterSystem_SkinItem.LAYER.HEAD,
	CharacterSystem_SkinItem.LAYER.HAIR,
	CharacterSystem_SkinItem.LAYER.HAT,
	CharacterSystem_SkinItem.LAYER.SHOES,
	CharacterSystem_SkinItem.LAYER.PANTS,
	CharacterSystem_SkinItem.LAYER.TORSO,
	CharacterSystem_SkinItem.LAYER.BEARD,
	CharacterSystem_SkinItem.LAYER.MAINHAND,
	CharacterSystem_SkinItem.LAYER.OFFHAND
]

@export var head_layer: CharacterSystem_SkinItem:
	set(value): if head_layer != value: head_layer = value; emit_changed()
@export var body_layer: CharacterSystem_SkinItem:
	set(value): if body_layer != value: body_layer = value; emit_changed()
@export var hair_layer: CharacterSystem_SkinItem:
	set(value): if hair_layer != value: hair_layer = value; emit_changed()
@export var hat_layer: CharacterSystem_SkinItem:
	set(value): if hat_layer != value: hat_layer = value; emit_changed()
@export var beard_layer: CharacterSystem_SkinItem:
	set(value): if beard_layer != value: beard_layer = value; emit_changed()
@export var torso_layer: CharacterSystem_SkinItem:
	set(value): if torso_layer != value: torso_layer = value; emit_changed()
@export var pants_layer: CharacterSystem_SkinItem:
	set(value): if pants_layer != value: pants_layer = value; emit_changed()
@export var shoes_layer: CharacterSystem_SkinItem:
	set(value): if shoes_layer != value: shoes_layer = value; emit_changed()
@export var mainhand_layer: CharacterSystem_SkinItem:
	set(value): if mainhand_layer != value: mainhand_layer = value; emit_changed()
@export var offhand_layer: CharacterSystem_SkinItem:
	set(value): if offhand_layer != value: offhand_layer = value; emit_changed()

func get_layers_in_drawing_order() -> Array[CharacterSystem_SkinItem]:
	var skin_layers: Array[CharacterSystem_SkinItem] = []
	var dict = {
		CharacterSystem_SkinItem.LAYER.HEAD: head_layer,
		CharacterSystem_SkinItem.LAYER.BODY: body_layer,
		CharacterSystem_SkinItem.LAYER.HAIR: hair_layer,
		CharacterSystem_SkinItem.LAYER.HAT: hat_layer,
		CharacterSystem_SkinItem.LAYER.BEARD: beard_layer,
		CharacterSystem_SkinItem.LAYER.TORSO: torso_layer,
		CharacterSystem_SkinItem.LAYER.PANTS: pants_layer,
		CharacterSystem_SkinItem.LAYER.SHOES: shoes_layer,
		CharacterSystem_SkinItem.LAYER.MAINHAND: mainhand_layer,
		CharacterSystem_SkinItem.LAYER.OFFHAND: offhand_layer
	}
	for layer_type in draw_order:
		if dict.get(layer_type):
			skin_layers.append(dict.get(layer_type))

	return skin_layers
