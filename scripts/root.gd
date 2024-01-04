# root.gd
extends Node

'''
Acts as the primer for the game
'''

## Reference to LevelManager
@onready var level_manager : LevelManager = $level_manager
## Reference to fade
@onready var fade := $level_manager/fade
## Reference to dither buffer
@onready var buf_dither := $effect/scaling/dither_buffer
## Reference to ntsc buffer
@onready var buf_ntsc := $effect/scaling/ntsc_buffer
## Reference to circle fade
@onready var fade_circle := $level_manager/fade/circle_fade/bg

## Target scene to start at
@export var target_scene : PackedScene
## Current version string.
@onready var ver = ProjectSettings.get_setting("application/config/version")

func _ready() -> void:
	# Load main menu scene
	level_manager.load_level(target_scene)
	
	await get_tree().process_frame
	
	# Configure debug
	DebugDraw2D.config.text_custom_font = load("res://asset/ui/Loosey Sans.otf")
	DebugDraw2D.config.text_default_size = 16
	DebugDraw2D.config.text_background_color = Color(0, 0, 0, 0)
	DebugDraw2D.config.text_foreground_color = Color(1, 1, 1, 0.7)
	DebugDraw2D.config.text_block_position = DebugDrawConfig2D.POSITION_LEFT_BOTTOM

func _process(_delta) -> void:
	# Update debug
	DebugDraw2D.set_text("fps", Engine.get_frames_per_second())
