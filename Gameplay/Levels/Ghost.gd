extends Sprite2D

func _ready():
	GameEvents.stage_clear.connect(_on_stage_clear)

func _on_stage_clear():
	visible = false
