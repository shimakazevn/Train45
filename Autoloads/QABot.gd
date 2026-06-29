## QA 자동화 봇. --qa-mode 인자로 실행 시 활성화.
## 이변 탐지 → 문 통과 루프를 반복하며 퀘스트 진행 상태를 추적·로깅한다.
extends Node

enum Phase { IDLE, MOVING_TO_ANOMALY, CHARGING, MOVING_TO_EVENT, MOVING_TO_DOOR, PLAYING_H_SCENE, SWITCHING_PARTNER, OPENING_SHOP, SHOPPING, EARNING_TICKET, PROLOGUE_TALK, PROLOGUE_FIND, COLLECTING_TICKETS, GOING_TO_BUTLER, REGISTERING_ROUTE, COLLECTING_ITEM_BOX, DESTINATION_TALK, GOING_TO_KONIAL }

## 이변까지 멈추는 거리(px). FindArea 반폭(59px) 이내여야 탐지 성공.
const STOP_DIST := 45.0
## 호감도 이벤트와 NPC가 겹칠 때, NPC를 등지고 이벤트만 감지하기 위해 서는 지점의
## 이벤트로부터의 오프셋(px). TalkArea 방향성 콜리전 폭(69) 이내여야 이벤트가 감지된다.
const _EVENT_BETWEEN_OFFSET := 45.0
## 이 시간(초) 동안 Phase 전환 없으면 Watchdog 발동.
const WATCHDOG_TIMEOUT := 20.0

var active := false
var phase := Phase.IDLE
var watchdog_timer := 0.0

## 메인 메뉴에서 새 게임을 한 번만 시작하도록 하는 가드. 스테이지 진입 시 리셋.
var _menu_start_requested := false
## 프롤로그를 한 번만 건너뛰도록 하는 가드. 봇 활성화 시 리셋.
var _prologue_skipped := false
## [임시 진단] 상태 로그 주기 타이머.
var _diag_timer := 0.0

var stage_count := 0
var clear_count := 0
var bug_count := 0
var log_lines: PackedStringArray = []

var h_scene_wait_timer := 0.0
const H_SCENE_EXIT_DELAY := 1.5
## H씬에서 move_up 탭(누름/뗌)을 번갈아 내기 위한 상태.
var _h_move_up_held := false
## H씬에서 move_down(일시정지 토글) 탭 상태.
var _h_move_down_held := false
## 기지 티켓 H에서 action progress가 90%에 도달했는지.
var _h_reached_90 := false
## 정념 스택 정체(저수지 소진) 감지용 직전 값/시각.
var _h_prev_ero_stack := 0.0
var _h_stack_stall_msec := 0
## 이번 H에서 사정(정념 환산)을 한 번 했는지. 했으면 종료(esc)한다.
var _h_has_cummed := false

var _shop_buy_timer := 0.0
const SHOP_BUY_INTERVAL := 0.8
var _shop_exit_pending := false
# 집사 상호작용이 대화 대신 교환 숍을 여는 케이스의 무한 루프 방지용.
var _butler_suppress_sig := ""
# 처리되지 않은 일시정지 모달(ESC 일시정지 메뉴 등)에서 빠져나오기 위한 정지 감지 타이머.
var _pause_stall_timer := 0.0
const PAUSE_STALL_TIMEOUT := 6.0

## 시작 시 오토세이브가 있으면 이어하기(프롤로그 반복 회피). --qa-new로 끄면 항상 새 게임.
var prefer_autosave := true

## 기능별 온오프 플래그
var enable_dialogue_skip := true
var enable_tutorial := true
var enable_h_scene := true
var enable_anomaly := true
var enable_event := true
var enable_run_clear := true
## 아이템 구매 시 티켓이 부족하면 티켓 획득 상태로 진입할지 여부. off면 그냥 상점을 나간다.
var enable_earn_ticket := true
## 티켓 획득 시 정념이 부족하면 치트로 정념을 최대치까지 채울지 여부.
var enable_ero_cheat := false
## 보유 아이템을 장착 코스트 한도 내에서 최대한 장착할지 여부(스테이지 전환마다).
var enable_equip_all := true

## 바닥 티켓 수거 페이즈 시작 시각(ms). 드롭 지연/상한 판단용.
var _collect_start_msec := 0

## route map 튜토리얼 입력 대기 시 조작 throttle 타이머.
var _route_act_timer := 0.0
## route map 등장 애니메이션(슬롯 생성 전) 대기 시작 시각(ms).
var _register_wait_msec := 0
## 종착점 경로를 확정(RouteStart)했는지 — 확정 후엔 esc로 닫는다.
var _route_confirmed := false
## 아이템 박스 action 입력 throttle 시각(ms).
var _box_act_msec := 0
## 이번 종착점 스테이지에서 히로인과 대화를 했는지(스테이지 전환 시 리셋).
var _dest_talked := false
## 이번 세션에 이미 감상한 호감도 이벤트의 dialog_title 집합(키만 사용).
## 게임의 event_played()가 감상 직후에도 false라 무한 리플레이되는 것을 봇 측에서 차단한다.
var _viewed_love_events := {}
## 현재 스테이지를 건너뛸지(이변 탐지 불가로 충전이 멈출 때). 스테이지 전환 시 리셋.
## 예: 유령 H-이변 스테이지는 AnomalyCollision이 높은 위치라 봇의 충전 탐지가 안 닿는다.
var _skip_current_stage := false

## 종착점 등록 대상(현재 노릴 종착점 destination_info 항목). 비어있으면 없음.
var _pending_dest: Dictionary = {}
## 등록 시도가 실패한(정답 경로 미보유 등) 힌트 id — 재시도 방지용.
var _skip_dest_hints: Dictionary = {}
## 등록하려는 종착점의 정답 노선이 잠겨 있어 코인 해금이 필요한 상태인지.
## true일 때만 코인 상점을 연다(불필요한 코인 선구매로 등록이 막히는 것 방지).
var _dest_coin_blocked := false

## ko, jp, zh, en, cn 순서 (Choice/56, Choice/66 동일)
const _PARTNER_CHOICE_TEXTS := ["탐색 동행", "探索同行", "探索同行", "Exploration Companion", "探索同行"]
## ko, jp, zh, en, cn 순서 (Choice/7c)
const _SHOP_CHOICE_TEXTS := ["티켓 교환", "チケット交換", "票券兌換", "Ticket Exchange", "票券兑换"]
## ko, jp, zh, en, cn 순서 (Choice/53, Choice/63 동일)
const _H_CHOICE_TEXTS := ["엣찌 하고싶어", "エッチしたいな", "我想做愛", "I wanna get naughty", "我想做爱"]

## 테스트 가속용 우선구매·장착 아이템(이속/탐지속도/정념소비속도). id는 .tres 기준(comsume 오타 포함).
const _SPEED_ITEMS := ["speed_up", "area_charge_time_up", "ero_gauge_comsume_up"]

## 챕터6+ 코니알 호감도 경험치용 러브 팔찌. 스토리(chapter6_start)에서 지급되며 장착해야 효과 발생.
const _BRACELET_ID := "love_bracelet"
const _BRACELET_FROM_CHAPTER := 6

## 스토리 진행용 선택지(집사/코니알 등) — 이 키워드를 포함한 선택지를 우선 선택해 챕터를 진행시킨다.
## - "파주주가 갇힌": 챕터5 집사 → dark_room 종착점 해금
## - "파주주에 대해": 챕터6 코니알 대화 → konial_talk1(호감도1 확정, konchan 진행)
## - "콘짱-오메가": 챕터6 기관실 → ending_0(해피엔딩) 분기
const _PROGRESS_CHOICE_KEYWORDS := ["파주주가 갇힌", "파주주에 대해", "콘짱-오메가"]

const PANEL_SCENE := preload("res://Autoloads/qa_bot_panel.tscn")
var _ui_layer: CanvasLayer
var _panel: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.stage_clear.connect(_on_stage_clear)
	GameEvents.stage_change.connect(_on_stage_change)

	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 100
	_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui_layer)
	_panel = PANEL_SCENE.instantiate()
	_panel.visible = false
	_ui_layer.add_child(_panel)
	_panel.setup(self)

	if "--qa-new" in OS.get_cmdline_args():
		prefer_autosave = false

	if "--qa-mode" in OS.get_cmdline_args():
		toggle()


func _input(event: InputEvent) -> void:
	# 출시(익스포트) 빌드에서는 F3 패널 토글을 막는다.
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.keycode == KEY_F3 and event.pressed and not event.echo:
		_panel.visible = not _panel.visible
		get_viewport().set_input_as_handled()


func toggle() -> void:
	active = !active
	if active:
		_log("=== QABot 시작 ===")
		phase = Phase.IDLE
		watchdog_timer = 0.0
		_menu_start_requested = false
		_prologue_skipped = false
	else:
		_reset_input()
		_log("=== QABot 일시정지 ===")
		_save_log()
	_panel.update_status(active, Phase.keys()[phase])


func _process(delta: float) -> void:
	if not active:
		return

	# [임시 진단] 3초마다 멈춤 상태를 기록한다.
	_diag_timer += delta
	if _diag_timer >= 3.0:
		_diag_timer = 0.0
		_log_diag()

	# 튜토리얼 패널 / ConfirmBox 자동 처리 (paused 상태에서만 동작)
	if get_tree().paused:
		if enable_tutorial:
			if _handle_confirm_box():
				return
			_handle_tutorial()
			# 칸칸네비(route map) 튜토리얼 — 게임이 paused된 채 진행되므로 여기서 처리.
			if _handle_route_map_tutorial(delta):
				return
		# 아이템 박스 정보창(개봉 시 tree paused) — action 한 번 더 눌러 닫고 획득.
		if _handle_item_box_paused():
			_pause_stall_timer = 0.0
			return
		if phase == Phase.SHOPPING:
			_pause_stall_timer = 0.0
			_shop_buy_timer += delta
			if _shop_buy_timer >= SHOP_BUY_INTERVAL:
				_shop_buy_timer = 0.0
				_handle_shopping()
			return
		# 위 핸들러로 처리되지 않은 일시정지 모달(ESC 일시정지 메뉴, 집사가 연 교환 숍, 상점 종료 시
		# 잘못 뜬 메뉴 등). 이 분기는 워치독을 증가시키지 않아 그대로 두면 영구 정지하므로,
		# 일정 시간 정지 시 ESC로 해제한다(플레이어가 막힌 메뉴에서 ESC로 빠져나오는 것과 동일).
		_pause_stall_timer += delta
		if _pause_stall_timer >= PAUSE_STALL_TIMEOUT:
			_pause_stall_timer = 0.0
			bug_count += 1
			_log("BUG[%d]: 처리되지 않은 일시정지 모달 %.0fs 정지 → ESC로 해제 (phase=%s)" % [bug_count, PAUSE_STALL_TIMEOUT, Phase.keys()[phase]])
			# 집사 상호작용이 교환 숍만 반복해 여는 경우 → 같은 퀘스트 상태에선 방문 보류(루프 차단).
			if phase == Phase.GOING_TO_BUTLER:
				_butler_suppress_sig = _butler_state_sig()
				_log("집사 방문 보류(교환 숍 반복) sig=%s" % _butler_suppress_sig)
			_press_esc()
		return
	_pause_stall_timer = 0.0

	# H씬 활성 감지 — Dialogic 체크보다 먼저 (event_on이 Dialogic.paused=true를 설정하므로)
	var fac := _get_free_action_component()
	if fac and fac.is_event:
		if enable_h_scene:
			if phase != Phase.PLAYING_H_SCENE:
				h_scene_wait_timer = 0.0
				_h_reached_90 = false
				_h_has_cummed = false
				_h_move_down_held = false
				_h_prev_ero_stack = 0.0
				_h_stack_stall_msec = Time.get_ticks_msec()
				_set_phase(Phase.PLAYING_H_SCENE)
			_tick_play_h_scene(delta)
		watchdog_timer = 0.0
		return

	# 호감도 이벤트 재생 차단: 트리거 경로(shift/자동)와 무관하게, 현재 재생 중인 타임라인 이름을
	# 기록해 둔다. _get_pending_event가 이미 본 호감도 이벤트(read history가 안 남는 게임 버그)를
	# 다시 타깃하지 않도록 한다.
	if Dialogic.current_timeline != null:
		var _tlname := Dialogic.current_timeline.resource_path.get_file().get_basename()
		if _tlname != "":
			_viewed_love_events[_tlname] = true

	# 다이얼로그 자동 스킵 (선택지 우선, 없으면 다음 대화)
	if Dialogic.current_timeline != null:
		if enable_dialogue_skip:
			# 프롤로그는 통째로 건너뛴다(end_prologue 라벨로 점프).
			if _try_skip_prologue():
				watchdog_timer = 0.0
				return
			var advanced := false
			if phase == Phase.SWITCHING_PARTNER:
				advanced = _try_select_partner_choice()
			elif phase == Phase.OPENING_SHOP:
				if _try_select_shop_choice():
					_shop_exit_pending = false
					_set_phase(Phase.SHOPPING)
					advanced = true
			elif phase == Phase.EARNING_TICKET:
				advanced = _handle_recollection_select() or _try_select_h_choice()
			else:
				# 스토리 진행 선택지(집사 "파주주가 갇힌 위치..." 등)를 일반 선택지보다 우선한다.
				advanced = _try_select_progress_choice() or _try_select_choice(-1)
			# 특수 선택지가 없어도 일반 선택지가 떠 있으면 골라서 멈춤 방지(예: chapter2_butler).
			if not advanced:
				advanced = _try_select_choice(-1)
			if not advanced:
				_press_dialogic_action()
		watchdog_timer = 0.0
		return

	# 입력 불가 상태(이벤트·강제 연출 등)는 대기
	if GameEvents.game_state != Constants.STATE_NORMAL:
		Input.action_release("action")
		return

	var level := _get_level()
	# 레벨이 없으면 메인 메뉴 상태로 간주하고 새 게임 시작을 시도한다.
	if not level:
		_try_start_from_menu()
		return

	watchdog_timer += delta
	if watchdog_timer >= WATCHDOG_TIMEOUT:
		_on_watchdog()

	if not level.player or not level.player.input_enabled:
		return

	match phase:
		Phase.IDLE:
			_decide_phase(level)
		Phase.MOVING_TO_ANOMALY:
			_tick_move_to_anomaly(level)
		Phase.CHARGING:
			_tick_charging()
		Phase.MOVING_TO_EVENT:
			_tick_move_to_event(level)
		Phase.MOVING_TO_DOOR:
			_tick_move_to_door(level)
		Phase.PLAYING_H_SCENE:
			_begin_collecting_tickets()  # H씬 종료 후 바닥에 뿌려진 티켓 수거
		Phase.SWITCHING_PARTNER:
			_tick_switching_partner(level)
		Phase.COLLECTING_TICKETS:
			_tick_collecting_tickets(level)
		Phase.GOING_TO_BUTLER:
			_tick_going_to_butler(level)
		Phase.GOING_TO_KONIAL:
			_tick_going_to_konial(level)
		Phase.REGISTERING_ROUTE:
			_tick_registering_route(level)
		Phase.COLLECTING_ITEM_BOX:
			_tick_collecting_item_box(level)
		Phase.DESTINATION_TALK:
			_tick_destination_talk(level)
		Phase.OPENING_SHOP:
			_tick_opening_shop(level)
		Phase.SHOPPING:
			pass  # 상점 오픈 대기 — paused 블록에서 처리
		Phase.EARNING_TICKET:
			_tick_earning_ticket(level)
		Phase.PROLOGUE_TALK:
			_tick_prologue_talk(level)
		Phase.PROLOGUE_FIND:
			_tick_prologue_find(level)


# ── 메인 메뉴에서 새 게임 시작 ────────────────────────────

## 현재 씬이 메인 메뉴([code]_on_play_pressed[/code] 보유)이고 인트로가 끝났으면 새 게임을 시작한다.
func _try_start_from_menu() -> void:
	if _menu_start_requested:
		return
	var scene := get_tree().current_scene
	if not scene or not scene.has_method("_on_play_pressed"):
		return
	if not scene.get("intro_end"):
		return  # 인트로 연출 종료 대기
	_menu_start_requested = true
	var slot := _best_auto_save_slot() if prefer_autosave else -1
	if slot != -1:
		_log("메인 메뉴 감지 → 오토세이브 슬롯 %d 로드(이어하기)" % slot)
		MetaProgression.load_save_file(slot)
		get_tree().change_scene_to_file("res://Gameplay/gameplay.tscn")
	else:
		_log("메인 메뉴 감지 → 새 게임 시작")
		scene._on_play_pressed()


## 데이터가 있는 오토세이브 슬롯(99~) 중 가장 최근에 저장된 슬롯 번호를 반환한다. 없으면 -1.
func _best_auto_save_slot() -> int:
	var best := -1
	var best_time := -1.0
	for i in Constants.AUTO_SAVE_SLOT_COUNT:
		var s: int = Constants.AUTO_SAVE_INDEX + i
		var data = MetaProgression.get_slot_save_data(s)
		if data is Dictionary and data.has("last_save_date") and data["last_save_date"].has("unix_time"):
			var t: float = data["last_save_date"]["unix_time"]
			if t > best_time:
				best_time = t
				best = s
	return best


## 프롤로그 레벨의 [code]PrologueEventComponent[/code]를 반환한다. 없으면 null.
func _get_prologue_component() -> Node:
	var level := _get_level()
	if not level:
		return null
	return level.find_child("PrologueEventComponent", true, false)


## 프롤로그 튜토리얼: 아직 대화하지 않은 NPC(ol=레이나, gyaru=마이)에게 다가가 말을 건다.
func _tick_prologue_talk(level: Level) -> void:
	var pc := _get_prologue_component()
	if not pc or (pc.talk_reina and pc.talk_mai):
		_set_phase(Phase.IDLE)
		return
	var target: Npc = pc.ol if not pc.talk_reina else pc.gyaru
	if not target or not is_instance_valid(target):
		_set_phase(Phase.IDLE)
		return
	var dx: float = target.global_position.x - level.player.global_position.x
	if abs(dx) <= STOP_DIST:
		_release_movement()
		_press_shift()
	else:
		_move_x(sign(dx))


## 프롤로그 찾기 튜토리얼 진행:
## 1) 아직 NPC(ol/gyaru)가 살아있으면 → 우측 talk1_area(konial 등장)로 이동
## 2) konial 후(NPC 해제), 인형 미등장 → 좌측 find_tuto_area로 이동(찾기 대화 트리거)
## 3) 인형(tuto_anomaly) 등장 → 다가가 영역 안에서 action 홀드로 충전 → player_tuto_action
func _tick_prologue_find(level: Level) -> void:
	var pc := _get_prologue_component()
	if not pc:
		_set_phase(Phase.IDLE)
		return

	var anomaly := pc.tuto_anomaly as Node2D
	# 3) 인형 등장 → 충전
	if anomaly and anomaly.visible and pc.tuto_anomaly.monitoring:
		if pc.anomaly_area_in:
			_release_movement()
			Input.action_press("action")  # 홀드 충전 → 100%에서 player_tuto_action 발행
		else:
			Input.action_release("action")
			_move_x(sign(anomaly.global_position.x - level.player.global_position.x))
		return

	Input.action_release("action")
	# 1) konial 전: NPC가 아직 살아있음 → 우측 talk1_area로
	if is_instance_valid(pc.ol) or is_instance_valid(pc.gyaru):
		_move_x(sign((pc.talk1_area as Node2D).global_position.x - level.player.global_position.x))
		return
	# 2) konial 후, 인형 등장 전 → 좌측 find_tuto_area로
	_move_x(sign((pc.find_tuto_area as Node2D).global_position.x - level.player.global_position.x))


## 프롤로그 타임라인이 재생 중이면 end_prologue 라벨로 점프해 한 번만 생략한다.
func _try_skip_prologue() -> bool:
	if _prologue_skipped:
		return false
	var tl := Dialogic.current_timeline
	if not tl or not tl.resource_path.contains("prologue"):
		return false
	_prologue_skipped = true
	_log("프롤로그 감지 → end_prologue 점프(생략)")
	Dialogic.Jump.jump_to_label("end_prologue")
	return true


# ── Phase 결정 ────────────────────────────────────────────

func _decide_phase(level: Level) -> void:
	# 프롤로그 튜토리얼은 전용 페이즈로 처리한다(PrologueEventComponent가 있을 때만 존재).
	var pc := _get_prologue_component()
	if pc:
		if not (pc.talk_reina and pc.talk_mai):
			_set_phase(Phase.PROLOGUE_TALK)
		else:
			_set_phase(Phase.PROLOGUE_FIND)
		return

	# 활성 아이템 박스가 있으면 먼저 획득한다(종착점은 박스를 열어야 복귀, 일반 스테이지는 보상).
	if level.stage_type != Constants.TYPE_BASE and _get_active_item_box(level):
		_set_phase(Phase.COLLECTING_ITEM_BOX)
		return

	# 종착점 스테이지: 미관람 호감도 이벤트(말풍선)가 있으면 감상하고,
	# 없으면 히로인과 1회 대화한다(대화하면 말풍선이 생겨 이후 감상으로 이어짐).
	if level.stage_type != Constants.TYPE_BASE and _is_destination_stage(level):
		if enable_event and _get_pending_event():
			_set_phase(Phase.MOVING_TO_EVENT)
			return
		if not _dest_talked and _get_dest_heroine(level):
			_set_phase(Phase.DESTINATION_TALK)
			return

	if level.stage_clear:
		if level.stage_type == Constants.TYPE_BASE:
			# base에 미관람 활성 호감도 이벤트(butler/konial 말풍선 등)가 있으면 가장 먼저 감상한다.
			# (상점/티켓보다 우선 — 호감도가 차면 버블 생성, 감상 시 호감도 이벤트/퀘스트 진행.)
			if enable_event and _get_pending_event():
				_set_phase(Phase.MOVING_TO_EVENT)
				return
			if _get_needed_partner() != MetaProgression.get_current_partner():
				_set_phase(Phase.SWITCHING_PARTNER)
				return
			# 종착점 해금용 route 코인이 부족하면 등록 전에 먼저 코인을 산다(코인 0이면 잠긴 노선 못 풀어 등록 실패).
			if _is_coin_shop_needed():
				_set_phase(Phase.OPENING_SHOP)
				return
			# 종착점 방문: 기존 힌트로 등록 가능한 미클리어 종착점이 있으면 먼저 등록한다.
			# - 챕터5: 항상 등록 시도.
			# - 챕터6: 호감도 파밍 중(item_konchan 미독)에는 등록 금지(팔찌가 칸칸 네비를 막아 무한 q 입력).
			#   konchan 트리거 후에만 팔찌를 해제하고 engine_room 종착점을 등록한다.
			var ch6_dest_ok := MetaProgression.get_current_chapter() == 6 and MetaProgression.has_read_event("item_konchan")
			if _is_destination_needed() or MetaProgression.get_current_chapter() == 5 or ch6_dest_ok:
				var dest := _get_uncleared_dest()
				if not dest.is_empty():
					_pending_dest = dest
					_set_phase(Phase.REGISTERING_ROUTE)
					return
			# 챕터6: konial_love_1 감상 후 코니알과 대화해 "파주주에 대해"(konial_talk1)를 진행한다.
			if _should_talk_konial():
				_set_phase(Phase.GOING_TO_KONIAL)
				return
			# 상점(아이템 + 힌트).
			if _is_shop_needed() or _is_hint_shop_needed():
				_set_phase(Phase.OPENING_SHOP)
				return
			# 퀘스트가 없거나(시작 필요) 모두 충족됐으면 집사에게 간다(챕터4+).
			if _should_visit_butler():
				_set_phase(Phase.GOING_TO_BUTLER)
				return
			# 퀘스트 조건에 티켓 보유 N개가 있으면 채울 때까지 티켓을 번다.
			if _is_ticket_needed():
				_set_phase(Phase.EARNING_TICKET)
				return
		if enable_event and _get_pending_event():
			_set_phase(Phase.MOVING_TO_EVENT)
		else:
			_set_phase(Phase.MOVING_TO_DOOR)
		return
	var fm := _get_floor_manager()
	if not fm:
		return
	# run_stage: find_lock=true라 차징 불가 → 강제 클리어 후 문으로
	if level.run_stage and enable_run_clear:
		GameEvents.emit_stage_clear()
		fm.stage_clear(level)
		# PlayTrigger·MoveGhost 등 귀신 메커니즘 일괄 비활성화
		for node in level.find_children("*", "GhostSkipComponent", true, false):
			(node as GhostSkipComponent).equip_ghost_skip = true
		# 아이템 장착 시 MoveGhost._on_stage_changed()가 호출하는 erase_follow_targets를
		# QABot은 뒤늦게 설정하므로 직접 수행 — player가 freed된 후 PhantomCamera2D 크래시 방지
		for node in level.find_children("*", "CharacterBody2D", true, false):
			if node.has_method("stage_clear"):
				var pcam: PhantomCamera2D = node.get_node_or_null("PhantomCamera2D")
				if pcam:
					pcam.erase_follow_targets(level.player)
		_set_phase(Phase.MOVING_TO_DOOR)
		return
	# 이변 탐지가 안 돼 충전이 멈춘 스테이지(예: 유령 H-이변)는 클리어를 포기하고 문으로 나가 재롤한다.
	if _skip_current_stage:
		_set_phase(Phase.MOVING_TO_DOOR)
		return
	if fm.current_stage_type == Constants.TYPE_STAGE and fm.current_anomaly and enable_anomaly:
		_set_phase(Phase.MOVING_TO_ANOMALY)
	else:
		_set_phase(Phase.MOVING_TO_DOOR)


# ── 이변으로 이동 ─────────────────────────────────────────

func _tick_move_to_anomaly(level: Level) -> void:
	var fm := _get_floor_manager()
	if not fm or not fm.current_anomaly:
		_set_phase(Phase.MOVING_TO_DOOR)
		return
	if level.stage_clear:
		_set_phase(Phase.MOVING_TO_DOOR)
		return

	var dx: float = (fm.current_anomaly.anomaly_collision as Node2D).global_position.x - level.player.global_position.x
	if abs(dx) <= STOP_DIST:
		_release_movement()
		_set_phase(Phase.CHARGING)
	else:
		_move_x(sign(dx))


# ── 호감도 이벤트로 이동 ─────────────────────────────────

func _tick_move_to_event(level: Level) -> void:
	var event := _get_pending_event()
	if not event:
		_set_phase(Phase.MOVING_TO_DOOR)
		return
	var player := level.player
	var event_x: float = event.global_position.x
	# 1) 타깃 이벤트 범위 안 + NPC 미감지 → 상호작용(shift)으로 감상.
	# near_event == event 확인: 다른 이벤트(예: 지나치는 konial_love_0) 위에서 shift를 눌러
	# 엉뚱한 이벤트를 트리거하지 않도록 한다. 감상 기록은 실제 재생되는 타임라인을 _process에서 마킹한다.
	if player.is_near_event and player.near_event == event and not player.is_near_npc:
		_release_movement()
		_press_shift()
		return
	# 2) NPC가 이벤트와 겹쳐 상호작용을 가로채는 경우(Player.find_target은 NPC 우선).
	#    TalkArea는 바라보는 방향의 대상만 감지하므로, NPC와 이벤트 사이에 서서 이벤트 쪽을
	#    바라보면 NPC가 뒤로 빠져 감지되지 않는다 → 이벤트만 감상 가능해진다.
	if player.is_near_npc and is_instance_valid(player.near_npc):
		var npc_x: float = player.near_npc.global_position.x
		var to_event: float = sign(event_x - npc_x)
		if to_event == 0.0:
			to_event = 1.0
		var target_x: float = event_x - to_event * _EVENT_BETWEEN_OFFSET
		var dx: float = target_x - player.global_position.x
		if abs(dx) > 8.0:
			_move_x(int(sign(dx)))
		else:
			_move_x(int(to_event))  # 이벤트 방향으로 facing을 고정 → NPC 미감지
		return
	# 3) 아직 이벤트 근처가 아니면 이벤트로 이동.
	_move_x(int(sign(event_x - player.global_position.x)))


func _get_pending_event() -> EventArea:
	for area in get_tree().get_nodes_in_group("eventcomponent"):
		var ea := area as EventArea
		if ea and ea.event_enabled and ea.current_stage_clear and not ea.played and ea.visible:
			# played 플래그는 스테이지 리로드/레벨업 시그널에서만 갱신돼, 감상 직후에도 false로 남는다.
			# 이미 읽은 이벤트(read history) 또는 이번 세션에 봇이 감상한 이벤트는 리플레이 확인창이
			# 떠 무한 반복되므로 제외한다.
			if ea.event_played():
				continue
			if ea.h_scene_info and _viewed_love_events.has(ea.h_scene_info.dialog_title):
				continue
			return ea
	return null


# ── 충전 (action 홀드) ────────────────────────────────────

func _tick_charging() -> void:
	# stage_clear 시그널 → _on_stage_clear에서 Phase 전환
	# 첫 프레임: just_pressed → 이후 is_pressed 유지 → 3초 후 자동 완전 충전
	Input.action_press("action")


# ── H씬 자유 행위 ────────────────────────────────────────

func _tick_play_h_scene(delta: float) -> void:
	var fac := _get_free_action_component()
	if not fac or not fac.is_event:
		_begin_collecting_tickets()  # H씬 종료 → 바닥 티켓 수거
		return

	if fac.scene_progress == 4:
		h_scene_wait_timer += delta
		if h_scene_wait_timer >= H_SCENE_EXIT_DELAY:
			h_scene_wait_timer = 0.0
			_press_esc()
		return

	h_scene_wait_timer = 0.0

	# 기지 시작지점 H(티켓 환산)인지 여부. 이때만 90% 대기 로직을 쓴다.
	var is_base_h: bool = get_tree().get_first_node_in_group("h_scene_window_component") != null

	if not is_base_h:
		# 스토리 등 일반 H: 게이지를 빠르게 올려 진행(종료는 scene_progress==4에서).
		if fac.is_input_locked:
			Input.action_release("move_up")
			_h_move_up_held = false
		else:
			_h_tap_move_up(fac)
		return

	# ── 기지 티켓 H ──
	# 사정 후처리(게이지 자동 감소) 중 — 입력 잠금. 사정했음을 기록한다.
	if fac.is_input_locked:
		_h_has_cummed = true
		_h_reached_90 = false
		Input.action_release("move_up")
		_h_move_up_held = false
		return

	# 한 번 사정해 정념을 티켓으로 환산했으면 종료(esc) → 바닥 티켓 수거로.
	if _h_has_cummed:
		_press_esc()
		return

	# action progress(사정 게이지)를 90%까지 올린다.
	if not _h_reached_90:
		if fac.current_gage >= 90.0:
			_h_reached_90 = true
			_h_prev_ero_stack = fac.current_ero_stack
			_h_stack_stall_msec = Time.get_ticks_msec()
		else:
			_h_tap_move_up(fac)
		return

	# 90% 도달 후: 정념이 계속 쌓이면 일시정지로 게이지를 유지, 정체되면(소진) 사정으로.
	# (release만으론 is_increasing이 안 꺼져 게이지가 계속 올라가므로 move_down으로 pause해야 한다.)
	if fac.current_ero_stack > _h_prev_ero_stack + 0.01:
		_h_prev_ero_stack = fac.current_ero_stack
		_h_stack_stall_msec = Time.get_ticks_msec()
	var ero_drained: bool = Time.get_ticks_msec() - _h_stack_stall_msec > 600

	if ero_drained:
		# move_up은 일시정지를 풀고 게이지를 다시 올린다 → 100%에서 사정.
		Input.action_release("move_down")
		_h_move_down_held = false
		_h_tap_move_up(fac)
	elif not fac.is_paused:
		# 게이지 상승을 멈추기 위해 move_down으로 일시정지.
		Input.action_release("move_up")
		_h_move_up_held = false
		_h_tap_move_down(fac)
	else:
		# 일시정지 유지 — 입력 없이 게이지 고정, 정념만 축적.
		Input.action_release("move_up")
		Input.action_release("move_down")
		_h_move_up_held = false
		_h_move_down_held = false


## move_up을 탭(누름↔뗌)하여 "증가 중 + 3배속(is_speed_doubled==false)" 상태로 게이지를 올린다.
## 일시정지(is_paused) 상태면 반드시 눌러 정지를 풀고 다시 상승시킨다.
func _h_tap_move_up(fac) -> void:
	var want_tap: bool = fac.is_paused or not fac.is_increasing or fac.is_speed_doubled
	if want_tap:
		# 한 프레임 누르고 다음 프레임 떼서 is_action_just_pressed가 다시 발생하게 한다.
		if _h_move_up_held:
			Input.action_release("move_up")
			_h_move_up_held = false
		else:
			Input.action_press("move_up")
			_h_move_up_held = true
	else:
		Input.action_release("move_up")
		_h_move_up_held = false


## move_down을 탭(누름↔뗌)하여 일시정지(pause)를 한 번 토글한다.
func _h_tap_move_down(_fac) -> void:
	if _h_move_down_held:
		Input.action_release("move_down")
		_h_move_down_held = false
	else:
		Input.action_press("move_down")
		_h_move_down_held = true


## 바닥 티켓 수거 페이즈로 전환한다(드롭 지연 대기 타이머 초기화).
func _begin_collecting_tickets() -> void:
	_collect_start_msec = Time.get_ticks_msec()
	_set_phase(Phase.COLLECTING_TICKETS)


## 바닥에 뿌려진 [DropItem](티켓)을 모두 줍는다. 플레이어가 근접하면 자동 회수된다.
func _tick_collecting_tickets(level: Level) -> void:
	var pending: Array = []
	for node in level.find_children("*", "DropItem", true, false):
		if is_instance_valid(node) and not node.was_collected:
			pending.append(node)

	var elapsed := Time.get_ticks_msec() - _collect_start_msec
	if pending.is_empty():
		# 드롭은 사정 2초 뒤에 생기므로 잠시 대기, 그래도 없으면 종료.
		if elapsed > 3000:
			_release_movement()
			_set_phase(Phase.IDLE)
		return
	if elapsed > 15000:  # 안전 상한 — 회수 불가 티켓에 갇히지 않도록
		_release_movement()
		_set_phase(Phase.IDLE)
		return

	var nearest: Node2D = null
	var best := INF
	for t in pending:
		var d: float = abs((t as Node2D).global_position.x - level.player.global_position.x)
		if d < best:
			best = d
			nearest = t
	if nearest:
		_move_x(sign(nearest.global_position.x - level.player.global_position.x))


# ── 상점 열기 ────────────────────────────────────────────

func _is_shop_needed() -> bool:
	var qd := _get_quest_data()
	if not qd or qd.collect_items <= 0:
		return false
	return MetaProgression.get_save_data_ability().size() < qd.collect_items


## 종착점이 더 필요하고, 상점에 아직 구매하지 않은 힌트가 있으면 true(상점에서 힌트 구매).
func _is_hint_shop_needed() -> bool:
	return _is_destination_needed() and _has_buyable_hint()


## route 코인이 부족하면 상점에서 산다(챕터4~5 종착점 등록용, 잠긴 정답 노선 해금). 코인은 항상 판매.
## 종착점 등록은 quest_4_3(챕터4)부터 시작되므로 챕터5 전용으로 막으면 챕터4에서 코인을 못 사 막힌다.
## 챕터6은 종착점 등록을 하지 않으므로(팔찌 파밍 우선) 제외한다.
## 중요: 등록하려는 종착점이 실제로 코인-잠금(`_dest_coin_blocked`)일 때만 산다 —
## 무조건 코인부터 모으면 잠기지 않은 종착점 등록까지 막혀 상점/탐색만 반복한다(quest_4_3 버그).
func _is_coin_shop_needed() -> bool:
	var ch := MetaProgression.get_current_chapter()
	if ch < 4 or ch > 5:
		return false
	if not _dest_coin_blocked:
		return false
	if MetaProgression.get_route_coin() >= 4:
		return false
	return _has_buyable_coin()


## 상점 목록에 route 코인(CurrencyShopItem) 아이템이 있는지.
func _has_buyable_coin() -> bool:
	var um := _get_upgrade_manager()
	if not um:
		return false
	for entry in um.upgrade_list.items:
		if entry["item"] is CurrencyShopItem:
			return true
	return false


## 상점 목록에 아직 보유하지 않은 종착점 힌트(ShopHint) 아이템이 있는지.
func _has_buyable_hint() -> bool:
	var um := _get_upgrade_manager()
	if not um:
		return false
	for entry in um.upgrade_list.items:
		var item = entry["item"]
		if item is ShopHint and not MetaProgression.has_route_hint(item.hint_info.id):
			return true
	return false


func _get_upgrade_manager() -> UpgradeManager:
	var nodes := get_tree().get_root().find_children("*", "UpgradeManager", true, false)
	return nodes[0] as UpgradeManager if not nodes.is_empty() else null


## 퀘스트 조건에 티켓 보유 N개가 있고 아직 모자라면 true.
func _is_ticket_needed() -> bool:
	if not enable_earn_ticket:
		return false
	var qd := _get_quest_data()
	if not qd or qd.ticket <= 0:
		return false
	return MetaProgression.get_ticket_num() < qd.ticket


## 집사에게 가야 하는 상태인지(챕터4+에서 퀘스트가 없거나 모두 충족됐을 때).
func _should_visit_butler() -> bool:
	if MetaProgression.get_current_chapter() < 4:
		return false
	# 집사가 교환 숍만 반복해 열어 진행 불가로 판단된 상태면 방문 보류(상태가 바뀌면 자동 해제).
	if _butler_suppress_sig != "" and _butler_state_sig() == _butler_suppress_sig:
		return false
	var ggm := get_tree().get_first_node_in_group("globalgamemanager") as GlobalGameManager
	if not ggm or not ggm.main_quest_component:
		return false
	var mqc: MainQuestComponent = ggm.main_quest_component
	if mqc.quest_data == null:
		return true  # 퀘스트 시작(예: chapter4_butler)을 위해 집사 필요
	# 집사에게 스토리 진행 선택지(예: 파주주 위치)가 떠 있는 상황이면 talk 퀘스트여도 방문.
	if _butler_progress_pending():
		return true
	# talk 전용 퀘스트(수치 목표 없음)는 is_clear가 항상 true이므로 제외 — 탐색으로 진행.
	if not _quest_has_numeric_goal(mqc.quest_data):
		return false
	return mqc.get_is_clear_check()  # 수치 조건 모두 충족 → 집사에게 보고


## 집사 방문 상태 시그니처(챕터+현재 퀘스트). 퀘스트가 진행되면 값이 바뀌어 루프 가드가 자동 해제된다.
func _butler_state_sig() -> String:
	var ggm := get_tree().get_first_node_in_group("globalgamemanager") as GlobalGameManager
	var qid := "null"
	if ggm and ggm.main_quest_component and ggm.main_quest_component.quest_data:
		qid = str(ggm.main_quest_component.quest_data.resource_path)
	return "%d:%s" % [MetaProgression.get_current_chapter(), qid]


## 집사 대화에 스토리 진행 선택지가 떠 있는 조건인지(챕터별 게이팅 이벤트로 판단).
func _butler_progress_pending() -> bool:
	# 챕터5: "파주주가 갇힌 위치를 찾고 싶어" 선택지는 quest_5가 전부 클리어됐을 때만 진행(chapter5_start 설정)된다.
	# quest_5 미완료 상태에서 선택하면 아무 진행 없이 선택지가 다시 떠 무한 반복하므로, 완료됐을 때만 방문한다.
	if MetaProgression.get_current_chapter() == 5 and not MetaProgression.has_read_event("chapter5_start"):
		return GameEvents.get_current_main_quest_all_clear("quest_5")
	return false


## 퀘스트에 실제 수치 목표(티켓/이변/수집/호감도 등)가 하나라도 있는지.
func _quest_has_numeric_goal(qd) -> bool:
	if qd == null:
		return false
	if qd.ticket > 0 or qd.route > 0 or qd.collect_destinations > 0:
		return true
	if qd.collect_items > 0 or qd.complete_count > 0 or qd.total_love > 0:
		return true
	return qd.npcs != null and qd.npcs.size() > 0


## 종착점 방문 퀘스트 조건이 있고 아직 부족하면 true.
func _is_destination_needed() -> bool:
	var qd := _get_quest_data()
	if not qd or qd.collect_destinations <= 0:
		return false
	return MetaProgression.get_current_destination_info().size() < qd.collect_destinations


## 보유 힌트 중 아직 방문 안 한(클리어 안 된) 종착점의 destination_info를 반환. 없으면 {}.
var _dest_dbg_msec := 0
func _get_uncleared_dest() -> Dictionary:
	# 챕터 종료 종착점(stage_complete_*)은 조기 챕터 전환 방지를 위해
	# 퀘스트가 모두 충족됐거나 talk 전용 퀘스트("X로 이동" 류)일 때만 허용한다.
	var allow_complete := _is_quest_clear_or_talk()
	# [임시 진단] 5초마다 힌트별 매칭/제외 사유를 덤프(왜 미클리어 종착점을 못 찾는지 추적).
	var dbg := Time.get_ticks_msec() - _dest_dbg_msec > 5000
	if dbg:
		_dest_dbg_msec = Time.get_ticks_msec()
		var parts: Array = []
		for raw_hint in MetaProgression.get_route_hint_array():
			var n := _normalize_hint(raw_hint)
			var matched := "none"
			for key in RouteData.destination_info.keys():
				var d: Dictionary = RouteData.destination_info[key]
				var dh: String = str(d.get("hint_id", ""))
				if dh != "" and _normalize_hint(dh) == n:
					var why := "OK"
					if _skip_dest_hints.has(dh): why = "skip"
					elif RouteData.is_clear_destination(dh): why = "cleared"
					elif not allow_complete and str(key).begins_with("stage_complete"): why = "stage_complete제외"
					matched = "%s/%s:%s" % [key, dh, why]
					break
			parts.append("%s->%s" % [raw_hint, matched])
		_log("[종착점진단] allow_complete=%s hints=%s" % [str(allow_complete), str(parts)])
	for raw_hint in MetaProgression.get_route_hint_array():
		var norm := _normalize_hint(raw_hint)
		for key in RouteData.destination_info.keys():
			var dest: Dictionary = RouteData.destination_info[key]
			var dhint: String = str(dest.get("hint_id", ""))
			if dhint == "" or _normalize_hint(dhint) != norm:
				continue
			# 클리어/스킵 판정은 종착점의 bare hint_id로 한다(보유 힌트는 hint_item_ 접두사가 붙기도 함).
			if _skip_dest_hints.has(dhint) or RouteData.is_clear_destination(dhint):
				continue
			if not allow_complete and str(key).begins_with("stage_complete"):
				continue
			return dest
	return {}


## 힌트 id를 정규화한다(hint_item_ 접두사 제거 + 언더스코어 제거).
## 예: "hint_item_handfan" → "handfan", 종착점 "hand_fan" → "handfan" (매칭 일치).
func _normalize_hint(id: String) -> String:
	var s := id
	if s.begins_with("hint_item_"):
		s = s.substr("hint_item_".length())
	return s.replace("_", "")


## 현재 메인 퀘스트가 모두 충족됐거나 talk 전용(수치 목표 없음)인지.
func _is_quest_clear_or_talk() -> bool:
	var ggm := get_tree().get_first_node_in_group("globalgamemanager") as GlobalGameManager
	if not ggm or not ggm.main_quest_component:
		return true
	var mqc: MainQuestComponent = ggm.main_quest_component
	if mqc.quest_data == null:
		return false
	if not _quest_has_numeric_goal(mqc.quest_data):
		return true  # talk 전용 — 특정 종착점 이동 퀘스트
	return mqc.get_is_clear_check()


## 챕터6+ 러브 팔찌가 장착돼 있으면 해제한다(장착 시 칸칸 네비 비활성).
## 스테이지 전환 타이밍(_ensure_speed_items_equipped)과 무관하게, 루트 등록 직전 보장용.
func _unequip_bracelet_if_equipped() -> void:
	if MetaProgression.get_current_chapter() < _BRACELET_FROM_CHAPTER:
		return
	var im = get_tree().get_first_node_in_group("inventorymanager")
	if not im or not im.equipment:
		return
	var equip = im.equipment
	var bitem = equip.item_data.get_item(_BRACELET_ID, ItemData.ItemTypes.ABILITY)
	if bitem and equip.has_equip_item(bitem):
		equip.erase_equip_list(bitem)
		_log("러브 팔찌 해제(루트 등록 위해 — 칸칸 네비 활성화)")


## 종착점 등록 페이즈: kankannavi가 닫혀 있으면 연다(열리면 paused 분기에서 등록 처리).
var _last_kankan_open_msec := 0
func _tick_registering_route(_level: Level) -> void:
	if _pending_dest.is_empty():
		_set_phase(Phase.IDLE)
		return
	# 팔찌가 끼워져 있으면 칸칸 네비가 안 열린다 → 등록 전에 먼저 해제.
	_unequip_bracelet_if_equipped()
	var rms := get_tree().get_root().find_children("*", "RouteMap", true, false)
	if not rms.is_empty():
		return  # 이미 열림 — 등록은 _handle_route_map_tutorial(paused)에서 수행
	_register_wait_msec = 0  # 새로 열기 → 슬롯 대기 타이머 리셋
	_route_confirmed = false
	if Time.get_ticks_msec() - _last_kankan_open_msec > 600:
		_last_kankan_open_msec = Time.get_ticks_msec()
		_press_game_action("shotcut_kankan")


## 칸칸네비(route map) 튜토리얼 처리. route map이 열려 있으면(게임 paused) true 반환.
## 대화가 진행 중이면(Dialogic.paused=false) 다음으로 넘기고,
## 입력 대기(Dialogic.paused=true)면 단계에 맞는 조작을 수행한다.
func _handle_route_map_tutorial(delta: float) -> bool:
	var rms := get_tree().get_root().find_children("*", "RouteMap", true, false)
	if rms.is_empty():
		# route map 미오픈 — "Q로 칸칸네비 열기" 차단 프롬프트면 연다.
		for ic in get_tree().get_root().find_children("*", "RouteSetIcon", true, false):
			var rsi := ic as RouteSetIcon
			if rsi and rsi.is_tuto_blocking:
				_route_act_timer += delta
				if _route_act_timer >= 0.5:
					_route_act_timer = 0.0
					_press_game_action("shotcut_kankan")
				return true
		return false
	var rm: RouteMap = rms[0]
	var rt = rm.route_tutorial
	if not rt or not rt.current_tutorial:
		# 종착점 등록 대상이 있으면 정답 경로를 등록하고, 없으면 esc로 닫는다.
		if not _pending_dest.is_empty():
			return _do_register_route(rm, delta)
		_route_act_timer += delta
		if _route_act_timer >= 0.5:
			_route_act_timer = 0.0
			_press_game_action("esc")
		return true

	# 대화 진행 중 — 선택지가 있으면 고르고, 없으면 다음 대사로 넘긴다.
	if not Dialogic.paused:
		if not _try_select_choice(-1):
			_press_dialogic_action()
		return true

	# 입력 대기 단계 — UI 상태에 맞는 조작을 throttle하여 수행.
	_route_act_timer += delta
	if _route_act_timer < 0.5:
		return true
	_route_act_timer = 0.0

	if rt.exit_input_enabled:
		_press_game_action("esc")  # 튜토리얼 종료 — 칸칸네비 닫기
	elif rm.route_start and not rm.route_start.disabled:
		rm.route_start.pressed.emit()  # 경로 확정 버튼
	elif rt.route_set_input_enabled:
		_press_game_action("kankan_routes_set")  # 노선 등록 단축키
	else:
		# 튜토리얼 지정 경로(3,4,5 등 활성화된 슬롯)를 모두 선택해야 종착점이 세팅된다.
		for child in rm.route_container.get_children():
			var slot := child as RouteSlot
			if slot and not slot.disabled:
				slot.pressed.emit()
	return true


## 임의의 인풋 액션을 한 번 발생시킨다(route_map._input 등이 직접 이벤트를 읽음).
func _press_game_action(action_name: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action_name
	ev.pressed = true
	Input.parse_input_event(ev)


## kankannavi에서 _pending_dest의 정답 경로를 등록한다. 처리 중이면 true 반환.
func _do_register_route(rm: RouteMap, delta: float) -> bool:
	# 등장 애니메이션(await kankan_on) 완료 전에는 route_container가 비어 있다 — 슬롯 생성까지 대기.
	if rm.route_container.get_child_count() == 0:
		if _register_wait_msec == 0:
			_register_wait_msec = Time.get_ticks_msec()
		elif Time.get_ticks_msec() - _register_wait_msec > 8000:
			_register_wait_msec = 0
			var h: String = _pending_dest.get("hint_id", "")
			if h != "":
				_skip_dest_hints[h] = true
			_log("종착점 등록 실패(%s) — route_container 8초간 비어있음, 포기" % h)
			_pending_dest = {}
			_press_game_action("esc")
			_set_phase(Phase.MOVING_TO_DOOR)
		return true
	_register_wait_msec = 0

	_route_act_timer += delta
	if _route_act_timer < 0.4:
		return true
	_route_act_timer = 0.0

	# 정답 조합이 맞아 종착점이 떴으면 확정(1회) → 닫기 → 탐색.
	if rm.destination_container.get_child_count() > 0:
		if not _route_confirmed:
			if rm.route_start and not rm.route_start.disabled:
				rm.route_start.pressed.emit()  # 경로 확정(set_setting_route, 창은 안 닫힘)
				_route_confirmed = true
			return true
		_press_game_action("esc")  # 확정했으니 칸칸네비 닫기
		_log("종착점 경로 등록 완료(%s) → 탐색" % _pending_dest.get("hint_id", "?"))
		_pending_dest = {}
		_route_confirmed = false
		_dest_coin_blocked = false  # 등록 성공 → 코인 잠금 해제 상태 리셋
		_set_phase(Phase.MOVING_TO_DOOR)
		return true

	# 정답 경로 슬롯을 선택한다. 잠겨 있으면 먼저 눌러 해금(confirm box는 _handle_confirm_box가 처리).
	var match_total := 0
	var match_unlocked := 0
	var match_in_set := 0
	for child in rm.route_container.get_children():
		var slot := child as RouteSlot
		if not slot or not _route_matches_pending(slot):
			continue
		match_total += 1
		if slot.is_unlocked:
			match_unlocked += 1
		if slot.route_path in rm.route_set_list:
			match_in_set += 1
			continue
		if slot.disabled:
			continue
		# 잠긴 노선은 코인이 있어야 해금 가능 — 코인 없으면 건너뛴다(무한 클릭 방지).
		if not slot.is_unlocked and MetaProgression.get_route_coin() < rm.get_need_unlock_coin_num():
			continue
		slot.pressed.emit()  # 미해금+코인있음이면 해금창, 해금돼 있으면 노선 등록
		return true

	# 처리할 매칭 슬롯이 더 없음(또는 없음) → 종착점 미생성. 상세 로그 후 포기.
	# 단, 코인 부족(잠긴 정답 노선)으로 실패한 경우는 영구 스킵하지 않는다(코인 모이면 재시도).
	var hid: String = _pending_dest.get("hint_id", "")
	var coin_blocked := match_total > 0 and match_unlocked < match_total
	if hid != "" and not coin_blocked:
		_skip_dest_hints[hid] = true
	# 잠긴 정답 노선(코인 부족)이면 코인 상점을 열도록 플래그를 세운다(영구 스킵 안 함).
	_dest_coin_blocked = coin_blocked
	var slot_nums: Array = []
	for child in rm.route_container.get_children():
		var s := child as RouteSlot
		if s:
			slot_nums.append(s.route_num)
	_log("종착점 등록 실패(%s) 포기 — 매칭=%d 해금=%d set포함=%d coin=%d route_set=%d | type=%s 정답=%s 슬롯수=%d 슬롯num=%s" % [
		hid, match_total, match_unlocked, match_in_set,
		MetaProgression.get_route_coin(), rm.route_set_list.size(),
		str(_pending_dest.get("route_list_type","?")), str(_pending_dest.get("route_list",[])),
		rm.route_container.get_child_count(), str(slot_nums.slice(0, 20))])
	_pending_dest = {}
	_press_game_action("esc")
	_set_phase(Phase.MOVING_TO_DOOR)
	return true


## RouteSlot이 _pending_dest의 정답 경로(route_list)에 해당하는지.
func _route_matches_pending(slot: RouteSlot) -> bool:
	var rtype: String = _pending_dest.get("route_list_type", "name")
	var rlist: Array = _pending_dest.get("route_list", [])
	if rtype == "number":
		for n in rlist:
			if int(n) == slot.route_num:
				return true
		return false
	# name 타입 — route_path 베이스명(stage_1 등)으로 비교.
	var base := slot.route_path.get_file().get_basename()
	return base in rlist


## 현재 레벨이 종착점 스테이지인지(route_data에 destination 정보가 있는지).
func _is_destination_stage(level: Level) -> bool:
	var fm := _get_floor_manager()
	if not fm or not fm.route_data:
		return false
	return not fm.route_data.get_destination_data(level).is_empty()


## 종착점에서 대화할 히로인(reina/mai) NPC를 반환한다. 없으면 null.
func _get_dest_heroine(_level: Level) -> Npc:
	var reina := _find_npc_by_type(Constants.NpcTypes.REINA)
	if reina:
		return reina
	return _find_npc_by_type(Constants.NpcTypes.MAI)


## 종착점의 히로인에게 다가가 1회 대화한다(이후 말풍선 이벤트로 이어짐).
func _tick_destination_talk(level: Level) -> void:
	var heroine := _get_dest_heroine(level)
	if not heroine:
		_set_phase(Phase.IDLE)
		return
	var dx: float = heroine.global_position.x - level.player.global_position.x
	if abs(dx) <= STOP_DIST:
		_release_movement()
		_press_shift()
		_dest_talked = true
		_set_phase(Phase.IDLE)  # 대화 트리거 후 재평가(말풍선 이벤트 감상으로 이어짐)
	else:
		_move_x(sign(dx))


## 현재 레벨의 활성(미획득) 아이템 박스를 반환한다. 없으면 null.
func _get_active_item_box(level: Level) -> RewardItemBox:
	for node in level.find_children("*", "RewardItemBox", true, false):
		var box := node as RewardItemBox
		if box and box.box_active and not box.getted:
			return box
	return null


## 게임이 paused된 아이템 박스 정보창을 처리한다. SHOW_INFO_END에서 action으로 닫고 획득.
func _handle_item_box_paused() -> bool:
	var level := _get_level()
	if not level:
		return false
	var box := _get_active_item_box(level)
	if not box:
		return false
	match box.box_state:
		RewardItemBox.BoxState.SHOW_INFO_END:
			if Time.get_ticks_msec() - _box_act_msec > 400:
				_box_act_msec = Time.get_ticks_msec()
				_press_game_action("action")  # 정보창 닫고 획득(→복귀/계속)
			return true
		RewardItemBox.BoxState.OPEN, RewardItemBox.BoxState.SHOW_INFO:
			return true  # 개봉 애니메이션 중 — 대기
	return false


## 아이템 박스로 다가가 action으로 개봉·획득한다(종착점은 획득해야 복귀).
func _tick_collecting_item_box(level: Level) -> void:
	var box := _get_active_item_box(level)
	if not box:
		_set_phase(Phase.IDLE)
		return
	if not box.current_near_player:
		_move_x(sign(box.global_position.x - level.player.global_position.x))
		return
	_release_movement()
	# 이미 획득한 내용물(ALREADY_GET)이면 박스가 알아서 복귀 처리하므로 대기.
	if box.box_state == RewardItemBox.BoxState.ALREADY_GET:
		return
	# action 탭으로 개봉(CLOSE→정보)·획득(SHOW_INFO_END→get). box._input이 이벤트를 직접 읽는다.
	if Time.get_ticks_msec() - _box_act_msec > 500:
		_box_act_msec = Time.get_ticks_msec()
		_press_game_action("action")


## 기지의 집사(BUTLER)에게 다가가 말을 건다. 말을 건 뒤엔 IDLE로 복귀해 재평가한다.
## NPC에게 다가가 대화를 건다. TalkArea가 방향성(이동방향 쪽만 감지)이라, X위치만 맞고 facing이
## 안 맞으면 is_near_npc가 안 들어와 shift가 먹지 않는다(오버슈트로 NPC를 지나친 경우 등).
## 그래서 NPC가 실제로 감지(near_npc==npc)될 때만 shift를 누르고, 아니면 NPC 쪽으로 nudge해 facing을 보정한다.
## shift를 실제로 보냈으면 true.
func _approach_npc_and_interact(level: Level, npc: Node2D) -> bool:
	var player = level.player
	var dx: float = npc.global_position.x - player.global_position.x
	if abs(dx) > STOP_DIST:
		_move_x(int(sign(dx)))
		return false
	# 위치 도달 — facing 방향에 이 NPC가 잡혔을 때만 shift가 대화를 연다.
	if player.near_npc == npc:
		_release_movement()
		_press_shift()
		return true
	# 위치는 맞지만 facing이 어긋나 미감지 → NPC 방향으로 한 칸 이동해 facing 보정.
	var dir := int(sign(dx))
	if dir == 0:
		dir = 1
	_move_x(dir)
	return false


func _tick_going_to_butler(level: Level) -> void:
	# 상태가 바뀌어 더 이상 집사 방문이 필요 없으면 즉시 복귀(무한 방문 방지).
	if not _should_visit_butler():
		_set_phase(Phase.IDLE)
		return
	var butler := _find_npc_by_type(Constants.NpcTypes.BUTLER)
	if not butler:
		_set_phase(Phase.MOVING_TO_DOOR)
		return
	if _approach_npc_and_interact(level, butler):
		_set_phase(Phase.IDLE)  # 대화 트리거 후 IDLE로 복귀(대화는 Dialogic 분기가 처리)


## 챕터6: konial_love_1을 감상한 뒤 코니알과 대화해야 "파주주에 대해" 선택지(konial_talk1)가 뜬다.
func _should_talk_konial() -> bool:
	return MetaProgression.get_current_chapter() == 6 \
		and MetaProgression.has_read_event("konial_love_1") \
		and not MetaProgression.has_read_event("konial_talk1")


## 베이스의 코니알 NPC에게 다가가 말을 건다(→ "파주주에 대해" 선택지는 _PROGRESS_CHOICE_KEYWORDS로 자동 선택).
func _tick_going_to_konial(level: Level) -> void:
	if not _should_talk_konial():
		_set_phase(Phase.IDLE)
		return
	var konial := _find_npc_by_type(Constants.NpcTypes.KONIAL)
	if not konial:
		_set_phase(Phase.MOVING_TO_DOOR)
		return
	if _approach_npc_and_interact(level, konial):
		_set_phase(Phase.IDLE)  # 대화 트리거 후 IDLE로 복귀(선택지는 Dialogic 분기가 처리)


func _tick_opening_shop(level: Level) -> void:
	var butler := _find_npc_by_type(Constants.NpcTypes.BUTLER)
	if not butler:
		_set_phase(Phase.MOVING_TO_DOOR)
		return
	# facing 보정 포함 접근(방향성 TalkArea로 X만 맞고 미감지되어 상점이 안 열리던 챕터5 고착 수정).
	_approach_npc_and_interact(level, butler)


# ── 아이템 구매 ──────────────────────────────────────────

func _get_shop() -> Node:
	var nodes := get_tree().get_root().find_children("Shop", "CanvasLayer", true, false)
	return nodes[0] if not nodes.is_empty() else null


func _handle_shopping() -> void:
	var shop := _get_shop()
	if not shop:
		_set_phase(Phase.IDLE)
		return
	var container := shop.find_child("AbilityContainer", true, false)
	if not container:
		_set_phase(Phase.IDLE)
		return
	# 구매 가능한 아이템들을 모은다.
	var affordable: Array = []
	for child in container.get_children():
		var ab := child as AbilityBox
		if ab and not ab.button.disabled and ab.modulate.a8 >= 255:
			affordable.append(ab)
	if not affordable.is_empty():
		var pick: AbilityBox = affordable[0]
		var picked := false
		# 1순위: 종착점 해금이 필요하면 route 코인을 최우선 구매한다.
		if _is_coin_shop_needed():
			for ab in affordable:
				if ab.upgrade_info is CurrencyShopItem:
					pick = ab
					picked = true
					break
		# 2순위: 테스트 가속 아이템(이속/탐지속도/정념소비).
		if not picked:
			for ab in affordable:
				var info = ab.upgrade_info
				if info and not (info is ShopHint) and info.get("id") in _SPEED_ITEMS:
					pick = ab
					picked = true
					break
		# 3순위: 종착점이 필요하면 힌트 아이템을 구매한다.
		if not picked and _is_destination_needed():
			for ab in affordable:
				if ab.upgrade_info is ShopHint:
					pick = ab
					break
		_shop_exit_pending = false
		pick.button.pressed.emit()
		return
	# 구매 가능한 아이템 없음 — 퀘스트 충족 여부에 따라 분기
	if _shop_exit_pending:
		_press_esc()
		# 티켓 부족으로 못 산 것(어빌리티/힌트/코인)이 남았으면 티켓을 번다(토글 off면 종료).
		if enable_earn_ticket and (_is_shop_needed() or _is_hint_shop_needed() or _is_coin_shop_needed()):
			_set_phase(Phase.EARNING_TICKET)
		else:
			_set_phase(Phase.IDLE)
	else:
		_shop_exit_pending = true


# ── 티켓 획득 ────────────────────────────────────────────

func _tick_earning_ticket(level: Level) -> void:
	if _handle_recollection_select():
		return
	var reina_ero := MetaProgression.get_npc_ero_gage(Constants.NpcTypes.REINA)
	var mai_ero := MetaProgression.get_npc_ero_gage(Constants.NpcTypes.MAI)
	# 정념(ero/lust)이 최대치의 절반 이상 찼을 때만 티켓 획득 free action에 진입한다.
	var ero_threshold: float = Constants.PARTNER_MAX_ERO_GAUGE * 0.5
	if max(reina_ero, mai_ero) < ero_threshold:
		# 치트 토글이 켜져 있으면 정념을 최대치까지 채워 바로 진행한다.
		if enable_ero_cheat:
			var pm := _get_partner_manager()
			if pm:
				pm.set_ero_gage(PartnerManager.NpcType.REINA, Constants.PARTNER_MAX_ERO_GAUGE)
				pm.set_ero_gage(PartnerManager.NpcType.MAI, Constants.PARTNER_MAX_ERO_GAUGE)
				reina_ero = MetaProgression.get_npc_ero_gage(Constants.NpcTypes.REINA)
				mai_ero = MetaProgression.get_npc_ero_gage(Constants.NpcTypes.MAI)
				_log("정념 부족 → 치트로 최대치 충전")
		# 치트가 없거나 실패해 여전히 부족하면 기지를 떠나 스테이지에서 정념을 채운다.
		if max(reina_ero, mai_ero) < ero_threshold:
			_log("정념 절반 미만 → 기지 이탈하여 스테이지 진행")
			_set_phase(Phase.MOVING_TO_DOOR)
			return
	var reina := _find_npc_by_type(Constants.NpcTypes.REINA)
	var mai := _find_npc_by_type(Constants.NpcTypes.MAI)
	var target_npc := reina if reina_ero >= mai_ero else mai
	if not target_npc:
		_set_phase(Phase.MOVING_TO_DOOR)
		return
	var dx := target_npc.global_position.x - level.player.global_position.x
	if abs(dx) <= STOP_DIST:
		_release_movement()
		_press_shift()
	else:
		_move_x(sign(dx))


func _handle_recollection_select() -> bool:
	for node in get_tree().get_root().find_children("*", "RecollectionRect", true, false):
		var rect := node as RecollectionRect
		if not rect or not rect.visible:
			continue
		# H씬 슬롯을 모아 잠기지 않은 것 중 랜덤 선택(첫 슬롯 고정 방지).
		var all_minis: Array = []
		var unlocked: Array = []
		for child in rect.recollection_container.get_children():
			if child is RecollectionButtonMini:
				all_minis.append(child)
				if not (child.lock_screen and child.lock_screen.visible):
					unlocked.append(child)
		var pool: Array = unlocked if not unlocked.is_empty() else all_minis
		if not pool.is_empty():
			pool[randi() % pool.size()].pressed.emit()
		return true  # 창이 열려있으면 항상 true — 대화 진행도 차단
	return false


func _try_select_h_choice() -> bool:
	if not Dialogic.has_subsystem("Choices"):
		return false
	var btn := Dialogic.Choices.get_choice_button_node(1)
	if btn == null or not btn.is_visible_in_tree():
		return false
	var choices: Array = Dialogic.Choices.get_current_question_info().get("choices", [])
	for choice in choices:
		if not choice.get("visible", false) or choice.get("disabled", false):
			continue
		if choice.get("text", "") in _H_CHOICE_TEXTS:
			Dialogic.Choices._choice_blocker.stop()
			Dialogic.Choices._on_choice_selected(choice)
			return true
	return false


# ── 파트너 전환 ───────────────────────────────────────────

func _tick_switching_partner(level: Level) -> void:
	var needed := _get_needed_partner()
	if needed == MetaProgression.get_current_partner():
		_set_phase(Phase.IDLE)
		return
	var target_npc := _find_npc_by_type(needed)
	if not target_npc:
		_set_phase(Phase.MOVING_TO_DOOR)
		return
	var dx := target_npc.global_position.x - level.player.global_position.x
	if abs(dx) <= STOP_DIST:
		_release_movement()
		_press_shift()
	else:
		_move_x(sign(dx))


# ── 문으로 이동 ───────────────────────────────────────────

func _tick_move_to_door(level: Level) -> void:
	if level.doors.is_empty():
		return
	var door := _pick_exit_door(level)
	if not door:
		return
	_move_x(sign(door.global_position.x - level.player.global_position.x))


func _pick_exit_door(level: Level) -> Door:
	for door in level.doors:
		if door.entry_direction == 3:  # west
			return door
	return level.doors[0]


# ── 시그널 핸들러 ─────────────────────────────────────────

func _on_stage_clear() -> void:
	if not active:
		return
	clear_count += 1
	_log("스테이지 클리어 (floor=%d, 누계=%d)" % [stage_count, clear_count])
	Input.action_release("action")
	_set_phase(Phase.IDLE)


func _on_stage_change() -> void:
	if not active:
		return
	_menu_start_requested = false
	_dest_talked = false
	_skip_current_stage = false
	stage_count += 1
	_reset_input()
	_set_phase(Phase.IDLE)
	_ensure_speed_items_equipped()
	if enable_equip_all:
		_equip_max_by_cost()
	_log_quest_status()
	_check_quest_complete()


## 보유 아이템을 장착 코스트 한도 내에서 최대한 장착한다(플레이어가 인벤토리에서 코스트껏 장착하는 것과 동일 결과).
## 코스트 초과는 하지 않으며(can_equip 규칙 준수), 러브 팔찌는 칸칸 네비 충돌로 여기서 다루지 않는다(_ensure_speed_items_equipped가 관리).
func _equip_max_by_cost() -> void:
	var im = get_tree().get_first_node_in_group("inventorymanager")
	if not im or not im.equipment:
		return
	var equip = im.equipment
	var max_cost: int = im.max_cost
	# 실제 장착 목록에서 사용 코스트를 재계산(신뢰 가능한 기준).
	var used := 0
	for it in equip.equipment_list:
		used += it.cost
	for ability_id in MetaProgression.get_save_data_ability().keys():
		if ability_id == _BRACELET_ID:
			continue  # 팔찌는 칸칸 네비 충돌 → 제외
		var item = equip.item_data.get_item(ability_id, ItemData.ItemTypes.ABILITY)
		if not item or equip.has_equip_item(item):
			continue
		if used + item.cost > max_cost:
			continue  # 코스트 초과 → 건너뜀(플레이어도 못 장착)
		equip.add_equip_list(item)
		im.set_current_cost(item.cost)
		used += item.cost
		_log("코스트 장착: %s (cost=%d, 누적 %d/%d)" % [ability_id, item.cost, used, max_cost])


## 테스트 가속: 보유 중인 이속/탐지속도 아이템을 장착(미장착 시).
func _ensure_speed_items_equipped() -> void:
	# 정식 장착 흐름(Equipment.add_equip_list)을 거쳐야 코스트 갱신 + 효과 적용(update_equip_item)이 된다.
	# 단순 MetaProgression.add_equipment()는 저장 배열만 바꿔 효과가 안 걸린다.
	var im = get_tree().get_first_node_in_group("inventorymanager")
	if not im or not im.equipment:
		return
	var equip = im.equipment
	for id in _SPEED_ITEMS:
		if not MetaProgression.has_ability(id):
			continue
		var item = equip.item_data.get_item(id, ItemData.ItemTypes.ABILITY)
		if item and not equip.has_equip_item(item):
			equip.add_equip_list(item)  # 리스트 추가 + 저장 + emit_update_equip_item(효과 적용)
			_log("테스트 가속 아이템 장착: %s" % id)
	# 챕터6+ 러브 팔찌(스토리 지급) 장착/해제.
	# - konchan 트리거(item_konchan) 전: 장착 → 스테이지 클리어마다 코니알 경험치 누적(호감도 파밍).
	# - konchan 트리거 후: 해제 → 팔찌 장착 시 칸칸 네비가 비활성화되므로, engine_room 종착점을
	#   등록하려면 반드시 해제해야 한다.
	if MetaProgression.get_current_chapter() >= _BRACELET_FROM_CHAPTER and MetaProgression.has_ability(_BRACELET_ID):
		var bitem = equip.item_data.get_item(_BRACELET_ID, ItemData.ItemTypes.ABILITY)
		if bitem:
			var konchan_done := MetaProgression.has_read_event("item_konchan")
			if not konchan_done and not equip.has_equip_item(bitem):
				equip.add_equip_list(bitem)
				_log("러브 팔찌 장착(챕터6 호감도 파밍)")
			elif konchan_done and equip.has_equip_item(bitem):
				equip.erase_equip_list(bitem)
				_log("러브 팔찌 해제(konchan 후 engine_room 등록 위해)")


# ── Watchdog ──────────────────────────────────────────────

func _on_watchdog() -> void:
	bug_count += 1
	_log("BUG[%d]: %ds 진행 없음 (phase=%s, game_state=%d)" % [
		bug_count, int(WATCHDOG_TIMEOUT), Phase.keys()[phase], GameEvents.game_state])
	# 이변 탐지/충전 단계에서 멈춘 것이면 클리어 불가 스테이지로 보고 건너뛴다(문으로 재롤).
	if phase == Phase.CHARGING or phase == Phase.MOVING_TO_ANOMALY:
		_skip_current_stage = true
		_log("스테이지 건너뛰기(이변 탐지 불가 추정) — 문으로 재롤")
	_reset_input()
	_set_phase(Phase.IDLE)


# ── 유틸 ──────────────────────────────────────────────────

func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	watchdog_timer = 0.0
	if _panel:
		_panel.update_status(active, Phase.keys()[phase])


func _move_x(dir: float) -> void:
	if dir > 0:
		Input.action_press("move_right")
		Input.action_release("move_left")
	elif dir < 0:
		Input.action_press("move_left")
		Input.action_release("move_right")
	else:
		_release_movement()


func _handle_tutorial() -> void:
	var pages := get_tree().get_root().find_children("*", "TutorialPage", true, false)
	if pages.is_empty():
		return
	var tuto: TutorialPage = pages[0] as TutorialPage
	if not tuto.canvas_layer.visible:
		return
	var panel: TutorialPanel = tuto.tuto_page
	if panel.arrow_next.visible:
		panel.arrow_next.pressed.emit()
	elif panel.confirm_button.visible:
		panel.confirm_button.pressed.emit()


func _get_needed_partner() -> int:
	var qd := _get_quest_data()
	if not qd or qd.total_love <= 0:
		return MetaProgression.get_current_partner()
	var reina := MetaProgression.get_npc_love_level(Constants.NpcTypes.REINA)
	var mai := MetaProgression.get_npc_love_level(Constants.NpcTypes.MAI)
	if reina > mai:
		return Constants.NpcTypes.MAI
	elif mai > reina:
		return Constants.NpcTypes.REINA
	return MetaProgression.get_current_partner()


func _find_npc_by_type(npc_type: int) -> Npc:
	for node in get_tree().get_nodes_in_group("npc"):
		var npc := node as Npc
		if npc and npc.npc_name == npc_type:
			return npc
	return null


func _try_select_shop_choice() -> bool:
	if not Dialogic.has_subsystem("Choices"):
		return false
	var btn := Dialogic.Choices.get_choice_button_node(1)
	if btn == null or not btn.is_visible_in_tree():
		return false
	var choices: Array = Dialogic.Choices.get_current_question_info().get("choices", [])
	for choice in choices:
		if not choice.get("visible", false) or choice.get("disabled", false):
			continue
		if choice.get("text", "") in _SHOP_CHOICE_TEXTS:
			Dialogic.Choices._choice_blocker.stop()
			Dialogic.Choices._on_choice_selected(choice)
			return true
	return false


func _try_select_partner_choice() -> bool:
	if not Dialogic.has_subsystem("Choices"):
		return false
	var btn := Dialogic.Choices.get_choice_button_node(1)
	if btn == null or not btn.is_visible_in_tree():
		return false
	var choices: Array = Dialogic.Choices.get_current_question_info().get("choices", [])
	for choice in choices:
		if not choice.get("visible", false) or choice.get("disabled", false):
			continue
		if choice.get("text", "") in _PARTNER_CHOICE_TEXTS:
			Dialogic.Choices._choice_blocker.stop()
			Dialogic.Choices._on_choice_selected(choice)
			return true
	return false


func _try_select_choice(target_index: int) -> bool:
	if not Dialogic.has_subsystem("Choices"):
		return false
	var btn := Dialogic.Choices.get_choice_button_node(1)
	if btn == null or not btn.is_visible_in_tree():
		return false
	var choices: Array = Dialogic.Choices.get_current_question_info().get("choices", [])
	for choice in choices:
		if not choice.get("visible", false) or choice.get("disabled", false):
			continue
		if target_index != -1 and choice.get("button_index", -1) != target_index:
			continue
		Dialogic.Choices._choice_blocker.stop()
		Dialogic.Choices._on_choice_selected(choice)
		return true
	return false


## 스토리 진행 키워드를 포함한 선택지(예: "파주주가 갇힌 위치를 찾고 싶어")가 있으면 선택한다.
func _try_select_progress_choice() -> bool:
	if not Dialogic.has_subsystem("Choices"):
		return false
	var btn := Dialogic.Choices.get_choice_button_node(1)
	if btn == null or not btn.is_visible_in_tree():
		return false
	var choices: Array = Dialogic.Choices.get_current_question_info().get("choices", [])
	for choice in choices:
		if not choice.get("visible", false) or choice.get("disabled", false):
			continue
		var text: String = str(choice.get("text", ""))
		for kw in _PROGRESS_CHOICE_KEYWORDS:
			if kw in text:
				Dialogic.Choices._choice_blocker.stop()
				Dialogic.Choices._on_choice_selected(choice)
				return true
	return false


func _press_shift() -> void:
	var ev := InputEventAction.new()
	ev.action = "shift"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().create_timer(0.3).timeout
	ev.pressed = false
	Input.parse_input_event(ev)


func _handle_confirm_box() -> bool:
	var nodes := get_tree().get_root().find_children("*", "ConfirmBox", true, false)
	for n in nodes:
		var cb := n as ConfirmBox
		if cb and cb.is_open:
			cb.confirm_button.pressed.emit()
			return true
	return false


func _press_dialogic_action() -> void:
	var ev := InputEventAction.new()
	ev.action = "dialogic_default_action"
	ev.pressed = true
	Input.parse_input_event(ev)


func _release_movement() -> void:
	Input.action_release("move_right")
	Input.action_release("move_left")


func _reset_input() -> void:
	# dialogic_default_action 포함: _press_dialogic_action이 누르기만 하고 해제를 안 해, 봇을 끄면
	# 이 액션이 눌린 채 stuck되어 수동/다음 실행의 대화 넘김 키가 안 먹던 버그 수정.
	for a in ["move_right", "move_left", "move_up", "move_down", "action", "ui_accept", "shift", "dialogic_default_action"]:
		Input.action_release(a)


func _get_quest_data() -> Resource:  # 실제 QuestData. quest_component.gd 참고(4.5 타입체크 우회)
	var ggm := get_tree().get_first_node_in_group("globalgamemanager") as GlobalGameManager
	if not ggm or not ggm.main_quest_component:
		return null
	return ggm.main_quest_component.quest_data


func _check_quest_complete() -> void:
	var ggm := get_tree().get_first_node_in_group("globalgamemanager") as GlobalGameManager
	if not ggm or not ggm.main_quest_component:
		return
	var mqc: MainQuestComponent = ggm.main_quest_component
	if not mqc.quest_data or not mqc.get_is_clear_check():
		return
	_log("퀘스트[%s] 완료." % mqc.quest_data.id)
	_on_quest_complete(mqc.quest_data.id)


func _on_quest_complete(quest_id: String) -> void:
	match quest_id:
		"quest_1":
			pass
		"quest_2":
			pass
		"quest_3":
			pass
		"quest_4":
			pass
		"quest_4_2":
			pass
		"quest_4_3":
			pass
		"quest_5":
			pass
		"quest_5_2":
			pass
		"quest_6":
			pass
		"quest_6_2":
			pass


func _log_quest_status() -> void:
	var ggm := get_tree().get_first_node_in_group("globalgamemanager") as GlobalGameManager
	if not ggm or not ggm.main_quest_component:
		return
	var mqc := ggm.main_quest_component as MainQuestComponent
	if not mqc.quest_data:
		return
	_log("퀘스트[%s] 완료=%s" % [mqc.quest_data.id, str(mqc.get_is_clear_check())])


## [임시 진단] 멈춤 원인 추적용 상태 덤프.
func _log_diag() -> void:
	var tl: String = "null"
	if Dialogic.current_timeline:
		tl = Dialogic.current_timeline.resource_path.get_file()
	var dpaused := "?"
	if Dialogic.has_method("get") :
		dpaused = str(Dialogic.paused)
	var level := _get_level()
	var lv := "null"
	if level:
		lv = "%s(clear=%s,player_in=%s)" % [level.name, str(level.stage_clear), str(level.player.input_enabled) if level.player else "noPlayer"]
	var scene_name := "null"
	if get_tree().current_scene:
		scene_name = get_tree().current_scene.name
	var h_info := ""
	var fac := _get_free_action_component()
	if fac:
		var is_base_h: bool = get_tree().get_first_node_in_group("h_scene_window_component") != null
		h_info = " | H[base=%s gage=%.0f stack=%.1f sp=%d inc=%s lock=%s cum=%s reached90=%s]" % [
			str(is_base_h), fac.current_gage, fac.current_ero_stack, fac.scene_progress,
			str(fac.is_increasing), str(fac.is_input_locked), str(_h_has_cummed), str(_h_reached_90)]
	var q_info := ""
	var qd := _get_quest_data()
	if qd:
		q_info = " | Q[%s dest=%d/%d items=%d/%d need_dest=%s hints=%d]" % [
			qd.id, MetaProgression.get_current_destination_info().size(), qd.collect_destinations,
			MetaProgression.get_save_data_ability().size(), qd.collect_items,
			str(_is_destination_needed()), MetaProgression.get_route_hint_array().size()]
	# [임시 진단] 챕터6 코니알 호감도 이벤트 상태(왜 konial_love_1을 감상 안 하는지 추적).
	var k_info := ""
	if MetaProgression.get_current_chapter() == 6:
		var pm := get_tree().get_first_node_in_group("partnermanager") as PartnerManager
		if pm:
			var kn = pm.partner[Constants.NpcTypes.KONIAL]
			k_info = " | K[lv=%d exp=%d/%d" % [kn.love_level, kn.love_exp, kn.target_love_exp]
			for area in get_tree().get_nodes_in_group("eventcomponent"):
				var ea := area as EventArea
				if ea and ea.h_scene_info and ea.h_scene_info.partner == Constants.NpcTypes.KONIAL:
					k_info += " %s(en=%s pl=%s vis=%s vw=%s)" % [
						ea.h_scene_info.dialog_title, str(ea.event_enabled), str(ea.played),
						str(ea.visible), str(_viewed_love_events.has(ea.h_scene_info.dialog_title))]
			k_info += "]"
	_log("[진단] phase=%s tree_paused=%s D.timeline=%s D.paused=%s game_state=%d scene=%s level=%s%s%s%s" % [
		Phase.keys()[phase], str(get_tree().paused), tl, dpaused, GameEvents.game_state, scene_name, lv, h_info, q_info, k_info])


func _log(msg: String) -> void:
	var line := "[QABot][%s] %s" % [Time.get_datetime_string_from_system(true), msg]
	print(line)
	log_lines.append(line)


func _get_level() -> Level:
	return get_tree().get_first_node_in_group("current_level") as Level


func _get_floor_manager() -> FloorManager:
	return get_tree().get_first_node_in_group("floormanager") as FloorManager


func _get_partner_manager() -> PartnerManager:
	return get_tree().get_first_node_in_group("partnermanager") as PartnerManager


func _get_free_action_component() -> HSceneFreeActionComponent:
	for node in get_tree().get_root().find_children("*", "HSceneFreeActionComponent", true, false):
		var fac := node as HSceneFreeActionComponent
		if fac and fac.is_event:
			return fac
	return null


func _press_esc() -> void:
	var ev := InputEventAction.new()
	ev.action = "esc"
	ev.pressed = true
	Input.parse_input_event(ev)


func _notification(what: int) -> void:
	if not active:
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_log()


func _save_log() -> void:
	_log("=== QABot 종료 (스테이지=%d, 클리어=%d, 버그=%d) ===" % [
		stage_count, clear_count, bug_count])
	var f := FileAccess.open("user://qa_bot_log.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(log_lines))
		f.close()
		print("[QABot] Log: user://qa_bot_log.txt")
