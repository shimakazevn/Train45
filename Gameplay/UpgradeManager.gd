extends Node
class_name UpgradeManager
## [KR] 상점(업그레이드) 시스템 매니저.
## [EN] Shop (upgrade) system manager.
## [br][KR] 어빌리티·힌트·분실물 지도·재화 등 다양한 아이템의 구매와 적용을 총괄한다.
## [br][EN] Manages the purchase and application of various items including abilities, hints, lost item maps, and currency.
## [KR] 챕터 진행도와 읽은 이벤트에 따라 상점 품목이 동적으로 갱신된다.
## [EN] Shop items are dynamically updated based on chapter progress and read events.

## [KR] 상점 열림/닫힘 상태 열거형.
## [EN] Shop open/close state enum.
enum ShopState {OPEN, CLOSE}
## [KR] 상점 상태가 변경될 때 발생한다. [param state]로 [enum ShopState] 값을 전달한다.
## [EN] Emitted when shop state changes. Passes [enum ShopState] value via [param state].
signal shop_state_changed(state:ShopState)
## [KR] 아이템 구매가 완료되었을 때 발생한다.
## [EN] Emitted when an item purchase is completed.
signal item_purchase

## [KR] 티켓 잔액을 관리하는 노드 참조.
## [EN] Reference to the node that manages ticket balance.
@export var ticket_manager: Node
## [KR] 상점 UI 씬 리소스.
## [EN] Shop UI scene resource.
@export var shop_scene: PackedScene

## [KR] 현재 보유 업그레이드 목록. [code]{id: {resource, quantity}}[/code] 구조.
## [EN] Currently owned upgrade list. [code]{id: {resource, quantity}}[/code] structure.
var current_upgrade = {}
## [KR] 상점에 표시할 전체 아이템 테이블.
## [EN] Full item table to display in the shop.
var upgrade_list : ShopTable = ShopTable.new()
## [KR] 아이템 데이터 정의 (업그레이드, 힌트, 분실물 지도, 재화).
## [EN] Item data definitions (upgrades, hints, lost item maps, currency).
var item_data : ItemData = ItemData.new()

## [KR] 시그널 연결 및 저장 데이터로부터 기존 구매 내역을 복원한다.
## [EN] Connects signals and restores existing purchase history from save data.
func _ready():
	GameEvents.get_item_event.connect(_get_item_event)
	GameEvents.set_chapter.connect(_on_chapter_change)
	GameEvents.add_read_history.connect(_on_add_read_history)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	# [KR] 상점 목록에 아이템 추가
	# [EN] Add items to shop list
	add_shop_items(MetaProgression.get_current_chapter())
	
	# [KR] 저장 파일에서 아이템 구매 상황 불러와서 적용
	# [EN] Load and apply item purchase status from save file
	for i in MetaProgression.get_save_data_ability():
		for j in upgrade_list.items:
			if j["item"].id == i:
				var has_upgrade = current_upgrade.has(j["item"].id)
				if !has_upgrade:
					current_upgrade[j["item"].id] ={
						"resource": j["item"],
						"quantity": MetaProgression.get_upgrade_count(i)
					}
				GameEvents.emit_ability_upgrade_added(j["item"], current_upgrade)
	#print(current_upgrade)
	#on_shop_open()

## [KR] [param target_chapter]에 해당하는 아이템들을 상점 목록에 추가한다.
## [EN] Adds items corresponding to [param target_chapter] to the shop list.
## [br][KR] 업그레이드·힌트·분실물 지도·재화 각 카테고리별로 조건을 확인하여 추가한다.
## [br][EN] Checks conditions for each category (upgrades, hints, lost item maps, currency) and adds them.
func add_shop_items(target_chapter: int):
	_add_items_from_dict(item_data.UPGRADES, "add_chapter", target_chapter, "upgrade")
	_add_items_from_dict(item_data.HINT_ITEMS, "add_dialogue", target_chapter, "hint", true)
	_add_items_from_dict(item_data.BOX_MAPS, "add_dialogue", target_chapter, "box_map", true)
	_add_items_from_dict(item_data.CURRENCY_ITEM, "add_chapter", target_chapter, "currency")


## [KR] [param item_dict]에서 조건에 맞는 아이템을 상점에 추가하는 내부 헬퍼.
## [EN] Internal helper that adds qualifying items from [param item_dict] to the shop.
## [br][KR] [param is_dialogue]가 [code]true[/code]이면 읽은 이벤트 기반, 아니면 챕터 번호 기반으로 필터링한다.
## [br][EN] Filters by read events if [param is_dialogue] is [code]true[/code], otherwise by chapter number.
func _add_items_from_dict(item_dict: Dictionary, condition_key: String, target_chapter: int, label: String, is_dialogue: bool=false):
	for item in item_dict:
		var info = item_dict[item].get("info", {})
		var res = item_dict[item].get("res", null)
		var condition = info.get(condition_key)

		if condition == null:
			continue

		if is_dialogue:
			# [KR] 힌트 아이템: add_dialogue가 이미 읽힌 이벤트인지 체크
			# [EN] Hint item: check if add_dialogue is an already read event
			if MetaProgression.has_read_event(condition):
				upgrade_list.add_item(res, 0)
				print("%s add = %s" % [label, item])
		else:
			# [KR] 일반 아이템: 챕터 조건 확인
			# [EN] Normal item: check chapter condition
			if condition <= target_chapter:
				upgrade_list.add_item(res, 0)
				print("%s add = %s" % [label, item])


## [KR] [param upgrade] 아이템 구매를 처리한다.
## [EN] Processes the purchase of [param upgrade] item.
## [br][KR] 티켓 잔액 확인 → 금액 차감 → 아이템 종류별 분기(힌트/분실물 지도/재화/어빌리티)를 수행한다.
## [br][EN] Verifies ticket balance → deducts amount → branches by item type (hint/lost item map/currency/ability).
func apply_upgrade(upgrade: AbilityUpgrade):
	var current_quantity_value = 0
	if current_upgrade.has(upgrade.id):
		current_quantity_value = current_upgrade[upgrade.id]["quantity"]
	var item_price = upgrade.price[current_quantity_value]
	if item_price > ticket_manager.current_ticket:
		return
		
	# [KR] 계산
	# [EN] Calculate
	purchase_item(item_price)
	
	# [KR] 구매 아이템의 종류에 따른 처리
	# [EN] Process based on purchased item type
	if item_data.is_type_hint(upgrade):
		# [KR] 힌트 아이템일 경우 세이브 데이터의 종착점 힌트에 저장한다
		# [EN] For hint items, save to destination hint in save data
		GameEvents.emit_add_route_hint(upgrade.hint_info.id)
	elif item_data.is_type_box_map(upgrade):
		# [KR] 분실물 찾기 아이템일 경우 세이브 데이터의 종착점 힌트에 저장한다
		# [EN] For lost item map, save to destination hint in save data
		GameEvents.emit_add_box_map(upgrade.id)
	elif item_data.is_type_currency(upgrade):
		# [KR] 재화 아이템의 경우
		# [EN] For currency items
		var currency: CurrencyShopItem = upgrade
		match currency.currency_type:
			CurrencyShopItem.CurrencyType.ROUTE_COIN: # [KR] 기념 주화 / [EN] Commemorative coin
				GameEvents.emit_set_coin(currency.value)
				MetaProgression.add_buyed_currency_item(currency.id, currency.value) # [KR] 상점에서 구매한 코인 갯수 기록 / [EN] Record coins purchased from shop
			CurrencyShopItem.CurrencyType.EQUIP_COST: # [KR] 장착 코스트 / [EN] Equipment cost
				GameEvents.emit_set_equip_cost(currency.value)
				MetaProgression.add_buyed_currency_item(currency.id, currency.value) # [KR] 상점에서 구매한 코인 갯수 기록 / [EN] Record coins purchased from shop
	else:
		# [KR] 어빌리티 아이템일 경우 세이브 데이터의 어빌리티 칸에 저장한다
		# [EN] For ability items, save to the ability slot in save data
		var has_upgrade = current_upgrade.has(upgrade.id)
		if !has_upgrade:
			current_upgrade[upgrade.id] ={
				"resource": upgrade,
				"quantity": 1
			}
		else:
			current_upgrade[upgrade.id]["quantity"] += 1
		GameEvents.emit_ability_upgrade_added(upgrade, current_upgrade)

	GameEvents.emit_get_ticket(upgrade, ticket_manager.current_ticket, current_upgrade)

	# [KR] 상점 경품을 모두 사들였는지(全경품 교환 = ACH.SOLD_OUT) 판정.
	# 위 구매 처리(어빌리티/힌트/박스맵/화폐)가 모두 동기로 저장된 뒤를 보장하기 위해 deferred로 미룬다.
	AchievementManager.check_shop_complete.call_deferred()

## [KR] 아이템 금액을 차감하고 구매 통계를 기록한다.
## [EN] Deducts item price and records purchase statistics.
## [br][KR] [param item_price]가 0 이하이면 차감 과정을 건너뛴다.
## [br][EN] Skips deduction if [param item_price] is 0 or less.
func purchase_item(item_price: int):
	if item_price <= 0:
		return
	
	GameEvents.emit_set_ticket("minus", item_price)
	#butler_love_up(item_price)
	MetaProgression.add_ticket_shop_used(item_price)
	item_purchase.emit()

## [KR] 상점 외부에서 발생하는 아이템 획득을 처리한다.
## [EN] Handles item acquisition that occurs outside the shop.
## [br][KR] [signal GameEvents.get_item_event] 콜백으로, [param item_name]에 해당하는 업그레이드를 적용한다.
## [br][EN] As a [signal GameEvents.get_item_event] callback, applies the upgrade corresponding to [param item_name].
func _get_item_event(item_name: String):
	if item_data.UPGRADES.has(item_name):
		apply_upgrade(item_data.UPGRADES[item_name]["res"])
	else:
		push_error("해당 item_name이 const에 존재하지 않습니다.",item_name)

## [KR] 상점에 표시할 업그레이드 목록을 [code]Array[AbilityUpgrade][/code]로 반환한다.
## [EN] Returns the upgrade list to display in the shop as [code]Array[AbilityUpgrade][/code].
func pick_upgrades():
	var chosen_upgrades: Array[AbilityUpgrade] = []
	
	for item in upgrade_list.items:
		chosen_upgrades.append(item["item"])
		
	return chosen_upgrades
	
## [KR] 상점 UI에서 업그레이드를 선택했을 때의 콜백. [method apply_upgrade]를 호출한다.
## [EN] Callback when an upgrade is selected in the shop UI. Calls [method apply_upgrade].
func on_upgrade_selected(upgrade: AbilityUpgrade):
	apply_upgrade(upgrade)

## [KR] 상점 UI를 열고 초기화한다.
## [EN] Opens and initializes the shop UI.
## [br][KR] 상점 씬을 인스턴스화하고, 티켓 매니저와 업그레이드 목록을 전달한다.
## [br][EN] Instantiates the shop scene and passes the ticket manager and upgrade list.
func on_shop_open():
	shop_state_changed.emit(ShopState.OPEN)
	var shop_screen_instance = shop_scene.instantiate()
	add_child(shop_screen_instance)
	var chosen_upgrades = pick_upgrades()
	shop_screen_instance.get_ticket_manager(ticket_manager)	
	shop_screen_instance.set_ability_upgrades(chosen_upgrades as Array[AbilityUpgrade], current_upgrade)
	shop_screen_instance.upgrade_selected.connect(on_upgrade_selected)
	item_purchase.connect(shop_screen_instance.item_purchase)

## [KR] Dialogic 시그널 콜백. [code]"shop_open"[/code] 인자가 오면 상점을 연다.
## [EN] Dialogic signal callback. Opens the shop when [code]"shop_open"[/code] argument is received.
func _on_dialogic_signal(arg: String):
	if arg == "shop_open":
		on_shop_open()

## [KR] 챕터 변경 시 새로운 챕터에 맞는 아이템을 상점에 추가한다.
## [EN] Adds items matching the new chapter to the shop on chapter change.
func _on_chapter_change(chapter: int):
	add_shop_items(chapter)

#func butler_love_up(use_price: int):
	#var add_love = int(use_price/floor(3)) # floor() = 반올림
	#GameEvents.emit_get_npc_exp(add_love, GameEvents.NpcTypes.BUTLER) ##다른 방법으로 호감도 상승하게 변경됨
	#pass

## [KR] 읽은 이벤트 히스토리 추가 시 특정 이벤트에 연동된 아이템을 상점에 추가한다.
## [EN] Adds items linked to specific events to the shop when read event history is added.
## [br]Why: 집사 인간 이벤트 등 특정 이벤트 완료 후에만 해금되는 상점 아이템이 있기 때문.
func _on_add_read_history(event_name: String):
	match event_name:
		Constants.QUESTLINE_BUTLER_HUMAN:
			add_shop_items(5) ## [KR] 집사 인간 이벤트 후 아이템 추가 / [EN] Add items after butler human event
