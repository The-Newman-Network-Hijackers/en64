# level_selector.gd
extends MarginContainer

'''
Loads levels from project files and lets you load them.
'''

## Base level directory
const LEVEL_DIR = "res://scenes/level/"
## Base scene directory
const SCENE_DIR = "res://scenes/"
## BBCode formatting
const FORMAT = [
	"[color=gray][font_size=19]",
	"[/font_size][/color]"
]

## Reference to level preview thread
@onready var level_preview = $ls_level_preview as LevelPreview
## Reference to level tree
@onready var level_tree = $panel/margin/horiz_split/level_sort/levels
## Reference to preview texture
@onready var preview_vp = $panel/margin/horiz_split/detail_sort/preview/vp_preview
## Reference to level name
@onready var level_name = $panel/margin/horiz_split/detail_sort/preview/vp_preview/overlay/margin/name
## Reference to info section
@onready var info = $panel/margin/horiz_split/detail_sort/info
## Reference to warning section
@onready var warning = $panel/margin/horiz_split/detail_sort/warning
## Reference to area dropdown
@onready var area_dropdown = $panel/margin/horiz_split/detail_sort/area
## Reference to load button
@onready var load_button = $panel/margin/horiz_split/detail_sort/load

## Level marker texture
@onready var _lm_tex = preload("res://asset/ui/debug_ls/ls_level_marker.png")

## Current selected path
var selected_path : String = ""

func _ready() -> void:
	# Connect signals
	level_preview.loading_complete.connect(_l_preview_loaded.bind())
	
	# Begin getting all levels and building tree
	var tree_root : TreeItem = level_tree.create_item()
	tree_root.set_text(0, "level")
	get_all_levels(LEVEL_DIR, tree_root)

func _input(event: InputEvent) -> void:
	# If we press accept in tree...
	if event.is_action_released("ui_accept") && level_tree.has_focus():
		# Set focus to load
		load_button.grab_focus()
	
	# If we press back in load...
	if event.is_action_pressed("ui_cancel") && load_button.has_focus():
		# Set focus to tree
		level_tree.grab_focus()

# FUNCTION
#-------------------------------------------------------------------------------

## Gets all levels in level directory, recursively
func get_all_levels(dir : String, tree_parent : TreeItem) -> void:
	# Open up directory
	var directory = DirAccess.open(dir)
	
	# Look for files or other directories
	if directory:
		directory.list_dir_begin()
		var f_name = directory.get_next()
		
		# Begin iterating
		while f_name != "":
			# If we've hit a directory, search
			if directory.current_is_dir():
				# Create new tree node
				var t_dir = tree_parent.create_child()
				t_dir.set_text(0, f_name)
				
				# Recursively iterate on that directory
				await get_all_levels(dir + "/" + f_name, t_dir)
			
			# We've hit a file, create a new entry and add to level paths
			else:
				if f_name.ends_with(".remap"):
					f_name = f_name.trim_suffix(".remap")
				
				# Skip if marked as an area
				if f_name.begins_with("area"):
					f_name = directory.get_next()
					continue
				
				var t_file = tree_parent.create_child()
				t_file.set_text(0, f_name)
				t_file.set_icon(0, _lm_tex)
				
			# Get next
			f_name = directory.get_next()

## Loads a level based on string
func load_level(path : String) -> void:
	# Get level manager
	var current_scene = get_tree().current_scene
	var l_m = current_scene.level_manager as LevelManager
	
	# Transition
	l_m.change_level(
		path,
		{"fade_length" : .75, "fade_delay" : 0.25, "warp_id" : -1, "subarea" : int(area_dropdown.get_selected_id())}
	)

## Calls to load preview based on selection
func load_preview(path : String) -> void:
	level_preview.request_level(path)

## Toggles warning.
func toggle_warning(on : bool) -> void:
	preview_vp.get_parent().visible = !on
	info.visible = !on
	warning.visible = on

## Changes warning to show if the level is loading
func toggle_loading_warning(on : bool) -> void:
	warning.text = (
		"Loading..."
		if on else
		"Select a level from the\ntree to continue."
	)

# SIGNAL
#-------------------------------------------------------------------------------

func _back_pressed() -> void:
	pass # Replace with function body.

func _on_load_pressed() -> void:
	load_level(selected_path)

func _l_preview_loaded(level : Node) -> void:
	# Detoggle warning
	toggle_loading_warning(false)
	toggle_warning(false)
	
	# Add level itself to VP
	level.process_mode = Node.PROCESS_MODE_DISABLED
	level = level as LevelScript
	preview_vp.add_child(level)
	
	
	# Get data from level
	var l_data = level.data
	level_name.text = l_data.level_name
	info.text = (
		FORMAT[0] + "Level Directory" + FORMAT[1] + "\n" +
		"~" + level.scene_file_path.erase(0, 12) + "\n\n" +
		FORMAT[0] + "Level Description" + FORMAT[1] + "\n" +
		l_data.level_desc
	)
	
	# Get areas from level
	var l_area = level.subareas.size()
	area_dropdown.clear()
	for area in range(l_area):
		area_dropdown.add_item("Area " + str(area), area)

func _level_selected() -> void:
	# Declare variables
	var selection = level_tree.get_selected() as TreeItem
	var parents : Array[TreeItem] = []
	var parent : TreeItem = selection
	var path : String = ""
	
	# Check if selection ends in tscn
	if !selection.get_text(0).ends_with(".tscn"):
		level_preview.unload_level()
		toggle_loading_warning(false)
		toggle_warning(true)
		return
	
	# Get parent items
	while parent != null:
		parent = parent.get_parent()
		if parent == null:
			break
		parents.push_front(parent)
	
	# Create path from there
	path = SCENE_DIR
	for p in parents:
		var f_name = p.get_text(0)
		path += f_name + "/"
	path += selection.get_text(0)
	selected_path = path
	
	# Load preview
	toggle_loading_warning(true)
	toggle_warning(true)
	load_preview(selected_path)
