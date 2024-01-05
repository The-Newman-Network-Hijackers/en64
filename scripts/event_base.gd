# event_base.gd
@icon("res://asset/editor/Event.svg")
class_name Event extends Node

'''
Base class for all Events
'''

## Reference to [Player].
var player : Player

signal execution_complete()

func _execute() -> void:
	print("Hello World!")
	execution_complete.emit()
