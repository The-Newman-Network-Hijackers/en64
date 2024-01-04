# trampoline.gd
@tool
class_name Trampoline extends Entity

'''
Trampoline object.
'''

## Type of trampoline
enum BounceTypes {
	SMALL,
	MEDIUM,
	LARGE
}
## BounceTypes equivalent heights
const HEIGHTS = [
	35,
	55,
	75
]

@export_category("Trampoline")
## The type of mushroom/trampoline.
@export var type : BounceTypes = BounceTypes.MEDIUM
## @DEBUG | Generates trampoline.
@export var debug_generate : bool :
	set(_value) : debug_generate = false; generate_trampoline()
	get : return debug_generate

## Reference to animation player
@onready var anim : AnimationPlayer = $anim
## Reference to player detector
@onready var p_det : Area3D = $player_detector
## Reference to boing sound effect
@onready var boing : AudioStreamPlayer3D = $boing
## Reference to stretch sound effect
@onready var stretch : AudioStreamPlayer3D = $stretch

## Reference to face material
var mat_face : Material
## Reference to cap material
var mat_cap : Material
## Reference to player
var player : Player
## Various materials.
var _t_mat : Array

## Whether or not the trampoline is animating
var is_active : bool = false
## Whether or not the player is on top of the trampoline
var player_touched : bool = false
## Whether or not the player is ground pounding
var player_gp : bool = false
## The strength co-eff of the bounce
var str_coeff : float = 0.0

func _ready() -> void:
	# Generate trampoline
	generate_trampoline()

# FUNCTION
#-------------------------------------------------------------------------------

func generate_trampoline() -> void:
	# Load face textures into memory
	_t_mat.resize(7)
	_t_mat[0] = load("res://asset/entity/trampoline/mat/vtx_face1.tres")
	_t_mat[1] = load("res://asset/entity/trampoline/mat/vtx_face2.tres")
	_t_mat[2] = load("res://asset/entity/trampoline/mat/vtx_face3.tres")
	_t_mat[3] = load("res://asset/entity/trampoline/mat/vtx_face4.tres")
	_t_mat[4] = load("res://asset/entity/trampoline/mat/vtx_cap1.tres")
	_t_mat[5] = load("res://asset/entity/trampoline/mat/vtx_cap2.tres")
	_t_mat[6] = load("res://asset/entity/trampoline/mat/vtx_cap3.tres")
	
	# Ensure references
	boing = get_node("boing")
	
	# Duplicate materials
	mat_cap = $mushroom/cap.mesh.get("surface_0/material")
	mat_face = $mushroom/stem.mesh.get("surface_1/material")
	
	# Generate based on type
	match type:
		BounceTypes.SMALL:
			# Set visuals
			mat_cap = _t_mat[4]
			mat_face = _t_mat[0]
			boing.pitch_scale = 1.3
		BounceTypes.MEDIUM:
			# Set visuals
			mat_cap = _t_mat[5]
			mat_face = _t_mat[1]
			boing.pitch_scale = 1
		BounceTypes.LARGE:
			# Set visuals
			mat_cap = _t_mat[6]
			mat_face = _t_mat[2]
			boing.pitch_scale = .7
	
	$mushroom/cap.set("surface_material_override/0", mat_cap)
	$mushroom/stem.set("surface_material_override/1", mat_face)

## Swaps the face of the trampoline.
func switch_face(id : int = type) -> void:
	$mushroom/stem.set("surface_material_override/1", _t_mat[id])
