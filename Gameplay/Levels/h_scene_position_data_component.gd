extends Node2D

func _ready() -> void:
	self.queue_free() #에디터에서만 참고할 것이므로 게임이 실행되면 지운다
