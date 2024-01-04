# event_conditional.gd
@tool
class_name EventConditional extends Event

'''
Attempts a conditional, and passes if true.
'''

@export_category("EventConditional")
## The condition to be parsed
@export var condition : String = ""
## The local flags to pass to the parser
@export var local_flags : Array[String] = []
## The global flags to pass to the parser
@export var global_flags : Array[String] = []
## Verifies the condition is valid
@export var verify_condition : bool = false :
	set(_value) : verify_condition = false; print(parse_condition())
	get : return verify_condition

## Reference to level script
@onready var level_script = owner as LevelScript
## Reference to level data
@onready var level_flags = level_script.data.flags as Dictionary

func _execute() -> void:
	# Check for true conditional
	var result = parse_condition()
	print(level_flags)
	
	# Pass if true, end if not
	if result:
		execution_complete.emit(+1)
		return
	execution_complete.emit()
	

# FUNCTION
#-------------------------------------------------------------------------------

## Parses the condition.
func parse_condition() -> bool:
	# Create and parse expression
	var exp = Expression.new()
	exp.parse(condition, local_flags + global_flags)
	
	# Obtain variables
	var variables : Array
	for flag in local_flags:
		variables.append(level_flags.get(flag))
	for flag in global_flags:
		pass
	
	# Execute
	var result = exp.execute(variables)
	
	# Check for failure
	if exp.has_execute_failed():
		push_error("Execution failed! Error in provided condition.")
		return false
	
	# Return result
	return result
