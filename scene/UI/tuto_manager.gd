## 튜토리얼 관리자.
## [br][br]
## 게임 진행 상황(스테이지 변경, NPC 레벨업, Dialogic 시그널 등)에 따라
## 적절한 튜토리얼을 자동으로 트리거한다.
## [MetaProgression]을 통해 이미 읽은 튜토리얼은 다시 표시하지 않는다.
extends Node
class_name TutoManager

## 튜토리얼 페이지 UI를 관리하는 [TutorialPage] 노드.
@export var tutorial_page: TutorialPage

## 테스트용 튜토리얼 ID.
const TEST_TUTO := "test_tuto"
## "탐색" 튜토리얼 ID.
const TUTO_FIND := "find"
## 기본 H 이벤트 튜토리얼 ID.
const TUTO_BASE_H_EVENT := "base_h_event"
## 에로 게이지 튜토리얼 ID.
const TUTO_ERO_GAGE := "ero_gage"
## 인벤토리 튜토리얼 ID.
const TUTO_INVEN := "inven"
## 집사 H 튜토리얼 ID.
const TUTO_BUTLER_H := "butler_h"
## 노선 구매 모드 튜토리얼 ID.
const TUTO_ROUTE_BUY_MODE := "tuto_route_buy_mode"
## 코니알 H 튜토리얼 ID.
const TUTO_KONIAL_H := "tuto_konial_h"
## 유령 이상현상 H 튜토리얼 ID.
const TUTO_GHOST_H := "anomaly_ghost_h"
## 기본 H 액션 튜토리얼 ID.
const TUTO_BASE_H_ACTION := "tuto_base_h_action"

## 튜토리얼 리소스 파일 경로.
const TUTO_RES_PATH = "res://Gameplay/GameData/Tutorials/"

## 경로에서 로드한 튜토리얼 리소스 배열.
var tuto_res_array : Array = TrainUtil.get_res_from_path(TUTO_RES_PATH)

## 튜토리얼 ID를 키로 하는 [Tutos] 리소스 딕셔너리.
var tuto_data : Dictionary = {}

## 초기화 시 리소스를 로드하고 게임 이벤트 시그널을 구독한다.
func _ready() -> void:
	init_res_path()
	
	GameEvents.call_tutorial.connect(_on_call_tutorial)
	GameEvents.stage_change.connect(_on_stage_changed)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	if tutorial_page.partner_manager:
		for i in tutorial_page.partner_manager.partner:
			var _npc = i as Npc
			if not _npc.love_level_up_event.is_connected(_on_npc_level_up):
				_npc.love_level_up_event.connect(_on_npc_level_up)
	else:
		push_warning("partner_manager 없음")

## [member tuto_res_array]의 리소스를 ID 기반으로 [member tuto_data] 딕셔너리에 등록한다.
func init_res_path():
	for res in tuto_res_array:
		if res is Tutos and (res as Tutos).id != "":
			tuto_data[res.id] = res
		else:
			push_warning("튜토리얼 리소스 ID가 비어있거나 잘못된 타입입니다: %s" % res.resource_path)

#스테이지가 변경될 때 발생하는 튜토리얼
func _on_stage_changed():
	if MetaProgression.get_current_chapter() == 1:
		if GameEvents.get_current_stage_changing_screen():
			await GameEvents.stage_transition_ended
		call_unlead_tuto(TUTO_FIND)
		

#히로인 레벨 업 시 발생하는 튜토리얼
func _on_npc_level_up(npc_type: int):
	var _love_level = tutorial_page.partner_manager.partner[npc_type].love_level
	if _love_level >= NpcData.UNLOCK_LEVEL_BASE_H:
		call_unlead_tuto(TUTO_BASE_H_EVENT)
	
	## 게임 플레이 방식 변경으로 튜토를 병합
	#if _love_level >= NpcData.UNLOCK_LEVEL_STACK_TICKET:
		#call_unlead_tuto(TUTO_ERO_GAGE)

#대화창 이벤트
func _on_dialogic_signal(arg: String):
	var target_tuto: String = get_call_dialog_timeline(arg)
	call_unlead_tuto(target_tuto)

## Dialogic 시그널 인자 [param arg]를 대응하는 튜토리얼 ID로 변환한다.
func get_call_dialog_timeline(arg)->String:
	match arg:
		"inven":
			return TUTO_INVEN
		"butler_h":
			return TUTO_BUTLER_H
		"route_buy_mode":
			return TUTO_ROUTE_BUY_MODE
		"tuto_konial_h":
			return TUTO_KONIAL_H
	return ""

## 아직 읽지 않은 튜토리얼 [param tuto_name]을 표시한다.[br]
## [param next_focus_button]이 지정되면 튜토리얼 종료 후 해당 버튼에 포커스를 준다.
func call_unlead_tuto(tuto_name: String, next_focus_button: Button = null):
	if tuto_name == "":
		return
	
	if not MetaProgression.has_read_event(tuto_name):
		if tuto_data.has(tuto_name):
			tutorial_page.start_tutorial(tuto_name, next_focus_button)
			
			if tuto_name == TUTO_FIND:
				MetaProgression.auto_save() ## 프롤로그 끝나고 자동저장 1회
		else:
			push_warning("튜토리얼 ID '%s'에 해당하는 리소스를 찾을 수 없습니다." % tuto_name)

## [signal GameEvents.call_tutorial] 시그널 핸들러. [method call_unlead_tuto]를 호출한다.
func _on_call_tutorial(tuto_name: String, next_focus_button: Button = null):
	call_unlead_tuto(tuto_name, next_focus_button)
