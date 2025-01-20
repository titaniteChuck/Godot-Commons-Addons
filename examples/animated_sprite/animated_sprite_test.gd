extends Node2D

@onready var option_button_animation: OptionButton = %OptionButton_Animation
@onready var button_play: Button = %Button_Play
@onready var button_play_backwards: Button = %Button_Play_Backwards
@onready var button_pause: Button = %Button_Pause
@onready var button_stop: Button = %Button_Stop
@onready var button_reset: Button = %Button_Reset
@onready var line_edit_speed: LineEdit = %LineEdit_Speed
@onready var line_edit_frame: LineEdit = %LineEdit_Frame
@onready var color_picker_button: ColorPickerButton = $CanvasLayer/GridContainer/ColorPickerButton

@onready var animated_sprite_control: AnimatedSpriteControl = %AnimatedSpriteControl
@onready var layered_animated_sprite_control: LayeredAnimatedSpriteControl = %LayeredAnimatedSpriteControl
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var layered_animated_sprite_2d: LayeredAnimatedSprite2D = $LayeredAnimatedSprite2D

@onready var nodes_to_handle: Array[Node] = [animated_sprite_2d, animated_sprite_control, layered_animated_sprite_control, layered_animated_sprite_2d]
@export var animation: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button_play.pressed.connect(_on_play)
	button_play_backwards.pressed.connect(_on_play_backwards)
	button_pause.pressed.connect(_on_pause)
	button_reset.pressed.connect(_on_reset)
	button_stop.pressed.connect(_on_stop)
	color_picker_button.color_changed.connect(_on_color_changed)

	var index = 0
	for name in (animated_sprite_2d.sprite_frames as SpriteFrames).get_animation_names():
		option_button_animation.add_item(name)
		if name == animation:
			option_button_animation.selected = index
			_on_animation_selected(index)
		index += 1
	option_button_animation.item_selected.connect(_on_animation_selected)
	line_edit_speed.text_changed.connect(_on_speed_changed)
	line_edit_frame.text_changed.connect(_on_frame_changed)

	animated_sprite_control.animation_looped.connect(func(): print("%s AnimatedSpriteControl.animation_looped" % Time.get_datetime_string_from_system()))
	layered_animated_sprite_control.animation_looped.connect(func(): print("%s LayeredAnimatedSpriteControl.animation_looped" % Time.get_datetime_string_from_system()))
	animated_sprite_2d.animation_looped.connect(func(): print("%s AnimatedSprite2D.animation_looped" % Time.get_datetime_string_from_system()))
	layered_animated_sprite_2d.animation_looped.connect(func(): print("%s LayeredAnimatedSprite2D.animation_looped" % Time.get_datetime_string_from_system()))

func _on_play():
	for node in nodes_to_handle:
		node.play()
	pass
func _on_play_backwards():
	for node in nodes_to_handle:
		node.play_backwards()
func _on_pause():
	for node in nodes_to_handle:
		node.pause()
	pass
func _on_reset():
	for node in nodes_to_handle:
		node.frame = 0

func _on_color_changed(new_color: Color):
	for node in nodes_to_handle:
		node.modulate = new_color

func _on_stop():
	for node in nodes_to_handle:
		node.stop()

func _on_speed_changed(new_text: String):
	if new_text.is_valid_float():
		var new_speed = float(new_text)
		for node in nodes_to_handle:
			node.speed_scale = new_speed

func _on_frame_changed(new_text: String):
	if new_text.is_valid_float():
		var new_speed = float(new_text)
		for node in nodes_to_handle:
			node.frame = new_speed

func _on_animation_selected(index: int):
	animation = option_button_animation.get_item_text(index)
	for node in nodes_to_handle:
		node.animation = animation

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$CanvasLayer/Control/GridContainer/SpeedScale_Label.text = "Speed: "+str(animated_sprite_control.get_playing_speed())
	$CanvasLayer/Control/GridContainer/Frame_Progress_Label.text = "FraPro: %.3f" % animated_sprite_control.frame_progress
	$CanvasLayer/Control/GridContainer/Frame_Label.text = "Frame: "+str(animated_sprite_control.frame)

	$CanvasLayer/Control/GridContainer2/SpeedScale_Label2.text = "Speed: "+str(layered_animated_sprite_control.get_playing_speed())
	$CanvasLayer/Control/GridContainer2/Frame_Progress_Label2.text = "FraPro: %.3f" % layered_animated_sprite_control.frame_progress
	$CanvasLayer/Control/GridContainer2/Frame_Label2.text = "Frame: "+str(layered_animated_sprite_control.frame)

	$CanvasLayer/Control/GridContainer3/SpeedScale_Label3.text = "Speed: "+str(animated_sprite_2d.get_playing_speed())
	$CanvasLayer/Control/GridContainer3/Frame_Progress_Label3.text = "FraPro: %.3f" % animated_sprite_2d.frame_progress
	$CanvasLayer/Control/GridContainer3/Frame_Label3.text = "Frame: "+str(animated_sprite_2d.frame)

	$CanvasLayer/Control/GridContainer4/SpeedScale_Label3.text = "Speed: "+str(layered_animated_sprite_2d.get_playing_speed())
	$CanvasLayer/Control/GridContainer4/Frame_Progress_Label3.text = "FraPro: %.3f" % layered_animated_sprite_2d.frame_progress
	$CanvasLayer/Control/GridContainer4/Frame_Label3.text = "Frame: "+str(layered_animated_sprite_2d.frame)
	pass
