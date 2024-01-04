# ui_options.gd
extends VBoxContainer

'''
Handles options and configuration.
'''

## The player's data.
var data : PlayerData

func _ready() -> void:
	# Initialize
	load_data()
	
	# Set version
	%version.text = %version.text % get_tree().current_scene.ver

# SIGNAL FUNCTIONS
#-------------------------------------------------------------------------------

func _resolution_selected(index: int) -> void:
	# Set resolution
	match index:
		0: # (640, 480)
			data.config.video.resolution = Vector2i(640, 480)
		1: # (640, 480)
			data.config.video.resolution = Vector2i(854, 480)
		2: # (1280, 960)
			data.config.video.resolution = Vector2i(1280, 960)
		3: # (1708, 960)
			data.config.video.resolution = Vector2i(1708, 960)

	# Update
	set_extra_availability(check_extra_availability())
	PlayerDataManager.config_update(data)

func _fullscreen_toggled(button_pressed: bool) -> void:
	data.config.video.fullscreen = button_pressed
	PlayerDataManager.config_update(data)

func _vsync_toggled(button_pressed: bool) -> void:
	data.config.video.vsync = button_pressed
	PlayerDataManager.config_update(data)

func _dithering_toggled(button_pressed: bool) -> void:
	data.config.video.dithering = button_pressed
	PlayerDataManager.config_update(data)

func _ntsc_toggled(button_pressed: bool) -> void:
	data.config.video.ntsc = button_pressed
	PlayerDataManager.config_update(data)

func _name_text_changed(new_text: String) -> void:
	data.config.multiplayer.name = new_text

func _clear_data_pressed() -> void:
	# Open sub window
	%clear_subwindow.show()
	%clear_subwindow.get_node("m/vsort/buttons/decline").grab_focus()

func _debug_draw_toggled(button_pressed: bool) -> void:
	data.config.video.debug = button_pressed
	PlayerDataManager.config_update(data)

func _option_back_pressed() -> void:
	# Save data
	PlayerDataManager.save_data(data)

func _clear_subwindow_confirmed() -> void:
	# Clear data
	@warning_ignore("redundant_await")
	await PlayerDataManager.delete_data()

	# Reload
	var lm := get_tree().get_first_node_in_group("LevelManager") as LevelManager
	lm.change_level("res://scenes/splash.tscn", {"fade_length" : 0.0, "fade_delay" : 0.0})

func _cpd_back() -> void:
	%clear_subwindow.hide()

func _camera_sensitivity_value_changed(value: float) -> void:
	# Update value in config
	data.config.input.sensitivity = value

	# Update display
	var display : Label = %camera_sensitivity_value
	display.text = str(value * 100, "%")

func _input_preference_item_selected(index: int) -> void:
	# Update value in config
	data.config.input.input_preference = index - 1
	PlayerDataManager.config_general_update(data)

func _on_music_volume_value_changed(value: float) -> void:
	# Update value in config
	data.config.audio.music_volume = value
	PlayerDataManager.config_general_update(data)
	
	# Update display
	var display : Label = %music_volume_value
	display.text = str(value * 100, "%")

func _on_ambient_volume_value_changed(value: float) -> void:
	# Update value in config
	data.config.audio.ambient_volume = value
	PlayerDataManager.config_general_update(data)

	# Update display
	var display : Label = %ambient_volume_value
	display.text = str(value * 100, "%")

func _on_sfx_volume_value_changed(value: float) -> void:
	# Update value in config
	data.config.audio.sfx_volume = value
	PlayerDataManager.config_general_update(data)

	# Update display
	var display : Label = %sfx_volume_value
	display.text = str(value * 100, "%")

func _camera_preference_selected(index: int) -> void:
	# Update value in config
	data.config.input.cam_mode = index
	PlayerDataManager.config_general_update(data)

func _invert_x_toggled(button_pressed: bool) -> void:
	data.config.input.invert_cam_x = button_pressed
	PlayerDataManager.config_update(data)

func _invert_y_toggled(button_pressed: bool) -> void:
	data.config.video.invert_cam_y = button_pressed
	PlayerDataManager.config_update(data)

# GENERAL FUNCTION
#-------------------------------------------------------------------------------

## Loads up configuration data and prepares menus.
func load_data() -> void:
	# Load up parameters
	data = PlayerDataManager.load_data()
	PlayerDataManager.call_deferred("verify_data", data)
	data = await PlayerDataManager.data_verified
	PlayerDataManager.config_update(data)

	# Set fields
	%fullscreen.button_pressed = data.config.video.fullscreen
	%vsync.button_pressed = data.config.video.vsync
	%debug_draw.button_pressed = data.config.video.debug
	%dithering.button_pressed = data.config.video.dithering
	%ntsc.button_pressed = data.config.video.ntsc
	%name.text = data.config.multiplayer.name
	%resolution.selected = resolution_to_id(data.config.video.resolution)
	%camera_sensitivity.value = data.config.input.sensitivity
	%camera_sensitivity_value.text = str(data.config.input.sensitivity * 100, "%")
	%music_volume.value = data.config.audio.music_volume
	%music_volume_value.text = str(data.config.audio.music_volume * 100, "%")
	%ambient_volume.value = data.config.audio.ambient_volume
	%ambient_volume_value.text = str(data.config.audio.ambient_volume * 100, "%")
	%sfx_volume.value = data.config.audio.sfx_volume
	%sfx_volume_value.text = str(data.config.audio.sfx_volume * 100, "%")
	%input_preference.selected = data.config.input.input_preference + 1
	%camera_preference.selected = data.config.input.cam_mode
	%invert_x.button_pressed = data.config.input.invert_cam_x
	%invert_y.button_pressed = data.config.input.invert_cam_y
	set_extra_availability(check_extra_availability())

## Converts resolution data to resolution selection id
func resolution_to_id(resolution : Vector2i) -> int:
	match resolution:
		Vector2i(640, 480):
			return 0
		Vector2i(854, 480):
			return 1
		Vector2i(1280, 960):
			return 2
		Vector2i(1708, 960):
			return 3
	# Return -1 if error
	return -1

## Returns first UI element in tab.
func get_first_element(id : int) -> Control:
	match id:
		0:
			return %name
		1:
			return %resolution
		2:
			return %music_volume
		3:
			return %input_preference
		_:
			return %option_back

## Checks to see if extra video settings are available
## based on resolution selected.
func check_extra_availability() -> bool:
	var resolution = data.config.video.resolution
	if resolution.y / 480 > 1:
		return false
	return true

## Sets availability of extra video settings.
func set_extra_availability(mode : bool) -> void:
	# Toggles
	%dithering.disabled = !mode
	%dithering.button_pressed = false if !mode else %dithering.button_pressed
	%ntsc.disabled = !mode
	%ntsc.button_pressed = false if !mode else %ntsc.button_pressed
	
	# Modulation 
	%dithering_input.modulate = Color.DARK_GRAY if !mode else Color.WHITE
	%ntsc_input.modulate = Color.DARK_GRAY if !mode else Color.WHITE
	data.config.video.dithering = false if !mode else data.config.video.dithering
	data.config.video.ntsc = false if !mode else data.config.video.ntsc
	
	# Text
	%extra_div.text = (
		"Extra Video Settings only available at lower resolutions!"
		if !mode else
		"Extra Video Settings"
	)
	
