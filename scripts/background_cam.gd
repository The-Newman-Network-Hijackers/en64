# background_cam.gd
class_name BackgroundCam extends Camera3D

'''
Compliment to Background class; mimics the main
viewport's camera to simulate background movement
'''

const CEOFFS = [
	[2.0, 1.0],
	[1.0, 1.25]
]

## The current camera in the scene.
var current_cam : Camera3D
## The assigned coeff.
var coeff : int = 1

func _ready() -> void:
	var bg := get_parent().get_parent().get_parent() as Background
	coeff = bg.type

func _process(_delta : float) -> void:
	# Stop if editor
	if Engine.is_editor_hint():
		return
	
	# Get camera
	current_cam = get_tree().root.get_camera_3d()
	if !current_cam:
		return
	
	# Update positioning
	position.x = current_cam.global_rotation_degrees.y / 180.0 * -1
	position.y = .1 + current_cam.global_rotation_degrees.x / (450.0 / CEOFFS[coeff][0])
	
	# Update FOV
	size = current_cam.fov / (100.0 * CEOFFS[coeff][1])
