extends Control
class_name HWindowSelectFrame

var tween: Tween

func set_frame_pos(pos: Vector2):
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "global_position:x", pos.x, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
