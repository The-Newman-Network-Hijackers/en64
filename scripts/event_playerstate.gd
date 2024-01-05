# event_playerstate.gd
class_name EventPlayerState extends Event

'''
Sets the state of the player
'''

@export_category("EventPlayerState")
## The state to set the player to
@export var target_state : String = "idle"
## Message to send to state
@export var message : Dictionary = {}

func _execute() -> void:
	# Set player state
	player._state_machine.transition_state(target_state, message)
	
	execution_complete.emit()
