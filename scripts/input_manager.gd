# input_manager.gd
extends Node

'''
Manages keybindings and input prompts.
'''

## Emitted when input method is changed.
signal input_changed()

## Paths for various icons
const PATH_KBM = "res://asset/ui/prompt/kbm/T_{key}_Key_Dark.png"
const PATH_GEN = "res://asset/ui/prompt/generic/T_X_{key}.png"

## References to equipment icons
const _tex_equip = [
	preload("res://asset/ui/equip/glove.png"),
	preload("res://asset/ui/equip/hammer.png"),
	preload("res://asset/ui/equip/slingshot.png"),
	preload("res://asset/ui/equip/none.png")
]

enum Device {
	KBM,
	Generic,
}

var _tex_kb = {
	KEY_SPACE : load(PATH_KBM.format({"key" : "Space"})),
	KEY_0 : load(PATH_KBM.format({"key" : "0"})),
	KEY_1 : load(PATH_KBM.format({"key" : "1"})),
	KEY_2 : load(PATH_KBM.format({"key" : "2"})),
	KEY_3 : load(PATH_KBM.format({"key" : "3"})),
	KEY_4 : load(PATH_KBM.format({"key" : "4"})),
	KEY_5 : load(PATH_KBM.format({"key" : "5"})),
	KEY_6 : load(PATH_KBM.format({"key" : "6"})),
	KEY_7 : load(PATH_KBM.format({"key" : "7"})),
	KEY_8 : load(PATH_KBM.format({"key" : "8"})),
	KEY_9 : load(PATH_KBM.format({"key" : "9"})),
	KEY_A : load(PATH_KBM.format({"key" : "A"})),
	KEY_B : load(PATH_KBM.format({"key" : "B"})),
	KEY_C : load(PATH_KBM.format({"key" : "C"})),
	KEY_D : load(PATH_KBM.format({"key" : "D"})),
	KEY_E : load(PATH_KBM.format({"key" : "E"})),
	KEY_F : load(PATH_KBM.format({"key" : "F"})),
	KEY_G : load(PATH_KBM.format({"key" : "G"})),
	KEY_H : load(PATH_KBM.format({"key" : "H"})),
	KEY_I : load(PATH_KBM.format({"key" : "I"})),
	KEY_J : load(PATH_KBM.format({"key" : "J"})),
	KEY_K : load(PATH_KBM.format({"key" : "K"})),
	KEY_L : load(PATH_KBM.format({"key" : "L"})),
	KEY_M : load(PATH_KBM.format({"key" : "M"})),
	KEY_N : load(PATH_KBM.format({"key" : "N"})),
	KEY_O : load(PATH_KBM.format({"key" : "O"})),
	KEY_P : load(PATH_KBM.format({"key" : "P"})),
	KEY_Q : load(PATH_KBM.format({"key" : "Q"})),
	KEY_R : load(PATH_KBM.format({"key" : "R"})),
	KEY_S : load(PATH_KBM.format({"key" : "S"})),
	KEY_T : load(PATH_KBM.format({"key" : "T"})),
	KEY_U : load(PATH_KBM.format({"key" : "U"})),
	KEY_V : load(PATH_KBM.format({"key" : "V"})),
	KEY_W : load(PATH_KBM.format({"key" : "W"})),
	KEY_X : load(PATH_KBM.format({"key" : "X"})),
	KEY_Y : load(PATH_KBM.format({"key" : "Y"})),
	KEY_Z : load(PATH_KBM.format({"key" : "Z"})),
	KEY_UP : load(PATH_KBM.format({"key" : "Up"})),
	KEY_DOWN : load(PATH_KBM.format({"key" : "Down"})),
	KEY_LEFT : load(PATH_KBM.format({"key" : "Left"})),
	KEY_RIGHT : load(PATH_KBM.format({"key" : "Right"})),
	KEY_BRACKETLEFT : load(PATH_KBM.format({"key" : "Brackets_L"})),
	KEY_BRACKETRIGHT : load(PATH_KBM.format({"key" : "Brackets_R"})),
	KEY_SLASH : load(PATH_KBM.format({"key" : "Slash"})),
	KEY_MINUS : load(PATH_KBM.format({"key" : "Minus"})),
	KEY_EQUAL : load(PATH_KBM.format({"key" : "Plus"})),
	KEY_SHIFT : load(PATH_KBM.format({"key" : "Shift"})),
	KEY_CTRL : load(PATH_KBM.format({"key" : "Ctrl"})),
}

var _tex_m = {
	MOUSE_BUTTON_LEFT : load(PATH_KBM.format({"key" : "Mouse_Left"})),
	MOUSE_BUTTON_RIGHT : load(PATH_KBM.format({"key" : "Mouse_Right"})),
	MOUSE_BUTTON_MIDDLE : load(PATH_KBM.format({"key" : "Mouse_Middle"})),
	MOUSE_BUTTON_WHEEL_UP : load(PATH_KBM.format({"key" : "Mouse_Scroll_Up"})),
	MOUSE_BUTTON_WHEEL_DOWN : load(PATH_KBM.format({"key" : "Mouse_Scroll_Down"}))
}

var _tex_gen = {
	JOY_BUTTON_A : load(PATH_GEN.format({"key" : "A_White"})),
	JOY_BUTTON_B : load(PATH_GEN.format({"key" : "B_White"})),
	JOY_BUTTON_X : load(PATH_GEN.format({"key" : "X_White"})),
	JOY_BUTTON_Y : load(PATH_GEN.format({"key" : "Y_White"})),
	JOY_BUTTON_BACK : load(PATH_GEN.format({"key" : "Share"})),
	JOY_BUTTON_START : load(PATH_GEN.format({"key" : "X"})),
	JOY_BUTTON_LEFT_STICK : load(PATH_GEN.format({"key" : "Left_Stick_Click"})),
	JOY_BUTTON_RIGHT_STICK : load(PATH_GEN.format({"key" : "Right_Stick_Click"})),
	JOY_BUTTON_LEFT_SHOULDER : load(PATH_GEN.format({"key" : "LB"})),
	JOY_BUTTON_RIGHT_SHOULDER : load(PATH_GEN.format({"key" : "RB"})),
	JOY_BUTTON_DPAD_UP : load(PATH_GEN.format({"key" : "Dpad_Up"})),
	JOY_BUTTON_DPAD_DOWN : load(PATH_GEN.format({"key" : "Dpad_Down"})),
	JOY_BUTTON_DPAD_LEFT : load(PATH_GEN.format({"key" : "Dpad_Left"})),
	JOY_BUTTON_DPAD_RIGHT : load(PATH_GEN.format({"key" : "Dpad_Right"})),
}

var _tex_genaxis = {
	JOY_AXIS_LEFT_X : load(PATH_GEN.format({"key" : "L_2D"})),
	JOY_AXIS_LEFT_Y : load(PATH_GEN.format({"key" : "L_2D"})),
	JOY_AXIS_RIGHT_X : load(PATH_GEN.format({"key" : "R_2D"})),
	JOY_AXIS_RIGHT_Y : load(PATH_GEN.format({"key" : "R_2D"})),
	JOY_AXIS_TRIGGER_LEFT : load(PATH_GEN.format({"key" : "LT"})),
	JOY_AXIS_TRIGGER_RIGHT : load(PATH_GEN.format({"key" : "RT"})),
}

## The font to use.
var font = preload("res://asset/ui/RobotoCondensed-Bold.ttf")
## Determines if the game should use the automatic input instead.
var use_automatic : bool = true

## Input device thats automatically detected.
var automatic_device : Device = Device.KBM :
	set(value) : automatic_device = value; current_device = value if use_automatic else current_device
	get : return automatic_device
## The current input device.
var current_device : Device = Device.KBM :
	set(value) : current_device = value as Device; input_changed.emit()
	get : return current_device

func _input(event : InputEvent) -> void:
	# Declare variable
	var next_device : Device = automatic_device
	
	# Keyboard input?
	if event is InputEventKey && event.is_pressed():
		next_device = Device.KBM
	# Mouse input?
	elif event is InputEventMouseButton && event.is_pressed():
		next_device = Device.KBM
	# Gamepad input?
	elif (
		event is InputEventJoypadButton && event.is_pressed() ||
		event is InputEventJoypadMotion && event.axis_value > 0.1
	):
		next_device = Device.Generic
	
	# Set automatic if change
	if next_device != automatic_device:
		automatic_device = next_device
	

# FUNCTION
#-------------------------------------------------------------------------------

## Generates an input prompt based on [InputPrompt]
func generate_prompt(prompt : InputPrompt) -> Control:
	# Declare variables
	var h_sort = HBoxContainer.new()
	var label = Label.new()
	var rect = []
	
	# Create rects first
	for s_name in prompt.input:
		var event = determine_input(s_name)
		var s_rect = generate_input_rect(event)
		h_sort.add_child(s_rect)
		rect.append(s_rect)
		
		# Only render once if we're targeting analog
		if prompt.render_as_analog && current_device == Device.Generic:
			break
	
	# Configure container
	h_sort.add_theme_constant_override("separation", -6)
	var spacer = h_sort.add_spacer(false)
	spacer.custom_minimum_size.x = 16
	
	# Configure label
	h_sort.add_child(label)
	label.text = prompt.message
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	
	return h_sort

## Generates a [TextureRect] based on provided Input.
func generate_input_rect(event : InputEvent) -> TextureRect:
	# Declare variables
	var rect = TextureRect.new()

	# Assign to rect
	rect.texture = generate_input_texture(event)
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	rect.custom_minimum_size.y = 24
	
	return rect

## Generates a [CompressedTexture2D] based on provided Input.
func generate_input_texture(event : InputEvent) -> CompressedTexture2D:
	# Declare variables
	var index : int
	var texture = CompressedTexture2D.new()
	
	# Determine texture
	if event is InputEventKey:
		index = event.physical_keycode
		texture = _tex_kb[index]
	elif event is InputEventMouseButton || event is InputEventJoypadButton:
		index = event.button_index
		texture = _tex_m[index] if event is InputEventMouseButton else _tex_gen[index]
	elif event is InputEventJoypadMotion:
		index = event.axis
		texture = _tex_genaxis[index]
	
	return texture

## Generates a [CompressedTexture2D] based on provided equipment ID.
func generate_equipment_texture(id : int) -> CompressedTexture2D:
	var texture = CompressedTexture2D.new()
	texture = _tex_equip[id]
	return texture

## Determines action associated with input based on device.
func determine_input(input_name : StringName) -> InputEvent:
	# Verify and obtain events from action
	assert(InputMap.has_action(input_name))
	var input_data = InputMap.action_get_events(input_name)
	
	# Compare and return
	match current_device:
		Device.Generic:
			for event in input_data:
				if event is InputEventJoypadButton || event is InputEventJoypadMotion:
					return event
			push_error("Could not find Generic button.")
		_:
			for event in input_data:
				if event is InputEventKey || event is InputEventMouseButton:
					return event
			push_error("Could not find KBM key.")
	return null

## Converts enumerator to string
func input_to_str(input : int) -> String:
	match input:
		Device.KBM:
			return "Keyboard and Mouse"
		Device.Generic:
			return "Generic Gamepad"
	return "Null"

## Determines if an input event is analog.
func is_analog(event : InputEvent) -> bool:
	if event is InputEventJoypadMotion:
		return true
	return false
