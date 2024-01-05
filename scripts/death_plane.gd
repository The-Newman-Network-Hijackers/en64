# death_plane.gd
class_name DeathPlane extends Area3D

'''
Instantly kills player and restarts area.
'''

func _ready() -> void:
	# Configure
	collision_mask = 1 << 1 # Player
	monitorable = false
	
	# Connect signal
	body_entered.connect(_body_entered.bind())

# FUNCTION
#-------------------------------------------------------------------------------

func _body_entered(body : Node3D) -> void:
	# Verify body is player
	if not body is Player:
		return
	
	# Disable self
	var col = get_child(0) as CollisionShape3D
	if col:
		col.disabled = true
	
	# Assign/Get variables
	var lm := get_tree().get_first_node_in_group("LevelManager") as LevelManager
	var cam := body._spring_arm as PCam_SpringArm
	var c_st := cam._fsm.state.name as String
	body = body as Player
	
	# Initiate death sequence
	body.death_cutscene.emit(body.last_known_area, body.last_known_warp)
	#body.hurtbox_node.take_damage(6, Vector3.ZERO, 0)
	cam._fsm.transition_state("fixed")
	
	# Wait for transition
	await lm.level_unloaded
	
	# Reset camera
	cam._fsm.transition_state(c_st)
	body.hurtbox_node.heal(6)
	body.hurtbox_node.is_invulnerable = false
	
	# Enable self
	if col:
		col.disabled = false
