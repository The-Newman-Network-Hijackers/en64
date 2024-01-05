# respawner.gd
class_name Respawner extends Node3D

'''
Respawns all descendants when they are out of the scene tree.
'''

@export_category("Respawner")
## Scene to spawn in
@export var spawn_scene : PackedScene
## The delay between respawning descendants
@export var respawn_delay : float = 3.0
## Parameters to propagate to respawned nodes
@export var parameters : Dictionary = {}

## Reference to spawn particles
const SPAWN_PARTICLE = preload("res://asset/effect/respawn/respawn.tscn")
## Reference to spawn stream
const SPAWN_STREAM = preload("res://audio/sfx/poof.wav")

## Array of transforms
var transforms := []

func _ready() -> void:
	# Iterate through children
	var children = get_children()
	for index in range(len(children)):
		transforms.append(children[index].transform) 
		children[index].queue_free()
		spawn_child(transforms[index], index, false)
	
	# Connect signal
	child_exiting_tree.connect(child_exited_tree.bind())

# FUNCTION
#-------------------------------------------------------------------------------

func child_exited_tree(_node : Node) -> void:
	# Verify we are in tree
	if !is_inside_tree():
		return
	
	# Verify node is part of respawn
	if !_node.name.is_valid_int():
		return
	
	# Get ID from node name
	var id := int(str(_node.name))
	
	# Put child in queue
	var nt := get_tree().create_timer(respawn_delay, false, true)
	nt.timeout.connect(spawn_child.bind(transforms[id], id))

func spawn_child(tf : Transform3D, id : int, effects : bool = true) -> void:
	# If not in tree, abort
	if !is_inside_tree():
		return
	
	if effects:
		# Create respawn particles
		var rp_i := SPAWN_PARTICLE.instantiate()
		rp_i.finished.connect(func(): rp_i.queue_free())
		
		# Create sound
		var sfx := AudioStreamPlayer3D.new()
		sfx.finished.connect(func(): sfx.queue_free())
		sfx.stream = SPAWN_STREAM
		sfx.volume_db = -4
		sfx.max_db = -4
		sfx.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
		sfx.max_distance = 120.0
		sfx.bus = "Sound"
		
		# Add both to scene
		get_parent().call_deferred("add_child", sfx)
		get_parent().call_deferred("add_child", rp_i)
		
		await sfx.ready
		sfx.transform = tf
		rp_i.transform = tf
		sfx.play()
		rp_i.restart()
	
	# Add child
	var child = spawn_scene.instantiate()
	for property in parameters.keys():
		child.set(property, parameters.get(property))
	child.transform = tf
	add_child(child)
	child.name = str(id)
