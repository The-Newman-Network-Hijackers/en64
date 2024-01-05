# res_leveldata.gd
class_name LevelData extends Resource

'''
Holds information about a level;
name, group, music and level boundaries.
'''

## The name of the level.
@export var level_name : String = "DEFAULT"
## Internal description of the level
@export_multiline var level_desc : String = ""
## Dictates if this level is a menu. If so, it will not
## load appendages (e.g. player)
@export var is_menu : bool = false

@export_group("Data")
## List of flags exclusive to level
@export var flags : Dictionary
