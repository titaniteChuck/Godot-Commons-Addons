class_name ItemSystem_InventoryGridController extends SpanGridController

@export var slot_factory: PackedScene = preload("res://addons/item_system/nodes/item_system_inventory_slot_control.tscn")
@export var slot_min_size: Vector2 = Vector2.ZERO
@export var expand_slots := true
@export var show_in_tree := true

func _init_table_cell():
	super._init_table_cell()
	if slot_factory:
		var new_slot = slot_factory.instantiate()
		grid_node.add_child(new_slot, true)
		if show_in_tree:
			new_slot.owner = owner
		if expand_slots:
			new_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			new_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		new_slot.custom_minimum_size = slot_min_size
