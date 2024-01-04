# event_notification.gd
class_name EventNotification extends Event

'''
Pushes a notification to the UI.
'''

@export_category("EventNotification")
## The string to push.
@export_multiline var notification : String = ""

func _execute() -> void:
	# Push notification
	var uim := get_tree().get_first_node_in_group("UIManager") as UIManager
	uim.push_notification(notification)
	
	# Done
	execution_complete.emit()
