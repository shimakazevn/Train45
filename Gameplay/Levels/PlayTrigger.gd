extends Area2D

@export var play_ground : PlayGround

func _on_body_entered(body):
	if not body is Player:
		return
	if play_ground.ghost_skip_component.equip_ghost_skip:
		return

	play_ground.play_start()
	set_deferred("monitoring",false)
