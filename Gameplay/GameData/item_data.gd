class_name ItemData

const ITEM_DATA := preload("res://Gameplay/GameData/item_data_json.json")

# {id : path}
var UPGRADES: Dictionary = {}
var HINT_ITEMS: Dictionary = {}
var BOX_MAPS: Dictionary = {}
var CURRENCY_ITEM: Dictionary = {}

func _init() -> void:
	var items: Dictionary = ITEM_DATA.data.get("item_data", {})

	for key in items.keys():
		var item_info: Dictionary = items[key]

		# path 유효성 검사
		var raw_path = item_info.get("path")
		if raw_path == null or raw_path == "":
			continue

		var path: String = str(raw_path)
		var resource: Resource = ResourceLoader.load(path)
		var item_type: String = item_info.get("item_type", "")

		# 타입별 저장 딕셔너리 결정
		var target_dict: Dictionary = {}
		match item_type:
			"upgrade":
				target_dict = UPGRADES
			"hint_item":
				target_dict = HINT_ITEMS
			"box_map":
				target_dict = BOX_MAPS
			"currency":
				target_dict = CURRENCY_ITEM
			_:
				push_warning("⚠ Unknown item_type for item: %s" % key)
				continue

		# 키가 없으면 초기화 후 리소스 저장
		if not target_dict.has(key):
			target_dict[key] = {}

		target_dict[key]["res"] = resource
		target_dict[key]["info"] = item_info
	print("✅ Loaded upgrades: %d, hint items: %d, box maps: %d, currency items: %d" %
	[UPGRADES.size(), HINT_ITEMS.size(), BOX_MAPS.size(), CURRENCY_ITEM.size()])


enum ItemTypes {ABILITY, ROUTE_HINT, CURRENCY}
##상점 아이템의 종류에 따라 해당 사전 안의 리소스를 가져옵니다
func get_item(_item_name: String, type: ItemTypes) -> Resource:
	var dict : Dictionary
	match type:
		ItemTypes.ABILITY:
			dict = UPGRADES
		ItemTypes.ROUTE_HINT:
			dict = HINT_ITEMS
		ItemTypes.CURRENCY:
			dict = CURRENCY_ITEM
	return get_resource_from_dict(dict, _item_name)




func get_resource_from_dict(dict: Dictionary, key: String) -> Resource:
	if dict.has(key):
		var item = dict[key]
		return item["res"]
	else:
		push_error("%s가 없습니다." % key)
		return null

func get_item_dict_count(_item_name: String) -> int:
	var keys = UPGRADES.keys()
	if keys.has(_item_name):
		return keys.find(_item_name)
	return -1

#func quantity_resizing(ability: Dictionary) -> Dictionary:
	#for ability_name in ability:
		#if UPGRADES.has(ability_name):
			#if UPGRADES[ability_name].quantity != ability_name.size():
				#ability_name.resize(UPGRADES[ability_name].quantity)
	#return ability

## 종착점 힌트 아이템이거나 박스 찾기 아이템일 경우 참을 반환
func is_type_hint(upgrade: AbilityUpgrade)-> bool:
	if upgrade is ShopHint:
		return true
	return false

func is_type_box_map(upgrade: AbilityUpgrade)-> bool:
	if upgrade is BoxMapItem:
		return true
	return false

func is_type_currency(upgrade: AbilityUpgrade)-> bool:
	if upgrade is CurrencyShopItem:
		return true
	return false
