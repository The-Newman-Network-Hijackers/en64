# breakable.gd
class_name Breakable extends StaticBody3D

'''
Properties for various breakable entities
'''

@export_category("Breakable")
## The visual node of breakable entity
@export var vis_node : Node3D
## The collision node of breakable entity
@export var col_node : CollisionShape3D
