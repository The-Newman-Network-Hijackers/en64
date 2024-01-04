# prop_logger.gd
extends HBoxContainer

'''
Shows all props in the game and information related to them.
'''

## Prop data directory.
const PDAT_PATH = "res://data/props/"

## Categories
enum Category {
	All,
	Collected,
	Not_Collected,
}

## Reference to Prop scene.
@onready var prop_instance = preload("res://scenes/prefab/shard.tscn")
## Reference to list container.
@onready var list : ItemList = $list_panel/margin/prop_list/scroll/list
## Reference to prop viewport
@onready var svp_prop : SubViewport = $prop_desc/prop_model/svp_prop


## List of props in game.
var all_props : Array[ShardData] = []
## List of player collected props
var player_props : Array[int] = []
## List of current props in list
var list_props : Array[ShardData] = []
## Determines what props the player owns.
var ownership_index : Array[bool] = []
## The current category
var category = Category.All
## Reference to current prop in viewport
var c_prop : Shard = null

func _ready() -> void:
	# Get a list of every prop
	all_props = LUTShard.shard
	player_props = PlayerDataManager.current_prop_list

	# Fill in list based on category
	generate_list()
	determine_progress()

# FUNCTION
#-------------------------------------------------------------------------------

## Generates contents of [ItemList] based on props
func generate_list() -> void:
	# Define variables
	var count : int = 0

	# Clear lists
	list.clear()
	list_props.clear()
	ownership_index.clear()

	match category:
		Category.Collected: # Collected
			# Show only collected props
			for prop in LUTShard.shard:
				# Increase count
				count += 1
				var identifier = str(count) + ". "
				
				# Check if prop is not in players
				if not count-1 in player_props:
					continue
				
				# Add to list
				list.add_item(identifier + prop.shard_name)
				list_props.append(prop)
				ownership_index.append(true)

		Category.Not_Collected: # Not Collected
			# Show non collected props
			for prop in LUTShard.shard:
				# Increase count
				count += 1
				var identifier = str(count) + ". "

				# Check if prop is in player's
				if count-1 in player_props:
					continue
				
				list.add_item(identifier + "???")
				list_props.append(prop)
				ownership_index.append(false)

		_: # All or Undefined
			# Show all props, collected and not
			for prop in LUTShard.shard:
				# Increase count
				count += 1
				var identifier = str(count) + ". "

				# Check if prop is in player's
				if count-1 in player_props:
					list.add_item(identifier + prop.shard_name)
					ownership_index.append(true)
				else:
					list.add_item(identifier + "???")
					ownership_index.append(false)
				list_props.append(prop)

## Loads a [Shard] from [ShardData].
func generate_shard(data : ShardData, owned : bool) -> void:
	# Delete existing prop
	if is_instance_valid(c_prop):
		c_prop.queue_free()

	# If we dont own the prop, avoid loading
	if !owned:
		return

	# Generate prop instance
	var i = prop_instance.instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Shard
	i.data = data
	svp_prop.add_child(i)
	c_prop = i

## Fills in info on screen from [ShardData]
func get_info_from_shard(data : ShardData, owned : bool) -> void:
	# Grab data from [PropData]
	var pname = data.shard_name
	var plocation = data.shard_location
	var pdesc = data.shard_description
	var phint = data.shard_hint

	# Set information
	%prop_name.text = pname if owned else "???"
	%prop_location.text = plocation
	%prop_description.text = pdesc if owned else phint

## Determines the player's prop progress.
func determine_progress() -> void:
	# Declare variables
	var total_props : int = all_props.size()
	var my_props : int = player_props.size()
	var percent : float = my_props / float(total_props)

	# Set text
	%count.text = "Collected: %03d/%03d" % [my_props, total_props]
	%progress.text = "Overall: %0d%%" % (percent * 100)

# SIGNAL
#-------------------------------------------------------------------------------

func _sort_item_selected(index: int) -> void:
	# Set category to index
	category = index as Category

	# Refresh
	generate_list()

	# Focus list
	list.grab_focus()

func _list_item_selected(index: int) -> void:
	# Determine if the prop is owned by player
	var ownership = ownership_index[index]
	var prop = list_props[index]

	# Generate prop from selection
	generate_shard(prop, ownership)
	get_info_from_shard(prop, ownership)
