# demo_menu.gd
extends "res://scripts/main_menu.gd"

'''
Extension of main menu functionality, for demo release
'''

func _start_pressed() -> void:
	# Change level
	level_manager.change_level(
		"res://scenes/level/vslice_demo/history/history_channel.tscn"
	)
