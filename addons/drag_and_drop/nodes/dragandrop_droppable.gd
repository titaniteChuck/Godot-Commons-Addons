class_name DragAndDrop_Droppable extends Control

signal drag_is_hovering(data: DragAndDrop_Data)
signal drag_stopped_hovering
signal data_dropped(data: DragAndDrop_Data)
var drop_node: Node

var can_receive: Callable
var receive_drag_data

@export var replace_if_occupied := true
@export var dragndrop_outline_destination := true
#@export var only_for_category: Inventory_InventoryItem.ItemType

@onready var outline_selected: TextureRect = $Outline_Selected
@onready var button: Button = $Button

enum State {IDLE, HOVERED_AND_DROPPABLE, HOVERED_BUT_NOT_DROPPABLE}
var current_state: State

var _reject_drop := false
#func _get_current_data() -> Object:
	#if drop_node and parent_property_name:
		#return drop_node.get(parent_property_name)
	#else:
		#return null
#
#func _has_data() -> bool:
	#return _get_current_data() != null

func _ready():
	drop_node = get_parent()
	mouse_exited.connect(_on_mouse_exit)
	visible = false
	name = "DragAndDrop_Draggable"

func reject_drop():
	_reject_drop = true

func _on_mouse_exit():
	current_state = State.IDLE

func _can_drop_data(_at_position:Vector2, data:Variant) -> bool:
	var can_receive = true
	if not data or data is not DragAndDrop_Data:
		can_receive = false

	#if not data.is_class(parent_property.hint_string):
		#can_receive = false
	
	# 2. if category
	
	#if replace_if_occupied:
		#can_receive = true
#
	#current_state = State.HOVERED_AND_DROPPABLE if can_receive else State.HOVERED_BUT_NOT_DROPPABLE
	return can_receive

func _drop_data(_at_position:Vector2, data: Variant) -> void:
	current_state = State.IDLE
	data = data as DragAndDrop_Data
	data.receiver = self
	data_dropped.emit(data)
	if _reject_drop:
		data.emitter.drag_failed.emit(data.data)
	else:
		data.emitter.drag_successful.emit(data)
	_reject_drop = false

func _change_state(new_state: State):
	if new_state != current_state:
		current_state = new_state
		match(current_state):
			State.IDLE: 
				if outline_selected: outline_selected.visible = false
				drag_stopped_hovering.emit()
			State.HOVERED_AND_DROPPABLE: 
				if outline_selected: outline_selected.visible = true
				drag_is_hovering.emit()
			State.HOVERED_BUT_NOT_DROPPABLE: 
				if outline_selected: outline_selected.visible = false
				drag_is_hovering.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		visible = true
	if what == NOTIFICATION_DRAG_END:
		visible = false

