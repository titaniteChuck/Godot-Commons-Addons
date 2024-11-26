## Scene_Manager

Scene_Manager allowing to load scenes with transitions, one transition for the scene exiting, one other for the scene created.

There is also the possibility to delete or not nodes during the transition.

Transitions do not use an AnimationPlayer, but rather tween properties like modulate for blur and position for slide

For 2D nodes with CanvasLayers, a special Node must be added to handle the opacity, so the Scene_Manager also adds it before doing the transition