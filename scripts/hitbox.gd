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

## Hurtboxes to apply damage to
var hurtboxes : Array[Hurtbox]

func _ready() -> void:
	collision_mask = scope
	monitorable = false
	
	# Connect signal
	area_entered.connect(hurtbox_entered.bind())
	area_exited.connect(hurtbox_exited.bind())

func _physics_process(delta : float) -> void:
	# Do not process with no hurtboxes
	if hurtboxes.size() == 0:
		return
	
	for hurtbox in hurtboxes:
		# Pass if invulnerable
		if hurtbox.is_invulnerable:
			continue
		
		# Check tag
		var tag_found = false
		if hurtbox.tags.size() > 0:
			for a_tag in hurtbox.tags:
				if a_tag == tag:
					tag_found = true
					break
			if !tag_found:
				continue
		
		hurtbox.take_damage(damage, global_position, knockback)

func hurtbox_entered(area : Area3D) -> void:
	# Weed out non-hurtboxes
	if not area is Hurtbox:
		return
	
	# Add body to array
	hurtboxes.append(area)
	
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

func hurtbox_exited(area : Area3D) -> void:
	# Check if area is even a hurtbox
	if not area is Hurtbox:
		return
	
	# Check if area is in hurtboxes
	if not area in hurtboxes:
		return
	
	# Remove 
	hurtboxes.remove_at(hurtboxes.find(area))
