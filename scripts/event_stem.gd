# event_stem.gd
class_name EventStem extends Event

'''
Interacts with AudioManager in order to modify
MusicStem data based on grouping
'''

@export_category("EventStem")
## The category of stem to target. A category of "None"
## will instead let you target a specific channel.
@export var category : MusicStem.Categories = MusicStem.Categories.None
## The channel of stem to target. Will be overriden by
## category variable if category is not set to "None."
@export var channel : int = 0
## The volume to fade these channels by. A value of 0
## will reset the stem to default
@export var volume : float = 0.0
## The time to fade the stem over.
@export var time : float = 1.0

# FUNCTION
#-------------------------------------------------------------------------------

func _execute() -> void:
	# Diverge based on input
	if category != MusicStem.Categories.None:
		modify_category()
	else:
		modify_channel()
	
	# We're done
	execution_complete.emit()

func modify_category() -> void:
	# Declare variables
	var streams = AudioManager.get_mps_from_category(category)
	var stems = AudioManager.get_stem_from_category(category)
	var tw := create_tween()
	
	# Configure tween
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_SINE)
	
	# Iterate over streams
	for index in range(streams.size()):
		tw.tween_property(
			streams[index], 
			"volume_db", 
			volume if !is_zero_approx(volume) else stems[index].volume,
			time
		)
	tw.play()

func modify_channel() -> void:
	# Declare variables
	var stream = AudioManager.get_mp_from_id(channel)
	var stem = AudioManager.get_stem_from_id(channel)
	var tw := create_tween()
	
	# Configure tween
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_SINE)
	
	# Tween
	tw.tween_property(
		stream,
		"volume_db",
		volume if !is_zero_approx(volume) else stem.volume,
		time
	)
	tw.play()
