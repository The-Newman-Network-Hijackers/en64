# event_evoke.gd
class_name EventEvoke extends Event

'''
Evokes a signal or function in one or more objects.
'''

@export_category("EventEvoke")
## The node to evoke upon
@export var node : Node
## The packets to iterate through and execute
@export var packets : Array[EvokeData]

func _execute() -> void:
	# Iterate over and execute packets
	for packet in packets:
		# Get data
		var type := packet.type
		var e_name := packet.e_name
		var e_args := packet.e_args
		
		# Determine execution
		match type:
			packet.Types.Callable:
				node.call_deferred("callv", e_name, e_args)
			packet.Types.Signal:
				node.call_deferred("emit_signal", e_name, e_args)
	
	# Mark as complete
	execution_complete.emit()
