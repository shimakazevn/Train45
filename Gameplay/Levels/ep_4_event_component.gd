extends EventComponent

@export var talk1_area : Area2D
@export var talk2_area : Area2D
@export var talk3_area : Area2D

func _on_quest_process(quest_str: String):
	match quest_str:
		"chapter4_talk1":
			talk1_area.monitoring = false
		"chapter4_talk2":
			talk2_area.monitoring = false

func _on_talk_1_area_body_entered(_body: Node2D) -> void:
	dialog_start("chapter4_complete")


func _on_talk_2_area_body_entered(_body: Node2D) -> void:
	dialog_start("chapter4_complete2")


func _on_talk_3_area_body_entered(_body: Node2D) -> void:
	dialog_start("chapter4_complete3")
