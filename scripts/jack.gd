# jack.gd
class_name Jack extends Area3D

'''
The secondary collectible and currency of the game.
'''

## The sound effect to play when collected.
@onready var sfx_collect = preload("res://audio/sfx/collect_jack.wav")

func _ready() -> void:
	# Animate
	$vis.play("default")
	$vis.frame = int(randf() * 29)

func _body_entered(body : Node3D) -> void:
	if body is Player:
		# Generate effects
		create_sparkle()
		AudioManager.spawn_sound_stream(sfx_collect, randf_range(0.95, 1.1), global_position)

		# Update data
		PlayerDataManager.current_jacks += 1

		# Remove self
		queue_free()

# FUNCTION
#-------------------------------------------------------------------------------

## Removes shadow from self.
func remove_shadow() -> void:
	$shadow.queue_free()

## Takes sparkle from self and instantiates.
func create_sparkle() -> void:
	# Create particle
	var p_dupe : GPUParticles3D = $sparkles.duplicate()

	# Add to scene
	get_tree().current_scene.add_child(p_dupe)
	p_dupe.global_position = global_position + Vector3.UP * 1.5
	p_dupe.emit()
