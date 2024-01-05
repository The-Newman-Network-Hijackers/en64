# lut_shard.gd
extends Node

'''
Lookup table for Shard data
'''

var shard : Array[ShardData] = [
	## HISTORY CHANNEL
	preload("res://data/props/history_channel/prop_backroom.tres"),
	preload("res://data/props/history_channel/prop_bomb1.tres"),
	preload("res://data/props/history_channel/prop_bomb2.tres"),
	preload("res://data/props/history_channel/prop_bomb3.tres"),
	preload("res://data/props/history_channel/prop_caged.tres"),
	preload("res://data/props/history_channel/prop_fungi.tres"),
	preload("res://data/props/history_channel/prop_gj_ruins.tres"),
	preload("res://data/props/history_channel/prop_prison.tres"),
	preload("res://data/props/history_channel/prop_ruinsfrag2.tres"),
	preload("res://data/props/history_channel/prop_seed.tres"),
	preload("res://data/props/history_channel/prop_spring1.tres"),
	## FLYING FORTRESS
	preload("res://data/props/flying_fortress/prop_gj_fortress.tres")
]

# FUNCTION
#-------------------------------------------------------------------------------

# Sorts through shard LUT based on data 
func find_shard(s : ShardData) -> int:
	for x in range(shard.size()):
		if shard[x] == s:
			return x
	return -1
