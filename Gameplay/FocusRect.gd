extends NinePatchRect
## 포커스 박스 애니메이션을 관리하는 [code]NinePatchRect[/code].
## 선택된 버튼의 위치와 크기에 맞춰 포커스 박스를 트윈 애니메이션으로 조정한다.

## 현재 활성화된 [Tween] 인스턴스
var tween : Tween

## 포커스 박스의 Y축 기본 오프셋 값
const y_offset: float = 3.0

## 초기화 시 [member tween]을 생성한다.
func _ready():
	tween = create_tween()

## [param button]의 위치와 크기에 맞춰 포커스 박스를 배치하고 크기 애니메이션을 실행한다.
## 버튼 유형(뒤로 가기, [HSlider], 일반)에 따라 위치와 크기를 다르게 계산한다.
func focus_box_set(button: Control):
	size.x = 0.0
	var target_size
	if button.is_in_group("back"):
		var target_pos = Vector2(button.global_position.x - 15, button.get_parent().global_position.y -2)
		position = target_pos
		target_size = 60
	if button is HSlider: #슬라이더일때
		var target_pos = Vector2(button.global_position.x-16, button.global_position.y -8)
		position = target_pos
		target_size = (button.size.x + 110)*button.scale.x
	else:
		var target_pos = Vector2(button.global_position.x - 40, button.get_parent().global_position.y + y_offset)
		position = target_pos
		#print(position)
		
		target_size = button.size.x + 80
	if tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "size:x", target_size, 0.3).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
