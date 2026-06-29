extends Area2D

@export var ghost : CharacterBody2D

func _on_body_entered(body):
	if body is Player and ghost.ghost_stage_clear == false and not ghost.ghost_skip_component.equip_ghost_skip:
		#body.find_faild.emit()
		body.rape("white_ghost")
		await TransitionScreen.on_transition_finishied
		ghost.queue_free()


func _on_area_entered(area):
	if area is Doll:
		ghost.stage_clear()
