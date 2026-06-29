## [KR] 이상현상(Anomaly) 이벤트 영역 컴포넌트.
## [br]맵 위에 배치되는 H 이벤트 버블을 관리하며,
## 파트너 호감도·스테이지 클리어 여부·챕터 해금 조건에 따라
## 이벤트 활성화 상태와 버블 색상을 제어한다.
## [EN] Anomaly event area component.
## [br]Manages H event bubbles placed on the map,
## controlling event activation state and bubble color based on
## partner affection, stage clear status, and chapter unlock conditions.
extends Area2D
class_name EventArea

## [KR] 이 이벤트 영역에 연결된 H씬 리소스 정보.
## [EN] H-scene resource info connected to this event area.
@export var h_scene_info: HSceneRes
@export var no_display_dialog_love: bool = false
@export var sfx: UiSoundStreamPlayer

## [KR] 이벤트 버블 텍스처.
## [EN] Event bubble texture.
@onready var h_event_bubble: TextureRect = $HEventBubble
## [KR] 이벤트 대상 NPC 아이콘.
## [EN] Target NPC icon for the event.
@onready var npc_icon: TextureRect = %NpcIcon
## [KR] 호감도 조건 라벨.
## [EN] Affection condition label.
@onready var label := %Label
@onready var love_level_fill: TextureRect = %LoveLevelFill # [KR] 이벤트 조건 참일 시 하트 채워진 리소스 표시 / [EN] Display filled heart resource when event condition is met
## [KR] 플레이어 접근 시 표시되는 키보드 아이콘.
## [EN] Keyboard icon displayed when player approaches.
@onready var keyboard_icon: TextureRect = $HEventBubble/KeyboardIcon

## [KR] 이 이벤트가 속한 레벨 참조.
## [EN] Reference to the level this event belongs to.
var current_level: Level
## [KR] 이벤트 활성화(호감도 조건 충족) 여부.
## [EN] Whether the event is enabled (affection condition met).
var event_enabled := false
## [KR] 현재 스테이지 클리어 여부.
## [EN] Whether the current stage is cleared.
var current_stage_clear := false
## [KR] 파트너 매니저 참조.
## [EN] Partner manager reference.
var partner_manager: PartnerManager
## [KR] 글로벌 게임 매니저 참조.
## [EN] Global game manager reference.
var global_game_manager : GlobalGameManager
## [KR] 층 관리자 참조. 스테이지 타입·층 변경 이벤트에 사용.
## [EN] Floor manager reference. Used for stage type and floor change events.
var floor_manager: FloorManager
## [KR] 이 이벤트를 이미 읽었는지 여부.
## [EN] Whether this event has already been read.
var played := false


## [KR] 활성 상태의 원본 색상 (흰색).
## [EN] Original color for active state (white).
var original_color := Color(1, 1, 1, 1)  # [KR] 흰색 (기본값) / [EN] White (default)
## [KR] 비활성 상태의 색상 (회색).
## [EN] Color for disabled state (gray).
var disabled_color := Color(0.5, 0.5, 0.5, 1)  # [KR] 회색 / [EN] Gray

## [KR] 초기화: 시그널 연결, 이벤트 읽음 여부 확인, NPC 아이콘·라벨 설정, 버블 비활성화.
## [EN] Initialization: signal connections, read-event check, NPC icon/label setup, bubble deactivation.
func _ready():
	current_level = owner
	
	GameEvents.npc_level_up.connect(_on_event_played)
	GameEvents.stage_clear.connect(_on_stage_clear)
	GameEvents.stage_change.connect(_on_stage_changed)
	GameEvents.player_event.connect(_on_player_event)
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	
	
	if MetaProgression.has_read_event(h_scene_info.dialog_title):
		played = true
	
	global_game_manager = get_tree().get_first_node_in_group("globalgamemanager")
	floor_manager = get_tree().get_first_node_in_group("floormanager")
	floor_manager.floor_changed.connect(_on_floor_changed)
	
	is_enable(false)
	
	keyboard_icon.hide()
	npc_icon.texture = Constants.SD_ICONS[h_scene_info.partner]
	label.text = str(h_scene_info.love_ability)
	_update_color()

## [KR] 층 변경 콜백. 현재 레벨이 변경된 층과 일치하면 [method npc_set]을 지연 호출한다.
## [EN] Floor change callback. Calls [method npc_set] deferred if current level matches the changed floor.
func _on_floor_changed(level: Level):
	if current_level == level:
		call_deferred("npc_set")


## [KR] NPC 파트너 설정 및 이벤트 버블 활성화 상태를 갱신한다.
## [br]시작 지점이면 무조건 클리어 상태로 설정하고, 각 NPC의 경험치 최대 시그널을 구독한다.
## [EN] Updates NPC partner settings and event bubble activation state.
## [br]Sets clear state unconditionally at starting point, and subscribes to each NPC's max EXP signal.
func npc_set():
	if floor_manager.current_level:
		if floor_manager.current_stage_type == Constants.TYPE_BASE:
			set_current_stage_clear(true)
		else:
			set_current_stage_clear(floor_manager.current_level.stage_clear)
		
	event_enabled_update()
	for i in partner_manager.partner:
		var _npc = i as Npc
		_npc.exp_max.connect(_on_npc_exp_max)

## [KR] 매 프레임 이벤트 활성화 상태에 따라 버블 색상을 갱신한다.
## [EN] Updates bubble color based on event activation state each frame.
func _process(_delta):
	# [KR] 조건에 따라 색상 업데이트
	# [EN] Update color based on conditions
	_update_color()

## [KR] 디버그용 입력 핸들러 (현재 비활성).
## [EN] Debug input handler (currently inactive).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_copy"):
		#_on_stage_changed()
		#npc_set()
		pass

## [KR] 스테이지 변경 콜백. 1프레임 대기 후 [method base_event_update]를 호출한다.
## [EN] Stage change callback. Calls [method base_event_update] after waiting 1 frame.
func _on_stage_changed():
	await get_tree().process_frame
	base_event_update()

## [KR] 시작 지점(TYPE_BASE)인 경우 이벤트 버블 표시 여부를 [member event_enabled]에 따라 갱신한다.
## [EN] Updates event bubble visibility based on [member event_enabled] when at starting point (TYPE_BASE).
func base_event_update():
	if floor_manager.current_stage_type == Constants.TYPE_BASE:
		if event_enabled:
			is_enable(true)
		else:
			is_enable(false)

## [KR] [PartnerManager]를 갱신하고 [method event_bubble_update]를 호출한다.
## [EN] Updates [PartnerManager] and calls [method event_bubble_update].
func event_enabled_update():
	partner_manager = get_tree().get_first_node_in_group("partnermanager") as PartnerManager
	event_bubble_update(partner_manager)

## [KR] 파트너 조건을 검사하여 [member event_enabled]를 갱신한다.
## [br]시작 지점에서는 동행 파트너를 검사하지 않고 호감도만 확인하며,
## 서브 히로인(코니알/파주주/집사)도 동행 검사를 생략한다.
## 일반 히로인은 현재 동행 파트너와 일치해야만 활성화된다.
## [EN] Checks partner conditions to update [member event_enabled].
## [br]At the starting point, only checks affection without verifying companion partner.
## Sub-heroines (Konial/Pazuzu/Butler) also skip companion checks.
## Regular heroines are only activated when matching the current companion partner.
func event_bubble_update(current_partner_manager: PartnerManager):
	if floor_manager.current_stage_type == Constants.TYPE_BASE: # [KR] 시작 지점인 경우 현재 파트너 검사 안함 / [EN] Skip current partner check at starting point
		if current_partner_manager.can_event(h_scene_info.love_ability, h_scene_info.partner):
			event_enabled = true
		else:
			event_enabled = false
	elif h_scene_info.partner == Constants.NpcTypes.KONIAL \
	or h_scene_info.partner == Constants.NpcTypes.PAZUZU \
	or h_scene_info.partner == Constants.NpcTypes.BUTLER: # [KR] 이벤트 대상이 동행하지 않는 서브 히로인일 경우 동행 파트너 검사 안함 / [EN] Skip companion partner check for sub-heroines that don't accompany
		if current_partner_manager.can_event(h_scene_info.love_ability, h_scene_info.partner):
			event_enabled = true
		else:
			event_enabled = false
	else:
		if current_partner_manager.current_partner == h_scene_info.partner \
		and current_partner_manager.can_event(h_scene_info.love_ability, current_partner_manager.current_partner):
			event_enabled = true
		else:
			event_enabled = false
	_update_color()

## [KR] 스테이지 클리어 콜백. 스테이지 타입에 따라 NPC 위치 재조정 후 이벤트를 활성화한다.
## [EN] Stage clear callback. Readjusts NPC positions by stage type then activates events.
func _on_stage_clear():
	if floor_manager.current_stage_type == Constants.TYPE_BASE:
		return
	elif floor_manager.current_stage_type == Constants.TYPE_STAGE:
		set_near_npc_position()
	
	set_current_stage_clear(true)
	event_enabled_update()
	is_enable(true)

## [KR] 스테이지 클리어 시 이벤트 영역과 겹치는 NPC를 감지하여 위치를 재조정한다.
## [br]맵 중앙(x=960) 기준으로 좌/우 150px씩 밀어내어 이벤트 버블과 겹치지 않게 한다.
## [EN] Detects NPCs overlapping the event area on stage clear and readjusts their positions.
## [br]Pushes left/right by 150px from map center (x=960) to avoid overlapping with event bubbles.
func set_near_npc_position():
	if floor_manager.current_stage_type != Constants.TYPE_STAGE: # [KR] 스테이지 이외에는 비조정 / [EN] No adjustment outside stages
		return
	var near_npc = get_overlapping_bodies()
	for body in near_npc:
		if body is Npc:
			if body.position.x >= 960: # [KR] 맵의 중앙 기준 / [EN] Based on map center
				body.position.x -= 150
			else:
				body.position.x += 150

## [KR] 해당 히로인의 경험치가 최대치에 도달했을 때 호출되는 콜백.
## [br]시작 지점에서는 히로인의 [code]love_level[/code]이 이벤트 조건과 정확히 일치해야 활성화된다.
## [EN] Callback when the heroine's EXP reaches maximum.
## [br]At the starting point, the heroine's [code]love_level[/code] must exactly match the event condition to activate.
func _on_npc_exp_max(npc_type: int):
	if npc_type == h_scene_info.partner:
		# [KR] 베이스에선 히로인의 레벨이 맞아야만 보이게 된다
		# [EN] At base, only visible when the heroine's level matches
		if floor_manager.current_stage_type == Constants.TYPE_BASE:
			if partner_manager.partner[npc_type].love_level == h_scene_info.love_ability:
				is_enable(true)
				event_enabled_update()
		else:
			is_enable(true)
			event_enabled_update()
	

## [KR] NPC 레벨업 시그널 콜백. 대상 NPC와 일치하면 [member played]를 [code]true[/code]로 설정한다.
## [EN] NPC level-up signal callback. Sets [member played] to [code]true[/code] if matching target NPC.
func _on_event_played(npc_int : int):
	if npc_int == h_scene_info.partner:
		played = true

## [KR] [member event_enabled] 상태에 따라 버블 텍스처와 modulate 색상을 갱신한다.
## [EN] Updates bubble texture and modulate color based on [member event_enabled] state.
func _update_color():
	if event_enabled:
		# [KR] 이벤트가 가능하면 원본 색상
		# [EN] Original color when event is available
		h_event_bubble.texture = Constants.H_EVENT_BUBBLES[Constants.HBubble.EVENT_ON]
		love_level_fill.show()
		self.modulate = original_color
	else:
		# [KR] 이벤트가 불가능하면 회색
		# [EN] Gray when event is unavailable
		love_level_fill.show()
		h_event_bubble.texture = Constants.H_EVENT_BUBBLES[Constants.HBubble.EVENT_OFF]
		self.modulate = disabled_color


## [KR] 플레이어 접근 상태에 따라 버블 크기와 키보드 아이콘 표시를 토글한다.
## [EN] Toggles bubble size and keyboard icon display based on player proximity.
func near_player(near:bool)->void:
	if near:
		h_event_bubble.scale = Vector2(1.2,1.2)
		keyboard_icon.show()
		# [KR] 대화 중에는 카메라/플레이어 이동(anim_change)으로 이벤트 영역에 닿아도 버블 SE를 재생하지 않는다.
		#      (호감도 H 이벤트 씬 전환 중 "퐁" SE가 잘못 울리던 버그 방지)
		if sfx and not Dialogic.current_timeline:
			var sound = UiSoundStreamPlayer.SOUND_LOVE_BUBBLE_OK if event_enabled else UiSoundStreamPlayer.SOUND_LOVE_BUBBLE_NO
			sfx.set_stream_play_to_file(sound)
		if not event_enabled:
			_try_show_friendly_noti()
	else:
		h_event_bubble.scale = Vector2(1.0,1.0)
		keyboard_icon.hide()

func _try_show_friendly_noti() -> void:
	var message_key: String
	match h_scene_info.partner:
		Constants.NpcTypes.REINA: message_key = "MORE_FRIENDLY_REINA"
		Constants.NpcTypes.MAI:   message_key = "MORE_FRIENDLY_MAI"
		_: return

	# 현재 동행 파트너가 일치해야만 알림 표시
	if not partner_manager or partner_manager.current_partner != h_scene_info.partner:
		return

	NotionEvent.notion(message_key, Constants.SD_ICONS[h_scene_info.partner])

## [KR] player_event 콜백. [member no_display_dialog_love]가 설정된 경우,
## 이 이벤트가 선택되는 순간(Dialogic.start 이전)에 호감도 UI를 억제한다.
## [EN] player_event callback. If [member no_display_dialog_love] is set,
## suppresses the love UI at the moment this event is selected (before Dialogic.start).
func _on_player_event(event: EventArea):
	if event == self and no_display_dialog_love:
		GameEvents.suppress_love_ui = true

## [KR] Dialogic 타임라인 시작 콜백. 대화 중에는 이벤트 버블을 숨긴다.
## [EN] Dialogic timeline start callback. Hides event bubbles during dialogue.
func _on_timeline_started():
	is_enable(false)

## [KR] Dialogic 타임라인 종료 콜백. 시작 지점이면 이벤트 상태에 따라, 스테이지이면 클리어 상태에 따라 버블을 복원한다.
## [EN] Dialogic timeline end callback. Restores bubbles by event state at starting point, or by clear state at stage.
func _on_timeline_ended():
	if no_display_dialog_love:
		GameEvents.suppress_love_ui = false
	if floor_manager.current_stage_type == Constants.TYPE_BASE:
		if event_enabled:
			is_enable(true)
		else:
			is_enable(false)
	else:
		is_enable(current_stage_clear)
		await get_tree().create_timer(0.5).timeout
		set_near_npc_position()

## [KR] 이 이벤트가 이미 읽혔는지 [GlobalGameManager]에서 조회하여 반환한다.
## [EN] Queries [GlobalGameManager] to check if this event has already been read.
func event_played()-> bool:
	return global_game_manager.get_read_event_list(h_scene_info.dialog_title)

## [KR] 이벤트 버블의 표시/숨김을 제어한다.
## [br][param state]가 [code]true[/code]이고 챕터 해금 조건을 충족하면 표시, 아니면 숨긴다.
## [EN] Controls event bubble show/hide.
## [br]Shows if [param state] is [code]true[/code] and chapter unlock condition is met, otherwise hides.
func is_enable(state: bool):
	if state and MetaProgression.get_current_chapter() >= h_scene_info.unlock_chapter:
		set_deferred("monitorable", true)
		set_deferred("visible", true)
	else:
		set_deferred("monitorable", false)
		set_deferred("visible", false)

## [KR] 현재 스테이지 클리어 상태를 설정한다.
## [EN] Sets the current stage clear state.
func set_current_stage_clear(state: bool):
	current_stage_clear = state

## [KR] 이벤트 다시 읽기 경고창에서 취소 시 시작 지점으로 복귀하는 함수.
## [br]스테이지 타입이 [code]TYPE_COMPLETE[/code]이면 게임 완료 이벤트를 발신한다.
## [EN] Function to return to starting point when canceling from the event replay warning.
## [br]Emits game complete event if stage type is [code]TYPE_COMPLETE[/code].
func no_event_replay_return_base():
	if current_level.stage_type == Constants.TYPE_COMPLETE:
		GameEvents.emit_game_complete()
