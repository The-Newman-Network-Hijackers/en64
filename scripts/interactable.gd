# interactable.gd
class_name Interactable extends Area3D

'''
Evokes a linked EventTree when the Player interacts.
'''

# Emitted when interracted with.
signal interacted_with()

@export_category("Interactable")
## The linked [EventTree].
@export var event_tree : EventTree
## The priority of the interactable. Higher value means higher priority
@export var event_priority : int = 0

@export_group("InputPrompt")
## The input prompt to associate with the interactable.
@export var input_prompt : InputPrompt
## The distance to draw the input prompt
@export var prompt_distance : float = 8.0

## Reference to input rect
var input_rect : Sprite3D
## Reference to equipment rect
var equipment_rect : Sprite3D
## Reference to input rect anchor
var input_anchor : Node3D
## Determines if the player is in the radius
@onready var focused : bool = false :
	set(value) : focused = value; if input_anchor: input_anchor.visible = value
	get : return focused

func _ready() -> void:
	# Configure
	collision_layer = 1 << 2 # Entity layer
	collision_mask = 0
	monitoring = false
	focused = false
	
	# Generate rect
	generate_input_rect()
	generate_equip_rect()

func _process(_delta: float) -> void:
	if focused:
		# Get current cam and look at it
		var c_cam = get_tree().root.get_camera_3d() as Camera3D
		input_anchor.look_at(c_cam.global_position)

# FUNCTION
#-------------------------------------------------------------------------------

## Ran when [Player] interacts with self.
func interact(player : Player) -> void:
	# Get collision
	var collision : CollisionShape3D
	for node in get_children():
		if not node is CollisionShape3D:
			continue
		collision = node
		break
	
	# Interact
	interacted_with.emit()
	event_tree.player = player
	event_tree.call_deferred("execute")
	
	# Disable and wait
	collision.set_deferred("disabled", true)
	await event_tree.completed
	
	# Re-enable
	collision.set_deferred("disabled", false)

## Generates input rect
func generate_input_rect() -> void:
	# Create anchor
	input_anchor = Node3D.new()
	input_anchor.visible = false
	add_child(input_anchor)
	
	# Get texture
	var event = InputManager.determine_input(input_prompt.input[0])
	var texture = InputManager.generate_input_texture(event)
	
	# Create sprite
	input_rect = Sprite3D.new()
	input_rect.texture = texture
	input_rect.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	input_rect.no_depth_test = true
	input_rect.fixed_size = true
	input_rect.pixel_size = 0.0015
	
	input_rect.position = Vector3(-prompt_distance, prompt_distance, 0)
	input_anchor.add_child(input_rect)
	
	# Connect signal
	InputManager.input_changed.connect(update_input_rect.bind())

## Generates equipment rect
func generate_equip_rect() -> void:
	# Verify equip rect is necessary
	if input_prompt.equip_icon == -1:
		return
	
	# Get texture
	var texture = InputManager.generate_equipment_texture(input_prompt.equip_icon)
	
	# Create sprite
	equipment_rect = Sprite3D.new()
	equipment_rect.texture = texture
	equipment_rect.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	equipment_rect.no_depth_test = true
	equipment_rect.fixed_size = true
	equipment_rect.pixel_size = 0.004
	equipment_rect.render_priority = 1
	equipment_rect.modulate.a = .1
	
	equipment_rect.position = Vector3(-prompt_distance - 2.5, prompt_distance + 2.5, 0)
	input_anchor.add_child(equipment_rect)
	
	await get_tree().physics_frame
	
	var p := get_tree().get_first_node_in_group("Player") as Player
	if !p:		return
	p._equip_manager.equipment_changed.connect(update_equip_rect.bind())
	update_equip_rect()

## Updates input rect
func update_input_rect() -> void:
	# Get texture
	var event = InputManager.determine_input(input_prompt.input[0])
	var texture = InputManager.generate_input_texture(event)
	
	# Set texture
	input_rect.texture = texture

## Updates equipment rect
func update_equip_rect(_hatch := [], _equip : int = 0) -> void:
	# Compare equip to prompt
	var p := get_tree().get_first_node_in_group("Player") as Player
	var is_equipped = p._equip_manager.current_hatch[p._equip_manager.current_hatch_pos] == 1 << input_prompt.equip_icon
	equipment_rect.modulate.a = 1.0 if is_equipped else 0.15
