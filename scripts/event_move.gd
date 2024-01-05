# event_move.gd
class_name EventMove extends Event

'''
Moves an Entity towards a point, optionally animating it
'''

@export_category("EventMove")
## The Entity to move
@export var node : Entity
## The target to move towards
@export var target : Marker3D

@export_group("Tween")
## Whether or not to wait for tween
@export var wait_for_tween : bool = true
## Time to move over
@export_range(0.0, 10.0) var move_time : float = 2.0
## Transition to use
@export var trans : Tween.TransitionType = Tween.TRANS_LINEAR
## Easing to use
@export var easing : Tween.EaseType = Tween.EASE_IN_OUT

@export_group("Animation")
## The animation to call on the node while moving
@export var animation_move : StringName = ""
## The animation to call on teh node when done moving
@export var animation_done : StringName = ""

func _execute() -> void:
	# Determine node
	if !node:
		node = get_tree().get_first_node_in_group("Player")
	
	# Do some calculations
	var offset_roty = deg_to_rad(90.0) if node is Player else 0.0
	node.visual_node.look_at(target.global_position)
	node.visual_node.global_rotation.y = wrap(node.visual_node.global_rotation.y + offset_roty, -PI, PI)
	var target_roty = node.visual_node.global_rotation.y + wrap(target.global_rotation.y - node.visual_node.global_rotation.y, -PI, PI)
	
	
	# Create tween
	var tw := create_tween()
	tw.set_trans(trans).set_ease(easing)
	tw.tween_property(node, "global_position", target.global_position, move_time)
	tw.tween_interval(move_time * 0.25)
	tw.set_parallel(true)
	tw.tween_property(node.visual_node, "global_rotation:y", target_roty, move_time)
	tw.tween_property(node, "vis_rotation:y", target_roty + offset_roty, move_time)
	tw.play()
	
	# Call animation, if necessary
	if animation_move:
		node.set_anim(animation_move)
	
	# Wait for tween to finish, if necessary
	if wait_for_tween:
		await tw.finished
	
	# We're done
	execution_complete.emit()
	
	# End animation, if necessary
	if animation_done:
		if tw.is_running():
			await tw.finished
		node.change_anim(animation_done)
