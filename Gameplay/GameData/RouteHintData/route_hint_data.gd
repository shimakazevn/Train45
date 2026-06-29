class_name RouteHintData

const ROUTE_HINT_RES_PATH = "res://Gameplay/GameData/RouteHint/"
var route_hint_res_array: Array = TrainUtil.get_res_from_path(ROUTE_HINT_RES_PATH)

var route_hint_info : Dictionary = {}

func get_route_hint(hint_id: String) -> Resource:
	if route_hint_info.is_empty():
		_initialize()

	return route_hint_info.get(hint_id, null)

func _initialize():
	for res in route_hint_res_array:
		if res is RouteHintPage and res.id != "":
			route_hint_info[res.id] = res
