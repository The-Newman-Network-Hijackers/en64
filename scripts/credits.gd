# credits.gd
extends CanvasLayer

'''
Manages credits sequence.
'''

## Reference to animation player
@onready var anim := $container/anim

func _ready() -> void:
	# Set mouse capture mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed():
			anim.speed_scale = 6.0
		else:
			anim.speed_scale = 1.0
