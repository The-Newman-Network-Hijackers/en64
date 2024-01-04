# button.gd
@tool
class_name ActivatorButton extends Activator

'''
Button that the player can bounce on in order to activate
'''

@export_category("ActivatorButton")

@export_group("Button")
## The amount of sides the button has. Minimum of 4 sides.
@export var sides : int = 6 :
	set(value) : sides = clamp(value, 4, 16)
	get : return sides
## The radius and height of the button
@export var size : Vector2 = Vector2(2, 1)
## The material used for the button
@export var material : Material
## Sound effect to play when pressed.
@export var stream_pressed : AudioStream = preload("res://audio/sfx/button_press.wav")

@export_group("")
## Generates the button.
@export var generate : bool = false :
	set(_value) : generate = false; generate_button()
	get : return generate
## @DEBUG | Previews the button press animation in editor
@export var debug_press : bool = false :
	set(_value) : debug_press = false; debug_preview_press()
	get : return debug_press

## Default button base material
var b_base_material : Material
## Default button top material
var button_material : Material

## Current set of meshes.
var meshes : Array[MeshInstance3D] = []
## Reference to pressed sound effect
var sfx_pressed : AudioStreamPlayer3D

## Whether or not the button is pressed
var pressed : bool = false

func _enter_tree() -> void:
	# Load materials
	b_base_material = load("uid://bhpwgl8gyvag8")
	button_material = load("uid://cgcp1y28k1ref")

func _ready() -> void:
	generate_button()

# FUNCTION
#-------------------------------------------------------------------------------

## Generates a button based on provided parameters.
func generate_button() -> void:
	# Remove existing
	for child in get_children():
		child.queue_free()
	meshes.clear()
	sfx_pressed = null
	
	# Create new
	create_meshes()
	create_collision()
	create_sound()

## Creates meshes for the button
func create_meshes() -> void:
	# Create meshes
	var button_mesh = create_cylinder(size.x, size.y, button_material if !material else material)
	var base_mesh = create_cylinder(size.x * 1.25, size.y * 0.5, b_base_material)
	
	# Create button
	meshes.append(MeshInstance3D.new())
	meshes[0].mesh = button_mesh
	add_child(meshes[0])
	meshes[0].position.y = size.y * 0.5
	
	# Create base
	meshes.append(MeshInstance3D.new())
	meshes[1].mesh = base_mesh
	add_child(meshes[1])
	meshes[1].position.y = size.y * 0.25

## Generates a cylinder based on params
func create_cylinder(radius : float, height : float, c_mat : Material) -> Mesh:
	var mesh = CylinderMesh.new()
	mesh.radial_segments = sides
	mesh.height = height
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.cap_bottom = false
	mesh.material = c_mat
	return mesh

## Creates collision based on meshes
func create_collision() -> void:
	# Create collision for button
	for mesh in meshes:
		mesh.create_convex_collision()
	
	# Create area
	var area = Hurtbox.new()
	area.scope = 1 << 2 # Entity
	add_child(area)
	area.position.y += size.y * 0.5
	area.died.connect(button_press_attempted.bind())
	
	# Create collider for area
	var a_col = CollisionShape3D.new()
	var a_shape = CylinderShape3D.new()
	a_shape.radius = size.x
	a_shape.height = size.y
	a_col.shape = a_shape
	area.add_child(a_col)

## Creates sound effects for the button
func create_sound() -> void:
	# Create sound node
	sfx_pressed = AudioStreamPlayer3D.new()
	sfx_pressed.stream = stream_pressed
	sfx_pressed.bus = &"Sound"
	sfx_pressed.unit_size = 50
	add_child(sfx_pressed)

# BUTTON INTERACTION FUNCTION
#-------------------------------------------------------------------------------

## Runs when area is destroyed.
func button_press_attempted(_value : int, _junk := {}) -> void:
	# Activate
	if !pressed:
		press_button()

## Animates the button being pressed.
func press_button() -> void:
	# Set value
	pressed = true
	
	# Animate
	sfx_pressed.play()
	var tw = create_tween()
	tw.tween_property(meshes[0], "position:y", size.y * 0.15, .75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	# Call signal
	activated.emit()

## Previews press animation in the editor.
func debug_preview_press() -> void:
	# SFX
	sfx_pressed.play()
	
	# Animate
	var tw = create_tween()
	tw.tween_property(meshes[0], "position:y", size.y * 0.15, .75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_property(meshes[0], "position:y", size.y * 0.5, .75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_delay(1)

