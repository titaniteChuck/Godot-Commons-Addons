@tool
class_name ItemSystem_InventoryGrid extends ItemSystem_InventoryControl

@export var columns := 1
@export_group("Theme Override Constants","theme_")
@export_range(0,1024) var theme_h_separation = 5
@export_range(0,1024) var theme_v_separation = 5
@export_group("")
@export_group("Node")
@export var foreground_grid: SpanningTableContainer:
	set(value): slots_parent = value
	get: return slots_parent

func _ready() -> void:
	super._ready()
