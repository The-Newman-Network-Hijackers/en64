# fade.gd
extends CanvasLayer

'''
Plays a fade transition (forwards or backwards) when evoked
'''

enum Types {
	FadeColor,
	FadeCircle
}

## FadeCircle sounds
@onready var sfx_fcircle = [
	$circle_fade/circle_in,
	$circle_fade/circle_out
]

@onready var anim := $anim

# Fades the screen out
func fade_out(type : Types, length : float = 1.0) -> void:
	# Fade out
	match type:
		Types.FadeColor:
			anim.speed_scale = 1.0 / length
			anim.play("fade")
		Types.FadeCircle:
			anim.speed_scale = 1.0 / length
			anim.play("fade_circle")
			sfx_fcircle[1].play()

# Fades the screen in
func fade_in(type : Types, length : float = 1.0) -> void:
	# Fade in
	match type:
		Types.FadeColor:
			anim.speed_scale = 1.0 / length
			anim.play_backwards("fade")
		Types.FadeCircle:
			anim.speed_scale = 1.0 / length
			anim.play_backwards("fade_circle")
			sfx_fcircle[0].play()
