extends Button

var tween: Tween
var base_position: Vector2

func _ready() -> void:
	base_position = position

func animate_position(to: Vector2):
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", to, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func _on_focus_entered() -> void:
	animate_position(base_position + Vector2(20, 0))

func _on_focus_exited() -> void:
	animate_position(base_position)

func _on_mouse_entered() -> void:
	animate_position(base_position + Vector2(20, 0))

func _on_mouse_exited() -> void:
	animate_position(base_position)
