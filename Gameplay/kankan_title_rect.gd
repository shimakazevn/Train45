extends TextureRect
class_name KankanTitleRect
## 칸칸 타이틀 애니메이션을 관리하는 [code]TextureRect[/code].
## 초기에 화면 위로 숨겨져 있다가 [method info_update] 호출 시 슬라이드 인 애니메이션으로 표시된다.

## 애니메이션용 [Tween] 인스턴스
var tween: Tween
## 원래 위치 (애니메이션 기준점)
var base_position : Vector2

## 초기화 시 [member base_position]을 저장하고 화면 위로 이동시킨다.
func _ready() -> void:
	base_position = position
	position = base_position + Vector2(0,-300)

## 타이틀을 위에서 아래로 슬라이드 인 애니메이션으로 표시한다.
func info_update():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", base_position, 0.3).from(base_position + Vector2(0,-300))\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
