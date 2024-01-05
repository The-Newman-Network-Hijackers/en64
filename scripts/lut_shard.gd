# lut_shard.gd
extends Node

'''
Lookup table for Shard data
'''

var shard : Array[ShardData] = [
	## HISTORY CHANNEL
	preload("uid://d3uegrkadkmny"),
	preload("uid://cypnm7io11ahb"),
	preload("uid://bs88qotqmv5th"),
	preload("uid://dpb52i5tau54d"),
	preload("uid://2bv6vxhw21ah"),
	preload("uid://dm177jrmwo8d1"),
	preload("uid://cnpb0t4g6h8vy"),
	preload("uid://dcs3nlrr7rqn3"),
	preload("uid://driif0qm4spen"),
	preload("uid://ns4v5f8qvncp"),
	preload("uid://b6k0u72b6efqy"),
	## FLYING FORTRESS
	preload("uid://bkljcn68ovpt2")
]

# FUNCTION
#-------------------------------------------------------------------------------

# Sorts through shard LUT based on data 
func find_shard(s : ShardData) -> int:
	for x in range(shard.size()):
		if shard[x] == s:
			return x
	return -1
