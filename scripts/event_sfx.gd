# event_sfx.gd
class_name EventSFX extends Event

'''
Plays a sound effect.
'''

@export_category("EventSFX")
## The stream to play when executed.
@export var stream : AudioStream
## The volume of which to play the stream.
@export_range(-80.0, 4.0) var volume : float = 0.0
## The pitch of which to play the stream.
@export_range(0.1, 4.0) var pitch : float = 1.0
## Whether or not to wait for the sound effect to finish
## before moving onwards.
@export var await_finish : bool = false

func _execute() -> void:
	# Create stream player
	var sp := AudioStreamPlayer.new()
	add_child(sp)
	
	# Configure and play
	sp.stream = stream
	sp.volume_db = volume
	sp.pitch_scale = pitch
	sp.bus = "Sound"
	sp.play()
	
	# Connect signal and move on
	sp.finished.connect(func():
		sp.queue_free()
	)
	if await_finish:
		await sp.finished
	execution_complete.emit()
