# input_prompt_container.gd
class_name InputPromptContainer extends HBoxContainer

'''
Stores and updates InputPrompts within.
'''

## Fired when queue is updated.
signal queue_updated()

@export_category("InputPromptContainer")
## The initial queue to begin with.
@export var initial_prompt : Array[InputPrompt] = [] :
	set(value) : initial_prompt = value; queue = value
	get : return initial_prompt

## The queue of [InputPrompt]s to update from.
var queue : Array[InputPrompt] = [] :
	set(value) : queue = value; queue_updated.emit()
	get : return queue

func _ready() -> void:
	# Connect signal
	InputManager.input_changed.connect(update.bind())
	queue_updated.connect(update.bind())
	
	# Set settings
	add_theme_constant_override("separation", 16)

func _exit_tree() -> void:
	# Disconnect signals
	InputManager.input_changed.disconnect(update.bind())
	queue_updated.disconnect(update.bind())
	
# FUNCTION
#-------------------------------------------------------------------------------

## Full update cycle.
func update() -> void:
	clear_queue()
	render_queue()

## Renders input prompts from queue.
func render_queue() -> void:
	for prompt in queue:
		var iP = InputManager.generate_prompt(prompt)
		add_child(iP)

## Clears children.
func clear_queue() -> void:
	for child in get_children():
		child.queue_free()
