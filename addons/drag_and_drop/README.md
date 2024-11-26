## Drag_And_Drop

A little bit of WIP regarding the signals.

The idea is to wrap the logic provided by godot with three nodes:
- `model/dragandrop_data.gd` : what is being dragged
- `nodes/draganddrop_draggable.gd`: a script to attach to a node that should be dragged.
- `nodes/draganddrop_droppable.gd`: a script to attach to a node that can receive a DropEvent.