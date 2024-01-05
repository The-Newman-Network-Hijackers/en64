# prop.gd
class_name Shard extends Area3D

'''
Primary collectible.
'''

@export_category("Prop")
## The [ShardData] associated with this [Shard].
@export var data : ShardData
## Optional [EventTree] to call after collecting.
@export var event_tree : EventTree

## The mesh of the prop.
@onready var i_mesh : Node3D = $visuals/mesh
## The collision of the prop.
@onready var collision : CollisionShape3D = $col
## The visual grouping of the prop
@onready var visual : Node3D = $visuals
## The glow_pivot of the prop.
@onready var glow_pivot : Node3D = $visuals/glow_pivot
## The glow mesh of the prop
@onready var glow_mesh : MeshInstance3D = $visuals/glow_pivot/glow
## Jack spawner
@onready var jacks : ClusterSpawner = $jacks

func _body_entered(body : Node3D) -> void:
	if body is Player:
		# Send data to stat
		var result = PlayerDataManager.add_shard(LUTShard.find_shard(data))

		# Force state transition and send self
		if result:
			body._state_machine.transition_state(
				"prop_get",
				{"prop" : data, "visual" : visual.duplicate()}
			)
		else:
			# Grant Player 25 Jacks
			jacks.reparent(get_parent())
			jacks.spawn()
			if event_tree:
				event_tree.execute()
			queue_free()
			return
		
		# If theres an EventTree, call it
		if event_tree:
			body.shard_collect_done.connect(event_tree.execute.bind(), CONNECT_ONE_SHOT | CONNECT_DEFERRED)
		
		# Die
		queue_free()
