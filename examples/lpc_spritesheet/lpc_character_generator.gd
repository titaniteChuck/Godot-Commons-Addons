extends Control

@export_dir var resources_folder: String = "res://addons/lpc_spritesheet/resources"

@onready var select_animation: OptionButton = $VBoxContainer/Line1/Select_Animation
@onready var options_container: GridContainer = $VBoxContainer/Line2/Left_panel/Options_Container
@onready var button_generate_random: Button = %Button_GenerateRandom
@onready var button_reset: Button = %Button_Reset
@onready var select_animation_speed: HSlider = $VBoxContainer/Line3/Select_Animation_Speed
@onready var layered_animated_sprite_control: LayeredAnimatedSpriteControl = $VBoxContainer/Line2/Control/LayeredAnimatedSpriteControl
@onready var layered_animated_sprite_2d: LayeredAnimatedSprite2D = $LayeredAnimatedSprite2D
const VARIANT_ARROW_SELECTOR = preload("res://addons/lpc_spritesheet/examples/nodes/select_variant_line/variant_arraow_selector.tscn")
var _current_animation: String = "walk_down"
var _character_skin := CharacterSystem_CharacterSkin.new() 

func _ready() -> void:
	for layer_name in _get_layerName_by_drawing_order():
		var layer := CharacterSystem_CharacterSkinLayer.new()
		layer.name = layer_name
		_character_skin.add_layer(layer)
	_update_options()
	_update_character()
	_update_animations()
	button_generate_random.pressed.connect(_generate_random)
	button_reset.pressed.connect(_reset)
	select_animation_speed.value = layered_animated_sprite_control.get_speed_scale()
	select_animation_speed.value_changed.connect(func(value): 
		layered_animated_sprite_control.speed_scale = value
		layered_animated_sprite_2d.speed_scale = value
	)
	_character_skin.changed.connect(_on_character_skin_changed)
	layered_animated_sprite_control.sprite_frames = _character_skin.get_layers_textures()
	layered_animated_sprite_control.animation = _current_animation
	layered_animated_sprite_2d.sprite_frames = _character_skin.get_layers_textures()
	layered_animated_sprite_2d.animation = _current_animation
	_on_character_skin_changed()

func _on_character_skin_changed():
	layered_animated_sprite_control.sprite_frames = _character_skin.get_layers_textures()
	layered_animated_sprite_control.animation = _current_animation
	layered_animated_sprite_2d.sprite_frames = _character_skin.get_layers_textures()
	layered_animated_sprite_2d.animation = _current_animation
	for index in range(_character_skin.layers.size()):
		layered_animated_sprite_control.get_child(index).self_modulate = _character_skin.layers[index].color
		layered_animated_sprite_2d.get_child(index).self_modulate = _character_skin.layers[index].color

func _reset():
	_update_options()
	_update_character()

func _generate_random():
	for option_line in options_container.get_children():
		if option_line is OptionButton:
			option_line.selected = range(option_line.item_count).pick_random()
		if option_line is VariantSelectorArrow:
			option_line.selected = range(option_line.item_count).pick_random()
		if option_line is ColorPickerButton:
			option_line.color = Color(randf(), randf(), randf())
	_update_character()

func _update_animations():
	var base_frame = _get_layer_variant_frames("body", "bodies")
	
	for animation in base_frame.get_animation_names():
		select_animation.add_item(animation)
		if animation == _current_animation:
			select_animation.selected = select_animation.item_count - 1

	if not select_animation.item_selected.is_connected(_on_animation_selected):
		select_animation.item_selected.connect(_on_animation_selected)

func _on_animation_selected(index: int):
	_current_animation = select_animation.get_item_text(index)
	layered_animated_sprite_control.animation = _current_animation

func _update_character():
	for extra_part in _get_layerName_by_drawing_order():
		var variant_option: VariantSelectorArrow = options_container.get_node(extra_part+"_variant_value")
		var color_option: ColorPickerButton = options_container.get_node(extra_part+"_ColorPicker")
		var variant_name = variant_option.get_item_text(variant_option.selected)
		var skin_layer: CharacterSystem_CharacterSkinLayer = _character_skin.get_layer_by_name(extra_part)
		skin_layer.color = color_option.color
		skin_layer.frames = _get_layer_variant_frames(extra_part, variant_name)

func _update_options():
	for child in options_container.get_children():
		options_container.remove_child(child)
		child.queue_free()
		
	for layer_name in _get_layerName_by_display_order():
		for child in _create_option_line(layer_name, _is_optional(layer_name)):
			options_container.add_child(child)

func _create_option_line(option_name: String, optional := true) -> Array[Node]:
	var output: Array[Node] = []
	var label := Label.new()
	label.text = option_name
	label.name = option_name + "_Label"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output.append(label)
	var new_line = VARIANT_ARROW_SELECTOR.instantiate()
	for child in new_line.get_children():
		if child is VariantSelectorArrow:
			child.mandatory = not optional
			child.possible_values = get_layer_variants(option_name)
			if option_name == "head":
				child.selected = child.possible_values.find("human")
			else:
				child.selected = 0
			child.item_selected.connect(func(index): _update_character())
			child.label_value.custom_minimum_size = Vector2(183, 0)
		child.name = option_name+"_"+child.name
		new_line.remove_child(child)
		output.append(child)
	new_line.queue_free()
#
	var colorPicker := ColorPickerButton.new()
	colorPicker.custom_minimum_size = Vector2(50, 0)
	colorPicker.color = Color.WHITE
	colorPicker.color_changed.connect(
		func(color): 
			_character_skin.get_layer_by_name(option_name).color = color
	)
	colorPicker.name = option_name + "_ColorPicker"
	#
	if option_name == "head" or option_name == "body":
		colorPicker.color = Color("fec2be")
	
	output.append(colorPicker)
	return output

func get_layer_variants(layer_name: String) -> Array[String]:
	var output: Array[String] = []
	if _is_optional(layer_name):
		output.append("")
	for file in DirAccess.get_files_at("%s/%s" % [resources_folder, layer_name]):
		if file.get_extension() == "tres":
			output.append(file.get_basename())
	return output

func _get_layer_variant_frames(layer_name: String, variant: String) -> SpriteFrames:
	return ResourceLoader.load("%s/%s/%s.tres" % [resources_folder, layer_name, variant])

func _get_layerName_by_drawing_order() -> Array:
	return ["body", "head", "hair", "feet", "legs", "torso", "beards", "hat"]
	
func _get_layerName_by_display_order() -> Array:
	return ["hat", "hair", "head", "beards", "body", "torso", "legs", "feet"]
	
func _is_optional(layer_name: String) -> bool:
	return layer_name not in ["body", "head"]
