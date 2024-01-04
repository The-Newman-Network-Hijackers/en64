# hurtbox.gd
class_name Hurtbox extends Area3D

'''
Handles incrementing and decrementing health data.
'''

## Fired when healed
signal healed(health : int, packet : Dictionary)
## Fired when damage is received.
signal damaged(health : int, packet : Dictionary)
## Fired when health has reached 0.
signal died(health : int, packet : Dictionary)

@export_category("Hurtbox")
## The amount of hits the [Hurtbox] can take before death.
@export var max_health : int = 1
## The amount of time to be invulnverable
@export var inv_time : float = 1.0
## Whether or not to flash when invulnerable
@export var flash_when_invulnerable : bool = false
## Damage tags to accept. Putting in none will allow all damage types
@export var tags : Array[String]
## Collision layer of the [Hurtbox].
@export_flags("World", "Player", "Entity") var scope : int = 1 << 1

## The current health of the [Hurtbox]
@onready var health := max_health
## Visual node of owner, inferred from damage func
@onready var visual_node = get_parent()

## Reference to invulnerability timer
var invulnerable_timer : SceneTreeTimer
## Whether or not this [Hurtbox] is currently invulnerable.
var is_invulnerable := false

func _ready() -> void:
	collision_layer = scope
	monitoring = false

func _physics_process(_delta: float) -> void:
	if !is_invulnerable || !flash_when_invulnerable || !visual_node || !invulnerable_timer:
		return
	
	var not_invisible = fposmod(invulnerable_timer.time_left, .1) < 0.05
	visual_node.visible = not_invisible

# FUNCTION
#-------------------------------------------------------------------------------

## Applies damage
func take_damage(damage : int, origin : Vector3 = Vector3.ZERO, knockback : float = 20.0) -> void:
	# Calculate knockback
	var is_entity := owner is Entity
	var from_back := false
	if is_entity:
		var entity := owner as Entity
		visual_node = entity.visual_node
		var direction := Vector2(origin.z, origin.x).angle_to_point(Vector2(entity.global_position.z, entity.global_position.x)) as float
		from_back = origin.direction_to(entity.global_position).dot(entity.visual_node.basis.z) > 0
		entity.vis_rotation.y = direction if from_back else direction + deg_to_rad(180)
		entity.forward_speed = knockback if from_back else -knockback
	
	# Apply damage
	health = max(0, health - damage)
	if health <= 0:
		died.emit(health, {"from_back" : from_back if is_entity else null})
	damaged.emit(health, {"from_back" : from_back if is_entity else null})
	
	# Apply invulnerability
	is_invulnerable = true
	if health <= 0:
		return
	invulnerable_timer = get_tree().create_timer(inv_time, false, true)
	invulnerable_timer.timeout.connect(
		func():
			is_invulnerable = false
			if flash_when_invulnerable:
				visual_node.visible = true
	)
	

## Applies healing
func heal(value : int) -> void:
	health = min(health + value, max_health)
	healed.emit(health, {})
