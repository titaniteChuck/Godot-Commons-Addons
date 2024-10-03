class_name LoadingScreen extends Node

signal loadingscreen_visible

@export var anim_player: AnimationPlayer:
	set(value):
		if anim_player:
			anim_player.animation_changed.disconnect(_on_animation_finished)
		anim_player = value
		anim_player.animation_finished.connect(_on_animation_finished)

var start_transition_animation_name: String
var end_transition_animation_name: String
var _animation_speed: float

func _ready() -> void:
	pass

func start_transition(animation_name:String, animation_duration := 1.0) -> void:
	if anim_player == null:
		push_error("LoadingScreen badly initialized. Missing anim_player")
		return
	if !anim_player.has_animation(animation_name):
		push_warning("'%s' animation does not exist" % animation_name)
		animation_name = "fade_to_black"
	start_transition_animation_name = animation_name
	
	anim_player.speed_scale = 1.0 / animation_duration # TODO this asks from the animations to be 1s long
	
	anim_player.play(animation_name)

func _on_animation_finished(animation_name: String):
	if animation_name == start_transition_animation_name:
		loadingscreen_visible.emit()

func finish_transition() -> void:
	anim_player.play_backwards(start_transition_animation_name)
	# once this final animation plays, we can free this scene
	await anim_player.animation_finished
	queue_free()

func update_loading_percent(percent: float):
	pass
