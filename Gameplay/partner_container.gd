## 파트너 UI 컨테이너. 스테이지 타입에 따라 슬라이드 인/아웃 애니메이션으로 표시 상태를 전환한다.
## 기지(BASE) 스테이지에서는 표시하고, 전투/안전 스테이지에서는 숨긴다.
extends Control

## 현재 스테이지 타입 정보를 가져오기 위한 [FloorManager] 참조.
@export var floor_manager: FloorManager

## 현재 활성화된 [Tween] 인스턴스.
var tween: Tween

## 컨테이너의 초기 위치. 슬라이드 애니메이션의 기준점으로 사용된다.
var base_position: Vector2
## 컨테이너를 화면 밖으로 이동시킬 때 사용하는 Y축 오프셋.
const OUTER_Y_OFFSET: float = 67

## 노드 준비 시 스테이지 이벤트 시그널을 연결하고, 초기 위치를 저장한다.
func _ready() -> void:
	GameEvents.stage_change.connect(_on_stage_change)
	GameEvents.in_next_stage.connect(_on_in_next_stage)
	GameEvents.stage_clear.connect(_on_stage_clear)
	base_position = self.position
	
## 스테이지 변경 시 타입에 따라 컨테이너를 표시하거나 숨긴다.
## [code]TYPE_BASE[/code]이면 표시, [code]TYPE_STAGE[/code] 또는 [code]TYPE_SAFE[/code]이면 숨긴다.
func _on_stage_change():
	var stage_type:= floor_manager.current_stage_type
	match stage_type:
		Constants.TYPE_BASE:
			set_show()
		Constants.TYPE_STAGE, Constants.TYPE_SAFE:
			set_out()

## 다음 스테이지 진입 시 호출되는 콜백. 현재는 미구현 상태.
func _on_in_next_stage():
	pass

## 스테이지 클리어 시 컨테이너를 다시 표시한다.
func _on_stage_clear():
	set_show()

## 컨테이너를 슬라이드 인하여 화면에 표시한다.
## [param wait_time]이 [code]0.0[/code]보다 크면 해당 시간 후 자동으로 [method set_out]을 호출한다.
func set_show(wait_time: float = 0.0):
	tween = create_tween()
	tween.tween_property(self, "position:y", base_position.y, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	if wait_time > 0.0:
		await get_tree().create_timer(wait_time).timeout
		set_out()

## 컨테이너를 아래로 슬라이드 아웃하여 화면에서 숨긴다.
func set_out():
	tween = create_tween()
	tween.tween_property(self, "position:y", base_position.y + OUTER_Y_OFFSET, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
