extends Node2D
## [KR] 대화(Dialog) 컨트롤러.
## [EN] Dialog controller.
## [KR] 플레이어와 NPC 간 대화 시작, H이벤트 진입, Dialogic 타임라인 제어를 담당한다.
## [EN] Handles dialogue initiation between player and NPC, H-event entry, and Dialogic timeline control.
## [KR] [FloorManager]·[PartnerManager]·[GlobalGameManager]와 협력하여 대화 조건을 판정한다.
## [EN] Cooperates with [FloorManager], [PartnerManager], and [GlobalGameManager] to determine dialogue conditions.

## [KR] 층 관리자 참조. 현재 스테이지 타입·이변 정보 접근에 사용.
## [EN] Floor manager reference. Used for accessing current stage type and anomaly info.
@export var floor_manager: FloorManager
## [KR] 파트너 관리자 참조. 대화 대상·호감도 정보 조회.
## [EN] Partner manager reference. Queries dialogue target and affection info.
@export var partner_manager: PartnerManager
## [KR] 글로벌 게임 매니저. 이벤트 읽음 기록 관리.
## [EN] Global game manager. Manages event read history.
@export var global_game_manager: GlobalGameManager
## [KR] 이벤트 재감상 확인용 컨펌 박스 UI.
## [EN] Confirm box UI for event replay confirmation.
@onready var confirm_box = $ConfirmBox

## [KR] 초기화. 대화·이벤트·Dialogic 시그널을 연결한다.
## [EN] Initialization. Connects dialogue, event, and Dialogic signals.
func _ready():
	GameEvents.player_talk.connect(on_talk)
	GameEvents.player_event.connect(on_event)
	Dialogic.signal_event.connect(_on_dialogic_signal)

## [KR] NPC와의 대화를 시작한다. Dialogic 변수를 설정한 뒤 적절한 타임라인을 재생.
## [EN] Starts dialogue with an NPC. Sets Dialogic variables then plays the appropriate timeline.
## [KR] [param label]이 [code]"quest_failed"[/code]이면 퀘스트 실패 분기로 진입한다.
## [EN] Enters the quest failed branch if [param label] is [code]"quest_failed"[/code].
func on_talk(npc: Npc, label: String = ""):
	var quest_failed:= false
	if label == "quest_failed":
		quest_failed = true
	
	anomaly_safety()
	Dialogic.VAR.npc.set('find_success', find_success(npc))
	
	# [KR] 공통 변수 설정
	# [EN] Set common variables
	partner_manager.current_talk(npc)
	Dialogic.VAR.npc.set('type', npc.npc_name)
	Dialogic.VAR.npc.set('love', partner_manager.get_current_talker().love_level)
	Dialogic.VAR.npc.set('current_partner', partner_manager.current_partner)
	
	# [KR] 대화 타입 결정
	# [EN] Determine dialogue type
	var talk_info: Dictionary = NpcTimelineData.get_talk_type(\
	npc, \
	floor_manager.current_stage_type, \
	floor_manager.current_complete_chapter, \
	floor_manager.current_anomaly_find, \
	floor_manager.current_prologue, \
	floor_manager.current_stage_extra_info, \
	quest_failed
	)
	var talk_type: String = talk_info["timeline"]
	label = talk_info["label"]
	
	# [KR] 파트너가 이변으로 변할때 지정 대사가 있으면 해당 타임라인 이동
	# [EN] When partner turns into anomaly, move to designated timeline if specific dialogue exists
	if floor_manager.current_level.npc_anomaly:
		label = floor_manager.current_level.npc_anomaly.anomaly_name
	
	# [KR] 대화 시작
	# [EN] Start dialogue
	if Dialogic.current_timeline == null and talk_type != "":
		Dialogic.start(talk_type, label)
		get_viewport().set_input_as_handled()

## [KR] H이벤트 영역 진입 시 호출. 이미 감상한 이벤트면 재감상 확인 팝업을 띄운다.
## [EN] Called on H-event area entry. Shows replay confirmation popup if the event was already viewed.
func on_event(event : EventArea):
	if event.event_enabled == true:
		if event.event_played():
			confirm_box.customize(
				"LEAD_AGAIN",
				"Replay",
				"LEAD_AGAIN_DESCRIPTION",
				"YES",
				"NO"
			)
			var is_confirmed = await confirm_box.prompt(true)
			if is_confirmed:
				dialog_event_start(event)
			else:
				event.no_event_replay_return_base()
		else:
			dialog_event_start(event)

## [KR] H이벤트 타임라인을 실제로 시작한다. 전환 화면 후 Dialogic 타임라인을 재생하고 읽음 기록을 저장.
## [EN] Actually starts the H-event timeline. Plays Dialogic timeline after transition screen and saves read history.
func dialog_event_start(event : EventArea):
	var event_res = event.h_scene_info as HSceneRes
	partner_manager.current_talker = event_res.partner
	Dialogic.VAR.npc.set('type', event_res.partner)
	if event_res.dialog_title == "":
		push_warning("event_name이 비어있습니다.")
	if Dialogic.current_timeline == null and event_res.dialog_title != "":
		TransitionScreen.transition()
		await TransitionScreen.on_transition_finishied
		GameEvents.anim_change("idle")
		Dialogic.start(event_res.dialog_title)
		global_game_manager.append_read_event_list(event_res.dialog_title)
		get_viewport().set_input_as_handled()

## [KR] 현재 스테이지 타입에 따라 Dialogic의 [code]anomaly_safe[/code] 변수를 설정한다.
## [EN] Sets the Dialogic [code]anomaly_safe[/code] variable based on the current stage type.
## [KR] 안전 구역이면 [code]true[/code], 일반 스테이지면 [code]false[/code].
## [EN] [code]true[/code] for safe zone, [code]false[/code] for normal stage.
func anomaly_safety():
	if floor_manager.current_stage_type == Constants.TYPE_STAGE:
		Dialogic.VAR.npc.set('anomaly_safe', false)	
	elif floor_manager.current_stage_type == Constants.TYPE_SAFE:
		Dialogic.VAR.npc.set('anomaly_safe', true)	

## [KR] NPC 탐색 성공 여부를 50% 확률로 판정한다.
## [EN] Determines NPC search success with 50% probability.
## [KR] [member Npc.find_count]가 0 이하이면 항상 실패.
## [EN] Always fails if [member Npc.find_count] is 0 or less.
func find_success(npc: Npc) -> bool:
	var find := false	
	if npc.find_count > 0:
		if randi() % 2 == 0:
			find = true
		else:
			find = false
	return find
		

## [KR] Dialogic [code]find_discount[/code] 시그널 수신 시 파트너의 탐색 횟수를 차감한다.
## [EN] Deducts the partner's search count when receiving Dialogic [code]find_discount[/code] signal.
func _on_dialogic_signal(arg: String):
	if arg == "find_discount":
		partner_manager.find_discount()
		
