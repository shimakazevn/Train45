extends Node
class_name PartnerManager
## [KR] 파트너 NPC 관리 클래스.
## [EN] Partner NPC management class.
## [KR] 모든 NPC의 호감도, 경험치, 정념 게이지, 티켓 등의 상태를 중앙에서 관리한다.
## [EN] Centrally manages affection, experience, desire gauge, tickets, and other states for all NPCs.
## [KR] [Npc] 인스턴스 배열([member partner])을 보유하며 [MetaProgression]과 동기화한다.
## [EN] Holds an array of [Npc] instances ([member partner]) and synchronizes with [MetaProgression].

## [KR] 현재 파트너가 변경될 때 발생. [param npc_type]은 새 파트너 타입.
## [EN] Emitted when the current partner changes. [param npc_type] is the new partner type.
signal partner_change(npc_type:NpcType)
## [KR] 호감도 게이지가 갱신될 때 발생. [param gage]는 현재 경험치.
## [EN] Emitted when the affection gauge is updated. [param gage] is the current experience.
signal love_gage_update(npc_type:NpcType, gage: int)
## [KR] 정념 게이지가 갱신될 때 발생. [param gage]는 현재 정념 값.
## [EN] Emitted when the desire gauge is updated. [param gage] is the current desire value.
signal ero_gage_update(npc_type:NpcType, gage: int)
## [KR] 정념 스택이 갱신될 때 발생. [param gauge]는 현재 스택 값.
## [EN] Emitted when the desire stack is updated. [param gauge] is the current stack value.
signal ero_stack_update(npc_type:NpcType, gauge: float)
## [KR] 자유 H씬 파트너가 변경될 때 발생.
## [EN] Emitted when the free H-scene partner changes.
signal current_free_h_partner_update(npc_type:NpcType)
## [KR] 자유 행동이 종료될 때 발생.
## [EN] Emitted when free action ends.
signal free_action_end()

## [KR] NPC 타입 열거형. [code]NONE[/code](-1)은 미선택 상태.
## [EN] NPC type enum. [code]NONE[/code](-1) is unselected state.
enum NpcType { NONE = -1, REINA, MAI, KONIAL, PAZUZU, BUTLER }

## [KR] 현재 층 관리자 참조.
## [EN] Reference to the current floor manager.
@export var floor_manager: FloorManager
## [KR] 부모 Gameplay 노드 참조.
## [EN] Reference to the parent Gameplay node.
@onready var gameplay: Gameplay = $".."
## [KR] 현재 파트너 정보를 표시하는 UI 컴포넌트.
## [EN] UI component that displays current partner information.
@onready var current_partner_ui = %CurrentPartnerUI
## [KR] NPC별 PackedScene 배열. 인스턴스화하여 [member partner]에 저장.
## [EN] Array of PackedScenes per NPC. Instantiated and stored in [member partner].
@export var partner_love: Array[PackedScene] = []
## [KR] 인스턴스화된 [Npc] 객체 배열. 인덱스가 NPC 타입에 대응.
## [EN] Array of instantiated [Npc] objects. Index corresponds to NPC type.
var partner :Array = [Npc]
## [KR] 디버그용 호감도 레벨 오버라이드 배열.
## [EN] Affection level override array for debugging.
@export var test_love_level : Array[int]

## [KR] 현재 대화 중인 NPC 타입.
## [EN] Currently talking NPC type.
var current_talker: int
## [KR] 현재 선택된 파트너 NPC 인덱스.
## [EN] Currently selected partner NPC index.
var current_partner := 0
## [KR] 현재 이벤트에서 요구하는 호감도 레벨. -1이면 이벤트 없음.
## [EN] Affection level required by the current event. -1 means no event.
var current_event_love_level := -1
## [KR] 현재 자유 H씬 대상 파트너. [code]NONE[/code]이면 미선택.
## [EN] Current free H-scene target partner. [code]NONE[/code] if unselected.
var current_free_h_partner : NpcType = NpcType.NONE

## [KR] 초기화. 게임 이벤트·Dialogic 시그널을 연결하고, 세이브 데이터에서 NPC 상태를 복원한다.
## [EN] Initialization. Connects game event and Dialogic signals, and restores NPC state from save data.
func _ready():
	GameEvents.npc_level_up.connect(on_npc_level_up)
	GameEvents.forcefix_current_event_love_level.connect(forcefix_current_event_love_level)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	GameEvents.get_npc_exp.connect(_on_get_npc_exp)
	GameEvents.get_ero_gauge.connect(_on_get_ero_gauge)
	GameEvents.collect_stack_ticket.connect(collect_npc_stack_ticket)
	GameEvents.stage_clear.connect(_on_stage_clear)
	GameEvents.player_event.connect(_on_h_event)
	self.current_free_h_partner_update.connect(_on_free_h_partner_change)
	
	# [KR] partner 배열을 파트너 씬의 수만큼 초기화
	# [EN] Initialize partner array to the number of partner scenes
	partner.resize(partner_love.size())
	if Constants.SCENE_DEBUG:
		current_partner = gameplay.debug_npc
	else:
		current_partner = MetaProgression.get_current_partner()
	
	# [KR] 파트너 씬을 인스턴스화하고 partner 배열에 추가
	# [EN] Instantiate partner scenes and add to partner array
	for i in range(partner_love.size()):
		partner[i] = partner_love[i].instantiate() as Npc
		partner[i].data_only = true
		add_child(partner[i])
		partner[i].hide()
		partner[i].remove_from_group("npc")
		var save_npc_info :Dictionary = MetaProgression.get_npc_info(partner[i]) as Dictionary
		if save_npc_info.is_empty():
			partner[i].love_level = 0
			partner[i].target_love_exp = set_target_exp(partner[i].npc_name, 0)
			partner[i].love_exp = 0
		else:
			partner[i].love_level = MetaProgression.get_npc_love_level(i)
			partner[i].target_love_exp = set_target_exp(partner[i].npc_name , partner[i].love_level)
			partner[i].get_exp(MetaProgression.get_npc_current_exp(i))
		partner[i].stack_ticket = MetaProgression.get_npc_stack_ticket(i)
		partner[i].ero_gage = MetaProgression.get_npc_ero_gage(i)
		
		
		if test_love_level[i] > 0:
			partner[i].love_level += test_love_level[i]
			push_warning("테스트로 호감도를 조정했습니다.")

	# [KR] 디버그용 호감도 레벨 조정
	# [EN] Adjust affection level for debugging
	if Constants.SCENE_DEBUG:
		partner[current_partner].love_level = gameplay.debug_npc_love_level

	partner_setting(current_partner)


## [KR] Dialogic [code]set_partner[/code] 시그널 수신 시 현재 대화 상대를 파트너로 설정한다.
## [EN] Sets the current dialogue target as partner when receiving Dialogic [code]set_partner[/code] signal.
func _on_dialogic_signal(arg: String):
	if arg == "set_partner":
		partner_setting(current_talker)
		NotionEvent.notion("NOTI_PARTNER_CHANGE", Constants.SD_ICONS[current_talker])
		

## [KR] 파트너를 [param partner_type]으로 변경한다. 동일 파트너면 무시.
## [EN] Changes partner to [param partner_type]. Ignored if same partner.
## [KR] [signal partner_change]를 발생시키고 [MetaProgression]에 저장한다.
## [EN] Emits [signal partner_change] and saves to [MetaProgression].
func partner_setting(partner_type: int):
	if partner_type == current_partner: # [KR] 변경하려는 파트너와 현재 파트너가 같으면 리턴함 / [EN] Return if target partner is same as current
		return
	
	current_partner = partner_type
	partner_change.emit(partner_type)
	MetaProgression.set_current_partner(partner_type)

## [KR] 대화를 시작할 NPC를 [member current_talker]에 기록한다.
## [EN] Records the NPC to start dialogue with in [member current_talker].
func current_talk(npc: Npc):
	current_talker = npc.npc_name
	#if current_talker < len(partner):
		#print(partner[current_talker].love_level, partner[current_talker].love_exp)
	#else:
		#print("파트너가 설정되지 않았습니다.")

## [KR] 현재 대화 중인 NPC의 [Npc] 인스턴스를 반환한다.
## [EN] Returns the [Npc] instance of the currently talking NPC.
func get_current_talker() -> Npc:
	var talker = partner[current_talker]
	return talker

## [KR] 스테이지 클리어 시 현재 파트너에게 기본 클리어 경험치를 부여하고 UI를 갱신한다.
## [EN] Grants base clear experience to the current partner on stage clear and updates the UI.
func _on_stage_clear():
	GameEvents.emit_get_npc_exp(Constants.BASE_CLEAR_EXP, current_partner)
	MetaProgression.npc_info_update(partner[current_partner])
	current_partner_ui.ui_update()

## [KR] NPC 경험치 획득 이벤트 핸들러. 정념 게이지 → 챕터 제한 체크 → 경험치 적용 순서로 처리.
## [EN] NPC experience acquisition event handler. Processes in order: desire gauge → chapter limit check → experience application.
## Why: 호감도 최대치에 상관없이 정념은 항상 상승해야 하므로 정념 처리를 가장 먼저 수행.
func _on_get_npc_exp(_exp: int, npc_type: int, show_notion := true):
	GameEvents.emit_get_ero_gauge(Constants.BASE_INCRESE_ERO_GAUGE, npc_type)
	
	# [KR] 호감도 최대치이거나 max 레벨일 때 처리
	# [EN] Handle when at max affection or max level
	if partner_chapter_limit_level(npc_type):
		if not Constants.PARTNER_CHAPTER_LIMIT_LEVEL[MetaProgression.get_current_chapter()] == Constants.PARTNER_MAX_LEVEL:
			NotionEvent.notion("NOTI_CHAPTER_LOVE_LEVEL_LIMIT", Constants.SD_ICONS[npc_type])
		return
	if partner[npc_type].love_level >= get_partner_max_level(npc_type):
		return
	
	partner[npc_type].get_exp(_exp)
	
	MetaProgression.npc_info_update(partner[npc_type])
	if show_notion:
		match npc_type:
			Constants.NPC_OL:
				NotionEvent.notion("NOTI_EXP_UP_REINA", Constants.SD_ICONS[Constants.NPC_OL])
			Constants.NPC_GYARU:
				NotionEvent.notion("NOTI_EXP_UP_MAI", Constants.SD_ICONS[Constants.NPC_GYARU])
			Constants.NPC_BUTLER:
				if MetaProgression.has_read_event(Constants.QUESTLINE_BUTLER_HUMAN): # [KR] 집사 인간폼일 경우만 띄움 / [EN] Only show for butler human form
					#NotionEvent.notion("NOTI_EXP_UP_BUTLER", Constants.SD_ICONS[Constants.NPC_BUTLER])
					pass
			Constants.NPC_KONIAL:
				var message = tr("NOTI_ITEM_KONIAL_LOVE_BONUS")%Constants.INCRESE_LOVE_EXP_KONIAL
				NotionEvent.notion(message, Constants.SD_ICONS[Constants.NPC_KONIAL])

	current_partner_ui.ui_update()
	love_gage_update.emit(npc_type, partner[npc_type].love_exp)

## [KR] 레이나·마이 한정으로 현재 챕터의 호감도 상한에 도달했는지 확인한다.
## [EN] Checks if the affection cap for the current chapter has been reached (Reina and Mai only).
func partner_chapter_limit_level(npc_type: int)-> bool:
	match npc_type:
		Constants.NpcTypes.REINA, Constants.NpcTypes.MAI:
			var love_level: int = partner[npc_type].love_level
			var limit_level: int = Constants.PARTNER_CHAPTER_LIMIT_LEVEL[MetaProgression.get_current_chapter()]
			if love_level >= limit_level:
				return true
	return false


## [KR] 정념 게이지 획득 이벤트 핸들러. [method set_ero_gage]에 위임.
## [EN] Desire gauge acquisition event handler. Delegates to [method set_ero_gage].
func _on_get_ero_gauge(ero_gauge: int, npc_type: int):
	set_ero_gage(npc_type, ero_gauge)

## [KR] NPC 레벨업 이벤트 핸들러. 조건 충족 시 레벨업을 실행하고 목표 경험치를 재설정한다.
## [EN] NPC level-up event handler. Executes level-up when conditions are met and resets target experience.
## Why: 집사는 레벨업 시 초과 경험치를 별도 스택에서 꺼내 재적용해야 한다.
func on_npc_level_up(npc_type : int):
	if partner[npc_type].npc_name == npc_type and can_love_level_up(npc_type):
		partner[npc_type].love_level_up()
		partner[npc_type].target_love_exp = set_target_exp(partner[npc_type].npc_name , partner[npc_type].love_level)
		MetaProgression.npc_info_update(partner[npc_type])
		current_event_love_level = -1
		
		## [KR] 집사인 경우 스택에 쌓인 초과 경험치를 꺼내 재적용
		## [EN] For butler, retrieves and reapplies overflow experience from the stack
		if npc_type == Constants.NpcTypes.BUTLER:
			GameEvents.emit_get_npc_exp(MetaProgression.popout_butler_stack_exp(), GameEvents.NpcTypes.BUTLER)

## [KR] 특정 호감도 레벨의 이벤트를 실행할 수 있는지 판정한다.
## [EN] Determines if an event at a specific affection level can be executed.
## [KR] 호감도가 높거나, 같은 레벨이면서 경험치가 최대인 경우 [code]true[/code].
## [EN] Returns [code]true[/code] if affection is higher, or at same level with max experience.
func can_event(event_love_level : int, npc_type: int) -> bool:
	if partner[npc_type].love_level > event_love_level:
		return true
	elif partner[npc_type].love_level == event_love_level:
		return get_partner_exp_max(npc_type)
	else :
		return false

## [KR] 레벨업 가능 여부를 확인한다. [member current_event_love_level]이 설정되어 있고
## [EN] Checks if level-up is possible. [member current_event_love_level] must be set
## [KR] NPC의 현재 레벨과 일치해야 레벨업을 허용한다.
## [EN] and must match the NPC's current level to allow level-up.
func can_love_level_up(npc_type: int)-> bool:
	if current_event_love_level == -1:
		return false
	if partner[npc_type].love_level == current_event_love_level:
		return true
	return false

## [KR] [member current_event_love_level]을 강제로 덮어쓴다. 외부 이벤트에서 레벨 보정 시 사용.
## [EN] Forcefully overwrites [member current_event_love_level]. Used for level correction in external events.
func forcefix_current_event_love_level(fix_level: int):
	current_event_love_level = fix_level

## [KR] 현재 선택된 파트너의 [Npc] 인스턴스를 반환한다.
## [EN] Returns the [Npc] instance of the currently selected partner.
func get_current_partner() -> Npc:
	return partner[current_partner]

## [KR] 현재 파트너의 호감도 레벨을 반환한다.
## [EN] Returns the affection level of the current partner.
func get_current_partner_love_level() -> int:
	return partner[current_partner].love_level

## [KR] NPC 타입과 호감도 레벨에 따른 다음 레벨업 목표 경험치를 계산한다.
## [EN] Calculates the next level-up target experience based on NPC type and affection level.
## [KR] 최소값은 100으로 보장한다.
## [EN] Guarantees a minimum value of 100.
func set_target_exp(npc_type: int, _partner_love_level: int)->int:
	var next_target_exp = 100 * (_partner_love_level+1)
	next_target_exp = NpcData.get_npc_max_exp(npc_type, _partner_love_level)
	return maxi(100, next_target_exp)

## [KR] NPC의 경험치가 목표치에 도달했는지 확인한다.
## [EN] Checks if the NPC's experience has reached the target.
func get_partner_exp_max(npc_type: int) -> bool:
	if partner[npc_type].love_exp >= partner[npc_type].target_love_exp:
		return true
	else:
		return false

## [KR] 파트너에게 정념 게이지를 추가한다. 0~최대값 범위로 클램프 후 저장.
## [EN] Adds desire gauge to the partner. Clamped to 0~max range and saved.
func set_ero_gage(npc_type:NpcType, gage: int):
	partner[npc_type].ero_gage = clampi(partner[npc_type].ero_gage + gage, 0, Constants.PARTNER_MAX_ERO_GAUGE)
	ero_gage_update.emit(npc_type, partner[npc_type].ero_gage)
	MetaProgression.set_npc_ero_gage(npc_type, partner[npc_type].ero_gage)

## [KR] 정념 게이지를 소모하여 티켓으로 환산한다.
## [EN] Consumes desire gauge and converts to tickets.
## [KR] 실제 감소한 양의 2배를 티켓으로 드롭한다.
## [EN] Drops tickets equal to 2x the actually consumed amount.
func consume_ero_gage(npc_type: NpcType, gage: int):
	var current_gage = partner[npc_type].ero_gage
	var new_gage = clampi(current_gage - gage, 0, Constants.PARTNER_MAX_ERO_GAUGE)
	var consumed_gage = current_gage - new_gage  # [KR] 실제로 감소한 양 / [EN] Actual amount decreased

	partner[npc_type].ero_gage = new_gage
	ero_gage_update.emit(npc_type, new_gage)
	MetaProgression.set_npc_ero_gage(npc_type, new_gage)

	# [KR] 실제 감소한 양만큼 티켓 드롭
	# [EN] Drop tickets equal to the actually consumed amount
	if consumed_gage > 0:
		GameEvents.emit_drop_item(Constants.PC_PLAYER, DropItemManager.ItemType.TICKET, consumed_gage*2)
		
		### [KR] 집사 인간폼 이후에 집사 호감도 상승 아이템도 드롭됨
		### [EN] After butler human form, butler affection-up item also drops
		# 아이템 상자 획득시 호감도 상승되게 변경됨
		#if MetaProgression.has_read_event(Constants.QUESTLINE_BUTLER_HUMAN) \
		#and floor_manager.current_level.stage_type == Constants.TYPE_BASE:
			#drop_butler_love(consumed_gage/2)

## [KR] 파트너에게 대화로 쌓인 스택 티켓을 수거하여 아이템으로 드롭한다. (제거 예정)
## [EN] Collects stack tickets accumulated through dialogue from the partner and drops as items. (To be removed)
func collect_npc_stack_ticket(npc_type: NpcType):
	var stack_ticket_num = partner[npc_type].stack_ticket
	if stack_ticket_num <= 0:
		return
	
	partner[npc_type].stack_ticket = 0
	MetaProgression.set_npc_stack_ticket(npc_type, 0)
	
	GameEvents.emit_drop_item(npc_type, DropItemManager.ItemType.TICKET, stack_ticket_num)

## [KR] 특정 NPC의 현재 정념 게이지를 반환한다.
## [EN] Returns the current desire gauge of a specific NPC.
func get_partner_ero_gauge(npc_type: NpcType)-> float:
	return partner[npc_type].ero_gage

## [KR] 현재 파트너의 탐색 횟수를 1 차감한다.
## [EN] Decrements the current partner's search count by 1.
func find_discount():
	partner[current_partner].find_count -= 1
	print("Remaining search count : ", str(partner[current_partner].find_count))

## [KR] H이벤트 진입 시 해당 이벤트의 요구 호감도 레벨을 기록한다.
## [EN] Records the required affection level of the event upon H-event entry.
func _on_h_event(event: EventArea):
	current_event_love_level = event.h_scene_info.love_ability

## [KR] 자유 H씬 파트너 변경 시 [member current_free_h_partner]를 갱신한다.
## [EN] Updates [member current_free_h_partner] when the free H-scene partner changes.
func _on_free_h_partner_change(npc_type: NpcType):
	current_free_h_partner = npc_type

## [KR] 미사용
## [EN] Unused
#func drop_butler_love(consumed_gage: int):
	#@warning_ignore("integer_division")
	#GameEvents.emit_drop_item(Constants.PC_PLAYER, DropItemManager.ItemType.BUTLER_HEART, consumed_gage/5)


## [KR] NPC 타입별 최대 호감도 레벨을 반환한다. 코니알·집사는 개별 상한을 적용.
## [EN] Returns the max affection level per NPC type. Konial and butler have individual caps.
func get_partner_max_level(npc_type: int)-> int:
	var max_level: int = Constants.PARTNER_MAX_LEVEL
	match npc_type:
		Constants.NpcTypes.REINA, Constants.NpcTypes.MAI:
			max_level = Constants.PARTNER_MAX_LEVEL
		Constants.NpcTypes.KONIAL:
			max_level = Constants.NPC_MAX_LEVEL_KONIAL
		Constants.NpcTypes.BUTLER:
			max_level = Constants.NPC_MAX_LEVEL_BUTLER
	return max_level
