# player.gd
class_name Player extends Entity

'''
Primary form of user control.
'''

## Signal fired when collecting a jack
signal jack_collected(area_id : int, warp_id : int)
## Signal fired when collecting a soda
signal soda_collected(health : int)
## Signal fired when collecting a prop
signal shard_collected(shard_data : ShardData)
## Signal fired when prop collection sequence is finished
signal shard_collect_done()
## Signal fired when camera attempts to toggle wobble effect
signal toggle_wobble(mode : bool, color : Color)
## Signal fired when a warp has begun
signal warp_began()
## Signal fired when a warp state has finished transitioning.
signal warp_finished()
## Signal fired when player is in death state.
signal death_cutscene()

## Player states that allow for interaction.
const INTERACT_WHITELIST = [
	"idle", "move"
]
## Player water states
const WATER_STATES = [
	"swim_idle",
	"swim_move"
]

# REFERENCES
#-------------------------------------------------------------------------------

## MAIN
@onready var _anim_tree : AnimationTree = $anim_tree
@onready var _vis_manager : PlayerVisualManager = $visual_manager
@onready var _equip_manager : PlayerEquipmentManager = $equipment_manager
@onready var _pim : PlayerInteractionRadius = $player_interaction_radius
@onready var _spring_arm : PCam_SpringArm = $spring_arm
@onready var _cam_body : Area3D = $spring_arm/f_cam/player_cam/cam_body
@onready var _state_machine : StateMachine = $state_machine as StateMachine

## SOUND
@onready var _sfx : Node3D = $sfx
@onready var _sfx_bonk : AudioStreamPlayer3D = $sfx/bonk

## PARTICLE
@onready var _particle : Node3D = $particle

## SKELETON
@onready var _skeleton : Skeleton3D = $visual/newman/skeleton
@onready var _hand_attach : BoneAttachment3D = $visual/newman/skeleton/item_follow
@onready var _hand_transform : RemoteTransform3D = $visual/newman/skeleton/item_follow/item_follow_transform

## LEDGE
@onready var _l_root : Node3D = $ledge
@onready var _l_edge_L : RayCast3D = $ledge/edge_l
@onready var _l_edge_R : RayCast3D = $ledge/edge_r
@onready var _l_edge : RayCast3D = $ledge/edge
@onready var _l_wall : RayCast3D = $ledge/wall
@onready var _l_wall_L : RayCast3D = $ledge/wall_l
@onready var _l_wall_R : RayCast3D = $ledge/wall_r
@onready var _l_wslide : RayCast3D = $ledge/wslide

# VARIABLES
#-------------------------------------------------------------------------------

#### WARPING

## The last known subarea teleported to.
var last_known_area : int = 0
## The last known warp teleported to.
var last_known_warp : int = -1

#### STATES

## Determines if the player did a double jump
var double_jumped : bool = false
## Determines if twirl is on cooldown
var twirl_on_cooldown : bool = false
## Determines if we should update control or not
var has_control : bool = true

#### WATER

## Signals that the player is touching water.
var touching_water : bool = false
## Signals that the player is submerged in water
var in_water : bool = false
## The bodies of water the player is currently in
var current_waterbody : Water

#### SLOPE

## Determines if the player is trying to slide down a slope
var going_down_slope : bool = false

func _ready() -> void:
	# Activate animation tree
	_anim_tree.active = true

func _physics_process(_delta: float) -> void:
	# Rotate ledge detection
	_l_root.rotation.y = visual_node.rotation.y + deg_to_rad(180)
	
	# Update waterbody if there is a waterbody
	if current_waterbody:
		update_waterbody()
	else:
		in_water = false
		touching_water = false
	
	# Debug
	DebugDraw2D.set_text("vel", velocity)
	DebugDraw2D.set_text("f_vel", forward_speed)
	DebugDraw2D.set_text("inpd", Vector2(input_direction.y, input_direction.x).angle())
	DebugDraw2D.set_text("move", get_movement())
	DebugDraw3D.draw_arrow_ray(global_position, input_direction, 3.25, Color.BLUE, 1, true)
	DebugDraw3D.draw_arrow_ray(global_position, velocity, .25, Color.DARK_RED, 1, true)

func _input(event : InputEvent) -> void:
	# Stop input if no control
	if !has_control:
		get_tree().root.set_input_as_handled()
	
	if event is InputEventKey:
		if event.keycode == KEY_F2 && event.is_pressed():
			if _state_machine.state.name != "debug_noclip":
				_state_machine.transition_state("debug_noclip")
				return
			_state_machine.transition_state("airborne")

# GENERAL FUNCTION
#-------------------------------------------------------------------------------

## Updates movement in the air.
func update_movement_air(delta : float) -> void:
	## Get and compare angles
	var input_ang = Vector2(input_direction.x, input_direction.z)
	var face_ang = Vector2(sin(visual_node.rotation.y), cos(visual_node.rotation.y))
	var angle_diff = input_ang.angle_to(face_ang)
	angle_diff = rad_to_deg(angle_diff)
	var movement = Vector3.ZERO
	
	# Apply different forces based on angle_diff
	if angle_diff > -45 && angle_diff < 45:
		# Forward movement
		forward_speed = ease_value(forward_speed, max(move_speed * input_direction.length(), forward_speed), acceleration, delta)
		side_speed = ease_value(side_speed, 0, deacceleration, delta)
	elif angle_diff <= -45 && angle_diff > -135:
		# Left movement
		side_speed = ease_value(side_speed, -move_speed * input_direction.length(), acceleration, delta)
	elif angle_diff <= -135 || angle_diff > 135:
		# Back movement
		forward_speed = ease_value(forward_speed, min(-move_speed * input_direction.length(), forward_speed), acceleration, delta)
		side_speed = ease_value(side_speed, 0, deacceleration, delta)
	elif angle_diff >= 45 && angle_diff <= 135:
		# Right movement
		side_speed = ease_value(side_speed, move_speed * input_direction.length(), acceleration, delta)
	
	# Rotate and apply speed
	movement = Vector3(side_speed, 0, forward_speed)
	var speed_rot = movement.rotated(Vector3.UP, visual_node.rotation.y)
	velocity.x = speed_rot.x
	velocity.z = speed_rot.z
	
	# Calculate gravity
	if !is_on_floor():
		velocity.y = max(velocity.y + get_gravity() * delta, -terminal_velocity)
	
	# Debug
	DebugDraw2D.set_text("vel", velocity)
	DebugDraw2D.set_text("f_vel", forward_speed)
	DebugDraw2D.set_text("inpd", input_direction)
	
	# Move
	move_and_slide()

## Updates physics in water.
func update_movement_water(delta : float) -> void:
	# Declare variables
	var normal = floor_raycast.get_collision_normal()
	var i_speed_rotated = (Vector3.FORWARD * -min(forward_speed, max_speed)).rotated(Vector3.UP, vis_rotation.y)

	# Calculate total speed
	velocity.x = i_speed_rotated.x
	velocity.z = i_speed_rotated.z
	
	# Move
	move_and_slide()

## Updates physics in debug noclip mode.
func update_movement_debug(delta : float) -> void:
	# Declare variables
	var i_speed_rotated = (Vector3.FORWARD * -min(forward_speed, max_speed)).rotated(Vector3.UP, vis_rotation.y)

	# Calculate total speed and move
	velocity.x = i_speed_rotated.x
	velocity.z = i_speed_rotated.z
	friction = get_friction(get_terrain())
	move_and_slide()

## Calculates player input direction.
func update_control() -> void:
	# Abort if no update
	if !has_control:
		input_direction = Vector3.ZERO
		return
	
	# Determine the input direction
	var input_vec : Vector2 = get_movement()
	input_direction = Vector3(input_vec.x, 0, -input_vec.y).rotated(Vector3.UP, _spring_arm.camera.global_rotation.y)

## Calculates player forward speed.
func update_forward_speed(delta : float, target_speed : float = move_speed, augment : float = 1) -> void:
	# Increment and deincrement based on input
	if input_direction.length() > 0.1: # Input
		forward_speed = ease_value(
			forward_speed,
			target_speed * input_direction.length(),
			acceleration * augment * friction,
			delta
		)
	else: # No input
		forward_speed = ease_value(
			forward_speed,
			0,
			deacceleration * augment * friction,
			delta
		)

## Updates player rotation visuals using interpolation
func update_visual(_delta : float, spd : float = 0.1, rot : bool = true) -> void:
	# Get a look direction
	var look_direction = vis_rotation.y

	# Check to see if there is any intended movement.
	if input_direction.length() > 0.1:
		look_direction = Vector2(input_direction.z, input_direction.x)
		vis_rotation.y = lerp_angle(vis_rotation.y, look_direction.angle(), spd)

	# Interpolate towards direction
	if rot:
		visual_node.rotation.y = vis_rotation.y

	# Additional calculations
	update_normal_rotation()
	update_x_rotation()

## Returns the current input vector.
func get_movement() -> Vector2:
	# Abort if no control
	if !has_control:
		return Vector2.ZERO
	
	if Input.get_connected_joypads().size() > 0:
		return Input.get_vector("left", "right", "down", "up")
	return Vector2(Input.get_axis("left", "right"), Input.get_axis("down", "up")).normalized()

## Returns the current input vector, projected along normal
func get_movement_rotated() -> Vector3:
	var movement = get_movement()
	var angle : float = _spring_arm.rotation.y
	return Vector3(movement.x, 0, movement.y).rotated(Vector3.UP, angle)

# NORMAL / ANGLE FUNCTION
#-------------------------------------------------------------------------------

## Updates player x rotation based on their inputs and velocity.
func update_x_rotation() -> void:
	# Declare variables
	var input_vec = get_movement()
	var x_rot = visual_node.rotation.x

	# Get the angle between intended and current movement
	var angle : float = (
		Vector2(sin(vis_rotation.y), cos(vis_rotation.y)).angle_to(Vector2(input_direction.x, input_direction.z)) if
		input_direction.length() > 0.1 else 0
	) * .5

	# Clamp value
	angle = clampf(angle, -1.5, 1.5)
	DebugDraw2D.set_text("vis_xang", angle)

	# Interpolate and set
	visual_node.rotation.x = lerp_angle(
		visual_node.rotation.x,
		angle if is_on_floor() else 0.0,
		0.1
	)

## Determines if a ledge grab is possible
func can_ledge_grab() -> bool:
	# Check to see if player is not on floor
	if !is_on_floor():
		# Check to see if there is ground
		_l_edge.force_raycast_update()

		# If there is, then check wall
		if _l_edge.is_colliding():
			# Check the magnitude of the ground
			if _l_edge.get_collision_normal().normalized().dot(Vector3.UP) <= 0.88:
				return false

			# Update wall raycast
			_l_wall.force_raycast_update()

			# If there is a wall, then we can ledge grab
			if _l_wall.is_colliding():
				return true

	# Otherwise, nope
	return false

## Gets the normal of the wall the player is facing.
func get_ledge_normal() -> Vector3:
	# Get collider
	var result = _l_wall.is_colliding()

	# If ray hits wall
	if result:
		# Get wall normal and return
		var normal = _l_wall.get_collision_normal()
		normal.y = 0
		return normal
	else:
		# Otherwise, return zero
		return global_position

## Determines the player's relationship with current waterbody
func update_waterbody() -> void:
	# Get the positions of the player and waterbody
	var g_pos = global_position
	var wb_g_pos = current_waterbody.global_position

	# Player is about 6 units tall
	if g_pos.y <= wb_g_pos.y && g_pos.y >= wb_g_pos.y - 3:
		touching_water = true
		in_water = false
	elif g_pos.y <= wb_g_pos.y - 3:
		touching_water = true
		in_water = true
		# Force transition
		if not _state_machine.state.name in WATER_STATES:
			_state_machine.transition_state("swim_idle")
			
			# Behave differently based on speed coming into pool
			if velocity.y > -15:
				$sfx/water/thump_shallow.play()
			else:
				emit_splash_particle()
				$sfx/water/thump_deep.play()
	else:
		touching_water = false
		in_water = false

## Ran when [Hurtbox] component is damaged
func _hurtbox_damaged(value: int, packet: Dictionary) -> void:
	# Put player in hurt state
	_state_machine.transition_state("hit", packet)

# TERRAIN FUNCTION
#-------------------------------------------------------------------------------

## Returns the footstep sound effect directory from floor.
func get_floor_sound(type : int) -> String:
	# If touching water, send water sounds
	if touching_water:
		return "sfx/step/wet"
		
	var t = Terrain.new()
	match type:
		t.AudioType.SOFT:
			t.queue_free()
			return "sfx/step/soft"
		t.AudioType.CRUNCHY:
			t.queue_free()
			return "sfx/step/crunchy"
	t.queue_free()
	return "sfx/step/generic"

# ANIMATION FUNCTION
#-------------------------------------------------------------------------------

## Creates a ring of particles
func emit_jump_particle(origin_path : NodePath = get_path()) -> void:
	# Get node
	var origin_node = get_node(origin_path)
	
	for i in range(8):
		# Instance land particle
		var p_land : GPUParticles3D = _particle.get_node_or_null("land")
		var instance = p_land.duplicate()
		add_child(instance)

		# Configure
		instance.global_position = origin_node.global_position
		instance.transform = align_to_normal(instance.transform, floor_raycast.get_collision_normal())
		instance.rotation.y = deg_to_rad(45 * i)
		instance.restart()
		
		# Connect signal
		get_tree().create_timer(instance.lifetime).timeout.connect(func():
			if is_instance_valid(instance):
				instance.queue_free()
		)

## Creates a splash particle
func emit_splash_particle() -> void:
	# Create splash instance
	var instance = _particle.get_node("splash").duplicate()
	instance.top_level = true
	add_child(instance)
	instance.global_position.y += 2
	
	# Execute
	instance.evoke()
