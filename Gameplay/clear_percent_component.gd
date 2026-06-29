## 게임 올 클리어 퍼센트를 계산하는 컴포넌트.
## 노선, 종착점, 아이템 3가지 카테고리의 개별 진행도를 산출하고
## 이들의 평균으로 전체 클리어율을 반환한다.
extends Node
class_name ClearPercentComponent

## 노선 정보를 조회하기 위한 [RouteData] 인스턴스
var route_data := RouteData.new()
## 아이템/업그레이드 정보를 조회하기 위한 [ItemData] 인스턴스
var item_data := ItemData.new()

## 전체 노선 수 (100% 기준)
var total_route_num: int
## 전체 종착점 수 (100% 기준, [const OFFSET_STAGE] 포함)
var total_destination_num: int
## 전체 아이템(업그레이드) 수 (100% 기준)
var total_item_num: int

## 파트너별 활성 H씬 총 개수 (is_disabled 제외). 100% 기준으로 사용한다.
var total_h_scene_by_partner: Dictionary = {}

## 메인 스토리에서 종착점 처리가 안되는 스테이지 갯수
## res://Gameplay/Levels/stage_complete.tscn, res://Gameplay/Levels/stage_complete_ep3.tscn ...
const OFFSET_STAGE: int = 4

func _ready() -> void:
	total_route_num = route_data.route_info.size()
	total_destination_num = route_data.destination_info.size() + OFFSET_STAGE
	total_item_num = item_data.UPGRADES.size()
	_cache_h_scene_totals()

## HSceneRes 리소스를 스캔해 파트너별 활성 H씬 개수를 1회 집계한다.
func _cache_h_scene_totals() -> void:
	for res in TrainUtil.get_res_from_path(HSceneData.H_SCENE_DATA_PATH):
		var h := res as HSceneRes
		if h == null or h.is_disabled:
			continue
		total_h_scene_by_partner[h.partner] = total_h_scene_by_partner.get(h.partner, 0) + 1

# -------------------------
# 개별 진행도 계산 함수들
# -------------------------

## [param save_info]의 [code]route_data[/code] 크기를 기반으로 노선 발견 퍼센트를 반환한다.
func get_route_percent(save_info: Dictionary) -> int:
	if total_route_num == 0:
		return 0
	return int((float(save_info["route_data"].size()) / float(total_route_num)) * 100.0)


## [param save_info]의 [code]destination_info[/code] 크기를 기반으로 종착점 발견 퍼센트를 반환한다.
func get_destination_percent(save_info: Dictionary) -> int:
	if total_destination_num == 0:
		return 0
	return int((float(save_info["destination_info"].size()) / float(total_destination_num)) * 100.0)


## [param save_info]의 [code]ability[/code] 크기를 기반으로 아이템 획득 퍼센트를 반환한다.
func get_item_percent(save_info: Dictionary) -> int:
	if total_item_num == 0:
		return 0
	return int((float(save_info["ability"].size()) / float(total_item_num)) * 100.0)


## [param save_info]에서 [param partner]의 H씬 수집 퍼센트를 반환한다.
## [br]해금 이벤트 수를 활성 H씬 총 개수로 나눈다. scene_name이 파트너 내에서 고유하므로
## unlock_event 개수를 그대로 세되, 비활성 씬 등으로 인한 초과는 총 개수로 상한 처리한다.
func get_h_scene_percent(save_info: Dictionary, partner: int) -> int:
	var total: int = total_h_scene_by_partner.get(partner, 0)
	if total == 0:
		return 0
	var npc_info: Dictionary = save_info.get("npc_info", {})
	var unlocked: int = 0
	if npc_info.has(partner):
		unlocked = (npc_info[partner].get("unlock_event", []) as Array).size()
	unlocked = mini(unlocked, total)
	return int((float(unlocked) / float(total)) * 100.0)


# -------------------------
# 전체 올 클리어 퍼센트
# -------------------------

## 노선, 종착점, 아이템 3개 카테고리의 평균 퍼센트를 전체 클리어율로 반환한다.
func get_all_clear_percent(save_info: Dictionary) -> int:
	var route_p = get_route_percent(save_info)
	var dest_p = get_destination_percent(save_info)
	var item_p = get_item_percent(save_info)

	# 3개 항목의 평균값 반환
	return int((route_p + dest_p + item_p) / 3.0)
