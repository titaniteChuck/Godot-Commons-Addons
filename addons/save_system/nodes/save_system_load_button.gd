class_name SaveSystem_LoadButton extends Button

func _ready() -> void:
	pressed.connect(_on_button_pressed)

func _on_button_pressed():
	SaveSystem.load_savefile()
