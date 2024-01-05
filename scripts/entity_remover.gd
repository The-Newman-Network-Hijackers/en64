# entity_remover.gd
class_name EntityRemover extends Area3D

'''
Removes and optionally respawns any Entities that come into contact.
'''

## Reference to spawn particles
const SPAWN_PARTICLE = preload("res://asset/effect/respawn/respawn.tscn")
## Reference to spawn stream
const SPAWN_STREAM = preload("res://audio/sfx/poof.wav")

func _ready() -> void:
	# Configure self
	monitorable = false
	collision_layer = 0 # None
	collision_mask = 1 << 2 | 1 << 15 # Entity, GrabbableEntity
	
	# Connect signal
	body_entered.connect(entity_entered.bind())
	
func entity_entered(node : Node3D) -> void:
	# Verify
	if not node is Entity:
		return
	
	# Cast
	node = node as Entity
	var c_pos = node.global_position as Vector3
	var o_pos = node.spawn as Vector3
	var o_parent = node.get_parent()
	
	# Destroy or move
	if !node.respawn:
		node.queue_free()
	else:
		o_parent.remove_child(node)
		spawn_effects(c_pos)
		await get_tree().create_timer(1.0, false).timeout
		node.position = o_pos
		node.velocity = Vector3.ZERO
		node.forward_speed = 0.0
		o_parent.call_deferred("add_child", node)
	
	# Effects
	spawn_effects(o_pos)

func spawn_effects(pos : Vector3) -> void:
	# Effect
	var rp_i := SPAWN_PARTICLE.instantiate()
	rp_i.finished.connect(func(): rp_i.queue_free())
	
	# Create sound
	var sfx := AudioStreamPlayer3D.new()
	sfx.finished.connect(func(): sfx.queue_free())
	sfx.stream = SPAWN_STREAM
	sfx.volume_db = -4
	sfx.max_db = -4
	sfx.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	sfx.max_distance = 120.0
	sfx.bus = "Sound"
	
	# Add both to scene
	add_child(sfx)
	add_child(rp_i)
	
	sfx.global_position = pos
	rp_i.global_position = pos
	sfx.play()
	rp_i.restart()
	
