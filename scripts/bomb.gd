# bomb.gd
class_name Bomb extends Entity

'''
Extension of Entity class, contains additional configuration
'''

@export_category("Bomb")
## The fuse time before explosion
@export var fuse_time : float = 5
## Whether to spawn in as fuming or as idle
@export var start_as_fuming : bool = false
## Reference to [Hitbox] node.
@export var hitbox : Hitbox
