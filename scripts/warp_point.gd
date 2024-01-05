# warp_point.gd
@tool
class_name WarpPoint extends Marker3D

'''
Positional target for an EventWarp call.
'''

enum Transitions {
	Fall_Land,
	Fall_Bounce,
	Move_Forward_Short,
	Move_Forward_Long
}

enum Camera {
	Behind,
	Infront,
	Custom
}

@export_category("WarpPoint")
## The ID associated with the WarpPoint.[br][br]
## [b]NOTE:[/b] An ID of -1 makes this the default spawn point.
@export var id : int = -1 :
	get       : return id
## The transition type to use when warping to this point.
@export var transition : Transitions = Transitions.Fall_Bounce
## The type of camera to use
@export var camera_type : Camera = Camera.Behind

## Reference to player, passed down from LevelManager.
var player : Player

func _ready() -> void:
	# Assign self to warp group
	add_to_group("Warp", true)

	# Extend gizmo
	gizmo_extents = 2.5

# FUNCTION
#-------------------------------------------------------------------------------

## Processes transition.
func process_transition() -> void:
	# Ensure player reference is working
	if !is_instance_valid(player):
		push_error("Player instance invalid, transition failed! - Warp ", name)
		return
	
	# Reset cam
	player._spring_arm.camera.current = true
	
	# Set rotations
	player._state_machine.transition_state("none")
	player.global_position = global_position
	player.vis_rotation.y = global_rotation.y
	player.visual_node.rotation.y = global_rotation.y
	
	# Splinter into different camera functionality
	var p_cam = player._spring_arm as PCam_SpringArm
	match camera_type:
		Camera.Behind:
			p_cam.rotation.y = global_rotation.y + deg_to_rad(180)
			p_cam.target_rotation.y = rad_to_deg(global_rotation.y) + 180
		
		Camera.Infront:
			p_cam.rotation.y = global_rotation.y
			p_cam.target_rotation.y = rad_to_deg(global_rotation.y)
		
		Camera.Custom:
			pass
	
	# Splinter into different functionality
	match transition:
		Transitions.Fall_Land:
			player._state_machine.transition_state("airborne")
		
		Transitions.Fall_Bounce:
			player._state_machine.transition_state("warp_bounce")
			await player.warp_finished
		
		Transitions.Move_Forward_Short:
			player._state_machine.transition_state("warp_move", {"dir" : Vector3.FORWARD.rotated(Vector3.UP, rotation.y + deg_to_rad(180))})
			await get_tree().create_timer(1.0).timeout
			player._state_machine.transition_state("idle")
			
		Transitions.Move_Forward_Long:
			player._state_machine.transition_state("warp_move", {"dir" : Vector3.FORWARD.rotated(Vector3.UP, rotation.y + deg_to_rad(180))})
			await get_tree().create_timer(2.0).timeout
			player._state_machine.transition_state("idle")
	
	
