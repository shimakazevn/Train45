## HUD 숨기기 컴포넌트.
## 테스트 키로 HUD와 NPC 가시성을 토글하며, 에필로그·타임라인·스테이지 전환 시 자동으로 상태를 복원한다.
extends Control

## HUD로 사용하는 [CanvasLayer] 배열.
@export var hud: Array[CanvasLayer]
## 숨기기 모드 활성 시 표시되는 라벨.
@onready var hide_mode_label: Label = $CanvasLayer/HideModeLabel
## 현재 [FloorManager] 참조.
@export var floor_manager: FloorManager

## 현재 숨기기 모드 활성 여부.
var hide_mode:= false

## [KR] 관찰 모드 토글 디바운스. LT 등 아날로그 트리거가 임계값 근처에서 디지털 on/off로
## [KR] 떨리면 이벤트 방식으론 모드가 반복 토글된다. 한 번 토글하면 이 시간 이상 '연속으로'
## [KR] 떼어질 때까지 재무장하지 않아, 트리거를 중간쯤 걸쳐 둬도 반복되지 않는다.
const _HIDE_TOGGLE_RELEASE_DEBOUNCE_MS := 150
var _hide_toggle_armed := true          # [KR] true면 다음 누름에 토글 가능
var _hide_toggle_last_pressed_ms := 0   # [KR] 마지막으로 눌려 있던 시각(떨림 포함)

## 시그널 연결 및 숨기기 모드 라벨 초기 숨김 처리를 수행한다.
func _ready() -> void:
	Dialogic.timeline_started.connect(_on_timeline_started)
	GameEvents.stage_change.connect(_on_stage_change)
	GameEvents.stage_clear.connect(_on_stage_clear)
	GameEvents.without_npc_hide.connect(_on_withouot_npc_hide)
	GameEvents.join_epilogue.connect(_on_join_epilogue)
	
	if hide_mode_label.visible:
		hide_mode_label.hide()

## 테스트 키(관찰 모드 토글) 입력을 매 프레임 폴링한다.
## Why: LT 등 아날로그 트리거가 임계값 근처에서 떨리면 눌림이 짧게 끊겼다 다시 들어와
##      이벤트 방식으로는 모드가 껐다 켜졌다 반복된다. 한 번 토글하면 일정 시간 '연속으로'
##      떼어질 때까지 재무장하지 않으므로, 트리거를 중간쯤 걸쳐 두어도 반복되지 않는다.
func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if Input.is_action_pressed("testkey"):
		_hide_toggle_last_pressed_ms = now  # 눌린 동안(순간 떨림 포함) 계속 갱신
		if _hide_toggle_armed:
			_hide_toggle_armed = false
			_toggle_hide_mode()
	elif now - _hide_toggle_last_pressed_ms >= _HIDE_TOGGLE_RELEASE_DEBOUNCE_MS:
		_hide_toggle_armed = true  # 충분히 오래 연속으로 떼어졌을 때만 다음 토글 허용

## 관찰 모드를 토글한다. 에필로그·대화·H액션·강제피격 중에는 무시한다.
func _toggle_hide_mode() -> void:
	if GameEvents.is_epilogue_room or Dialogic.current_timeline:
		return
	if GameEvents.get_window_state(Constants.WINDOW_STATE_H_ACTION):
		return
	if GameEvents.game_state == Constants.STATE_RAPE:
		return
	set_hide_mode(not hide_mode)

## 숨기기 모드를 [param state]로 설정한다.
## HUD 가시성과 NPC 가시성을 함께 변경하며, 에필로그 중에는 강제로 비활성한다.
func set_hide_mode(state: bool):
	if GameEvents.is_epilogue_room: ## 에필로그인 경우 hud 무조건 안보이도록
		state = false
	
	hide_mode = state
	set_hud_visible(hide_mode)
	set_npc_visible(hide_mode)


## NPC 숨기기 모드 타입.
## [code]HIDE_FIND[/code]는 탐지용으로 반투명 처리하고,
## [code]HIDE_FULL[/code]는 [param active_npc_type] 외의 NPC를 완전히 투명하게 만든다.
enum HideModeType {HIDE_FIND, HIDE_FULL}

## NPC 가시성을 [param state]에 따라 변경한다.
## [param hide_mode_type]으로 숨기기 방식을 지정하고,
## [code]HIDE_FULL[/code] 모드에서는 [param active_npc_type]에 해당하는 NPC만 유지한다.
func set_npc_visible(state: bool, hide_mode_type: HideModeType = HideModeType.HIDE_FIND, active_npc_type: int = -1):
	var npc_array: Array[Node] = get_tree().get_nodes_in_group("npc")
	if hide_mode_type == HideModeType.HIDE_FIND: #탐지용 숨기기 기능
		var player:Player = floor_manager.current_level.player
		if is_instance_valid(player):
			if state:player.modulate = Color(0,1,1,0.2)
			else: player.modulate = Color.WHITE
		
		for i in npc_array:
			if is_instance_valid(i):
				var npc:Npc = i
				if state: npc.modulate = Color(0,1,1,0.2)
				else: npc.modulate = Color.WHITE
	
	elif hide_mode_type == HideModeType.HIDE_FULL: #H이벤트용 다른 엔피씨 숨기기 기능, 해당 엔피씨를 제외한 다른 엔피씨를 숨긴다.
		for i in npc_array:
			if is_instance_valid(i):
				var npc:Npc = i
				if npc.npc_name == active_npc_type:
					continue
				else:
					if state: npc.modulate = Color.TRANSPARENT
					else: npc.modulate = Color.WHITE

## [signal GameEvents.without_npc_hide] 시그널 콜백. [code]HIDE_FULL[/code] 모드로 NPC를 숨긴다.
func _on_withouot_npc_hide(state: bool, active_npc_type: int):
	set_npc_visible(state, HideModeType.HIDE_FULL, active_npc_type)

## HUD [CanvasLayer] 배열의 가시성을 [param state]에 따라 토글한다.
## 숨기기 모드가 활성이면 HUD를 숨기고 라벨을 표시한다.
func set_hud_visible(state: bool):
	for i in hud.size():
		hud[i].visible = !state
		hide_mode_label.visible = state

## 타임라인 시작 시 숨기기 모드를 해제한다.
func _on_timeline_started():
	if hide_mode:
		set_hide_mode(false)

## 스테이지 변경 시 에필로그이면 HUD를 숨기고, 아니면 숨기기 모드를 해제한다.
func _on_stage_change():
	if GameEvents.is_epilogue_room:
		epilogue_hud_hide()
		return
	if hide_mode:
		set_hide_mode(false)

## 스테이지 클리어 시 숨기기 모드를 해제한다.
func _on_stage_clear():
	if hide_mode:
		set_hide_mode(false)

## 에필로그 진입 시 HUD를 숨긴다.
func _on_join_epilogue():
	epilogue_hud_hide()

## 에필로그 전용 HUD 숨기기. 모든 HUD [CanvasLayer]를 비표시한다.
func epilogue_hud_hide():
	for i in hud.size():
		hud[i].visible = false
