extends Node
class_name EventFloorManager
## [KR] 호감도 이벤트 층(러브 이벤트 플로어)을 관리한다.
## [EN] Manages the affection event floor (love event floor).
## [br][KR] 파트너 NPC의 호감도가 최대 경험치에 도달하면, 해당 레벨의 이벤트 스테이지를 준비하고
## [br][EN] When a partner NPC's affection reaches max experience, prepares the event stage for that level
## [KR] 레벨업 완료 후 보너스 티켓을 드롭한다.
## [EN] and drops bonus tickets after level-up completion.

## [KR] 부모로부터 가져오는 층 관리자 참조.
## [EN] Floor manager reference obtained from parent.
var floor_manager : FloorManager
## [KR] H씬 데이터 정의 인스턴스.
## [EN] H-scene data definition instance.
var h_scene_data := HSceneData.new()

## [KR] 경로에서 불러온 H씬 리소스 배열.
## [EN] H-scene resource array loaded from path.
var h_scene_res_array: Array = []

## [KR] 파트너 매니저 참조. 현재 파트너 변경 시그널을 수신한다.
## [EN] Partner manager reference. Receives current partner change signals.
@export var partner_manager : PartnerManager
## [KR] 현재 활성화된 러브 이벤트 스테이지 경로.
## [EN] Currently active love event stage path.
var current_love_stage_path : String


const TICKET_ICON = preload("res://resources/ui/ticket_icon.png")

## [KR] 시그널 연결 및 H씬 리소스를 미리 로드한다.
## [EN] Connects signals and pre-loads H-scene resources.
func _ready():
	GameEvents.npc_level_up_wating.connect(on_npc_level_up_wating)
	partner_manager.partner_change.connect(_on_partner_change)
	floor_manager = get_parent()
	
	h_scene_res_array = TrainUtil.get_res_from_path(h_scene_data.H_SCENE_DATA_PATH)


## [KR] NPC 레벨업 대기 상태일 때 이벤트 스테이지를 준비한다.
## [EN] Prepares the event stage when NPC is in level-up waiting state.
## [br][KR] 현재 파트너가 아니면 무시하고, 해당 레벨의 이벤트가 있으면 플로어를 잠금(lock) 상태로 전환한다.
## [br][EN] Ignores if not the current partner; transitions floor to locked state if an event exists for that level.
func on_npc_level_up_wating(npc:Npc):
	if !partner_manager.get_current_partner() == npc:
		return
	
	var current_event_stage := get_h_scene_path(npc.npc_name, npc.love_level)
	if current_event_stage == "":
		push_error("이벤트 스테이지 비어있음")
		return
	
	floor_manager.current_love_event_lock = true
	current_love_stage(current_event_stage)
	floor_manager.floor_setting(floor_manager.current_level)
	print("Event stage preparing : "+ str(current_event_stage))
	if not npc.love_level_up_event.is_connected(on_npc_level_up):
		npc.love_level_up_event.connect(on_npc_level_up)

## [KR] [param npc_type]과 [param love_level]에 해당하는 메인 러브 이벤트의 스테이지 이름을 반환한다.
## [EN] Returns the stage name of the main love event for [param npc_type] and [param love_level].
## [br][KR] 일치하는 리소스가 없으면 빈 문자열을 반환한다.
## [br][EN] Returns an empty string if no matching resource is found.
func get_h_scene_path(npc_type: int, love_level: int)->String:
	for i in h_scene_res_array:
		var res = i as HSceneRes
		if res.partner == npc_type:
			if res.love_ability == love_level and res.main_love_event:
				if res.stage_name == "":
					var res_name = res.resource_path.get_file().get_basename()
					push_error("%s의 stage_name이 비었습니다"%res_name)
				else:
					return res.stage_name
	return ""

## [KR] 파트너 변경 시 경험치 상태를 확인하여 이벤트 준비 또는 일반 상태로 복귀한다.
## [EN] Checks experience status on partner change and either prepares event or returns to normal state.
func _on_partner_change(_npc_type: int):
	var current_npc = partner_manager.get_current_partner() as Npc
	if current_npc.is_max_exp():
		on_npc_level_up_wating(current_npc)
	else:
		# [KR] 히로인 변경시 경험치가 안차있는경우 다시 일반상태로 바꿈
		# [EN] Return to normal state if experience is not full when changing heroine
		love_event_setting(false)

## [KR] NPC 레벨업 완료 시 이벤트 잠금을 해제하고 보너스 티켓을 드롭한다.
## [EN] Releases event lock and drops bonus tickets on NPC level-up completion.
func on_npc_level_up(_npc_type: int):
	love_event_setting(false)
	NotionEvent.notion("NOTI_LOVE_LEVEL_UP", Constants.SD_ICONS[_npc_type])
	var ticket_value:int = Constants.LOVE_LEVEL_UP_BONUS_TICKET #50*2개
	GameEvents.emit_drop_item(_npc_type, DropItemManager.ItemType.TICKET, ticket_value)
	var message = tr("NOTI_LOVE_LEVEL_UP_BONUS_TICKET")% (ticket_value * Constants.TICKET_VALUE_NORMAL)
	NotionEvent.notion(message, TICKET_ICON)

## [KR] 러브 이벤트 잠금 상태를 설정한다. [param lock]이 [code]false[/code]이면 잠금 해제 후 스테이지를 랜덤으로 변경한다.
## [EN] Sets the love event lock state. Unlocks and randomly changes stage if [param lock] is [code]false[/code].
func love_event_setting(lock := false):
	if lock:
		return
	else:
		floor_manager.current_love_event_lock = false
		current_love_stage_path = ""
		# [KR] 스테이지 랜덤으로 변경
		# [EN] Change stage randomly
		if floor_manager.current_level != null:
			floor_manager.floor_setting(floor_manager.current_level)

## [KR] 현재 러브 이벤트 스테이지 경로를 [param stage_name]으로 설정한다.
## [EN] Sets the current love event stage path to [param stage_name].
func current_love_stage(stage_name: String):
	current_love_stage_path = stage_name
