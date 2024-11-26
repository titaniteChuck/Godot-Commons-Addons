## Animated_Sprite
I looked at the AnimatedSprite2D node, and I wanted to do the same thing but:
- layered (one for the head, the torso...) -> `layered_animated_sprite_2d.gd`
- a child of control Node for better integration with UI -> `animated_sprite_control.gd`
- a control Node + layered -> `layered_animated_sprite_control.gd`

Since it all uses the same logic, the class `animated_sprite_delegate.gd` provides all the logic, and uses signals when its time to change.

This way, the "layered" nodes do not risk to fall out of sync.