## 스테이지 힌트(노선 설명)를 관리하고 말풍선 UI로 표시하는 매니저.
## 실패한 스테이지에 재진입 시 이전 힌트를 다시 보여주는 기능을 포함한다.
extends Node
class_name FloorHintManager

## 힌트 말풍선 UI를 인스턴스화할 [PackedScene] 템플릿
@export var stage_hint_bubble_component: PackedScene
## 현재 스테이지의 힌트 문자열
var current_stage_hint: String
## 직전 스테이지의 힌트 문자열
var before_stage_hint: String
## 가장 최근 실패한 스테이지의 힌트를 저장 — 재진입 시 자동 표시에 사용
var failed_stage_hint: String #가장 최근 실패했던 스테이지 힌트를 저장
## 노선 데이터에서 힌트 설명을 조회하기 위한 [RouteData] 인스턴스
var route_data:= RouteData.new()

## [param current_stage]의 스테이지 타입에 따라 힌트 문자열을 설정한다.
## 이전에 실패한 스테이지와 동일하면 말풍선 힌트를 자동으로 표시한다.
func set_current_stage_hint(current_stage: Level):
	if current_stage == null:
		return

	if failed_stage_hint == route_data.get_route_description(current_stage) and failed_stage_hint != "":
		#print("힌트 스테이지 재등장")
		show_stage_bubble_hint(current_stage, failed_stage_hint)
	before_stage_hint = current_stage_hint

	if current_stage.stage_type == Constants.TYPE_STAGE:
		current_stage_hint = route_data.get_route_description(current_stage)
	elif current_stage.stage_type == Constants.TYPE_SAFE:
		current_stage_hint = "ROUTE_INFO_SAFEROOM"
	else:
		current_stage_hint = ""

## 직전 스테이지의 힌트 설명 문자열을 반환한다.
func get_before_stage_description()-> String:
	return before_stage_hint

## 실패한 스테이지 힌트를 저장한다.
## 해당 스테이지에 재진입 시 [method set_current_stage_hint]에서 자동으로 말풍선을 표시하기 위함.
func set_failed_stage_hint(before_hint: String):
	failed_stage_hint = before_hint

## [param current_level]에 힌트 말풍선 인스턴스를 생성하고,
## 스테이지 시작 시 [param stage_hint] 텍스트를 표시하도록 연결한다.
func show_stage_bubble_hint(current_level: Level, stage_hint: String):
	var stage_hint_bubble_instance:StageHintBubbleComponent = stage_hint_bubble_component.instantiate()
	current_level.stage_start.connect(stage_hint_bubble_instance.show_stage_hint.bind(stage_hint))
	stage_hint_bubble_instance.position = Vector2(26,10)
	current_level.add_child(stage_hint_bubble_instance)
