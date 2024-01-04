# activator_zone.gd
@tool
class_name ActivatorZone extends Area3D

'''
Renders as activated when the Player walks into it.
Can activate an EventTree directly, or contribute to an ActivatonGroup
'''

signal activated()

@export_category("ActivatorZone")
## The [EventTree] to execute, if applicable.
@export var event_tree : EventTree
## Optional [EventTree] to execute based on flag
@export var divert_trees : Dictionary
## Whether or not to execute once.
@export var one_shot : bool = true
## The size of the [ActivatorZone].
@export var size : Vector3 = Vector3.ONE * 10 :
	set(value) : size = value; if Engine.is_editor_hint(): generate()
	get : return size

## Whether or not the zone has been passed through yet.
var is_activated : bool = false

func _ready() -> void:
	# Configure self
	collision_layer = 0 # None
	collision_mask = 1 << 1 # Player
	monitorable = false
	
	# Connect signals
	body_entered.connect(zone_entered.bind())
	body_exited.connect(zone_exited.bind())

func _exit_tree() -> void:
	body_entered.disconnect(zone_entered.bind())
	body_exited.disconnect(zone_exited.bind())

func _notification(what) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if visible:
				is_activated = false

func zone_entered(body : Node3D) -> void:
	# Verify body
	if not body is Player:
		return
		
	if !is_node_ready():
		return
	
	if !is_activated:
		# Check divert
		var result = check_divert(body)
		
		# No divert, lets move on
		if !result && event_tree:
			event_tree.player = body
			event_tree.call_deferred("execute")
			
			# Disable collision
			var col = get_child(0) as CollisionShape3D
			if col:
				col.disabled = true
				
			# Wait for eventtree to finish
			await event_tree.completed
			if col:
				col.disabled = false
			
		activated.emit()
	is_activated = true

func zone_exited(body : Node3D) -> void:
	# Verify body
	if not body is Player:
		return
	
	# Set activation
	if !one_shot:
		is_activated = false


# FUNCTION
#-------------------------------------------------------------------------------

## Full generation cycle
func generate() -> void:
	# Clear children
	for child in get_children():
		child.queue_free()
	
	# Generate collision
	generate_col()

## Generates the collision shape.
func generate_col() -> void:
	# Declare variables
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	
	# Configure shape
	shape.size = size
	col.shape = shape
	
	# Add to self
	add_child(col)
	col.set_owner(get_tree().edited_scene_root if Engine.is_editor_hint() else get_parent())

## Goes through diversion trees and checks if their condition is true.
func check_divert(player : Player) -> bool:
	# Get level info
	var lm := get_tree().get_first_node_in_group("LevelManager") as LevelManager
	var l_dat := lm.level.data
	
	for key in divert_trees.keys():
		if l_dat.flags[key] == true:
			# Get node from path and execute
			var path = divert_trees[key]
			var tree = get_node_or_null(path) as EventTree
			if !tree:
				continue
			tree.player = player
			tree.execute()
			return true
	return false
