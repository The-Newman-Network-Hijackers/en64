# ui_customization.gd
extends HBoxContainer

'''
Manages the customization UI.
'''

enum Categories {
	Head = 1 << 0,
	Face = 1 << 1,
	Body = 1 << 2
}

## Reference to [PlayerVisualManager]
@onready var pvm := %visual_manager as PlayerVisualManager
## Reference to back button
@onready var back : Button = %back
## Reference to render viewport
@onready var vp_render : Viewport = $render
## Reference to render [PlayerVisualManager].
@onready var vp_pvm := $render/visual_manager as PlayerVisualManager
## Reference to costume name
@onready var cs_name : LineEdit = $tabs/Costumes/margin/v_sort/options/costume_name
## Reference to thumbnail generator
@onready var tb_gen := $thumbnail_gen
## Reference to costume rename window
@onready var cr_win := $debug/rename_window

## The current category.
var category : int = Categories.Head
## Costume ID intended to be renamed (cr_win)
var cr_id : int = 0
## Target name to change cr_id to (cr_win)
var cr_name : String = ""

func _ready() -> void:
	# Initialize
	%category.grab_focus()

	# Connect signal
	back.pressed.connect(back_pressed.bind())
	
	# Generate lists
	create_accessory_list()

## Exits out of menu.
func back_pressed() -> void:
	# Save menu
	var player_data : PlayerData = pvm.player_data
	PlayerDataManager.save_data(player_data)
	
	# Leave
	queue_free()

# ACCESSORY LIST FUNCTION
#-------------------------------------------------------------------------------

## Creates a list of items based on current category
func create_accessory_list() -> void:
	# Declare variables
	var player_data : PlayerData = pvm.player_data
	var owned_accessories = player_data.owned_accessories

	# Ensure list is cleared first
	clear_accessory_list()

	# Set button group
	%entry.button_group.allow_unpress = true

	# Iterate and create buttons for each accessory
	for id in owned_accessories:
		# Get accessory from LUT
		var accessory : AccessoryData = pvm._acc_lut[id]
		
		# Compare flags
		if !(accessory.type & category):
			continue

		# Create button
		var new_entry : Button = %entry.duplicate()

		# Set as toggled if equipped
		new_entry.button_pressed = (
			true if accessory == player_data.accessories[cat_to_str()] else false
		)

		# Configure button
		new_entry.visible = true
		new_entry.data = accessory
		new_entry.icon = accessory.icon
		new_entry.modulate = accessory.icon_modulation
		new_entry.name = accessory.name.to_lower().replace(" ", "_")

		# Toggle button if

		# Connect signal
		new_entry.entry_selected.connect(accessory_selected.bind())
		new_entry.entry_focused.connect(accessory_focused.bind())

		# Add to list
		%items.add_child(new_entry)

## Removes all items inside of accessory list
func clear_accessory_list() -> void:
	for child in %items.get_children():
		if child.name != "entry":
			child.queue_free()

# COSTUME LIST FUNCITON
#-------------------------------------------------------------------------------

## Creates a list of costumes based on player data
func create_costume_list(textures : Array[Texture2D]) -> void:
	# Declare variables
	var player_data : PlayerData = pvm.player_data
	var costumes : Dictionary = player_data.costumes
	
	# Clear existing
	clear_costume_list()
	
	# Iterate through costumes
	var index := 0
	for key in costumes.values():
		# Skip if not dict
		if not key is Dictionary:
			continue
		
		# Create entry
		var c_entry = %costume_entry.duplicate()
		var ce_button = c_entry.get_node("costume") as Button
		c_entry.id = key.id
		c_entry.pvm = pvm
		c_entry.visible = true
		
		ce_button.icon = textures[index]
		ce_button.text = key.name
		
		# Add to scene
		%costume_entries.add_child(c_entry)
		c_entry.set_owner(self)
		
		# Increment index
		index += 1
	
	# Set count
	%costume_count.text = "Slots : " + str(costumes.count) + " / 24"
	
	# Let user save again
	%save.disabled = false

## Removes all items inside of costume list
func clear_costume_list() -> void:
	# Iterate and clear
	for child in %costume_entries.get_children():
		if child.name != "costume_entry":
			child.queue_free()

## Saves current outfit to data.
func save_costume() -> void:
	# Disable saving for now
	%save.disabled = true
	
	# Save costume and rebuild
	pvm.save_costume(%costume_name.text if %costume_name.text != "" else "Some kind of costume")
	tb_gen.generate_thumbnails()

# ENTRY FUNCTION
#-------------------------------------------------------------------------------

## Called when an accessory entry is selected, forwards data to visual manager
func accessory_selected(node : Button) -> void:
	# Update entry
	pvm.set_outfit(cat_to_str(), node.data if node.button_pressed else null)

	# Update visual
	pvm.load_outfit()

## Called when an entry is focused.
func accessory_focused(node : Button) -> void:
	# Determine data type
	var data = node.data

	if data is AccessoryData: # Accessory data
		%name.text = data.name
		%description.text = data.description

	else: # Color data
		%name.text = data[1]
		%description.text = data[2]

## Returns the string equivalent of the current category
func cat_to_str() -> String:
	match category:
		0:	return "skin"
		1:	return "head"
		2:	return "face"
		4:	return "torso"
		_:	return ""

func _newman_color_item_selected(index: int) -> void:
	pvm.set_color(0, index)
	pvm.load_outfit()

func _primary_color_item_selected(index: int) -> void:
	pvm.set_color(1, index)
	pvm.load_outfit()

func _secondary_color_item_selected(index: int) -> void:
	pvm.set_color(2, index)
	pvm.load_outfit()

# CATEGORY FUNCTION
#-------------------------------------------------------------------------------

func category_item_selected(index: int) -> void:
	# Declare variables
	var tw = create_tween()
	var cam : Camera3D = %camera
	var cam_pos : Node = %cam_pos
	var target : Vector3

	# Set category and camera target
	match index:
		0: # Head
			category = Categories.Head
			target = cam_pos.get_node("head").global_position
		1: # Face
			category = Categories.Face
			target = cam_pos.get_node("face").global_position
		2: # Body
			category = Categories.Body
			target = cam_pos.get_node("body").global_position

	# Tween camera
	tw.tween_property(cam, "global_position", target, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	create_accessory_list()

func _tab_changed(_tab: int) -> void:
	# Declare variables
	var tw = create_tween()
	var cam : Camera3D = %camera
	var cam_pos : Node = %cam_pos
	var target : Vector3
	
	# Set camera target
	target = cam_pos.get_node("skin").global_position
	
	# Tween camera
	tw.tween_property(cam, "global_position", target, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# WINDOW FUNCTION
#-------------------------------------------------------------------------------

func show_window(id : int) -> void:
	# Get costume information
	var player_data : PlayerData = pvm.player_data
	var costumes : Dictionary = player_data.costumes
	var costume = costumes.get(id, null)
	
	# Fluke if costume isnt found
	if !costume:
		push_error("No costume found of ID " + str(id))
		return
	
	# Reset field
	cr_id = id
	cr_win.get_node("margin/sort/name_input").text = ""
	cr_win.get_node("margin/sort/prompt").text = (
		"Change costume \"%s\" to..." % costume.name
	)
	
	# Show window
	cr_win.show()

func name_changed() -> void:
	# Get costume information
	var player_data : PlayerData = pvm.player_data
	var costumes : Dictionary = player_data.costumes
	var costume = costumes.get(cr_id, null)
	
	# Fluke if costume isnt found
	if !costume:
		push_error("No costume found of ID " + str(cr_id))
		return
	
	# Set name and hide window
	costume.name = cr_name
	cr_win.hide()
	
	# Refresh list
	tb_gen.generate_thumbnails()

func name_input_changed(new_text : String) -> void:
	cr_name = new_text if new_text != "" else "Some kind of costume"

func close_window() -> void:
	cr_win.hide()
