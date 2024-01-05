# audio_manager.gd
extends Node

'''
Manages sound effect, music, and ambient audio streams.
'''
## References for the current set of music players.
@export var music_players : Array[AudioStreamPlayer] = []
## References for the current set of music stems
@export var music_stems : Array[MusicStem] = []

func _enter_tree() -> void:
	# Fix pause bug
	process_mode = Node.PROCESS_MODE_ALWAYS

# FUNCTION
#-------------------------------------------------------------------------------

## Generates an [AudioStreamPlayer] or [AudioStreamPlayer3D] that deletes itself
## after playing a specified stream.
func spawn_sound_stream(
	stream : AudioStream,
	pitch : float = 1.0,
	position : Vector3 = Vector3.ZERO,
) -> void:
	# Create AudioStreamPlayer(2D)
	@warning_ignore("incompatible_ternary")
	var emitter = (
		AudioStreamPlayer.new() if position == Vector3.ZERO
		else AudioStreamPlayer3D.new()
	)

	# Configure
	emitter.stream = stream
	emitter.pitch_scale = pitch
	emitter.set_bus("Sound")
	emitter.finished.connect(emitter.queue_free.bind())

	# Add to self
	add_child(emitter)
	emitter.play()

	# Position in world space
	if emitter is AudioStreamPlayer3D:
		emitter.global_position = position

## Generates a stem stream if it doesnt already exist.
func spawn_music_stream(new_streams : Array[MusicStem]) -> void:
	# Declare variables
	var spawn : Array[bool] = []
	var index : int = 0

	# Generate array
	spawn.resize(new_streams.size())
	spawn.fill(true)

	# Check if stream already exists
	for stem in music_stems:
		for data in new_streams:
			if data.stream == stem.stream:
				spawn[index] = false
			index += 1
		index = 0

	# Spawn streams if spawn index says to
	for data in new_streams:
		# Increment index
		index += 1

		# Check spawn
		if spawn[index-1] == false:
			continue

		# Spawn in a new stream
		var new_player = AudioStreamPlayer.new()
		new_player.stream = data.stream
		new_player.volume_db = -80
		new_player.pitch_scale = data.pitch
		new_player.set_bus("Music" if data.channel == 0 else "Ambiance")

		# Tween volume
		var tween = create_tween()
		tween.tween_property(
			new_player,
			"volume_db",
			data.volume,
			data.fade.x
		)

		# Add to pool and self
		add_child(new_player)
		music_players.append(new_player)
		music_stems.append(data)

		# Play!
		new_player.play()
		new_player.seek(get_position_from_tag(data.tag))

## Cleans out music pool based on provided stems
func clean_music_pool(new_stems : Array[MusicStem]) -> void:
	# Declare variables
	var temp_players : Array[AudioStreamPlayer] = []
	var temp_stems : Array[MusicStem] = []
	
	for index in music_players.size():
		# Look for overlap. If overlap,
		# dont delete stream.
		var overlap_found = false

		for data in new_stems:
			if music_players[index].stream == data.stream:
				overlap_found = true
				temp_players.append(music_players[index])
				temp_stems.append(music_stems[index])

		if !overlap_found:
			var player = music_players[index]
			var stream = music_stems[index]
			fade_audio_out(player, stream.fade.y)
	
	# Push temporary to actual
	music_players = temp_players
	music_stems = temp_stems

## Fades an audio channel out before deleting it
func fade_audio_out(player : AudioStreamPlayer, fade_time : float = 3) -> void:
	# Create tween
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80, fade_time).set_ease(Tween.EASE_OUT)
	tween.play()
	await tween.finished
	player.queue_free()

## Obtains all music players that fall under
## a defined MusicStem category.
func get_mps_from_category(category : int) -> Array[AudioStreamPlayer]:
	# Declare variable
	var streams : Array[AudioStreamPlayer] = []
	
	# Iterate over stems
	for index in range(music_stems.size()):
		if music_stems[index].category != category:
			continue
		streams.append(music_players[index])
	
	# Return final array
	return streams

## Obtains all music stems that fall under
## a defined MusicStem category.
func get_stem_from_category(category : int) -> Array[MusicStem]:
	# Declare variable
	var stems : Array[MusicStem] = []
	
	# Iterate over stems
	for stem in music_stems:
		if stem.category != category:
			continue
		stems.append(stem)
	
	# Return final array
	return stems

## Obtains music player based on provided ID
func get_mp_from_id(id : int) -> AudioStreamPlayer:
	return music_players[id]

## Obtains music stem based on provided ID
func get_stem_from_id(id : int) -> MusicStem:
	return music_stems[id]

## Checks for stems with the same tag, and returns the position in track
func get_position_from_tag(tag : String) -> float:
	# Abort if no tag
	if tag == "":
		return 0.0
	
	var position : int = 0
	var seek : float = 0.0
	for stem in music_stems:
		if stem.tag == tag:
			var new_seek = music_players[position].get_playback_position()
			seek = new_seek if new_seek > seek else seek
		position += 1
	return seek

## Checks for overlapping stems.
func is_stem_overlapping(player : AudioStreamPlayer, stream : AudioStream) -> bool:
	if player.stream == stream:
		return true
	return false
