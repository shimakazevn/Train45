extends Sprite2D

@export var train : Node2D
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	train.train_vibe.connect(_on_train_vibe)
	
func _on_train_vibe():
	anim.play("vibe")
