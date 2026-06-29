## [KR] AchievementManager 신규 도전과제 판정 로직 단위 테스트.
## [br]SteamManager.debug_unlocked(로그 모드 기록)를 검사해 의도한 도전과제가 해금 요청되는지 확인한다.
## [br]게임 본문은 수정하지 않고 AchievementManager의 실제 메서드를 직접 호출한다.
extends GutTest

## user:// 세이브와 겹치지 않게 높은 슬롯 사용.
const SLOT := 18

func before_each():
	MetaProgression.save_slot = SLOT
	MetaProgression.new_game()
	SteamManager._debug_log = true
	SteamManager.debug_unlocked.clear()

func _unlocked(api: String) -> bool:
	return SteamManager.debug_unlocked.has(api)

# -------------------- 챕터 클리어 --------------------
func test_set_chapter_unlocks_previous_chapter():
	AchievementManager._on_set_chapter(2)  # ch1 클리어
	assert_true(_unlocked("ACH_CHAPTER_1"), "set_chapter(2) → CHAPTER_1")
	AchievementManager._on_set_chapter(6)  # ch5 클리어
	assert_true(_unlocked("ACH_CHAPTER_5"), "set_chapter(6) → CHAPTER_5")

func test_set_chapter_one_has_no_chapter_zero():
	AchievementManager._on_set_chapter(1)  # 프롤로그→ch1, CHAPTER_0 없음
	assert_false(_unlocked("ACH_CHAPTER_0"))
	assert_eq(SteamManager.debug_unlocked.size(), 0)

# -------------------- 엔딩 --------------------
func test_ending_reached_unlocks_true_ending():
	AchievementManager._on_ending()
	assert_true(_unlocked("ACH_TRUE_ENDING"))
	assert_false(_unlocked("ACH_ENDING"), "구 ENDING 키는 더 이상 쓰지 않음")

# -------------------- 아이템(고스트 스킵) --------------------
func test_ghost_skip_item_unlocks():
	AchievementManager._on_get_item("ghost_skip")
	assert_true(_unlocked("ACH_ITEM_GHOSTSKIP"))

func test_non_ghost_item_does_not_unlock_ghostskip():
	AchievementManager._on_get_item("milk")
	assert_false(_unlocked("ACH_ITEM_GHOSTSKIP"))

# -------------------- 특정 종착점 (바니/온천) --------------------
# [KR] 바니/온천은 "도착"이 아니라 해당 H 이벤트를 본 시점에 해금된다.
# 도착만으로는 해금되지 않아야 한다(룰렛 실패/스포일러 방지).
func test_destination_arrival_alone_does_not_unlock_bunny_or_onsen():
	MetaProgression.save_data["destination_info"] = {
		"res://Gameplay/Levels/stage_d_rulet.tscn": {},
		"res://Gameplay/Levels/stage_d_onsen.tscn": {},
	}
	AchievementManager._check_destinations()
	assert_false(_unlocked("ACH_DEST_BUNNY"), "도착만으론 바니 해금 X")
	assert_false(_unlocked("ACH_DEST_ONSEN"), "도착만으론 온천 해금 X")

func test_bunny_h_event_unlocks_bunny():
	MetaProgression.add_npc_unlock_event(Constants.NPC_GYARU, "scene21")  # 마이 바니 H 관람
	AchievementManager._check_event_achievements()
	assert_true(_unlocked("ACH_DEST_BUNNY"))

func test_onsen_h_event_unlocks_onsen():
	MetaProgression.add_npc_unlock_event(Constants.NPC_OL, "scene3")  # 레이나 온천 H 관람
	AchievementManager._check_event_achievements()
	assert_true(_unlocked("ACH_DEST_ONSEN"))

func test_other_h_event_unlocks_neither():
	MetaProgression.add_npc_unlock_event(Constants.NPC_GYARU, "scene1")  # 무관한 씬
	AchievementManager._check_event_achievements()
	assert_false(_unlocked("ACH_DEST_BUNNY"))
	assert_false(_unlocked("ACH_DEST_ONSEN"))

# -------------------- 무장착 클리어 --------------------
func test_no_item_run_when_equipment_empty():
	MetaProgression.save_data["equipment"] = []
	AchievementManager.check_no_item_run()
	assert_true(_unlocked("ACH_NO_ITEM_RUN"))

func test_no_item_run_blocked_when_equipped():
	MetaProgression.save_data["equipment"] = ["any_item"]
	AchievementManager.check_no_item_run()
	assert_false(_unlocked("ACH_NO_ITEM_RUN"))

# -------------------- 아이템박스(분실물) --------------------
func test_all_itembox_incomplete_does_not_unlock():
	AchievementManager._check_item_boxes()  # 새 게임 = 0개 수집
	assert_false(_unlocked("ACH_ALL_ITEMBOX"))

func test_all_itembox_complete_unlocks():
	# json의 모든 박스를 보유 상태로 구성한다.
	var data: Dictionary = AchievementManager.ITEM_BOX_SCENES.data
	for scene_path in data:
		for box in data[scene_path]:
			var n: String = box["name"]
			if n.begins_with("ticket") or n.begins_with("route_coin"):
				MetaProgression.save_data["box_getted_stage"].append(scene_path)
			else:
				MetaProgression.save_data["ability"][n] = true
	AchievementManager._check_item_boxes()
	assert_true(_unlocked("ACH_ALL_ITEMBOX"))

# [KR] 버그: 마지막 분실물이 코인/티켓 박스면 get_item_event/add_route_hint를 안 쏴서
# _check_item_boxes가 트리거되지 않아, 로드(evaluate_all) 전까지 ALL_ITEMBOX 해금이 누락됐다.
# 이제 코인/티켓 박스도 item_box_collected 시그널을 발신 → AchievementManager가 구독해
# deferred 판정하므로, 마지막 박스가 코인/티켓이어도 즉시(같은 프레임 끝) 해금된다.
func test_last_coin_ticket_box_unlocks_via_signal_not_on_reload():
	var data: Dictionary = AchievementManager.ITEM_BOX_SCENES.data
	# 코인/티켓 박스 1개를 마지막으로 남기고 나머지 전부 보유 상태로 만든다.
	var last_coin_scene := ""
	for scene_path in data:
		for box in data[scene_path]:
			var n: String = box["name"]
			if n.begins_with("ticket") or n.begins_with("route_coin"):
				if last_coin_scene == "":
					last_coin_scene = scene_path
					continue  # 이 박스만 미수집으로 남긴다
				MetaProgression.save_data["box_getted_stage"].append(scene_path)
			else:
				MetaProgression.save_data["ability"][n] = true
	assert_ne(last_coin_scene, "", "코인/티켓 박스가 최소 1개 있어야 테스트 성립")
	# 마지막 박스 미수집 상태 → 아직 미해금
	AchievementManager._check_item_boxes()
	assert_false(_unlocked("ACH_ALL_ITEMBOX"), "마지막 박스 전엔 미해금")
	# 마지막 코인/티켓 박스 획득(reward_item_box와 동일 순서: 기록 후 시그널 발신)
	MetaProgression.save_data["box_getted_stage"].append(last_coin_scene)
	GameEvents.emit_item_box_collected()
	assert_false(_unlocked("ACH_ALL_ITEMBOX"), "deferred flush 전엔 미해금")
	await get_tree().process_frame
	assert_true(_unlocked("ACH_ALL_ITEMBOX"), "코인/티켓 박스 신호로 즉시 해금 (로드 불필요)")

# -------------------- 타이밍(버그4): 완료 시점 즉시 해금, 로드 대기 없이 --------------------
# [KR] set_route_data는 route_data에 쓰기 "전에" stage_first_clear를 emit한다.
# 과거엔 AchievementManager가 같은 프레임에 동기로 먼저 돌아 직전 루트를 못 세고 해금 실패 →
# 다음 로드의 evaluate_all에서야 뒤늦게 해금되던 버그(路線マニア 갑툭튀).
# 이제 판정을 call_deferred로 미루므로, emit 시점엔 아직 미해금이고
# 같은 프레임 끝(flush)에 쓰기가 반영된 상태로 판정되어 즉시 해금된다.
func test_all_routes_unlocks_same_frame_not_on_reload():
	var total: int = AchievementManager._get_total_routes()
	if total <= 0:
		pass_test("route 총량 0 — 스킵")
		return
	# 마지막 1개만 남기고 미리 채운다.
	for i in (total - 1):
		MetaProgression.save_data["route_data"]["res://dummy_route_%d.tscn" % i] = {}
	# 실제 경로로 마지막 루트 추가 (내부: emit → write 순서)
	MetaProgression.set_route_data("res://final_route.tscn", {})
	# emit 직후(=deferred flush 전)에는 아직 해금되지 않아야 한다.
	assert_false(_unlocked("ACH_ALL_ROUTES"), "deferred 전엔 미해금")
	await get_tree().process_frame
	# 같은 프레임 끝 flush 후: route_data에 마지막 루트가 반영된 상태로 판정 → 해금.
	assert_true(_unlocked("ACH_ALL_ROUTES"), "프레임 flush 후 즉시 해금 (로드 불필요)")

# -------------------- 상점 전 경품 매진 (버그7): SOLD_OUT은 전 챕터 완매에만 --------------------
# [KR] 상점 품목(add_chapter 있는 업그레이드 + 힌트 + 박스맵 + 화폐)을 전부 최대 구매했을 때만 해금.
# add_chapter 없는 업그레이드(아이템박스/스토리 획득)는 상점 품목이 아니므로 제외 대상.
func _fill_all_shop_prizes():
	var item_data: ItemData = ItemData.new()
	for key in item_data.UPGRADES:
		if item_data.UPGRADES[key]["info"].get("add_chapter") == null:
			continue
		var r := item_data.UPGRADES[key]["res"] as AbilityUpgrade
		MetaProgression.save_data["ability"][r.id] = {"quantity": r.max_quantity}
	for key in item_data.HINT_ITEMS:
		var hr := item_data.HINT_ITEMS[key]["res"] as ShopHint
		MetaProgression.save_data["route_hint"].append(hr.hint_info.id)
	MetaProgression.init_save_data("box_map", [])
	for key in item_data.BOX_MAPS:
		var br := item_data.BOX_MAPS[key]["res"] as BoxMapItem
		MetaProgression.save_data["box_map"].append(br.id)
	MetaProgression.init_save_data("buyed_route_coin", {})
	for key in item_data.CURRENCY_ITEM:
		var cr := item_data.CURRENCY_ITEM[key]["res"] as CurrencyShopItem
		MetaProgression.save_data["buyed_route_coin"][cr.id] = cr.max_count

func test_shop_complete_all_prizes_unlocks_sold_out():
	_fill_all_shop_prizes()
	AchievementManager.check_shop_complete()
	assert_true(_unlocked("ACH_SOLD_OUT"))

func test_new_game_does_not_unlock_sold_out():
	AchievementManager.check_shop_complete()  # 새 게임 = 아무것도 안 삼
	assert_false(_unlocked("ACH_SOLD_OUT"))

func test_shop_only_hints_unlock_without_nonshop_hints():
	# [KR] 상점 품목만 전부 구매(비매물 힌트=story/item_box는 미보유)해도 SOLD_OUT 해금.
	# 비매물 힌트 획득은 check_shop_complete를 호출하지 않으므로, 분모에서 제외돼야 한다(버그 회귀).
	var item_data: ItemData = ItemData.new()
	for key in item_data.UPGRADES:
		if item_data.UPGRADES[key]["info"].get("add_chapter") == null:
			continue
		var r := item_data.UPGRADES[key]["res"] as AbilityUpgrade
		MetaProgression.save_data["ability"][r.id] = {"quantity": r.max_quantity}
	for key in item_data.HINT_ITEMS:
		if item_data.HINT_ITEMS[key]["info"].get("how_to_get") != "shop":
			continue  # 비매물 힌트는 일부러 채우지 않는다
		var hr := item_data.HINT_ITEMS[key]["res"] as ShopHint
		MetaProgression.save_data["route_hint"].append(hr.hint_info.id)
	MetaProgression.init_save_data("box_map", [])
	for key in item_data.BOX_MAPS:
		var br := item_data.BOX_MAPS[key]["res"] as BoxMapItem
		MetaProgression.save_data["box_map"].append(br.id)
	MetaProgression.init_save_data("buyed_route_coin", {})
	for key in item_data.CURRENCY_ITEM:
		var cr := item_data.CURRENCY_ITEM[key]["res"] as CurrencyShopItem
		MetaProgression.save_data["buyed_route_coin"][cr.id] = cr.max_count
	AchievementManager.check_shop_complete()
	assert_true(_unlocked("ACH_SOLD_OUT"), "비매물 힌트 없이도 상점 완매면 해금")

func test_only_upgrades_does_not_unlock_sold_out():
	# 업그레이드만 전부 사고 힌트/박스맵/화폐 미보유 → 미해금 (2장 조기 발급 방지의 핵심)
	var item_data: ItemData = ItemData.new()
	for key in item_data.UPGRADES:
		if item_data.UPGRADES[key]["info"].get("add_chapter") == null:
			continue
		var r := item_data.UPGRADES[key]["res"] as AbilityUpgrade
		MetaProgression.save_data["ability"][r.id] = {"quantity": r.max_quantity}
	AchievementManager.check_shop_complete()
	assert_false(_unlocked("ACH_SOLD_OUT"))
