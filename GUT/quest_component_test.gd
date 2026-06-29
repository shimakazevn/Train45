## QuestComponent 단위 테스트
## check_quests_clear, get_is_all_clear, set_clear_label의 동작을 검증한다.
##
## 전략:
##   - quest_component.tscn을 인스턴스화하되 quest_data를 null로 덮어써
##     _ready()의 set_quest_info() 호출을 방지한다.
##   - 씬에 사전 배치된 QuestSlot의 current_quest_clear를 직접 조작해
##     MetaProgression 의존 없이 클리어 판정 로직만 검증한다.
extends GutTest
class_name QuestComponentTest

const QUEST_COMPONENT_SCENE := preload("res://Gameplay/Ui/quest_component.tscn")
const QUEST_SLOT_SCENE     := preload("res://Gameplay/Ui/quest_slot.tscn")

var _component: QuestComponent

# ---------------------------------------------------------------------------
# 훅
# ---------------------------------------------------------------------------

func before_each() -> void:
	_component = autofree(QUEST_COMPONENT_SCENE.instantiate()) as QuestComponent
	# null을 넣어 _ready()에서 set_quest_info()가 호출되지 않도록 한다.
	# 씬에 사전 배치된 QuestSlot은 type 미설정 → value=-1 → current_quest_clear=false 상태가 된다.
	_component.quest_data = null
	add_child(_component)
	await get_tree().process_frame


# ===========================================================================
# check_quests_clear
# ===========================================================================

## 슬롯이 1개이고 클리어 상태일 때 quest_clear 시그널이 발행된다.
func test_single_slot_cleared_emits_quest_clear_signal() -> void:
	_set_all_slots(_component.quest_list_container, true)

	watch_signals(_component)
	_component.check_quests_clear()

	assert_signal_emitted(_component, "quest_clear")


## 슬롯이 1개이고 클리어 상태일 때 is_clear가 true로 갱신된다.
func test_single_slot_cleared_sets_is_clear_true() -> void:
	_set_all_slots(_component.quest_list_container, true)

	_component.check_quests_clear()

	assert_true(_component.is_clear)


## 슬롯이 1개이고 미클리어 상태일 때 quest_clear 시그널이 발행되지 않는다.
func test_single_slot_not_cleared_does_not_emit_signal() -> void:
	_set_all_slots(_component.quest_list_container, false)

	watch_signals(_component)
	_component.check_quests_clear()

	assert_signal_not_emitted(_component, "quest_clear")


## 슬롯이 1개이고 미클리어 상태일 때 is_clear가 false로 유지된다.
func test_single_slot_not_cleared_sets_is_clear_false() -> void:
	_set_all_slots(_component.quest_list_container, false)

	_component.check_quests_clear()

	assert_false(_component.is_clear)


## 슬롯이 2개이고 모두 클리어 상태일 때 quest_clear 시그널이 발행된다.
func test_multiple_slots_all_cleared_emits_signal() -> void:
	var extra := _add_slot()
	# 추가된 슬롯과 사전 배치 슬롯 모두 클리어 상태로 설정
	extra.current_quest_clear = true
	_set_all_slots(_component.quest_list_container, true)

	watch_signals(_component)
	_component.check_quests_clear()

	assert_signal_emitted(_component, "quest_clear")


## 슬롯이 2개이고 일부만 클리어 상태일 때 quest_clear 시그널이 발행되지 않는다.
func test_multiple_slots_partial_clear_does_not_emit_signal() -> void:
	var extra := _add_slot()
	extra.current_quest_clear = true           # 추가 슬롯: 클리어

	# 사전 배치 슬롯은 미클리어 상태로 유지
	for child in _component.quest_list_container.get_children():
		if child is QuestSlot and child != extra:
			child.current_quest_clear = false

	watch_signals(_component)
	_component.check_quests_clear()

	assert_signal_not_emitted(_component, "quest_clear")


## is_clear가 true였다가 미클리어 슬롯이 생기면 false로 재설정된다.
func test_is_clear_resets_to_false_when_slot_becomes_uncleared() -> void:
	# 먼저 클리어 상태로 만든다
	_set_all_slots(_component.quest_list_container, true)
	_component.check_quests_clear()
	assert_true(_component.is_clear)

	# 슬롯을 미클리어로 되돌린다
	_set_all_slots(_component.quest_list_container, false)
	_component.check_quests_clear()

	assert_false(_component.is_clear)


# ===========================================================================
# get_is_all_clear
# ===========================================================================

## quest_data.id가 일치하고 is_clear=true이면 true를 반환한다.
func test_get_is_all_clear_matching_id_and_cleared_returns_true() -> void:
	#var data := QuestData.new()
	#data.id = "quest_1"
	#_component.quest_data = data
	_component.is_clear = true

	assert_true(_component.get_is_all_clear("quest_1"))


## quest_data.id가 일치해도 is_clear=false이면 false를 반환한다.
func test_get_is_all_clear_matching_id_but_not_cleared_returns_false() -> void:
	#var data := QuestData.new()
	#data.id = "quest_1"
	#_component.quest_data = data
	_component.is_clear = false

	assert_false(_component.get_is_all_clear("quest_1"))


## quest_data.id가 다르면 is_clear=true여도 false를 반환한다.
func test_get_is_all_clear_wrong_id_returns_false() -> void:
	#var data := QuestData.new()
	#data.id = "quest_1"
	#_component.quest_data = data
	_component.is_clear = true

	assert_false(_component.get_is_all_clear("quest_2"))


## 챕터 간 퀘스트 전환 시 이전 챕터 ID로 조회하면 false를 반환한다.
func test_get_is_all_clear_returns_false_for_previous_chapter_id() -> void:
	#var data := QuestData.new()
	#data.id = "quest_2"          # 현재는 챕터 2 퀘스트
	#_component.quest_data = data
	_component.is_clear = true

	# 챕터 1 ID로 조회 → 관계없는 챕터이므로 false
	assert_false(_component.get_is_all_clear("quest_1"))


# ===========================================================================
# set_clear_label
# ===========================================================================

## state=true이면 clear_label이 표시된다.
func test_set_clear_label_shows_label_when_true() -> void:
	_component.set_clear_label(true)

	assert_true(_component.clear_label.visible)


## state=false이면 clear_label이 숨겨진다.
func test_set_clear_label_hides_label_when_false() -> void:
	_component.set_clear_label(false)

	assert_false(_component.clear_label.visible)


## check_quests_clear가 전체 클리어 시 clear_label을 자동으로 표시한다.
func test_check_quests_clear_shows_label_on_full_clear() -> void:
	_set_all_slots(_component.quest_list_container, true)

	_component.check_quests_clear()

	assert_true(_component.clear_label.visible)


## check_quests_clear가 미클리어 시 clear_label을 자동으로 숨긴다.
func test_check_quests_clear_hides_label_when_not_cleared() -> void:
	_set_all_slots(_component.quest_list_container, false)

	_component.check_quests_clear()

	assert_false(_component.clear_label.visible)


# ===========================================================================
# 헬퍼
# ===========================================================================

## 컨테이너 내 모든 QuestSlot의 current_quest_clear를 [param state]로 설정한다.
func _set_all_slots(container: VBoxContainer, state: bool) -> void:
	for child in container.get_children():
		if child is QuestSlot:
			child.current_quest_clear = state


## quest_slot.tscn을 인스턴스화해 컨테이너에 추가하고 반환한다.
## _ready()가 동기적으로 실행된 뒤 반환되므로 current_quest_clear는 이후에 덮어쓴다.
func _add_slot() -> QuestSlot:
	var slot := autofree(QUEST_SLOT_SCENE.instantiate()) as QuestSlot
	_component.quest_list_container.add_child(slot)
	return slot
