extends Button

@export var parent_of_generated_nodes: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_generate_child)
	pass # Replace with function body.

func _generate_child():
	if parent_of_generated_nodes:
		var new_child = Label.new()
		new_child.text = str(randi_range(0, 10))
		parent_of_generated_nodes.add_child(new_child)
		new_child.position = Vector2(randi_range(0, 800), randi_range(0, 400))

