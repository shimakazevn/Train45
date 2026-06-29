extends Node2D

var is_owner : Npc

func _ready() -> void:
	is_owner = self.owner as Npc
	self.position = is_owner.npc_camera.position ## 각각 다른 카메라 포지션에 맞추기 위한 코드

func _process(_delta: float) -> void:
	if self.visible == true:
		self.position = is_owner.npc_camera.position ## 각각 다른 카메라 포지션에 맞추기 위한 코드
