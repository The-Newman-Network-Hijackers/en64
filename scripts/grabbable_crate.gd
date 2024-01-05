# grabbable_crate.gd
@tool
class_name GrabbableCrate extends Node3D

'''
Grabbable version of the Crate object
'''

enum Types {
	BIG,
	BIGGER,
}
const SIZE = [
	Vector3.ONE * 2.5,
	Vector3.ONE * 4.0
]

@export_category("GrabbableCrate")
## Material to use for the crate.
@export var material := preload("res://asset/entity/crate/metal/mat/vtx_metal_crate_glove.tres") :
	set(value) : material = value; update_crate()
	get : return material
## Type of crate, will determine size
@export var type : Types = Types.BIG :
	set(value) : type = value; update_crate()
	get : return type
## Priority of the grabbable interaction
@export var interact_priority : int = 0 :
	set(value) : interact_priority = value; update_crate()
	get : return interact_priority

# FUNCTION
#-------------------------------------------------------------------------------

## Updates crate in full
func update_crate() -> void:
	if !is_node_ready():
		await ready
	
	set_material()
	set_size()
	set_grabbable_params()
	
	# Set up signal
	var grabbable := get_node("crate/grabbable") as Grabbable
	if !Engine.is_editor_hint():
		if !grabbable.interacted_with.is_connected(crate_interracted.bind()):
			grabbable.interacted_with.connect(crate_interracted.bind())

## Called when player has successfully picked up crate
func crate_interracted() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	get_node("crate/crate_fsm").transition_state("picked_up")

## Sets [Grabbable] parameters.
func set_grabbable_params() -> void:
	var grabbable := get_node("crate/grabbable") as Grabbable
	grabbable.priority = interact_priority
	grabbable.type = 1

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
	var shadow := get_node("crate/shadow") as Shadow
	var particle := get_node("crate/vis/particle") as Node3D
	var g_col := get_node("crate/grabbable/col") as CollisionShape3D
	var ray_player := get_node("crate/player") as ShapeCast3D
	var ray_shape := BoxShape3D.new()
	var shape := BoxShape3D.new()
	var g_shape := BoxShape3D.new()
	
	# Resize and reposition physical shape
	visual.scale = SIZE[type]
	visual.position.y = SIZE[type].y
	particle.position.y = SIZE[type].y
	shadow.size = (SIZE[type].x + SIZE[type].z) * 1.25
	col1.position.y = SIZE[type].y
	col1.shape = shape
	shape.size = SIZE[type] * 2
	
	# Resize and reposition grab shape
	g_shape.size = SIZE[type] * 3
	g_col.position.y = SIZE[type].y * 1.5
	g_col.shape = g_shape
	
	# Resize and reposition player shapecast
	ray_shape.size = SIZE[type] * 1.9
	ray_player.shape = ray_shape
	ray_player.target_position.y = ray_shape.size.y * 0.45
