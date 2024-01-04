# event_cam.gd
class_name EventCam extends Event

'''
Sets child camera as current for a defined period of time.
'''

## Properties list
const PROPERTY = [
	"global_position",
	"global_rotation",
	"fov"
]

@export_category("EventCam")
## The camera to mark as current. If left empty, the player's camera
## will be chosen as default.
@export var camera : Camera3D
## The amount of time to wait, in seconds. A duration of 0 or lower
## will instantly move on to the next event.
@export var duration : float = 1.0
## Whether or not to fade bars in. If left unchecked, will fade bars
## out if they are faded in currently.
@export var cutscene_bars : bool = false

@export_group("Animation")
## Optional animation node to play
@export var anim : AnimationPlayer
## The name of the animation to play
@export var anim_name : StringName

@export_group("Interpolation")
## Whether or not to interpolate from the last active camera
@export var do_interpolate : bool = false
## Length of the interpolation
@export var int_length : float = 0.5
## Easing type to use during interpolation
@export var int_ease : Tween.EaseType = Tween.EASE_OUT
## Transition type to use during interpolation
@export var int_trans : Tween.TransitionType = Tween.TRANS_SINE
## Properties to lock between interpolation. Any properties that
## are flagged will not be updated during the interpolation, and will
## instead be updated instantly.
@export_flags("Position", "Rotation", "FOV") var lock_properties = 0

# FUNCTION
#-------------------------------------------------------------------------------

func _execute() -> void:
	# Determine camera if there is none
	camera = player._spring_arm.camera if !camera else camera
	
	# Check for cutscene bars and fade in if needed
	var uiM := get_tree().get_first_node_in_group("UIManager") as UIManager
	uiM.toggle_bars(cutscene_bars)
	
	# Verify animation and play.
	if anim:
		assert(anim.has_animation(anim_name))
		anim.play(anim_name)
	
	# Interpolate if needed, otherwise immediately set to event cam.
	if do_interpolate:
		var current_cam = get_tree().root.get_camera_3d() as Camera3D
		interpolate(current_cam)
	else:
		camera.current = true
		
	# Start timer
	var timer = get_tree().create_timer(duration)
	await timer.timeout
	
	# Continue onwards
	execution_complete.emit()

func interpolate(from : Camera3D) -> void:
	# Create new camera and tween
	var lerp_cam := Camera3D.new()
	var tw := create_tween()
	add_child(lerp_cam)
	
	# Configure lerp cam
	lerp_cam.global_transform = from.global_transform
	lerp_cam.fov = from.fov
	lerp_cam.current = true
	
	# Configure tween
	tw.set_parallel(true)
	tw.set_ease(int_ease)
	tw.set_trans(int_trans)
	
	# Iterate over flags and configure accordingly
	for index in range(3):
		# Check if flag is ticked
		if (lock_properties & 1 << index):
			lerp_cam.set(PROPERTY[index], camera.get(PROPERTY[index]))
			continue
		
		# If we're on rotation, divert
		if index == 1:
			var target_ang = from.global_rotation + wrap_vector(camera.global_rotation - from.global_rotation, -PI, PI)
			tw.tween_property(lerp_cam, PROPERTY[index], target_ang, int_length)
			continue
		
		# Tween property
		tw.tween_property(lerp_cam, PROPERTY[index], camera.get(PROPERTY[index]), int_length)
		
	# Wait for tween to finish, then remove tween cam and set cutscene cam
	# as current.
	await tw.finished
	camera.current = true
	lerp_cam.queue_free()

func wrap_vector(vector : Vector3, min : float, max : float) -> Vector3:
	return Vector3(
		wrap(vector.x, min, max),
		wrap(vector.y, min, max),
		wrap(vector.z, min, max)
	)
