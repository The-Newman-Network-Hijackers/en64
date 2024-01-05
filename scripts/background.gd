# background.gd
@tool
class_name Background extends CanvasLayer

'''
Generates a background viewport based on provided parameters.
'''

enum Types {
	_512x512,
	_1024x512,
}

const TYPE_COEFF = [
	2,
	1
]

@export_category("Background")
## The material to use for the background
@export var bg_material : Material
## The type of background.
@export var type : Types = Types._512x512
## @debug | Generates background when pressed.
@export var generate : bool = false :
	set(_value) : generate = false; generate_background()
	get : return generate

## The viewport environment.
var vp_env : Environment
## The camera properties resource
var vp_cap : CameraAttributesPractical
## Reference to viewport container
var viewport_container : SubViewportContainer
## Reference to viewport
var viewport : SubViewport
## Reference to mesh node
var bg_mesh : MeshInstance3D
## Reference to camera
var bg_cam : BackgroundCam

func _enter_tree() -> void:
	# Load resources
	vp_env = load("res://asset/environment/env_bg.tres")
	vp_cap = load("res://asset/environment/cap_bg.tres")
	
	# Configure self
	layer = -128
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	# Set visibility to owner visibility
	visible = get_parent().visible

# FUNCTION
#-------------------------------------------------------------------------------

func generate_background() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()
	
	# Generate
	generate_viewport()
	generate_mesh()
	generate_camera()

func generate_viewport() -> void:
	# Generate container first
	viewport_container = SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	add_child(viewport_container)
	
	# Generate viewport next
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.handle_input_locally = false
	viewport_container.add_child(viewport)
	
	if Engine.is_editor_hint():
		viewport_container.set_owner(get_tree().edited_scene_root)
		viewport.set_owner(get_tree().edited_scene_root)
	else:
		viewport_container.set_owner(get_tree().current_scene)
		viewport.set_owner(get_tree().current_scene)

func generate_mesh() -> void:
	# Create nodes
	bg_mesh = MeshInstance3D.new()
	var bg_mdat := ArrayMesh.new()
	var st := SurfaceTool.new()
	
	# Configure
	bg_mesh.mesh = bg_mdat
	bg_mesh.material_overlay = bg_material 
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Tri 1
	st.set_uv(Vector2(-TYPE_COEFF[type], -1))
	st.add_vertex(Vector3(-2, TYPE_COEFF[type] * 0.5, 0))
	st.set_uv(Vector2(TYPE_COEFF[type], -1))
	st.add_vertex(Vector3(2, TYPE_COEFF[type] * 0.5, 0))
	st.set_uv(Vector2(-TYPE_COEFF[type], 0))
	st.add_vertex(Vector3(-2, -TYPE_COEFF[type] * 0.5, 0))
	
	# Tri 2
	st.set_uv(Vector2(TYPE_COEFF[type], -1))
	st.add_vertex(Vector3(2, TYPE_COEFF[type] * 0.5, 0))
	st.set_uv(Vector2(TYPE_COEFF[type], 0))
	st.add_vertex(Vector3(2, -TYPE_COEFF[type] * 0.5, 0))
	st.set_uv(Vector2(-TYPE_COEFF[type], 0))
	st.add_vertex(Vector3(-2, -TYPE_COEFF[type] * 0.5, 0))
	
	bg_mdat.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	viewport.add_child(bg_mesh)
	
	if Engine.is_editor_hint():
		bg_mesh.set_owner(get_tree().edited_scene_root)
	else:
		bg_mesh.set_owner(get_tree().current_scene)

func generate_camera() -> void:
	bg_cam = BackgroundCam.new()
	bg_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	bg_cam.size = 0.7
	bg_cam.position.z = 0.1
	bg_cam.environment = vp_env
	bg_cam.attributes = vp_cap
	viewport.add_child(bg_cam)
	
	if Engine.is_editor_hint():
		bg_cam.set_owner(get_tree().edited_scene_root)
	else:
		bg_cam.set_owner(get_tree().current_scene)
