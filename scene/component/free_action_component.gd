## [KR] H씬 자유 행위(Free Action) 컴포넌트.
## [br]게이지 기반 인터랙션으로 H씬을 진행하며,
## 게이지 증감·애니메이션 속도 연동·사정 처리·정념 스택 교환 등
## H씬 인터랙션의 핵심 로직을 담당한다.
## [EN] H-scene Free Action component.
## [br]Drives H-scene interactions through gauge-based input,
## handling gauge increase/decrease, animation speed sync, climax processing,
## and erotic-stack exchange as the core interaction logic.
extends Node
class_name HSceneFreeActionComponent

## [KR] 행위 상태가 변경될 때 발생. [param state]는 진행 단계, [param scene_name]은 씬 이름, [param climax]는 절정 여부.
## [EN] Emitted when action state changes. [param state] is the progress stage, [param scene_name] is the scene name, [param climax] indicates climax status.
signal action_state_change(state: int, scene_name: String, climax: bool)
## [KR] 애니메이션 정보가 변경될 때 발생. [param current_npc]는 NPC 타입, [param current_anim]은 애니메이션 플레이어.
## [EN] Emitted when animation info changes. [param current_npc] is the NPC type, [param current_anim] is the animation player.
signal anim_info_changed(current_npc:int, current_anim:AnimationPlayer, scene_name: String)
## [KR] 사정 시 발생하는 시그널.
## [EN] Signal emitted on climax.
signal cumming() # [KR] 사정시 신호 발생 / [EN] Signal emitted on climax
## [KR] 자유 행위가 종료될 때 발생하는 시그널.
## [EN] Signal emitted when free action ends.
signal free_action_end
## [KR] 풀스프라이트 준비 완료 시 발생하는 시그널.
## [EN] Signal emitted when full sprite is ready.
signal full_sprite_ready

## [KR] 이 컴포넌트가 속한 NPC 참조.
## [EN] Reference to the NPC this component belongs to.
@export var npc : Npc
## [KR] NPC의 기본(비-H씬) 애니메이션 플레이어.
## [EN] NPC's default (non-H-scene) animation player.
@export var normal_anim : AnimationPlayer
## [KR] NPC의 기본 스프라이트.
## [EN] NPC's default sprite.
@export var normal_sprite : Sprite2D
## [KR] 자유 행위 시 티켓 배수 보너스를 관리하는 컴포넌트.
## [EN] Component managing ticket multiplier bonus during free action.
@export var free_action_ticket_multiplier : FreeTicketMultiplier

## [KR] H씬 리소스 데이터를 관리하는 인스턴스.
## [EN] Instance managing H-scene resource data.
var h_scene_data : HSceneData = HSceneData.new()
## [KR] 풀스프라이트 모드에서 사용되는 [PackedScene].
## [EN] [PackedScene] used in full sprite mode.
var anim_full_sprite : PackedScene
## [KR] 현재 재생 중인 [AnimationPlayer]. H씬 또는 기본 애니메이션을 가리킨다.
## [EN] Currently playing [AnimationPlayer]. Points to H-scene or default animation.
var current_anim : AnimationPlayer
## [KR] 현재 활성화된 [HScene] 인스턴스.
## [EN] Currently active [HScene] instance.
var current_h_scene: HScene

## [KR] 이벤트가 활성화되지 않은 상태를 나타내는 상수.
## [EN] Constant representing inactive event state.
const NONE_EVENT: = -1
## cum 음성이 없을 때 사정 애니메이션 전환 전 대기 시간(초).
const CUM_DELAY_FALLBACK := 1.5
## cum 음성 재생 중 사정 애니메이션을 시작할 비율 (0.6 = 60% 지점).
const CUM_VOICE_RATIO := 0.5
## [KR] 현재 재생 중인 H 이벤트 번호. [member NONE_EVENT]이면 비활성 상태.
## [EN] Currently playing H event number. Inactive when [member NONE_EVENT].
var current_event : int = NONE_EVENT
## [KR] 씬 진행 상태: 0=null, 1=대기(stay), 2=행위(play), 3=사정(finish), 4=종료(end).
## [EN] Scene progress state: 0=null, 1=stay, 2=play, 3=finish, 4=end.
@export_enum("null(0)", "stay(1)", "play(2)", "finish(3)", "end(4)") var scene_progress

## [KR] 행위 진행도 바의 베이스 스프라이트.
## [EN] Base sprite of the action progress bar.
@onready var action_progress_base: Sprite2D = %ActionProgressBase
## [KR] 행위 진행도 바(게이지 UI).
## [EN] Action progress bar (gauge UI).
@onready var action_progress_bar = %ActionProgressBar
## [KR] H씬 UI를 표시하는 [CanvasLayer].
## [EN] [CanvasLayer] displaying H-scene UI.
@onready var canvas_layer = $CanvasLayer
## [KR] 행위 진행도 바의 애니메이션 플레이어(스트로크 효과 등).
## [EN] Animation player for the action progress bar (stroke effect, etc.).
@onready var action_progress_anim: AnimationPlayer = %ActionProgressAnim

## [KR] 파트너(히로인) 정보를 관리하는 매니저 참조.
## [EN] Reference to the partner (heroine) manager.
var partner_manager : PartnerManager

## [KR] H 이벤트 활성화 여부. [code]true[/code]이면 입력 처리 및 게이지 업데이트가 동작한다.
## [EN] Whether H event is active. When [code]true[/code], input handling and gauge updates are active.
var is_event := false
## [KR] H씬 비주얼이 표시 중인지 여부.
## [EN] Whether H-scene visuals are currently displayed.
var is_h_scene_visible := false
## [KR] 풀스프라이트 모드 활성화 여부.
## [EN] Whether full sprite mode is active.
var is_full_mode := false

## [KR] 현재 사정 게이지 값 (0.0 ~ [member max_gage]).
## [EN] Current climax gauge value (0.0 ~ [member max_gage]).
var current_gage := 0.0
## [KR] 게이지가 증가 중인지 여부.
## [EN] Whether the gauge is currently increasing.
var is_increasing := false
## [KR] 게이지 변동이 일시정지된 상태인지 여부.
## [EN] Whether gauge changes are paused.
var is_paused := false
var is_input_locked := false  # [KR] 입력 잠금 상태 변수 추가 / [EN] Input lock state variable
## [KR] 화면 팬(오프셋 이동) 모드 활성화 여부. ZoomInComponent가 토글하며,
## [code]true[/code]이면 move_up/move_down을 팬이 가져가므로 속도/일시정지 입력을 무시한다.
## [EN] Whether screen pan (offset move) mode is active. Toggled by ZoomInComponent.
## When [code]true[/code], move_up/move_down are used for panning, so speed/pause input is ignored.
var is_pan_mode := false
## [KR] 사정이 발생했는지 여부.
## [EN] Whether climax has occurred.
var is_cum := false
var _waiting_cum := false
var _cum_timer: Timer
## [KR] 절정 상태(게이지가 [member CLIMAX_GAUGE] 이상)인지 여부.
## [EN] Whether in climax state (gauge >= [member CLIMAX_GAUGE]).
var is_climax := false
## [KR] 절정 상태 진입 기준 게이지 값.
## [EN] Gauge threshold for entering climax state.
const CLIMAX_GAUGE := 100

## [KR] 정념 교환에 사용된 누적 정념 스택 값.
## [EN] Accumulated erotic stack value used for desire exchange.
var current_ero_stack := 0.0 # [KR] 쌓인 정념이 얼마나 환산되었는지 저장하는 변수 / [EN] Stores how much accumulated desire has been converted
## [KR] 현재 적용 중인 티켓 배수 보너스 값.
## [EN] Current ticket multiplier bonus value.
var current_ticket_multiplier: int = 0 # [KR] 티켓 보너스 / [EN] Ticket bonus
## [KR] 보너스 티켓 드롭 간격 제어용 타이머 누적값.
## [EN] Timer accumulator for controlling bonus ticket drop intervals.
var bonus_ticekt_timer := 0.0

## [KR] 사정 게이지의 최대값.
## [EN] Maximum value of the climax gauge.
var max_gage := 100.0
## [KR] 게이지 감소 속도 (프레임당).
## [EN] Gauge decrease speed (per frame).
@export_range(1.0, 10.0) var decrease_speed := 5.0  # [KR] 게이지 감소 속도 / [EN] Gauge decrease speed
## [KR] 사정 후 게이지 감소 속도. 일반 감소보다 빠르게 설정하여 쿨다운 체감을 준다.
## [EN] Post-climax gauge decrease speed. Set faster than normal to create cooldown feel.
@export_range(1.0, 40.0) var cum_decrease_speed := 7.0  # [KR] 누적 게이지 감소 속도 / [EN] Cumulative gauge decrease speed
## [KR] 게이지 증가 속도 (프레임당).
## [EN] Gauge increase speed (per frame).
@export_range(1.0, 20.0) var increase_speed := 3.0  # [KR] 게이지 증가 속도 / [EN] Gauge increase speed
## [KR] [member increase_speed]의 원본 값. 속도 토글 복원 시 사용.
## [EN] Original value of [member increase_speed]. Used for speed toggle restoration.
var original_increase_speed := increase_speed  # [KR] 원래 증가 속도를 저장 / [EN] Stores the original increase speed

## [KR] 애니메이션 재생 속도의 최솟값 (게이지 0일 때).
## [EN] Minimum animation playback speed (when gauge is 0).
var min_speed := 0.6
## [KR] 애니메이션 재생 속도의 최댓값 (게이지 최대일 때).
## [EN] Maximum animation playback speed (when gauge is max).
var max_speed := 2.7
## [KR] 속도 토글 상태. [code]true[/code]이면 3배속 모드.
## [EN] Speed toggle state. [code]true[/code] means 3x speed mode.
var is_speed_doubled := false  # [KR] 속도가 두 배인지 여부를 확인하는 변수 / [EN] Variable to check if speed is doubled

## [KR] free action 카메라 줌 최소 배율(1.0=기본, 낮출수록 축소).
@export var zoom_min := 1.0
## [KR] free action 카메라 줌 최대 배율(클수록 확대).
@export var zoom_max := 2.5
## [KR] 줌 변화 속도(초당 배율 변화량).
@export var zoom_speed := 2.0

#only debug
@onready var test_cam = $"../TestCam"


## [KR] 초기화: 시그널 연결, 캔버스 숨김, 게이지 리셋, 디버그 모드 설정.
## [EN] Initialization: signal connections, canvas hiding, gauge reset, debug mode setup.
func _ready():
	canvas_layer.visible = false
	if npc != null and npc.data_only:
		return
	partner_manager = get_tree().get_first_node_in_group("partnermanager")
	GameEvents.on_npc_h_event.connect(_on_npc_h_event)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	current_anim = normal_anim
	reset_gage()
	_cum_timer = Timer.new()
	_cum_timer.one_shot = true
	_cum_timer.timeout.connect(_on_cum_timer_timeout)
	add_child(_cum_timer)
	
	#test
	if Constants.FREE_ACTION_TEST:
		push_warning("debug 중입니다")
		event_on(npc.npc_name, current_event)
		test_cam.enabled = true
	else : 
		test_cam.enabled = false		

## [KR] 매 프레임 게이지 업데이트, 애니메이션 속도 동기화, 입력 처리를 수행한다.
## [br]H 이벤트가 비활성 상태이면 즉시 반환한다.
## [EN] Performs gauge update, animation speed sync, and input handling each frame.
## [br]Returns immediately if H event is inactive.
func _process(delta):
	if is_event:
		get_viewport().set_input_as_handled()
	else:
		return

	# [KR] 게이지 업데이트
	# [EN] Gauge update
	update_gage(delta)

	# [KR] 애니메이션 속도 업데이트
	# [EN] Animation speed update
	update_animation_speed(delta)

	
	# [KR] 입력 처리 (action)
	# [EN] Input handling (action)
	# [KR] 팬 모드일 때는 move_up/move_down을 화면 이동이 가져가므로 속도/일시정지 입력을 무시한다.
	# [EN] In pan mode, move_up/move_down drive panning, so ignore speed/pause input.
	if not is_input_locked and not is_pan_mode:
		if Input.is_action_just_pressed("move_down"):
			handle_action_input()
		# [KR] move_right 입력 처리 (언제든지 입력 가능하게 설정)
		# [EN] move_right input handling (set to accept input anytime)
		if Input.is_action_just_pressed("move_up"):
			_spd_up()

	# [KR] free action 전용 카메라 줌 (scroll_up=확대 / scroll_down=축소)
	# [EN] Free-action-only camera zoom
	_update_zoom(delta)

## [KR] 속도 토글 후 게이지 증가를 시작한다. move_up 입력에 대응.
## [EN] Toggles speed and starts gauge increase. Responds to move_up input.
func _spd_up(fast: bool = false, slow: bool = false):
	toggle_speed(fast, slow)
	is_increasing = true
	is_paused = false

## [KR] free action 중 scroll 입력으로 npc 카메라를 캐릭터 기준 줌인/아웃한다.
## [br]오직 free action(_process는 is_event일 때만 동작)에서만 적용되며,
## 종료 시 [method _reset_zoom]로 기본 배율(1.0)로 복원된다.
## [EN] Zooms the npc camera (centered on character) via scroll input during free action.
## [br]Applied only in free action; restored to default via [method _reset_zoom] on exit.
func _update_zoom(delta):
	if not npc or not npc.npc_camera:
		return
	var dir := Input.get_action_strength("scroll_up") - Input.get_action_strength("scroll_down")
	if is_zero_approx(dir):
		return
	var cam := npc.npc_camera
	var next_zoom: float = clampf(cam.zoom.x + dir * zoom_speed * delta, zoom_min, zoom_max)
	cam.zoom = Vector2(next_zoom, next_zoom)

## [KR] npc 카메라 줌을 기본 배율(1.0)로 되돌린다. free action 종료 시 호출하여 다른 상태에 영향이 남지 않게 한다.
## [EN] Restores the npc camera zoom to default (1.0). Called on free action exit so no zoom leaks to other states.
func _reset_zoom():
	if npc and npc.npc_camera:
		npc.npc_camera.zoom = Vector2.ONE
		# [KR] ZoomInComponent가 화면 팬으로 바꾼 Camera2D.offset도 함께 원복(공유 카메라라 다른 상태로 새는 것 방지)
		# [EN] Also reset the Camera2D.offset that ZoomInComponent changed for panning (shared camera, prevents leaking to other states)
		var host = npc.npc_camera.get_pcam_host_owner()
		if host and host.camera_2d:
			host.camera_2d.offset = Vector2.ZERO

## [KR] ESC 입력 시 H 이벤트를 종료하는 글로벌 입력 핸들러.
## [br]이벤트 비활성 상태이거나 입력 잠금 / 화면 전환 중에는 무시한다.
## [EN] Global input handler that exits H event on ESC press.
## [br]Ignored when event is inactive, input is locked, or screen is transitioning.
func _input(event: InputEvent) -> void:
	#_find_click_node(event)
	
	if not is_event:
		return
	if not is_input_locked and not TransitionScreen.get_is_transition():
		if event.is_action_pressed("esc"):
			event_exit()
			get_viewport().set_input_as_handled()
	

## [KR] 사정 게이지 및 관련 상태 플래그를 초기화한다.
## [br]이벤트가 활성 상태이고 씬만 교체하는 경우, 정념 스택은 유지된다.
## [EN] Resets climax gauge and related state flags.
## [br]If the event is active and only the scene is being swapped, the erotic stack is preserved.
func reset_gage():
	if not is_event: ## [KR] 만약 이벤트가 켜져 있고 씬만 바꾸는 경우면 쌓인 정념 스택을 초기화하지 않음 / [EN] If event is on and only the scene changes, accumulated erotic stack is not reset
		current_gage = 0.0
		current_ero_stack = 0.0
	action_progress_bar.value = current_gage
	is_increasing = false
	is_paused = false
	is_input_locked = false  # [KR] 입력을 초기화할 때 잠금 해제 / [EN] Unlock input when resetting
	is_speed_doubled = false  # [KR] 속도 두 배 상태를 초기화 / [EN] Reset double speed state
	increase_speed = original_increase_speed  # [KR] 속도를 원래 값으로 초기화 / [EN] Reset speed to original value


## [KR] 매 프레임 게이지 상태를 갱신한다.
## [br]절정 상태 전환 판정 후, 증가/감소 로직을 분기 호출한다.
## [EN] Updates gauge state each frame.
## [br]After evaluating climax state transition, branches to increase/decrease logic.
func update_gage(delta):
	if current_gage < CLIMAX_GAUGE and is_climax:
			is_climax = false
			action_state_change.emit(2, "scene" + str(current_event), false)
			
	if is_increasing and not is_paused:
		increase_gage(delta)
	elif not is_increasing and not is_paused:
		decrease_gage(delta)

## [KR] 사정 게이지를 [member increase_speed]만큼 증가시킨다.
## [br]게이지가 [member CLIMAX_GAUGE]를 넘으면 절정 상태로 전환되고,
## [member max_gage]에 도달하면 [method shoot]을 호출하여 사정을 처리한다.
## [EN] Increases the climax gauge by [member increase_speed].
## [br]Transitions to climax state when gauge exceeds [member CLIMAX_GAUGE],
## and calls [method shoot] to process climax when [member max_gage] is reached.
func increase_gage(delta):
	if current_gage < max_gage: # [KR] 사정 게이지 올라감 / [EN] Climax gauge increasing
		is_cum = false
		
		# [KR] 게이지 상승
		# [EN] Gauge increase
		current_gage += increase_speed * delta
		current_gage = clamp(current_gage, 0, max_gage)
		action_progress_bar.value = current_gage
		
		
		
		if current_gage >= CLIMAX_GAUGE and not is_climax:
			is_climax = true
			action_state_change.emit(3, "scene" + str(current_event), true)
		
			
		if scene_progress != 2:
			event_change(current_event, 2)
	elif current_gage >= max_gage:
		# climax_voice_delay 신호가 오지 않은 경우(cum 대사 없음) 폴백 처리
		if not _waiting_cum:
			_on_climax_voice_delay(0.0)

## [KR] 사정 게이지를 감소시킨다.
## [br]입력 잠금 상태(사정 후)에서는 [member cum_decrease_speed]로 빠르게 감소하며,
## 게이지가 0에 도달하면 사정 여부에 따라 티켓 정산 또는 대기 상태로 전환한다.
## [EN] Decreases the climax gauge.
## [br]In input-locked state (post-climax), decreases faster at [member cum_decrease_speed].
## When gauge reaches 0, transitions to ticket settlement or standby based on climax status.
func decrease_gage(delta):
	if current_gage > 0:
		if is_input_locked:
			if is_instance_valid(current_anim):
				if current_anim.is_playing():
					current_gage -= cum_decrease_speed * delta
				else :
					current_gage -= (cum_decrease_speed*4) * delta
		else:
			current_gage -= decrease_speed * delta
		current_gage = clamp(current_gage, 0, max_gage)
		action_progress_bar.value = current_gage
	
	if current_gage <= 0 and not(scene_progress == 1 or scene_progress == 4):
		is_input_locked = false  # [KR] 게이지가 0이 되면 입력 잠금 해제 / [EN] Unlock input when gauge reaches 0
		if not is_cum:
			event_change(current_event, 1)
		else: ## [KR] 사정했을때 / [EN] When climax occurred
			if partner_manager:
				var current_base_h_mode = get_tree().get_first_node_in_group("h_scene_window_component")
				if current_base_h_mode: ## [KR] 시작 지점에서의 h일때만 티켓을 가공한다 / [EN] Only process tickets during H from the starting point
					
					# [KR] 모인 티켓 뿌리기
					# [EN] Drop accumulated tickets
					partner_manager.consume_ero_gage(npc.npc_name, int(current_ero_stack))
					free_action_ticket_multiplier.drop_stack_ticket()
					
					current_ero_stack = 0.0
					#print("ticket get")
			event_change(current_event, 4)
			cumming.emit()
		

## [KR] 정념 스택을 [param speed_factor]에 비례하여 증가시킨다.
## [br]파트너의 정념 게이지 상한까지만 적립되며,
## [member current_ticket_multiplier]가 있으면 0.7초 간격으로 보너스 티켓을 추가한다.
## [EN] Increases the erotic stack proportionally to [param speed_factor].
## [br]Accumulated up to the partner's erotic gauge limit.
## When [member current_ticket_multiplier] is active, adds bonus tickets at 0.7s intervals.
func increase_ero_stack(speed_factor:float, delta):
	current_ero_stack += ((Constants.ERO_GAUGE_STACK_BASE + add_stack_spd_for_item()) * speed_factor) * delta
	var current_partner_ero_gauge: float = partner_manager.get_partner_ero_gauge(npc.npc_name)
	current_ero_stack = min(current_ero_stack, current_partner_ero_gauge)
	partner_manager.ero_stack_update.emit(npc.npc_name, current_ero_stack)
	
	# [KR] --- 간격 제어 ---
	# [EN] --- Interval control ---
	if current_ticket_multiplier > 0 and current_ero_stack < current_partner_ero_gauge:
		bonus_ticekt_timer += delta
		if bonus_ticekt_timer >= 0.7:
			free_action_ticket_multiplier.add_stack_ticket(current_ticket_multiplier)
			bonus_ticekt_timer = 0.0

## [KR] 장비 [code]ero_gauge_comsume_up[/code] 보유 시 추가 정념 스택 속도를 반환한다.
## [EN] Returns additional erotic stack speed when equipment [code]ero_gauge_comsume_up[/code] is owned.
func add_stack_spd_for_item()-> float:
	if MetaProgression.has_equipment("ero_gauge_comsume_up"):
		return Constants.ERO_GAUGE_ADD_STACK_SPD
	return 0.0

## [KR] 현재 게이지에 비례하여 애니메이션 재생 속도를 [method lerp]로 보간한다.
## [br]행위(play) 상태에서만 동작하며, 동시에 [method increase_ero_stack]을 호출한다.
## [EN] Interpolates animation playback speed proportionally to gauge using [method lerp].
## [br]Only operates in play state, simultaneously calling [method increase_ero_stack].
func update_animation_speed(delta):
	if not current_anim:
		return
	if current_gage >= 0 and scene_progress == 2:
		var speed_factor = lerp(min_speed, max_speed, current_gage / max_gage)
		current_anim.speed_scale = speed_factor
		if not action_progress_anim.is_playing():
			action_progress_anim.play("stroke")
		action_progress_anim.speed_scale = speed_factor*2
		increase_ero_stack(speed_factor, delta)
	else:
		current_anim.speed_scale = 1.0
		if action_progress_anim.is_playing():
			action_progress_anim.stop()

## [KR] move_down 입력에 따라 게이지 일시정지/재개를 토글한다.
## [br]속도 배율을 원래 값으로 복원한 뒤, 현재 상태에 따라 정지 또는 감소로 전환한다.
## [EN] Toggles gauge pause/resume on move_down input.
## [br]Restores speed multiplier to original value, then switches to stop or decrease based on current state.
func handle_action_input():
	increase_speed = original_increase_speed  # [KR] pausing 시 두 배 속도 상태를 원래대로 돌림 / [EN] Restore double speed state to original when pausing
	is_speed_doubled = false
	if is_paused:
		is_increasing = false
		is_paused = false
	elif not is_increasing:
		is_paused = true
	else:
		is_paused = true

## [KR] H 이벤트를 활성화하고 해당 씬을 로드한다.
## [br][param npc_type]은 NPC 식별자, [param _event]는 이벤트 번호(100 미만=일반, 100 이상=풀스프라이트),
## [param _event_count]는 씬 내 진행 단계이다.
## 기존 H씬이 있으면 해제 후 교체하고, 없으면 화면 전환 효과를 적용한다.
## [EN] Activates the H event and loads the corresponding scene.
## [br][param npc_type] is the NPC identifier, [param _event] is the event number (<100=normal, >=100=full sprite),
## [param _event_count] is the progress stage within the scene.
## Frees existing H-scene before replacing, or applies screen transition if none exists.
func event_on(npc_type: int, _event : int, _event_count := 1):
	if partner_manager:
		partner_manager.current_free_h_partner_update.emit(npc_type)
	is_cum = false
	
	if current_h_scene or anim_full_sprite: # [KR] 현재 실행중인 h씬이 있을 경우 / [EN] If an H-scene is currently running
		free_sprite()
		if is_instance_valid(current_h_scene):
			current_h_scene.queue_free() # [KR] 기존 h씬을 제거함 / [EN] Remove existing H-scene
	else: # [KR] 화면 전환 효과를 적용 / [EN] Apply screen transition effect
		TransitionScreen.transition()
		if Dialogic.current_timeline:
			Dialogic.paused = true
		if Dialogic.Text.is_textbox_visible():
			Dialogic.Text.hide_textbox()
		
		await TransitionScreen.on_transition_finishied
	
	npc.sub_anim_hide()
	npc.position_setting(_event)
	
	if _event < 100:
		var h_scene = h_scene_data.get_h_scene(npc_type, _event) as HScene
		h_scene.npc_type = npc.npc_name
		npc.add_child(h_scene)
		current_anim = h_scene.get_child(0) as AnimationPlayer
		current_h_scene = h_scene
		is_full_mode = false
		anim_info_changed.emit(npc_type, current_anim, "scene" + str(_event) + "_" + str(_event_count))
	elif _event > 100:
		init_full_sprite(npc_type, _event)
		#await full_sprite_ready
		print("emit anim = "+ str(current_anim.get_instance_id()))
		anim_info_changed.emit(npc_type, current_anim, "scene" + str(_event) + "_" + str(_event_count))
		scene_mode(true)
		
	GameEvents.game_state_change(Constants.STATE_EVENT)	
	normal_anim.stop()
	normal_sprite.hide()
	canvas_layer.visible = true
	is_h_scene_visible = true
	is_event = true
	GameEvents.set_window_state(Constants.WINDOW_STATE_H_ACTION, true)
	current_event = _event
	scene_progress = _event_count
	event_change(current_event, scene_progress)
	reset_gage()

## [KR] H 이벤트를 종료하고 원래 상태로 복귀한다.
## [br]사정 애니메이션(progress=3) 중에는 종료를 차단하며,
## 행위(progress=2) 중 종료 시 사정 애니메이션으로 강제 전환한다.
## [EN] Exits the H event and restores to original state.
## [br]Blocks exit during climax animation (progress=3).
## Forces transition to climax animation when exiting during play (progress=2).
func event_exit():
	## [KR] 대화 진행중이며, 액션 진행중일땐 나가지 못하게 처리
	## [EN] Prevent exiting while dialogue and action are in progress
	#if not (scene_progress == 1 or scene_progress == 4) and Dialogic.current_timeline:
		#return
	
	if scene_progress == 3:
		return
	
	canvas_layer.visible = false
	is_event = false
	_reset_zoom() # [KR] free action 종료 시 카메라 줌 원복(다른 상태에 영향 방지)
	GameEvents.set_window_state(Constants.WINDOW_STATE_H_ACTION, false)
	partner_manager.current_free_h_partner_update.emit(partner_manager.NpcType.NONE)
	
	# [KR] 현재 시작 지점에서 파트너의 엣치 이벤트를 통해 처리하고 있을때는 타임라인 상태를 변경하지 않는다.
	# [EN] Do not change timeline state when processing through partner's H event from the starting point.
	var current_base_h_mode = get_tree().get_first_node_in_group("h_scene_window_component")
	if current_base_h_mode:
		if not current_base_h_mode.current_base_h_mode_on:
			if Dialogic.current_timeline:
				Dialogic.paused = false
			if not Dialogic.Text.is_textbox_visible():
				Dialogic.Text.hide_textbox(false)
	else:
		if Dialogic.current_timeline:
			Dialogic.paused = false
		if not Dialogic.Text.is_textbox_visible():
			Dialogic.Text.hide_textbox(false)
	
	reset_gage()
	# [KR] 사정 없이 중단했으므로 누적된 Bonus 티켓 스택을 보상 없이 초기화한다.
	#      (사정 시에는 decrease_gage에서 drop_stack_ticket으로 정산되므로 여기서 건드리지 않음)
	# [EN] Aborted without climax, so reset the accumulated Bonus ticket stack without reward.
	#      (On climax it is settled via drop_stack_ticket in decrease_gage, so it's left untouched here.)
	if free_action_ticket_multiplier:
		free_action_ticket_multiplier.reset_stack_ticket()
	bonus_ticekt_timer = 0.0
	free_action_end.emit()
	partner_manager.free_action_end.emit()
	GameEvents.emit_h_event_end(npc.npc_name, self) # [KR] 회상방에서 이벤트 종료시 호출하는 시그널 / [EN] Signal called when event ends in the recollection room
	
	## [KR] 행위중일 때 esc를 눌러 종료하면 사정 애니로 바로 넘어가도록 처리, 대화 이벤트에서 사용
	## [EN] When ESC is pressed during action, transition directly to climax animation; used in dialogue events
	if scene_progress == 2:
		current_anim.speed_scale = 1.0
		event_change(current_event, 3)
	
	_cum_timer.stop()
	_waiting_cum = false
	current_event = NONE_EVENT # [KR] 현재 플레이중인 H 초기화 / [EN] Reset currently playing H event

## cum 음성의 재생 길이를 기반으로 대기 후 shoot(true)를 호출한다.
## h_talk_component의 climax_voice_delay 신호 또는 폴백으로 직접 호출된다.
func _on_climax_voice_delay(voice_duration: float) -> void:
	if _waiting_cum:
		return
	_waiting_cum = true
	is_climax = false
	is_input_locked = true
	is_increasing = false
	is_paused = true
	var delay := voice_duration * CUM_VOICE_RATIO if voice_duration > 0.0 else CUM_DELAY_FALLBACK
	_cum_timer.start(delay)


func _on_cum_timer_timeout() -> void:
	_waiting_cum = false
	is_paused = false
	shoot(true)


## [KR] 이벤트 진행 상태를 변경하고 대응하는 애니메이션을 재생한다.
## [br]사정(progress=3)이 아닌 경우 [signal action_state_change]를 발신하여 대사를 출력한다.
## [EN] Changes event progress state and plays the corresponding animation.
## [br]Emits [signal action_state_change] to display dialogue unless it's climax (progress=3).
func event_change(event : int, progress : int):
	print("anim name: %s"%str(event))
	scene_progress = progress
	var event_string := "scene" + str(event) + "_" + str(progress)
	current_anim.play(event_string)
	if progress != 3: # [KR] 사정 대사일 경우 제외하고 대사 출력 / [EN] Display dialogue except for climax lines
		action_state_change.emit(progress, "scene" + str(event), false)

## [KR] 사정을 실행한다. 사정 애니메이션으로 전환하고 [signal GameEvents.shot_semen]을 발신한다.
## [EN] Executes climax. Transitions to climax animation and emits [signal GameEvents.shot_semen].
func shoot(cum := false):
	if cum:
		event_change(current_event, 3)
		is_cum = true
		
		GameEvents.shot_semen.emit(npc.position, npc.npc_name, current_event)

## [KR] 게이지 증가 속도를 1배/3배로 토글한다.
## [EN] Toggles gauge increase speed between 1x and 3x.
func toggle_speed(fast: bool = false, slow: bool = false):
	if fast:
		increase_speed = original_increase_speed * 3
		is_speed_doubled = false
	elif slow:
		increase_speed = original_increase_speed
		is_speed_doubled = true
	elif not is_speed_doubled:
		increase_speed = original_increase_speed  # [KR] 원래 속도로 복원 / [EN] Restore to original speed
		is_speed_doubled = true
	else:
		increase_speed = original_increase_speed * 3  # [KR] 두 배로 증가 / [EN] Increase to triple
		is_speed_doubled = false

## [KR] Dialogic 시그널 이벤트 수신 콜백. 대화 중 H 이벤트 트리거에 사용된다.
## [EN] Dialogic signal event callback. Used to trigger H events during dialogue.
func _on_dialogic_signal(arg: String):
	on_npc_h_event(Dialogic.VAR.npc.get('type'), arg)
	if arg.begins_with("scene"):
		GameEvents.emit_dialogic_h_event_on() ## [KR] backlog버튼 감추기용 / [EN] For hiding the backlog button

## [KR] [signal GameEvents.on_npc_h_event] 수신 콜백. [method on_npc_h_event]로 위임한다.
## [EN] Callback for [signal GameEvents.on_npc_h_event]. Delegates to [method on_npc_h_event].
func _on_npc_h_event(npc_type: int, arg: String, ticket_multiplier: int = 0):
	on_npc_h_event(npc_type, arg, ticket_multiplier)

## [KR] NPC H 이벤트를 처리한다.
## [br][param arg]가 [code]scene[/code]으로 시작하면 해당 씬 번호를 파싱하여 [method event_on]을 호출한다.
## 동일 씬이 이미 재생 중이면 중복 호출을 무시한다.
## [EN] Processes NPC H events.
## [br]If [param arg] starts with [code]scene[/code], parses the scene number and calls [method event_on].
## Ignores duplicate calls if the same scene is already playing.
func on_npc_h_event(npc_type: int, arg: String, ticket_multiplier: int = 0):
	if npc.npc_name == npc_type:
		if arg.begins_with("scene"):
			var scene_number = int(arg.replace("scene", ""))
			
			## [KR] 현재 재생중 이벤트가 같을 경우 입력 무시
			## [EN] Ignore input if the currently playing event is the same
			if current_event == scene_number:
				return
			
			event_on(npc.npc_name, scene_number, 1)
			MetaProgression.add_npc_unlock_event(npc.npc_name, arg)
			current_ticket_multiplier = ticket_multiplier

## [KR] 씬 모드를 전환한다. [param _full]이 [code]true[/code]이면 풀스프라이트 모드, 아니면 기본 애니메이션으로 복원.
## [EN] Switches scene mode. Full sprite mode when [param _full] is [code]true[/code], otherwise restores default animation.
func scene_mode(_full := false):
	if _full == true:
		is_full_mode = true
	else:
		is_full_mode = false
		if current_anim == normal_anim:
			current_anim.stop()
		current_anim = normal_anim
		
## [KR] 풀스프라이트 H씬을 로드하여 [code]FullAnimComponent[/code]에 인스턴스화한다.
## [br]기존 자식 노드가 있으면 모두 해제한 뒤 새 씬을 추가한다.
## [EN] Loads the full sprite H-scene and instantiates it in [code]FullAnimComponent[/code].
## [br]Frees all existing child nodes before adding the new scene.
func init_full_sprite(npc_type: int, event_num : int):
	var full_scene_path = h_scene_data.get_h_full_scene_path(npc_type, event_num)
	anim_full_sprite = ResourceLoader.load(full_scene_path) as PackedScene
	var full_sprite_instance: NpcFullScene = anim_full_sprite.instantiate()
	var full_anim_component = npc.get_node("FullAnimComponent")
	
	var before_children: Array[Node] = full_anim_component.get_children()
	if before_children.size() > 0:
		for i in before_children:
			i.queue_free()
	
	if full_anim_component.get_child_count() > 0:
		full_anim_component.get_child(0).queue_free()
	full_anim_component.add_child(full_sprite_instance)
	
	current_anim = full_sprite_instance.current_anim
	print("new anim = "+ str(current_anim.get_instance_id()))
	_on_full_sprite_ready()

## [KR] 풀스프라이트 로드 완료 시 [signal full_sprite_ready]를 발신한다.
## [EN] Emits [signal full_sprite_ready] when full sprite loading is complete.
func _on_full_sprite_ready():
	print("sprite ready")
	full_sprite_ready.emit()

## [KR] [code]FullAnimComponent[/code]에서 현재 풀스프라이트 [NpcFullScene]을 반환한다. 없으면 [code]null[/code].
## [EN] Returns the current full sprite [NpcFullScene] from [code]FullAnimComponent[/code]. Returns [code]null[/code] if none exists.
func get_full_sprite() -> NpcFullScene:
	var full_anim_player = npc.get_node("FullAnimComponent")
	if full_anim_player.get_child_count() == 0:
		return null
	var full_sprite = full_anim_player.get_child(0) as NpcFullScene
	return full_sprite

## [KR] 현재 H씬에 사용된 노드(풀스프라이트 및 [HScene])를 [method Node.queue_free]로 해제한다.
## [EN] Frees nodes used in the current H-scene (full sprite and [HScene]) via [method Node.queue_free].
func free_sprite():
	var current_full_sprite = get_full_sprite() as NpcFullScene
	if current_full_sprite:
		current_full_sprite.queue_free()
		anim_full_sprite = null
	if is_instance_valid(current_anim):
		var current_scene = current_anim.get_parent() as HScene
		if current_scene:
			current_scene.queue_free()
		
	is_h_scene_visible = false

## [KR] Dialogic 타임라인 종료 콜백. H씬이 표시 중이면 스프라이트를 해제하고 일반 상태로 복귀한다.
## [EN] Dialogic timeline end callback. Frees sprites and restores normal state if H-scene is displayed.
func _on_timeline_ended():
	_reset_zoom() # [KR] 타임라인 종료 시에도 줌 원복(event_exit를 거치지 않는 경로 대비)
	if is_h_scene_visible and current_anim:
		free_sprite()
		GameEvents.game_state_change(Constants.STATE_NORMAL)


## [KR] 현재 H씬 애니메이션을 정지하고 숨긴다. 회상 모드 전환 등에서 사용.
## [EN] Stops and hides the current H-scene animation. Used for recollection mode transitions, etc.
func hide_current_scene():
	if is_instance_valid(current_anim):
		var current_scene = current_anim.get_parent()
		if current_scene is HScene or current_scene is NpcFullScene:
			current_anim.stop()
			current_scene.hide()



## [KR] 정지 버튼 콜백. [method handle_action_input]을 호출하여 일시정지를 토글한다.
## [EN] Stop button callback. Calls [method handle_action_input] to toggle pause.
func _on_stop_pressed() -> void:
	if is_input_locked:
		return
	handle_action_input()

## [KR] 재생 버튼 콜백. [method _spd_up]을 호출하여 게이지 증가를 시작한다.
## [EN] Play button callback. Calls [method _spd_up] to start gauge increase.
func _on_play_pressed() -> void:
	if is_input_locked:
		return
	_spd_up(false, true)

## [KR] 배속 버튼 콜백. [method _spd_up]을 호출하여 속도를 토글한다.
## [EN] Speed button callback. Calls [method _spd_up] to toggle speed.
func _on_double_pressed() -> void:
	if is_input_locked:
		return
	_spd_up(true)


## [KR] 정지 버튼 마우스 진입 콜백 (미구현).
## [EN] Stop button mouse enter callback (not implemented).
func _on_stop_mouse_entered() -> void:
	pass # Replace with function body.

## [KR] 디버그용: 마우스 클릭 위치의 최상단 UI 노드 정보를 콘솔에 출력한다.
## [EN] Debug: prints the topmost UI node info at the mouse click position to console.
func _find_click_node(event):
	# [KR] 마우스 왼쪽 클릭이 눌렸을 때
	# [EN] When left mouse button is clicked
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# [KR] 현재 마우스 위치에 있는 최상단 컨트롤 노드를 가져옴
		# [EN] Get the topmost control node at the current mouse position
		var blocker = get_viewport().gui_get_hovered_control()
		
		if blocker:
			print("--------------------------------------------------")
			print("Culprit node name: ", blocker.name)
			print("Culprit node path: ", blocker.get_path())
			print("Mouse filter setting: ", blocker.mouse_filter) # 0:Stop, 1:Pass, 2:Ignore
			print("--------------------------------------------------")
		else:
			print("No UI node detected under the mouse.")
