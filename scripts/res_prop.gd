# res_prop.gd
class_name ShardData extends Resource

'''
Holds information and model data of a shard.
'''

@export_category("ShardData")
## The name of the shard.
@export var shard_name : String = "Shard"
## The level location of the shard.
@export var shard_location : String = "World"
## The description of the shard.
@export_multiline var shard_description : String
## A hint about the location of the shard
@export_multiline var shard_hint : String
