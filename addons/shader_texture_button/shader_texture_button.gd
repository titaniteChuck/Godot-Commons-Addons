class_name ShaderTextureButton extends TextureButton

@export var shader: ShaderMaterial
@export var activate_shader_while_pressed: bool = false

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_on_mouse_exited()

func _toggled(toggled_on: bool) -> void:
	if activate_shader_while_pressed:
		material = shader if toggled_on else null

func _on_mouse_entered():
	material = shader

func _on_mouse_exited():
	if activate_shader_while_pressed and not button_pressed:
		material = null
