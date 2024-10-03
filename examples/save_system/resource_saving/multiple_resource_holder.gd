extends Control

@export var values: Array[CounterModel] = []:
	set(new_values):
		if new_values != values:
			values = new_values
			_read_model()

@onready var label: Label = $Label
@onready var label_2: Label = $Label2
@onready var label_3: Label = $Label3
@onready var label_4: Label = $Label4

func _ready():
	SaveSystem.save_requested.connect(_on_save_requested)
	SaveSystem.load_requested.connect(_on_load_request)
	if not values:
		values = [CounterModel.new(),CounterModel.new(),CounterModel.new(),CounterModel.new()]
	pass # Replace with function body.

func _on_save_requested():
	SaveSystem.save_entity(get_path().get_concatenated_names()+":values", values)

func _on_load_request():
	var from_save = SaveSystem.load_entity(get_path().get_concatenated_names()+":values")
	for i in range(0, from_save.size()):
		values[i].value = from_save[i].value
	_read_model()

func _read_model():
	for value in values:
		value.changed.connect(_update_ui)
	_update_ui()
	
func _update_ui():
	if not is_inside_tree(): await draw
	var label_list = [label, label_2, label_3, label_4]
	for i in range(0, values.size()):
		label_list[i].text = str(values[i].value)


func _generate_random():
	for val in values:
		val.value = randi_range(0, 10)
