extends GutTest

## 과거 커밋에서 수정된 핵심 버그들을 회귀 테스트한다.
## 각 테스트는 버그가 재발하면 즉시 감지할 수 있도록 실제 수정 조건을 검증한다.

# ==============================================================================
# Bug: CurrentNpc가 hide 상태(run_stage·도주·파트너 비표시)인데 shift로 대화가 걸려
#      게임오버되는 버그 (리포트 #3 인형스테이지 도주, #4 파트너 비표시 스테이지)
# Fix: Player.gd can_talk_to_npc() — near_npc 부모의 visible로 대화 가능 여부 판정
#      (게이팅 로직을 find_target() 인라인에서 술어 함수로 추출)
# Commit: 38c7238 "엔피씨 가려지는 스테이지에서 대화가 되는 버그 수정"
# Note: 실제 Player.can_talk_to_npc()를 호출해 검증한다(동어반복 테스트 아님).
# ==============================================================================

func test_npc_talk_blocked_when_current_npc_hidden():
	# CurrentNpc(부모)가 hide 상태이면 대화가 차단되어야 한다
	var player := Player.new()
	var current_npc_node = Node2D.new()
	var npc_node = Node2D.new()
	add_child_autofree(current_npc_node)
	current_npc_node.add_child(npc_node)

	current_npc_node.visible = false
	assert_false(player.can_talk_to_npc(npc_node),
		"CurrentNpc가 hide일 때 대화가 차단되어야 한다 (#3/#4)")
	player.free()

func test_npc_talk_allowed_when_current_npc_visible():
	# CurrentNpc(부모)가 visible 상태이면 대화가 허용되어야 한다
	var player := Player.new()
	var current_npc_node = Node2D.new()
	var npc_node = Node2D.new()
	add_child_autofree(current_npc_node)
	current_npc_node.add_child(npc_node)

	current_npc_node.visible = true
	assert_true(player.can_talk_to_npc(npc_node),
		"CurrentNpc가 visible일 때 대화가 가능해야 한다")
	player.free()

# ==============================================================================
# Bug: 스테이지 전환 중에도 기지 복귀 입력이 처리되어 중복 전환이 발생하는 버그
# Fix: return_base_component.gd — stage_changing 플래그 및 _can_return_base() 추가
# Commit: 30cd793 "버그 수정"
# ==============================================================================

var return_base: Node

func _make_return_base() -> Node:
	var node = load("res://Gameplay/return_base_component.gd").new()
	add_child_autofree(node)
	return node

func test_cannot_return_base_during_stage_changing():
	# 스테이지 전환 중(stage_changing=true)에는 기지 복귀가 차단되어야 한다
	var component = _make_return_base()
	component.stage_changing = true
	assert_false(component._can_return_base(), "스테이지 전환 중에는 기지 복귀가 차단되어야 한다")

func test_can_return_base_when_idle():
	# 아무 차단 조건이 없을 때는 기지 복귀가 허용되어야 한다.
	# 다른 테스트가 남긴 전역 상태(특히 Dialogic.current_timeline)가 가드를
	# 오작동시키지 않도록 _can_return_base()가 참조하는 전역값을 비차단 상태로 초기화한다.
	GameEvents.is_epilogue_room = false
	GameEvents.game_state = Constants.STATE_NORMAL
	Dialogic.current_timeline = null
	TransitionScreen.is_transition = false
	var component = _make_return_base()
	component.stage_changing = false
	assert_true(component._can_return_base(), "대기 상태에서는 기지 복귀가 허용되어야 한다")

func test_stage_changing_set_on_in_next_stage_signal():
	# in_next_stage 시그널이 오면 stage_changing이 true로 설정되어야 한다
	var component = _make_return_base()
	component.stage_changing = false
	component._on_in_next_stage()
	assert_true(component.stage_changing, "in_next_stage 수신 시 stage_changing이 true여야 한다")

func test_stage_changing_cleared_on_stage_changed_signal():
	# stage_change 시그널이 오면 stage_changing이 false로 해제되어야 한다
	var component = _make_return_base()
	component.stage_changing = true
	component._on_stage_changed()
	assert_false(component.stage_changing, "stage_changed 수신 시 stage_changing이 false여야 한다")

# ==============================================================================
# Bug: 종착점 도달 직전 스테이지에서도 미방문 스테이지가 강제 설정되어
#      종착점이 아닌 스테이지로 이동하는 버그
# Fix: FloorManager.gd — add_clear_stage_stack에 _is_next_complete_stage() 조건 추가
# Commit: dafe291 "버그 및 편의사항 수정"
# ==============================================================================

var floor_manager_instance: FloorManager

func before_each():
	floor_manager_instance = FloorManager.new()

func after_each():
	floor_manager_instance.free()

func test_is_next_complete_stage_at_threshold():
	# current_floor가 complete_stage_num - 1 이상이면 종착점으로 판단해야 한다
	floor_manager_instance.complete_stage_num = 5
	floor_manager_instance.current_floor = 4  # maxi(5-1, 0) = 4
	assert_true(floor_manager_instance._is_next_complete_stage(),
		"종착점 임계값 도달 시 true를 반환해야 한다")

func test_is_not_next_complete_stage_below_threshold():
	# current_floor가 임계값보다 낮으면 종착점이 아니어야 한다
	floor_manager_instance.complete_stage_num = 5
	floor_manager_instance.current_floor = 3
	assert_false(floor_manager_instance._is_next_complete_stage(),
		"임계값 미달 시 false를 반환해야 한다")

func test_is_next_complete_stage_single_stage_chapter():
	# complete_stage_num = 1일 때 maxi(1-1, 0) = 0 이므로 0층부터 종착점이어야 한다
	floor_manager_instance.complete_stage_num = 1
	floor_manager_instance.current_floor = 0
	assert_true(floor_manager_instance._is_next_complete_stage(),
		"1스테이지 챕터에서는 0층부터 종착점이어야 한다")

# ==============================================================================
# Bug: chibi 이상현상의 충돌 영역 Y오프셋이 일반 이상현상과 동일하게 -160으로
#      설정되어 탐지 판정 위치가 잘못되는 버그
# Fix: npc_anomaly.gd — _set_y_offset()에 anomaly_name별 분기 추가
# Commit: dafe291 "버그 및 편의사항 수정"
# ==============================================================================

func test_chibi_anomaly_y_offset_is_30():
	# chibi 이상현상의 충돌 오프셋은 -30이어야 한다
	# _ready()가 호출되지 않도록 트리에 추가하지 않는다
	var anomaly = NpcAnomaly.new()
	anomaly.anomaly_name = "chibi"

	var col = CollisionShape2D.new()
	col.position = Vector2(100, 200)
	anomaly._set_y_offset(col)

	assert_eq(col.position.y, 200.0 - 30.0,
		"chibi 이상현상의 Y오프셋은 -30이어야 한다")

	anomaly.free()
	col.free()

func test_default_anomaly_y_offset_is_160():
	# 일반 이상현상의 충돌 오프셋은 -160이어야 한다
	var anomaly = NpcAnomaly.new()
	anomaly.anomaly_name = "normal_anomaly"

	var col = CollisionShape2D.new()
	col.position = Vector2(100, 200)
	anomaly._set_y_offset(col)

	assert_eq(col.position.y, 200.0 - 160.0,
		"일반 이상현상의 Y오프셋은 -160이어야 한다")

	anomaly.free()
	col.free()

# ==============================================================================
# Bug: 코니알의 호감도가 1에서 더 오르지 않음 (리포트 #17)
# Cause: 코니알은 H이벤트가 아니라 대화창 안에서 레벨업하는데, 이때
#        current_event_love_level이 -1이라 can_love_level_up()이 false를 반환하여
#        레벨업이 차단됨
# Fix: 해당 대화에서 forcefix_current_event_love_level(1)을 호출해 이벤트 레벨을
#      현재 호감도 레벨과 맞춰 레벨업을 허용
# Commit: 92a721a "코니알 호감도 1에서 안오르는 버그 수정"
# ==============================================================================

# can_love_level_up()은 partner[npc_type].love_level만 참조하므로 최소 스텁으로 충분하다.
class FakeNpc:
	var love_level: int = 0

func _make_partner_manager(love_level: int) -> PartnerManager:
	# _ready()를 호출하지 않도록 트리에 추가하지 않는다(오토로드/씬 의존 회피).
	var pm := PartnerManager.new()
	var npc := FakeNpc.new()
	npc.love_level = love_level
	pm.partner = [npc]   # 인덱스 0 = 테스트 대상 NPC
	return pm

func test_love_levelup_blocked_without_event_level():
	# 버그 재현 조건: 이벤트 호감도 레벨이 미지정(-1)이면 레벨업이 차단된다
	var pm := _make_partner_manager(1)
	pm.current_event_love_level = -1
	assert_false(pm.can_love_level_up(0),
		"이벤트 호감도 레벨 미지정 시 레벨업이 차단되어야 한다 (#17 재현 조건)")
	pm.free()

func test_forcefix_enables_dialogue_levelup():
	# 수정 검증: forcefix로 이벤트 레벨을 현재 레벨(1)과 맞추면 레벨업이 허용된다
	var pm := _make_partner_manager(1)
	pm.forcefix_current_event_love_level(1)
	assert_eq(pm.current_event_love_level, 1,
		"forcefix_current_event_love_level가 이벤트 레벨을 설정해야 한다")
	assert_true(pm.can_love_level_up(0),
		"이벤트 레벨==현재 레벨(1)이면 레벨업이 허용되어야 한다 (#17 수정)")
	pm.free()

# ==============================================================================
# Bug: 룰렛 콜라보칸에서 정지 버튼을 빠르게 밟으면 한 슬롯에서 두 번 밟힌 판정 (리포트 #86)
# Fix: roulette.gd button_pressed()에 is_pressed 가드를 추가해 재진입을 차단
# Commit: 4df539a "버그 수정: ... 룰렛 중복입력 ..."
# ==============================================================================

func test_roulette_blocks_double_press():
	# 이미 밟힌 상태(is_pressed=true)에서 다시 button_pressed()를 호출하면
	# slot_stop 시그널이 재발행되지 않아야 한다(중복 판정 방지).
	var roulette = load("res://Gameplay/Levels/roulette.gd").new()
	roulette.is_pressed = true
	watch_signals(roulette)
	roulette.button_pressed()
	assert_signal_not_emitted(roulette, "slot_stop",
		"이미 밟힌 상태에서는 slot_stop이 재발행되지 않아야 한다 (#86)")
	roulette.free()
