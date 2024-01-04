# enabler_reciever.gd
class_name EnablerReciever extends Area3D

'''
Enables owner when sender is met.
'''

enum Types {
	Inherit,
	Always,
	Pausable,
	When_Paused,
}

@export_category("EnablerReciever")
## Node override. Will default to owner node if not set.
@export var target : Node
## What type of processing to set owner when enabled
@export var type : Node.ProcessMode = Node.PROCESS_MODE_INHERIT

## Whether or not enabler is enabling
var is_enabling : bool = false :
	set(value) : is_enabling = value; call_thread_safe("update")
	get : return is_enabling

func _enter_tree() -> void:
	# Configure self
	monitoring = false
	collision_mask = 0
	input_ray_pickable = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	target = target if target else owner
	
func _ready() -> void:
	call_deferred("update")

# FUNCTION
#-------------------------------------------------------------------------------

func update() -> void:
	if !is_instance_valid(target) || !is_inside_tree():
		queue_free()
		return
	target.process_mode = type if is_enabling else Node.PROCESS_MODE_DISABLED
