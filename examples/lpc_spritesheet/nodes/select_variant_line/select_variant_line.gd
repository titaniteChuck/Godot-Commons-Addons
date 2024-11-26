class_name VariantSelectorArrow extends Node

signal item_selected(index: int)

@export var previous_button: Button
@export var next_button: Button
@export var reset_button: Button
@export var label_value: Label
@export var possible_values: Array[String] = []: set = _set_possible_values
@export var warp := true
@export var mandatory := false

var selected := -1:
	set(value):
		selected = value
		_update_ui()
var item_count := 0:
	get: return possible_values.size()

func _ready() -> void:
	previous_button.pressed.connect(_on_previous)
	next_button.pressed.connect(_on_next)
	reset_button.pressed.connect(_on_reset)
	_update_ui()

func _on_previous():
	if warp:
		selected = selected - 1 if selected > 0 else possible_values.size() - 1
	else:
		selected = clamp(selected - 1, 0, possible_values.size())
	_update_ui()
	item_selected.emit(selected)

func _on_next():
	if warp:
		selected = selected + 1 if selected < possible_values.size() - 1 else 0
	else:
		selected = clamp(selected + 1, 0, possible_values.size())
	_update_ui()
	item_selected.emit(selected)
	
func _on_reset() -> void:
	selected = -1
	item_selected.emit(selected)

func _set_possible_values(new_array: Array[String]):
	possible_values = new_array
	_update_ui()
	
func _update_ui():
	if not is_inside_tree(): await ready
	label_value.text = possible_values[selected] if selected in range(possible_values.size()) else ""
	if not warp:
		previous_button.disabled = selected == 0
		next_button.disabled = selected == possible_values.size() - 1
	if mandatory or label_value.text.is_empty():
		reset_button.modulate = Color.TRANSPARENT
		reset_button.disabled = true
	else:
		reset_button.modulate = Color.WHITE
		reset_button.disabled = false
		

func get_item_text(index: int):
	if index not in range(possible_values.size()):
		return ""
	return possible_values[index]
