# player_equipment_manager.gd
class_name PlayerEquipmentManager extends Node

'''
Manages swapping in and out various equipment the Player uses.
'''

## Fired when equipment is requested (usually by Player)
signal evoke_equipment(msg : Dictionary)
## Fired when equipment is changed
signal equipment_changed(hatch : Array, equip : int)

## References to equipment nodes
const EQUIPMENT = [
	preload("res://scenes/prefab/player_equipment_glove.tscn")
]

## Hatch constants
const NONE = -1
const UP = 0
const LEFT = 1
const DOWN = 2
const RIGHT = 3

## Bone to attach items to
@onready var item_bone := owner.get_node("visual/newman/skeleton/item_follow")

## Current hatch layout
var current_hatch = [
	PlayerData.EQUIPMENT.GLOVE,
	PlayerData.EQUIPMENT.NONE,
	PlayerData.EQUIPMENT.NONE,
	PlayerData.EQUIPMENT.NONE
]
## Reference to current equipment
var current_equipment : EquipmentStateMachine
## Reference to current equipment ID
var current_equipment_id : int = PlayerData.EQUIPMENT.NONE
## Current position on hatch.
var current_hatch_pos : int = -1
## Whether or not you can currently switch equipment
var can_switch_equipment : bool = true

func _ready() -> void:
	# Connect signals
	evoke_equipment.connect(equipment_evoked.bind())

func _unhandled_input(_event : InputEvent) -> void:
	if !can_switch_equipment:
		return
	
	if _event is InputEventJoypadButton:
		if !Input.is_action_pressed("equipment_modifier"):
			return
		get_tree().root.set_input_as_handled()
	
	if _event.is_action_pressed("equipment_up"):
		change_equipment(current_hatch[0])
		change_hatch_selection(0)
	elif _event.is_action_pressed("equipment_left"):
		change_equipment(current_hatch[1])
		change_hatch_selection(1)
	elif _event.is_action_pressed("equipment_down"):
		change_equipment(current_hatch[2])
		change_hatch_selection(2)
	elif _event.is_action_pressed("equipment_right"):	
		change_equipment(current_hatch[3])
		change_hatch_selection(3)
		

# FUNCTION
#-------------------------------------------------------------------------------

## Loads a new piece of equipment in place of the current one.
func change_equipment(id : int) -> void:
	# Clear current
	var ce_name = ""
	if is_instance_valid(current_equipment):
		ce_name = current_equipment.name
		current_equipment.queue_free()
	
	# Abort if ID is -1
	if id == -1:
		current_equipment_id = -1
		return
	
		# Abort if equipment is same
	var new_equip = equipment_from_id(id).instantiate() as EquipmentStateMachine
	if ce_name == new_equip.name:
		new_equip.queue_free()
		current_equipment = null
		current_equipment_id = -1
		return
	
	# Load new equipment from ID
	current_equipment = new_equip
	current_equipment.player = owner as Player
	add_child(current_equipment)
	current_equipment.owner = get_parent()
	current_equipment_id = id
	
	# Print
	print("Changed equipment, ", current_equipment.name)

## Changes the hatch selection variable
func change_hatch_selection(id : int) -> void:
	# If ID is the same, set to none
	if id == current_hatch_pos:
		current_hatch_pos = -1
		equipment_changed.emit(current_hatch, current_hatch_pos)
		return
	current_hatch_pos = id
	equipment_changed.emit(current_hatch, current_hatch_pos)

## Verifies if a transition can take place based on equipment whitelist
func can_transition(state : String) -> bool:
	# Check if no equipment
	if !current_equipment:
		return false
	
	# Convert state into flag
	var flag : int
	match state:
		"idle":						flag = 1 << 0
		"move":						flag = 1 << 1
		["jump", "airborne"]:		flag = 1 << 2
		_:							flag = -1
	
	# Compare flag to whitelist
	if (current_equipment.whitelist & flag) == flag:
		return true
	return false

## Ran in-tandem when evoke_equipment is emitted
func equipment_evoked(msg : Dictionary) -> void:
	# Check if equipment exists
	if !current_equipment:
		return
	
	current_equipment.transition_state("interact_router", msg)

## Converts ID into PackedScene
func equipment_from_id(id : int) -> PackedScene:
	match id:
		1 << 0:		return EQUIPMENT[0]
		_:			return null
