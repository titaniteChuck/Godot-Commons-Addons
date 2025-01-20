@tool
class_name SpeechBubble extends Control

@export var bubble_pin_position: Vector2 = Vector2.ZERO:
	set(value):
		bubble_pin_position = value
		queue_redraw()
@export var bubble_color: Color = Color.SKY_BLUE:
	set(value):
		bubble_color = value
		if has_theme_stylebox("panel"):
			# While in 4.3, do not do this in _draw. It fails, somehow
			get_theme_stylebox("panel").set(&"bg_color", bubble_color)
		queue_redraw()

@export var font_color: Color = Color.BLACK:
	set(value):
		font_color = value
		queue_redraw()

@onready var label: Label = $Text

var previous_size = null
var previous_position = null
func _process(delta: float) -> void:
	if size != previous_size or previous_position != position:
		previous_size = size
		previous_position = position
		queue_redraw()
	pass

func _draw():
	label.add_theme_color_override(&"font_color", font_color)
	#print("drawww")
	var pin = bubble_pin_position - global_position
	var center = size / 2
	var delta: Vector2 = size / 7

	draw_colored_polygon([pin, center + delta, center - delta], bubble_color)
	draw_colored_polygon([pin, center + delta * Vector2(-1, 1), center - delta * Vector2(-1, 1)], bubble_color)

func type_label(text: String):
	if not visible:
		visible = true
	label.visible_ratio = 0
	label.text = ""
	size.y = 0
	label.text = text
	var tween: Tween = get_tree().create_tween().bind_node(self)
	var lps = 10
	var duration: float = text.length() / lps
	tween.tween_property(label, ^"visible_ratio", 1.0, duration)
