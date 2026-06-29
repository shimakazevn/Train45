extends Area2D

@export var event_component: EventComponent
@export var need_npc: Constants.NpcTypes = Constants.NpcTypes.NONE

var is_active: bool = false

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_active:
		is_active = true
		event_component.not_matching_partner_return_base(need_npc)
