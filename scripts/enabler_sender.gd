# enabler_sender.gd
class_name EnablerSender extends Area3D

'''
Enables any EnablerRecievers that come into contact.
'''

func _enter_tree() -> void:
	# Configure
	monitorable = false
	collision_layer = 0
	input_ray_pickable = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _ready() -> void:
	# Connect signal
	area_entered.connect(enabler_entered.bind())
	area_exited.connect(enabler_exited.bind())
	
# FUNCTION
#-------------------------------------------------------------------------------

func enabler_entered(area : Area3D) -> void:
	if not area is EnablerReciever:
		return
	
	if !is_instance_valid(area) || area.is_queued_for_deletion() || !weakref(area):
		return
	
	area.is_enabling = true

func enabler_exited(area : Area3D) -> void:
	if not area is EnablerReciever:
		return
		
	if !is_instance_valid(area) || area.is_queued_for_deletion() || !weakref(area):
		return
	
	area.is_enabling = false
