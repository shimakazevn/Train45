extends Node
class_name GlobalGameManager

## [KR] 글로벌 게임 상태 관리자.
## [EN] Global game state manager.
##
## [KR] 라이프, 코인, 일시정지, 대화 스킵 등 게임 전반의 상태를 관리한다.
## [EN] Manages overall game state including life, coins, pause, and dialogue skip.
## [KR] [GameEvents] 시그널을 수신하여 챕터 진행, 아이템 획득, 이벤트 기록을 처리하며,
## [EN] Receives [GameEvents] signals to handle chapter progression, item acquisition, and event recording,
## [KR] [signal life_changed]를 통해 UI에 라이프 변경을 알린다.
## [EN] and notifies the UI of life changes through [signal life_changed].

## [KR] 선택지 자동 스킵 활성화 여부
## [EN] Whether automatic choice skip is enabled
@export var choice_skip: bool = false

## [KR] 층 진행 관리자 참조
## [EN] Reference to the floor progression manager
@export var floor_manager : FloorManager
## [KR] 일시정지 메뉴 씬
## [EN] Pause menu scene
@export var pause_menu : PackedScene
## [KR] 메인 퀘스트 컴포넌트 참조
## [EN] Reference to the main quest component
@export var main_quest_component: MainQuestComponent
## [KR] 칸칸네비 아이콘 리소스
## [EN] KankanNavi icon resource
const ICONS_KANKAN = preload("res://resources/ui/icons/icons16.png")

## [KR] 라이프 값이 변경될 때 발생한다.
## [EN] Emitted when the life value changes.
signal life_changed

## [KR] 현재 씬 전환 중인지 여부
## [EN] Whether a scene transition is currently in progress
var is_transition := false
## [KR] 읽은 이벤트 이름 목록
## [EN] List of read event names
var read_event_list : Array[String]

## [KR] 게임 시작 시각 (밀리초)
## [EN] Game start time (milliseconds)
var game_start_time := 0
## [KR] 현재 시각 (밀리초, 매 프레임 갱신)
## [EN] Current time (milliseconds, updated every frame)
var game_current_time := 0
## [KR] 게임 클리어 횟수
## [EN] Game clear count
var game_clear_num := 0
## [KR] 라이프 기본값
## [EN] Life default value
var life_base = PlayerData.PLAYER_START_LIFE
## [KR] 현재 라이프
## [EN] Current life
var life = 0

## [KR] 선택지 블록 딜레이 기본값 (스킵 복원용)
## [EN] Choice block delay default value (for skip restoration)
var choice_block_delay_base : float
## [KR] 선택지 표시 딜레이 기본값 (스킵 복원용)
## [EN] Choice reveal delay default value (for skip restoration)
var choice_reveal_delay_base : float

## [KR] 오토 플레이(스킵 아님) 중 선택지가 떴을 때, 첫 선택지를 자동선택하기 전 최소 대기(초).
## 선택지를 읽을 시간을 확보한다. (중요 선택지는 자동선택하지 않음)
const AUTOPLAY_CHOICE_DELAY := 3.0

## [KR] 플레이어 데이터
## [EN] Player data
var player_data : PlayerData

## [KR] 게임 이벤트 시그널을 연결하고, 저장 데이터로부터 초기 상태를 복원한다.
## [EN] Connects game event signals and restores initial state from save data.
func _ready():
	
	GameEvents.game_complete.connect(_on_game_complete)
	GameEvents.set_chapter.connect(_on_chapter_change)
	GameEvents.add_read_history.connect(append_read_event_list)
	GameEvents.add_route_hint.connect(_on_add_route_hint)
	GameEvents.add_box_map.connect(_on_add_box_map)
	GameEvents.set_coin.connect(_on_set_coin)
	GameEvents.set_equip_cost.connect(_on_set_equip_cost)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	DialogicUtil.autoload().Choices.question_shown.connect(_on_question_shown)
	DialogicUtil.autoload().Choices.choice_selected.connect(_on_choice_selected)
	DialogicUtil.autoload().Inputs.auto_skip.toggled.connect(_on_skip_toggled)
	TransitionScreen.on_transition_start.connect(_on_transition_start)
	TransitionScreen.on_transition_all_end.connect(_on_transition_all_end)
	player_data = PlayerData.new()
	game_start_time = Time.get_ticks_msec()
	read_event_list.append_array(MetaProgression.get_read_event())
	game_clear_num = MetaProgression.get_game_clear_count()
	floor_manager.set_complete_stage_num(MetaProgression.get_current_chapter())
	life = life_base
	life_changed.emit()
	
	choice_block_delay_base = DialogicUtil.autoload().Choices.block_delay
	choice_reveal_delay_base = DialogicUtil.autoload().Choices.reveal_delay

## [KR] 매 프레임 시간을 갱신하고, Shift 키로 대화 자동 스킵을 토글한다.
## [EN] Updates time every frame and toggles dialogue auto-skip with Shift key.
func _process(_delta):
	game_current_time = Time.get_ticks_msec()
	
	if not GameEvents.get_window_state("safe_stage_h_action"):
		if Input.is_action_just_pressed("tr45_skip") and Dialogic.current_timeline and not is_transition:
			if not Dialogic.Inputs.auto_skip.enabled:
				Dialogic.Inputs.auto_skip.enabled = true
				_choice_auto_select()
			
		if Input.is_action_just_released("tr45_skip") and Dialogic.current_timeline:
			if Dialogic.Inputs.auto_skip.enabled:
				Dialogic.Inputs.auto_skip.enabled = false

## [KR] 씬 전환이 시작될 때 전환 플래그를 설정한다.
## [EN] Sets the transition flag when scene transition starts.
func _on_transition_start():
	#if Dialogic.Inputs.auto_skip.enabled:
		#Dialogic.Inputs.auto_skip.enabled = false
	is_transition = true

## [KR] 씬 전환이 완전히 종료되면 전환 플래그를 해제한다.
## [EN] Clears the transition flag when scene transition is fully complete.
func _on_transition_all_end():
	is_transition = false

## [KR] ESC 키 입력 시 일시정지 메뉴를 연다.
## [EN] Opens the pause menu on ESC key input.
## [KR] 대화 중이거나, 다른 창이 열려있거나, 에필로그 중에는 무시한다.
## [EN] Ignored during dialogue, when other windows are open, or during epilogue.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc") and !Dialogic.current_timeline:
		if GameEvents.get_window_state_array().size() > 0:
			print("Cannot be used because that window is currently open : " + str(GameEvents.get_window_state_array()))
			return
		#if GameEvents.get_current_stage_changing_screen():
			#print("맵 이동중에는 esc불가")
			#return
		if GameEvents.is_epilogue_room:
			print("ESC not allowed in the epilogue stage")
			return
		var pause_menu_instante = pause_menu.instantiate()
		add_child(pause_menu_instante)

## [KR] 라이프를 [param num]만큼 증감시키고 [signal life_changed]를 발생시킨다.
## [EN] Increases/decreases life by [param num] and emits [signal life_changed].
func set_life(num : int):
	life += num
	life_changed.emit()
	# [KR] 시작 지점 복귀 노이즈 SE는 '라이프 0' 여부가 아니라 '복귀 동작' 자체에 묶여 재생된다.
	#      (탐지실패·귀환버튼·H신 종료 등은 TeleportComponent._on_find_faild_teleport,
	#       문 미클리어 강제복귀는 FloorManager.into_next_door 에서 재생)

## [KR] 라이프를 기본값([member life_base])으로 초기화한다.
## [EN] Resets life to the default value ([member life_base]).
func init_base_life():
	life = life_base
	life_changed.emit()

## [KR] 기지(TYPE_BASE) 스테이지에서만 라이프를 기본값으로 리셋한다.
## [EN] Resets life to default only on base (TYPE_BASE) stage.
func set_base_life():
	if floor_manager.current_level.stage_type == Constants.TYPE_BASE: # [KR] 시작 지점에서만 세팅되게 / [EN] Only set at starting point
		life = life_base
		life_changed.emit()

## [KR] 라이프 증가 아이템 장착 시 [member life_base]를 2로 설정한다.
## [EN] Sets [member life_base] to 2 when a life-up item is equipped.
func set_life_up_item_equip():
	life_base = 2
	if floor_manager.current_level.stage_type == Constants.TYPE_BASE:
		set_base_life()

## [KR] 챕터 변경 시그널 핸들러. 현재 챕터보다 높은 경우에만 갱신한다.
## [EN] Chapter change signal handler. Only updates if higher than the current chapter.
func _on_chapter_change(chapter: int):
	if MetaProgression.get_current_chapter() >= chapter:
		return
	print("[GlobalGameManager] Chapter changed: %d -> %d" % [MetaProgression.get_current_chapter(), chapter])
	MetaProgression.set_current_chapter(chapter)

## [KR] 게임 완료 시그널 핸들러. 클리어 횟수를 1 증가시킨다.
## [EN] Game complete signal handler. Increments the clear count by 1.
func _on_game_complete():
	game_clear_num += 1
	

## [KR] 마지막 호출 이후 경과한 플레이 시간(초)을 반환한다.
## [EN] Returns the elapsed play time (seconds) since the last call.
## [KR] 호출 시 [member game_start_time]이 현재 시각으로 리셋된다.
## [EN] [member game_start_time] is reset to current time on call.
func get_play_time() -> int:
	var play_time = int((game_current_time - float(game_start_time)) / 1000)
	game_start_time = Time.get_ticks_msec()
	if play_time <= 0.0:
		return 0
	return play_time

## [KR] [param event_name] 이벤트를 읽음 목록에 추가하고 메타 프로그레션에 저장한다.
## [EN] Adds [param event_name] event to the read list and saves to meta-progression.
func append_read_event_list(event_name: String):
	MetaProgression.read_event_update(event_name)
	if !read_event_list.has(event_name):
		read_event_list.append(event_name)
	#print(read_event_list)

## [KR] [param event_name] 이벤트를 이미 읽었는지 여부를 반환한다.
## [EN] Returns whether [param event_name] event has already been read.
func get_read_event_list(event_name: String)-> bool:
	if read_event_list.has(event_name):
		return true
	else:
		return false

## [KR] 노선 힌트 획득 시그널 핸들러. 메타 데이터에 저장하고 알림을 표시한다.
## [EN] Route hint acquisition signal handler. Saves to metadata and displays notification.
func _on_add_route_hint(route_hint_id: String):
	MetaProgression.add_route_hint(route_hint_id)
	item_getted_notion("route_hint")

## [KR] 상자 지도 획득 시그널 핸들러. 메타 데이터에 저장하고 알림을 표시한다.
## [EN] Box map acquisition signal handler. Saves to metadata and displays notification.
func _on_add_box_map(box_map_id: String):
	MetaProgression.add_box_map(box_map_id)
	item_getted_notion("box_map")

## [KR] 기념주화 개수를 [param value]만큼 증감시킨다.
## [EN] Increases/decreases commemorative coin count by [param value].
func _on_set_coin(value: int):
	MetaProgression.add_or_minus_route_coin(value)

## [KR] 장비 코스트 변경 시그널 핸들러. 양수일 때 코스트를 추가하고 알림을 표시한다.
## [EN] Equipment cost change signal handler. Adds cost and displays notification when positive.
func _on_set_equip_cost(value: int):
	if value > 0:
		MetaProgression.add_extra_cost(value) # [KR] 코스트 추가 / [EN] Add cost
		var msg: String = tr("NOTI_MAX_COST_UP") + str(value)
		NotionEvent.notion(msg, Constants.INVENTORY_ICON)

## [KR] 아이템 획득 시 알림 메시지를 표시한다.
## [EN] Displays a notification message when an item is acquired.
## [KR] 칸칸네비를 획득하지 않았으면 알림을 표시하지 않는다.
## [EN] Does not display notification if KankanNavi has not been acquired.
## [KR] 대화 중이면 타임라인 종료 후 알림을 표시한다.
## [EN] If in dialogue, displays notification after timeline ends.
func item_getted_notion(type: String):
	var msg: String
	match type:
		"route_hint":
			msg = "NOTI_NEW_ROUTE_ADDED"
		"box_map":
			msg = "NOTI_NEW_BOX_MAP_ADDED"
	
	if not MetaProgression.has_read_event(Constants.QUESTLINE_KANKANNAVI_GET): ## [KR] 칸칸네비 획득하지 않았을시 알림이 뜨지 않음 / [EN] No notification if KankanNavi not acquired
		return
	if Dialogic.current_timeline:
		await Dialogic.timeline_ended
		NotionEvent.notion(msg, ICONS_KANKAN)
	else:
		NotionEvent.notion(msg, ICONS_KANKAN)

## [KR] 대화 타임라인 종료 시 자동 스킵을 비활성화하고 히스토리를 초기화한다.
## [EN] Disables auto-skip and clears history when dialogue timeline ends.
func _on_timeline_ended():
	Dialogic.Inputs.auto_skip.enabled = false
	Dialogic.History.get_simple_history().clear()
	# 선택지 멈춤 플래그가 소비되지 않고 남았으면 해제한다
	GameEvents.block_skip_on_choice = false

## [KR] 선택지가 표시될 때 자동 스킵 상태이면 첫 번째 활성 선택지를 자동으로 선택한다.
## [EN] Automatically selects the first active choice when choices are shown during auto-skip.
func _on_question_shown(info:Dictionary):
	# 중요 선택지로 지정된 경우 스킵을 끄고 자동선택하지 않아 플레이어 입력을 기다린다
	if GameEvents.block_skip_on_choice:
		Dialogic.Inputs.auto_skip.enabled = false
		return

	# 자동 스킵 또는 오토 플레이 중일 때만 첫 선택지를 자동선택한다.
	if not Dialogic.Inputs.auto_skip.enabled and not GameEvents.autoplay_enabled:
		return

	#print(info)
	# 이 질문의 이벤트 인덱스. 대기 중 수동 선택/다른 질문으로 바뀌면 자동선택을 취소한다(이중 선택 방지).
	var question_idx := Dialogic.current_event_idx
	var delay := DialogicUtil.autoload().Choices.block_delay
	# 오토 플레이(스킵 아님)에서는 음성을 끝까지 듣고, 선택지를 읽을 시간을 확보한다.
	if GameEvents.autoplay_enabled and not Dialogic.Inputs.auto_skip.enabled:
		delay = maxf(delay, AUTOPLAY_CHOICE_DELAY)
		# 음성이 재생 중이면 끝날 때까지 기다린다(음성이 다 나오기 전 자동선택 방지).
		if not await _wait_for_choice_voice_end():
			return
	await get_tree().create_timer(delay+0.1).timeout

	# 대기 중 상태가 바뀌었을 수 있다(수동 선택·타임라인 종료·오토 해제). 재확인 후 선택.
	if Dialogic.current_state != Dialogic.States.AWAITING_CHOICE:
		return
	# 수동(스페이스)으로 이미 선택했거나 다른 질문으로 넘어갔으면 자동선택하지 않는다.
	if Dialogic.current_event_idx != question_idx:
		return
	if not Dialogic.Inputs.auto_skip.enabled and not GameEvents.autoplay_enabled:
		return

	for choice in info["choices"].size():
		if info["choices"][choice]["disabled"] == false:
			DialogicUtil.autoload().Choices._on_choice_selected(info["choices"][choice])
			break

## [KR] 오토 플레이에서 선택지 질문의 음성이 재생 중이면 끝날 때까지 기다린다.
## 도중에 오토가 꺼지거나 선택지 상태가 풀리면(수동 선택 등) false를 반환해 자동선택을 중단한다.
func _wait_for_choice_voice_end() -> bool:
	if not Dialogic.has_subsystem("Voice"):
		return true
	# 일시정지(백로그·옵션 메뉴) 중에는 음성이 멈춰 있어도 끝난 게 아니므로 계속 기다린다.
	while Dialogic.paused or Dialogic.Voice.is_running():
		await get_tree().process_frame
		if not GameEvents.autoplay_enabled:
			return false
		if Dialogic.current_state != Dialogic.States.AWAITING_CHOICE:
			return false
	return true

## [KR] 선택지가 선택되면 중요 선택지 멈춤 플래그를 해제한다.
func _on_choice_selected(_info:Dictionary):
	GameEvents.block_skip_on_choice = false

## [KR] 현재 표시 중인 선택지에서 첫 번째 활성 선택지를 즉시 선택한다.
## [EN] Immediately selects the first active choice from the currently displayed choices.
func _choice_auto_select():
	print("_choice_auto_select")
	# 중요 선택지로 지정된 경우 자동선택하지 않고 스킵을 끈다
	if GameEvents.block_skip_on_choice:
		Dialogic.Inputs.auto_skip.enabled = false
		return
	var info = DialogicUtil.autoload().Choices.get_current_question_info()
	if info == {}:
		return
	for choice in info["choices"].size():
		if info["choices"][choice]["disabled"] == false:
			DialogicUtil.autoload().Choices._on_choice_selected(info["choices"][choice])
			break

## [KR] 자동 스킵 토글 시 선택지 딜레이를 조정한다.
## [EN] Adjusts choice delay when auto-skip is toggled.
## [KR] 활성화 시 딜레이를 최소화하고, 비활성화 시 원래 값으로 복원한다.
## [EN] Minimizes delay when enabled, restores original values when disabled.
func _on_skip_toggled(toggled: bool):
	if not choice_skip:
		return
	
	if toggled:
		DialogicUtil.autoload().Choices.block_delay = 0.1
		DialogicUtil.autoload().Choices.reveal_delay = 0.1
	else:
		DialogicUtil.autoload().Choices.block_delay = choice_block_delay_base
		DialogicUtil.autoload().Choices.reveal_delay = choice_reveal_delay_base
		
	#print(DialogicUtil.autoload().Choices.block_delay)
	#print(DialogicUtil.autoload().Choices.reveal_delay)
