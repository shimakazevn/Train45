extends Node
class_name GhostSkipComponent

#귀신 스테이지 스킵 아이템을 장착했을 경우 스테이지가 바로 클리어된다

var equip_ghost_skip: bool = false

func _ready() -> void:
	GameEvents.stage_change.connect(_on_stage_changed)
	

func _on_stage_changed():
	equip_ghost_skip = MetaProgression.has_equipment("ghost_skip")
	if Constants.ITEM_DEBUG_GHOST_SKIP:
		push_warning("debug!")
	if equip_ghost_skip or Constants.ITEM_DEBUG_GHOST_SKIP:
		GameEvents.emit_stage_clear()
