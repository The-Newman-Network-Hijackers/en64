# equipment_state_machine.gd
class_name EquipmentStateMachine extends StateMachine

'''
Extended StateMachine for player equipment
'''

@export_category("EquipmentStateMachine")
## The whitelist of transitions allowed in this equipment
@export_flags("Idle", "Move", "Airborne") var whitelist = 1 << 1

## Reference to player
var player : Player
## Temporary data storage.
var temp_dat : Dictionary = {}

func _ready() -> void:
	# Propogate self to children
	for child in get_children():
		if child is State:
			child.state_machine = self
			child.owner = player

	# Enter the initial state
	state._enter()
