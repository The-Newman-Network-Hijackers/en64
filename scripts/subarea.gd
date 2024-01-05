# subarea.gd
class_name Subarea extends Node3D

'''
Child of LevelScript, acts as an area of a level.
'''

@export_category("Subarea")
## The music to play in this level.
@export var music : Array[MusicStem]
## Whether or not to reload level when dying.
## Area has to be saved to a file (*.TSCN) in order to be properly reloaded.
@export var reload_on_death : bool = false
## Environment effect for this area
@export var environment : WorldEnvironment
## Weather effect to attach to the player
@export var weather_effect : Node3D

## Copy of subarea
var subarea_copy : PackedScene

func _ready() -> void:
	# Determine copy if necessary
	if reload_on_death:
		var area_path = scene_file_path as String
		if area_path:
			subarea_copy = load(area_path) as PackedScene
			return
		push_error("Reload on death ticked, but area is not an instance!")

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if visible:
				if !is_ancestor_of(environment):
					add_child(environment)
				return
			remove_child(environment)

func _exit_tree() -> void:
	if is_instance_valid(environment):
		environment.queue_free()

## Called to change music stack
func change_stem(new_stems : Array[MusicStem]) -> void:
	AudioManager.clean_music_pool(new_stems)
	AudioManager.spawn_music_stream(new_stems)

## Sets last respawn info in [Player].
func set_respawn(target_warp : int) -> void:
	var p := get_tree().get_first_node_in_group("Player") as Player
	if !p: return
	p.last_known_warp = target_warp
