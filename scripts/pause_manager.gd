# pause_manager.gd
class_name PauseManager extends Node

'''
Pause UI manager.
'''

## Path to character customization
const CMENU_PATH = "res://scenes/ui_customization.tscn"

## Reference to parent pause gui
@onready var pause : MarginContainer = %pause

## Reference to level manager
@onready var lm : LevelManager = get_tree().current_scene.level_manager

## Determines if the game is currently paused or not
var is_paused : bool = false
## Determines if the game can be paused.
var can_pause : bool = true

func _ready() -> void:
	# Make sure pause menu is not visible
	pause.visible = false

	# Grab mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# Check for escape key
	if event.is_action_pressed("pause"):
		# Stop if cant pause
		if !can_pause:
			return

		# Pause
		toggle_pause()

# FUNCTION
#-------------------------------------------------------------------------------

## Manages pause event
func toggle_pause() -> void:
	# Flip variables
	is_paused = not is_paused
	get_tree().paused = not get_tree().paused

	# Toggle visibility
	pause.visible = is_paused

	# Toggle mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if !is_paused else Input.MOUSE_MODE_VISIBLE

	# Set focus
	if pause.visible:
		%unpause.grab_focus()

# SIGNAL
#-------------------------------------------------------------------------------

## Unpause button pressed.
func _unpause_pressed() -> void:
	# Toggle pause
	toggle_pause()

## Character button pressed.
func _on_character_pressed() -> void:
	# Instantiate character menu
	var menu = load(CMENU_PATH)
	menu = menu.instantiate()
	%pause.add_child(menu)

	# Set pause mode of root menu
	%root_menu.process_mode = PROCESS_MODE_DISABLED

	# Connect signal
	menu.back.pressed.connect(func():
		%unpause.grab_focus()
		%root_menu.process_mode = PROCESS_MODE_WHEN_PAUSED
		lm.player._vis_manager.load_outfit()
	)

func _on_logbook_pressed() -> void:
	# Switch to option menu
	%root_menu.visible = false
	%logbook_menu.visible = true

	# Prepare menu
	%logbook_menu.generate_list()
	%logbook_menu.determine_progress()

	# Set pause mode of root menu
	%root_menu.process_mode = Node.PROCESS_MODE_DISABLED

	# Grab focus
	$pause/logbook_menu/list_panel/margin/prop_list/sort.grab_focus()

func _option_pressed() -> void:
	# Switch to option menu
	%root_menu.visible = false
	%options_menu.visible = true

	# Set pause mode of root menu
	%root_menu.process_mode = Node.PROCESS_MODE_DISABLED

	# Set tab
	var tabs : TabContainer = %options_menu.get_node("tabs")
	tabs.current_tab = 0
	%options_menu.get_node("tabs/General/v_sort/debug_draw_input/debug_draw").grab_focus()

func _options_back_pressed() -> void:
	# Switch to root menu
	%root_menu.visible = true
	%options_menu.visible = false

	# Set pause mode of root menu
	%root_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Grab focus
	%unpause.grab_focus()

func _logbook_back_pressed() -> void:
	# Switch to root menu
	%root_menu.visible = true
	%logbook_menu.visible = false

	# Set pause mode of root menu
	%root_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Grab focus
	%unpause.grab_focus()

func _leave_pressed():
	# Call to LevelManager
	lm.change_level("res://scenes/menu/main_menu.tscn")
	
	# Pause self
	%root_menu.process_mode = Node.PROCESS_MODE_DISABLED
