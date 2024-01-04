# cage.gd
extends StaticBody3D

'''
Disables node(s), until self is destroyed.
'''

@export_category("Cage")
## Nodes to disable.
@export var disabled_nodes : Array[Node]

func _enter_tree() -> void:
	for node in disabled_nodes:
		node.process_mode = Node.PROCESS_MODE_DISABLED

func _cage_tree_exiting() -> void:
	for node in disabled_nodes:
		if !is_instance_valid(node):
			continue
		node.process_mode = Node.PROCESS_MODE_INHERIT
