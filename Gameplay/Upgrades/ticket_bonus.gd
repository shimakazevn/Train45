extends Node2D


const ICON_TICKET_BONUS = preload("res://resources/ui/icons/icons13.png")

func _ready() -> void:
	GameEvents.stage_clear.connect(_on_stage_clear)

func _on_stage_clear():
	var ticket_n: int = Constants.BONUS_TICKET_CLEAR_ITEM
	var ticket_v: int = Constants.TICKET_VALUE_NORMAL # 2
	
	if GameEvents.get_current_stage_type() == Constants.TYPE_SAFE:
		GameEvents.emit_set_ticket("plus", ticket_n)
	else:
		GameEvents.emit_drop_item(Constants.PC_PLAYER, DropItemManager.ItemType.TICKET, int(float(ticket_n) / ticket_v))
	
	var message = tr("NOTI_ITEM_TICKET_BONUS")%(ticket_n)
	NotionEvent.notion(message, ICON_TICKET_BONUS)
