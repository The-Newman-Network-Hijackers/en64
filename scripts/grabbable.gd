# grabbable.gd
class_name Grabbable extends Interactable

'''
Grabbable interactible
'''

enum Types {
	Small = 0,
	Big   = 1
}

signal thrown()

@export_category("Grabbable")
## Type of grabbable
@export var type : Types = Types.Small
## Reference to entity component
@export var entity : Entity

## Original physics values
@onready var og_layer = entity.collision_layer
@onready var og_mask = entity.collision_mask

## Whether or not [Entity] is grabbed
var is_grabbed = false
## Reference to player
var p_ref : Player

func _enter_tree() -> void:
	# Connect signals
	if !thrown.is_connected(grabbable_thrown):
		thrown.connect(grabbable_thrown.bind())

func _exit_tree() -> void:
	if is_grabbed:
		var em := p_ref._equip_manager as PlayerEquipmentManager
		p_ref._state_machine.transition_state("airborne")
		em.current_equipment.transition_state("none", {"force_detach" : true})

# FUNCTION
#-------------------------------------------------------------------------------

## Ran when [Player] interacts with self.
func interact(player : Player) -> void:
	# Check if player has glove
	var em := player._equip_manager
	var id := em.current_equipment_id
	
	# If Player has glove equipped, transition to glove states
	if id == PlayerData.EQUIPMENT.GLOVE && em.can_switch_equipment:
		# Emit signal
		interacted_with.emit()
		
		# Configure
		p_ref = player
		entity.collision_layer = 1 << 15 # GrabbedEntity
		entity.collision_mask = 0 # None
		is_grabbed = true
		
		# Transition
		var em_fsm := em.current_equipment as EquipmentStateMachine
		em_fsm.transition_state(
			"interact_router",
			{
				"state" : player._state_machine.state.name,
				"gr_ref" : self,
				"gr_ent" : entity,
				"p_type" : type,
				"p_node" : owner,
			}
		)
		
		# Make indicator invisible
		input_anchor.visible = false

## Ran when [Player] throws [Grabbable].
func grabbable_thrown() -> void:
	# Re-enable collisions
	entity.collision_layer = og_layer
	entity.collision_mask = og_mask
	
	# Remove reference
	is_grabbed = false
	p_ref = null
