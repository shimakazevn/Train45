extends TextureRect
## 노선 확인 버블 UI를 관리하는 [code]TextureRect[/code].
## [signal route_confirm] 시그널을 수신하여 확인 메시지를 팝업 애니메이션으로 표시한다.

## 노선도 맵 참조
@export var route_map: RouteMap
## 애니메이션용 [Tween] 인스턴스
var tween : Tween
## 버블이 현재 활성화 상태인지 여부
var is_enabled:= false
## 확인 메시지를 표시하는 [Label] 참조
@onready var label: Label = $Label

## 초기화 시 [signal route_confirm] 시그널을 연결하고, 표시 중이면 숨긴다.
func _ready() -> void:
	route_map.route_confirm.connect(is_confirm)
	if visible == true:
		hide()

## 노선 확인 시 호출된다. [param target_text]를 표시하고 팝업 후 자동으로 사라지는 애니메이션을 실행한다.
func is_confirm(target_text: String):
	label.text = target_text
	show()
	is_enabled = true
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.4).from(Vector2.ZERO).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	await get_tree().create_timer(2.0).timeout
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.4).from(Vector2.ONE).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(set_disabled)

## 버블을 숨기고 [member is_enabled]를 [code]false[/code]로 설정한다.
func set_disabled():
	hide()
	is_enabled = false
