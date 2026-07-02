## [KR] 게임 전체의 중앙 이벤트 버스 싱글톤.
## [br]다양한 시스템 간의 느슨한 결합(loose coupling)을 위해 시그널을 중앙에서 관리한다.
## [member game_state]로 현재 게임플레이 상태를 추적하고,
## [member current_window_state]로 열린 UI 창 상태를 관리한다.
## [EN] Central event bus singleton for the entire game.
## [br]Manages signals centrally for loose coupling between various systems.
## Tracks current gameplay state via [member game_state],
## and manages open UI window state via [member current_window_state].
extends Node


## [KR] 현재 게임 언어 설정 코드. 기본값은 [code]"ko"[/code](한국어).
## [EN] Current game language setting code. Default is [code]"ko"[/code] (Korean).
var current_language := "ko" :
	get :
		return current_language
	set(str):
		current_language = str

## [KR] 현재 입장한 게임 모드가 회상방일 경우 [code]true[/code]
## [EN] [code]true[/code] when the current game mode is the recollection room
var is_recollection_room:= false

## [KR] 현재 에필로그 스테이지일 경우 [code]true[/code]로 활성화
## [EN] Set to [code]true[/code] when on an epilogue stage
var is_epilogue_room:= false

## [KR] [code]true[/code]이면 대화 중 호감도 바 UI 표시를 억제한다.
## [EN] When [code]true[/code], suppresses love bar UI display during dialogue.
var suppress_love_ui: bool = false

## [KR] 대화 중 호감도 바 UI를 즉시 숨기라는 요청 시그널. [method hide_dialog_love_ui]에서 발신한다.
signal dialog_love_ui_hide_requested

## [KR] 타임라인의 [code]do[/code]에서 호출해 대화 중 호감도 바 UI를 숨긴다.
## 여러 명이 등장하는 대화 등에서 사용하며, 억제는 타임라인 종료 시 자동 해제된다.
func hide_dialog_love_ui() -> void:
	suppress_love_ui = true
	dialog_love_ui_hide_requested.emit()

## [KR] [code]true[/code]이면 다음 선택지에서 Shift 스킵 자동선택을 막고 멈춰
## 플레이어 입력을 기다린다. 중요한 선택지(예: H 동의) 직전에 타임라인에서
## [method stop_skip_on_next_choice]로 설정한다. 선택이 끝나면 해제된다.
var block_skip_on_choice: bool = false

## [KR] 다음 선택지에서 스킵 자동선택을 막는다. 타임라인의 [code]do[/code]에서 호출한다.
func stop_skip_on_next_choice() -> void:
	block_skip_on_choice = true

## [KR] 대화 오토 플레이(AutoButton) on/off. 텍스트박스가 대화마다 새로 생성돼도
## 세션 동안 유지되도록 오토로드에 보관한다. (저장 안 됨 — 게임 재시작 시 초기화)
var autoplay_enabled: bool = false

## [KR] 현재 실행 중인 창이나 상태의 현황을 기록한 배열.
## [method set_window_state] / [method get_window_state]를 통해 접근한다.
## [EN] Array recording the status of currently open windows or states.
## Accessed via [method set_window_state] / [method get_window_state].
var current_window_state : Array[String] = []

## [KR] NPC 유형 열거형. 파트너 인덱스 및 시그널 파라미터에 사용된다.
## [EN] NPC type enum. Used for partner index and signal parameters.
enum NpcTypes {PLAYER = -1, REINA, MAI, KONIAL, PAZUZU, BUTLER}

# [KR] ──────────────────────────────────────────
# [KR] 플레이어 및 NPC 상호작용 시그널
# [KR] ──────────────────────────────────────────
# [EN] ──────────────────────────────────────────
# [EN] Player and NPC interaction signals
# [EN] ──────────────────────────────────────────

## [KR] 특정 노드가 준비 완료되었음을 알린다.
## [EN] Notifies that a specific node is ready.
signal node_ready(node_name : String)
## [KR] 플레이어가 [param npc]와 대화를 시작한다. [param lable]은 Dialogic 타임라인 라벨.
## [EN] Player starts dialogue with [param npc]. [param lable] is the Dialogic timeline label.
signal player_talk(npc : Npc, lable: String)
## [KR] 플레이어가 [param event] 이벤트 영역에 진입했을 때 발생한다.
## [EN] Emitted when the player enters the [param event] event area.
signal player_event(event : EventArea)
## [KR] 플레이어 캐릭터의 표시/숨김 상태를 변경한다.
## [EN] Changes the player character's visibility state.
signal player_visible(state: bool)
## [KR] NPC가 레벨업 대기 상태에 진입했을 때 발생한다.
## [EN] Emitted when an NPC enters the level-up waiting state.
signal npc_level_up_wating(npc : Npc)
## [KR] NPC 레벨업이 확정되었을 때 발생한다. [param npc_int]는 NPC 인덱스.
## [EN] Emitted when NPC level-up is confirmed. [param npc_int] is the NPC index.
signal npc_level_up(npc_int : int)
## [KR] 현재 이벤트의 호감도를 [param fix_level]로 강제 보정한다.
## [EN] Force-adjusts the current event's affection level to [param fix_level].
signal forcefix_current_event_love_level(fix_level: int)
## [KR] [param npc_type] NPC에게 [param exp]만큼 경험치를 부여한다.
## [EN] Grants [param exp] experience to the [param npc_type] NPC.
signal get_npc_exp(exp : int, npc_type: NpcTypes, show_notion: bool)
## [KR] [param npc_type] NPC의 에로 게이지를 [param ero_gauge]만큼 변경한다.
## [EN] Changes the [param npc_type] NPC's ero gauge by [param ero_gauge].
signal get_ero_gauge(ero_gauge: int, npc_type: NpcTypes)

# [KR] ──────────────────────────────────────────
# [KR] H 이벤트 시그널
# [KR] ──────────────────────────────────────────
# [EN] ──────────────────────────────────────────
# [EN] H event signals
# [EN] ──────────────────────────────────────────

## [KR] [param npc_type] NPC의 H 이벤트 [param scene_name]이 발생했을 때 방출된다.
## [EN] Emitted when the [param npc_type] NPC's H event [param scene_name] occurs.
signal on_npc_h_event(npc_type: NpcTypes, scene_name: String)
## [KR] Dialogic 내부에서 H 이벤트가 활성화되었을 때 발생한다.
## [EN] Emitted when an H event is activated within Dialogic.
signal dialogic_h_event_on()
## [KR] H 이벤트가 종료되었을 때 발생한다.
## [EN] Emitted when an H event ends.
signal h_event_end(npc_type: NpcTypes, free_action_component: HSceneFreeActionComponent)
## [KR] 사정 연출을 실행한다. [param npc_position]에서 이펙트가 발생한다.
## [EN] Executes the climax effect. Effect occurs at [param npc_position].
signal shot_semen(npc_position: Vector2, npc_type: NpcTypes, event_num: int)
## [KR] NPC 숨김 없이 특정 상태를 전환한다. [param active_npc_type]은 활성 NPC.
## [EN] Switches to a specific state without hiding NPCs. [param active_npc_type] is the active NPC.
signal without_npc_hide(state: bool, active_npc_type: int)

# [KR] ──────────────────────────────────────────
# [KR] 스테이지 및 챕터 진행 시그널
# [KR] ──────────────────────────────────────────
# [EN] ──────────────────────────────────────────
# [EN] Stage and chapter progression signals
# [EN] ──────────────────────────────────────────

## [KR] 챕터를 [param chapter_num]으로 변경한다.
## [EN] Changes the chapter to [param chapter_num].
signal set_chapter(chapter_num : int)
## [KR] 게임 클리어(완료) 시 발생한다.
## [EN] Emitted when the game is cleared (completed).
signal game_complete()
## [KR] [param stage_path] 경로의 스테이지로 전환을 요청한다.
## [EN] Requests transition to the stage at [param stage_path].
signal set_change_stage(stage_path: String)
## [KR] 튜토리얼 완료 시 발생한다.
## [EN] Emitted when the tutorial is completed.
signal tuto_complete()
## [KR] 현재 스테이지를 클리어했을 때 발생한다.
## [EN] Emitted when the current stage is cleared.
signal stage_clear()
## [KR] 스테이지가 전환될 때 발생한다.
## [EN] Emitted when the stage changes.
signal stage_change
## [KR] 스테이지 전환 로딩 화면 애니메이션이 완전히 끝났을 때 발생한다.
signal stage_transition_ended
## [KR] 스테이지 실행/일시정지 상태를 전환한다.
## [EN] Toggles stage run/pause state.
signal stage_run(run : bool)
## [KR] 다음 스테이지로 향할 때 발생하는 시그널.
## [EN] Signal emitted when heading to the next stage.
signal in_next_stage()
## [KR] 에필로그 스테이지에 합류할 때 발생한다.
## [EN] Emitted when joining an epilogue stage.
signal join_epilogue

# [KR] ──────────────────────────────────────────
# [KR] NPC 위치 · 애니메이션 시그널
# [KR] ──────────────────────────────────────────
# [EN] ──────────────────────────────────────────
# [EN] NPC position and animation signals
# [EN] ──────────────────────────────────────────

## [KR] [param npc_type] NPC의 위치가 [param position]으로 변경되었음을 알린다.
## [EN] Notifies that the [param npc_type] NPC's position changed to [param position].
signal npc_position_change(npc_type: NpcTypes, position: Vector2)
## [KR] 전체 NPC에게 애니메이션 변경 명령을 방출한다.
## [EN] Emits animation change command to all NPCs.
signal anim_change_emit(str : String)
## [KR] 특정 [param npc_type] NPC에게만 애니메이션 변경 명령을 보낸다.
## [EN] Sends animation change command only to the specified [param npc_type] NPC.
signal anim_change_this_npc(str : String, npc_type: NpcTypes)
## [KR] [param npc_type] NPC의 좌표를 ([param x], [param y])로 변경한다.
## [EN] Changes the [param npc_type] NPC's coordinates to ([param x], [param y]).
signal position_change(npc_type: NpcTypes, x:float, y:float)
## [KR] [param npc_type] NPC의 좌우 반전 상태를 설정한다. [code]false[/code] = 왼쪽, [code]true[/code] = 오른쪽.
## [EN] Sets the [param npc_type] NPC's flip state. [code]false[/code] = left, [code]true[/code] = right.
signal npc_flip(npc_type: NpcTypes, flip: bool)
## [KR] 플레이어의 이동 방향을 [param direction]으로 변경한다.
## [EN] Changes the player's movement direction to [param direction].
signal direction_change(direction: String)

# [KR] ──────────────────────────────────────────
# [KR] 카메라 및 컷신 시그널
# [KR] ──────────────────────────────────────────
# [EN] ──────────────────────────────────────────
# [EN] Camera and cutscene signals
# [EN] ──────────────────────────────────────────

## [KR] 카메라 순서/우선순위를 변경한다. [param offset_x], [param offset_y]는 추가 오프셋.
## [EN] Changes camera order/priority. [param offset_x], [param offset_y] are additional offsets.
signal camera_order_change(npc_type: NpcTypes, value : int, offset_x: int, offset_y: int)
## [KR] 카메라 기준 위치를 [param npc_type] NPC로 설정한다.
## [EN] Sets the camera base position to the [param npc_type] NPC.
signal set_camera_base_position(npc_type: NpcTypes)
## [KR] 카메라 흔들림을 시작하거나 중지한다.
## [EN] Starts or stops camera shake.
signal camera_shake(state: bool)
## [KR] 지정된 [param duration](초) 동안 카메라를 흔든다.
## [EN] Shakes the camera for the specified [param duration] (seconds).
signal camera_shake_time(duration: float)
## [KR] [param cutscene_name] 컷신을 재생한다.
## [EN] Plays the [param cutscene_name] cutscene.
signal cutscene_play(cutscene_name: String)

# [KR] ──────────────────────────────────────────
# [KR] 아이템 · 장비 · 재화 시그널
# [KR] ──────────────────────────────────────────
# [EN] ──────────────────────────────────────────
# [EN] Item, equipment, and currency signals
# [EN] ──────────────────────────────────────────

## [KR] 능력 업그레이드 [param upgrade]가 추가되었을 때 발생한다.
## [EN] Emitted when ability upgrade [param upgrade] is added.
signal ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrade: Dictionary)
## [KR] 장비 목록이 갱신되었을 때 발생한다.
## [EN] Emitted when the equipment list is updated.
signal update_equip_item(equipment_list: Array[AbilityUpgrade])
## [KR] 상점 등에서 아이템 [param item_name]을 획득했을 때 발생한다.
## [EN] Emitted when item [param item_name] is obtained from shop, etc.
signal get_item_event(item_name: String)

## [KR] 티켓 [param type]의 수량을 [param number]로 설정한다.
## [EN] Sets the quantity of ticket [param type] to [param number].
signal set_ticket(type : String, number : int)
## [KR] 장비 비용을 [param value]로 설정한다.
## [EN] Sets equipment cost to [param value].
signal set_equip_cost(value: int)
## [KR] 코인 수량을 [param value]로 설정한다.
## [EN] Sets coin quantity to [param value].
signal set_coin(value: int)
## [KR] NPC가 아이템을 드롭했을 때 발생한다.
## [EN] Emitted when an NPC drops an item.
signal drop_item(npc_type: int, item_type: int, value: int)
## [KR] 아이템을 주울 수 있는 상태임을 알린다.
## [EN] Notifies that an item can be picked up.
signal can_pick_item()
## [KR] 티켓을 획득했을 때 발생한다.
## [EN] Emitted when a ticket is obtained.
signal get_ticket(upgrade: AbilityUpgrade, current_ticket : int, current_upgrade: Dictionary)
## [KR] [param npc_type] NPC의 누적 티켓을 수집한다.
## [EN] Collects stacked tickets from the [param npc_type] NPC.
signal collect_stack_ticket(npc_type: NpcTypes)

# [KR] ──────────────────────────────────────────
# [KR] 퀘스트 · 기록 · UI 시그널
# [KR] ──────────────────────────────────────────
# [EN] ──────────────────────────────────────────
# [EN] Quest, record, and UI signals
# [EN] ──────────────────────────────────────────

## [KR] 이벤트 [param event_name]을 읽음 기록에 추가한다.
## [EN] Adds event [param event_name] to read history.
signal add_read_history(event_name: String)
## [KR] 루트 힌트 [param hint_id]를 추가한다.
## [EN] Adds route hint [param hint_id].
signal add_route_hint(hint_id: String)
## [KR] 박스 맵 [param box_map_id]를 추가한다.
## [EN] Adds box map [param box_map_id].
signal add_box_map(box_map_id: String)
## [KR] 분실물(아이템 박스)을 획득했을 때 발생한다. (도전과제 수집 판정용)
## [br]코인/티켓 박스는 get_item_event/add_route_hint를 발신하지 않으므로, 이 시그널로 수집 판정을 트리거한다.
## [EN] Emitted when a lost item (item box) is collected. (For achievement collection check)
signal item_box_collected()
## [KR] 퀘스트 [param quest_str] 진행 상황을 처리한다.
## [EN] Processes quest [param quest_str] progress.
signal quest_process(quest_str : String)
## [KR] 퀘스트 조건 갱신을 감지하기 위한 시그널.
## [EN] Signal for detecting quest condition updates.
signal update_quest_process() # [KR] 퀘스트 조건 갱신 감지용 신호 / [EN] Signal for quest condition update detection

## [KR] 텍스트 박스의 표시 상태가 변경되었을 때 발생한다.
## [EN] Emitted when the text box visibility state changes.
signal textbox_visible_changed(vis: bool)

## [KR] 튜토리얼을 호출한다. [param next_focus_button]은 완료 후 포커스할 버튼.
## [EN] Calls the tutorial. [param next_focus_button] is the button to focus after completion.
signal call_tutorial(quest_id: String, next_focus_button: Button)

## [KR] 현재 게임플레이 상태를 추적한다.
## [code]STATE_NORMAL[/code], [code]STATE_EVENT[/code], [code]STATE_RAPE[/code] 등
## [code]Constants[/code]에 정의된 상수를 사용한다.
## [EN] Tracks current gameplay state.
## Uses constants defined in [code]Constants[/code] such as [code]STATE_NORMAL[/code], [code]STATE_EVENT[/code], [code]STATE_RAPE[/code].
var game_state := Constants.STATE_NORMAL

## [KR] [signal node_ready] 시그널을 방출한다.
## [EN] Emits the [signal node_ready] signal.
func emit_node_ready(node_name : String):
	node_ready.emit(node_name)

## [KR] [member game_state]를 [param state] 값으로 변경한다.
## [EN] Changes [member game_state] to [param state].
func game_state_change(state :=0):
	game_state = state
	
## [KR] [signal npc_position_change] 시그널을 방출한다.
## [EN] Emits the [signal npc_position_change] signal.
func emit_npc_position_change(npc_type: NpcTypes, position: Vector2):
	npc_position_change.emit(npc_type, position)

## [KR] [signal anim_change_emit] 시그널을 방출하여 전체 NPC 애니메이션을 변경한다.
## [EN] Emits [signal anim_change_emit] to change all NPC animations.
func anim_change(_str : String):
	anim_change_emit.emit(_str)

## [KR] [signal anim_change_this_npc] 시그널을 방출하여 특정 NPC 애니메이션을 변경한다.
## [EN] Emits [signal anim_change_this_npc] to change a specific NPC's animation.
func emit_anim_change_this_npc(_str : String, npc_type: NpcTypes):
	anim_change_this_npc.emit(_str, npc_type)

## [KR] [signal position_change] 시그널을 방출하여 NPC 좌표를 변경한다.
## [EN] Emits [signal position_change] to change NPC coordinates.
func emit_position_change(npc_type: NpcTypes, _x:float, _y:float):
	position_change.emit(npc_type, _x, _y)

## [KR] [signal npc_flip] 시그널을 방출한다. [code]false[/code] = 왼쪽, [code]true[/code] = 오른쪽.
## [EN] Emits the [signal npc_flip] signal. [code]false[/code] = left, [code]true[/code] = right.
func emit_npc_flip(npc_type: NpcTypes, flip: bool):
	npc_flip.emit(npc_type, flip)

## [KR] [signal direction_change] 시그널을 방출하여 이동 방향을 변경한다.
## [EN] Emits [signal direction_change] to change movement direction.
func emit_direction_change(direction: String):
	direction_change.emit(direction)

## [KR] [signal player_talk] 시그널을 방출하여 NPC 대화를 시작한다.
## [EN] Emits [signal player_talk] to start NPC dialogue.
func emit_player_talk(npc : Npc, lable: String = ""):
	player_talk.emit(npc, lable)

## [KR] [signal player_event] 시그널을 방출하여 이벤트 영역 진입을 알린다.
## [EN] Emits [signal player_event] to notify event area entry.
func emit_player_event(event : EventArea):
	player_event.emit(event)

## [KR] [signal player_visible] 시그널을 방출하여 플레이어 표시 상태를 전환한다.
## [EN] Emits [signal player_visible] to toggle player visibility.
func emit_player_visible(state: bool):
	player_visible.emit(state)

## [KR] [signal npc_level_up_wating] 시그널을 방출하여 NPC 레벨업 대기 상태를 알린다.
## [EN] Emits [signal npc_level_up_wating] to notify NPC level-up waiting state.
func emit_npc_level_up_wating(npc : Npc):
	npc_level_up_wating.emit(npc)

## [KR] [signal npc_level_up] 시그널을 방출하여 NPC 레벨업을 확정한다.
## [EN] Emits [signal npc_level_up] to confirm NPC level-up.
func emit_npc_level_up(npc_int : int):
	npc_level_up.emit(npc_int)

## [KR] [signal forcefix_current_event_love_level] 시그널을 방출하여 호감도를 강제 보정한다.
## [EN] Emits [signal forcefix_current_event_love_level] to force-adjust affection level.
func emit_forcefix_current_event_love_level(fix_level: int):
	forcefix_current_event_love_level.emit(fix_level)

## [KR] [signal get_npc_exp] 시그널을 방출하여 NPC 경험치를 부여한다.
## [EN] Emits [signal get_npc_exp] to grant NPC experience.
func emit_get_npc_exp(_exp : int, npc_type: NpcTypes, show_notion := true):
	get_npc_exp.emit(_exp, npc_type, show_notion)

## [KR] [signal get_ero_gauge] 시그널을 방출하여 에로 게이지를 변경한다.
## [EN] Emits [signal get_ero_gauge] to change ero gauge.
func emit_get_ero_gauge(ero_gauge: int, npc_type: NpcTypes):
	get_ero_gauge.emit(ero_gauge, npc_type)

## [KR] [signal on_npc_h_event] 시그널을 방출하여 NPC H 이벤트를 개시한다.
## [EN] Emits [signal on_npc_h_event] to start NPC H event.
func emit_on_npc_h_event(npc_type: NpcTypes, scene_name: String, ticket_multiplier: int = 0):
	on_npc_h_event.emit(npc_type, scene_name, ticket_multiplier)

## [KR] [signal dialogic_h_event_on] 시그널을 방출하여 Dialogic H 이벤트를 활성화한다.
## [EN] Emits [signal dialogic_h_event_on] to activate Dialogic H event.
func emit_dialogic_h_event_on():
	dialogic_h_event_on.emit()

## [KR] [signal h_event_end] 시그널을 방출하여 H 이벤트 종료를 알린다.
## [EN] Emits [signal h_event_end] to notify H event end.
func emit_h_event_end(npc_type: NpcTypes, free_action_component: HSceneFreeActionComponent):
	h_event_end.emit(npc_type, free_action_component)

## [KR] BGM 하이라이트(클라이맥스) 구간으로 전환한다.
## [KR] [code]SoundManager[/code]가 수신하여 루프 구간에서 하이라이트 구간으로 크로스페이드한다.
## [EN] Transitions BGM to the highlight (climax) section.
## [EN] Received by [code]SoundManager[/code] to crossfade from the loop section to the highlight section.
signal music_highlight_trigger

## [KR] [signal music_highlight_trigger] 시그널을 방출하여 BGM 하이라이트 구간으로 전환한다.
## [EN] Emits [signal music_highlight_trigger] to transition BGM to the highlight section.
func emit_music_highlight_trigger() -> void:
	music_highlight_trigger.emit()

## [KR] [signal shot_semen] 시그널을 방출하여 사정 연출을 실행한다.
## [EN] Emits [signal shot_semen] to execute climax effect.
func emit_shot_semen(npc_position: Vector2, npc_type: NpcTypes, event_num: int):
	shot_semen.emit(npc_position, npc_type, event_num)

## [KR] [signal without_npc_hide] 시그널을 방출한다.
## [EN] Emits the [signal without_npc_hide] signal.
func emit_without_npc_hide(state: bool, active_npc_type: int):
	without_npc_hide.emit(state, active_npc_type)

## [KR] [signal set_chapter] 시그널을 방출하여 챕터를 변경한다.
## [method emit_game_complete]보다 먼저 호출해야 정상 작동한다.
## [EN] Emits [signal set_chapter] to change chapter.
## Must be called before [method emit_game_complete] for proper operation.
func emit_set_chapter(chapter: int):
	set_chapter.emit(chapter)

## [KR] [signal game_complete] 시그널을 방출하여 게임 클리어를 알린다.
## [EN] Emits [signal game_complete] to notify game clear.
func emit_game_complete():
	game_complete.emit()

## [KR] [signal set_change_stage] 시그널을 방출하여 스테이지를 전환한다.
## [EN] Emits [signal set_change_stage] to change stage.
func emit_set_change_stage(stage_path: String):
	set_change_stage.emit(stage_path)

## [KR] [signal tuto_complete] 시그널을 방출하여 튜토리얼 완료를 알린다.
## [EN] Emits [signal tuto_complete] to notify tutorial completion.
func emit_tuto_complete():
	tuto_complete.emit()

## [KR] [signal stage_clear] 시그널을 방출하여 스테이지 클리어를 알린다.
## [EN] Emits [signal stage_clear] to notify stage clear.
func emit_stage_clear():
	stage_clear.emit()

## [KR] [signal stage_change] 시그널을 방출하여 스테이지 전환을 알린다.
## [EN] Emits [signal stage_change] to notify stage change.
func emit_stage_change():
	stage_change.emit()

## [KR] [signal in_next_stage] 시그널을 방출하여 다음 스테이지 진입을 알린다.
## [EN] Emits [signal in_next_stage] to notify next stage entry.
func emit_in_next_stage():
	in_next_stage.emit()

## [KR] [signal join_epilogue] 시그널을 방출하고 [member is_epilogue_room]을 활성화한다.
## [EN] Emits [signal join_epilogue] and activates [member is_epilogue_room].
func emit_join_epilogue():
	join_epilogue.emit()
	is_epilogue_room = true

## [KR] [signal stage_run] 시그널을 방출하여 스테이지 실행/일시정지를 전환한다.
## [EN] Emits [signal stage_run] to toggle stage run/pause.
func emit_stage_run(run: bool):
	stage_run.emit(run)

## [KR] [signal camera_order_change] 시그널을 방출하여 카메라 우선순위를 변경한다.
## [EN] Emits [signal camera_order_change] to change camera priority.
func emit_camera_order_change(npc_type: NpcTypes, value : int, offset_x: int = 0, offset_y: int = 0):
	camera_order_change.emit(npc_type, value, offset_x, offset_y)

## [KR] [signal set_camera_base_position] 시그널을 방출하여 카메라 기준 위치를 설정한다.
## [EN] Emits [signal set_camera_base_position] to set camera base position.
func emit_set_camera_base_position(npc_type: NpcTypes):
	set_camera_base_position.emit(npc_type)

## [KR] [signal camera_shake] 시그널을 방출하여 카메라 흔들림을 전환한다.
## [EN] Emits [signal camera_shake] to toggle camera shake.
func emit_camera_shake(state: bool):
	camera_shake.emit(state)

## [KR] [signal camera_shake_time] 시그널을 방출하여 일정 시간 동안 카메라를 흔든다.
## [EN] Emits [signal camera_shake_time] to shake camera for a duration.
func emit_camera_shake_time(duration: float):
	camera_shake_time.emit(duration)

## [KR] [signal cutscene_play] 시그널을 방출하여 컷신을 재생한다.
## [EN] Emits [signal cutscene_play] to play cutscene.
func emit_cutscene_play(cutscene_name: String):
	cutscene_play.emit(cutscene_name)

## [KR] [signal ability_upgrade_added] 시그널을 방출하여 능력 업그레이드 추가를 알린다.
## [EN] Emits [signal ability_upgrade_added] to notify ability upgrade addition.
func emit_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	ability_upgrade_added.emit(upgrade, current_upgrades)

## [KR] [signal update_equip_item] 시그널을 방출하여 장비 목록 갱신을 알린다.
## [EN] Emits [signal update_equip_item] to notify equipment list update.
func emit_update_equip_item(equipment_list: Array[AbilityUpgrade]):
	update_equip_item.emit(equipment_list)

## [KR] [signal get_item_event] 시그널을 방출하여 상점 아이템 구매를 알린다.
## [EN] Emits [signal get_item_event] to notify shop item purchase.
func emit_get_item_event(item_name: String):
	get_item_event.emit(item_name)

## [KR] [signal set_ticket] 시그널을 방출하여 티켓 수량을 설정한다.
## [EN] Emits [signal set_ticket] to set ticket quantity.
func emit_set_ticket(type : String, number : int):
	set_ticket.emit(type, number)

## [KR] [signal set_equip_cost] 시그널을 방출하여 장비 비용을 설정한다.
## [EN] Emits [signal set_equip_cost] to set equipment cost.
func emit_set_equip_cost(value: int):
	set_equip_cost.emit(value)

## [KR] [signal set_coin] 시그널을 방출하여 코인 수량을 설정한다.
## [EN] Emits [signal set_coin] to set coin quantity.
func emit_set_coin(value: int):
	set_coin.emit(value)

## [KR] [signal drop_item] 시그널을 방출하여 아이템 드롭을 알린다.
## [EN] Emits [signal drop_item] to notify item drop.
func emit_drop_item(npc_type: int, item_type: int, value: int):
	drop_item.emit(npc_type, item_type, value)

## [KR] [signal can_pick_item] 시그널을 방출하여 아이템 수집 가능 상태를 알린다.
## [EN] Emits [signal can_pick_item] to notify item pickup availability.
func emit_can_pick_item():
	can_pick_item.emit()

## [KR] [signal get_ticket] 시그널을 방출하여 티켓 획득을 알린다.
## [EN] Emits [signal get_ticket] to notify ticket acquisition.
func emit_get_ticket(upgrade: AbilityUpgrade, current_ticket : int, current_upgrade: Dictionary):
	get_ticket.emit(upgrade, current_ticket, current_upgrade)

## [KR] [signal collect_stack_ticket] 시그널을 방출하여 누적 티켓을 수집한다.
## [EN] Emits [signal collect_stack_ticket] to collect stacked tickets.
func emit_collect_stack_ticket(npc_type: NpcTypes):
	collect_stack_ticket.emit(npc_type)

## [KR] [signal add_read_history] 시그널을 방출하여 읽음 기록을 추가한다.
## [EN] Emits [signal add_read_history] to add read history.
func emit_add_read_history(event_name: String):
	add_read_history.emit(event_name)

## [KR] [signal add_route_hint] 시그널을 방출하여 루트 힌트를 추가한다.
## [EN] Emits [signal add_route_hint] to add route hint.
func emit_add_route_hint(route_hint_id: String):
	add_route_hint.emit(route_hint_id)

## [KR] [signal add_box_map] 시그널을 방출하여 박스 맵을 추가한다.
## [EN] Emits [signal add_box_map] to add box map.
func emit_add_box_map(box_map_id: String):
	add_box_map.emit(box_map_id)

## [KR] [signal item_box_collected] 시그널을 방출하여 분실물 획득을 알린다.
## [EN] Emits [signal item_box_collected] to notify lost item collection.
func emit_item_box_collected():
	item_box_collected.emit()

## [KR] [signal quest_process] 시그널을 방출하여 퀘스트 진행을 처리한다.
## [EN] Emits [signal quest_process] to process quest progress.
func emit_quest_process(quest_str: String):
	quest_process.emit(quest_str)

## [KR] [signal update_quest_process] 시그널을 방출하여 퀘스트 조건 갱신을 알린다.
## [EN] Emits [signal update_quest_process] to notify quest condition update.
func emit_update_quest_process():
	update_quest_process.emit()

## [KR] [signal textbox_visible_changed] 시그널을 방출하여 텍스트 박스 표시 상태 변경을 알린다.
## [EN] Emits [signal textbox_visible_changed] to notify text box visibility change.
func emit_textbox_visible_changed(vis: bool):
	textbox_visible_changed.emit(vis)

## [KR] 해당 NPC에게 안 읽은 대화 이벤트가 있는지 확인한다.
## [code]NpcData[/code] 스크립트를 통해 읽음 여부를 판별한다.
## [EN] Checks if the NPC has unread dialogue events.
## Determines read status via the [code]NpcData[/code] script.
func is_new_read_event(npc_type: int)-> bool:
	var npc_info = NpcData.new()
	var partner_manager = get_tree().get_first_node_in_group("partnermanager") as PartnerManager
	if npc_info.new_read_event(partner_manager.partner[npc_type]):
		return true
	return false

## [KR] 대화 리스트에서 [param talk_name] 대화가 등장하기 위한 필요 호감도 수치를 반환한다.
## 해당 대화를 찾을 수 없으면 [code]99[/code]를 반환한다.
## [EN] Returns the required affection level for [param talk_name] dialogue to appear in the dialogue list.
## Returns [code]99[/code] if the dialogue cannot be found.
func get_need_love(talk_name: String)-> int:
	var npc_data: Dictionary = NpcData.npc_info
	var unlock_talk: bool = true
	for i in npc_data:
		if npc_data[i]["talk_event"].has(talk_name):
			var is_talk_name = npc_data[i]["talk_event"][talk_name]
			if is_talk_name.has("unlock_quest"):
				if not MetaProgression.has_read_event(is_talk_name["unlock_quest"]):
					unlock_talk = false
			
			if unlock_talk:
				return is_talk_name["need_love"]
	return 99

## [KR] [param talk_name] 대화 완료 시 획득하는 추가 호감도 경험치를 반환한다.
## 해당 대화를 찾을 수 없으면 [code]0[/code]을 반환한다.
## [EN] Returns bonus affection experience gained when [param talk_name] dialogue is completed.
## Returns [code]0[/code] if the dialogue cannot be found.
func get_talk_add_exp(talk_name: String)-> int:
	var npc_data: Dictionary = NpcData.npc_info
	for i in npc_data:
		if npc_data[i]["talk_event"].has(talk_name):
			var talk_exp:int = npc_data[i]["talk_event"][talk_name]["plus_love_exp"]
			print("talk end - exp get : ", talk_exp)
			return talk_exp
	return 0

## [KR] [signal call_tutorial] 시그널을 방출하여 튜토리얼을 호출한다.
## [EN] Emits [signal call_tutorial] to call the tutorial.
func emit_call_tutorial(id: String, next_focus_button: Button = null):
	call_tutorial.emit(id, next_focus_button)

## [KR] 현재 스테이지의 타입(정수)을 [code]FloorManager[/code]에서 조회하여 반환한다.
## [EN] Queries and returns the current stage type (integer) from [code]FloorManager[/code].
func get_current_stage_type()->int:
	var floor_manager:FloorManager = get_tree().get_first_node_in_group("floormanager")
	return floor_manager.current_level.stage_type

## [KR] 현재 등록된 메인 퀘스트 [param quest_id]의 모든 조건이 클리어 상태인지 확인한다.
## Dialogic 타임라인에서 조건 분기에 사용된다.
## [EN] Checks if all conditions of the registered main quest [param quest_id] are cleared.
## Used for conditional branching in Dialogic timeline.
func get_current_main_quest_all_clear(quest_id: String)-> bool:
	var global_game_manager: GlobalGameManager = get_tree().get_first_node_in_group("globalgamemanager") as GlobalGameManager
	var main_quest_component: MainQuestComponent = global_game_manager.main_quest_component as MainQuestComponent
	if main_quest_component:
		if main_quest_component.quest_data:
			if main_quest_component.quest_data.id == quest_id:
				return main_quest_component.get_is_clear_check()
	return false


## [KR] 맵 이동 중 화면 전환 상태를 설정한다.
## [param state]가 [code]true[/code]이면 [member current_window_state]에 전환 상태를 추가한다.
## [EN] Sets the screen transition state during map movement.
## If [param state] is [code]true[/code], adds transition state to [member current_window_state].
func set_current_stage_changing_screen(state: bool):
	if state:
		current_window_state.append(Constants.WINDOW_STATE_STAGE_CHANGING)
	else:
		current_window_state.erase(Constants.WINDOW_STATE_STAGE_CHANGING)
		stage_transition_ended.emit()

## [KR] 현재 맵 전환 화면이 활성 상태인지 반환한다.
## [EN] Returns whether the current map transition screen is active.
func get_current_stage_changing_screen() -> bool:
	if current_window_state.has(Constants.WINDOW_STATE_STAGE_CHANGING):
		return true
	return false

## [KR] [member current_window_state]에 창 상태 [param state_name]을 추가하거나 제거한다.
## [param state]가 [code]true[/code]이면 추가, [code]false[/code]이면 제거한다.
## [EN] Adds or removes window state [param state_name] from [member current_window_state].
## Add if [param state] is [code]true[/code], remove if [code]false[/code].
func set_window_state(state_name: String, state: bool):
	if state:
		if not current_window_state.has(state_name):
			current_window_state.append(state_name)
	else:
		if current_window_state.has(state_name):
			current_window_state.erase(state_name)

## [KR] [param state_name] 상태가 현재 활성 중인지 확인한다.
## [EN] Checks if [param state_name] state is currently active.
func get_window_state(state_name: String)-> bool:
	if current_window_state.has(state_name):
		return true
	else:
		return false

## [KR] [member current_window_state] 배열 전체를 반환한다.
## [EN] Returns the entire [member current_window_state] array.
func get_window_state_array()-> Array:
	return current_window_state
