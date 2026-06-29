## [KR] 도전과제 조건을 판정하고 [code]SteamManager[/code]로 해금을 요청하는 중앙 매니저.
## [br]게임플레이 코드를 수정하지 않고 기존 이벤트 버스([code]GameEvents[/code])와
## 세이브 매니저([code]MetaProgression[/code])의 시그널만 구독해 동작한다.
## [br]수집 완료 판정에 쓰는 전체 개수는 하드코딩하지 않고 런타임에 직접 집계하므로,
## 루트/이벤트가 추가되어도 조건이 자동으로 따라간다.
extends Node

## [KR] 내부 키 → Steamworks 파트너 사이트에 등록할 도전과제 API 이름.
const ACH := {
	"TRUE_ENDING": "ACH_TRUE_ENDING",
	"BAD_ENDING": "ACH_BAD_ENDING",
	"REINA_MAX": "ACH_REINA_MAX_LOVE",
	"MAI_MAX": "ACH_MAI_MAX_LOVE",
	"KONIAL_MAX": "ACH_KONIAL_MAX_LOVE",
	"BUTLER_MAX": "ACH_BUTLER_MAX_LOVE",
	"ALL_ROUTES": "ACH_ALL_ROUTES",
	"DEST_ALL": "ACH_ALL_DESTINATIONS",
	"ITEM_ALL": "ACH_ALL_ITEMS",
	"CHAPTER_1": "ACH_CHAPTER_1",
	"CHAPTER_2": "ACH_CHAPTER_2",
	"CHAPTER_3": "ACH_CHAPTER_3",
	"CHAPTER_4": "ACH_CHAPTER_4",
	"CHAPTER_5": "ACH_CHAPTER_5",
	"ALL_CLEAR": "ACH_ALL_CLEAR",
	"DEST_BUNNY": "ACH_DEST_BUNNY",
	"DEST_ONSEN": "ACH_DEST_ONSEN",
	"SOLD_OUT": "ACH_SOLD_OUT",
	"ITEM_GHOSTSKIP": "ACH_ITEM_GHOSTSKIP",
	"NO_ITEM_RUN": "ACH_NO_ITEM_RUN",
	"ALL_ITEMBOX": "ACH_ALL_ITEMBOX",
}

## [KR] 전체 아이템박스(분실물) 목록. 분모 집계 기준. (collect_item_boxes_component가 생성)
const ITEM_BOX_SCENES := preload("res://Gameplay/GameData/item_box_scenes.json")

## [KR] 메인 스토리에서 종착점 처리가 안되는 스테이지 수. clear_percent_component의 OFFSET_STAGE와 동일.
const DESTINATION_OFFSET := 4

## [KR] 아이템(업그레이드) 전체 개수 집계용. 최초 1회만 생성해 캐싱한다.
var _item_data: ItemData = null

func _ready() -> void:
	GameEvents.npc_level_up.connect(_on_npc_level_up)
	GameEvents.ability_upgrade_added.connect(_on_ability_added)
	MetaProgression.ending_reached.connect(_on_ending)
	MetaProgression.stage_first_clear.connect(_on_route_found)
	MetaProgression.destination_cleared.connect(_on_destination_cleared)
	GameEvents.set_chapter.connect(_on_set_chapter)
	GameEvents.get_item_event.connect(_on_get_item)
	GameEvents.add_route_hint.connect(_on_add_route_hint)
	GameEvents.item_box_collected.connect(_on_item_box_collected)

#region 시그널 핸들러
func _on_ending() -> void:
	# [KR] ending_reached는 트루엔딩(엔진룸 분기→epilogue_0)에서만 발신된다.
	SteamManager.unlock(ACH.TRUE_ENDING)

# [KR] 조건 판정은 모두 call_deferred로 미룬다.
# [br]AchievementManager(오토로드)는 게임플레이 코드보다 시그널에 먼저 연결되므로,
# 같은 시그널을 받는 레벨업/루트 저장 로직보다 핸들러가 먼저 실행된다.
# 즉시 판정하면 아직 세이브 데이터에 반영되지 않은 직전 값을 읽어(레벨 -1, 루트 누락 등)
# 해금이 한 박자 늦거나(다음 이벤트/로드 시점) 엉뚱한 시점에 발생한다.
# 프레임 끝으로 미뤄 데이터 커밋 이후에 판정하면 이 타이밍 문제가 사라진다.
func _on_npc_level_up(_npc_int: int) -> void:
	_check_love_levels.call_deferred()

func _on_route_found() -> void:
	_check_routes.call_deferred()
	_check_item_boxes.call_deferred()

func _on_ability_added(_upgrade: AbilityUpgrade, _current_upgrade: Dictionary) -> void:
	_check_items.call_deferred()

func _on_destination_cleared() -> void:
	_check_destinations.call_deferred()

## [KR] 챕터 전환 시그널. set_chapter(N) 진입은 N-1 챕터 클리어를 의미한다(2~6 → CHAPTER_1~5).
func _on_set_chapter(next_chapter: int) -> void:
	var key := "CHAPTER_%d" % (next_chapter - 1)
	if ACH.has(key):
		SteamManager.unlock(ACH[key])

## [KR] 상점/아이템박스 아이템 획득 시그널. 고스트 스킵 아이템 획득 시 해금.
func _on_get_item(item_name: String) -> void:
	if item_name == "ghost_skip":
		SteamManager.unlock(ACH.ITEM_GHOSTSKIP)
	_check_item_boxes.call_deferred()

## [KR] 루트 힌트(분실물 맵) 획득 시그널. 아이템박스 수집 판정에 사용.
func _on_add_route_hint(_hint_id: String) -> void:
	_check_item_boxes.call_deferred()

## [KR] 분실물(아이템박스) 획득 시그널. 코인/티켓 박스는 get_item_event/add_route_hint를 안 쏘므로,
## 이 시그널이 없으면 마지막 분실물이 코인/티켓 박스일 때 해금이 로드 전까지 누락된다.
func _on_item_box_collected() -> void:
	_check_item_boxes.call_deferred()
#endregion

#region 조건 판정
func _check_love_levels() -> void:
	if MetaProgression.get_npc_love_level(Constants.NPC_OL) >= Constants.PARTNER_MAX_LEVEL:
		SteamManager.unlock(ACH.REINA_MAX)
	if MetaProgression.get_npc_love_level(Constants.NPC_GYARU) >= Constants.PARTNER_MAX_LEVEL:
		SteamManager.unlock(ACH.MAI_MAX)
	if MetaProgression.get_npc_love_level(Constants.NPC_KONIAL) >= Constants.NPC_MAX_LEVEL_KONIAL:
		SteamManager.unlock(ACH.KONIAL_MAX)
	if MetaProgression.get_npc_love_level(Constants.NPC_BUTLER) >= Constants.NPC_MAX_LEVEL_BUTLER:
		SteamManager.unlock(ACH.BUTLER_MAX)

func _check_routes() -> void:
	var found: int = MetaProgression.get_routes_dict().size()
	if found >= _get_total_routes():
		SteamManager.unlock(ACH.ALL_ROUTES)
	_check_all_clear()

func _check_destinations() -> void:
	# [KR] 게임 표준 정의(clear_percent_component)와 동일: destination_info 크기 / (전체 + OFFSET)
	var total := _get_total_destinations()
	var dest_info: Dictionary = MetaProgression.save_data.get("destination_info", {})
	var found: int = dest_info.size()
	if total > 0 and found >= total:
		SteamManager.unlock(ACH.DEST_ALL)
	# [KR] DEST_BUNNY / DEST_ONSEN은 종착점 "도착"이 아니라 해당 H 이벤트를 끝까지 본 시점에 해금해야 한다.
	# (룰렛 실패 시 바니를 못 보거나, 온천 H 전에 떠서 스포일러가 되는 문제)
	# → 각 타임라인 종료부(e_roullete.dtl / e_onsen.dtl)에서 직접 해금하며,
	#   기존 세이브 소급 해금은 evaluate_all의 _check_event_achievements가 담당한다.
	_check_all_clear()

func _check_items() -> void:
	# [KR] 게임 표준 정의(clear_percent_component)와 동일: ability 크기 / UPGRADES 크기
	var total := _get_total_items()
	var collected: int = (MetaProgression.save_data.get("ability", {}) as Dictionary).size()
	if total > 0 and collected >= total:
		SteamManager.unlock(ACH.ITEM_ALL)
	_check_all_clear()

## [KR] 노선·종착점·아이템 3개 카테고리가 모두 100%면 진행도 100%로 보고 해금한다.
## [br]clear_percent_component.get_all_clear_percent(3개 평균)이 100이 되는 조건과 동일하다.
func _check_all_clear() -> void:
	var routes_done: bool = MetaProgression.get_routes_dict().size() >= _get_total_routes()
	var dest_done: bool = (MetaProgression.save_data.get("destination_info", {}) as Dictionary).size() >= _get_total_destinations()
	var items_done: bool = (MetaProgression.save_data.get("ability", {}) as Dictionary).size() >= _get_total_items()
	if routes_done and dest_done and items_done:
		SteamManager.unlock(ACH.ALL_CLEAR)

## [KR] 분실물(아이템박스)을 모두 회수했는지 판정한다.
## [br]분모는 item_box_scenes.json의 전체 박스 수, 분자는 박스 종류별 보유 여부로 집계한다.
## [br]코인/티켓 박스는 스테이지 단위(box_getted_stage), 그 외는 아이템/힌트 id 보유로 판단.
func _check_item_boxes() -> void:
	var data: Dictionary = ITEM_BOX_SCENES.data
	var total := 0
	var collected := 0
	for scene_path in data:
		for box in data[scene_path]:
			total += 1
			var box_name: String = box.get("name", "")
			if box_name.begins_with("ticket") or box_name.begins_with("route_coin"):
				if MetaProgression.has_box_getted_stage(scene_path):
					collected += 1
			elif MetaProgression.has_ability(box_name) or MetaProgression.has_route_hint(box_name):
				collected += 1
	if total > 0 and collected >= total:
		SteamManager.unlock(ACH.ALL_ITEMBOX)

## [KR] 특정 H 이벤트를 끝까지 본 적이 있으면 해금한다. (기존 세이브 소급 해금용)
## [br]평소에는 e_roullete.dtl / e_onsen.dtl 종료부에서 직접 해금하므로, 이 함수는 로드 시 보정만 담당한다.
## [br]바니(룰렛) = 마이 scene21, 온천 = 레이나 scene3.
func _check_event_achievements() -> void:
	if _has_seen_event(Constants.NPC_GYARU, "scene21"):
		SteamManager.unlock(ACH.DEST_BUNNY)
	if _has_seen_event(Constants.NPC_OL, "scene3"):
		SteamManager.unlock(ACH.DEST_ONSEN)

## [KR] [param npc_type] NPC가 [param event_name] 이벤트를 해금(관람)한 적이 있는지 안전하게 확인한다.
func _has_seen_event(npc_type: int, event_name: String) -> bool:
	var npc_info: Dictionary = MetaProgression.save_data.get("npc_info", {})
	var entry: Dictionary = npc_info.get(npc_type, {})
	return (entry.get("unlock_event", []) as Array).has(event_name)

## [KR] 상점에서 구매 가능한 모든 경품을 끝까지(매진) 사들였는지 판정해 ACH.SOLD_OUT을 해금한다.
## [br]"全ての景品を交換" 업적. 챕터별로 품목이 추가되는 구조라 챕터 진행을 모두 끝낸 6장에서만 충족된다.
## [br]대상은 "상점 품목만": item_data의 4개 카테고리 중 상점에서 살 수 있는 것만 센다.
## add_chapter가 없는 업그레이드(아이템박스/스토리로만 획득)는 상점에 등장하지 않으므로 제외한다.
## [br]판정 기준은 shop.is_sold_out과 동일: 업그레이드=최대 수량, 힌트=route_hint 보유,
## 박스맵=box_map 보유, 화폐=최대 구매수.
## [br]힌트는 how_to_get=="shop"인 것만 센다. item_box/story로만 얻는 힌트는 상점에 없고
## 획득 시 check_shop_complete가 호출되지 않아, 포함하면 로드 전까지 해금이 누락된다.
func check_shop_complete() -> void:
	if _item_data == null:
		_item_data = ItemData.new()
	for key in _item_data.UPGRADES:
		if _item_data.UPGRADES[key]["info"].get("add_chapter") == null:
			continue  # [KR] 상점 비매물(아이템박스/스토리 획득) → 제외
		var up_res := _item_data.UPGRADES[key]["res"] as AbilityUpgrade
		if MetaProgression.get_upgrade_count(up_res.id) < up_res.max_quantity:
			return
	for key in _item_data.HINT_ITEMS:
		if _item_data.HINT_ITEMS[key]["info"].get("how_to_get") != "shop":
			continue  # [KR] 상점 비매물(스토리/아이템박스로만 획득하는 힌트) → 제외
		var hint_res := _item_data.HINT_ITEMS[key]["res"] as ShopHint
		if not MetaProgression.has_route_hint(hint_res.hint_info.id):
			return
	for key in _item_data.BOX_MAPS:
		var bm_res := _item_data.BOX_MAPS[key]["res"] as BoxMapItem
		if not MetaProgression.has_box_map(bm_res.id):
			return
	for key in _item_data.CURRENCY_ITEM:
		var cur_res := _item_data.CURRENCY_ITEM[key]["res"] as CurrencyShopItem
		if MetaProgression.get_buyed_currency_item(cur_res.id) < cur_res.max_count:
			return
	SteamManager.unlock(ACH.SOLD_OUT)
#endregion

## [KR] 세이브 로드 직후 전체 조건을 재판정한다.
## [br]업데이트로 추가된 도전과제를, 이미 조건을 충족한 기존 세이브에 소급 해금하기 위함.
func evaluate_all() -> void:
	if MetaProgression.save_data.get("is_ending", false):
		_on_ending()
	_check_love_levels()
	_check_routes()
	_check_destinations()
	_check_items()
	_check_item_boxes()
	_check_event_achievements()
	check_shop_complete()
	if Constants.IS_DEBUG:
		_debug_dump_events()

## [KR] 챕터6 최상층(끝) 도달 시 chapter6_complete.dtl에서 호출된다.
## [br]장비를 하나도 장착하지 않은 상태면 해금한다. (엔딩 분기 스테이지는 층 방문이 아니므로 무관)
func check_no_item_run() -> void:
	if MetaProgression.get_equipment_array().is_empty():
		SteamManager.unlock(ACH.NO_ITEM_RUN)

## [KR] 파트너별 미수집 이벤트를 콘솔에 출력한다. (디버그 전용 진단)
func _debug_dump_events() -> void:
	var names := {0: "레이나", 1: "마이", 2: "코니알", 3: "파주주", 4: "집사"}
	var by_partner: Dictionary = {}
	var arr: Array = TrainUtil.get_res_from_path(HSceneData.H_SCENE_DATA_PATH)
	for res in arr:
		var h := res as HSceneRes
		if h == null or h.is_disabled:
			continue
		if not by_partner.has(h.partner):
			by_partner[h.partner] = []
		by_partner[h.partner].append(h.scene_name)
	var npc_info: Dictionary = MetaProgression.save_data.get("npc_info", {})
	for p in by_partner:
		var all_names: Array = by_partner[p]
		var unlocked: Array = npc_info.get(p, {}).get("unlock_event", [])
		var missing: Array = []
		for n in all_names:
			if not unlocked.has(n):
				missing.append(n)
		print("[ACH][DEBUG] %s: %d/%d, uncollected=%s" % [names.get(p, str(p)), all_names.size() - missing.size(), all_names.size(), str(missing)])

#region 집계 유틸
## [KR] enable=true인 전체 루트 개수를 route_data_json에서 직접 집계한다.
func _get_total_routes() -> int:
	var data: Dictionary = (preload("res://Gameplay/GameData/route_data_json.json") as JSON).data
	var count := 0
	for key in data["route_info"]:
		if data["route_info"][key].get("enable", false):
			count += 1
	return count

## [KR] 전체 종착점 개수 (destination_info + OFFSET). clear_percent_component와 동일 기준.
func _get_total_destinations() -> int:
	var data: Dictionary = (preload("res://Gameplay/GameData/route_data_json.json") as JSON).data
	return (data["destination_info"] as Dictionary).size() + DESTINATION_OFFSET

## [KR] item_type=="upgrade"인 전체 아이템 개수 (ItemData.UPGRADES).
func _get_total_items() -> int:
	if _item_data == null:
		_item_data = ItemData.new()
	return _item_data.UPGRADES.size()

#endregion
