# event_flag.gd
class_name EventFlag extends Event

'''
Sets a local or global flag.
'''

enum Type {
	Local,
	Global
}

@export_category("EventFlag")
## The scope of flag
@export var flag_type : Type = Type.Local
## The flag key to look for
@export var flag_name : String = ""
## The value to set the flag
@export var flag_value : bool = true

func _execute() -> void:
	# Determine if global or local
	match flag_type:
		Type.Local:
			# Get level
			var lm := get_tree().get_first_node_in_group("LevelManager") as LevelManager
			var l_dat := lm.level.data as LevelData
			
			# Check if it has flag
			if l_dat.flags.has(flag_name):
				l_dat.flags[flag_name] = flag_value
			else:
				push_error("Local flag not found - ", flag_name)
	
	# We're done
	execution_complete.emit()
