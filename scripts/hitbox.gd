# hitbox.gd
class_name Hitbox extends Area3D

'''
Damages any Hurtboxes within.
'''

@export_category("Hitbox")
## The amount of damage to deal to [Hurtbox].
@export var damage : int = 1
## The amount of knockback (equivalent of forward speed) to apply
@export var knockback : float = 20.0
## Damage tags to send. Putting in none will check for nothing
@export var tag : String = ""
## Scope of what to damage.
@export_flags("World", "Player", "Entity") var scope : int = 1 << 1

func _ready() -> void:
	collision_mask = scope
	monitorable = false
	
	# Connect signal
	area_entered.connect(hurtbox_entered.bind())

func hurtbox_entered(area : Area3D) -> void:
	# Weed out non-hurtboxes
	if not area is Hurtbox:
		return
	
	# Check for invulnerability frame
	if area.is_invulnerable:
		return
	
	# Check tags
	var tag_found = false
	if area.tags.size() > 0:
		for a_tag in area.tags:
			if a_tag == tag:
				tag_found = true
				break
		if !tag_found:
			return
	
	# Send damage
	area = area as Hurtbox
	area.take_damage(damage, global_position, knockback)
