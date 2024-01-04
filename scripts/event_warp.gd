# event_warp.gd
class_name EventWarp extends Event

'''
When executed, signals to LevelManager to warp to WarpPoint.
'''

enum Types {
	Same_Area,
	Different_Area,
	Different_Level,
}

@export_category("EventWarp")

## The type of teleport event.
@export var type : Types = Types.Different_Level
## Whether or not to pause the game when warping.
@export var do_pause : bool = true
## The target scene, if applicable.
@export_file("*.tscn") var target_scene
## The target area, if applicable.
@export var target_area : int = 0
## The target [WarpPoint] ID. A target of -1 will teleport
## you to the default warp of the scene.
@export var target_id : int = -1

@export_group("Transition")

## The length of the fade transition.
@export var fade_length : float = 0.5
## The delay of the fade transition.
@export var fade_delay : float = 0.15

func _execute() -> void:
	# Obtain level_manager
	var level_manager := get_tree().current_scene.get_node("level_manager") as LevelManager
	assert(level_manager != null)

	# Create packet from parameters
	var packet : Dictionary = {
		"fade_length" : fade_length,
		"fade_delay" : fade_delay,
		"warp_id" : target_id,
		"subarea" : target_area,
		"pause" : do_pause
	}

	# Diverge based on warp types.
	match type:
		Types.Same_Area:
			print_debug("Warping to same area")

			# Fade and await signal from level manager
			level_manager.fade_screen(packet)
			await level_manager.faded

			# Get all warp nodes and begin iterating
			var warps = get_tree().get_nodes_in_group("Warp")
			for warp in warps:
				warp = warp as WarpPoint
				if warp.id == target_id && warp.process_mode != Node.PROCESS_MODE_DISABLED:
					# Found proper warp, teleport player
					warp.player = player
					warp.process_transition()
					execution_complete.emit()
					return

			# There was an error!
			push_error("Warp of ID ", target_id, " not found.")

		Types.Different_Area:
			print_debug("Warping to different area")
			level_manager.change_subarea(packet)
		
		Types.Different_Level:
			# If the level is different, send warp packet
			level_manager.change_level(
				target_scene,
				packet
			)
	
	await level_manager.level_unloaded
	execution_complete.emit()
	return
