@tool
class_name TreeGenerator_Config extends Resource


signal visual_changed

@export_subgroup("Trunk")
@export var trunk_width: int = 45
@export_range(0, 1000) var trunk_length: int = 200.0
@export_range(-PI, PI) var trunk_angle: float = 0.0
@export var trunk_color = Color("#6c584c"):
	set(value):
		trunk_color = value
		visual_changed.emit()
## Start trunk with <trunk_subbranches> subbranches.
## Those subbranches will in turn have less and less subbranches
@export_range(0, 20) var trunk_subbranches: int = 5
## The number of recursive creation that must be done. 
## If too much is provided, the (trunk_subbranches - child_reduction) will stop the recusion anyway
@export_range(0, 20) var total_iterations: int = 1

@export_subgroup("Branch growth")
## Branch will grow in a straight line for length_min_before_curve % of its total length. The first curve will occur after this length
@export_range(0, 1.0) var length_min_before_curve: float = 0.5
## Branch will grow in curves, angled by randf_range[branch_angle_min, branch_angle_max]
@export_range(-PI/2, PI/2) var branch_angle_min: float = -PI/8:
	set(value):
		branch_angle_min = min(branch_angle_max, value)
## Branch will grow in curves, angled by randf_range[branch_angle_min, branch_angle_max]
@export_range(-PI/2, PI/2) var branch_angle_max: float = PI/8:
	set(value):
		branch_angle_max = max(branch_angle_min, value)

## Subbranches's length will be reduced by randf_range[branch_length_min, branch_length_max]% from the parent length
@export_range(0, 1.0) var branch_length_min: float = 0.5:
	set(value):
		branch_length_min = min(branch_length_max, value)
@export_range(0, 1.0) var branch_length_max: float = 0.8:
	set(value):
		branch_length_max = max(branch_length_min, value)

@export_subgroup("Child-Branches")
## Subbranches will grow in a region randf_range[child_spawn_area_min, child_spawn_area_max] * parent_branch_length
@export_range(0, 1) var child_spawn_area_min: float = 0.6:
	set(value):
		child_spawn_area_min = min(child_spawn_area_max, value)
## Subbranches will grow in a region randf_range[child_spawn_area_min, child_spawn_area_max] * parent_branch_length
@export_range(0, 1) var child_spawn_area_max: float = 0.8:
	set(value):
		child_spawn_area_max = max(child_spawn_area_min, value)

## Subbranches will grow in the same angle as the parent + variation in randf_range[child_angle_min, child_angle_max]
@export_range(-PI/2, PI/2) var child_angle_min: float = -PI/8:
	set(value):
		child_angle_min = min(child_angle_max, value)
## Subbranches will grow in the same angle as the parent + variation in randf_range[child_angle_min, child_angle_max]
@export_range(-PI/2, PI/2) var child_angle_max: float = PI/8:
	set(value):
		child_angle_max = max(child_angle_min, value)

## Subbranches's length will be reduced by randf_range[child_length_min, child_length_max]% from the parent length
@export_range(0, 1.0) var child_length_min: float = 0.75:
	set(value):
		child_length_min = min(child_length_max, value)
@export_range(0, 1.0) var child_length_max: float = 0.9:
	set(value):
		child_length_max = max(child_length_min, value)

## Every subbranch will have randi_range[child_reduction_min, child_reduction_max] less subbranches than its parent
## If you want constant reduction: 3 subbranches -> 2 -> 1 -> 0, set the min and max to the same value
@export_range(0, 100) var child_reduction_min: int = 0:
	set(value):
		child_reduction_min = min(child_reduction_max, value)
## Every subbranch will have randi_range[child_reduction_min, child_reduction_max] less subbranches than its parent
## If you want constant reduction: 3 subbranches -> 2 -> 1 -> 0, set the min and max to the same value
@export_range(0, 100) var child_reduction_max: int = 3:
	set(value):
		child_reduction_max = max(child_reduction_min, value)

@export_subgroup("Leaves")
## Leaves will grow in a region randf_range[leaf_spawn_area_min, leaf_spawn_area_max] * parent_branch_length
@export_range(0, 1) var leaf_spawn_area_min: float = 0.8:
	set(value):
		leaf_spawn_area_min = min(leaf_spawn_area_max, value)
## Leaves will grow in a region randf_range[leaf_spawn_area_min, leaf_spawn_area_max] * parent_branch_length
@export_range(0, 1) var leaf_spawn_area_max: float = 1.0:
	set(value):
		leaf_spawn_area_max = max(leaf_spawn_area_min, value)
@export_range(0, 20) var leaf_spawn_from_iteration: int = 0:
	set(value):
		leaf_spawn_from_iteration = min(total_iterations +1 , value)
@export_range(0, 20) var leaf_count_by_branch: int = 7
@export_range(0, 1.0) var leaf_scale: float = 0.5:
	set(value):
		leaf_scale = value
		visual_changed.emit()
@export var leaf_texture: Texture2D:
	set(value):
		leaf_texture = value
		visual_changed.emit()
@export var leaf_color1: Color = Color("#dde5b6"):
	set(value):
		leaf_color1 = value
		visual_changed.emit()
@export var leaf_color2: Color = Color("#ADC178"):
	set(value):
		leaf_color2 = value
		visual_changed.emit()
