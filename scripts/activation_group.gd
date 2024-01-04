# activation_group.gd
class_name ActivationGroup extends Node3D

'''
Waits for activation from all linked interactibles,
then evokes an EventTree or 
'''

@export_category("ActivationGroup")
## The [EventTree] to execute.
@export var event_tree : EventTree

## The interactibles linked to this [ActivationGroup].
var interactables : Array[Node] = []
## The progress of the activation group
var progress : int = 0

func _ready() -> void:
	# Get all children
	for child in get_children():
		if not child is Activator:
			continue
		
		interactables.append(child)
	
	# Connect signals
	for interactable in interactables:
		interactable.activated.connect(interactable_activated.bind())

# FUNCTION
#-------------------------------------------------------------------------------

## Ran when an interactable is activated.
func interactable_activated() -> void:
	progress += 1
	if progress >= interactables.size():
		activate()

## Ran when everything is active
func activate() -> void:
	event_tree.player = get_tree().get_first_node_in_group("Player")
	event_tree.execute()
