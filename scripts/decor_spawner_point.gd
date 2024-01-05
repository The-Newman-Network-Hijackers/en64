# decor_spawner_point.gd
@tool
class_name DecorSpawnerPoint extends MultiMeshInstance3D

'''
Spawns decorations based on the position of child nodes
'''

@export_category("DecorSpawnerPoint")
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
	
	# Get positions
	positions = await gather_positions()
	multimesh.instance_count = get_child_count()
	
	# Create instances
	for instance in range(multimesh.instance_count):
		multimesh.set_instance_transform(instance, Transform3D(Basis(), positions[instance]))
	
	# We're done
	print("Decor generation successful!")

## Gathers positions from children nodes
func gather_positions() -> Array[Vector3]:
	# Declare variables
	var tmp_positions : Array[Vector3] = []
	
	# Get positions from children
	for child in get_children():
		tmp_positions.append(child.global_position)
	
	return tmp_positions
	

## Looks for errors in configuration
func verify_config() -> String:
	if !multimesh:
		return "No multimesh defined!"
	return "OK"
