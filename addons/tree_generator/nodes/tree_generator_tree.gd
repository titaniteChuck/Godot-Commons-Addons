@tool
class_name TreeGenerator_Tree extends Node2D

@export_subgroup("Actions")
@export_range(0.0, 1.0) var growth: float = 1.0
@export var generate: bool:
	set(value):
		generate_tree()

@export_subgroup("Geneartion Config")
@export var config: TreeGenerator_Config:
	set(value):
		config = value
		if config:
			config.visual_changed.connect(light_update)

func _ready():
	generate_tree()

func generate_tree()-> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	add_child(create_branch(Vector2.ZERO, Vector2.UP.angle(), config.trunk_length, config.trunk_width, config.trunk_subbranches, config.total_iterations, false))
	
	#if not Engine.is_editor_hint():
		#change_owner_recursively()

func create_branch(pos: Vector2, angle: float, length: float, width: float, subbranches_count: int, iterations := 0, create_leaves := true) -> Line2D:
	var output = Line2D.new()
	output.position = pos
	output.default_color = config.trunk_color
	output.antialiased = true
	output.width = width
	output.width_curve = Curve.new()
	output.width_curve.add_point(Vector2.DOWN)
	output.width_curve.add_point(Vector2.RIGHT)
	output.points = generate_tree_curve_points(length, angle)
	if config.leaf_spawn_from_iteration <= (config.total_iterations - iterations):
		for i in config.leaf_count_by_branch:
			create_leaf_on_branch(output)

	if iterations > 0:
		for i in subbranches_count:
			create_subbranch_on_branch(output, subbranches_count, iterations)
	return output

func create_subbranch_on_branch(branch: Line2D, subbranches_count: int, iterations := 0):
	var random_point_factor: float = randf_range(config.child_spawn_area_min, config.child_spawn_area_max)
	var random_point_index: int = int(branch.points.size() * random_point_factor)
	var child_pos: Vector2 = branch.points[ random_point_index ]
	var child_angle: float = Vector2.RIGHT.rotated(randf_range(config.child_angle_min, config.child_angle_max) + child_pos.angle()).angle()
	var child_length: float = child_pos.length() * randf_range(config.child_length_min, config.child_length_max) # subbranches are smaller and smaller
	var child_width: float = branch.width * (1-random_point_factor) # subbranches are thinner and thinner. (1-factor) -> Further is the point, thinner is the branch
	var child_subbranches_count:int = subbranches_count - randi_range(config.child_reduction_min, config.child_reduction_max) # subbranches have less and less ramifications
	branch.add_child(create_branch(child_pos, child_angle, child_length, child_width, child_subbranches_count, iterations - 1))

func create_leaf_on_branch(branch: Line2D):
		var random_point_factor: float = randf_range(config.leaf_spawn_area_min, config.leaf_spawn_area_max)
		var random_point_index:int = int(branch.points.size() * random_point_factor)

		var leaf: Sprite2D = Sprite2D.new()
		leaf.z_index = 1
		leaf.position = branch.points[random_point_index]
		leaf.texture = config.leaf_texture
		leaf.scale = Vector2.ONE * config.leaf_scale
		leaf.rotation = randf_range(-PI, PI)
		leaf.modulate = config.leaf_color1 if randf_range(0, 1) <= 0.5 else config.leaf_color2
		branch.add_child(leaf)

func generate_tree_curve_points(length: float, first_angle: float) -> PackedVector2Array:
	var rough_points: PackedVector2Array = []
	rough_points.append(Vector2.ZERO)
	var first_segment_length: float = length * config.length_min_before_curve # no curve near the root of the branch 
	var segment_length: float = first_segment_length
	var direction: Vector2 = Vector2.RIGHT.rotated(first_angle)
	var new_point: Vector2 = direction * segment_length
	rough_points.append(new_point)
	var cumulated_length: float = segment_length
	while cumulated_length < length:
		direction = Vector2.RIGHT.rotated(randf_range(config.child_angle_min, config.child_angle_max) + first_angle)
		segment_length = first_segment_length * randf_range(config.branch_length_min, config.branch_length_max) # segments are smaller and smaller
		new_point += direction * segment_length
		cumulated_length += segment_length
		rough_points.append(new_point)

	var curve: Curve2D = Curve2D.new()
	curve.bake_interval = 1.0
	for i in rough_points.size():
		if i-1 > 0 and i+1 < rough_points.size():
			var in_point := (rough_points[i-1] - rough_points[i+1])/4
			curve.add_point(rough_points[i], in_point, -in_point)
		else:
			curve.add_point(rough_points[i], Vector2.ZERO)
	return curve.get_baked_points()


func _update_ui()-> void:
	pass

func light_update(branch: Node = get_child(0), iteration := 0) -> void: 
	if not branch: return
	branch.default_color = config.trunk_color
	
	for child in branch.get_children():
		if child is Sprite2D:
			child.texture = config.leaf_texture
			child.scale = Vector2.ONE * config.leaf_scale
		if child is Line2D:
			light_update(child)

func change_owner_recursively(node: Node = get_child(0)):
	node.owner = get_tree().edited_scene_root
	for child in node.get_children():
		change_owner_recursively(child)

