# big_door.gd
@tool
class_name BigDoor extends Node3D

'''
Generates a big door that can be opened and closed.
'''

enum Types {
	Single,
	Double
}

signal door_opened()
signal door_closed()

@export_category("BigDoor")
## The type of door to generate.
@export var type : Types = Types.Single

@export_group("Door")
## The size of the door.
@export var size : Vector2 = Vector2(5, 7)
## The uv size of the door
@export var uv_fac : float = 4.0
## The material used for the door
@export var material : Material

@export_subgroup("Handles")
## Whether to generate handles or not
@export var handles : bool = false
## Mesh to use for handles
@export var handles_mesh : Mesh = preload("res://asset/entity/bigdoor/handle_lowpoly.tres")
## Material to use for handles
@export var handles_material : Material = preload("res://asset/entity/bigdoor/vtx_handle.tres")

@export_group("Animation")
## How fast to open the door
@export var anim_length : float = 1
## Type of tweening transition to use
@export var transition : Tween.TransitionType = Tween.TransitionType.TRANS_SINE
## Type of tweening ease to use
@export var easing : Tween.EaseType = Tween.EaseType.EASE_IN

@export_group("Sound")
## Sound to play when the door is moving
@export var stream_moving : AudioStream
## Sound to play when the door is closed
@export var stream_closed : AudioStream
## Amount of delay before the close sound plays
@export var close_delay : float = 1.5

@export_group("")
## Generates the door.
@export var generate : bool = false :
	set(_value) : generate = false; if is_node_ready(): generate_door()
	get : return generate
## @DEBUG | Toggles the door opening sequence
@export var debug_open : bool = false :
	set(_value) : debug_open = false; if is_node_ready(): open_door()
	get : return debug_open
## @DEBUG | Toggles the door closing sequence
@export var debug_close : bool = false :
	set(_value) : debug_close = false; if is_node_ready(): close_door()
	get : return debug_close

## Current set of meshes.
var meshes : Array = []
## Current reference to moving audio
var sfx_moving : AudioStreamPlayer3D
## Current reference to closed audio
var sfx_closed : AudioStreamPlayer3D
## Timer associated with closing player
var timer_closed : Timer
## Whether the door is open or not.
var open : bool = false

func _ready() -> void:
	generate_door()

# FUNCTION
#-------------------------------------------------------------------------------

func generate_door() -> void:
	# Clear data
	for child in get_children():
		child.queue_free()
	meshes.clear()
	sfx_moving = null
	sfx_closed = null
	timer_closed = null
	
	# Generate meshes
	generate_mesh()
	generate_collision()
	generate_handles()
	generate_audio()
	
	# Set ownership of self
	self.set_owner(get_tree().edited_scene_root if Engine.is_editor_hint() else get_tree().current_scene)

func generate_mesh() -> void:
	# Handle creating actual doors first
	match type:
		Types.Single:
			# Create mesh(es)
			var mesh1 = MeshInstance3D.new()
			add_child(mesh1)
			mesh1.set_owner(self)
			meshes.append(mesh1)
			
			# Create mesh data
			var door1 = ArrayMesh.new()
			door1.add_surface_from_arrays(
				Mesh.PRIMITIVE_TRIANGLES,
				generate_points(size, Vector2(-size.x / 2, 0))
			)
			
			# Apply to instance nodes
			mesh1.material_override = material
			mesh1.mesh = door1
			
		Types.Double:
			# Create mesh(es)
			var mesh1 = MeshInstance3D.new()
			var mesh2 = MeshInstance3D.new()
			add_child(mesh1)
			add_child(mesh2)
			mesh1.set_owner(self)
			mesh2.set_owner(self)
			meshes.append(mesh1)
			meshes.append(mesh2)
			
			# Create mesh data
			var door1 = ArrayMesh.new()
			var door2 = ArrayMesh.new()
			door1.add_surface_from_arrays(
				Mesh.PRIMITIVE_TRIANGLES,
				generate_points(Vector2(size.x / 2, size.y), Vector2(-size.x / 2, 0))
			)
			door2.add_surface_from_arrays(
				Mesh.PRIMITIVE_TRIANGLES,
				generate_points(Vector2(size.x / 2, size.y), Vector2(0, 0))
			)
			
			# Apply to instance nodes
			mesh1.material_override = material
			mesh2.material_override = material
			mesh1.mesh = door1
			mesh2.mesh = door2
			
			# Move nodes around
			mesh1.position.x = size.x / 2
			mesh2.position.x = -size.x / 2

func generate_audio() -> void:
	# Create audio players
	sfx_moving = AudioStreamPlayer3D.new()
	sfx_moving.stream = stream_moving
	sfx_moving.bus = &"Sound"
	add_child(sfx_moving)
	sfx_moving.set_owner(self)
	
	sfx_closed = AudioStreamPlayer3D.new()
	sfx_closed.stream = stream_closed
	sfx_closed.bus = &"Sound"
	add_child(sfx_closed)
	sfx_closed.set_owner(self)
	
	timer_closed = Timer.new()
	timer_closed.wait_time = close_delay
	timer_closed.one_shot = true
	add_child(timer_closed)
	timer_closed.set_owner(self)

func generate_handles() -> void:
	if !handles:
		return
	
	match type:
		Types.Single:
			# Create handle object
			var handle1 = MeshInstance3D.new()
			handle1.mesh = handles_mesh
			handle1.material_override = handles_material
			meshes[0].add_child(handle1)
			
			# Position handle
			handle1.position = Vector3(
				size.x / 2 * 0.8,
				size.y * 0.5,
				0
			)
			handle1.rotation.x = deg_to_rad(90)
			
		Types.Double:
			# Create handle objects
			var handle1 = MeshInstance3D.new()
			handle1.mesh = handles_mesh
			handle1.material_override = handles_material
			meshes[0].add_child(handle1)
			
			var handle2 = MeshInstance3D.new()
			handle2.mesh = handles_mesh
			handle2.material_override = handles_material
			meshes[1].add_child(handle2)
			
			# Position handles
			handle1.position = Vector3(
				size.x / 2 * -0.8,
				size.y * 0.5,
				0
			)
			handle2.position = Vector3(
				size.x / 2 * 0.8,
				size.y * 0.5,
				0
			)
			handle1.rotation.x = deg_to_rad(90)
			handle2.rotation.x = deg_to_rad(90)

func generate_points(msize : Vector2 = size, offset : Vector2 = Vector2.ZERO) -> Array:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Tri 1
	st.set_normal(Vector3.FORWARD)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(0 + offset.x, 0 + offset.y, 0))
	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(0 + offset.x, msize.y + offset.y, 0))
	st.set_uv(Vector2(msize.x / uv_fac, 0))
	st.add_vertex(Vector3(msize.x + offset.x, msize.y + offset.y, 0))

	# Tri 2
	st.set_normal(Vector3.FORWARD)
	st.set_uv(Vector2(msize.x / uv_fac, 0))
	st.add_vertex(Vector3(msize.x + offset.x, msize.y + offset.y, 0))
	st.set_uv(Vector2(msize.x / uv_fac, 1))
	st.add_vertex(Vector3(msize.x + offset.x, 0 + offset.y, 0))
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(0 + offset.x, 0 + offset.y, 0))
	
	st.generate_tangents()
	
	return st.commit_to_arrays()

func generate_collision() -> void:
	for mesh in meshes:
		mesh = mesh as MeshInstance3D
		mesh.create_convex_collision()

# ANIMATION FUNCTION
#-------------------------------------------------------------------------------

func toggle_door() -> void:
	open_door() if !open else close_door()

func open_door() -> void:
	sfx_moving.play()
	open = true
	door_opened.emit()
	animate_single_door() if type == Types.Single else animate_double_door()

func close_door() -> void:
	sfx_moving.play()
	open = false
	door_closed.emit()
	animate_single_door(open) if type == Types.Single else animate_double_door(open)
	timer_closed.start()
	await timer_closed.timeout
	sfx_closed.play()

func animate_single_door(opening : bool = true) -> void:
	# Tween
	var tw = create_tween()
	tw.tween_property(
		meshes[0],
		"position:y",
		size.y if opening else 0.0,
		anim_length
	).set_trans(transition).set_ease(easing)
	tw.play()
	
func animate_double_door(opening : bool = true) -> void:
	# Tween
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(
		meshes[0],
		"rotation:y",
		deg_to_rad(135) if opening else deg_to_rad(0),
		anim_length
	).set_trans(transition).set_ease(easing).set_delay(anim_length * 0.05)
	tw.tween_property(
		meshes[1],
		"rotation:y",
		deg_to_rad(-135) if opening else deg_to_rad(0),
		anim_length
	).set_trans(transition).set_ease(easing)
	tw.play()

func test() -> void:
	print("Hello!")
