extends Control
class_name SubHEventComponent

@export var npc: Npc
var partner_manager: PartnerManager

func _ready() -> void:
	partner_manager = get_tree().get_first_node_in_group("partnermanager")
	call_deferred("get_npc_exp")

func get_npc_exp():
	var _npc_info = partner_manager.partner[npc.npc_name] as Npc
	if _npc_info.is_max_exp():
		show()
	else:
		hide()
