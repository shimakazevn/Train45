extends Sprite2D

@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.animation_finished.connect(_on_anim_finished)
	
func _on_anim_finished(anim_name : String):
	if anim_name == "down":
		animation_player.play("broke")

func play_down():
	animation_player.play("down")
