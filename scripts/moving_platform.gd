# moving_platform.gd
class_name MovingPlatform extends Node3D

'''
Manages moving geometry.
'''

@export_category("MovingPlatform")
## The [AnimationPlayer] associated with this [MovingPlatform].
@export var anim : AnimationPlayer
## The name of the animation to loop through
@export var anim_name : String = "default"

func _ready() -> void:
	# Verify AnimationPlayer exists
	assert(anim != null and anim.has_animation(anim_name))

	# Play animation
	anim.play(anim_name)

