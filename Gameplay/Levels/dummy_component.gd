extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("idle")

func anim_change(anim_name: String) -> void:
	if animation_player.current_animation == anim_name:
		return
		
	var fade_duration := 0.1

	# 1) 페이드 아웃
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	# 2) 애니메이션 변경
	animation_player.play(anim_name)

	# 3) 페이드 인
	var tween_in = create_tween()
	tween_in.tween_property(self, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
