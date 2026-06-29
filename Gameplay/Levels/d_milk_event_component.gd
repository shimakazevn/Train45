extends EventComponent

func _ready() -> void:
	GameEvents.call_deferred("emit_stage_clear")
