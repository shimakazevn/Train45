extends Node2D

# 종착점 스테이지에서 스테이지 클리어해야만 해당 이벤트를 볼 수 있게 하는 부모 노드임

var h_event_show:= false

func _ready() -> void:
	hide() #기본 안보이는 상태
	GameEvents.stage_clear.connect(_on_stage_clear)

func _on_stage_clear():
	show()
