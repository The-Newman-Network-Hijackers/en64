# ls_level_preview.gd
class_name LevelPreview extends Node

'''
Loads a level to show as preview on a seperate thread
'''

signal loading_complete(level : Node)
signal request_complete

## The level thats currently loaded
var level : Node
## Whether or not loading is complete
var is_loading : bool = false

func _exit_tree() -> void:
	unload_level()

# FUNCTION
#-------------------------------------------------------------------------------

## Requests a new level to be displayed
func request_level(path : String) -> void:
	# If we're in the process of loading already, wait for original request to finish
	if is_loading:
		await request_complete
	
	# We're loading now
	is_loading = true
	
	# Unload existing and load new
	unload_level()
	var result = await load_level(path);
	if !result: push_error("Level request failed!"); is_loading = false; return
	
	# Done loading
	is_loading = false
	request_complete.emit()

## Unloads current level
func unload_level() -> void:
	# Unload reference
	if level:
		level.queue_free()
		level = null

## Loads level into preview
func load_level(path : String) -> bool:
	# Create a loader and queue
	ResourceLoader.load_threaded_request(path)
	
	# Wait for level to load
	print("Loading preview... \"", path + "\"")
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	
	# Level has loaded to some capacity
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_FAILED:
		push_error("Loading resource failed.")
		return false
	
	# Unpack level resource and send over signal
	var data = ResourceLoader.load_threaded_get(path) as PackedScene
	level = data.instantiate()
	loading_complete.emit(level)
	return true
