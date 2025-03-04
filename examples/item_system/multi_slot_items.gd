extends Node2D

@onready var item_system_inventory_grid: ItemSystem_InventoryGrid = $ItemSystem_InventoryGrid
@onready var item_system_inventory_grid_2: ItemSystem_InventoryGrid = $ItemSystem_InventoryGrid2
@onready var selected_texture: TextureRect = %Selected_Texture
@onready var selected_name: Label = %Selected_Name
@onready var selected_quantity: Label = %Selected_quantity

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for slot in item_system_inventory_grid.slots:
		slot.selected.connect(
			func():
				selected_texture.texture = slot.item_stack.item.icon if slot.item_stack.item else null
				selected_name.text = slot.item_stack.item.name if slot.item_stack.item else ""
				selected_quantity.text = str(slot.item_stack.quantity) if slot.item_stack.item else "0"
		)
	for slot in item_system_inventory_grid_2.slots:
		slot.selected.connect(
			func():
				selected_texture.texture = slot.item_stack.item.icon if slot.item_stack.item else null
				selected_name.text = slot.item_stack.item.name if slot.item_stack.item else ""
				selected_quantity.text = str(slot.item_stack.quantity) if slot.item_stack.item else "0"
		)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
