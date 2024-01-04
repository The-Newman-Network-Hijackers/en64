# decor_spawner.gd
@tool
class_name DecorSpawner extends MultiMeshInstance3D

'''
Spawns decorations randomly across a mesh 
'''

@export_category("DecorSpawner")
## PhysicsBody to collide with.
@export var target : StaticBody3D
## Mesh to generate AABB from.
@export var mesh : MeshInstance3D
## The amount of decor to spawn
@export var count : int = 25
## Seed to use for generation
@export var seed : int = 0
## Randomizes seed when toggled
@export var randomize_seed : bool = false :
	set(_value) : randomize_seed = false; seed = rand_from_seed(seed)[0]
	get : return randomize_seed
## Generates a new multi-mesh when toggled
@export var generate : bool = false :
	set(_value) : generate = false; generate_decorations()
	get : return generate

## The positions to place the mesh instances
var positions : Array[Vector3]

# FUNCTION
#-------------------------------------------------------------------------------

## Generates decorations.
func generate_decorations() -> void:
	# Seed and verify
	seed(seed)
	if verify_config() != "OK":
		push_warning(verify_config())
		return
	
	# Gather positions
	multimesh.instance_count = 0
	positions = await gather_positions()
	
	# Create decor
	multimesh.instance_count = count
	for instance in range(multimesh.instance_count):
		multimesh.set_instance_transform(instance, Transform3D(Basis(), positions[instance]))
	
	# We're done
	print("Decor generation successful!")

## Gathers positions using raycasts
func gather_positions() -> Array[Vector3]:
	# Declare variables
	var tmp_positions : Array[Vector3] = []
	var target_layer = target.collision_layer
	
	# Create raycast node
	var ray : RayCast3D = RayCast3D.new()
	ray.target_position = Vector3.DOWN * 1000
	add_child(ray)
	await get_tree().physics_frame
	
	# Get AABB and spawn range
	var aabb = mesh.get_aabb()
	var x_range = Vector2(aabb.position.x, aabb.end.x)
	var z_range = Vector2(aabb.position.z, aabb.end.z)
	
	# Print coords
	print(x_range)
	print(z_range)
	
	# Configure masks
	ray.collision_mask = 1 << 15
	target.collision_layer = 1 << 15
	
	for index in range(count):
		var passed = false
		while !passed:
			# Generate new position
			var raypos = Vector3(
				mesh.global_position.x + randf_range(x_range.x, x_range.y),
				aabb.position.y + aabb.size.y + 150,
				mesh.global_position.z + randf_range(z_range.x, z_range.y)
			) 
			
			# Shoot ray and check
			ray.global_position = raypos
			ray.force_raycast_update()
			await get_tree().physics_frame
			
			if ray.is_colliding():
				tmp_positions.append(ray.get_collision_point())
				passed = true
	
	# Wrap up
	ray.queue_free()
	target.collision_layer = target_layer
	return tmp_positions

## Looks for errors in configuration
func verify_config() -> String:
	if !target:
		return "No target found!"
	if !mesh:
		return "No mesh to generate AABB from!"
	if !multimesh:
		return "No multimesh defined!"
	return "OK"
