## [KR] 플레이어 캐릭터 컨트롤러.
## 이동, 이상현상 탐지(차지), NPC/이벤트 상호작용, 고스트 H 연출 등
## 플레이어의 모든 입력과 상태를 총괄한다.[br]
## [b]구성 컴포넌트:[/b][br]
## - [member velocity_component]: 이동 속도/가속도 계산[br]
## - [member upgrade_component]: 장비/능력치 업그레이드 적용[br]
## - [member find_area]: 이상현상 탐지 범위[br]
## - [member talk_area]: NPC 대화 가능 범위[br]
## - [member abilities]: 어빌리티 관리[br]
## 외부 시스템과는 시그널([code]GameEvents[/code], [code]Dialogic[/code])로 느슨하게 연결한다.
## [EN] Player character controller.
## Handles movement, anomaly detection (charge), NPC/event interaction, ghost H scenes, etc.
## Manages all player input and state.[br]
## [b]Components:[/b][br]
## - [member velocity_component]: Movement speed/acceleration calculation[br]
## - [member upgrade_component]: Equipment/stat upgrade application[br]
## - [member find_area]: Anomaly detection range[br]
## - [member talk_area]: NPC conversation range[br]
## - [member abilities]: Ability management[br]
## Loosely connected to external systems via signals ([code]GameEvents[/code], [code]Dialogic[/code]).
class_name Player extends CharacterBody2D

## [KR] 아날로그 스틱 이동 데드존. 이동은 normalized()로 크기를 버려 풀스피드라
##      미세 조작이 없으므로, 드리프트 방지를 위해 다소 높게 잡는다.
const STICK_DEADZONE := 0.3

## [KR] 차징(액션 키)을 시작한 패드 device. 진동은 이 패드에만 보낸다.
##      패드 0 하드코딩은 2개 연결 시 미사용 패드를 울리므로, 액션 키를 실제로 누른 패드만 진동시킨다.
var _charging_pad_device := -1

## [KR] 전역 게임 흐름(스테이지 전환, 상태 관리 등)을 조율하는 매니저 참조.
## [EN] Reference to the manager that coordinates global game flow (stage transitions, state management, etc.).
var global_game_manager : GlobalGameManager
## [KR] 현재 층(스테이지) 정보를 관리하는 매니저 참조.
## [EN] Reference to the manager that handles current floor (stage) information.
var floor_manager : FloorManager
## [KR] 이동 속도·가속도 계산을 분리한 컴포넌트.
## [EN] Component that separates movement speed/acceleration calculation.
@onready var velocity_component = $VelocityComponent
## [KR] 장비·능력 업그레이드를 플레이어에 적용하는 컴포넌트.
## [EN] Component that applies equipment/ability upgrades to the player.
@onready var upgrade_component = $UpgradeComponent

## [KR] 플레이어 스프라이트 애니메이션을 제어하는 [AnimationPlayer].
## [EN] [AnimationPlayer] that controls player sprite animation.
@onready var animation_player = $AnimationPlayer
## [KR] 플레이어의 시각적 루트 노드. 좌우 반전([code]scale.x[/code]) 등에 사용.
## [EN] Player's visual root node. Used for horizontal flipping ([code]scale.x[/code]), etc.
@onready var visual = $Visual
## [KR] 탐지 차지 진행률을 표시하는 프로그레스 바 UI.
## [EN] Progress bar UI that displays detection charge progress.
@onready var find_progress = %FindProgress
## [KR] 탐지 차지 중 플레이어 주변에 표시되는 셰이더 이펙트.
## [EN] Shader effect displayed around the player during detection charging.
@onready var find_effect = %FindEffect
## [KR] 이상현상 탐지 판정에 사용되는 [Area2D] 영역.
## [EN] [Area2D] region used for anomaly detection checks.
@onready var find_area = $FindArea
## [KR] 아이템 자동 수집 판정 영역.
## [EN] Area for automatic item collection detection.
@onready var item_collect_area: Area2D = $ItemCollectArea

## [KR] 플레이어가 보유한 어빌리티를 관리하는 노드.
## [EN] Node that manages the player's abilities.
@onready var abilities = $Abilities
## [KR] NPC·이벤트와 대화 가능 여부를 판정하는 상호작용 영역.
## [EN] Interaction area that determines whether NPC/event conversation is possible.
@onready var talk_area: Area2D = $TalkArea
@onready var ui_sound_stream_player: UiSoundStreamPlayer = $UiSoundStreamPlayer
#@onready var finding_charge_stream: AudioStreamPlayer = $FindingChargeStreamPlayer
## [KR] 귀신 강간 중 귀신 신음 루프 플레이어.
@onready var ghost_moan_stream: GhostMoanStream = $GhostMoanStream

## [KR] 게이지 위젯(표시/숨김용). 바·스트로크 애니를 포함한 컨테이너.
@onready var rape_gauge_base: Sprite2D = %ActionProgressBase
## [KR] 강간 저항 게이지(값). base를 거쳐 참조 → ActionProgressBase를 씬화(인스턴스)해도 안 깨진다.
@onready var rape_gauge: TextureProgressBar = rape_gauge_base.get_node("ActionProgressBar")
## [KR] 저항 중 표시되는 키 입력 안내 아이콘(사정 시 숨김).
@onready var keyboard_icon: TextureRect = %CumKeyboardIcon
## [KR] 사정 스프라이트(평소 숨김) — 귀신별 cum 애니는 rape anim_string과 같은 이름.
@onready var cum_sprite: Sprite2D = $Visual/CumSprite
@onready var cum_anim: AnimationPlayer = $Visual/CumSprite/CumAnim
## [KR] 사정 시 화면 깜박임(흰 플래시) — free action(omt_component)과 동일. CanvasLayer라 별도로 켜야 렌더된다.
@onready var cum_canvas: CanvasLayer = $Visual/CumSprite/CumCanvasLayer
@onready var cum_effect: ColorRect = $Visual/CumSprite/CumCanvasLayer/CumEffect
## [KR] 강간 루프 아트 스프라이트(사정 시 숨김).
@onready var rape_sprite: Sprite2D = $Visual/Sprite2D
## [KR] 저항/귀환 안내 라벨. 상태에 따라 '참기'↔'귀환' 번역키로 전환.
@onready var cum_delay_label: Label = %CumDelayLabel

## [KR] 게이지 자동 증가 속도(초당).
@export var rape_gauge_fill := 15.0
## [KR] 자동 증가의 가속(초당²). 0이면 등속(선형). 올리면 시간이 지날수록 빨라진다.
@export var rape_gauge_fill_accel := 0.0
## [KR] action 키 1회당 게이지 감소량(참기).
@export var rape_gauge_drain := 18.0
## [KR] 사정 애니 종료 후 자동 귀환까지 대기 시간(초).
@export var rape_return_delay := 1.0

@export var cum_sfx_player: HSfxStream

## [KR] 안내 라벨 번역키(시트에 직접 추가 예정). 저항=참기, 귀환 대기=귀환.
const RAPE_RESIST_GUIDE_KEY := "RAPE_RESIST_GUIDE"
const RAPE_RETURN_GUIDE_KEY := "RAPE_RETURN_GUIDE"

var _rape_anim := ""
var _rape_cumming := false
var _rape_fill_rate := 0.0
var _cum_ef_tween: Tween

## [KR] 외부(컷씬·이벤트 등)에서 플레이어 입력 가능 여부를 제어하기 위한 플래그.
## [EN] Flag for controlling player input availability from external sources (cutscenes, events, etc.).
@export var input_enabled:bool = true
## [KR] 탐지 차지에 필요한 기본 시간(초). [member upgrade_component]로 변경될 수 있다.
## [EN] Base time (seconds) required for detection charge. Can be modified by [member upgrade_component].
var charge_base_time: float = PlayerData.PLAYER_START_CHARGE_TIME
## [KR] 실제 적용되는 탐지 차지 소요 시간(초). 업그레이드 적용 후의 값.
## [EN] Actual detection charge duration (seconds). Value after upgrades are applied.
var charge_time: float = PlayerData.PLAYER_START_CHARGE_TIME
## [KR] 탐지 영역의 기본 크기. 업그레이드로 확장될 수 있다.
## [EN] Base size of the detection area. Can be expanded through upgrades.
var find_area_base_size : Vector2 = PlayerData.PLAYER_START_AREA_SIZE


## [KR] 탐지 액션을 일시적으로 잠그는 플래그. 튜토리얼 등에서 사용.
## [EN] Flag that temporarily locks the detection action. Used in tutorials, etc.
var find_lock = false
## [KR] 탐지 키를 누르고 있는 중인지 여부 (차지 진행 중).
## [EN] Whether the detection key is being held down (charge in progress).
var is_charging = false
## [KR] NPC가 [member talk_area] 안에 있는지 여부.
## [EN] Whether an NPC is within [member talk_area].
var is_near_npc = false
## [KR] 이벤트 오브젝트가 상호작용 범위 안에 있는지 여부.
## [EN] Whether an event object is within interaction range.
var is_near_event = false
## [KR] 근처에 H 상호작용이 가능한 고스트 이상현상 참조.
## [EN] Reference to a nearby ghost anomaly that allows H interaction.
var near_h_ghost: GhostHAnomaly # [KR] 근처에 h가능한 귀신 / [EN] Nearby ghost available for H
## [KR] 현재 고스트 H 연출이 진행 중인지 여부.
## [EN] Whether a ghost H scene is currently in progress.
var is_ghost_play: bool = false # [KR] 현재 귀신과 h액션 중인지 / [EN] Whether currently in H action with ghost
## [KR] 탐지 차지가 시작된 시각(초 단위, [method Time.get_ticks_msec] 기반).
## [EN] Time when detection charge started (in seconds, based on [method Time.get_ticks_msec]).
var charging_start_time = 0.0
## [KR] 현재 탐지 차지 진행률 ([code]0.0[/code]–[code]100.0[/code]).
## [EN] Current detection charge progress ([code]0.0[/code]–[code]100.0[/code]).
var charging_percentage = 0.0
## [KR] 탐지 영역의 [CollisionShape2D]. 크기 조정 시 참조.
## [EN] [CollisionShape2D] of the detection area. Referenced when resizing.
@onready var find_area_base = $FindArea/CollisionShape2D

## [KR] 현재 상호작용 범위 안에 있는 NPC 참조. 없으면 [code]null[/code].
## [EN] Reference to the NPC currently within interaction range. [code]null[/code] if none.
var near_npc: Npc = null
## [KR] 현재 상호작용 범위 안에 있는 이벤트 오브젝트 참조. 없으면 [code]null[/code].
## [EN] Reference to the event object currently within interaction range. [code]null[/code] if none.
var near_event = null

## [KR] 플레이어가 활성화(입력 가능) 상태로 전환되었을 때 발행.
## [EN] Emitted when the player transitions to an active (input enabled) state.
signal player_enable
## [KR] 대화 키를 눌렀을 때 발행.
## [EN] Emitted when the talk key is pressed.
signal player_press_talk
## [KR] 탐지 차지 완료 시 발행 (일반 스테이지).
## [EN] Emitted when detection charge completes (normal stage).
signal player_action
## [KR] 탐지 차지 완료 시 발행 (프롤로그/튜토리얼 스테이지).
## [EN] Emitted when detection charge completes (prologue/tutorial stage).
signal player_tuto_action
## [KR] 이상현상을 성공적으로 발견했을 때 발행.
## [EN] Emitted when an anomaly is successfully found.
signal find_anomaly
## [KR] 이상현상 탐지에 실패했을 때 발행.
## [EN] Emitted when anomaly detection fails.
signal find_faild
## [KR] 고스트 H 연출 시작/종료 시 발행. [param state]가 [code]true[/code]이면 시작.
## [EN] Emitted when ghost H scene starts/ends. Starts when [param state] is [code]true[/code].
signal player_ghost_sex(state: bool)

## [KR] 이동 속도의 기준값. [member velocity_component]의 초기 [code]max_speed[/code]를 저장.
## [EN] Base movement speed value. Stores the initial [code]max_speed[/code] of [member velocity_component].
var base_speed = 0
## [KR] 마지막 입력 이동 방향 벡터.
## [EN] Last input movement direction vector.
var move_dir:Vector2
## [KR] 직전 프레임의 [member visible] 값. 가시성 변경 감지에 사용.
## [EN] Previous frame's [member visible] value. Used to detect visibility changes.
var before_visible:= false


## [KR] 초기화. 의존성을 연결하고 전역 이벤트·다이얼로그 시그널을 구독한다.
## [EN] Initialization. Connects dependencies and subscribes to global event/dialog signals.
func _ready():
	visibility_changed.connect(_on_visible_changed)
	global_game_manager = get_tree().get_first_node_in_group("globalgamemanager") as GlobalGameManager
	floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
	
	find_faild.connect(on_find_faild)
	cum_anim.animation_finished.connect(_on_cum_anim_finished)
	if cum_sfx_player:
		cum_sfx_player.h_sfx_played.connect(_on_cum_sfx_played)
	cum_sprite.hide() # 사정 아트만 숨김(게이지 위젯은 RapeGaugeLayer로 분리되어 씬에서 visible=false로 시작)

	charge_time = charge_base_time
	base_speed = velocity_component.max_speed
	upgrade_component.set_player(self)
	player_press_talk.connect(npc_talk)
	GameEvents.update_equip_item.connect(on_ability_upgrade_added)
	GameEvents.position_change.connect(on_position_change)
	GameEvents.player_visible.connect(on_visible)
	GameEvents.direction_change.connect(on_direction_change)
	Dialogic.signal_event.connect(_on_signal_event)
	Dialogic.timeline_started.connect(_on_dialog_started)

## [KR] 매 프레임 플레이어 상태를 갱신한다.[br]
## 게임 상태·다이얼로그·트랜지션 등 전역 조건에 따라 입력 허용 여부를 결정하고,
## 허용된 경우에만 액션 처리와 이동을 수행한다.
## [EN] Updates player state every frame.[br]
## Determines input availability based on global conditions (game state, dialog, transition, etc.),
## and only performs action processing and movement when allowed.
func _process(_delta):
	before_visible = visible
	if GameEvents.game_state == Constants.STATE_FIND_FAILED or GameEvents.game_state == Constants.STATE_DONT_MOVE:
		input_enabled = false
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
	if GameEvents.game_state == Constants.STATE_RAPE_FAILED: 
		input_enabled = false
	if GameEvents.game_state == Constants.STATE_RAPE:
		if not _rape_cumming:
			_update_rape_gauge(_delta)
		input_enabled = false
	if GameEvents.game_state == Constants.STATE_EVENT:
		input_enabled = false
		visible = false
	if global_game_manager.is_transition:
		input_enabled = false

	if GameEvents.game_state == Constants.STATE_NORMAL and Dialogic.current_timeline == null and not is_ghost_play:
		visible = true
		
	if not Dialogic.current_timeline == null :
		input_enabled = false
		animation_player.play("idle")
	else:
		Callable(self, "set_input_enabled").call_deferred(true)
	
	if not input_enabled:
		return 

	active_action()
	find_target_icon()

	# [KR] Why: 고스트 H 연출은 별도 상태 머신(ghost_sex)이 제어하므로
	# 일반 이동 로직과 충돌하지 않도록 차단한다.
	# [EN] Why: Ghost H scenes are controlled by a separate state machine (ghost_sex),
	# so normal movement logic is blocked to avoid conflicts.
	if not is_ghost_play:
		if not is_charging:
			if GameEvents.game_state != Constants.STATE_NORMAL:
				return
			character_move()
		else:
			animation_player.play("idle")		
		
	
## [KR] [param value]에 따라 [member input_enabled]를 설정한다.[br]
## [code]call_deferred[/code]로 호출되어 프레임 말미에 입력을 복원할 때 사용.
## [EN] Sets [member input_enabled] according to [param value].[br]
## Called via [code]call_deferred[/code] to restore input at the end of the frame.
func set_input_enabled(value: bool):
	input_enabled = value

## [KR] 입력 벡터를 계산하여 [member velocity_component]에 이동을 위임하고,
## 이동 방향에 따라 애니메이션과 스프라이트 방향을 갱신한다.
## [EN] Calculates the input vector, delegates movement to [member velocity_component],
## and updates animation and sprite direction based on movement direction.
func character_move():
	var movement_vector = get_movement_vector()
	var direction = movement_vector.normalized()
	velocity_component.accelerate_in_direction(direction)
	velocity_component.move(self)

	if movement_vector.x != 0 or movement_vector.y != 0:
		animation_player.play("walk")
	else:
		animation_player.play("idle")

	var move_sign = sign(movement_vector.x)
	if move_sign != 0:
		visual.scale = Vector2(move_sign, 1)
		talk_area.update_move_sign(move_sign)
	move_dir = movement_vector

## [KR] 키보드/D패드와 아날로그 스틱 입력을 통합하여 이동 벡터를 반환한다.[br]
## 아날로그 스틱 입력이 데드존([code]STICK_DEADZONE[/code])을 초과하면 스틱 우선, 아니면 키보드 사용.
## [EN] Combines keyboard/D-pad and analog stick input to return a movement vector.[br]
## If analog stick input exceeds the deadzone ([code]0.2[/code]), stick takes priority; otherwise keyboard is used.
func get_movement_vector() -> Vector2:
	# [KR] 1) 키보드 / D패드용 (8방향)
	# [EN] 1) For keyboard / D-pad (8-directional)
	var x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	var keyboard_vec = Vector2(x, y)

	# [KR] 2) 패드 왼쪽/오른쪽 스틱(아날로그) 읽기
	#     패드 2개 연결 시 device 0 고정은 엉뚱한(방치된) 패드를 읽어 조작이 막힌다.
	#     연결된 모든 패드를 순회해 가장 강한 스틱 입력을 채택한다.
	# [EN] 2) Read gamepad left/right stick (analog)
	var joy_vec := Vector2.ZERO
	var joy_right_vec := Vector2.ZERO
	for device in Input.get_connected_joypads():
		var lv := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		var rv := Vector2(Input.get_joy_axis(device, JOY_AXIS_RIGHT_X), Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y))
		if lv.length() > joy_vec.length():
			joy_vec = lv
		if rv.length() > joy_right_vec.length():
			joy_right_vec = rv

	# [KR] 3) 데드존 설정 (스틱 중립 근처는 0 처리) — 왼쪽 스틱 → 오른쪽 스틱 → 키보드/D패드 순으로 우선
	# [EN] 3) Deadzone setting — priority: left stick → right stick → keyboard/D-pad
	if joy_vec.length() > STICK_DEADZONE:
		return joy_vec
	elif joy_right_vec.length() > STICK_DEADZONE:
		return joy_right_vec
	else:
		return keyboard_vec

## [KR] 액션 입력의 진입점. 프레임마다 호출된다.[br]
## [member near_h_ghost]가 존재하고 사후 상태가 아니면 [method ghost_sex]를 우선 실행하고,
## 그 외에는 일반 탐지([method find_target])를 수행한다.
## [EN] Entry point for action input. Called every frame.[br]
## If [member near_h_ghost] exists and is not in post-state, [method ghost_sex] is prioritized;
## otherwise normal detection ([method find_target]) is performed.
func active_action():
	if near_h_ghost != null and not near_h_ghost.current_state == GhostHAnomaly.GhostState.AFTER_CUM:
		#if not near_h_ghost.current_state == GhostHAnomaly.GhostState.CUM:
		if is_charging: _stop_charging()
		ghost_sex()
	else:
		find_target()

## [KR] 고스트 H 상호작용 상태 머신.[br]
## [code]AFTER_FIND[/code] 상태에서 액션 키를 누르면 H 연출을 시작하고,
## [code]ACTION[/code] 상태에서 키를 떼면 조건에 따라 종료 처리한다.[br]
## Why: H 연출은 고스트 측 상태([code]GhostState[/code])와 플레이어 입력이
## 맞물려야 하므로 상태별 분기로 동기화한다.
## [EN] Ghost H interaction state machine.[br]
## Pressing the action key in [code]AFTER_FIND[/code] state starts the H scene,
## and releasing the key in [code]ACTION[/code] state triggers end processing based on conditions.[br]
## Why: H scenes require synchronization between ghost-side state ([code]GhostState[/code]) and player input,
## so state-based branching is used for synchronization.
func ghost_sex():
	if not near_h_ghost.equip_item_check_override():
		return
	if near_h_ghost.current_state == GhostHAnomaly.GhostState.CUM:
		return
	# [KR] 근처 h가능 귀신이 있으면 키를 누르는 동안 플레이어 스프라이트 숨김
	# [EN] Hide player sprite while key is held if a nearby H-capable ghost exists
	if near_h_ghost.current_state == GhostHAnomaly.GhostState.AFTER_FIND:
		if Input.is_action_just_pressed("action") and find_lock == false:
			if not near_h_ghost.end_ghost_h.is_connected(set_end_ghost_sex):
				near_h_ghost.end_ghost_h.connect(set_end_ghost_sex)
				
			is_ghost_play = true
			self.hide()
			animation_player.stop()
			player_ghost_sex.emit(true)
	# [KR] 키를 때면 다시 플레이어 보임, idle상태로 플레이
	# [EN] When key is released, player becomes visible again and plays idle state
	if near_h_ghost.current_state == GhostHAnomaly.GhostState.ACTION:
		if Input.is_action_just_released("action"):
			if near_h_ghost.climax_life > 0.0:
				set_end_ghost_sex()
			player_ghost_sex.emit(false)

## [KR] 고스트 H 연출 종료 시 호출되는 정리 함수.[br]
## [member is_ghost_play] 해제, 스프라이트 복원, 애니메이션 초기화,
## [code]end_ghost_h[/code] 시그널 연결 해제까지 일괄 처리한다.
## [EN] Cleanup function called when ghost H scene ends.[br]
## Handles releasing [member is_ghost_play], restoring the sprite, resetting animation,
## and disconnecting the [code]end_ghost_h[/code] signal in one batch.
func set_end_ghost_sex():
	is_ghost_play = false
	self.show()
	animation_player.play("idle")
	near_h_ghost.end_ghost_h.disconnect(set_end_ghost_sex)

## [KR] 이상현상 탐지(차지) 액션의 전체 흐름을 처리한다.[br]
## 액션 키를 누르면 차지를 시작하고, 떼면 취소한다.
## 차지가 [code]100%[/code]에 도달하면 현재 스테이지 타입에 따라
## [signal player_action] 또는 [signal player_tuto_action]을 발행한다.[br]
## Why: 차지 기반 탐지는 즉발 입력 대비 오탐을 줄이고 긴장감을 높이기 위한 설계.
## 프롤로그에서는 별도 시그널로 튜토리얼 흐름을 분리한다.
## [EN] Handles the entire flow of the anomaly detection (charge) action.[br]
## Pressing the action key starts charging, releasing cancels it.
## When charge reaches [code]100%[/code], emits [signal player_action] or
## [signal player_tuto_action] depending on the current stage type.[br]
## Why: Charge-based detection reduces false positives and increases tension compared to instant input.
## In the prologue, a separate signal isolates the tutorial flow.
func find_target():
	# [KR] 키가 눌렸을 때 충전 시작
	# [EN] Start charging when key is pressed
	if Input.is_action_just_pressed("action") and find_lock == false:
		_vibrate_charging(0.1, 0.1, 7.0)
		is_charging = true
		charging_start_time = Time.get_ticks_msec() / 1000.0  # [KR] 현재 시간(초) 저장 / [EN] Store current time (seconds)
		charging_percentage = 0.0  # [KR] 초기화 / [EN] Initialize
		
	if Input.is_action_just_pressed("shift"):
		#if is_near_npc and near_npc.stage_state == Npc.StageState.NONE: #코니알 대화 안되므로 주석처리함
		_stop_charging()
		
		# near_npc / near_event 는 "마지막 진입" 하나만 유지된다(TalkArea에서 상호 해제).
		# 살아있는 하나가 곧 대상이므로 순서/우선순위는 의미 없다.
		if is_near_npc:
			if can_talk_to_npc(near_npc): # [KR] CurrentNpc가 hide 상태(run_stage 등)일 때 대화 차단 / [EN] Block dialogue when CurrentNpc is hidden (e.g. run_stage)
				npc_talk(near_npc)
		elif is_near_event and near_event.visible == true:
			event_talk(near_event)
	
	# [KR] 키가 눌린 상태에서의 처리
	# [EN] Processing while key is held down
	if is_charging:
		# [KR] 누르고 있는 시간에 비례하여 퍼센트 계산
		# [EN] Calculate percentage proportional to hold time
		var elapsed_time = Time.get_ticks_msec() / 1000.0 - charging_start_time
		charging_percentage = min((elapsed_time / charge_time) * 100, 100)  # [KR] 100%를 넘지 않도록 제한 / [EN] Clamp to not exceed 100%
		# [KR] 100%에 도달하면 find() 메서드 호출
		# [EN] Call find() method when 100% is reached
		if charging_percentage >= 100:
			if floor_manager.current_stage_type != Constants.TYPE_BASE:
				player_action.emit()
			else:
				if floor_manager.current_prologue:
					player_tuto_action.emit()

			_stop_charging_vibration()
			is_charging = false  # [KR] 완료 후 더 이상 누르지 않도록 처리 / [EN] Prevent further holding after completion

	# [KR] 키가 떼졌을 때 충전 중지
	# [EN] Stop charging when key is released
	if Input.is_action_just_released("action") and is_charging or not Input.is_action_pressed("action"):
		_stop_charging_vibration()
		is_charging = false
		charging_percentage = 0.0  # [KR] 초기화 / [EN] Initialize

## [KR] [member charging_percentage]에 따라 탐지 UI와 셰이더 이펙트를 갱신한다.[br]
## 실제 판정은 [method find_target]에서 수행하며, 이 함수는 순수하게 시각 효과만 담당.
## [EN] Updates detection UI and shader effects based on [member charging_percentage].[br]
## Actual detection is performed in [method find_target]; this function handles visuals only.
func find_target_icon():
	find_progress.value = charging_percentage
	find_effect.material.set_shader_parameter("progress", charging_percentage/100)
	if is_charging:
		find_progress.visible = true
		find_effect.visible = true
	else:
		find_progress.visible = false
		find_effect.visible = false

## [KR] near_npc와 실제로 대화할 수 있는지 판정한다.[br]
## CurrentNpc(부모 노드)가 hide 상태(run_stage·도주·파트너 비표시 등)이면 대화를 차단한다.
## Why: 도주/비표시 스테이지에서 shift로 대화가 걸려 게임오버되던 버그(리포트 #3/#4) 방지.
## [EN] Determines whether the near NPC can actually be talked to.[br]
## Blocks dialogue when the CurrentNpc (parent node) is hidden (run_stage, escape, invisible partner, etc.).
func can_talk_to_npc(npc: Node) -> bool:
	return npc.get_parent().visible

## [KR] [param npc]와의 대화를 [code]GameEvents[/code]를 통해 시작한다.
## [EN] Starts a conversation with [param npc] through [code]GameEvents[/code].
func npc_talk(npc : Npc):
	GameEvents.emit_player_talk(npc)
## [KR] [param event] 이벤트 영역과의 상호작용을 [code]GameEvents[/code]를 통해 시작한다.
## [EN] Starts interaction with [param event] event area through [code]GameEvents[/code].
func event_talk(event : EventArea):
	GameEvents.emit_player_event(event)

## [KR] 탐지 액션의 잠금 상태를 설정한다. [param lock]이 [code]true[/code]이면 탐지 불가.
## [EN] Sets the lock state for the detection action. Detection is disabled when [param lock] is [code]true[/code].
func set_find_lock(lock : bool):
	find_lock = lock

func _on_dialog_started():
	#_stop_charging()
	pass

func _stop_charging():
	is_charging = false
	charging_percentage = 0.0
	find_progress.visible = false
	find_effect.visible = false
	_stop_charging_vibration()

## [KR] 액션 키를 누른 패드를 진동 대상으로 기록한다.[br]
## 키보드 입력은 [InputEventJoypadButton]이 아니므로 기록되지 않아 진동도 발생하지 않는다.
## Why: 패드 2개 연결 시 미사용 패드(device 0)를 울리던 문제를, 실제로 누른 패드만 진동시켜 해결.
func _input(event):
	if event is InputEventJoypadButton and event.is_action_pressed("action"):
		_charging_pad_device = event.device

## [KR] 차징을 시작한 패드만 진동시킨다. 해당 패드가 연결돼 있지 않으면 아무것도 하지 않는다.
func _vibrate_charging(weak: float, strong: float, duration: float):
	if _charging_pad_device in Input.get_connected_joypads():
		Input.start_joy_vibration(_charging_pad_device, weak, strong, duration)

## [KR] 차징 패드의 진동을 멈춘다.
func _stop_charging_vibration():
	if _charging_pad_device in Input.get_connected_joypads():
		Input.stop_joy_vibration(_charging_pad_device)

## [KR] 강제 피격(rape) 연출 진입 헬퍼.[br]
## 게임 상태를 [code]STATE_RAPE[/code]로 전환하고, 화면 트랜지션 완료 후
## [param anim_string]에 해당하는 애니메이션을 재생한다.
## [EN] Helper for entering forced attack (rape) scene.[br]
## Transitions game state to [code]STATE_RAPE[/code], and after screen transition completes,
## plays the animation corresponding to [param anim_string].
func rape(anim_string : String):
	GameEvents.game_state_change(Constants.STATE_RAPE)
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finishied
	animation_player.play(anim_string)
	# [KR] 귀신 신음 루프 시작(보이스가 정의된 귀신만). H신 종료 시 enable()에서 정지.
	ghost_moan_stream.start_moan(anim_string)
	# [KR] 저항 게이지 시작: 0부터 차오르고 action 키로 참다가, 가득 차면 사정으로 넘어간다.
	_rape_anim = anim_string
	_rape_cumming = false
	_rape_fill_rate = rape_gauge_fill
	rape_gauge.step = 0.01 # step이 1.0이면 프레임당 작은 증가분이 반올림돼 사라져, 게이지가 한참 0이다 급등한다 → 작은 step으로 연속 증가
	rape_gauge.value = 0.0
	# [KR] 게이지는 RapeGaugeLayer(Visual 바깥)로 분리돼 좌우반전 영향을 안 받는다.
	#      CumSprite는 사정 아트라 저항 중엔 보이면 안 되므로 켜되 투명 처리한다.
	cum_sprite.show()
	cum_sprite.self_modulate = Color(1, 1, 1, 0)
	rape_gauge_base.show()
	keyboard_icon.show()
	cum_delay_label.text = tr(RAPE_RESIST_GUIDE_KEY)
	cum_delay_label.show()

## [KR] 강간 중 매 프레임: 게이지를 채우고(점점 가속) action 키로 감소시킨다. 가득 차면 사정.
func _update_rape_gauge(delta: float) -> void:
	_rape_fill_rate += rape_gauge_fill_accel * delta
	rape_gauge.value += _rape_fill_rate * delta
	if Input.is_action_just_pressed("action"):
		rape_gauge.value = maxf(0.0, rape_gauge.value - rape_gauge_drain)
	if rape_gauge.value >= rape_gauge.max_value:
		_start_cum()

## [KR] 사정 전환: cum 애니가 있으면 강간 아트를 숨기고 사정 애니 재생, 없으면 기존처럼 바로 복귀.
func _start_cum() -> void:
	_rape_cumming = true
	rape_gauge_base.hide()
	keyboard_icon.hide()
	cum_delay_label.hide()
	cum_sprite.self_modulate = Color.WHITE # 사정 아트 표시 복원
	if cum_anim.has_animation(_rape_anim):
		# [KR] 강간 애니가 루프 중이면 매 루프 :visible=true 트랙이 sprite를 다시 켜므로(Aseprite 임포트 특성),
		#      먼저 애니를 정지한 뒤 숨겨야 숨김이 유지된다.
		animation_player.stop()
		rape_sprite.hide()
		cum_anim.play(_rape_anim)
		cum_anim.advance(0.0) # 첫 프레임 즉시 적용 → 사정 전환 시 1프레임 위치 어긋남 방지
		# [KR] 사정 효과음은 cum 애니의 메서드 트랙(발사 프레임)에서 cum_sfx_player.play_h_sfx_cum()으로 재생한다.
		#      그 순간 h_sfx_played(CUM) 신호 → _play_cum_ef()로 깜박임이 동기 발동된다.
	else:
		find_faild.emit() # 폴백: 사정 에셋이 없는 귀신은 기존처럼 바로 시작 지점 복귀

## [KR] 사정 애니 종료 → 잠시 대기 후 자동으로 시작 지점 귀환.
func _on_cum_anim_finished(_anim_name: String) -> void:
	ghost_moan_stream.stop_moan() # 신음 루프 정지
	await get_tree().create_timer(rape_return_delay).timeout
	find_faild.emit()

## [KR] 사정 시 화면을 한 번 깜박인다(빠르게 밝아졌다 천천히 사라짐) — free action(omt_component)과 동일.
func _play_cum_ef() -> void:
	if _cum_ef_tween and _cum_ef_tween.is_running():
		return
	cum_effect.modulate.a = 0.0
	cum_canvas.show()
	cum_effect.show()
	_cum_ef_tween = create_tween()
	_cum_ef_tween.tween_property(cum_effect, "modulate:a", 1.0, 0.1)
	_cum_ef_tween.tween_property(cum_effect, "modulate:a", 0.0, 1.2)
	_cum_ef_tween.tween_callback(_hide_cum_ef)

func _hide_cum_ef() -> void:
	cum_effect.hide()
	cum_canvas.hide()

## [KR] cum 효과음이 재생되는 순간(h_sfx_played) 깜박임을 동기 발동 — free action과 동일한 결.
func _on_cum_sfx_played(type: int) -> void:
	if type == HSfxStream.HSceneTypes.CUM or type == HSfxStream.HSceneTypes.ORGASM:
		_play_cum_ef()


## [KR] [param percentage]만큼 이동 속도를 비율로 변경한다.[br]
## 예: [code]10.0[/code]이면 기존 속도의 10%를 새 속도로 설정.
## [EN] Changes movement speed by [param percentage] ratio.[br]
## Example: [code]10.0[/code] sets the new speed to 10% of the current speed.
func set_speed_percentage(percentage: float):
	# [KR] percentage는 퍼센트 값 (예: 10.0 -> 10% 증가, -10.0 -> 10% 감소)
	# [EN] percentage is a percent value (e.g. 10.0 -> 10% increase, -10.0 -> 10% decrease)
	var speed_offset = velocity_component.max_speed * (percentage / 100.0)
	velocity_component.max_speed = speed_offset
## [KR] [param value]로 이동 가속도를 직접 설정한다.
## [EN] Directly sets movement acceleration to [param value].
func set_speed_acceleration(value: float):
	velocity_component.acceleration = value


## [KR] 이동 속도 업그레이드 식별자.
## [EN] Movement speed upgrade identifier.
const SPEED_UP_ID = "speed_up"
## [KR] 탐지 영역 확대 업그레이드 식별자.
## [EN] Detection area expansion upgrade identifier.
const DETECT_AREA_UP_ID = "detect_area_up"

## [KR] 장비 목록이 변경되었을 때 [member upgrade_component]에 업그레이드를 적용한다.
## [EN] Applies upgrades to [member upgrade_component] when the equipment list changes.
func on_ability_upgrade_added(equipment_list: Array[AbilityUpgrade]):
	upgrade_component.apply_upgrade(equipment_list)

## [KR] 전역 위치 동기화 콜백. [param npc_type]이 [code]Constants.PC_PLAYER[/code]일 때만
## [param _x], [param _y] 좌표로 플레이어 위치를 강제 이동한다.[br]
## 컷씬·이벤트에서 플레이어 좌표를 직접 지정할 때 사용.
## [EN] Global position sync callback. Only when [param npc_type] is [code]Constants.PC_PLAYER[/code],
## forcefully moves the player to [param _x], [param _y] coordinates.[br]
## Used when directly specifying player coordinates in cutscenes/events.
func on_position_change(npc_type: int, _x:int, _y:int):
	if npc_type != Constants.PC_PLAYER:
		return
	if _x != 0:
		position.x = _x
	if _y != 0:
		position.y = _y
## [KR] 전역 방향 전환 콜백. [param direction]에 따라 스프라이트 좌우 반전을 적용한다.
## [EN] Global direction change callback. Applies horizontal sprite flipping based on [param direction].
func on_direction_change(direction : String):
	if direction == "left":
		visual.scale = Vector2(-1, 1)
	elif direction == "right":
		visual.scale = Vector2(1, 1)
		

## [KR] 액션 결과를 반환한다. 현재 미구현.
## [EN] Returns the action result. Currently unimplemented.
func get_action():
	pass
## [KR] [param _dir] 방향으로 플레이어를 회전한다. 현재 미구현.
## [EN] Rotates the player in the [param _dir] direction. Currently unimplemented.
func orient(_dir:Vector2) -> void:
	pass
## [KR] 플레이어를 비활성화한다.[br]
## 입력을 차단하고 [code]idle[/code] 애니메이션으로 전환하며,
## 게임 상태를 [code]STATE_EVENT[/code]로 변경한다.
## [EN] Deactivates the player.[br]
## Blocks input, switches to [code]idle[/code] animation,
## and changes game state to [code]STATE_EVENT[/code].
func disable():
	input_enabled = false
	animation_player.play("idle")
	GameEvents.game_state_change(Constants.STATE_EVENT)
## [KR] [method disable]과 쌍을 이루는 재활성화 함수.[br]
## 입력 복원, 가시성 복원, [signal player_enable] 발행,
## 게임 상태를 [code]STATE_NORMAL[/code]로 복원한다.
## [EN] Re-activation function that pairs with [method disable].[br]
## Restores input, restores visibility, emits [signal player_enable],
## and restores game state to [code]STATE_NORMAL[/code].
func enable():
	input_enabled = true
	visible = true
	player_enable.emit()
	GameEvents.game_state_change(Constants.STATE_NORMAL)
	# [KR] H신 종료 → 귀신 신음 루프 정지.
	ghost_moan_stream.stop_moan()

## [KR] 탐지 실패 시 게임 상태를 [code]STATE_RAPE_FAILED[/code]로 전환하는 콜백.
## [EN] Callback that transitions game state to [code]STATE_RAPE_FAILED[/code] on detection failure.
func on_find_faild():
	GameEvents.game_state_change(Constants.STATE_RAPE_FAILED)

## [KR] [code]Dialogic[/code] 시그널 이벤트 콜백.[br]
## [param event_name]이 [code]"move_back"[/code]이면 플레이어를 x=1600 위치로 이동시킨다.
## [EN] [code]Dialogic[/code] signal event callback.[br]
## Moves the player to x=1600 position when [param event_name] is [code]"move_back"[/code].
func _on_signal_event(event_name: String):
	if event_name == "move_back":
		global_position.x = 1600.0
	elif event_name == "tuto_move_back":
		position.x += -100.0

## [KR] [param state]에 따라 플레이어의 가시성을 설정하는 콜백.
## [EN] Callback that sets player visibility based on [param state].
func on_visible(state: bool):
	visible = state

## [KR] 가시성이 실제로 변경되었을 때만 디버그 로그를 출력한다.[br]
## [member before_visible]과 비교하여 [code]false → true[/code] 전환 시에만 로그.
## [EN] Outputs debug log only when visibility actually changes.[br]
## Logs only on [code]false → true[/code] transition by comparing with [member before_visible].
func _on_visible_changed():
	if visible == true and before_visible == false:
		print("visible")
