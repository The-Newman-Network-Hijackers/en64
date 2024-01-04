# state.gd
class_name State extends Node

'''
Holds functions to be executed on entering, process, and exit.
'''

## To be set by the actual stateMachine node.
var state_machine : StateMachine

## Virtual function, called when state is activated
func _enter(_msg := {}):
	pass

## Virtual function, called when active state is changing
func _exit():
	pass

## Virtual function, handles input events
func _state_unhandled_input(_event : InputEvent):
	pass

## Virtual function, handles updates by frame
func _state_process(_delta : float):
	pass

## Virtual function, handles physics updates
func _state_physics_process(_delta : float):
	pass
