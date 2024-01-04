# pcam_springarm.gd
class_name PCam_SpringArm extends SpringArm3D

'''
Provides player camera rotation and movement
'''

## The target rotation of the camera, in degrees.
@onready var target_rotation : Vector3 = rotation_degrees
## Reference to camera
@onready var camera : Camera3D = $f_cam/player_cam
## Reference to cam_body
@onready var cam_body : Area3D = $f_cam/player_cam/cam_body
## Reference to state machine
@onready var _fsm := $state_machine as StateMachine

## The sensitivity value of the camera.
var sensitivity : float
## Whether to invert input on the x axis
var invert_x : bool = false
## Whether to invert input on the y axis
var invert_y : bool = false
## The target length of the springarm
var target_length : float = 24.0

func _ready() -> void:
	# Connect signals
	PlayerDataManager.data_changed.connect(get_config.bind())
	cam_body.area_entered.connect(cam_area_entered.bind())
	cam_body.area_exited.connect(cam_area_exited.bind())
	
	# Determine sensitivity
	get_config()

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventKey:
		if event.physical_keycode == KEY_F1 && event.is_pressed():
			_fsm.transition_state("debug" if _fsm.state.name != "debug" else "manual_analog")

func cam_area_entered(area : Area3D) -> void:
	# Check if area is water.
	if not area is Water:
		return
	
	# Get material from area
	area = area as Water
	var material = area.material
	var color = material.get("shader_parameter/out_color") as Color
	color.s = 0.5
	
	# Signal to UI to toggle wobbly effect
	var player : Player = owner as Player
	player.toggle_wobble.emit(true, color)

func cam_area_exited(area : Area3D) -> void:
	# Check if area is water.
	if not area is Water:
		return
	
	# Signal to UI to toggle wobbly effect
	var player : Player = owner as Player
	player.toggle_wobble.emit(false, Color.AQUA)

# FUNCTION
#-------------------------------------------------------------------------------

## Gets the camera configuration from [PlayerData].
func get_config() -> void:
	# Get player data and set parameters
	var data : PlayerData = PlayerDataManager.load_data()
	sensitivity = data.config.input.sensitivity
	invert_x = data.config.input.invert_cam_x
	invert_y = data.config.input.invert_cam_y
