extends GutTest
## 주요 UI 씬 스모크 테스트.
##
## 상점/칸칸네비(route_map)/세이브 등 주요 UI 씬과 핵심 컴포넌트를 CanvasLayer 호스트에
## 마운트하여 _ready()가 에러 없이 초기화되는지 검증한다. GUT 9.5는 마운트 중 엔진 에러를
## Unexpected Errors로 자동 실패 처리하므로, 구조 assert + 에러 감지가 함께 동작한다.
##
## 에디터의 GUT 패널에서 실행하면 각 UI가 실제로 렌더링되어 눈으로도 확인 가능하다.
## DWELL_SECONDS를 0보다 크게 두면 각 UI를 잠시 머물러 시각 확인할 수 있다.
##
## 주의: UI마다 의존 컨텍스트가 다르다. 일부(shop 등)는 특정 부모/매니저나 게임 상태를
##       전제하므로, 신규게임 컨텍스트만으로는 실패할 수 있다. 빨간 항목은 "씬 깨짐"인지
##       "컨텍스트 부족"인지 직접 확인한다.

const IntegrationHelpers = preload("res://GUT/integration/integration_helpers.gd")

## 시각 확인용 체류 시간(초). 0이면 프레임만 대기(빠름).
const DWELL_SECONDS := 0.0
## _ready 안정화 대기 프레임 수.
const SETTLE_FRAMES := 6

# 검증 대상 UI 씬 — 주요 화면 + 핵심 컴포넌트.
const UI_SCENES := [
	"res://Gameplay/main_menu.tscn",
	"res://Gameplay/options_menu.tscn",
	"res://Gameplay/load_menu.tscn",
	"res://Gameplay/pause_menu.tscn",
	"res://scene/shop.tscn",
	"res://Gameplay/route_map.tscn",
	"res://scene/UI/save_slot.tscn",
	"res://Gameplay/Ui/inventory.tscn",
	"res://scene/UI/confirm_box.tscn",
	"res://scene/UI/notion_panel.tscn",
	"res://scene/UI/life_ball.tscn",
	"res://scene/UI/love_progress_bar.tscn",
]

var _host: CanvasLayer


func before_all() -> void:
	IntegrationHelpers.clear_integration_save_slot()
	MetaProgression.new_game()
	IntegrationHelpers.reset_game_events_for_title()
	_host = CanvasLayer.new()
	add_child(_host)


func after_all() -> void:
	if is_instance_valid(_host):
		_host.free()
	get_tree().paused = false
	IntegrationHelpers.reset_game_events_for_title()


func after_each() -> void:
	# 일부 UI(shop 등)는 _ready에서 get_tree().paused = true로 트리를 멈추므로 복구한다.
	get_tree().paused = false


func test_ui_scene_loads(path = use_parameters(UI_SCENES)) -> void:
	var packed: PackedScene = load(path)
	assert_not_null(packed, "%s 로드 실패" % path)
	if packed == null:
		return

	var inst = packed.instantiate()
	_host.add_child(inst)   # 여기서 _ready 실행
	await wait_physics_frames(SETTLE_FRAMES, "%s 초기화" % path.get_file())
	if DWELL_SECONDS > 0.0:
		await wait_seconds(DWELL_SECONDS)

	assert_true(is_instance_valid(inst), "%s 인스턴스가 살아있어야 한다" % path.get_file())
	assert_true(inst.is_inside_tree(), "%s 가 씬 트리에 마운트되어야 한다" % path.get_file())

	if is_instance_valid(inst):
		inst.free()
