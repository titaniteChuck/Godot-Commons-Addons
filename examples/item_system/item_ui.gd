class_name ItemUI extends Button

@export var item: ItemSystem_Item:
	set(value):
		if item != value:
			item = value
			_read_model()

func _ready():
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP

func _read_model():
	item.changed.connect(_update_ui)
	_update_ui()

func _update_ui():
	icon = item.texture2D
	text = item.id
