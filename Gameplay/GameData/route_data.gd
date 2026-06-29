class_name RouteData

const STAGE_PATH_PREFIX := "res://Gameplay/Levels/"
const STAGE_PATH_SUFFIX := ".tscn"
const ROUTE_DATA := preload("res://Gameplay/GameData/route_data_json.json")

var current_routes : Dictionary = {}
var setting_routes : Array = []

const NORMAL_COMPLETE_STAGE := "stage_complete"
static var complete_stage: Dictionary = {
	3: "stage_complete_ep3",
	6: "stage_complete_pazuzu"
}

var route_info: Dictionary = {}
static var destination_info : Dictionary = {}


func _init() -> void:
	var data: Dictionary = ROUTE_DATA.data
	
	route_info = data["route_info"]
	destination_info = data["destination_info"]

## limit_event = 공백이 아니라면 해당 이벤트가 세이브 데이터에 존재할시 다시 방문 불가능하다.

static func get_stage_path(stage_name: String) -> String:
	return STAGE_PATH_PREFIX + stage_name + STAGE_PATH_SUFFIX

##현재 스테이지의 경로들을 불러와 종착점에 충족하는지 확인
func check_destination(route_list: Array) -> Dictionary:
	for destination_key in destination_info.keys():
		var destination = destination_info[destination_key]
		var route_list_type = destination.get("route_list_type", "name")
		var required_routes = destination["route_list"]

		# destination에 요구된 route들을 실제 경로로 변환
		var destination_routes: Array = []
		var dest_nums_array: Array = []

		# 종착점 달성 조건이 스테이지들의 이름인 경우
		if route_list_type == "name":
			destination_routes = required_routes.map(func(stage_id): return get_stage_path(stage_id))
		# 종착점 달성 조건이 스테이지들의 번호인 경우
		elif route_list_type == "number":
			# current_routes에서 route_num이 해당 숫자 중 하나인 것만 뽑기
			for stage_path in route_list:
				if current_routes.has(stage_path):
					var route_data_entry = current_routes[stage_path]
					if route_data_entry.has("route_num"):
						dest_nums_array.append(route_data_entry["route_num"])

		# 모든 route가 route_list에 포함되는지 확인
		var partial_count = destination.get("partial_match_count", null)
		if route_list_type == "name":
			var matched = _is_partial_match(route_list, destination_routes, partial_count) if partial_count != null else _is_exact_match(route_list, destination_routes)
			if matched:
				if not MetaProgression.has_route_hint(destination["hint_id"]):
					push_warning("종착점은 존재하나 관련 힌트를 얻지 않았으므로 리턴합니다: %s" % destination["title"])
					return {}
				elif is_destination_limit(destination):
					push_warning("종착점은 존재하나 재방문 할 수 없으므로 리턴합니다: %s" % destination["title"])
					return {}
				else:
					return {"path": get_stage_path(destination_key), "info": destination}
		elif route_list_type == "number":
			var matched = _is_partial_match(dest_nums_array, required_routes, partial_count) if partial_count != null else _is_exact_match(dest_nums_array, required_routes)
			if matched:
				if not MetaProgression.has_route_hint(destination["hint_id"]):
					push_warning("종착점은 존재하나 관련 힌트를 얻지 않았으므로 리턴합니다: %s" % destination["title"])
					return {}
				elif is_destination_limit(destination):
					push_warning("종착점은 존재하나 재방문 할 수 없으므로 리턴합니다: %s" % destination["title"])
					return {}
				else:
					return {"path": get_stage_path(destination_key), "info": destination}

	return {}

# --------------------------------------------------------
func _is_partial_match(selected: Array, required: Array, min_count: int) -> bool:
	# 후보(required)가 아닌 칸이 노선에 하나라도 섞이면 오답 (일반 정확매칭과 동일한 철학)
	for item in selected:
		if item not in required:
			return false
	# 후보 중 노선에 포함된 개수가 min_count(예: 3) 이상이어야 통과
	var count = 0
	for item in required:
		if item in selected:
			count += 1
	return count >= min_count

# 🔸 route_list와 destination_routes가 정확히 동일한지 확인
func _is_exact_match(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for item in a:
		if item not in b:
			return false
	return true

##재방문이 가능한 종착점인지 확인
func is_destination_limit(destination: Dictionary)-> bool:
	if destination["limit_event"] != null and MetaProgression.has_read_event(destination["limit_event"]):
		return true
	return false

##현재 챕터에 해당하는 노선들 추가
func route_append(current_chapter: int):
	current_routes = get_current_chapter_route(current_chapter)

func get_current_chapter_route(current_chapter: int) -> Dictionary:
	var result: Dictionary = {}

	for key in route_info.keys():
		var data = route_info[key]
		if data.has("enable") and data["enable"] and data.has("chapter") and data["chapter"] <= current_chapter:
			result[get_stage_path(key)] = data

	return result

func add_find_stage_metadata(stage: Level):
	var stage_path = stage.get_scene_file_path()
	for key in route_info.keys():
		if get_stage_path(key) == stage_path:
			MetaProgression.set_route_data(stage_path, route_info[key])


static func get_complete_stage(chapter: int) -> String:
	if complete_stage.has(chapter):
		return get_stage_path(complete_stage[chapter])
	else:
		return get_stage_path(NORMAL_COMPLETE_STAGE)

static func get_complete_stage_name(chapter: int) -> String:
	if complete_stage.has(chapter):
		return complete_stage[chapter]
	else:
		return NORMAL_COMPLETE_STAGE

##클리어한 종착점인지 확인
static func is_clear_destination(hint_name: String) -> bool:
	for key in destination_info.keys():
		if destination_info[key].has("hint_id") and destination_info[key]["hint_id"] == hint_name:
			var meta_destinations = MetaProgression.get_current_destination_info()
			var target_path = get_stage_path(key)
			if meta_destinations.has(target_path):
				return true
	return false

static func get_reward_cost(hint_name: String)-> int:
	for key in destination_info.keys():
		if destination_info[key].has("hint_id") and destination_info[key]["hint_id"] == hint_name:
			if destination_info[key]["cost_reward"] != null:
				return destination_info[key]["cost_reward"]
	return 0

func get_route_description(stage: Level) -> String:
	return get_route_data(stage, "info")

func get_route_title(stage: Level)-> String:
	if stage.stage_type == Constants.TYPE_BASE:
		return "시작 지점"
	return get_route_data(stage, "title")

func get_route_title_routename(route_name, route_list_type: String) -> String:
	for key in route_info.keys():
		if route_list_type == "name":
			if key == str(route_name):  # 문자열로 비교
				return route_info[key]["title"]
		elif route_list_type == "number":
			if route_info[key].has("route_num") and route_info[key]["route_num"] == int(route_name):  # 정수로 비교
				return route_info[key]["title"]
	return ""


## 노선의 번호 반환
func get_route_index_routename(route_name, route_list_type: String)-> int:
	if route_list_type == "number": #종착점 힌트가 숫자 타입인 경우 route_name은 int이기 때문에 바로 넘긴다
		return route_name
	elif route_list_type == "name":
		for key in route_info.keys():
			if key == route_name:
				return route_info[key]["route_num"]
	return 0

func get_route_data(stage: Level, type: String)-> String:
	var stage_path: String = stage.get_scene_file_path()
	for key in route_info.keys():
		if get_stage_path(key) == stage_path:
			return route_info[key][type]
	#push_warning("route_info에 해당하는 정보가 없습니다: %s" % stage_path)
	return ""


## destination_info dictionary에서 해당 레벨의 정보를 찾아 반환한다
func get_destination_data(stage: Level)-> Dictionary:
	var stage_path: String = stage.get_scene_file_path()
	for key in destination_info.keys():
		if get_stage_path(key) == stage_path:
			return destination_info[key]
	#push_warning("route_info에 해당하는 정보가 없습니다: %s" % stage_path)
	return {}

func has_route_basename(base_name: String)-> bool:
	if route_info.has(base_name):
		return true
	return false
