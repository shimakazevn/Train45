extends GutTest

## route_map.gd(RouteMap) 노선도 컨트롤러의 격리 가능한 로직을 회귀 테스트한다.
##
## RouteMap은 오토로드(GameEvents/MetaProgression/Dialogic)와 씬트리에 강하게 결합돼 있어
## 전체 씬을 띄운 통합테스트(_ready: await kankan_on + pause_game + 리소스 로드 + 슬롯 16개
## 인스턴스화)는 헤드리스에서 불안정하다. 따라서 _ready()를 호출하지 않도록 .new()로 만든 뒤
## 필요한 노드/필드만 직접 주입해 각 메서드를 실제로 호출하여 검증한다.
##
## floor_manager 의존 로직(set_setting_route/set_base_route)은 FloorManager를 상속한
## FakeFloorManager로 무거운 floor_setting()만 오버라이드하고, SettingRouteManager는
## _ready 없이 .new()로 주입해 실제 노선 확정/복원 로직을 검증한다.
##
## 미커버(입력/UI/씬 인스턴스 의존, 별도 통합테스트 필요):
##   _ready, _process, _input, detail_update, create_routes, exit_anim_start,
##   confirm_unlock, set_route_buy_mode_actived, _grab_focus_set_route(트리 await)

## floor_setting()은 실제로는 전체 층 셋업을 수행하므로, 노선 적용 로직만 격리 검증하기
## 위해 호출 여부만 기록하도록 오버라이드한다.
class FakeFloorManager extends FloorManager:
	var floor_setting_called := false
	var floor_setting_arg = "UNSET"
	func floor_setting(change_floor: Level):
		floor_setting_called = true
		floor_setting_arg = change_floor

var route_map: RouteMap

func before_each():
	# _ready()가 돌지 않도록 트리에 넣지 않는다. onready/export 변수는 null로 남는다.
	route_map = RouteMap.new()

func after_each():
	route_map.free()

# ------------------------------------------------------------------------------
# 잠금 해제 비용
# ------------------------------------------------------------------------------

func test_get_need_unlock_coin_num_is_one():
	assert_eq(route_map.get_need_unlock_coin_num(), 1,
		"노선 잠금 해제 비용은 코인 1개로 고정되어야 한다")

# ------------------------------------------------------------------------------
# 등장 애니메이션 완료 신호
# ------------------------------------------------------------------------------

func test_emit_kankan_on_emits_signal():
	# 등장 애니메이션 메서드 트랙이 호출하는 emit_kankan_on()이 kankan_on을 발행해야 한다.
	watch_signals(route_map)
	route_map.emit_kankan_on()
	assert_signal_emitted(route_map, "kankan_on",
		"emit_kankan_on() 호출 시 kankan_on 신호가 발행되어야 한다")

# ------------------------------------------------------------------------------
# 종착점 슬롯 조회/제거
# ------------------------------------------------------------------------------

func test_get_destination_route_null_when_empty():
	route_map.destination_container = autofree(Panel.new())
	assert_null(route_map.get_destination_route(),
		"종착점 컨테이너가 비어있으면 null을 반환해야 한다")

func test_get_destination_route_returns_child():
	# get_destination_route()의 반환형이 DestinationRect이므로 실제 타입으로 주입한다.
	# current_route를 비워두면 _ready가 onready 노드 접근 전에 반환되어 트리 없이도 안전하다.
	var container: Panel = autofree(Panel.new())
	var child: DestinationRect = autofree(DestinationRect.new())
	container.add_child(child)
	route_map.destination_container = container
	assert_eq(route_map.get_destination_route(), child,
		"종착점 컨테이너에 슬롯이 있으면 첫 자식을 반환해야 한다")

func test_erase_destination_route_frees_child():
	var container: Panel = autofree(Panel.new())
	var child := DestinationRect.new()  # queue_free 대상이므로 autofree로 이중 해제하지 않는다
	container.add_child(child)
	route_map.destination_container = container
	route_map.erase_destination_route()
	assert_true(child.is_queued_for_deletion(),
		"erase_destination_route()는 종착점 슬롯을 해제 예약해야 한다")

func test_erase_destination_route_safe_when_empty():
	# 종착점이 없을 때 제거를 호출해도 예외가 없어야 한다(get_destination_route null 가드).
	route_map.destination_container = autofree(Panel.new())
	route_map.erase_destination_route()
	assert_eq(route_map.destination_container.get_child_count(), 0,
		"비어있는 상태에서 erase를 호출해도 안전해야 한다")

# ------------------------------------------------------------------------------
# 출발 버튼 상태
# ------------------------------------------------------------------------------

func test_check_route_start_button_enables():
	var start_button: Button = autofree(Button.new())
	start_button.disabled = true
	route_map.route_start = start_button
	route_map.check_route_start_button()
	assert_false(start_button.disabled,
		"check_route_start_button()은 출발 버튼을 활성화해야 한다")

# ------------------------------------------------------------------------------
# 노선 대기열 추가 가드 (중복 방지 / 최대 개수 제한)
# ------------------------------------------------------------------------------

func test_append_route_set_list_blocks_duplicate():
	# 이미 대기열에 있는 경로는 다시 추가되지 않아야 한다(중복 추가 방지).
	route_map.route_set_container = autofree(HBoxContainer.new())
	route_map.route_set_list = ["res://Gameplay/Levels/stage_a.tscn"]

	var slot: RouteSlot = autofree(RouteSlot.new())
	slot.route_path = "res://Gameplay/Levels/stage_a.tscn"
	route_map.append_route_set_list(slot)

	assert_eq(route_map.route_set_container.get_child_count(), 0,
		"중복 경로는 대기열 컨테이너에 추가되지 않아야 한다")
	assert_eq(route_map.route_set_list.size(), 1,
		"중복 경로는 대기열 목록에 추가되지 않아야 한다")

func test_append_route_set_list_blocks_when_full():
	# 대기열이 MAX_ROUTE_COUNT에 도달하면 더 이상 추가되지 않아야 한다.
	var container: HBoxContainer = autofree(HBoxContainer.new())
	for i in Constants.MAX_ROUTE_COUNT:
		container.add_child(Control.new())  # 부모(container) 해제 시 함께 해제됨
	route_map.route_set_container = container
	route_map.route_set_list = []

	var slot: RouteSlot = autofree(RouteSlot.new())
	slot.route_path = "res://Gameplay/Levels/stage_new.tscn"
	route_map.append_route_set_list(slot)

	assert_eq(container.get_child_count(), Constants.MAX_ROUTE_COUNT,
		"대기열이 가득 차면 새 노선이 추가되지 않아야 한다")
	assert_false(route_map.route_set_list.has("res://Gameplay/Levels/stage_new.tscn"),
		"가득 찬 대기열에는 경로가 목록에 추가되지 않아야 한다")

# ------------------------------------------------------------------------------
# 코인 라벨 갱신
# ------------------------------------------------------------------------------

func test_update_my_coin_noop_when_buy_mode_inactive():
	# 구매 모드 비활성 시 라벨을 건드리지 않고 즉시 반환해야 한다(라벨 null이어도 안전).
	route_map.active_route_buy_mode = false
	route_map.update_my_coin()
	assert_false(route_map.active_route_buy_mode,
		"구매 모드 비활성 상태에서 update_my_coin()은 아무 작업도 하지 않아야 한다")

func test_update_my_coin_formats_label_when_active():
	route_map.active_route_buy_mode = true
	var coin_label: Label = autofree(Label.new())
	route_map.my_coin_label = coin_label
	route_map.update_my_coin()
	assert_eq(coin_label.text, "x" + str(MetaProgression.get_route_coin()),
		"구매 모드 활성 시 보유 코인 수를 'x<코인>' 형식으로 표시해야 한다")

# ------------------------------------------------------------------------------
# 노선 확정 (set_setting_route) — FakeFloorManager + 실제 SettingRouteManager
# ------------------------------------------------------------------------------

## set_setting_route 테스트용 환경(가짜 플로어 매니저 + 노선 매니저)을 구성해 route_map에 주입한다.
func _setup_floor_manager() -> FakeFloorManager:
	var fm := FakeFloorManager.new()
	var srm := SettingRouteManager.new()  # _ready 미실행: setting_route/base는 빈 상태로 시작
	fm.setting_route_manager = srm
	autofree(srm)
	autofree(fm)
	route_map.floor_manager = fm
	return fm

func test_set_setting_route_appends_normal_complete_when_no_destination():
	# 종착점이 없으면 대기열 노선 뒤에 해당 챕터의 일반 종착점이 붙어야 한다.
	var fm := _setup_floor_manager()
	route_map.destination_container = autofree(Panel.new())  # 종착점 슬롯 없음
	route_map.route_set_list = ["res://Gameplay/Levels/stage_a.tscn"]

	route_map.set_setting_route()

	var expected_complete := RouteData.get_complete_stage(MetaProgression.get_current_chapter())
	assert_eq(fm.setting_route_manager.setting_route,
		["res://Gameplay/Levels/stage_a.tscn", expected_complete],
		"종착점이 없으면 노선 끝에 일반 종착점이 추가되어야 한다")
	assert_eq(fm.setting_route_manager.get_setting_route_base(),
		["res://Gameplay/Levels/stage_a.tscn"],
		"종착점을 제외한 노선 원본이 base에 저장되어야 한다")
	assert_true(fm.floor_setting_called,
		"노선 적용 후 floor_setting()이 호출되어야 한다")

func test_set_setting_route_appends_destination_when_present():
	# 종착점 슬롯이 있으면 그 경로가 노선 끝에 붙어야 한다.
	var fm := _setup_floor_manager()
	var container: Panel = autofree(Panel.new())
	var dest := DestinationRect.new()  # 부모(container) 해제 시 함께 해제됨
	dest.route_path = "res://Gameplay/Levels/stage_dest.tscn"
	container.add_child(dest)
	route_map.destination_container = container
	route_map.route_set_list = ["res://Gameplay/Levels/stage_a.tscn"]

	route_map.set_setting_route()

	assert_eq(fm.setting_route_manager.setting_route,
		["res://Gameplay/Levels/stage_a.tscn", "res://Gameplay/Levels/stage_dest.tscn"],
		"종착점이 있으면 그 경로가 노선 끝에 추가되어야 한다")
	assert_true(fm.floor_setting_called,
		"노선 적용 후 floor_setting()이 호출되어야 한다")

# ------------------------------------------------------------------------------
# 노선 복원 (set_base_route)
# ------------------------------------------------------------------------------

func test_set_base_route_noop_when_base_empty():
	# 저장된 base 노선이 없으면 대기열을 건드리지 않고 반환해야 한다.
	_setup_floor_manager()  # setting_route_base = []
	route_map.route_set_container = autofree(HBoxContainer.new())
	route_map.set_base_route()
	assert_eq(route_map.route_set_container.get_child_count(), 0,
		"저장된 노선이 없으면 대기열에 아무것도 복원되지 않아야 한다")

func test_set_base_route_restores_saved_route():
	# 저장된 base 노선의 경로와 일치하는 슬롯이 대기열에 복원되어야 한다.
	var fm := _setup_floor_manager()
	fm.setting_route_manager.setting_route_base = ["res://Gameplay/Levels/stage_a.tscn"]

	# set_base_route가 참조/주입하는 노드들 구성
	route_map.route_set_container = autofree(HBoxContainer.new())
	route_map.route_set_scene = load("res://Gameplay/Ui/route_set_button.tscn") as PackedScene
	route_map.route_start = autofree(Button.new())
	route_map.route_data = RouteData.new()
	route_map.destination_container = autofree(Panel.new())

	# 발견 노선 컨테이너에 일치하는 RouteSlot 하나 배치(실제 프리팹으로 _ready 정상 동작)
	var route_container: GridContainer = autofree(GridContainer.new())
	var slot := (load("res://Gameplay/Ui/route_slot.tscn") as PackedScene).instantiate() as RouteSlot
	slot.route_path = "res://Gameplay/Levels/stage_a.tscn"
	route_container.add_child(slot)
	route_map.route_container = route_container

	route_map.set_base_route()

	assert_eq(route_map.route_set_list, ["res://Gameplay/Levels/stage_a.tscn"],
		"저장된 노선이 대기열 목록에 복원되어야 한다")
	assert_eq(route_map.route_set_container.get_child_count(), 1,
		"저장된 노선 슬롯이 대기열 컨테이너에 추가되어야 한다")
