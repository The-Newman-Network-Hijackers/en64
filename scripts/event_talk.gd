# event_talk.gd
class_name EventTalk extends Event

'''
Spawns a dialog box with proivded resource.
'''

@export_category("EventTalk")
## The dialog resource that will be used in this [Event].
@export var dialog : DialogueResource
## The line marker in the [DialogueResource] to start at.
@export var title : String

func _execute() -> void:
	# Gather references
	var level_manager = get_tree().current_scene.level_manager
	var level_ui = level_manager.ui
	var ui_manager = level_ui.get_node("ui_manager")
	
	# Ensure the node exists
	if ui_manager == null:
		push_error("Could not find UI Manager! - EventTalk.", name)
		return
		

	# Hook up signal
	DialogueManager.dialogue_ended.connect(dialogue_complete.bind())

	# Begin dialogue
	ui_manager.create_dialog(
		dialog,
		title if title else dialog.first_title,
		
	)

func dialogue_complete(_resource : DialogueResource) -> void:
	# Disconnect signal
	DialogueManager.dialogue_ended.disconnect(dialogue_complete.bind())

	# Signal that execution is complete
	execution_complete.emit()
