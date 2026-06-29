## 다루마(달마) 캐릭터 노드.
## 플레이어가 감지 범위에 진입하면 힌트 라벨을 트윈으로 표시/숨김한다.
extends Node2D

## 스폰 기본 좌표.
const SPAWN_POSITION:= Vector2(683, 243)
## 힌트 텍스트를 표시하는 [RichTextLabel].
@onready var hint_label: RichTextLabel = %HintLabel
## 힌트 라벨의 원래 스케일. 트윈 복원 시 사용.
var hint_label_original_scale: Vector2

## 초기화 — 스폰 위치 설정 및 힌트 라벨 숨김.
func _ready() -> void:
	position = SPAWN_POSITION
	hint_label_original_scale = hint_label.scale
	set_hint(false)


## [Player]가 감지 영역에 진입하면 힌트를 표시한다.
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		set_hint(true)


## [Player]가 감지 영역에서 벗어나면 힌트를 숨긴다.
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		set_hint(false)

## 힌트 라벨의 표시 상태를 [param state]에 따라 트윈으로 전환한다.
## [code]true[/code]면 원래 스케일로 확대, [code]false[/code]면 [code]Vector2.ZERO[/code]로 축소.
func set_hint(state: bool):
	var target_scale: Vector2
	var tween:Tween = create_tween()
	if state:
		hint_label.show()
		target_scale = hint_label_original_scale
	else:
		target_scale = Vector2.ZERO
	
	tween.tween_property(hint_label, "scale", target_scale, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
