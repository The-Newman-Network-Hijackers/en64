# event_wait.gd
class_name EventWait extends Event

'''
Waits for a period of time, signal or player state before
continuing execution of the EventTree.
'''

enum Types {
	Time,
	Signal,
	PlayerState,
}

@export_category("EventWait")
## The type of wait event
@export var type : Types = Types.Time

@export_group("Time")
## The amount of time to wait, in seconds.
@export var time : float = 1.0

@export_group("Signal")
## The node to look for a signal from.
@export var node : Node
## The specific signal to wait for. Please note that
## mishandling this may create an infinite loop.
@export var node_signal : StringName

@export_group("PlayerState")
## The player state to wait for. Please note that
## mishandling this may create an infinite loop.
@export var player_state : StringName

func _execute() -> void:
	# Execute based on type
	match type:
		Types.Time:
			# Create timer and wait
			var timer := get_tree().create_timer(time)
			await timer.timeout
			execution_complete.emit()
		Types.Signal:
			# Await signal from node
			node.connect(node_signal, signal_fired.bind())
		Types.PlayerState:
			# Await state from fsm
			player._state_machine.transition.connect(player_state_entered.bind())

func signal_fired() -> void:
	execution_complete.emit()

func player_state_entered(state : String) -> void:
	if state == player_state:
		execution_complete.emit()
