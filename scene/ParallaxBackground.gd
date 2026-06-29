## 자동 스크롤 패럴랙스 배경.
## [br][br]
## 매 프레임마다 좌측으로 자동 스크롤하여 배경 이동 효과를 만든다.
extends ParallaxBackground


## 매 프레임 좌측으로 400px/s 속도로 스크롤 오프셋을 이동시킨다.
func _process(delta):
	scroll_offset.x -= 400*delta
