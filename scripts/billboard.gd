# billboard.gd
extends Node3D

'''
Billboards a node to always face the current camera.
'''

func _process(_delta: float) -> void:
	# Get current camera
	var camera : Camera3D = get_viewport().get_camera_3d()

	# If there is no camera, break
	if !camera:
		return

	# Rotate towards camera
	look_at(camera.global_position, Vector3.UP)
