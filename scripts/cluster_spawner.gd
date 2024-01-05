# cluster_spawner.gd
class_name ClusterSpawner extends Node3D

'''
Spawns a defined number of Entity nodes
'''

@export_category("ClusterSpawner")
## The scene to instantiate
@export var scene : PackedScene
## The amount of [Entity] to spawn
@export var spawn_count : int = 3
## The timing between each spawn
@export var delay_per_spawn : float = 0.0
## The variance in forward velocity, with X being minimum and Y being maximum
@export var fs_variance : Vector2 = Vector2(30, 40)
## The variance in y velocity, with X being minimum and Y being maximum
@export var yv_variance : Vector2 = Vector2(45, 65)
## Whether or not this cluster is a one shot.
@export var one_shot : bool = false

## Reference to timer node
var timer : Timer

func _ready() -> void:
	# Create timer node
	if delay_per_spawn > 0.0:
		timer = Timer.new()
		timer.wait_time = delay_per_spawn
		timer.one_shot = true
		timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
		add_child(timer)

# FUNCTION
#-------------------------------------------------------------------------------

func spawn() -> void:
	# Iterate and spawn
	for x in range(spawn_count):
		# Create new instance
		var instance = scene.instantiate()
		instance.name = str(x)
		
		# Verify this is an Entity
		if not instance is Entity:
			print(instance.get_class())
			print("Instance is not entity.")
			return
		
		# Configure instance
		instance = instance as Entity
		instance.visual_node.rotation.y = deg_to_rad(360 / spawn_count * x)  
		instance.forward_speed = randf_range(fs_variance.x, fs_variance.y)
		instance.velocity.y = randf_range(yv_variance.x, yv_variance.y)
		add_child(instance)
		instance.tree_exited.connect(child_exited.bind())
		
		# Wait for timer
		if timer:
			timer.start()
			await timer.timeout

func child_exited() -> void:
	if !one_shot:
		return
	if get_child_count() > 0:
		return
	queue_free()
