# textbox.gd
class_name Textbox extends Control

'''
Handles displaying text on screen.
'''

## The space margin between each line of dialog
const LINE_Y_MARGIN = 80

## Voice types
enum Voices {
	Default,
	Accordian,
	Accordian_Deep
}

## Reference to textbox_labels container
@onready var tb_labels : VBoxContainer = %textbox_labels
## Reference to scroll_container
@onready var tb_scroll : ScrollContainer = %scroll_container
## Reference to base_textbox_label
@onready var tb_base : DialogueLabel = %base_textbox_label
## Reference to textbox_name
@onready var tb_name : RichTextLabel = %textbox_name
## Reference to textbox_anim
@onready var tb_anim : AnimationPlayer = %textbox_anim

## Reference to ui_in sound
@onready var sfx_in : AudioStreamPlayer = $in
## Reference to ui_out sound
@onready var sfx_out : AudioStreamPlayer = $out
## Reference to ui_click sound
@onready var sfx_click : AudioStreamPlayer = $click
## Reference to ui_type sound
@onready var sfx_type : AudioStreamPlayer = $type

## Voice streams
@onready var stream_voices = [
	preload("res://data/r_sfx/voice_default.tres"),
	preload("res://data/r_sfx/voice_accordian.tres"),
	preload("res://data/r_sfx/voice_accordian.tres")
]

## Whether or not we are waiting for user input
var awaiting_input : bool = false
## The current label
var current_label : DialogueLabel
## The current gamestates
var current_GS : Array = []
## The current dialog resource
var diag_resource : DialogueResource
## The current position in label_instances
var li_position : int = 0

## Characters between each text sound
var chars_between_sound = 2

## The current line of dialog
var diag_line : DialogueLine :
	set(value) :
		# We are not waiting for input now
		awaiting_input = false
		
		# Error catching
		if !value:
			tb_anim.play_backwards("appear")
			sfx_out.play()
			await tb_anim.animation_finished
			queue_free()
			return
		
		# Create new label
		var tb_line = tb_base.duplicate() as DialogueLabel
		tb_line.name = "diag_line_%02d" % (li_position + 1)
		tb_line.visible = true
		tb_line.spoke.connect(on_speak.bind())
		tb_labels.add_child(tb_line)
		
		# Get data from resource
		var current_id = str_to_var(value.id)
		var next_id = str_to_var(value.next_id)
		var d_label = tb_line
		var d_name = value.character
		var d_text = value.text
		
		# Set values
		diag_line = value
		current_label = d_label
		
		# Set character label
		tb_name.get_parent().visible = d_name != ""
		tb_name.text = d_name
		
		# Animate the textbox
		if li_position != 0:
			tb_anim.play("none")
			var tw = create_tween()
			tw.tween_property(tb_scroll, "scroll_vertical", tb_scroll.scroll_vertical + 80, 0.5)
			await tw.finished
		else:
			sfx_in.play()
			tb_anim.play("appear")
			await tb_anim.animation_finished
		
		# Increment position
		li_position += 1
		
		# Set dialog line
		current_label.dialogue_line = diag_line
		
		# Begin typing
		if not diag_line.text.is_empty():
			current_label.type_out()
			await current_label.finished_typing
		
		# Type out text
		if diag_line.time != null:
			var time = diag_line.text.length() * 0.02 if diag_line.time == "auto" else diag_line.time.to_float()
			await get_tree().create_timer(time).timeout
			next_line(diag_line.next_id)
		
		# Done typing
		else:
			awaiting_input = true
			tb_anim.play("await")
		
	get: 
		return diag_line

func _unhandled_input(event: InputEvent) -> void:
	# If the user clicks on the balloon while it's typing then skip typing
	if current_label.is_typing and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		current_label.skip_typing()
		return
	
	# Reject if we arent waiting for input
	if !awaiting_input: 
		return
	
	# If there are responses, also reject
	if diag_line.responses.size() > 0: 
		return
	
	# Go to next dialog
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		sfx_click.play()
		next_line(diag_line.next_id)

# FUNCTION
#-------------------------------------------------------------------------------

## Starts a dialog.
func start_dialog(incoming_resource: DialogueResource, title: String, extra_GS : Array = []) -> void:
	# Set up variables
	current_GS = extra_GS
	awaiting_input = false
	diag_resource = incoming_resource
	
	# Begin dialog
	self.diag_line = await diag_resource.get_next_dialogue_line(title, current_GS)

## Goes to the next line of dialog
func next_line(next_id: String) -> void:
	self.diag_line = await diag_resource.get_next_dialogue_line(next_id, current_GS)

## Plays a sound effect
func on_speak(letter : String, letter_index : int, _speed : float) -> void:
	if not letter in [" ", ".", ",", "?", "!"]:
		if chars_between_sound > 0:
			if letter_index % chars_between_sound == 0:
				sfx_type.play()
				return
			else:
				return
			sfx_type.play()

## Changes textbox voice to something different
func change_voice(id : int) -> void:
	sfx_type.stream = stream_voices[id]
	match id:
		Voices.Default:			
			chars_between_sound = 0
			sfx_type.pitch_scale = 1.0
		Voices.Accordian:		
			chars_between_sound = 2
			sfx_type.pitch_scale = 1.0
		Voices.Accordian_Deep:
			chars_between_sound = 2
			sfx_type.pitch_scale = .8
