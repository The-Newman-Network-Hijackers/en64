# splash_manager.gd
extends Node

'''
Manages bootup screen
'''

## Whether or not to prompt the player
var prompt : bool = true
## Whether or not the player should be prompted in the future
var disable_prompt : bool = false
## Copy of the player's save data
var save_data : PlayerData

func _ready() -> void:
	# Load and apply config from data
	save_data = PlayerDataManager.load_data()
	PlayerDataManager.config_update(save_data)
	
	# Check for anything in misc
	prompt = save_data.config.misc.get("splash_prompt", true)
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		skip_animation()

# FUNCTION
#-------------------------------------------------------------------------------

func skip_animation() -> void:
	$anim.play("RESET")

func do_not_show_ticked(toggle : bool) -> void:
	disable_prompt = toggle

func ok_pressed() -> void:
	if disable_prompt:
		save_data.config.misc["splash_prompt"] = !disable_prompt
		PlayerDataManager.save_data(save_data)
	$popup.hide()

func _animation_finished(anim_name: StringName) -> void:
	if prompt:
		$popup.show()
		$popup/margin_container/sort/sort/ok.grab_focus()
		await $popup/margin_container/sort/sort/ok.pressed
	
	# Determine mode
	var root = get_tree().current_scene
	var mode = root.dmode
	
	if mode:
		$demo_warp.execute()
		return
	$default_warp.execute()
