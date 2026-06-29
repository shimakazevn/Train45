extends Label
## 게이지 스택 수치를 표시하는 [code]Label[/code].
## 게이지 스택 값이 업데이트되면 텍스트를 갱신하고 표시한다.

## 애니메이션용 [Tween] 인스턴스
var tween: Tween

## 초기화 시 라벨을 숨긴다.
func _ready() -> void:
	#tween = create_tween()
	hide()

## 게이지 스택 값을 [param value]로 업데이트한다.
## 라벨이 숨겨진 상태라면 표시한 후, 텍스트를 갱신한다.
func update_gauge_stack(value: int):
	if self.visible == false:
		self.show()
	self.text = str(value)
