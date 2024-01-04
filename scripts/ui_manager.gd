# ui_manager.gd
class_name UIManager extends Node

'''
In-game UI display manager.
'''

## Texture references for equipment
const _T_EQUIP = [
	preload("res://asset/ui/equip/none.png"),
	preload("res://asset/ui/equip/glove.png"),
	preload("res://asset/ui/equip/slingshot.png"),
	preload("res://asset/ui/equip/hammer.png")
]
## Texture references for healthbar
const _T_HEALTH = [
	preload("res://asset/ui/lifebar/tex/lifebar_0000.png"),
	preload("res://asset/ui/lifebar/tex/lifebar_0001.png"),
	preload("res://asset/ui/lifebar/tex/lifebar_0002.png"),
	preload("res://asset/ui/lifebar/tex/lifebar_0003.png"),
	preload("res://asset/ui/lifebar/tex/lifebar_0004.png"),
	preload("res://asset/ui/lifebar/tex/lifebar_0005.png"),
	preload("res://asset/ui/lifebar/tex/lifebar_0006.png")
]

### HEALTH

## Reference to health ball
@onready var hp_ball := %ball
## Reference to health update timer
@onready var hp_upd_tick := %hp_tick
## Reference to health animation
@onready var hp_anim := %hp_anim
## Current health value in HUD.
var current_health := 6
## Target health value.
var target_health := 6

### DEATH CUTSCENE

## Reference to death cutscene container
@onready var dc_container := %die_container
## Referebce to death cutscene anim player
@onready var dc_anim := $ui_main/svp_main/die_container/clapper2/AnimationPlayer

### EQUIP

## References to equipment hatch rects
@onready var equip_rect = [
	$ui_main/svp_main/ui_container/hatch/mover/equip_up,
	$ui_main/svp_main/ui_container/hatch/mover/equip_left,
	$ui_main/svp_main/ui_container/hatch/mover/equip_down,
	$ui_main/svp_main/ui_container/hatch/mover/equip_right
]
## Reference to equipment marker
@onready var equip_marker = $ui_main/svp_main/ui_container/hatch/mover/equipped
## Reference to equipment anim
@onready var equip_anim := $ui_main/svp_main/ui_container/hatch/anim as AnimationPlayer

### DIALOG

## PackedScene of DialogBox
@onready var dialog_box = preload("res://scenes/menu/textbox_ui.tscn")

### NOTIFICATION

## Queue for notifications
var notif_queue : Array[String] = []
## Reference to [AnimationPlayer]
@onready var notif_anim := $ui_main/svp_main/ui_container/notification/nf_anim

### MISC

## Reference to pause manager
@onready var pause_manager := owner.get_node("pause_manager") as PauseManager

## Height of the screen.
var screen_x : int
## Whether or not bars are faded into screen
var bars_on : bool = false

func _enter_tree() -> void:
	# Connect signal from PlayerDataManager
	PlayerDataManager.data_changed.connect(determine_screen_size.bind())
	PlayerDataManager.stat_changed.connect(update_requested.bind())

	# First time setup
	update_requested()
	determine_screen_size()

func _unhandled_input(event : InputEvent) -> void:
	if not event is InputEventKey:
		return
	
	if event.keycode == KEY_F3 and event.is_pressed():
		toggle_visibility(!$ui_prop_get.visible)

func _exit_tree() -> void:
	# Disconnect signal from PlayerDataManager
	PlayerDataManager.data_changed.disconnect(determine_screen_size.bind())
	PlayerDataManager.stat_changed.disconnect(update_requested.bind())

# MAIN FUNCTION
#-------------------------------------------------------------------------------

## Ran when a UI update is requested.
func update_requested() -> void:
	update_collectibles()
	update_camera()

## Updates collectible portion of the UI.
func update_collectibles() -> void:
	%props_amount.text = "Shards x %02d" % PlayerDataManager.current_props
	%jacks_amount.text = "Jacks x %04d" % PlayerDataManager.current_jacks

## Updates health portion of the UI.
func update_health(health : int, _packet : Dictionary) -> void:
	# Set new heath
	target_health = health
	
	# Loop
	while target_health != current_health:
		# Increment
		if current_health > target_health:
			current_health += -1  
			
			# If current health is below certain threshold, switch animation
			if current_health <= 2 && hp_anim.current_animation == "normal":
				hp_anim.play("hurt")
			elif current_health > 2 && hp_anim.current_animation != "normal":
				hp_anim.play("normal")
			elif current_health == 0:
				hp_anim.play("fade")
		else: 
			current_health += 1
			hp_anim.stop()
			hp_anim.play("heal")
		
		# Update
		hp_ball.texture = _T_HEALTH[current_health]
		
		# Wait
		hp_upd_tick.start()
		await hp_upd_tick.timeout

## Updates camera portion of the UI.
func update_camera() -> void:
	pass

## Updates equipment hatch
func update_hatch(hatch : Array, equip : int) -> void:
	# Update textures
	var _tex = []
	for eq in hatch:
		_tex.append(flag_to_tex(eq))
	for index in range(equip_rect.size()):
		equip_rect[index].texture = _tex[index]
	
	# Set equip
	equip_marker.visible = false if equip == -1 else true
	equip_marker.position = Vector2(
		equip_rect[equip].position.x - 4,
		equip_rect[equip].position.y - 3
	)
	
	# Animate
	if equip_anim.is_playing():
		equip_anim.stop()
	equip_anim.play("RESET")
	equip_anim.play("switch")

## Pushes a new notification to the notification queue.
func push_notification(notif : String) -> void:
	# Add to stack
	notif_queue.append(notif)
	
	# Update
	while notif_queue.size() > 0:
		# Set text
		var text = notif_queue.pop_back() as String
		%notif_text.text = text
		
		# Animate
		notif_anim.play("appear")
		
		# Wait
		await get_tree().create_timer(5.0, false).timeout
	
	# Animate out
	notif_anim.play_backwards("appear")

## Toggle wobbly screen effect
func toggle_wobble(mode : bool = true, color : Color = Color.AQUA) -> void:
	var wobble = %ui_effect_wobbly as ColorRect
	wobble.visible = mode
	wobble.material.set("shader_parameter/tint", color)

## Toggles bars on screen
func toggle_bars(mode : bool = true) -> void:
	var bar_anim := $ui_main/svp_main/bars/bars_anim
	
	if mode && !bars_on:
		bar_anim.play("fade")
		bars_on = mode
	elif !mode && bars_on:
		bar_anim.play_backwards("fade")
		bars_on = mode

## Toggles death cutscene
func death_cutscene(area_id : int, warp_id : int) -> void:
	# Play animation
	toggle_visibility(false)
	dc_container.visible = true
	dc_anim.play("cut")
	
	# Toggle pausing
	pause_manager.can_pause = false
	
	await dc_anim.animation_finished
	
	# Restart level here
	var lm := get_tree().get_first_node_in_group("LevelManager") as LevelManager
	lm.change_subarea(
		{
			"subarea" : area_id, 
			"warp_id" : warp_id, 
			"pause" : true,
			"reload" : true,
		}
	)
	
	await lm.faded
	
	toggle_visibility(true)
	dc_container.visible = false

## Toggles visibility of UI
func toggle_visibility(mode : bool) -> void:
	$ui_prop_get.visible = mode
	%ui_container.visible = mode

## Toggles visibility of cam overlay
func toggle_cam_overlay(mode : bool) -> void:
	%cam_container.visible = mode

## Updates statistics on cam overlay
func update_cam_overlay(zoom : float = 1) -> void:
	%cam_stat.text = (
		("4:3" if screen_x == 640 else "16:9") +
		" - " +
		"Zoom: %0.1fx" % zoom
	)

# DIALOG FUNCTION
#-------------------------------------------------------------------------------

## Creates a dialog box.
func create_dialog(dialogue : DialogueResource, title : String) -> void:
	# Create new instance
	var db_instance = dialog_box.instantiate()
	%ui_container.add_child(db_instance)
	
	# Pass arguements to instance
	db_instance.start_dialog(dialogue, title, [db_instance])

# PROP GET FUNCTION
#-------------------------------------------------------------------------------

## Ran when [Player] collects [Prop].
func shard_collected(shard_data : ShardData) -> void:
	# Make main UI invisible
	%ui_main.visible = false

	# Set labels from data
	%prop_name.text = shard_data.shard_name
	%prop_location.text = shard_data.shard_location

	# Determine screen height
	var screen_size = get_tree().root.size
	screen_x = 640 if screen_size.x % 640 == 0 else 854
	%svp_prop_get.size_2d_override = Vector2i(screen_x, 480)

	# Begin animation
	%propg_anim.play("fade")

	# Gear up fade for transition
	%prop_fade.visible = true
	%prop_fade.position.y = -48
	%prop_fade.size.y = 480 + 96

	# Tween fade
	var t = get_tree().create_tween()
	t.set_parallel(true)
	t.tween_property(%prop_fade, "size:y", 480, .85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(%prop_fade, "position:y", 0, .85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.play()

## Ran when the prop collection sequence is complete.
func shard_collect_done() -> void:
	# Begin animation
	%propg_anim.play_backwards("fade")

	# Tween fade
	var t = get_tree().create_tween()
	t.set_parallel(true)
	t.tween_property(%prop_fade, "size:y", 480 + 96, .85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(%prop_fade, "position:y", -48, .85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.play()

	await t.finished

	# Make main UI visible
	%ui_main.visible = true

# MISC FUNCTION
#-------------------------------------------------------------------------------

## Sets the proper scaling for all UI components.
func determine_screen_size() -> void:
	# Get and define screen size
	var screen_size = get_tree().root.content_scale_size
	screen_x = 854 if screen_size.x % 854 == 0 else 640

	# Set viewport scales
	%svp_prop_get.size_2d_override = Vector2i(screen_x, 480)
	%svp_main.size_2d_override = Vector2i(screen_x, 480)

## Returns a texture based on equipment flag
func flag_to_tex(flag : int) -> Texture2D:
	match flag:
		PlayerData.EQUIPMENT.NONE:		return _T_EQUIP[0]
		PlayerData.EQUIPMENT.GLOVE:		return _T_EQUIP[1]
		PlayerData.EQUIPMENT.SLINGSHOT:	return _T_EQUIP[2]
		PlayerData.EQUIPMENT.HAMMER:	return _T_EQUIP[3]
		_:								return _T_EQUIP[0]
