## 셰이더 기반 하이라이트 효과를 재생하는 [ColorRect].
## [signal start_highlight] 시그널을 통해 효과를 시작하며,
## 셰이더 파라미터 [code]Position[/code]을 트윈으로 애니메이션한다.
extends ColorRect

## 현재 활성화된 [Tween] 인스턴스.
var tween: Tween

## 하이라이트 효과 시작을 요청하는 시그널.
signal start_highlight

## 노드 준비 시 자신을 숨기고, [signal start_highlight] 시그널을 연결한다.
func _ready() -> void:
	hide()
	self.start_highlight.connect(_start_highlight)
	
## 하이라이트 효과를 재생한다. 노드를 표시한 뒤 셰이더 [code]Position[/code] 파라미터를
## [code]1.0[/code]에서 [code]0.0[/code]으로 트윈하고, 완료 후 다시 숨긴다.
func _start_highlight():
	show()
	tween = create_tween()
	tween.tween_property(material, "shader_parameter/Position", 0.0, 1.0).from(1.0)\
	.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_callback(hide)
	
