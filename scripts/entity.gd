# entity.gd
class_name Entity extends CharacterBody3D

'''
Base class for all physics entities
'''

@export_category("Entity")

## The name of the [Entity].
@export var e_name : String = "Entity"
## Whether or not the [Entity] can respawn.
@export var respawn : bool = false
## Hurtbox component of the [Entity].
@export var hurtbox_node : Hurtbox 
## The visual component of the [Entity], used in rotations
@export var visual_node : Node3D
## The floor raycast component of the [Entity], used for determining
## normal based rotations.
@export var floor_raycast : RayCast3D
## AnimationTree component of the [Entity].
@export var anim_tree : AnimationTree

@export_subgroup("Movement")
## Movement speed of the [Entity].
@export var move_speed : float = 30.0
## How fast an [Entity] reaches [move_speed] velocity. [0.0 - 1.0]
@export var acceleration : float = 65
## How fast an [Entity] reaches zero velocity. [0.0 - 1.0]
@export var deacceleration : float = 80
## The maximum amount of forward speed this entity can reach.
@export var max_speed : float = 100.0

@export_subgroup("Jump")
## The jump height of the [Entity].
@export var jump_height : float = 10.0
## The amount of time it takes to reach the peak of the jump.
@export var jtt_peak : float = 0.35
## The amount of time it takes to descend after a jump.
@export var jtt_descent : float = 0.25
## The maximum terminal velocity the [Entity] can reach.
@export var terminal_velocity : float = 150.0

## Jump calculations
@onready var jump_velocity : float = (2.0 * jump_height) / jtt_peak
@onready var jump_gravity : float = (-2.0 * jump_height) / pow(jtt_peak, 2)
@onready var fall_gravity : float = (-2.0 * jump_height) / (jtt_descent * jtt_descent)
## Intended rotation value, replicated to visual
@onready var vis_rotation : Vector3 = visual_node.global_rotation

## Origin/Spawn point
@onready var spawn : Vector3 = global_position

## The intended movement direction
var input_direction : Vector3 = Vector3.ZERO
## The speed to push [Entity] forward and back with
var forward_speed : float = 0.0
## The speed to push [Entity] sideways with
var side_speed : float = 0.0

## Determines if the [Entity] is currently jumping.
var jumping : bool = false
## The current friction of the [Entity]
var friction : float = 1.0

# FUNCTION
#-------------------------------------------------------------------------------

## Updates [Entity]'s physics.
func update_movement(delta : float, rot : bool = true) -> void:
	# Declare variables
	var i_speed_rotated = (Vector3.FORWARD * -min(forward_speed, max_speed)).rotated(Vector3.UP, vis_rotation.y if rot else visual_node.rotation.y)

	# Calculate total speed
	velocity.x = i_speed_rotated.x
	velocity.z = i_speed_rotated.z

	# Calculate gravity
	if !is_on_floor():
		velocity.y = max(velocity.y + i_speed_rotated.y + get_gravity() * delta, -terminal_velocity)

	# Move
	move_and_slide()

## Updates [Entity]'s physics and returns collision data.
func update_collide(delta : float, rot : bool = true) -> KinematicCollision3D:
	# Declare variables
	var i_speed_rotated = (Vector3.FORWARD * -min(forward_speed, max_speed)).rotated(Vector3.UP, vis_rotation.y if rot else visual_node.rotation.y)

	# Calculate total speed
	velocity.x = i_speed_rotated.x
	velocity.z = i_speed_rotated.z
	
	# Update friction
	friction = get_friction(get_terrain())

	# Calculate gravity
	if !is_on_floor():
		velocity.y = max(velocity.y + i_speed_rotated.y + get_gravity() * delta, -terminal_velocity)

	# Move
	return move_and_collide(velocity * delta)

## Updates [Entity] rotation visuals using interpolation.
func update_visual(_delta : float, spd : float = 0.1) -> void:
	# Get a look direction
	var look_direction = vis_rotation.y

	# Interpolate towards direction
	visual_node.rotation.y = lerp_angle(
		visual_node.rotation.y,
		look_direction,
		spd
	)

	# Additional calculations
	update_normal_rotation()

## Calculates [Entity] slope speed.
func update_slope(_delta : float, augment : float = 1.0) -> void:
	# Declare variables
	var normal = floor_raycast.get_collision_normal()
	var resistance = get_resistance(get_terrain())

	# Check to see if floor is steep
	if normal and is_on_floor():
		# Get direction, comparison and magnitude of slope
		var slope_dir = get_normal_direction(normal)
		var comparison = visual_node.basis.z.dot(slope_dir)
		var magnitude = sqrt(pow(normal.x, 2) + pow(normal.z, 2))

		# Check if magnitude is steep enough
		if magnitude < 0.1:
			return

		# Apply slope force if going down slope
		if comparison < 0.05:
			forward_speed = forward_speed - (magnitude * resistance * augment) * _delta
		elif comparison >= 0.05:
			forward_speed = forward_speed + ((1 + magnitude) * (65 + (15 / friction)) * augment) * _delta
			input_direction.x = lerpf(input_direction.x, slope_dir.x, 0.7)
			input_direction.z = lerpf(input_direction.z, slope_dir.z, 0.7)

	# Increase snapping and rotate velocity
	floor_snap_length = max(1.0, 1.0 + forward_speed / 8)
	velocity = velocity - velocity.project(normal)

## Returns the current gravity of the [Entity].
func get_gravity() -> float:
	return jump_gravity if velocity.y > 0 and jumping else fall_gravity

## Eases a value towards a target based on provided increment.
func ease_value(value : float, target : float, increment : float, delta : float) -> float:
	# Stop if values are equal
	if is_equal_approx(value, target):
		return target

	# Declare variable
	var new_value : float = value
	var d_inc : float = increment * delta

	# Do first comparison passthrough
	if value <= target:
		new_value += d_inc
	else:
		new_value -= d_inc

	# Check if new value is approximately target
	if new_value >= target - d_inc * .97 && new_value <= target + d_inc * .97:
		new_value = target

	# Return new value
	return new_value

## Eases a vector towards a target based on provided increment
func ease_vector(value : Vector3, target : Vector3, increment : float, delta : float) -> Vector3:
	# Declare variable
	var new_value : Vector3 = value

	# Iterate over values and ease
	for i in range(3):
		new_value[i] = ease_value(value[i], target[i], increment, delta)

	# Return new value
	return new_value

# NORMAL / ANGLE FUNCTION
#-------------------------------------------------------------------------------

## Rotates the [Entity] along the current normal.
func update_normal_rotation(from_ray : bool = true) -> void:
	# Check if we're moving at all
	if velocity.length() < 0.1:
		return
	
	# Calculate floor normal rotation
	var target_transform : Transform3D
	if is_on_floor():
		var normal = floor_raycast.get_collision_normal() if from_ray && floor_raycast else get_floor_normal()
		target_transform = align_to_normal(visual_node.global_transform, normal)
	else:
		target_transform = align_to_normal(visual_node.global_transform, Vector3.UP)

	# Interpolate to normal
	visual_node.global_transform = visual_node.global_transform.interpolate_with(target_transform, 0.15)

## Returns whether or not an angle is too steep
func angle_is_steep(normal : Vector3) -> bool:
	var angle = abs(normal.dot(Vector3.UP))
	var margin = get_steep_margin(get_terrain())
	if angle < margin:
		return true
	return false

## Returns the angle of a slope based on normal.
func angle_from_normal(normal : Vector3) -> float:
	return Vector2(
		normal.z,
		normal.x
	).angle()

## Gets the direction of a normal
func get_normal_direction(normal : Vector3) -> Vector3:
	var r = normal.cross(Vector3.DOWN)
	r = r.cross(normal)
	return Vector3(r.x, 0, r.z)

## Aligns transform with a surface normal
func align_to_normal(xform : Transform3D, normal : Vector3) -> Transform3D:
	xform.basis.y = normal
	xform.basis.x = normal.cross(xform.basis.z)
	xform.basis.z = xform.basis.x.cross(normal)
	xform.basis = xform.basis.orthonormalized()
	return xform

## Looks at a desired node.
func look_at_node(node : Node3D) -> void:
	var apos := self.global_position.direction_to(node.global_position) as Vector3
	var angle := atan2(apos.x, apos.z) as float
	vis_rotation.y = angle

# TERRAIN FUNCTION
#-------------------------------------------------------------------------------

## Gets the current terrain type from floor
func get_terrain() -> int:
	# Get collider
	var hit = floor_raycast.get_collider()
	if hit and hit is Terrain:
		return hit.surface_type

	# If theres no collider, return default
	return 0

## Gets the current terrain audio type from floor
func get_terrain_audio() -> int:
	# Get collider
	var hit = floor_raycast.get_collider()
	if hit and hit is Terrain:
		return hit.audio_type
		
	# If theres no collider, return default
	return 0

## Gets the current friction from floor
func get_friction(type : int) -> float:
	var t = Terrain.new()
	match type:
		t.SurfaceType.DEFAULT:
			t.queue_free()
			return 0.8
		t.SurfaceType.NO_SLIP:
			t.queue_free()
			return 1.0
		t.SurfaceType.SLIPPERY:
			t.queue_free()
			return .5
		_:
			t.queue_free()
			return 0.8

## Gets the current resistance from floor
func get_resistance(type : int) -> float:
	var t = Terrain.new()
	match type:
		t.SurfaceType.NO_SLIP:
			t.queue_free()
			return 10.0
		t.SurfaceType.SLIPPERY:
			t.queue_free()
			return 100.0
		_:
			t.queue_free()
			return 70.0

## Gets the current steepness margin from floor
func get_steep_margin(type : int) -> float:
	var t = Terrain.new()
	match type:
		t.SurfaceType.NO_SLIP:
			t.queue_free()
			return 0.0
		t.SurfaceType.SLIPPERY:
			t.queue_free()
			return 0.98
		_:
			t.queue_free()
			return 0.89

# ANIMATION FUNCTION
#-------------------------------------------------------------------------------

## Transitions to a specified animation state.
func change_anim(animation : String) -> void:
	# Get variables
	var state = anim_tree.get("parameters/playback")
	var root = anim_tree.get("tree_root")

	# Check to see if state exists
	if !root.has_node(animation):
		push_error("Animation \'" + animation + "\' could not be found.")
		return

	# Travel to animation
	state.travel(animation, false)

## Forces the AnimationTree into a specific state.
func set_anim(animation : String) -> void:
	# Get variables
	var state = anim_tree.get("parameters/playback")
	var root = anim_tree.get("tree_root")

	# Check to see if state exists
	if !root.has_node(animation):
		push_error("Animation \'" + animation + "\' could not be found.")
		return

	# Begin animation
	state.start(animation)
