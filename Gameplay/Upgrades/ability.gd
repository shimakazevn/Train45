extends HBoxContainer
class_name AbilityBox
#상점의 아이템 버튼

signal selected
signal cant_purchase

var upgrade_info: AbilityUpgrade
var is_buyed: bool = false
var is_affordable: bool = true
@onready var ability_name = %AbilityName
var price_data : int
var cost: int
var quantity_data : int
var quantity_max_data : int
@onready var price_label = %Price
@onready var current_quantity_label = %Quantity
@onready var stock_lable: Label = %StockLable

@onready var button = %Button
var infomation : String
@onready var highlight_shader: ColorRect = $AbilityNamePanel/HighlightShader

func _ready():
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	GameEvents.get_ticket.connect(on_get_ticket)
	stock_lable.hide()

##상점 오픈시 호출됩니다. 
func set_ability_list(upgrade: AbilityUpgrade, current_upgrade: Dictionary):
	upgrade_info = upgrade
	
	set_quantity_data(upgrade_info, current_upgrade)
	if quantity_data >= quantity_max_data:
		max_quantity_check(quantity_data, quantity_max_data)
	else:
		quantity_data = min(quantity_data, upgrade_info.price.size()-1)
		set_price_data(upgrade_info.price[quantity_data])
	ability_name.text = upgrade_info.name
	cost = upgrade_info.cost
	infomation = upgrade_info.description
	
	if upgrade_info is CurrencyShopItem:
		if upgrade_info.max_count > 1:
			stock_lable.show()
			stock_lable.text = get_stock_string()

func can_upgrade(upgrade: AbilityUpgrade, current_ticket : int, current_upgrade: Dictionary):
	set_quantity_data(upgrade, current_upgrade)

	#아이템 구매여부 체크
	#힌트 아이템일 경우 메타 데이터에서 해당 힌트를 얻었는지 확인한다
	#어빌리티 아이템일 경우 최고 등급인지 확인한다
	if upgrade is ShopHint:
		if MetaProgression.has_route_hint(upgrade.hint_info.id):
			set_is_buyed()
		else:
			enough_money_check(upgrade.price[quantity_data], current_ticket)
	if upgrade is BoxMapItem: # 분실물 위치 찾기 아이템일 경우
		if MetaProgression.has_box_map(upgrade.id):
			set_is_buyed()
		else:
			enough_money_check(upgrade.price[quantity_data], current_ticket)
	else:
		max_quantity_check(quantity_data, quantity_max_data)
		if quantity_data >= quantity_max_data:
			return
		enough_money_check(upgrade.price[quantity_data], current_ticket)

func set_quantity_data(upgrade: AbilityUpgrade, current_upgrade: Dictionary):
	quantity_max_data = upgrade.max_quantity
	if current_upgrade.has(upgrade.id):
		quantity_data = current_upgrade[upgrade.id]["quantity"]
	current_quantity_label.text = str(quantity_data)

func set_price_data(price: int):
	price_data = price
	price_label.text = str(price)
	
func enough_money_check(price: int, current_ticket: int):
	if is_buyed:
		modulate.a8 = 180
		return

	if price > current_ticket:
		modulate.a8 = 180
		is_affordable = false
	else:
		modulate.a8 = 255
		is_affordable = true

func max_quantity_check(current_quantity: int, max_quantity: int):
	if current_quantity >= max_quantity:
		set_is_buyed()

func set_is_buyed():
	if not is_buyed:
		is_buyed = true
		modulate.a8 = 180
		button.disabled = true
		highlight_shader.start_highlight.emit()
		price_label.text = tr("SHOP_SOLD_OUT")

## 상점 목록 새로고침
func set_list_update(current_ticket_num: int):
	enough_money_check(price_data, current_ticket_num)
	max_quantity_check(quantity_data, quantity_max_data)
	if upgrade_info is ShopHint: # 힌트 아이템일 경우
		if MetaProgression.has_route_hint(upgrade_info.hint_info.id):
			set_is_buyed()
	elif upgrade_info is BoxMapItem: # 분실물 맵일 경우
		if MetaProgression.has_box_map(upgrade_info.id):
			set_is_buyed()
	elif upgrade_info is CurrencyShopItem:
		await get_tree().process_frame
		stock_lable.text = get_stock_string()
		var buyed :int = MetaProgression.get_buyed_currency_item(upgrade_info.id)
		var is_max :int = upgrade_info.max_count
		if buyed >= is_max:
			set_is_buyed()

func _on_button_pressed():
	if not is_affordable:
		cant_purchase.emit()
		return
	selected.emit()
	

##아이템 구매 후 해당 아이템의 정보 업데이트(품절 여부, 단계)
func on_ability_upgrade_added(ability_upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	if ability_name.text == ability_upgrade.name:
		set_quantity_data(ability_upgrade, current_upgrades)
		if quantity_data >= quantity_max_data:
			max_quantity_check(quantity_data, quantity_max_data)
		else:
			set_price_data(ability_upgrade.price[quantity_data])


func on_get_ticket(ability_upgrade: AbilityUpgrade, current_ticket : int, current_upgrade: Dictionary):
	if upgrade_info.id == ability_upgrade.id:
		can_upgrade(ability_upgrade, current_ticket, current_upgrade)

func get_stock_string()-> String:
	return str(MetaProgression.get_buyed_currency_item(upgrade_info.id)) + "/" + str(upgrade_info.max_count)
