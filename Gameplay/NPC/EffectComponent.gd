extends Node2D

@onready var vignette = $Vignette
@onready var animation_player = vignette.get_node_or_null("AnimationPlayer")  # 처음에 한 번만 찾기

func flash():
	if animation_player:
		animation_player.stop()
		animation_player.play("hit")
	else:
		print("AnimationPlayer node not found.")
