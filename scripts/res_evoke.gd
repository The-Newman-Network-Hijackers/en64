# res_evoke.gd
class_name EvokeData extends Resource

'''
Holds information used in EventEvoke.
'''

enum Types {
	Callable,
	Signal,
}

@export_category("EvokeData")

## The type of evoke.
@export var type : Types = Types.Callable
## The name of what we're calling/signalling
@export var e_name : String = ""
## The arguements to pass through
@export var e_args : Array = []
