# state_machine.gd
class_name StateMachine extends Node

'''
Manages the transition between various child State nodes.
'''

signal transition(new_state : String)

@export_category("StateMachine")
## The initial State of the StateMachine
@export var initial_state : State
## Toggles debug printing
@export var debug_print : bool = false

## The currently active state
@onready var state = initial_state if initial_state else null

func _ready() -> void:
	# Await parent initialization
	await owner.ready

	# Propogate self to children
	for child in get_children():
		if child is State:
			child.state_machine = self

	# Enter the initial state
	state._enter()

func _unhandled_input(event: InputEvent) -> void:
	state._state_unhandled_input(event)

func _process(delta: float) -> void:
	state._state_process(delta)

func _physics_process(delta: float) -> void:
	state._state_physics_process(delta)

# FUNCTION
#-------------------------------------------------------------------------------

func transition_state(target_state : String, data : Dictionary = {}) -> void:
	# Validate that state exists
	if not has_node(target_state):
		push_error(target_state, " not found in StateMachine.")
		return

	# Exit current state, and transition to next.
	state._exit()
	state = get_node(target_state)
	state._enter(data)

	# Emit signal
	transition.emit(state.name)

	# Print state if debug_print enabled
	if debug_print:
		# Transition
		print(owner.name, " - Transitioning to ", state.name)
		# Message
		print("Message : ", JSON.parse_string(str(data)))

