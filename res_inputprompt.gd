# res_inputprompt.gd
class_name InputPrompt extends Resource

'''
Contains all data required to generate an input prompt. 
'''

@export_category("InputPrompt")
## The target input.
@export var input : Array[StringName]
## Render as analog input, if applicable
@export var render_as_analog : bool = false
## Render with equipment icon. -1 will not render any icon.
@export var equip_icon : int = -1
## The message associated with the input.
@export var message : String = "to Interact"
