extends Control
class_name TutorialBlock


func _ready() -> void:
	pause_game(true)
	pass
	
func pause_game(pause: bool):
	get_tree().paused = pause
	if pause:
		Engine.time_scale = 1.0
	else:
		Engine.time_scale = 1.0

func _exit_tree() -> void:
	#pause_game(false)
	pass

func _on_tuto_end():
	MetaProgression.read_event_update("tuto_kankannavi")
	queue_free()
