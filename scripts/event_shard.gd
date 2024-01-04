# event_shard.gd
class_name EventShard extends Event

'''
Spawns a Shard, at origin point, to target point.
'''

const TIME_UP = 1.0
const TIME_DOWN = 1.0
const TIME_BOUNCE = .5

const STREAM_BOUNCE = preload("res://audio/sfx/twinkle_bounce.wav")

@export_category("EventShard")
## The shard to spawn.
@export var shard : Shard
## Origin point to spawn the shard at
@export var origin : Marker3D
## Target point to move the shard towards
@export var target : Marker3D
## Camera that will look at the shard when spawning.
@export var follow_cam : Camera3D



## Determines when to update look cam
var update_look_cam := false
## Determines when to update follow cam
var update_follow_cam := false
## Reference to true camera
var player_cam : Camera3D

func _ready() -> void:
	# Disable shard, for now
	print(shard)
	shard.visible = false
	shard.process_mode = Node.PROCESS_MODE_DISABLED

func _execute() -> void:
	# Re-enable shard
	shard.visible = true
	shard.process_mode = Node.PROCESS_MODE_INHERIT
	shard.global_position = origin.global_position
	
	# Create and configure tween
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	
	# Animate moving up
	var vec_half := origin.global_position.slerp(target.global_position, 0.5)
	var y_fac := origin.global_position.y + 25.0 if origin.global_position.y > target.global_position.y else target.global_position.y + 25.0
	tw.set_parallel(true)
	tw.tween_callback(look_camera.bind())
	tw.tween_property(shard, "global_position:x", vec_half.x, TIME_UP)
	tw.tween_property(shard, "global_position:z", vec_half.z, TIME_UP)
	tw.tween_property(shard, "global_position:y", y_fac, TIME_UP).set_trans(Tween.TRANS_CUBIC)
	tw.set_parallel(false)
	tw.tween_interval(TIME_UP)

	# Animate moving down
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_parallel(true)
	tw.tween_property(shard, "global_position:x", target.global_position.x, TIME_UP)
	tw.tween_property(shard, "global_position:z", target.global_position.z, TIME_UP)
	tw.tween_property(shard, "global_position:y", target.global_position.y, TIME_UP).set_trans(Tween.TRANS_CUBIC)
	tw.set_parallel(false)
	
	# Animate bounce
	tw.tween_callback(follow_camera.bind())
	tw.tween_callback(play_bounce.bind())
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(
		shard,
		"global_position:y",
		target.global_position.y + 10,
		TIME_BOUNCE
	)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(
		shard,
		"global_position:y",
		target.global_position.y,
		TIME_BOUNCE
	)
	tw.tween_callback(play_bounce.bind())
	tw.tween_interval(2.0)
	tw.tween_callback(finish_sequence.bind())
	
	# You got all that? Now lets play.
	tw.play()
	await tw.finished
	execution_complete.emit()

## Creates the initial follow cam in the cutscene
func look_camera() -> void:
	# Create new camera
	var cam := Camera3D.new()
	player_cam = get_tree().root.get_camera_3d()
	
	# Configure
	cam.fov = player_cam.fov
	cam.position = player_cam.global_position
	
	# Add and make current
	add_child(cam)
	cam.make_current()
	update_look_cam = true
	
	# Update
	while update_look_cam:
		cam.look_at(shard.global_position)
		await get_tree().process_frame
	
	# Cleanup
	cam.queue_free()

## Sets and updates the follow camera defined in properties
func follow_camera() -> void:
	# Get properties from look cam
	var fov = get_tree().root.get_camera_3d().fov
	
	# Disable look cam and enable self
	update_follow_cam = true
	update_look_cam = false
	follow_cam.make_current()
	
	# Tween
	var tw := create_tween()
	tw.tween_property(follow_cam, "fov", follow_cam.fov, 0.5).from(fov)
	tw.play()
	
	# Update
	while update_follow_cam:
		follow_cam.look_at(shard.global_position)
		await get_tree().process_frame

func finish_sequence() -> void:
	# Reset stuff
	update_follow_cam = false
	player_cam.make_current()

func play_bounce() -> void:
	AudioManager.spawn_sound_stream(STREAM_BOUNCE)
