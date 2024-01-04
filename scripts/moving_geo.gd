# moving_geo.gd
@tool
class_name MovingGeo extends Node3D

'''
Configures and previews moving geometry in editor.
You will need to supply your own geometry and collision.
Do not rename children nodes.
'''

@export_category("MovingGeometry")
@export_group("Configuration")
## Whether or not to loop around or not.
@export var loop_around : bool = false
## [AudioStream] to use for movement.
@export var stream_move : AudioStream
## [AudioStream] to use for stopping.
@export var stream_stop : AudioStream
## The time it will take to move the platform from
## one end of the path to the next
@export_range(0.25, 20.0) var time_to_end : float = 2.0
## The time it will spend idle between travel periods
@export_range(0.0, 20.0) var time_idle : float = 3.0
## Type of transition to use.
@export var t_trans : Tween.TransitionType = Tween.TransitionType.TRANS_CUBIC
## Type of easing to use.
@export var t_ease : Tween.EaseType = Tween.EaseType.EASE_IN_OUT

@export_group("")
## Generates nodes when toggled.
@export var generate_base : bool = false :
	set(_value) : generate_base = false; generate_base_nodes();
	get : return generate_base
## Toggles previewing of the moving geometry.
@export var toggle_preview : bool = false :
	set(value) : toggle_preview = value; show_preview();
	get : return toggle_preview

## Reference to path
var path : Path3D
## Reference to path follower
var path_follow : PathFollow3D
## Reference to remote transform
var r_transform : RemoteTransform3D
## Reference to animatable body
var geometry : AnimatableBody3D
## Reference to moving sound
var sfx_move : AudioStreamPlayer3D
## Reference to stopping sound
var sfx_stop : AudioStreamPlayer3D
## Tween
var tween : Tween
## Whether or not to clear all children nodes when generating.
var ready_to_clear : bool = false

func _enter_tree() -> void:
	if !Engine.is_editor_hint():
		toggle_preview = false

func _ready() -> void:
	# Get refs
	path = get_node("path")
	sfx_move = get_node("sfx_move")
	sfx_stop = get_node("sfx_stop")
	path_follow = get_node("path/path_follower")
	r_transform = get_node("path/path_follower/remote_transform")
	geometry = get_node("geometry")
	
	
	# If theres nulls, warn
	if !path || !path_follow || !r_transform || !geometry || !sfx_move || !sfx_stop:
		push_error("Broken refs in moving geometry! " + name)
	
	# Begin animating
	if !Engine.is_editor_hint():
		move_geo()

# FUNCTION
#-------------------------------------------------------------------------------

## Generates the base set of nodes needed to operate
## the moving geometry.
func generate_base_nodes() -> void:
	# If there's children, dont run
	if get_child_count() > 0:
		if ready_to_clear:
			print("Children cleared.")
			ready_to_clear = false
			for child in get_children():
				child.queue_free()
			return
			
		print("Children nodes present, press again to confirm regen.")
		ready_to_clear = true
		return
	
	# Create new nodes
	path = Path3D.new()
	path_follow = PathFollow3D.new()
	r_transform = RemoteTransform3D.new()
	geometry = AnimatableBody3D.new()
	sfx_move = AudioStreamPlayer3D.new()
	sfx_stop = AudioStreamPlayer3D.new()
	
	# Add to self
	add_child(path)
	path.add_child(path_follow)
	path_follow.add_child(r_transform)
	add_child(geometry)
	add_child(sfx_move)
	add_child(sfx_stop)
	
	# Configure nodes
	path.name = "path"
	path.curve = Curve3D.new()
	path_follow.name = "path_follower"
	path_follow.loop = false
	path_follow.rotation_mode = PathFollow3D.ROTATION_NONE
	r_transform.name = "remote_transform"
	r_transform.update_rotation = false
	r_transform.update_scale = false
	r_transform.remote_path = geometry.get_path()
	geometry.name = "geometry"
	geometry.sync_to_physics = true
	sfx_move.name = "sfx_move"
	sfx_move.stream = stream_move
	sfx_move.bus = "Sound"
	sfx_stop.name = "sfx_stop"
	sfx_stop.stream = stream_stop
	sfx_stop.bus = "Sound"
	
	# Set owner
	path.set_owner(get_tree().edited_scene_root)
	path_follow.set_owner(get_tree().edited_scene_root)
	r_transform.set_owner(get_tree().edited_scene_root)
	geometry.set_owner(get_tree().edited_scene_root)
	sfx_move.set_owner(get_tree().edited_scene_root)
	sfx_stop.set_owner(get_tree().edited_scene_root)

## Shows a preview of how the platform will function in-game.
func show_preview() -> void:
	# Wait if not in tree
	if !is_inside_tree():
		await tree_entered
	
	# Wait if not ready
	if !is_node_ready():
		await ready
	
	# Abort if not in editor
	if !Engine.is_editor_hint():
		return
	
	# If theres a tween, kill it
	if tween:
		tween.kill()
	
	# Abort if no preview
	if !toggle_preview:
		path_follow.progress_ratio = 0.0
		return
	
	# Create tween
	tween = create_tween()
	tween.set_trans(t_trans)
	tween.set_ease(t_ease)
	tween.set_loops()
	
	# Start phase
	tween.tween_callback(sfx_move.play.bind())
	tween.parallel().tween_property(sfx_move, "volume_db", -4, time_to_end * 0.5).from(-40)
	tween.parallel().tween_property(path_follow, "progress_ratio", 1.0, time_to_end).from(0.0)
	tween.parallel().tween_interval(time_to_end)
	
	# End phase
	tween.tween_callback(sfx_move.stop.bind())
	tween.parallel().tween_callback(sfx_stop.play.bind())
	tween.tween_interval(time_idle)
	
	if !loop_around:
		# Start phase
		tween.tween_callback(sfx_move.play.bind())
		tween.parallel().tween_property(sfx_move, "volume_db", -4, time_to_end * 0.5).from(-40)
		tween.parallel().tween_property(path_follow, "progress_ratio", 0.0, time_to_end).from(1.0)
		tween.parallel().tween_interval(time_to_end)
		
		# End phase
		tween.tween_callback(sfx_move.stop.bind())
		tween.parallel().tween_callback(sfx_stop.play.bind())
		tween.tween_interval(time_idle)
		
		
	tween.play()
		
## Animates the platform ingame.
func move_geo() -> void:
	# Create tween
	tween = create_tween()
	tween.set_trans(t_trans)
	tween.set_ease(t_ease)
	tween.set_loops()
	
	# Start phase
	tween.tween_callback(sfx_move.play.bind())
	tween.parallel().tween_property(sfx_move, "volume_db", -4, time_to_end * 0.5).from(-40)
	tween.parallel().tween_property(path_follow, "progress_ratio", 1.0, time_to_end).from(0.0)
	tween.parallel().tween_interval(time_to_end)
	
	# End phase
	tween.tween_callback(sfx_move.stop.bind())
	tween.parallel().tween_callback(sfx_stop.play.bind())
	tween.tween_interval(time_idle)
	
	if !loop_around:
		# Start phase
		tween.tween_callback(sfx_move.play.bind())
		tween.parallel().tween_property(sfx_move, "volume_db", -4, time_to_end * 0.5).from(-40)
		tween.parallel().tween_property(path_follow, "progress_ratio", 0.0, time_to_end).from(1.0)
		tween.parallel().tween_interval(time_to_end)
		
		# End phase
		tween.tween_callback(sfx_move.stop.bind())
		tween.parallel().tween_callback(sfx_stop.play.bind())
		tween.tween_interval(time_idle)
		
		
	tween.play()
