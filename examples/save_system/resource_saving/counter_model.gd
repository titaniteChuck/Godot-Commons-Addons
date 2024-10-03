class_name CounterModel extends Resource

@export var value := 0:
	set(new_value):
		if value != new_value:
			value = new_value
			emit_changed()

