# soda.gd
class_name Soda extends Area3D

'''
Primary health source for Newman
'''

enum Types {
	Normal, ## Okie Cola, heals 2 health
	Mega, ## Strawberry soda, heals all health
}
const HEALING = [
	2, ## Normal healing amount
	6, ## Mega healing amount
]

@export_category("Soda")
## The type of Soda, which determines healing amount.
@export var type : Types = Types.Normal

func _ready() -> void:
	# Connect signal
	body_entered.connect(soda_collected.bind())

# FUNCTION
#-------------------------------------------------------------------------------

## Ran when Soda is collected
func soda_collected(body : Node3D) -> void:
	# Ensure body is player
	if not body is Player:
		return
	
	# Heal player
	body = body as Player
	var hurtbox = body.hurtbox_node as Hurtbox
	hurtbox.heal(HEALING[type])
	
	# Animate self
	var e_e = $external_effect
	get_tree().create_timer(2).timeout.connect(func(): e_e.queue_free())
	$external_effect/soda.emitting = true
	$external_effect/open.play()
	e_e.reparent(get_tree().current_scene, true)
	
	# Die
	queue_free()
