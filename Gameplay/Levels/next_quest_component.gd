extends Node2D

func _ready() -> void:
	GameEvents.npc_level_up.connect(_on_update)
	GameEvents.update_quest_process.connect(_on_update)
	Dialogic.timeline_ended.connect(_on_update)
	Dialogic.timeline_started.connect(func(_arg = null): visible = false)
	_on_update()

func _on_update(_arg = null) -> void:
	var love_level :int = MetaProgression.get_npc_love_level(Constants.NPC_KONIAL)
	visible = love_level == 1 and MetaProgression.has_read_event("konial_love_1")
