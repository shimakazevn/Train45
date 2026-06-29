extends Area2D

@export var event_component: EventComponent
@export var quest_component: QuestComponent

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if not quest_component.is_clear:
			event_component.dialog_start("stage_complete", "quest_failed_chapter3")
