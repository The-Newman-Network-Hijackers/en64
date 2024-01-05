# level_script.gd
@icon("res://asset/editor/LevelScript.svg.ctex")
class_name LevelScript extends Node

'''
Container for LevelData; manages data caching
(e.g. entity and item persistence)
'''

## LevelData associated with this LevelScript
@export var data : LevelData
## Subareas in the level
@export var subareas : Array[Subarea] = []

func _ready() -> void:
	# Set process mode
	if is_inside_tree() && get_parent() is LevelManager:
		process_mode = Node.PROCESS_MODE_PAUSABLE if process_mode == Node.PROCESS_MODE_INHERIT else process_mode
	
	# Verify subareas exist.
	if subareas.size() == 0:
		push_error("No subareas defined in level! - ", name)
		return
