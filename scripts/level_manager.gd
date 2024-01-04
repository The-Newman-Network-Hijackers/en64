# level_manager.gd
@icon("res://asset/editor/LevelManager.svg")
class_name LevelManager extends Node

'''
Loads, unloads and manages levels at runtime
'''

## Emitted when a level is unloaded.
signal level_unloaded()
## Emitted during the median of a screen-fade.
signal faded()

## Fallback fade length constant.
const FADE_LENGTH = 1.0
## Fallback fade delay constant.
const FADE_DELAY = 0.5

@export_category("LevelManager")

@export_group("Components")
## Path to the Player scene file
@export var scene_player : PackedScene
## Path to the UI scene file
@export var scene_ui : PackedScene

## Reference to fade out node
@onready var fade : CanvasLayer = $fade

## The current Level
var level : LevelScript
## The current [Player]
var player : Player
## The current UI
var ui : CanvasLayer #UserInterface

# PRIMARY FUNCTION
#-------------------------------------------------------------------------------

## Changes current level to another.
func change_level(path : String, packet : Dictionary = {}) -> void:
	# Evaluate packet
	var pause_manager := get_tree().get_first_node_in_group("PauseManager")
	var fade_length = packet.fade_length if packet.has("fade_length") else FADE_LENGTH
	var fade_delay = packet.fade_delay if packet.has("fade_delay") else FADE_DELAY
	var fade_type = packet.get("fade_type", 1)
	var pause = packet.get("pause", true)

	# Pause game (and disable player pausing)
	get_tree().paused = pause
	if pause_manager:		pause_manager.can_pause = false

	# Begin fade in
	fade.fade_in(fade_type, fade_length)

	# Wait for the delay
	await get_tree().create_timer(fade_length).timeout

	# Unload existing
	await unload_level()
	await get_tree().create_timer(fade_delay / 2).timeout

	# Prepare to load new level
	var new_level = load(path)
	level_unloaded.emit()
	call_deferred("load_level", new_level, packet)

	# Finish delay and fade back out
	await get_tree().create_timer(fade_delay / 2).timeout
	fade.fade_out(fade_type, fade_length)

	# Unpause
	get_tree().paused = false
	pause_manager = get_tree().get_first_node_in_group("PauseManager")
	if pause_manager:		pause_manager.can_pause = true

## Switches between subareas in a level.
func change_subarea(packet : Dictionary = {}) -> void:
	# Evaluate packet
	var pause_manager := get_tree().get_first_node_in_group("PauseManager")
	var fade_length = packet.fade_length if packet.has("fade_length") else FADE_LENGTH
	var fade_delay = packet.fade_delay if packet.has("fade_delay") else FADE_DELAY
	var fade_type = packet.get("fade_type", 1)
	var target_warp = packet.get("warp_id", -1)
	var target_area = packet.get("subarea", 0)
	var pause = packet.get("pause", true)
	var reload = packet.get("reload", false)
	
	# Pause game (and disable player pausing)
	get_tree().paused = pause
	pause_manager.can_pause = false

	# Begin fade in
	fade.fade_in(fade_type, fade_length)

	# Wait for the delay
	await get_tree().create_timer(fade_length).timeout
	await get_tree().create_timer(fade_delay / 2).timeout

	# Warp player to area
	await call_deferred(
		"load_subarea" if !reload else "reload_subarea", 
		target_area, 
		target_warp
	)
	level_unloaded.emit()
	faded.emit()

	# Finish delay and fade back out
	await get_tree().create_timer(fade_delay / 2).timeout
	fade.fade_out(fade_type, fade_length)

	# Unpause
	get_tree().paused = false
	pause_manager.can_pause = true

## Loads a level.
func load_level(scene : PackedScene, packet : Dictionary = {}) -> void:
	# Load level into scene
	var new_level : LevelScript = scene.instantiate()
	var subarea_id : int = packet.get("subarea", 0)
	var subarea = new_level.subareas[subarea_id] as Subarea
	var data = new_level.data as LevelData
	var music = new_level.subareas[subarea_id].music as Array[MusicStem]
	level = new_level
	add_child(level)
	
	# Iterate
	for area in level.subareas:
		# Check if target is subarea
		if area == subarea:
			area.process_mode = Node.PROCESS_MODE_INHERIT
			area.visible = true
			continue
		
		# Otherwise disable
		area.process_mode = Node.PROCESS_MODE_DISABLED
		area.visible = false
	
	# Load level like normal if it isn't a menu
	if !data.is_menu:
		# Create important nodes
		if ui == null: ui = create_ui(level)
		player = create_player(level, packet)
		
		# Connect signals
		var ui_manager = ui.get_node("ui_manager")
		player.connect("shard_collected", ui_manager.shard_collected.bind())
		player.connect("shard_collect_done", ui_manager.shard_collect_done.bind())
		player.connect("toggle_wobble", ui_manager.toggle_wobble.bind())
		player._equip_manager.equipment_changed.connect(ui_manager.update_hatch.bind())
		player.hurtbox_node.damaged.connect(ui_manager.update_health.bind())
		player.hurtbox_node.died.connect(ui_manager.update_health.bind())
		player.hurtbox_node.healed.connect(ui_manager.update_health.bind())
		player.death_cutscene.connect(ui_manager.death_cutscene.bind())
	
	# Load streams
	AudioManager.clean_music_pool(music)
	AudioManager.call_deferred("spawn_music_stream", music)

## Loads a subarea
func load_subarea(area_target : int, warp_target : int) -> void:
	# Load up subarea first
	var subarea = level.subareas[area_target] as Subarea
	var music = subarea.music as Array[MusicStem]
	
	# Iterate
	for area in level.subareas:
		# Check if target is subarea
		if area == subarea:
			area.process_mode = Node.PROCESS_MODE_INHERIT
			area.visible = true
			continue
		
		# Otherwise disable
		area.process_mode = Node.PROCESS_MODE_DISABLED
		area.visible = false
	
	# Next, get warp
	var warp = get_warp(warp_target)
	player.reparent(subarea, false)
	player.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT) 
	player.last_known_warp = warp_target
	player.last_known_area = area_target
	player.position = warp.global_position
	warp.player = player
	warp.process_transition()
	
	# Load streams
	AudioManager.clean_music_pool(music)
	AudioManager.call_deferred("spawn_music_stream", music)

## Reloads current subarea back to its initial state
func reload_subarea(area_target : int, warp_target : int) -> void:
	# Load up subarea first
	var subarea = level.subareas[area_target] as Subarea
	var subarea_copy = level.subareas[area_target].subarea_copy as PackedScene
	var music = subarea.music as Array[MusicStem]
	
	# Copy process, if necessary
	if subarea_copy:
		# Reparent player
		player.reparent(self, false)
		player.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED) 
		
		# Delete current
		subarea.free()
		await get_tree().process_frame
		
		# Create new instance of copy, make it current
		var instance = subarea_copy.instantiate()
		subarea = instance
		
		# Add subarea to level and reconnect
		level.add_child(subarea)
		level.subareas[area_target] = subarea
	
	# Get warp
	var warp = get_warp(warp_target)
	player.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT) 
	player.last_known_warp = warp_target
	player.last_known_area = area_target
	player.position = warp.global_position
	player.reparent(subarea)
	warp.player = player
	warp.process_transition()
	
	# Load streams
	AudioManager.clean_music_pool(music)
	AudioManager.call_deferred("spawn_music_stream", music)

## Unloads the current level.
func unload_level() -> void:
	# Queue existing level for deletion
	if level:
		level.queue_free()

	# Additional arguements go here
	pass

	# Wait a frame
	await get_tree().process_frame

## Instantiates a UI set
func create_ui(scene : LevelScript) -> CanvasLayer:
	# Spawn UI
	var ui_instance : CanvasLayer = scene_ui.instantiate()
	scene.add_child(ui_instance)

	# Return
	return ui_instance

func create_player(scene : LevelScript, packet : Dictionary = {}) -> Player:
	# Spawn player
	var p_instance : Player = scene_player.instantiate()
	var sub_id : int = packet.get("subarea", 0)
	p_instance.last_known_area = sub_id
	
	# Add weather if defined
	if scene.subareas[sub_id].weather_effect:
		scene.subareas[sub_id].weather_effect.reparent(p_instance)

	# Position player based on warp
	var id = packet.get("warp_id", -1)
	var warp = get_warp(id)
	if warp:
		p_instance.last_known_warp = id
		p_instance.position = warp.global_position
		warp.player = p_instance
		scene.subareas[sub_id].add_child(p_instance)
		warp.process_transition()

	# Return player reference
	return p_instance

# MISC FUNCTION
#-------------------------------------------------------------------------------

## Plays the fade animation based on provided arguements.
func fade_screen(packet : Dictionary = {}) -> void:
	# Determine variables
	var fade_length = packet.fade_length if packet.has("fade_length") else FADE_LENGTH
	var fade_delay = packet.fade_delay if packet.has("fade_delay") else FADE_DELAY
	var fade_type = packet.get("fade_type", 0)

	# Fade in
	fade.fade_in(fade_type, fade_length)

	# Wait for length + delay
	await get_tree().create_timer(fade_length + fade_delay).timeout
	faded.emit()

	# Fade out
	fade.fade_out(fade_type, fade_length)

## Grabs a reference of a target [WarpPoint]
func get_warp(id : int = -1) -> WarpPoint:
	var warps = get_tree().get_nodes_in_group("Warp")

	for warp in warps:
		if warp is WarpPoint:
			if !warp.is_visible_in_tree():
				continue
			if warp.id == id:
				return warp
		else:
			continue

	return null
