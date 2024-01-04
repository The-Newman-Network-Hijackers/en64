# jack_spawner.gd
@tool
class_name JackSpawner extends Marker3D

'''
Spawns Jacks in various formations
'''

enum Formations {
	Row,
	Column,
	Circle,
	VCircle,
}

@export_category("JackSpawner")
## The type of formation to use.
@export var formation : Formations = Formations.Row :
	set(value) : formation = value; if Engine.is_editor_hint(): request_update()
	get : return formation
## The amount of spacing between each Jack.
@export_range(3, 10) var spacing : float = 5 :
	set(value) : spacing = value; if Engine.is_editor_hint(): request_update()
	get : return spacing
## The amount of jacks to spawn
@export_range(3, 15) var count : int = 5 :
	set(value) : count = value; if Engine.is_editor_hint(): request_update()
	get : return count
## Whether or not to cast shadows.
@export var shadows : bool = true :
	set(value) : shadows = value; if Engine.is_editor_hint(): request_update()
	get : return shadows
## Whether or not to snap jacks to floor.
@export var snap_to_floor : bool = false :
	set(value) : snap_to_floor = value; if Engine.is_editor_hint(): request_update()
	get : return snap_to_floor

## Reference to [Jack] scene.
@onready var jack_scene : PackedScene = preload("res://scenes/prefab/jack.tscn")

## Whether or not we're updating right now.
var is_updating : bool = false

func _enter_tree() -> void:
	# Configure self
	gizmo_extents = 5.0
	set_meta("_edit_group_", true)
	set_notify_transform(true)

func _ready() -> void:
	# If snap, snap to floor
	if get_child_count() > 0 && snap_to_floor && Engine.is_editor_hint():
		snap_children_to_floor()
	
	# If no shadows, remove at runtime
	if Engine.is_editor_hint() || shadows:
		return
	for jack in get_children():
		jack = jack as Jack
		jack.call_deferred("remove_shadow")

func _notification(what: int) -> void:
	match what:
		CanvasItem.NOTIFICATION_TRANSFORM_CHANGED:
			if !Engine.is_editor_hint():
				return
			if !is_node_ready():
				return
			call_deferred("request_update", false)

# FUNCTION
#-------------------------------------------------------------------------------

## An update cycle.
func update(clear_jacks : bool = true) -> void:
	# Run cycle
	if clear_jacks:
		@warning_ignore("redundant_await")
		await clear_jacks()
		@warning_ignore("redundant_await")
		await spawn_jacks()

	# Snap to floor
	if snap_to_floor: snap_children_to_floor()

	# Done with update
	is_updating = false

## Requests an update.
func request_update(clear_jacks : bool = true) -> void:
	# Dont push if currently updating
	if is_updating:
		return

	# Wait if not ready
	if !is_node_ready():
		await ready

	is_updating = true
	update(clear_jacks)

## Spawns jacks based on parameters.
func spawn_jacks() -> void:
	match formation:
		Formations.Row:
			# Calculate values
			var start : float = -(spacing * (count - 1)) / 2

			for place in range(count):
				var jack = instance_jack()
				jack.position.z = start + (place * spacing)

		Formations.Column:
			# Calculate values
			var start : float = -(spacing * (count - 1)) / 2

			for place in range(count):
				var jack = instance_jack()
				jack.position.y = start + (place * spacing)

		Formations.Circle:
			# Calculate values
			var increment : float = deg_to_rad(360.0 / count)

			for place in range(count):
				var angle = increment + (increment * place)
				var target_position = Vector3.FORWARD.rotated(Vector3.UP, angle) * spacing
				var jack = instance_jack()
				jack.position = target_position

		Formations.VCircle:
			# Calculate values
			var increment : float = deg_to_rad(360.0 / count)

			for place in range(count):
				var angle = increment + (increment * place)
				var target_position = Vector3.UP.rotated(Vector3.FORWARD, angle) * spacing
				var jack = instance_jack()
				jack.position = target_position

## Clears all spawned Jacks.
func clear_jacks() -> void:
	for child in get_children():
		if not child is Jack:
			continue
		child.queue_free()

## Instances a Jack.
func instance_jack() -> Jack:
	# Create Jack
	var instance : Jack = jack_scene.instantiate(PackedScene.GEN_EDIT_STATE_MAIN_INHERITED)
	add_child(instance)

	# Remove shadow if necessary
	if !shadows and !Engine.is_editor_hint():
		instance.call_deferred("remove_shadow")

	# Configure and return
	instance.set_owner(get_tree().edited_scene_root if Engine.is_editor_hint() else get_tree().current_scene)
	instance.set_meta("_edit_lock_", true)
	return instance

## Snaps all children to floor.
func snap_children_to_floor():
	# Declare variables
	var ray_pool : Array[RayCast3D] = []

	# Iterate through children
	for child in get_children():
		# Continue if child is not Jack
		if not child is Jack:
			continue

		# Setup query
		var space = get_world_3d().direct_space_state
		var origin = Vector3(child.global_position.x, global_position.y, child.global_position.z)
		var end = origin + (Vector3.DOWN * 100)
		var query = PhysicsRayQueryParameters3D.create(origin, end, 1 << 0, [child])
		
		# Cast and apply
		var result = space.intersect_ray(query)
		if result.has("position"):
			child.global_position = result.position
