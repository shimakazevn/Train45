## [KR] 이벤트 관련 기능을 제공하는 컴포넌트.
## 퀘스트 처리, 다이얼로그 시작, 파트너 매칭 검증 등의 이벤트 로직을 담당한다.
## [EN] Component providing event-related functionality.
## Handles event logic including quest processing, dialogue start, and partner matching validation.
class_name EventComponent
extends Node

## [KR] 노드 준비 시 퀘스트 진행 시그널에 콜백을 연결한다.
## [EN] Connects callback to quest progress signal on node ready.
func _ready():
	GameEvents.quest_process.connect(_on_quest_process)

## [KR] 퀘스트 진행 시그널 콜백. 하위 클래스에서 오버라이드하여 사용한다.
## [param _quest_str]: 처리할 퀘스트 식별 문자열
## [EN] Quest progress signal callback. Override in subclasses to use.
## [param _quest_str]: quest identifier string to process
func _on_quest_process(_quest_str: String):
	pass

## [KR] 지정한 다이얼로그 타임라인을 재생한다.
## [param target_partner]를 지정하지 않으면 카메라 이동 없이 재생하며,
## [param is_current_partner]가 [code]true[/code]이면 현재 동행 파트너와 대화한다.
## [param dialog_name]: Dialogic 타임라인 이름
## [param label]: 시작할 라벨 (빈 문자열이면 처음부터 재생)
## [param target_partner]: 대화 대상 파트너 ID ([code]-1[/code]이면 카메라 이동 없음)
## [param is_current_partner]: [code]true[/code]이면 현재 파트너를 대화 대상으로 설정
## [EN] Plays the specified dialogue timeline.
## If [param target_partner] is not specified, plays without camera movement.
## When [param is_current_partner] is [code]true[/code], talks with the current companion partner.
## [param dialog_name]: Dialogic timeline name
## [param label]: starting label (empty string plays from beginning)
## [param target_partner]: dialogue target partner ID ([code]-1[/code] means no camera movement)
## [param is_current_partner]: [code]true[/code] sets the current partner as the dialogue target
func dialog_start(dialog_name: String, label: String = "", target_partner: int = -1, is_current_partner:bool = false):
	if Dialogic.current_timeline:
		push_warning("dialog_start blocked: '%s' (current: %s)" % [dialog_name, Dialogic.current_timeline.resource_path])
		return
	var partner_manager = get_tree().get_first_node_in_group("partnermanager") as PartnerManager
	if is_current_partner:
		partner_manager.current_talker = partner_manager.current_partner
	else:
		partner_manager.current_talker = target_partner
		
	if target_partner != -1:
		Dialogic.VAR.npc.set('type', partner_manager.current_partner)
		Dialogic.VAR.npc.set('love', partner_manager.get_current_talker().love_level)
		Dialogic.VAR.npc.set('current_partner', partner_manager.current_partner)
	Dialogic.start(dialog_name, label)

## [KR] 종착점에서 현재 동행 파트너가 이벤트 대상과 다를 경우 시작 지점으로 돌아간다.
## 파트너 불일치 시 2초 대기 후 "not_matching_partner" 다이얼로그를 재생한다.
## [param event_partner_type]: 이벤트에서 요구하는 파트너 타입 ID
## [EN] Returns to starting point at the endpoint if the current companion partner differs from event target.
## On partner mismatch, waits 2 seconds then plays "not_matching_partner" dialogue.
## [param event_partner_type]: partner type ID required by the event
func not_matching_partner_return_base(event_partner_type: int):
	var partner_manager:PartnerManager = get_tree().get_first_node_in_group("partnermanager")
	if partner_manager.current_partner != event_partner_type:
		await get_tree().create_timer(2.0).timeout
		dialog_start("stage_complete_partner", "not_matching_partner")
