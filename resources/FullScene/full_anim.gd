class_name NpcFullScene
extends Sprite2D

var current_anim: AnimationPlayer

func _ready() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "self_modulate", Color.WHITE, 0.5).from(Color.TRANSPARENT).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	
	current_anim = get_child(0) as AnimationPlayer

func current_anim_play(play: bool):
	if play:
		current_anim.play()
	else:
		if current_anim.is_playing():
			current_anim.stop()
	
