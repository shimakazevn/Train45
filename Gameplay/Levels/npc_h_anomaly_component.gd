extends GhostHAnomaly

@export var current_npc: CurrentNpc
@export var npc_type: Constants.NpcTypes

func check_npc():
	var npc = current_npc.get_child(0) as Npc
	if  npc.npc_name == npc_type:
		pass
	else:
		ghost_sprite.queue_free()

func set_near_npc_position():
	pass

func set_to_stage_clear():
	var npc = current_npc.get_child(0) as Npc
	ghost_sprite.flip_h = npc.npc_sprite.flip_h
	ghost_sprite.position = npc.global_position + npc.npc_sprite.position
	ghost_sprite.y_sort_enabled = true
	ghost_sprite.z_index = 3
	npc.hide()

func equip_item_check_override()->bool:
	if MetaProgression.has_equipment("npc_ano_h"):
		return true
	return false

func need_item_notion_override():
	NotionEvent.notion("NOTI_UNEQUIP_ITEM", Constants.NPC_H_ITEM_ICON, Color.BLACK)
