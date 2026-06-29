extends Button
class_name HintSlot

var hint_info : RouteHintPage
@onready var title_label: Label = %TitleLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var find_label: Label = %FindLabel
@onready var item_icon_rect: ColorRect = $ItemIconRect
@onready var item_icon_texture: TextureRect = %ItemIconTexture
@onready var route_answer_label: Label = %RouteAnswerLabel
@onready var cost_reward_label: Label = %CostRewardLabel
@onready var cost_reward_container: HBoxContainer = $CostRewardContainer

@onready var partner_frame: TextureRect = %PartnerFrame
@onready var partner_icon: TextureRect = %PartnerIcon

var answer_num: int = 0 # 종착점의 답의 개수

# enum 순서가 곧 정렬 순서다(is_route_state 오름차순). 미발견 → 발견(이벤트 미획득) → 발견 → 폐쇄 순으로 표시된다
enum HintState { STATE_NOT_FIND, STATE_FIND_NO_EVENT, STATE_FIND, STATE_CLOSED }
const ROUTE_STATE: Dictionary = {
	HintState.STATE_NOT_FIND : "ROUTE_NOT_FIND",
	HintState.STATE_FIND : "ROUTE_FIND",
	HintState.STATE_CLOSED : "ROUTE_CLOSE",
	HintState.STATE_FIND_NO_EVENT : "ROUTE_FIND_NO_EVENT"
}
var is_route_state: HintState = HintState.STATE_NOT_FIND

func _ready() -> void:
	if hint_info:
		title_label.text = hint_info.title
		find_label.text = ROUTE_STATE[HintState.STATE_NOT_FIND]
		description_label.text = hint_info.description
		_init_answer_num()

		#루트 방문 여부에 따라 텍스트 변경
		if RouteData.is_clear_destination(hint_info.id): # 루트 방문했을 경우
			find_label.text = ROUTE_STATE[HintState.STATE_FIND]
			is_route_state = HintState.STATE_FIND
			find_label.modulate = Color.GREEN_YELLOW
			route_answer_label.show()
			route_answer_label.text = get_hint_answer()
			set_visit_limit()
			# 발견했으나 잘못된 파트너를 동행하여 보상 H씬을 보지 못한 경우 별도 표시
			if is_route_state == HintState.STATE_FIND and _is_reward_h_locked():
				find_label.text = ROUTE_STATE[HintState.STATE_FIND_NO_EVENT]
				is_route_state = HintState.STATE_FIND_NO_EVENT
				find_label.modulate = Color.ORANGE
		else:
			route_answer_label.hide()
		
		#힌트 아이콘이 있을 경우 표시
		if hint_info.texture:
			item_icon_texture.texture = hint_info.texture
			item_icon_rect.show()
		else:
			item_icon_rect.hide()
		
		#파트너 이벤트가 있을 경우 표시
		if hint_info.partner_type != hint_info.PartnerType.NONE:
			partner_frame.show()
			partner_icon.texture = Constants.SD_ICONS[hint_info.partner_type]
		else:
			partner_frame.hide()
			partner_icon.texture = null
		
		#방문 코스트 보상이 있을 시 표시
		var reward_cost: int = RouteData.get_reward_cost(hint_info.id)
		if reward_cost > 0:
			cost_reward_label.text = str(reward_cost)
			cost_reward_container.show()
		else:
			cost_reward_container.hide()

## 이 종착점의 보상 H씬이 존재하지만 아직 해금되지 않았는지 확인한다.
## (발견했으나 잘못된 파트너를 동행하여 H씬을 보지 못한 경우 true)
func _is_reward_h_locked() -> bool:
	var dest_key: String = _get_destination_key()
	if dest_key == "":
		return false
	var h_res_array: Array = TrainUtil.get_res_from_path(HSceneData.H_SCENE_DATA_PATH)
	for res in h_res_array:
		if res is HSceneRes and res.stage_name == dest_key:
			return not MetaProgression.get_npc_unlock_event(res.partner, res.scene_name)
	return false

## hint_info.id에 해당하는 종착점 키를 반환한다. 없으면 빈 문자열.
func _get_destination_key() -> String:
	var destination_info = (RouteData.destination_info as Dictionary)
	for i in destination_info:
		if destination_info[i]["hint_id"] == hint_info.id:
			return i
	return ""

func set_visit_limit():
	var route_data: RouteData = RouteData.new()
	var destination_info = (RouteData.destination_info as Dictionary).duplicate(true)
	
	for i in destination_info:
		if destination_info[i]["hint_id"] == hint_info.id:
			if route_data.is_destination_limit(destination_info[i]):
				find_label.text = ROUTE_STATE[HintState.STATE_CLOSED]
				is_route_state = HintState.STATE_CLOSED
				
				find_label.modulate = Color.RED
			break

func get_hint_answer()->String:
	var route_data: RouteData = RouteData.new()
	var answer: String
	var routes: Array = []
	var route_list_type: String
	var routes_tr: Array = []
	var destination_info = (RouteData.destination_info as Dictionary).duplicate(true)
	
	for i in destination_info:
		if destination_info[i]["hint_id"] == hint_info.id:
			routes = destination_info[i]["route_list"]
			# partial 케이스도 후보 전체 개수를 표시한다 (필요 개수는 "N개 이상" 라벨로 별도 안내)
			set_answer_num(routes.size())
			route_list_type = destination_info[i]["route_list_type"]
			break

	for i in routes.size():
		var title := tr(route_data.get_route_title_routename(routes[i], route_list_type))
		var numbered := "(%d)%s" % [route_data.get_route_index_routename(routes[i], route_list_type), title]
		routes_tr.append(numbered)
	answer = " + ".join(routes_tr)
	#print(answer)
	return answer

func set_answer_num(num: int):
	answer_num = num

## discovered 여부와 관계없이 [member answer_num]을 초기화한다.
func _init_answer_num():
	var destination_info = (RouteData.destination_info as Dictionary).duplicate(true)
	for i in destination_info:
		if destination_info[i]["hint_id"] == hint_info.id:
			var routes: Array = destination_info[i]["route_list"]
			answer_num = routes.size()
			break
