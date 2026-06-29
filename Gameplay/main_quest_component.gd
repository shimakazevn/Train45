extends QuestComponent
class_name MainQuestComponent
## [KR] 메인 퀘스트 UI 컴포넌트.
## [EN] Main quest UI component.
## [br][KR] 챕터별 메인 퀘스트 진행 상태를 추적하고, 퀘스트 목록 UI를 갱신한다.
## [br][EN] Tracks main quest progress per chapter and updates the quest list UI.
## [KR] 다이얼로그·상점 등 다른 창이 열리면 퀘스트 UI를 숨긴다.
## [EN] Hides the quest UI when other windows like dialogue or shop are open.

## [KR] 층 관리자 참조. 현재 스테이지 타입 확인에 사용.
## [EN] Floor manager reference. Used for checking current stage type.
@export var floor_manager: FloorManager
## [KR] 상점 매니저 참조. 상점 열림/닫힘 상태 감지에 사용.
## [EN] Shop manager reference. Used for detecting shop open/close state.
@export var upgrade_manager: UpgradeManager

# Why: .tres의 스크립트(quest.gd)가 먼저 로드된 상태에서 .tres를 preload하면 Godot 버그로
# 스크립트 없는 generic Resource로 굳는다(타입 대입/is 실패). load()(런타임)는 정상이므로
# 경로 상수만 두고 get_main_quest()에서 load()로 불러온다.
const QUEST_1 := "res://Gameplay/GameData/QuestData/quest_1.tres"
const QUEST_2 := "res://Gameplay/GameData/QuestData/quest_2.tres"
const QUEST_3 := "res://Gameplay/GameData/QuestData/quest_3.tres"
const QUEST_4 := "res://Gameplay/GameData/QuestData/quest_4.tres"
const QUEST_4_2 := "res://Gameplay/GameData/QuestData/quest_4_2.tres"
const QUEST_4_3 := "res://Gameplay/GameData/QuestData/quest_4_3.tres"
const QUEST_5 := "res://Gameplay/GameData/QuestData/quest_5.tres"
const QUEST_5_2 := "res://Gameplay/GameData/QuestData/quest_5_2.tres"
const QUEST_6 := "res://Gameplay/GameData/QuestData/quest_6.tres"
const QUEST_6_2 := "res://Gameplay/GameData/QuestData/quest_6_2.tres"

## [KR] 다른 창(다이얼로그, 상점 등)이 열려 있는지 여부.
## [EN] Whether other windows (dialogue, shop, etc.) are open.
var current_other_window_open := false

## [KR] 시그널 연결 및 초기 퀘스트 상태를 갱신한다.
## [EN] Connects signals and updates initial quest state.
func _ready() -> void:
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	upgrade_manager.shop_state_changed.connect(_on_shop_state_changed)
	GameEvents.stage_change.connect(_on_stage_change)
	main_quest_update()

## [KR] 현재 챕터에 맞는 메인 퀘스트를 조회하고 퀘스트 목록 UI를 갱신한다.
## [EN] Queries the main quest matching the current chapter and updates the quest list UI.
func main_quest_update():
	quest_data = get_main_quest()
	for i in quest_list_container.get_children():
		i.queue_free()
		await i.tree_exited
	if quest_data:
		set_quest_info()

## [KR] 현재 챕터와 읽은 이벤트를 기반으로 활성화할 메인 퀘스트 리소스를 반환한다.
## [EN] Returns the main quest resource to activate based on current chapter and read events.
## [br]Why: 챕터 4~6은 이벤트 분기에 따라 퀘스트가 달라지므로, [method MetaProgression.has_read_event]로 분기를 판별한다.
func get_main_quest()->Resource:
	match MetaProgression.get_current_chapter():
		1:
			return _load_quest(QUEST_1)
		2:
			return _load_quest(QUEST_2)
		3:
			return _load_quest(QUEST_3)
		4:
			if MetaProgression.has_read_event("chapter4_butler"):
				if not MetaProgression.has_read_event(Constants.QUESTLINE_KANKANNAVI_GET): # [KR] 칸칸네비 획득 여부 / [EN] Whether KankanNavi is acquired
					return _load_quest(QUEST_4)
				else:
					return _load_quest(QUEST_4_2)
			else:
				return null
		5:
			if MetaProgression.has_read_event("chapter5_start"):
				return _load_quest(QUEST_5_2)
			elif MetaProgression.has_read_event("chapter4_butler3"):
				return _load_quest(QUEST_5)
			elif MetaProgression.has_read_event("chapter4_butler4"):
				return _load_quest(QUEST_4_3)
			else:
				return null
		6:
			if MetaProgression.has_read_event("chapter6_start"):
				if not MetaProgression.has_read_event("konial_love_0"):
					return _load_quest(QUEST_6)
				else:
					return _load_quest(QUEST_6_2)
			else:
				return null

	return null

## [KR] 퀘스트 .tres를 load하고 스크립트(QuestData) 부착 여부를 검증·로깅한다.
## [br]Why: preload 버그로 스크립트 없는 generic Resource로 로드되면 여기서 조기에 잡기 위함.
## [br]정상 로드는 디버그 빌드에서만 print, 실패는 항상 push_error로 알린다.
func _load_quest(path: String) -> Resource:
	var res := load(path)
	if res is QuestData:
		if OS.is_debug_build():
			print("[Quest] Load succeeded: %s (id=%s)" % [path.get_file(), res.id])
	else:
		push_error("[퀘스트] 로드 실패: 스크립트 미부착(generic Resource). 어딘가에서 이 .tres를 preload하는지 확인 필요. path=%s" % path)
	return res

## [KR] 스테이지 변경 시 퀘스트 UI를 갱신한다. 기지(TYPE_BASE)에서만 표시하고 그 외에는 숨긴다.
## [EN] Updates quest UI on stage change. Shows only on base (TYPE_BASE), hides otherwise.
func _on_stage_change():
	if floor_manager.current_level == null:
		return
	
	call_deferred("main_quest_update")
	call_deferred("check_quests_clear")
	
	if floor_manager.current_stage_type == Constants.TYPE_BASE:
		show()
		var next_quest = get_main_quest()
		if quest_data == next_quest:
			return

		for i in quest_list_container.get_children():
			i.queue_free()
			await i.tree_exited
		
		quest_data = next_quest
		if quest_data:
			set_quest_info()
	else:
		hide()

## [KR] Dialogic 타임라인 시작 시 퀘스트 UI를 숨긴다.
## [EN] Hides quest UI when Dialogic timeline starts.
func _on_timeline_started():
	view_enable(false)

## [KR] Dialogic 타임라인 종료 시 퀘스트 UI를 다시 표시한다.
## [EN] Shows quest UI again when Dialogic timeline ends.
## [br][KR] 단, 다른 창이 열려 있으면 표시하지 않는다.
## [br][EN] However, does not show if other windows are open.
func _on_timeline_ended():
	if current_other_window_open:
		return
	view_enable(true)

## [KR] 상점 상태 변경 콜백. 상점이 열리면 퀘스트 UI를 숨기고, 닫히면 다시 표시한다.
## [EN] Shop state change callback. Hides quest UI when shop opens, shows again when closed.
func _on_shop_state_changed(state: int):
	if state == upgrade_manager.ShopState.OPEN:
		current_other_window_open = true
		view_enable(false)
	else:
		current_other_window_open = false
		view_enable(true)

## [KR] 퀘스트 UI 표시 여부를 [param state]에 따라 제어한다.
## [EN] Controls quest UI visibility based on [param state].
## [br]Why: 챕터 4~6은 이벤트 분기가 동적이므로, 표시 시점에 퀘스트를 다시 갱신해야 한다.
func view_enable(state: bool):
	if state:
		if floor_manager.current_stage_type == Constants.TYPE_BASE:
			if MetaProgression.get_current_chapter() == 4:
				call_deferred("main_quest_update")

			if MetaProgression.get_current_chapter() == 5:
				call_deferred("main_quest_update")

			if MetaProgression.get_current_chapter() == 6:
				call_deferred("main_quest_update")
			show()
	else:
		if floor_manager.current_stage_type == Constants.TYPE_BASE:
			hide()

## [KR] 클리어 라벨 표시를 설정한다 (현재 미사용).
## [EN] Sets clear label display (currently unused).
func set_clear_label(_state: bool):
	pass

## [KR] 퀘스트 클리어 여부를 반환한다.
## [EN] Returns whether the quest is cleared.
func get_is_clear_check()-> bool:
	return is_clear
