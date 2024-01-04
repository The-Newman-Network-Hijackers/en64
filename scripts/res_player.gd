# res_player.gd
class_name PlayerData extends Resource

'''
Stores player accessories, collectibles and config
'''

## Version number of this file
@export var ver = ""

# OUTFIT
#-------------------------------------------------------------------------------

## The player's accessory dictionary
@export var accessories : Dictionary = {
	"color1" : 8,
	"color2" : 10,
	"color3" : 7,
	"head" : null,
	"face" : null,
	"torso" : null,
}

## The player's saved costumes
@export var costumes : Dictionary = {
	"count" : 0
}

## The player's owned accessories
@export var owned_accessories : Array[int] = [
	00, 01, 02, 03, 04, 05,
	06, 07, 08, 09, 10, 11,
	12
]

# STATISTICS
#-------------------------------------------------------------------------------

## The player's total amount of [Jack]s collected.
@export var jacks : int = 0
## The player's total amount of shards collected.
@export var props : int = 0
## The player's list of collected shards.
@export var prop_list : Array[int] = []

# EQUIPMENT
#-------------------------------------------------------------------------------

## Constants for each equipment
enum EQUIPMENT {
	NONE			= -1,
	GLOVE			= 1 << 0,
	SLINGSHOT		= 1 << 1,
	HAMMER			= 1 << 2
}

## Current equipment hatch, in counter-clockwise order [ULDR]
var equip_hatch = [
	-1,
	-1,
	-1,
	-1
]
## Current selection from the hatch. [0 - 3]
var equip_selection = 0

# CONFIG
#-------------------------------------------------------------------------------

## The player's config settings
@export var config : Dictionary = {
	"video" : {
		"resolution" : Vector2i(854, 480),
		"vsync" : false,
		"fullscreen" : true,
		"dithering" : false,
		"ntsc" : false,
		"debug" : false,
	},
	"audio" : {
		"music_volume" : 0.6,
		"ambient_volume" : 0.7,
		"sfx_volume" : 0.8
	},
	"input" : {
		"input_preference" : -1,
		"sensitivity" : 0.35,
		"cam_mode" : 0,
		"invert_cam_x" : false,
		"invert_cam_y" : true,
	},
	"multiplayer" : {
		"name" : "Player"
	},
	"misc" : {
		"splash_prompt" : true,
	}
}
