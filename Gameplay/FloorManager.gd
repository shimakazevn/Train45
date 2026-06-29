extends Node
class_name FloorManager

## [KR] 층(스테이지) 진행 관리자.
## [EN] Floor (stage) progression manager.
##
## [KR] 플레이어의 스테이지 이동, 노선 선택, 클리어 스택 관리를 담당한다.
## [EN] Handles player stage movement, route selection, and clear stack management.
## [KR] [SettingRouteManager]를 통한 지정 루트와 랜덤 루트 모두 지원하며,
## [EN] Supports both designated routes via [SettingRouteManager] and random routes,
## [KR] 종착점 도달 시 메타 프로그레션 데이터를 갱신한다.
## [EN] and updates meta-progression data upon reaching the destination.

## [KR] 클리어 스택이 변경될 때 발생한다.
## [EN] Emitted when the clear stack changes.
signal clear_stack_update()
## [KR] 층이 변경될 때 [param level]과 함께 발생한다.
## [EN] Emitted with [param level] when the floor changes.
signal floor_changed(level: Level)

## [KR] 글로벌 게임 매니저 참조
## [EN] Reference to the global game manager
var global_game_manager : GlobalGameManager
## [KR] 이벤트 층 관리자 노드
## [EN] Event floor manager node
@onready var event_floor_manager = $EventFloorManager
## [KR] 노선 설정 관리자 노드
## [EN] Route setting manager node
@onready var setting_route_manager: SettingRouteManager = $SettingRouteManager
## [KR] 층 힌트 관리자 노드
## [EN] Floor hint manager node
@onready var floor_hint_manager: FloorHintManager = $FloorHintManager

## [KR] 스테이지 클리어 이펙트
## [EN] Stage clear effect
@onready var clear_effect = %ClearEffect

## [KR] 현재 플레이의 노선 데이터
## [EN] Route data for the current play session
var route_data := RouteData.new()
## [KR] 챕터 정보 (목표 스테이지 수 등)
## [EN] Chapter info (target stage count, etc.)
var chapter_info := ChapterInfo.new()
## [KR] 현재 층 번호 (0부터 시작)
## [EN] Current floor number (starts from 0)
var current_floor := 0
## [KR] 종착점까지 필요한 스테이지 수
## [EN] Number of stages required to reach the destination
var complete_stage_num := 1
## [KR] 현재 활성화된 레벨
## [EN] Currently active level
var current_level : Level
## [KR] 현재 스테이지 타입 ([code]Constants.TYPE_*[/code])
## [EN] Current stage type ([code]Constants.TYPE_*[/code])
var current_stage_type : int
## [KR] 현재 프롤로그 스테이지 여부
## [EN] Whether the current stage is a prologue stage
var current_prologue := false
## [KR] 현재 스테이지의 부가 정보
## [EN] Extra info for the current stage
var current_stage_extra_info := ""
## [KR] 종착점(TYPE_COMPLETE) 도달 시 해당 챕터 번호
## [EN] Chapter number when reaching the destination (TYPE_COMPLETE)
var current_complete_chapter : int
## [KR] 현재 이변(anomaly) Area2D 참조
## [EN] Reference to the current anomaly Area2D
var current_anomaly : Area2D
## [KR] 다음 스테이지 씬 경로
## [EN] Scene path for the next stage
var next_stage_path : String

## [KR] 연속 클리어 스택 (미방문 스테이지 유도에 사용)
## [EN] Consecutive clear stack (used to guide to unvisited stages)
var clear_stage_stack: int = 0
## [KR] 미방문 스테이지가 설정되었는지 여부
## [EN] Whether an unvisited stage has been set
var unvisit_stage_setted: bool = false
## [KR] 클리어한 스테이지 경로 목록
## [EN] List of cleared stage paths
var clear_stage_list = []

## [KR] 테스트용 스테이지 선택 기록
## [EN] Stage selection records for testing
var test_pick_stage_list = []

## [KR] 호감도 이벤트 잠금 여부
## [EN] Whether the affection event is locked
var current_love_event_lock = false
## [KR] 현재 이변 발견 여부
## [EN] Whether the current anomaly has been found
var current_anomaly_find := false
## [KR] 안전 스테이지 출현 확률 (0.0~1.0)
## [EN] Safe stage appearance probability (0.0~1.0)
@export_range(0.0, 1.0) var safe_stage_percent : float = 0.1
## [KR] 디버그용 테스트 씬 이름
## [EN] Test scene name for debugging
@export var test_scene_name := "stage_0"


## [KR] 초기화 시 [GlobalGameManager] 참조를 획득하고 챕터 변경 시그널을 연결한다.
## [EN] On initialization, acquires [GlobalGameManager] reference and connects the chapter change signal.
func _ready():
	global_game_manager = get_tree().get_first_node_in_group("globalgamemanager") as GlobalGameManager
	GameEvents.set_chapter.connect(_on_set_chapter)
	route_data.route_append(MetaProgression.get_current_chapter())


## [KR] 새로운 층(스테이지)으로 전환할 때 호출된다.
## [EN] Called when transitioning to a new floor (stage).
## [KR] 노선 경로를 갱신하고, 종착점 도달 시 메타 프로그레션 데이터를 저장한다.
## [EN] Updates route path and saves meta-progression data upon reaching the destination.
## [KR] [signal floor_changed] 시그널을 발생시킨 뒤 [method floor_setting]으로 다음 스테이지를 준비한다.
## [EN] Emits [signal floor_changed] signal then prepares the next stage via [method floor_setting].
func floor_change(change_floor : Level) -> void:
	if change_floor.stage_type != Constants.TYPE_BASE:
		setting_route_manager.popout_route_path()
	if change_floor.stage_type == Constants.TYPE_BASE:
		setting_route_manager.set_routes(change_floor.stage_type)
	## [KR] 종착점 스테이지일 경우: 노선 해제 및 방문 기록 저장
	## [EN] When at destination stage: release routes and save visit records
	if change_floor.stage_type == Constants.TYPE_COMPLETE:
		## [KR] 종착점에 도착했으므로 현재 메타데이터에 저장된 노선들 전부 해제
		## [EN] Arrived at destination, so release all routes stored in current metadata
		MetaProgression.clear_setting_routes()
		MetaProgression.clear_kankan_destination()
		setting_route_manager.clear_current_destination()
		## [KR] 세이브 데이터에 방문한 종착점 저장
		## [EN] Save visited destination to save data
		if not MetaProgression.has_visited_destination_route(change_floor.get_scene_file_path()): # [KR] 최초 1회 방문시 코스트 업 / [EN] Cost up on first visit
			if change_floor.destination_info != {}:
				if change_floor.destination_info["cost_reward"] != null:
					_delay_add_extra_cost(change_floor.destination_info["cost_reward"])
		MetaProgression.set_current_destination_info(change_floor.get_scene_file_path(), route_data.get_destination_data(change_floor))
		MetaProgression.set_game_complete_count_up() # [KR] 게임 클리어 횟수 1회 추가 / [EN] Increment game clear count by 1
	
	floor_hint_manager.set_current_stage_hint(change_floor)
	current_level = change_floor
	floor_changed.emit(change_floor)
	var current_level_title:String = tr(route_data.get_route_title(change_floor))
	print("[FloorManager] floor change -> %s %s" % [get_stage_path(change_floor), current_level_title])
	#print("current floor = " + str(current_floor))
	floor_setting(change_floor)

## [KR] 종착점 최초 방문 시 보상 코스트를 지연 지급한다 (연출 대기 2초).
## [EN] Delays granting reward cost on first destination visit (2-second delay for presentation).
func _delay_add_extra_cost(cost_reward):
	await get_tree().create_timer(2.0).timeout
	_add_extra_cost(cost_reward)

## [KR] 다음 스테이지 경로를 결정한다.
## [EN] Determines the next stage path.
## [KR] 칸칸네비로 루트가 지정된 경우 해당 경로를, 아니면 [method floor_normal_setting]으로 랜덤 결정한다.
## [EN] Uses the designated path if a route is set via KankanNavi, otherwise randomly determines via [method floor_normal_setting].
func floor_setting(change_floor : Level) :
	if setting_route_manager.setting_route_on(): # [KR] 칸칸네비로 루트 지정했을 때 / [EN] When a route is set via KankanNavi
		next_stage_path = setting_route_manager.pick_route_path()
		# [KR] 원본(base)은 남아있으나 소비용 노선(setting_route)이 비어 빈 경로가 반환되는 경우.
		#      pick_next_stage 치트 등으로 next_stage_path가 setting_route를 우회해 소비되면 둘이 어긋난다.
		#      빈 경로로 진행하면 차량 이동(층 전환)이 멈춰 진행불능이 되므로 일반 선택으로 폴백한다.
		if next_stage_path == "":
			floor_normal_setting(change_floor)
		else:
			print("[FloorManager] Next stage selected: kankan -> %s" % next_stage_path.get_file().get_basename())
	else: # [KR] 완전 랜덤하게 노선도 설정 / [EN] Set route completely randomly
		floor_normal_setting(change_floor)
		
	#print(test_pick_stage_list) #이변이 나타났는지 안나타났는지 여부를 모아놓은 리스트
	if change_floor == null:
		push_warning("change_floor = null")
		return
	current_stage_type = change_floor.stage_type
	current_prologue = change_floor.prologue_stage
	current_stage_extra_info = change_floor.extra_info
	current_complete_chapter = change_floor.current_chapter

## [KR] 노선이 지정되지 않은 경우의 다음 스테이지 결정 로직.
## [EN] Next stage determination logic when no route is designated.
## [KR] 종착점 > 호감도 이벤트 > 안전 스테이지 > 랜덤 스테이지 순으로 우선순위를 적용한다.
## [EN] Applies priority in order: destination > affection event > safe stage > random stage.
func floor_normal_setting(change_floor: Level):
	if _is_next_complete_stage(): # [KR] 현재 종착점인지 / [EN] Whether it's the destination
		pick_complete_stage(MetaProgression.get_current_chapter())
		print("[FloorManager] Next stage selected: complete")
	elif randf() < 1.0 and current_love_event_lock: # [KR] 호감도 가득 찼으면 h이벤트 스테이지 이동 / [EN] Move to H-event stage if affection is full
		pick_love_stage()
		print("[FloorManager] Next stage selected: love_event")
	elif randf() < safe_stage_percent: # [KR] 일정 확률로 안전 스테이지 이동 / [EN] Move to safe stage with a certain probability
		pick_safe_stage()
		print("[FloorManager] Next stage selected: safe")
		test_pick_stage_list.append("O")
	else: # [KR] 랜덤 스테이지 이동 / [EN] Move to random stage
		pick_stage(change_floor)
		print("[FloorManager] Next stage selected: random -> %s" % next_stage_path.get_file().get_basename())
		test_pick_stage_list.append("X")

## [KR] 현재 층이 종착점에 도달할 차례인지 판별한다.
## [EN] Determines whether the current floor is due to reach the destination.
func _is_next_complete_stage()-> bool:
	if current_floor >= maxi(complete_stage_num-1, 0):
		return true
	else:
		return false

## [KR] 현재 런에서 방문하지 않은 TYPE_STAGE가 하나라도 있는지 확인한다.
## [EN] Returns true if at least one unvisited TYPE_STAGE exists in the current run.
func _has_unvisited_stage() -> bool:
	var visited_stages: Dictionary = MetaProgression.get_routes_dict()
	for stage_path in route_data.current_routes.keys():
		if route_data.has_route_basename(stage_path.get_file().get_basename()):
			if not visited_stages.has(stage_path):
				return true
	print("route all find")
	return false

## [KR] 현재 층 번호를 1 증가시킨다.
## [EN] Increments the current floor number by 1.
func floor_up() -> void:
	current_floor += 1

## [KR] 스테이지 클리어 시 호출된다. 클리어 이펙트를 재생하고 클리어 기록을 갱신한다.
## [EN] Called when a stage is cleared. Plays the clear effect and updates the clear record.
func stage_clear(stage : Level):
	current_anomaly_find = true
	clear_effect.visible = true
	clear_effect.animation_player.play("idle")
	clear_stage_list.append(get_stage_path(stage))
	route_data.add_find_stage_metadata(stage)
	
	stage.stage_clear = true
	
	#print(clear_stage_list)

## [KR] [member clear_stage_list]를 초기화한다.
## [EN] Clears [member clear_stage_list].
func stage_clear_list_remove():
	clear_stage_list.clear()
	#print(clear_stage_list)

## [KR] [param stage_name]을 기반으로 [member next_stage_path]를 설정한다.
## [EN] Sets [member next_stage_path] based on [param stage_name].
## [KR] 디버그 모드 시 [member test_scene_name]을 대신 사용한다.
## [EN] Uses [member test_scene_name] instead in debug mode.
func set_next_stage_path(stage_name: String):
	if Constants.FLOOR_MANAGER_ROUTE_DEBUG:
		push_warning("현재 디버그 모드로 경로를 수동 설정했습니다.")
		next_stage_path = "res://Gameplay/Levels/" + test_scene_name + ".tscn"
	else:
		next_stage_path = "res://Gameplay/Levels/" + stage_name + ".tscn"

## [KR] 랜덤으로 다음 스테이지를 선택한다.
## [EN] Randomly selects the next stage.
## [KR] [param should_pick_unvisit_stage]가 [code]true[/code]이면 미방문 스테이지만 선택 대상으로 한다.
## [EN] If [param should_pick_unvisit_stage] is [code]true[/code], only unvisited stages are considered.
## [KR] 최대 100회 시도하여 이전 스테이지/클리어 스테이지와 중복되지 않는 경로를 찾는다.
## [EN] Attempts up to 100 times to find a path that doesn't overlap with previous/cleared stages.
func pick_stage(change_floor: Level, should_pick_unvisit_stage: bool = false):
	var befor_stage_name = get_stage_path(change_floor)
	var current_route_keys = route_data.current_routes.keys()

	var stage_path := ""
	var stage_file_basename := ""
	
	# [KR] 방문 기록 딕셔너리 불러오기 (키들이 방문한 스테이지 경로)
	# [EN] Load visit history dictionary (keys are visited stage paths)
	var visited_stages: Dictionary = MetaProgression.get_routes_dict()
	
	var found := false
	var attempts:= 0
	while attempts < 100:
		attempts += 1

		var rand_index = randi_range(0, current_route_keys.size() - 1)
		stage_path = current_route_keys[rand_index]
		stage_file_basename = stage_path.get_file().get_basename()

		var is_type_stage := false
		if route_data.has_route_basename(stage_file_basename):
			is_type_stage = true

		# [KR] 방문 여부 체크
		# [EN] Check visit status
		var is_visited := visited_stages.has(stage_path)

		# [KR] 기본 조건
		# [EN] Base conditions
		var valid := stage_file_basename != befor_stage_name \
			and not clear_stage_list.has(stage_file_basename) \
			and is_type_stage

		# [KR] 추가 조건: unvisited 옵션이 true면, 방문하지 않은 스테이지만 허용
		# [EN] Additional condition: if unvisited option is true, only allow unvisited stages
		if should_pick_unvisit_stage:
			valid = valid and not is_visited

		if valid:
			found = true
			break  # [KR] 조건 만족 → 루프 탈출 / [EN] Condition met → exit loop

	# [KR] 미발견 칸만 찾으려 했으나 모두 방문한 경우, 일반 랜덤으로 폴백
	# [EN] If only unvisited stages were sought but all are visited, fall back to normal random
	if should_pick_unvisit_stage and not found:
		pick_stage(change_floor, false)
		return

	set_next_stage_path(stage_file_basename)

## [KR] 안전 스테이지([code]stage_safe_0[/code])를 다음 경로로 설정한다.
## [EN] Sets the safe stage ([code]stage_safe_0[/code]) as the next path.
func pick_safe_stage():
	# [KR] 안전한 스테이지 경로 설정 (set_next_stage_path 함수 사용)
	# [EN] Set safe stage path (using set_next_stage_path function)
	set_next_stage_path("stage_safe_0")

## [KR] 호감도 이벤트 스테이지를 다음 경로로 설정한다.
## [EN] Sets the affection event stage as the next path.
func pick_love_stage():
	var current_love_stage = event_floor_manager.current_love_stage_path
	if current_love_stage == "":
		printerr("Empty")
	set_next_stage_path(current_love_stage)

## [KR] 노선 미지정 상태에서 종착점에 도달했을 때 이동할 스테이지를 설정한다.
## [EN] Sets the stage to move to when reaching the destination without a designated route.
func pick_complete_stage(current_chapter: int):
	set_next_stage_path(RouteData.get_complete_stage_name(current_chapter))

## [KR] 문을 통과하여 다음 스테이지로 이동할 때 호출된다.
## [EN] Called when moving to the next stage through a door.
## [KR] 스테이지 미클리어 시 라이프를 차감하고, 라이프가 0이면 기지(base)로 복귀한다.
## [EN] Deducts life if the stage is not cleared; returns to base if life reaches 0.
## [KR] 다음 스테이지 씬 경로를 반환한다.
## [EN] Returns the next stage scene path.
func into_next_door(stage : Level) -> String:
	if stage.stage_clear == false && current_stage_type != Constants.TYPE_BASE:
		global_game_manager.set_life(-1)
		print("[FloorManager] HP decreased -> HP: %d (stage not cleared)" % global_game_manager.life)
		if global_game_manager.life <= 0:
			current_floor = 0
			print("[FloorManager] HP 0 -> forced return to base")
			next_stage_path = "res://Gameplay/Levels/base_0.tscn"
			# [KR] 이 강제 복귀는 find_faild 텔레포트 funnel을 타지 않으므로 복귀 SE를 직접 재생한다.
			#      (오토로드 SoundManager로 재생해 씬 전환에도 끊기지 않음)
			SoundManager.play_sfx(UiSoundStreamPlayer.RETURN_TO_START_POINT)
		else:
			# [KR] 생명이 남았다 = 미클리어로 칸을 넘기며 기회를 1 잃음(LIFE_UP 장착 중 첫 실패).
			#      플레이어 노드는 곧 씬 전환으로 해제되므로, 오토로드 SoundManager에서 효과음을 재생한다.
			# [EN] Life remains = a chance lost by passing the stage uncleared (first failure with LIFE_UP).
			#      The player node is freed by the upcoming scene transition, so play via the SoundManager autoload.
			SoundManager.play_sfx(UiSoundStreamPlayer.FAIL_TO_FIND_ABNORMALITY)
	else:
		if current_stage_type == Constants.TYPE_SAFE:
			GameEvents.emit_stage_clear()
		floor_up()
	
	if unvisit_stage_setted:
		init_unvisit_stage_setted()
	current_anomaly_reset()
	
	return next_stage_path

## [KR] 기지(base) 스테이지로 강제 복귀시킨다. 층 번호를 초기화한다.
## [EN] Forces return to the base stage. Resets the floor number.
func stage_path_return_base(_stage) -> String:
	if current_stage_type != Constants.TYPE_BASE:
		current_floor = 0
	next_stage_path = "res://Gameplay/Levels/base_0.tscn"
	current_anomaly_reset()
	return next_stage_path


## [KR] 이변 발견 상태를 초기화한다.
## [EN] Resets the anomaly discovery state.
func current_anomaly_reset():
	current_anomaly_find = false


## [KR] [param stage]의 씬 파일 경로에서 파일명(확장자 제외)을 추출하여 반환한다.
## [EN] Extracts and returns the file name (without extension) from [param stage]'s scene file path.
func get_stage_path(stage: Level) -> String:
	var stage_file_basename = stage.get_scene_file_path().get_file().get_basename()  # [KR] stage의 파일명 추출 / [EN] Extract stage file name
	return stage_file_basename

## [KR] 챕터 변경 시그널 핸들러. 종착점 스테이지 수를 갱신하고 노선 데이터에 추가한다.
## [EN] Chapter change signal handler. Updates destination stage count and appends to route data.
func _on_set_chapter(next_chapter: int):
	set_complete_stage_num(next_chapter)
	route_data.route_append(next_chapter)

## [KR] [param next_chapter]에 해당하는 목표 스테이지 수를 [member complete_stage_num]에 설정한다.
## [EN] Sets the target stage count for [param next_chapter] to [member complete_stage_num].
func set_complete_stage_num(next_chapter: int):
	complete_stage_num = chapter_info.get_chapter_goal(next_chapter)

## [KR] 클리어 스택을 누적하고, 임계값 도달 시 미방문 스테이지를 다음 목적지로 설정한다.
## [EN] Accumulates the clear stack, and sets an unvisited stage as the next destination upon reaching the threshold.
## [KR] 노선이 지정된 상태면 스택을 초기화한다.
## [EN] Resets the stack if a route is designated.
func add_clear_stage_stack(unvisit_on_need_stack: int):
	if setting_route_manager.get_setting_route().size() > 0:
		clear_stage_stack = 0
		return
	
	if MetaProgression.has_route_data(current_level.level_path):
		clear_stage_stack += 1
	
	clear_stack_update.emit()
	if clear_stage_stack >= unvisit_on_need_stack and not _is_next_complete_stage() and _has_unvisited_stage():
		set_next_stage_is_unvisit_stage()

## [KR] 현재 클리어 스택 값을 반환한다.
## [EN] Returns the current clear stack value.
func get_clear_stage_stack()-> int:
	return clear_stage_stack

## [KR] 다음 스테이지를 미방문 스테이지로 강제 설정한다.
## [EN] Forces the next stage to be an unvisited stage.
func set_next_stage_is_unvisit_stage():
	unvisit_stage_setted = true
	NotionEvent.notion("NOTI_SET_UNVISIT_STAGE")
	pick_stage(current_level, true)

## [KR] 미방문 스테이지 설정 상태와 클리어 스택을 초기화한다.
## [EN] Resets the unvisited stage setting state and clear stack.
func init_unvisit_stage_setted():
	clear_stage_stack = maxi(clear_stage_stack-4, 0)
	unvisit_stage_setted = false

## [KR] 장비 코스트를 [param cost]만큼 추가한다.
## [EN] Adds [param cost] amount of equipment cost.
func _add_extra_cost(cost: int):
	GameEvents.emit_set_equip_cost(cost)
