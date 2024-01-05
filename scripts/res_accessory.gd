# res_accessory.gd
class_name AccessoryData extends Resource

'''
Holds various data related to Player accessories.
'''

@export_category("AccessoryData")
## The type of accessory.
@export_flags("Head", "Face", "Torso") var type : int = 1
## The model of the accessory.
@export var model : Mesh
## The offset of the accessory.
@export var offset : Vector3 = Vector3.UP

@export_group("ColorManagement")
## Primary color material to modify
@export var primary_material : ShaderMaterial
## Primary surface material ID to overwrite
@export var primary_surface : int = 0
## Secondary color material to modify
@export var secondary_material : ShaderMaterial
## Secondary surface material ID to overwrite
@export var secondary_surface : int = 1

@export_group("Info")
## The name of the accessory.
@export var name : String = "Default"
## The description of the accessory.
@export_multiline var description : String = "Default"
## The icon of the accessory.
@export var icon : Texture2D
## The modulation of the icon.
@export var icon_modulation : Color = Color.WHITE
