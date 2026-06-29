extends MarginContainer
## 디테일 패널을 관리하는 [code]MarginContainer[/code].
## 갱신 시 애니메이션을 재생하여 시각적 피드백을 제공한다.

## 디테일 패널 [AnimationPlayer] 참조
@onready var animation_player = $AnimationPlayer

## 디테일 패널의 갱신 애니메이션을 재생한다.
## 기존 애니메이션을 중지하고 [code]update[/code] 애니메이션을 실행한다.
func detail_update():
	animation_player.stop()
	animation_player.play("update")
