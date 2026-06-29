extends Sprite2D

func _ready():
	#GameEvents.stage_clear.connect(_on_stage_clear)
	pass

##기능 보류, 항상 보여지게 설정
func _on_stage_clear():
	visible = true
