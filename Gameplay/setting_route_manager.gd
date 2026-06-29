## [KR] 플레이어가 설정한 노선(경로) 및 종착점 정보를 관리하는 매니저.
## [EN] Manager that handles player-configured routes (paths) and destination information.
## [KR] [member setting_route]에서 다음 노선을 순차적으로 꺼내며(pop-out),
## [EN] Sequentially pops out the next route from [member setting_route],
## [KR] [MetaProgression]을 통해 세이브 데이터와 동기화한다.
## [EN] and synchronizes with save data through [MetaProgression].
extends Node
class_name SettingRouteManager

## [KR] 노선 정보가 변경될 때 발생하는 시그널 (UI 갱신 등에 사용)
## [EN] Signal emitted when route information changes (used for UI updates, etc.)
signal route_update

## [KR] 부모 노드에서 가져오는 [FloorManager] 참조
## [EN] [FloorManager] reference obtained from parent node
@onready var floormanager : FloorManager

## [KR] 순서대로 소비(pop-out)되는 노선 경로 배열
## [EN] Route path array consumed (popped out) in order
var setting_route := [] # [KR] 가장 앞의 노선을 popout하는 배열 / [EN] Array that pops out the frontmost route
## [KR] 사용자가 등록한 노선 원본 정보 배열
## [EN] Array of original route information registered by the user
var setting_route_base := [] # [KR] 노선의 등록 정보 / [EN] Route registration info
## [KR] 현재 칸칸네비 종착점 정보 딕셔너리
## [EN] Current KankanNavi destination information dictionary
var current_destination_info :Dictionary = {}
## [KR] 현재 종착점 발견 여부
## [EN] Whether the current destination has been found
var current_destination_find :bool

## [KR] 챕터 전환 중 플래그 — [code]true[/code]이면 기지 복귀 시 기존 노선을 재설정하지 않음
## [EN] Chapter transition flag — if [code]true[/code], existing routes are not reset on base return
var chapter_changing:= false

func _ready() -> void:
	floormanager = get_parent()
	GameEvents.game_complete.connect(_on_game_complete)
	set_meta_route()
	
	GameEvents.set_chapter.connect(_on_set_chapter)

## [KR] 현재 설정된 노선 배열을 반환한다. 비어있으면 빈 배열을 반환.
## [EN] Returns the currently set route array. Returns empty array if empty.
func get_setting_route() -> Array:
	if setting_route == []:
		return []
	return setting_route
	
## [KR] 노선 등록 원본 배열을 반환한다.
## [EN] Returns the original route registration array.
func get_setting_route_base() -> Array:
	return setting_route_base

## [KR] 노선 등록 원본을 [param base_list]로 교체하고 [MetaProgression]에 저장한 뒤
## [EN] Replaces the original route registration with [param base_list], saves to [MetaProgression],
## [KR] [signal route_update]를 발생시킨다.
## [EN] and emits [signal route_update].
func set_setting_route_base(base_list: Array):
	setting_route_base.clear()
	setting_route_base = base_list
	MetaProgression.set_base_route(setting_route_base, setting_route)
	route_update.emit()

## [KR] [param destination]에서 종착점 정보와 발견 여부를 저장하고
## [EN] Saves destination information and discovery status from [param destination],
## [KR] [MetaProgression]에 칸칸네비 종착점을 기록한다.
## [EN] and records the KankanNavi destination in [MetaProgression].
## [KR] [param destination]이 [code]null[/code]이면 종착점을 초기화한다.
## [EN] Clears the destination if [param destination] is [code]null[/code].
func set_current_destination(destination:DestinationRect):
	if destination:
		current_destination_info = destination.current_route
		current_destination_find = destination.is_find
	else:
		clear_current_destination()
	
	# [KR] 세이브 파일에 현재 칸칸네비 종착점 저장
	# [EN] Save current KankanNavi destination to save file
	MetaProgression.set_kankan_destination(current_destination_info)

## [KR] 현재 종착점 정보를 초기화한다.
## [EN] Clears the current destination information.
func clear_current_destination():
	current_destination_info = {}
	current_destination_find = false

## [KR] 현재 종착점 정보 딕셔너리를 반환한다.
## [EN] Returns the current destination information dictionary.
func get_current_destination_info()->Dictionary:
	return current_destination_info

## [KR] 현재 종착점 발견 여부를 반환한다.
## [EN] Returns whether the current destination has been found.
func get_current_destination_finded()-> bool:
	return current_destination_find

## [KR] 노선이 설정되어 있으면 [code]true[/code], 비어있으면 [code]false[/code]를 반환한다.
## [EN] Returns [code]true[/code] if a route is set, [code]false[/code] if empty.
func setting_route_on() -> bool:
	if setting_route_base == []:
		return false
	return true

## [KR] 설정된 노선 배열의 첫 번째 경로를 반환한다. 비어있으면 빈 문자열 반환.
## [EN] Returns the first path of the set route array. Returns empty string if empty.
func pick_route_path() -> String:
	if setting_route == []:
		return ""
	return setting_route[0]
	
## [KR] 설정된 노선 배열의 첫 번째 경로를 제거(pop)한다.
## [EN] Removes (pops) the first path from the set route array.
func popout_route_path():
	if setting_route == []:
		return
	setting_route.pop_front()

## [KR] 게임 완료 시 노선 배열을 비운다.
## [EN] Clears the route array on game completion.
func _on_game_complete():
	setting_route.clear()

## [KR] 기지 스테이지에 진입하면 노선을 초기화하고 [MetaProgression]에서 재로드한다.
## [EN] Clears routes on base stage entry and reloads from [MetaProgression].
## [KR] [member chapter_changing]이 [code]true[/code]이면 챕터 전환이므로 재로드를 건너뛴다.
## [EN] Skips reload if [member chapter_changing] is [code]true[/code] as it means a chapter transition.
func set_routes(stage_type: int):
	if stage_type == Constants.TYPE_BASE:
		clear_routes()
		if not chapter_changing: # [KR] 챕터 변경시 기존 노선도로 재설정하지 않음 / [EN] Don't reset to existing routes on chapter change
			set_meta_route()
		
		chapter_changing = false

## [KR] 챕터 변경 시그널 수신 시 [member chapter_changing] 플래그를 활성화한다.
## [EN] Activates the [member chapter_changing] flag on chapter change signal.
func _on_set_chapter(_chapter_num: int):
	chapter_changing = true

## [KR] 설정된 노선과 등록 원본을 모두 초기화하고 [signal route_update]를 발생시킨다.
## [EN] Clears all set routes and registration originals, and emits [signal route_update].
func clear_routes():
	setting_route.clear()
	setting_route_base.clear()
	route_update.emit()

## [KR] [MetaProgression]에서 저장된 노선, 등록 원본, 종착점 정보를 로드한다.
## [EN] Loads saved routes, registration originals, and destination info from [MetaProgression].
func set_meta_route():
	setting_route.append_array(MetaProgression.get_routes())
	setting_route_base.append_array(MetaProgression.get_base_route())
	var meta_destination_info = MetaProgression.get_kankan_destination() as Dictionary
	if meta_destination_info != {}:
		current_destination_info = meta_destination_info
