class_name CounterLabel extends Label

@export var counter := CounterModel.new():
	set(value):
		if value != counter:
			counter = value
			_read_model()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _read_model():
	if counter:
		counter.changed.connect(_update_ui)
		_update_ui()

func _update_ui():
	if not is_inside_tree(): await draw
	text = str(counter.value)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
