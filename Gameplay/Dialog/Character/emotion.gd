extends Sprite2D

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	self.visibility_changed.connect(_on_visibility_changed)
	
func _on_visibility_changed():
	if self.visible:
		anim.play("idle")
		await get_tree().create_timer(3.0).timeout
		if self.visible:
			hide()
