# player_visual_manager.gd
class_name PlayerVisualManager extends Node

'''
Manages the loading of Player accessories.
'''

const FLAG_HEAD = 1 << 0
const FLAG_FACE = 1 << 1
const FLAG_BODY = 1 << 2

const MAX_OUTFIT = 24

## The default save path for costume thumbnails
const THUMB_PATH = "user://thumb/"

enum Faces {
	Neutral = 0,
	N_Left = 1,
	N_Right = 2,
	Scowl = 3,
	Dead = 4,
	Closed = 5
}

## Accessory LUT
const _acc_lut = [
	preload("res://data/accessory/body/suit.tres"),					# 0  - Suit
	preload("res://data/accessory/face/glasses.tres"),				# 1  - Glasses
	preload("res://data/accessory/face/mustache.tres"),				# 2  - Mustache
	preload("res://data/accessory/face/old_mustache.tres"),			# 3  - Old Mustache
	preload("res://data/accessory/face/sunflower_glasses.tres"),	# 4  - Sunflower Glasses
	preload("res://data/accessory/head/beanie.tres"),				# 5  - Beanie
	preload("res://data/accessory/head/cap.tres"),					# 6  - Cap
	preload("res://data/accessory/head/cowboy_hat.tres"),			# 7  - Cowboy Hat
	preload("res://data/accessory/head/fungus.tres"),				# 8  - Fungus
	preload("res://data/accessory/head/propeller.tres"),			# 9  - Propeller
	preload("res://data/accessory/head/stem.tres"),					# 10 - Stem
	preload("res://data/accessory/body/knight_armor.tres"),			# 11 - Knight Armor
	preload("res://data/accessory/head/knight_helmet.tres"),		# 12 - Knight Helmet
]

## Palette LUT
const _pal_lut = [
	Color("#343440"), # 0  - Black
	Color("#70646f"), # 1  - Dark Grey
	Color("#e2cabe"), # 2  - Light Grey
	Color("#fff8e6"), # 3  - White
	Color("#ff8588"), # 4  - Red
	Color("#ffc78d"), # 5  - Orange
	Color("#fff8a7"), # 6  - Yellow
	Color("#88b68b"), # 7  - Dark Green
	Color("#afff88"), # 8  - Green
	Color("#d8ff80"), # 9  - Lime Green
	Color("#aba2f4"), # 10 - Purple
	Color("#a5d2f3"), # 11 - Blue
	Color("#adf0e4"), # 12 - Teal
	Color("#f1ff9b"), # 13 - Brown
	Color("#f78ae5"), # 14 - Pink
]

@export_category("PlayerVisualManager")

@export_group("Bones")
## Reference to [Player]'s head accessory bone
@export var bone_head : BoneAttachment3D
## Reference to [Player]'s face accessory bone
@export var bone_face : BoneAttachment3D
## Reference to [Player]'s skeleton
@export var skeleton : Skeleton3D

@export_group("Mesh")
## Reference to [Player]'s skin mesh
@export var mesh_skin : MeshInstance3D
## Reference to [Player]'s body/outfit mesh
@export var mesh_body : MeshInstance3D
## Reference to [Player]'s face mesh
@export var mesh_face : MeshInstance3D
## Reference to [Player]'s body material
@export var material_body : ShaderMaterial
## Reference to primary accessory material
@export var material_acc_primary : ShaderMaterial = preload("res://asset/accessory/mat/vtx_acc_primary.tres")
## Reference to secondary accessory material
@export var material_acc_secondary : ShaderMaterial = preload("res://asset/accessory/mat/vtx_acc_secondary.tres")

## The [Player]'s [PlayerData]
@onready var player_data : PlayerData = PlayerDataManager.load_data()
## The [Player]'s face textures
@onready var _t_face = [
	preload("res://asset/newman/eyes_neutral.png"), # 0 - Neutral
	preload("res://asset/newman/eyes_left.png"),	# 1 - N_Left
	preload("res://asset/newman/eyes_right.png"),	# 2 - N_Right
	preload("res://asset/newman/eyes_scowl.png"),	# 3 - Scowl
	preload("res://asset/newman/eyes_dead.png"),	# 4 - Dead
	preload("res://asset/newman/eyes_closed.png"),	# 5 - Closed
]

## The [Player]'s current body accessory
var body_accessory_ref : MeshInstance3D

func _ready() -> void:
	load_outfit()

# OUTFIT FUNCTION
#-------------------------------------------------------------------------------

## Loads outfit based on [PlayerData]
func load_outfit() -> void:
	# Clear current accessories
	clear_children(bone_head)
	clear_children(bone_face)
	if body_accessory_ref:
		body_accessory_ref.queue_free()
		body_accessory_ref = null

	# Set Newman color
	var n_material : ShaderMaterial = material_body.duplicate()
	n_material.set("shader_parameter/modulate_color", _pal_lut[player_data.accessories.color1])
	mesh_skin.material_override = n_material
	
	# Set Primary and Secondary color
	material_acc_primary.set("shader_parameter/modulate_color", _pal_lut[player_data.accessories.color2])
	material_acc_secondary.set("shader_parameter/modulate_color", _pal_lut[player_data.accessories.color3])

	# Create and position head accessory
	var head_accessory = player_data.accessories.head
	if head_accessory:
		bone_head.add_child(generate_model(head_accessory))

	# Create and position face accessory
	var face_accessory = player_data.accessories.face
	if face_accessory:
		bone_face.add_child(generate_model(face_accessory))

	# Create and position body accessory
	var body_accessory = player_data.accessories.torso
	mesh_body.visible = true
	if body_accessory:
		mesh_body.visible = false
		body_accessory_ref = generate_model(body_accessory)
		skeleton.add_child(body_accessory_ref)

## Saves current outfit to a data store.
func save_costume(oname : String = "Some kind of costume") -> void:
	# Verify that limit has not been reached
	if player_data.costumes["count"] >= MAX_OUTFIT:
		return
	
	# Create a copy of current accessories
	var accessories = player_data.accessories.duplicate()
	
	# Create new dictionary
	var dict := {
		player_data.costumes["count"] : {
			"id" : player_data.costumes["count"],
			"name" : oname,
			"outfit" : accessories
	}}
	player_data.costumes["count"] += 1
	
	# Merge dictionaries
	player_data.costumes.merge(dict)
	
	# Save
	save_data()

## Removes an existing outfit from the data store
func remove_costume(id : int) -> void:
	# Verify outfit exists at id
	if !player_data.costumes.has(id):
		return
	
	# Rebuild dict
	var d_new := {
		"count" : player_data.costumes["count"] - 1
	}
	var index := 0
	for dict in player_data.costumes.values():
		if not dict is Dictionary:
			continue
		if dict.id == id:
			continue
		d_new[index] = dict
		dict.id = index
		index += 1
	
	# Set dict
	player_data.costumes = d_new
	
	# Save data
	save_data()

## Equips a costume from the data store
func equip_costume(id : int) -> void:
	# Verify outfit exists at id
	if !player_data.costumes.has(id):
		return
	
	# Copy over data from costume to accessory
	var c_dat = player_data.costumes.get(id, null) as Dictionary
	assert(c_dat != null)
	
	for key in player_data.accessories:
		player_data.accessories[key] = c_dat["outfit"][key]

## Sets the outfit in [PlayerData]
func set_outfit(key : String, data : AccessoryData) -> void:
	# Error catching
	assert(player_data.accessories.has(key))

	# Set key to data and save
	player_data.accessories[key] = data

## Sets the color in [PlayerData]
func set_color(category : int, id : int) -> void:
	# Error catching
	assert(id > -1 && id < 16)

	# Set key to data and save
	player_data.accessories[color_category_to_str(category)] = id

## Returns string equivalent of color category.
func color_category_to_str(category : int) -> String:
	match category:
		0:			return "color1"
		1:			return "color2"
		2:			return "color3"
	return ""

## Creates and returns a model.
func generate_model(accessory : AccessoryData) -> MeshInstance3D:
	# Create mesh
	var model = MeshInstance3D.new()
	model.mesh = accessory.model
	model.name = accessory.name.to_lower().replace(" ", "_")

	# Add offset
	model.position = accessory.offset

	# Set layers
	model.layers = 1 << 1
	
	# Set color
	var am_1 = accessory.primary_material as ShaderMaterial
	var am_2 = accessory.secondary_material as ShaderMaterial
	
	if am_1:
		am_1 = am_1.duplicate()
		model.set_surface_override_material(accessory.primary_surface, am_1)
		am_1.set_shader_parameter("modulate_color", _pal_lut[player_data.accessories.color2])
	if am_2:
		am_2 = am_2.duplicate()
		model.set_surface_override_material(accessory.secondary_surface, am_2)
		am_2.set_shader_parameter("modulate_color", _pal_lut[player_data.accessories.color3])

	# Return
	return model

# FACE FUNCTION
#-------------------------------------------------------------------------------

## Sets the face texture of [Player].
func set_face(id : int) -> void:
	# Get face material
	var face_material = mesh_face.mesh.surface_get_material(0)
	var d_mat : ShaderMaterial = face_material.duplicate()
	
	# Set albedo and apply
	d_mat.set("shader_parameter/albedoTex", _t_face[id])
	mesh_face.material_override = d_mat

# MISC FUNCTION
#-------------------------------------------------------------------------------

## Saves outfit to [PlayerData]
func save_data() -> void:
	PlayerDataManager.save_data(player_data)

## Saves image data to THUMB_PATH
func save_thumbnail(image : Image) -> String:
	# Ensure path exists
	if !DirAccess.dir_exists_absolute(THUMB_PATH):
		DirAccess.make_dir_absolute(THUMB_PATH)
	
	# Create new file
	image.save_png(THUMB_PATH + str(player_data.costumes.count) + ".png")
	return THUMB_PATH + str(player_data.costumes.count) + ".png"
		
## Clears the children of a node
func clear_children(node : Node) -> void:
	for child in node.get_children():
		child.queue_free()
