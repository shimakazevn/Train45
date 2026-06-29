extends GutTest
## 스테이지 씬 스모크 테스트.
##
## gameplay.tscn을 호스트로 한 번 띄워 FloorManager 등 살아있는 게임 컨텍스트를
## 만든 뒤, Gameplay/Levels/ 의 **일반(stage) 타입** 스테이지 씬을 차례로
## level_holder에 마운트하여 _ready()가 에러 없이 완료되고 트리에 정상 부착되는지
## 검증한다. (base/complete/event/safe 타입은 route_data·챕터 셋업이 필요하므로 1차 제외)
##
## 에디터의 GUT 패널에서 실행하면 각 씬이 실제로 렌더링되므로 눈으로도 확인 가능하다.
## - [member DWELL_SECONDS]를 0보다 크게(예: 0.4) 두면 각 씬을 잠시 머물러 시각 확인.
## - 0이면 프레임만 대기하고 넘어가 빠르게 에러/크래시만 잡는다(기본값).
##
## 주의: 마운트 시 push_error 등 엔진 에러가 나면 GUT 출력/패널에 빨갛게 표시된다.
##       실패가 곧 "씬 깨짐"일 수도, "신규게임 컨텍스트엔 없는 챕터/파트너 상태 의존"일
##       수도 있으므로, 빨간 항목은 직접 확인한다.

const IntegrationHelpers = preload("res://GUT/integration/integration_helpers.gd")
const GAMEPLAY_SCENE := preload("res://Gameplay/gameplay.tscn")
const STAGE_DIR := "res://Gameplay/Levels/"

## 시각 확인용 체류 시간(초). 0이면 프레임만 대기(빠름). >0이면 씬마다 그만큼 머문다.
const DWELL_SECONDS := 0.0
## 씬 _ready/초기화 안정화 대기 프레임 수.
const SETTLE_FRAMES := 8

var _gameplay: Gameplay
var _floor_manager: Node


func before_all() -> void:
	IntegrationHelpers.clear_integration_save_slot()
	MetaProgression.new_game()
	IntegrationHelpers.reset_game_events_for_title()
	_gameplay = GAMEPLAY_SCENE.instantiate() as Gameplay
	add_child(_gameplay)
	await wait_physics_frames(15, "gameplay 호스트 _ready 초기화")
	# 스테이지 _ready가 참조하는 floor_manager.current_level을 갱신하기 위해 캐싱.
	_floor_manager = get_tree().get_first_node_in_group("floormanager")


func after_all() -> void:
	if is_instance_valid(_gameplay):
		_gameplay.free()
	IntegrationHelpers.reset_game_events_for_title()


## Gameplay/Levels/ 의 모든 .tscn 경로를 정렬하여 반환한다.
func _all_stage_paths() -> Array:
	var paths := []
	var dir := DirAccess.open(STAGE_DIR)
	if dir:
		for f in dir.get_files():
			if f.ends_with(".tscn"):
				paths.append(STAGE_DIR + f)
	paths.sort()
	return paths


## 각 스테이지 씬을 살아있는 컨텍스트에 마운트해 초기화가 완료되는지 검증한다.
func test_stage_scene_loads(path = use_parameters(_all_stage_paths())) -> void:
	var packed: PackedScene = load(path)
	assert_not_null(packed, "%s 로드 실패" % path)
	if packed == null:
		return

	var inst = packed.instantiate()   # instantiate()는 _ready를 호출하지 않는다
	# 트리에 넣기 전에 stage_type을 확인해 일반 stage만 1차 검증한다.
	if not (inst is Level) or inst.stage_type != Constants.TYPE_STAGE:
		inst.free()
		pass_test("%s: 일반 stage 타입 아님 → 1차 범위 제외" % path.get_file())
		return

	# 이전 스테이지를 즉시 해제(다음 _ready가 해제된 레벨을 참조하지 않도록).
	if _gameplay.level_holder.get_child_count() > 0:
		var old = _gameplay.level_holder.get_child(0)
		_gameplay.level_holder.remove_child(old)
		old.free()
		await wait_physics_frames(1)

	# _ready가 floor_manager.current_level / gameplay.current_level을 읽으므로 부착 전에 갱신.
	if _floor_manager:
		_floor_manager.current_level = inst
	_gameplay.current_level = inst
	_gameplay.level_holder.add_child(inst)   # 여기서 _ready 실행

	await wait_physics_frames(SETTLE_FRAMES, "%s 초기화" % path.get_file())
	if DWELL_SECONDS > 0.0:
		await wait_seconds(DWELL_SECONDS)
	else:
		await wait_physics_frames(1)

	assert_true(is_instance_valid(inst), "%s 인스턴스가 살아있어야 한다" % path.get_file())
	assert_true(inst.is_inside_tree(), "%s 가 씬 트리에 마운트되어야 한다" % path.get_file())
	assert_eq(_gameplay.current_level, inst, "%s 가 current_level로 설정되어야 한다" % path.get_file())
