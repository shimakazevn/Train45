## 사인파 기반으로 밝기가 자연스럽게 깜빡이는 포인트 라이트.
## [br][br]
## [member energy_offset] 값을 기준으로 에너지가 부드럽게 오르내리는
## 무한 반복 트윈 애니메이션을 재생한다.
extends PointLight2D

## 라이트 에너지(밝기)의 기준 오프셋 값.
@export var energy_offset := 0.89


## 초기화 시 [method animate_light_range]를 호출하여 애니메이션을 시작한다.
func _ready():
	
	# 처음 애니메이션 시작
	animate_light_range()

## 사인파 트랜지션으로 에너지를 [member energy_offset] ~ [code]energy_offset - 0.05[/code] 사이에서
## 무한 반복하는 트윈 애니메이션을 생성한다.
func animate_light_range():
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)

	
	var duration = 1.7
	tween.tween_property(self, "energy", energy_offset, duration)
	tween.tween_property(self, "energy", energy_offset-0.05, duration)
