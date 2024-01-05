# shadow.gd
class_name Shadow extends Node3D

'''
Casts a fake shadow at the collision point of the ray.
'''

enum Types {
	Circle,
	Square
}

@export_category("Shadow")

## Scope of the shadow.
@export_flags_3d_render var scope = 1 << 0
## The size of the shadow, in units.
@export var size : float = 2
## Length of the shadow's raycast.
@export var length : float = 100.0
## The type of shadow.
@export var type : Types = Types.Circle

@export_group("Auto Size")
## Whether or not to automatically calculate shadow based on AABB.
@export var auto_size : bool = false
## The mesh to base the AABB calculation on.
@export var aabb_mesh : MeshInstance3D

## Reference to shadow mesh
var shadow : Decal
## Last known position.
var last_pos : Vector3

func _enter_tree() -> void:
	# Reject if mesh exists
	if shadow:
		return
	
	# Generate mesh
	shadow = generate_shadow()
	add_child(shadow)

func _physics_process(delta) -> void:
	# Determine if an update is needed
	if get_parent().global_position == last_pos:
		return
	
	# Declare variables
	var space := get_world_3d().direct_space_state
	var origin = global_position
	var end = origin + (Vector3.DOWN * length)
	var query = PhysicsRayQueryParameters3D.create(origin, end, scope)
	query.hit_from_inside = true
	query.exclude = [get_parent()]
	
	# Get result and apply
	var result = space.intersect_ray(query)
	shadow.global_position = result.position if result.has("position") else (
		Vector3(get_parent().global_position.x, global_position.y, get_parent().global_position.z)
	)
	
	# Set last pos
	last_pos = get_parent().global_position

# FUNCTION
#-------------------------------------------------------------------------------

## Generates a shadow based on specified parameters
func generate_shadow() -> Decal:
	# Declare variables
	var instance = Decal.new()
	var target_size = get_aabb_size() if auto_size else Vector3.ONE * size
	
	# Configure and return
	instance.texture_albedo = get_material()
	instance.size = target_size
	instance.cull_mask = scope
	instance.top_level = true
	return instance

## Calculates size based on mesh AABB
func get_aabb_size() -> Vector3:
	var mesh_aabb = aabb_mesh.get_aabb()
	return mesh_aabb.size

## Loads material based on shadow type
func get_material() -> StandardMaterial3D:
	match type:
		Types.Circle:
			return load("res://asset/effect/shadow/round.png")
		Types.Square:
			return load("res://asset/effect/shadow/square.png")
		_:
			return null
