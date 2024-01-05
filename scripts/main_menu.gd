# main_menu.gd
extends CanvasLayer

'''
Main menu script.
'''

## Reference to level_manager
@onready var level_manager : LevelManager = get_tree().current_scene.level_manager

## Player data.
var data : PlayerData

func _ready() -> void:
	# Set focus to ready
	%start_test.grab_focus()
	
	# Set version
	%version.text = %version.text % get_tree().current_scene.ver
	
	# Generate prompts
	generate_prompts()

# FUNCTION
#-------------------------------------------------------------------------------

## Generates input prompts.
func generate_prompts() -> void:
	var prompt1 = InputPrompt.new()
	prompt1.input = [&"up", &"left", &"down", &"right"] as Array[StringName]
	prompt1.render_as_analog = true
	prompt1.message = "Navigate"
	
	var prompt2 = InputPrompt.new()
	prompt2.input = [&"jump"] as Array[StringName]
	prompt2.render_as_analog = false
	prompt2.message = "Confirm"
	
	var list = [prompt1, prompt2] as Array[InputPrompt]
	%prompt_container.queue = list

# SIGNALS LAYER 1
#-------------------------------------------------------------------------------

func _start_pressed() -> void:
	# Switch menu
	%root_menu.visible = false
	%level_selector.visible = true

	# Grab focus
	var tree = $sort/menu/center_container/level_selector/panel/margin/horiz_split/level_sort/levels
	tree.grab_focus()

func _multiplayer_pressed() -> void:
	# Switch menu
	%root_menu.visible = false
	%multiplayer_menu.visible = true

	# Grab focus
	var host = %multiplayer_menu.get_node("mp_buttons/host")
	host.grab_focus()

func _option_pressed() -> void:
	# Switch menu
	%root_menu.visible = false
	%options_menu.visible = true

	# Set tab
	var tabs : TabContainer = %options_menu.get_node("tabs")
	tabs.current_tab = 0

func _exit_pressed() -> void:
	# Close game
	get_tree().quit()

# SIGNALS LAYER 2
#-------------------------------------------------------------------------------

func _host_pressed() -> void:
	pass # Replace with function body.

func _join_pressed() -> void:
	pass # Replace with function body.

func _mpback_pressed() -> void:
	# Switch menu
	%multiplayer_menu.visible = false
	%root_menu.visible = true

	# Grab focus
	%start_test.grab_focus()

# SIGNALS LAYER 3
#-------------------------------------------------------------------------------

func _option_back_pressed() -> void:
	# Switch menu
	%options_menu.visible = false
	%root_menu.visible = true

	# Grab focus
	%start_test.grab_focus()

# SIGNALS LAYER 4
#-------------------------------------------------------------------------------

func _ls_back_pressed() -> void:
	# Switch menu
	%level_selector.visible = false
	%root_menu.visible = true
	
	# Grab focus
	%start_test.grab_focus()
