extends TextureRect

var tween: Tween
var base_scale: Vector2

func _ready() -> void:
	base_scale = scale

func update_scale(is_equip: bool):
	if tween:
		tween.kill()
	tween = create_tween().set_parallel()
	var target_scale: Vector2
	var target_color: Color
	if is_equip:
		target_scale = base_scale * 1.1
		target_color = Color.WHITE
	else:
		target_scale = base_scale
		target_color = Color.GRAY
		
	tween.tween_property(self, "scale", target_scale, 0.2)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "self_modulate", target_color, 0.2)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
