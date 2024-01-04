# playerinteractradius.gd
class_name PlayerInteractionRadius extends Area3D

'''
Handles interactions with [Interactable] based on priorities.
'''

signal interact_attempted(p_ref)

const INTERACT_WHITELIST = [
	"idle", "move"
]

@export_category("PlayerInteractRadius")
## Reference to player's state machine
@export var player_fsm : StateMachine

## Assume owner is player
@onready var player = owner as Player

## The current array of [Interactable] bodies
var interact_pool : Array[Interactable] = []
## The current target from interact_pool
var interact_target : Interactable = null

func _ready() -> void:
	# Configure
	collision_mask = 1 << 2
	collision_layer = 0
	monitorable = false
	
	# Link up signals
	area_entered.connect(_area_entered.bind())
	area_exited.connect(_area_exited.bind())

func _area_entered(area : Area3D) -> void:
	# Verify type
	if !(area is Interactable):
		return
	
	# Append self to interaction pool
	interact_pool.append(area)
	update_target()

func _area_exited(area : Area3D) -> void:
	# Verify type
	if !(area is Interactable):
		return
	
	# Look for self in pool and remove
	for i in range(interact_pool.size()):
		if interact_pool[i] == area:
			interact_pool.remove_at(i)
			update_target()
			return

func _unhandled_input(event: InputEvent) -> void:
	# Interaction attempted
	if event.is_action_pressed("interact"):
		# Check if player is in whitelisted state
		if player_fsm.state.name in INTERACT_WHITELIST && interact_target != null:
			get_tree().root.set_input_as_handled()
			interact_attempted.emit(player)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			interact_pool.clear()
			update_target()
	
# FUNCTION
#-------------------------------------------------------------------------------

## Update cycle for determining the current target
func update_target() -> void:
	# Reset current
	if interact_target:
		interact_attempted.disconnect(interact_target.interact.bind())
		interact_target.focused = false
		interact_target = null
	
	# Get new
	if interact_pool.size() > 0:
		interact_target = get_new_target()
		interact_attempted.connect(interact_target.interact.bind())
		interact_target.focused = true

## Determines the Interactable with the top-most priority.
func get_new_target() -> Interactable:
	# Declare variables
	var target : Interactable
	var minimum : int = -1
	
	# Iterate through pool and compare priority
	for interactable in interact_pool:
		# Set minimum from first
		if minimum == -1:
			minimum = interactable.event_priority
			target = interactable
			continue
		
		# See if there is a new minimum
		if interactable.event_priority >= minimum:
			minimum = interactable.event_priority
			target = interactable
			continue
	
	return target
