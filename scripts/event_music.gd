# event_music.gd
class_name EventMusic extends Event

'''
Pushes a new stem stack to the AudioManager
'''

@export_category("EventMusic")
# New stack to send to [AudioManager].
@export var new_stems : Array[MusicStem]

func _execute() -> void:
	# Push stack
	AudioManager.clean_music_pool(new_stems)
	AudioManager.spawn_music_stream(new_stems)
	
	execution_complete.emit()
