extends EventComponent
class_name MirrorEventComponent

@export var current_level: Level

func _ready() -> void:
	current_level.stage_start.connect(_on_stage_start)

func _on_stage_start():
	GameEvents.call_deferred("emit_stage_clear")
	GameEvents.emit_get_npc_exp(100, GameEvents.NpcTypes.PAZUZU)
