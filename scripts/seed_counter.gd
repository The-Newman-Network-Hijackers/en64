# seed_counter.gd
extends Area3D

'''
Monitors for Seed entities and creates stems in their place.
'''

## Amount of seeds needed before firing [EventTree].
const COUNT_TO_EVENT = 5
## Reference to spawn particles
const SPAWN_PARTICLE = preload("res://asset/effect/respawn/respawn.tscn")

@export_category("SeedCounter")
## [EventTree] to execute when complete.
@export var event_tree : EventTree

## Stem reference
@onready var stem := $stem as MeshInstance3D
## SFX reference
@onready var sfx_poof := $poof as AudioStreamPlayer
## Stem materials
@onready var _tex = [
	preload("res://asset/effect/grass/vtxe_stem_1.tres"),
	preload("res://asset/effect/grass/vtxe_stem_2.tres")
]

## Current progress.
var progress : int = 0

func _body_entered(body : Node3D) -> void:
	# Filter for seed
	if not body is Entity:
		return
	body = body as Entity
	if body.e_name.to_lower() != "seed":
		return 
	
	# Get position and spawn stem
	var pos = get_new_position(body)
	var instance = $stem.duplicate()
	instance.visible = true
	instance.material_override = _tex[randi_range(0, 1)]
	add_child(instance)
	instance.global_position = pos
	
	# Create some particles for good measure
	var particle = SPAWN_PARTICLE.instantiate()
	add_child(particle)
	particle.global_position = instance.global_position
	particle.emitting = true
	particle.finished.connect(func(): particle.queue_free())
	
	# Play sound
	sfx_poof.play()
	
	# Destroy incoming node
	body.queue_free()
	
	# Increment progress
	progress += 1
	if progress >= 5:
		event_tree.execute()
	
func get_new_position(body : Entity) -> Vector3:
	# Body is seed, remove and put stem in place
	var space := get_world_3d().direct_space_state
	var b_pos = body.global_position + (Vector3.UP * 5)
	var target = b_pos + (Vector3.DOWN * 50)
	var queue = PhysicsRayQueryParameters3D.create(b_pos, target, 1 << 0)
	queue.hit_from_inside = true
	queue.exclude = [body]
	var result = space.intersect_ray(queue)
	DebugDraw3D.draw_line(b_pos, target, Color.RED, 10.0)
	print(result)
	
	if !result.has("position"):
		return Vector3.ZERO
	return result.get("position") as Vector3
