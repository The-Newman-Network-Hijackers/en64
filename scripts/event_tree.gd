# event_tree.gd
@icon("res://asset/editor/EventTree.svg.ctex")
class_name EventTree extends Node

'''
Executes a list of events either in a defined order
or in parallel.
'''

# Emitted when fully executed.
signal completed()

enum Primer {
	Evoke, ## [br]Executes only when evoked externally (e.g. [Interactable])
	Automatic, ## [br]Executes when put into the SceneTree.
}

enum Execution {
	Step, ## [br]Executes each child [Event] in node order.
	Parallel ## [br]Executes each child [Event] at the same time.
}

enum Exiter {
	Nothing, ## [br]Do nothing when execution is finished.
	One_Time, ## [br]Remove self when execution is finished.
}

enum PHandler {
	Keep_Player, ## [br]Allows complete control over the player during this [EventTree].
	NoControl_Player, ## [br]Prevents control of player, but player movement continues.
	Freeze_Player, ## [br]Freezes player, but events like [EventMove] will still modify player.
	Stop_Player, ## [br]Completely disables player.
}

@export_category("EventTree")
## Determines if the Player will be frozen, but still manipulatable.
@export var player_handler : PHandler = PHandler.Stop_Player
## The primer type of this [EventTree].
@export var primer : Primer = Primer.Evoke
## The execution type of this [EventTree].
@export var execution : Execution = Execution.Step
## The exiter type of this [EventTree].
@export var exiter : Exiter = Exiter.Nothing

## Position in execution order.
var position : Array[int] = [0]
## Depth in the execution order.
var depth : int = 0
## Root to pull events from
@onready var root : Node = self

## [Event] list.
var events : Array = []
## Reference to the player.
var player : Player
## Copy of last player state
var p_last : String = ""

func _ready() -> void:
	# Disregard if paused
	if process_mode == Node.PROCESS_MODE_DISABLED:
		return
	
	# Set process mode
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Execute based on primer value
	match primer:
		Primer.Automatic:
			execute()
		_:
			pass

# FUNCTION
#-------------------------------------------------------------------------------

## Executes all children events.
func execute() -> void:
	# Get player if not already provided.
	if !player:
		player = get_tree().get_first_node_in_group("Player")
		if player:
			handle_player()
	else:
		handle_player()
	
	# Stop if parallel
	if execution == Execution.Parallel:
		return

	# Begin execution
	var event = root.get_child(position[depth])
	if !event.execution_complete.is_connected(next_event.bind()):
		event.execution_complete.connect(next_event.bind())
	event.player = player
	event._execute()

## Plays the next event
func next_event(n_depth : int = 0) -> void:
	# If we're paused, wait
	while get_tree().paused:
		await get_tree().physics_frame
	
	# Determine if we need to resurface
	if position[depth] + 1 > root.get_child_count() - 1 && depth != 0:
		# Surface root and decrement
		root = root.get_parent()
		depth -= 1
	
	# Look to see if we're done
	if position[depth] + 1 > root.get_child_count() - 1 && depth == 0:
		# Re-enable player if needed.
		finish_player()

		# Run end_tree
		end_tree()
		return
	
	if n_depth:
		# Set new root
		root = get_child(position[depth])
		
		# Increment depth
		depth += n_depth
		position.resize(depth + 1)
		position[depth] = 0
	else:
		# Increment position
		position[depth] += 1
	
	# Get event at position
	var event = root.get_child(position[depth])
	if !event.execution_complete.is_connected(next_event.bind()):
		event.execution_complete.connect(next_event.bind())
	
	# Provide player to event
	event.player = player
	
	# Execute event
	event._execute()

func end_tree() -> void:
	# Reinitialize variables
	position.clear()
	position = [0]
	depth = 0
	
	# Signal complete
	completed.emit()
	
	# Handle based on exiter.
	match exiter:
		Exiter.One_Time:
			queue_free()
		_:
			pass

func handle_player() -> void:
	match player_handler:
		PHandler.NoControl_Player:
			player.has_control = false
		
		PHandler.Freeze_Player:
			p_last = player._state_machine.state.name
			player._state_machine.transition_state("none")

		PHandler.Stop_Player:
			player.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

func finish_player() -> void:
	match player_handler:
		PHandler.NoControl_Player:
			player.has_control = true
		
		PHandler.Freeze_Player:
			player._state_machine.transition_state(p_last)
			p_last = ""
		
		PHandler.Stop_Player:
			player.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
