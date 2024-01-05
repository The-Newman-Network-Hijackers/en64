# player_data_manager.gd
extends Node

'''
Manages loading and saving of PlayerData.
'''

## The default save path.
const PATH = "user://data.tres"
## The backup save path.
const BK_PATH = "user://data_backup{date}.tres"
## Path to [Jack] soundeffect.
const JSFX_PATH = "res://audio/sfx/collect_jack.wav"
## Base multiplicatives of resolution
const BASE_RES = [
	Vector2i(640, 480),
	Vector2i(854, 480)
]

## Fired whenever data is updated
signal data_changed()
## Fired whenever data has been successfully verified
signal data_verified(data : PlayerData)
## Fired whenever statistic data is changed
signal stat_changed()

## The player's current total amount of [Jack]s collected.
var current_jacks : int = 0 :
	set(value) : current_jacks = value; stat_changed.emit()
	get : return current_jacks

## The player's total amount of props collected.
var current_props : int = 0 :
	set(value) : current_props = value; stat_changed.emit()
	get : return current_props

## The player's list of collected props.
var current_prop_list : Array[int] = [] :
	set(value) :
		current_prop_list = value
		current_props = current_prop_list.size()
		stat_changed.emit()
	get : return current_prop_list

func _enter_tree() -> void:
	# Load up data and set temporary values
	var data = await load_data()
	set("current_jacks", data.jacks)
	set("current_props", data.props)
	set("current_prop_list", data.prop_list)

func _exit_tree() -> void:
	# Attempt to save data to disk
	var data = load_data()
	data.jacks = current_jacks
	data.props = current_props
	data.prop_list = current_prop_list
	save_data(data)

# FUNCTION
#-------------------------------------------------------------------------------

# Loads player data. Creates a new file if one doesnt exist.
func load_data() -> PlayerData:
	# If PlayerData file doesnt exist, make one
	if !ResourceLoader.exists(PATH) || !ResourceLoader.load(PATH):
		# Create variables
		var data : PlayerData = PlayerData.new()

		# Set some starting info
		randomize(); data.config.multiplayer.name = "guest-" + str(randi_range(0,9999))
		data.ver = ProjectSettings.get_setting("application/config/version")
		
		# Save resource and return
		save_data(data, PATH)
		return data

	# Else, just load
	var data = ResourceLoader.load(PATH) as PlayerData
	return data

# Saves player data.
func save_data(data : PlayerData, path : String = PATH) -> void:
	ResourceSaver.save(data, path)
	data_changed.emit()

# Deletes current save data.
func delete_data() -> void:
	current_jacks = 0
	current_props = 0
	current_prop_list = []
	var res = DirAccess.remove_absolute(PATH)
	print(res)

## Verifies that all keys are present in a [PlayerData] resource.
func verify_data(data : PlayerData) -> void:
	# Get base data
	var base : PlayerData = PlayerData.new()

	# Check version
	#if data.ver != get_tree().current_scene.ver:
		# Throw up window
	#	show_bvwindow(data)
	#	return

	# Iterate through base and compare
	for cat_key in base.config:
		# If our data has key, continue
		if data.config.get(cat_key) != null:
			for key in base.config[cat_key]:
				if data.config[cat_key].get(key) != null:
					continue
				else:
					data.config[cat_key][key] = base.config[cat_key][key]
			continue

		# Otherwise, populate our data with key and value
		data.config[cat_key] = base.config[cat_key]
	
	# Return new resource
	data_verified.emit(data)

# Updates game based on config
func config_update(data : PlayerData) -> void:
	if !data:
		return
		
	config_general_update(data)
	config_video_update(data)

## Updates general config options
func config_general_update(data : PlayerData) -> void:
	# Update debug draw
	DebugDraw3D.debug_enabled = data.config.video.debug
	DebugDraw2D.debug_enabled = data.config.video.debug
	
	# Set input
	InputManager.current_device = data.config.input.input_preference as InputManager.Device
	InputManager.use_automatic = true if data.config.input.input_preference == -1 else false
	
	# Set audio
	var volumes = [
		lerp(-40, 4, data.config.audio.music_volume),
		lerp(-40, 4, data.config.audio.ambient_volume),
		lerp(-40, 4, data.config.audio.sfx_volume)
	]
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), volumes[0] if volumes[0] != -40 else -80)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambiance"), volumes[1] if volumes[1] != -40 else -80)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), volumes[2] if volumes[2] != -40 else -80)

## Updates video specific config options
func config_video_update(data : PlayerData) -> void:
	# Update parameters
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if data.config.video.vsync else
		DisplayServer.VSYNC_DISABLED
	)
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if data.config.video.fullscreen else
		DisplayServer.WINDOW_MODE_WINDOWED
	)
	DisplayServer.window_set_flag(
		DisplayServer.WINDOW_FLAG_BORDERLESS,
		data.config.video.fullscreen
	)
	
	# Set buffers
	var nroot := get_tree().current_scene
	var db_mat := nroot.buf_dither.get_node("color_rect").material as ShaderMaterial
	var nb_mat := nroot.buf_ntsc.get_node("color_rect").material as ShaderMaterial
	var fc_mat := nroot.fade_circle.material as ShaderMaterial
	
	nroot.buf_dither.visible = data.config.video.dithering
	nroot.buf_dither.scale = data.config.video.resolution * 0.01
	nroot.buf_dither.position = data.config.video.resolution / 2
	db_mat.set_shader_parameter("SCREEN_WIDTH", data.config.video.resolution.x)
	
	nroot.buf_ntsc.visible = data.config.video.ntsc
	nroot.buf_ntsc.scale = data.config.video.resolution * 0.01
	nroot.buf_ntsc.position = data.config.video.resolution / 2
	nb_mat.set_shader_parameter("SCREEN_SIZE", data.config.video.resolution)
	
	fc_mat.set_shader_parameter("SCREEN_SIZE", data.config.video.resolution)
	
	# Set resolution
	DisplayServer.window_set_size(data.config.video.resolution)
	get_tree().root.set_content_scale_size(data.config.video.resolution)

	# Reposition
	#var screen = DisplayServer.get_primary_screen()
	#var monitor_resolution = DisplayServer.screen_get_size(DisplayServer.get_primary_screen())
	#DisplayServer.window_set_position(
	#	Vector2i(
	#		monitor_resolution.x / 2 - data.config.video.resolution.x / 2,
	#		monitor_resolution.y / 2 - data.config.video.resolution.y / 2
	#	) + Vector2i(monitor_resolution.x * screen, 0)
	#)

# MISC FUNCTION
#-------------------------------------------------------------------------------

## Adds any new prop to player's inventory.
func add_shard(id : int) -> bool:
	# Verify that prop isnt already in inventory
	for shard in current_prop_list:
		if shard == id:
			return false

	# Append and approve
	var copy = current_prop_list.duplicate()
	copy.append(id)
	current_prop_list = copy
	stat_changed.emit()
	return true

## Adds a defined amount of Jacks in increments.
func add_jacks(count : int) -> void:
	var remainder = count
	var sfx = load(JSFX_PATH)

	while remainder > 0:
		# Increment
		current_jacks += 1
		remainder -= 1

		# Sound effect
		AudioManager.spawn_sound_stream(sfx, randf_range(0.95, 1.05))
		await get_tree().create_timer(0.075).timeout

## Ran when save is wiped from bad version diag
func accept_bvwindow():
	# Hide window
	$bad_version.hide()
	
	# Backup save
	var data := load_data()
	var path := BK_PATH.format({"date" : Time.get_datetime_string_from_system()})
	save_data(data, path)
	
	# Delete save
	delete_data()
	
	# Restart scene
	request_ready()
	get_tree().reload_current_scene()
	

## Ran when bad version window is about to popup
func show_bvwindow(data : PlayerData) -> void:
	# Set text
	var text_ver = $bad_version/margin/v_box_container/version as Label
	text_ver.text = text_ver.text % [data.ver if data.ver else "unknown", get_tree().current_scene.ver]
	
	# Pause game
	get_tree().paused = true
	
	# Show window
	$bad_version.popup()
