# golden_jack_manager
class_name GoldenJackManager extends ActivationGroup

'''
Manages Golden Jack hunt sequences.
'''

func _ready() -> void:
	# Get all children
	var index = 0
	for child in get_children():
		# If ball, connect different signal
		if child is GJBall:
			child.tree_exiting.connect(gjb_collected.bind())
			continue
		
		# Skip over non-jacks
		if not child is GoldenJack:
			continue
		
		# Increment
		index += 1
		
		# Append, configure and connect
		interactables.append(child)
		child.visible = false
		child.process_mode = Node.PROCESS_MODE_DISABLED
		child.collected.connect(update_gj.bind())

## Ran when a golden jack ball is collected.
func gjb_collected() -> void:
	# Iterate over golden jacks and activate them
	for gj in interactables:
		gj.visible = true
		gj.process_mode = Node.PROCESS_MODE_INHERIT

## Ran when a golden jack is collected.
func update_gj(source : GoldenJack) -> void:
	# Update progress
	progress += 1
	if progress >= interactables.size():
		activate()
	
	# Set text to progress
	source.id_count = progress

