## 정보 텍스처 UI 컴포넌트.
## [br][br]
## 팝업 애니메이션과 랜덤 효과음 재생을 지원하며,
## [method rand_rotation]으로 랜덤 회전 효과를 적용할 수 있다.
extends TextureRect

## 팝업 등 애니메이션을 재생하는 [AnimationPlayer].
@onready var animation_player = $AnimationPlayer
## 랜덤 효과음을 재생하는 [AudioStreamPlayer].
@onready var random_stream_player: AudioStreamPlayer = $RandomStreamPlayerGlobalComponent

## 초기화 시 숨김 상태로 설정한다.
func _ready() -> void:
	self.hide()

## 텍스처를 표시하고 팝업 애니메이션 + 랜덤 효과음을 재생한다.
func anim_play():
	self.show()
	animation_player.stop()
	animation_player.play("pop")
	random_stream_player.play_random()

## 텍스처에 랜덤 회전(-20~20도)을 적용한다.
func rand_rotation():
	# 랜덤 각도 생성 (-10 ~ 10도)
	var random_angle = randf_range(-20, 20)
	# 랜덤 각도를 라디안 값으로 변환 (Godot은 라디안을 사용)
	var random_radians = deg_to_rad(random_angle)
	# TextureRect의 rotation 속성에 적용
	rotation = random_radians
