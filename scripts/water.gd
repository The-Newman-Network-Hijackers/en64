# water.gd
@tool
class_name Water extends Area3D

'''
Generates a water surface along with collision.
'''

@export_category("Water")

## The size of the water plane
@export var size : Vector3 = Vector3(250, 100, 250)
## The amount of subdivisons to do on the plane.
@export var detail : int = 1
## Ambient sound effect to use.
@export var ambience : AudioStream = preload("res://audio/amb/amb_ocean.mp3")

@export_group("Material")
## The material to use for the water plane
@export var material : Material
## The size of the UV
@export var uv_fac : float = 4

@export_group("")
## Generates pool of water
@export var generate : bool = false :
	set(value) : if value || !expose_nodes: generate_water(); generate = false;
	get : return generate
## Whether or not to expose children nodes to editor
@export var expose_nodes : bool = false :
	set(value) : expose_nodes = value;
	get : return expose_nodes

## Reference to visual
var visual : MeshInstance3D
## Reference to collision
var collision : CollisionShape3D

func _ready() -> void:
	# Configure self
	collision_mask = 1 << 1 # Player
	collision_layer = 1 << 3 # Water
	
	# Connect signals
	body_entered.connect(_body_entered.bind())
	body_exited.connect(_body_exited.bind())

func _body_entered(body : Node3D) -> void:
	# Verify body is player
	assert(body is Player)
	
	# Assign self to player
	body = body as Player
	body.current_waterbody = self
	
	# Debug print
	print("Player has entered waterbody! - ", name)

func _body_exited(body : Node3D) -> void:
	# Verify body is player
	assert(body is Player)
	
	print("Player has left waterbody! - ", name)
	
	# Do nothing if current_waterbody isnt self
	body = body as Player
	if body.current_waterbody != self:
		return
	
	# Otherwise, just remove the reference
	body.current_waterbody = null

# FUNCTION
#-------------------------------------------------------------------------------

## Full generate cycle for water surface
func generate_water() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()
	visual = null
	collision = null
	
	# Cycle
	generate_visual()
	generate_collision()
	generate_ambience()

## Generates the visual
func generate_visual() -> void:
	# Declare variables
	var tris : Array = []
	var mesh := ArrayMesh.new()
	visual = MeshInstance3D.new()
	
	# Create surface tool
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Iterate and get points
	for div_x in range(detail):
		for div_y in range(detail):
			generate_plane(
				st,
				Vector2(size.x, size.z) / detail, 
				(Vector2(size.x, size.z) / detail) * Vector2(div_x, div_y) - Vector2(size.x / 2, size.z / 2)
			)
	
	# Commit to array
	tris = st.commit_to_arrays()
	
	# Set mesh
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, tris)
	visual.mesh = mesh
	visual.material_override = material
	visual.layers = 1 << 3 # Water
	visual.rotation.z = deg_to_rad(180)
	add_child(visual)
	if Engine.is_editor_hint() && expose_nodes:
		visual.set_owner(get_tree().edited_scene_root)

## Generates a set of points that creates one plane
func generate_plane(st : SurfaceTool, p_size : Vector2, p_off : Vector2 = Vector2.ZERO) -> void:
	# Tri 1
	st.set_normal(Vector3.DOWN)
	st.set_uv(Vector2(p_off.x, p_off.y) / uv_fac)
	st.add_vertex(Vector3(p_off.x, 0, p_off.y))
	st.set_uv(Vector2(p_off.x, p_off.y + p_size.y) / uv_fac)
	st.add_vertex(Vector3(p_off.x, 0, p_size.y + p_off.y))
	st.set_uv(Vector2(p_off.x + p_size.x, p_off.y + p_size.y) / uv_fac)
	st.add_vertex(Vector3(p_size.x + p_off.x, 0, p_size.y + p_off.y))

	# Tri 2
	st.set_normal(Vector3.DOWN)
	st.set_uv(Vector2(p_off.x + p_size.x, p_off.y + p_size.y) / uv_fac)
	st.add_vertex(Vector3(p_size.x + p_off.x, 0, p_size.y + p_off.y))
	st.set_uv(Vector2(p_off.x + p_size.x, p_off.y) / uv_fac)
	st.add_vertex(Vector3(p_size.x + p_off.x, 0, p_off.y))
	st.set_uv(Vector2(p_off.x, p_off.y) / uv_fac)
	st.add_vertex(Vector3(p_off.x, 0, p_off.y))

## Generates the collision
func generate_collision() -> void:
	# Declare variables
	collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	
	# Configure shape and assign
	shape.size = size
	collision.shape = shape
	add_child(collision)
	collision.position.y = -size.y * 0.5 
	if Engine.is_editor_hint() && expose_nodes:
		collision.set_owner(get_tree().edited_scene_root)

## Generates ambient player
func generate_ambience() -> void:
	# Abort if no ambience defined
	if !ambience:
		return
	
	# Create stream
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = ambience
	audio_player.volume_db = -4
	audio_player.autoplay = true
	audio_player.unit_size = (size.x + size.z) / 2
	audio_player.bus = "Ambiance"
	add_child(audio_player)
	if Engine.is_editor_hint() && expose_nodes:
		audio_player.set_owner(get_tree().edited_scene_root)
