# crate.gd
@tool
class_name Crate extends Node3D

'''
Configures Crate entity.
'''

@export_category("Crate")
## Material to use for the crate.
@export var material := preload("res://asset/entity/crate/wooden/mat/wood_crate_1.tres") :
	set(value) : material = value; call_deferred("set_material")
	get : return material
## The amount of health the crate has.
@export var health := 1 :
	set(value) : health = value; call("set_health")
	get : return health
## The amount of [Jack] to drop when broken.
@export var jacks := 0 :
	set(value) : jacks = value; call_deferred("set_jacks")
	get : return jacks
## The size of the crate
@export var size := Vector3(3,3,3) :
	set(value) : size = value; call_deferred("set_size")
	get : return size
## Whether or not to process physics on this crate.
@export var process_physics : bool = false :
	set(value) : process_physics = value; call("set_physics")
	get : return process_physics

func _ready() -> void:
	# Get signal
	for child in get_children():
		child.tree_exited.connect(child_exited.bind())

func child_exited() -> void:
	if get_child_count() > 0:
		return
	queue_free()

# FUNCTION
#-------------------------------------------------------------------------------

## Sets material of crate.
func set_material() -> void:
	# Get node
	var mesh := get_node("crate/vis/Cube") as MeshInstance3D
	mesh.material_override = material

## Sets size of crate.
func set_size() -> void:
	# Get nodes
	var visual := get_node("crate/vis/Cube") as Node3D
	var col1 := get_node("crate/col") as CollisionShape3D
	var col2 := get_node("crate/hbox/col") as CollisionShape3D
	var col3 := get_node("enabler_reciever/col") as CollisionShape3D
	var particle := get_node("crate/vis/particle") as Node3D
	var jack_spawner := get_node("jspawn") as ClusterSpawner
	var chunk_spawner := get_node("chunks") as ClusterSpawner
	var shape := BoxShape3D.new()
	
	# Resize and reposition
	visual.scale = size
	visual.position.y = size.y
	particle.position.y = size.y
	col1.position.y = size.y
	col1.shape = shape
	col2.position.y = size.y
	col2.shape = shape
	col3.shape = shape
	chunk_spawner.spawn_count = ceili((size.x + size.y + size.z) / 3 * 0.5)
	jack_spawner.position.y = size.y
	shape.size = size * 2

## Sets health of crate.
func set_health() -> void:
	# Get node
	var hbox := get_node("crate/hbox")
	hbox.max_health = health

## Sets the amount of jacks to drop.
func set_jacks() -> void:
	# Get node
	var j_spawn := get_node("jspawn")
	j_spawn.spawn_count = jacks

## Sets the physics processing.
func set_physics() -> void:
	# Get node
	var crate_fsm := get_node("crate/crate_fsm")
	crate_fsm.process_mode = Node.PROCESS_MODE_DISABLED if !process_physics else Node.PROCESS_MODE_INHERIT
