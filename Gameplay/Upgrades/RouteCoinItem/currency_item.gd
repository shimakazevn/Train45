extends AbilityUpgrade
class_name CurrencyShopItem

enum CurrencyType { ROUTE_COIN, EQUIP_COST }
@export var currency_type: CurrencyType
@export var value: int = 1
##구매 가능한 최대 수량
@export var max_count: int = 1
