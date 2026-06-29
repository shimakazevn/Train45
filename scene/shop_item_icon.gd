## 상점 아이템 아이콘 UI 컴포넌트.
## [br][br]
## 위아래로 부드럽게 떠다니는 플로팅 애니메이션을 무한 반복하여
## 아이템 아이콘에 생동감을 부여한다.
extends TextureRect

## 플로팅 애니메이션 트윈 참조.
var tween: Tween

## 초기화 시 텍스처를 비우고 Y축 ±5px 범위의 플로팅 트윈을 시작한다.
func _ready() -> void:
	self.texture = null
	
	var current_position = position
	tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", current_position.y + 5, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", current_position.y - 5, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
