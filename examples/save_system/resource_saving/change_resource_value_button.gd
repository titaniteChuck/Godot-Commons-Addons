class_name ChangeResourceValueButton extends Button

enum Type {INCREMENT, DECREMENT}
@export var label: CounterLabel
@export var type: Type = Type.INCREMENT

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_button_pressed)
	pass # Replace with function body.

func _on_button_pressed():
	if label and label.counter:
		var current_value: int = label.counter.value
		if type == Type.INCREMENT:
			current_value += 1
		else:
			current_value -= 1
		label.counter.value = current_value
			
