# res_music_stem.gd
class_name MusicStem extends Resource

'''
Holds stream, pitch and volume data for music and ambient
'''

## Enumerator for sound channels
enum Channels {
	Music,
	Ambiance,
}
## Enumerator for categories
enum Categories {
	None,
	Primary,
	Secondary,
	Percussion
}

@export_category("MusicStem")
## The audio stream associated with this stream
@export var stream : AudioStream
## The tag associated with the stream. If there are multiple
## streams with the same tag, stem playback will sync
@export var tag : String = ""
## The category of the stem. You can fade out stem categories using
## [EventStem]
@export var category : Categories = Categories.None

@export_group("Playback")
## Whether or not to restart this stream during a transition.
@export var always_restart : bool = false
## The pitch of the stream
@export var pitch : float = 1.0
## The volume, in decibels, of the stream
@export var volume : float = 0
## The fade times. X represents fadein while Y represents fadeout
@export var fade : Vector2 = Vector2(0.25, 0.25)
## The channel to play this track on
@export var channel : Channels = Channels.Music

