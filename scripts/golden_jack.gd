# golden_jack.gd
class_name GoldenJack extends Jack

'''
Extension of Jack class, used by GoldenJackManager
'''

signal collected(source : GoldenJack)

var id_count : int = 0 :
	set(value) : id_count = value; update_text()
	get : return id_count

@onready var txt_count := $count
@onready var anim := $anim

func _ready() -> void:
	# Animate
	$vis.play("default")
	$vis.frame = int(randf() * 29)

func _body_entered(body : Node3D) -> void:
	if body is Player:
		# Signal
		collected.emit(self)
		
		# Generate effects
		anim.play("collected")
		AudioManager.spawn_sound_stream(sfx_collect, 1.0 + (id_count * 0.1), global_position)
		
		# Update data
		PlayerDataManager.current_jacks += 1

func update_text() -> void:
	txt_count.text = str(id_count)
