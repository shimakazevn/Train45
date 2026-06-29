## 인게임 상점 UI 컴포넌트.
## [br][br]
## 어빌리티 업그레이드 목록을 표시하고, 티켓을 사용하여 구매할 수 있는 상점 화면.
## [UpgradeManager]와 연동되어 구매 가능한 아이템 목록을 관리하며,
## [signal upgrade_selected] 시그널로 선택된 업그레이드를 상위에 전달한다.
extends CanvasLayer

## 사용자가 업그레이드를 선택했을 때 [param upgrade]를 전달하는 시그널.
signal upgrade_selected(upgrade: AbilityUpgrade)

## 상점을 관리하는 [UpgradeManager] 참조.
@onready var upgrade_manager: UpgradeManager

## 업그레이드 항목 UI를 생성하기 위한 [PackedScene].
@export var upgrade_list_scene: PackedScene

## 어빌리티 항목들이 배치되는 컨테이너.
@onready var ability_container = %AbilityContainer
## 상점 나가기 버튼.
@onready var exit = %Exit

## 선택된 아이템 정보를 팝업으로 표시하는 [InfoTexture] 노드.
@onready var info_texture = $InfoTexture
## 선택된 아이템의 설명 텍스트.
@onready var info = %Info
## 선택된 아이템의 비용 텍스트.
@onready var info_cost = %InfoCost
## 선택된 아이템의 이름 텍스트.
@onready var info_name = %InfoName
## 선택된 아이템의 아이콘 [TextureRect].
@onready var item_icon: TextureRect = %ItemIcon
## 상점 UI 효과음 재생기.
@onready var shop_stream_player: UiSoundStreamPlayer = $ShopStreamPlayer
## 모든 아이템이 매진일 때 표시하는 [Label].
@onready var sold_out_label: Label = %SoldOutLabel

## 현재 보유 티켓 수를 표시하는 노드.
@onready var ticket_num = %TicketNum

## 상점 열림/닫힘 애니메이션을 재생하는 [AnimationPlayer].
@onready var animation_player = $TextureRect/AnimationPlayer

## [TicketManager] 노드 참조 (티켓 잔고 및 갱신 관리).
var ticket : Node

## 상점 초기화. 게임을 일시정지하고 열림 애니메이션을 재생한다.
func _ready():
	sold_out_label.hide()
	upgrade_manager = get_parent() as UpgradeManager
	animation_player.play("in")
	shop_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.SOUND_SHOP_ON)
	
	GameEvents.set_window_state(Constants.WINDOW_STATE_SHOP_OPEN, true)
	
	#test
	for child in ability_container.get_children():
		child.queue_free()
	#test
		
	info.text = ""
	info_cost.text = ""
	info_name.text = ""
	exit.grab_focus()
	get_tree().paused = true
	get_viewport().gui_focus_changed.connect(on_focus_changed)


## 구매 가능한 업그레이드 목록을 [param upgrades]로 설정한다.[br]
## [param current_upgrades]는 현재 보유 업그레이드 딕셔너리로, 매진 판별 및 구매 가능 여부에 사용된다.
func set_ability_upgrades(upgrades: Array[AbilityUpgrade], current_upgrades: Dictionary):
	var count := 0
	for upgrade in upgrades:
		if is_sold_out(upgrade, current_upgrades):
			continue

		var list_instance = upgrade_list_scene.instantiate() as AbilityBox
		ability_container.add_child(list_instance)
		list_instance.set_ability_list(upgrade, current_upgrades)
		list_instance.can_upgrade(upgrade, ticket.current_ticket, current_upgrades)
		list_instance.selected.connect(on_upgrade_selected.bind(upgrade))
		list_instance.cant_purchase.connect(item_cant_purchase)
		list_instance.button.mouse_entered.connect(_on_mouse_entered.bind(list_instance.button))
		if count == 0:
			list_instance.button.grab_focus()
		count += 1
	
	if count == 0:
		# [KR] 현재 챕터 샵이 비었다는 UI 표시만 한다.
		# ACH.SOLD_OUT(全경품 교환)은 챕터별 매진이 아니라 전 챕터·전 상점경품 완매 시 해금해야 하므로
		# 여기서 발급하지 않는다. 판정은 AchievementManager.check_shop_complete()가 담당(구매 시/로드 시).
		sold_out_label.show()
	else:
		sold_out_label.hide()

## [param upgrade] 아이템이 매진 상태인지 확인한다.[br]
## [ShopHint], [BoxMapItem], [CurrencyShopItem] 등 아이템 타입별로
## [MetaProgression]의 구매 이력과 [param current_upgrades]를 참고하여 판별한다.
func is_sold_out(upgrade: AbilityUpgrade, current_upgrades: Dictionary)-> bool:
	if upgrade is ShopHint: #종착점 힌트 아이템일 경우 메타데이터에서 획득한 아이템인지 확인
		if MetaProgression.has_route_hint(upgrade.hint_info.id):
			return true
	elif upgrade is BoxMapItem: # 분실물 맵일 경우 메타데이터에서 획득한 아이템인지 확인
		if MetaProgression.has_box_map(upgrade.id):
			return true
	elif upgrade is CurrencyShopItem:
		var buyed :int = MetaProgression.get_buyed_currency_item(upgrade.id)
		var is_max :int = upgrade.max_count
		if buyed >= is_max:
			return true #구매 가능 갯수보다 구매한 코인이 더 많을때 매진
	if current_upgrades.has(upgrade.id): #어빌리티 아이템인 경우 구매 단계 확인
		if current_upgrades[upgrade.id]["quantity"] >= upgrade.max_quantity:
			return true
	return false

## [param ticket_manager] 노드를 연결하고 티켓 갱신 시그널을 구독한다.
func get_ticket_manager(ticket_manager : Node):
	ticket = ticket_manager
	ticket.ticket_updated.connect(_on_ticket_updated)
	ticket_num.text = str(ticket.current_ticket)

## 업그레이드 항목이 선택되었을 때 [signal upgrade_selected]를 발생시킨다.
func on_upgrade_selected(upgrade: AbilityUpgrade):
	upgrade_selected.emit(upgrade)
	
## 티켓 수량이 [param num]으로 갱신되었을 때 UI와 각 아이템의 구매 가능 상태를 업데이트한다.
func _on_ticket_updated(num : int):
	ticket_num.text = str(num)
	var item_list = ability_container.get_children()
	for item in item_list:
		if not (item is AbilityBox):
			return
		item.set_list_update(num)

## 나가기 버튼이 눌렸을 때 닫힘 애니메이션을 재생하고 효과음을 출력한다.
func _on_exit_pressed():
	animation_player.play("out")
	shop_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.SOUND_SHOP_OFF)

## ESC 키 입력 시 상점을 닫는다.
func _input(event):
	if event.is_action_pressed("esc"):
		_on_exit_pressed()

## 상점을 완전히 닫고 일시정지를 해제한 뒤 자기 자신을 제거한다.
func shop_out():
	get_tree().paused = false
	upgrade_manager.shop_state_changed.emit(upgrade_manager.ShopState.CLOSE)
	GameEvents.set_window_state(Constants.WINDOW_STATE_SHOP_OPEN, false)
	queue_free()

## 포커스된 [param button]의 아이템 정보를 상세 정보 패널에 반영한다.
func on_focus_changed(button : Control):
	if not button is AbilityButton:
		return
	else:
		var ability = button.ability as AbilityBox
		if info_name.text == ability.upgrade_info.name:
			return
		
		info_texture.anim_play()
		info.text = ability.upgrade_info.description
		info_name.text = ability.upgrade_info.name
		info_cost.text = str(ability.upgrade_info.cost)
		item_icon.texture = ability.upgrade_info.icon as CompressedTexture2D

## 마우스가 [param button] 위에 올라갔을 때 [method on_focus_changed]를 호출한다.
func _on_mouse_entered(button: Control):
	on_focus_changed(button)

## 아이템 구매 시 구매 효과음을 재생한다.
func item_purchase():
	shop_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.SOUND_SHOP_BUY)

## 품절이거나 티켓이 부족해 구매하지 못했을 때 효과음을 재생한다.
func item_cant_purchase():
	shop_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.SOUND_SHOP_CANT_BUY)
