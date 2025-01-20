@tool
class_name CharacterSystem_LayeredAnimatedSpriteControl extends LayeredAnimatedSpriteControl

@export var skin: CharacterSystem_Skin:
	set(value):
		skin = value
		if skin:
			skin.changed.connect(_load_skin)

func _ready():
	super._ready()
	if skin:
		_load_skin()

func _load_skin() -> void:
	if skin:
		for skin_layer in skin.get_layers_in_drawing_order():
			if not skin_layer.color_changed.is_connected(_fine_tune_children):
				skin_layer.color_changed.connect(_fine_tune_children)
		sprite_frames = get_sprite_frames()
		_fine_tune_children()

func get_sprite_frames() -> Array[SpriteFrames]:
	var output: Array[SpriteFrames] = []
	if skin:
		var skin_layers: Array[CharacterSystem_SkinItem] = skin.get_layers_in_drawing_order()
		skin_layers.reverse()
		for layer in skin_layers:
			if layer.frames_bg:
				output.append(layer.frames_bg)
		skin_layers.reverse()
		for layer in skin_layers:
			if layer.frames_fg:
				output.append(layer.frames_fg)
	return output

func _fine_tune_children() -> void:
	var skin_layers: Array[CharacterSystem_SkinItem] = skin.get_layers_in_drawing_order()
	var layers_children = get_children().filter(func(el): return el is TextureRect)
	var current_layer = 0
	skin_layers.reverse()
	for layer in skin_layers:
		if layer.frames_bg:
			layers_children[current_layer].name = "Layer_"+CharacterSystem_SkinItem.LAYER.find_key(layer.layer).capitalize()
			layers_children[current_layer].self_modulate = layer.modulate
			current_layer += 1
	skin_layers.reverse()
	for layer in skin_layers:
		if layer.frames_fg:
			layers_children[current_layer].name = "Layer_"+CharacterSystem_SkinItem.LAYER.find_key(layer.layer).capitalize()
			layers_children[current_layer].self_modulate = layer.modulate
			current_layer += 1
