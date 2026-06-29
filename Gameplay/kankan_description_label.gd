extends Label
class_name KankanDescriptionLable
## 칸칸 설명 라벨 애니메이션을 관리하는 [code]Label[/code].
## 초기에 투명하게 숨겨져 있다가 [method info_update] 호출 시 슬라이드 인과 페이드 인 애니메이션으로 표시된다.

## 애니메이션용 [Tween] 인스턴스
var tween: Tween
## 원래 위치 (애니메이션 기준점)
var base_position : Vector2
## 원래 색상 (페이드 인 애니메이션 목표)
var original_color : Color

## 초기화 시 [member base_position]과 [member original_color]를 저장하고 화면 위로 이동 및 투명화시킨다.
func _ready() -> void:
	base_position = position
	original_color = modulate
	position = base_position + Vector2(0,-300)
	modulate = Color.TRANSPARENT


## 설명 라벨을 슬라이드 인 및 페이드 인 애니메이션으로 표시한다.
## [code]0.1[/code]초 지연 후 위치와 색상을 병렬로 트윈한다.
func info_update():
	modulate = Color.TRANSPARENT
	if tween:
		tween.kill()
	tween = create_tween().set_parallel()
	tween.tween_property(self, "position", base_position, 0.3).from(base_position + Vector2(0,-300))\
	.set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate", original_color, 0.2)\
	.set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
