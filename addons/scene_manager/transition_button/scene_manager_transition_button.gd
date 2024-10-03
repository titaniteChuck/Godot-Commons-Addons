class_name SceneManager_TransitionButton extends Button

@export var transition: SceneManager_TransitionData

@export var transitions: Array[SceneManager_TransitionData] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_button_pressed)
	pass


func _on_button_pressed():
	if transition and transitions.is_empty():
		await SceneManager.play_transition(self, transition)
	for t in transitions:
		SceneManager.play_transition(self, t)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _init_new_scene(node: Node) -> void:
	node.get_node("Label").text = "ext value"
