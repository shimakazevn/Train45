extends Node2D

func _ready() -> void:
	self.visibility_changed.connect(_on_visiblility_changed)
	
func _on_visiblility_changed():
	if visible:
		pass
	else:
		pass
