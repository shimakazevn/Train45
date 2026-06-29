## 퀘스트 조건 UI를 구성하고 클리어 여부를 판정하는 컴포넌트.
## [member quest_data]를 기반으로 [QuestSlot]을 동적으로 생성하며,
## 모든 조건 충족 시 [signal quest_clear]를 발행한다.
extends Control
class_name QuestComponent

## 현재 퀘스트 데이터 리소스.
## Why @export 필수: quest_component.tscn 기본값 및 stage_complete.tscn 등에서 인스펙터로
## quest_data를 지정한다. @export를 빼면 씬 저장 시 이 값이 떨어져 나가 quest_data=null이 되고,
## 슬롯 미생성 → check_quests_clear 미호출 → quest_clear 미발행 → TalkEvent가 항상 실패 처리된다.
@export var quest_data: QuestData
## 퀘스트 슬롯 프리팹 [PackedScene].
@export var quest_slot: PackedScene
## 퀘스트 슬롯이 배치되는 [VBoxContainer].
@onready var quest_list_container: VBoxContainer = %QuestListContainer
## 전체 클리어 시 표시되는 라벨.
@export var clear_label: Label

## 모든 퀘스트 항목이 클리어되었는지 여부.
var is_clear:= false

## 모든 퀘스트 조건이 충족되면 발행된다.
signal quest_clear

## [member quest_data]가 존재하면 퀘스트 정보를 설정한다.
func _ready() -> void:
	if quest_data:
		set_quest_info()


## [member quest_data]를 읽어 퀘스트 슬롯을 생성한다.
## 기존 슬롯을 모두 제거한 뒤 NPC 호감도, 티켓, 이변 수 등 조건별로 인스턴스를 추가한다.
func set_quest_info():
	for i in quest_list_container.get_children():
		if i is QuestSlot:
			if i.quest_cleared.is_connected(check_quests_clear):
				i.quest_cleared.disconnect(check_quests_clear)
		i.queue_free()
		await i.tree_exited

	for i in quest_data.npcs: # 엔피씨 호감도
		var quest_slot_instance = quest_slot.instantiate() as QuestSlot
		quest_slot_instance.quest_npc = i
		set_instance_quest(quest_slot_instance, quest_slot_instance.QuestType.LOVE, i.need_love)
	
	if quest_data.total_love != -1: # 호감도 합계
		var quest_slot_instance = quest_slot.instantiate() as QuestSlot
		set_instance_quest(quest_slot_instance, quest_slot_instance.QuestType.TOTAL_LOVE, quest_data.total_love)
	
	if quest_data.ticket != -1: # 현재 소지 티켓
		var quest_slot_instance = quest_slot.instantiate() as QuestSlot
		set_instance_quest(quest_slot_instance, quest_slot_instance.QuestType.TICKET, quest_data.ticket)
		
	if quest_data.route != -1: # 발견 이변 갯수
		var quest_slot_instance = quest_slot.instantiate() as QuestSlot
		set_instance_quest(quest_slot_instance, quest_slot_instance.QuestType.ROUTE, quest_data.route)
	
	if quest_data.collect_destinations != -1: # 발견 종착점 갯수
		var quest_slot_instance = quest_slot.instantiate() as QuestSlot
		set_instance_quest(quest_slot_instance, quest_slot_instance.QuestType.COLLECT_DESTINATION, quest_data.collect_destinations)
	
	if quest_data.collect_items != -1: # 수집한 아이템 갯수
		var quest_slot_instance = quest_slot.instantiate() as QuestSlot
		set_instance_quest(quest_slot_instance, quest_slot_instance.QuestType.COLLECT_ITEM, quest_data.collect_items)
	
	if quest_data.complete_count != -1: # 수집한 아이템 갯수
		var quest_slot_instance = quest_slot.instantiate() as QuestSlot
		set_instance_quest(quest_slot_instance, quest_slot_instance.QuestType.GOAL_COUNT, quest_data.complete_count)
		
	if quest_data.talk != "": # 그냥 텍스트만 띄움
		var quest_slot_instance = quest_slot.instantiate() as QuestSlot
		var type = quest_slot_instance.QuestType.TALK
		quest_slot_instance.type = type
		quest_slot_instance.quest_config[type]["text_key"] = quest_data.talk ## value가 아닌 text_key에 대입
		quest_list_container.add_child(quest_slot_instance)
	
	call_deferred("check_quests_clear")

## [param quest_slot_instance]에 [param quest_type]과 [param value]를 설정하고
## 컨테이너에 추가 + 클리어 시그널을 연결한다.
func set_instance_quest(quest_slot_instance:QuestSlot, quest_type: QuestSlot.QuestType, value: int):
	var type = quest_type
	quest_slot_instance.type = type
	quest_slot_instance.quest_config[type]["value"] = value
	quest_list_container.add_child(quest_slot_instance)
	quest_slot_instance.quest_cleared.connect(check_quests_clear)


## 모든 [QuestSlot]의 클리어 상태를 확인하여 전체 클리어 여부를 갱신한다.
## 전부 클리어되면 [signal quest_clear]를 발행한다.
func check_quests_clear():
	var _clear := true
	for i in quest_list_container.get_children():
		if not (i as QuestSlot).current_quest_clear:
			_clear = false
	
	#_clear = true # test
	
	if _clear:
		quest_clear.emit()
	set_clear_label(_clear)

	is_clear = _clear

## [param quest_id]가 현재 퀘스트와 일치하면 [member is_clear] 상태를 반환한다.
func get_is_all_clear(quest_id: String)-> bool:
	if quest_data.id == quest_id:
		return is_clear
	else:
		return false

## 클리어 라벨의 표시 여부를 [param state]에 따라 설정한다.
func set_clear_label(state: bool):
	clear_label.visible = state
