## 인벤토리 버튼 아이콘.
## 특정 챕터 이상에서 해금되며, 버튼 클릭 또는 단축키로 인벤토리를 열 수 있다.
## 상점 상태·튜토리얼에 따라 활성/비활성을 자동 전환한다.
extends Button

## 인벤토리 매니저 참조.
@export var inventory_manager: InventoryManager
## 업그레이드 매니저 참조.
@export var upgrade_manager: UpgradeManager
## 현재 코스트 표시 라벨.
@export var current_cost_label: Label

## 인벤토리 아이콘이 표시되기 시작하는 챕터.
const VIEW_CHAPTER := 2

## 시그널 연결 및 챕터에 따른 초기 표시 상태를 설정한다.
func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	inventory_manager.cost_update.connect(_cost_updated)
	upgrade_manager.shop_state_changed.connect(_on_shop_state_change)
	if is_collect_chapter():
		inven_on(true)
	else:
		inven_on(false)

## 단축키 입력 시 인벤토리를 연다. 아이콘이 표시 중이고 다른 창이 없을 때만 동작한다.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(Constants.TRAIN_KEY_INVENTORY) and self.visible: # 화면에 아이콘이 나타날때만 단축키 가능
		if _can_open():
			inventory_on()
		else:
			#print("현재 해당 창이 열려있기 때문에 사용할 수 없습니다 : " + str(GameEvents.get_window_state_array()))
			return

## 인벤토리를 열 수 있는 상태인지 확인한다.
## 다른 윈도우가 열려있거나 타임라인 재생 중이면 [code]false[/code]를 반환한다.
func _can_open()-> bool:
	if GameEvents.get_window_state_array().size() > 0:
		return false
	elif Dialogic.current_timeline:
		return false
	elif disabled:
		return false
	else:
		return true

## 버튼 클릭 콜백. 인벤토리를 연다.
func _on_pressed() -> void:
	inventory_on()

## 인벤토리를 오픈 상태로 전환한다.
func inventory_on():
	inventory_manager.inventory.set_inventory_state(Inventory.InvenState.INVEN_OPEN)

## 인벤토리 아이콘 표시/숨김을 설정한다.
## [param on]이 [code]true[/code]이고 해금 챕터 이상이면 표시, 아니면 숨긴다.
func inven_on(on: bool):
	if on and is_collect_chapter():
		show()
		disabled = false
	else:
		hide()
		disabled = true

## 현재 챕터가 인벤토리 해금 챕터([member VIEW_CHAPTER]) 이상인지 확인한다.
func is_collect_chapter()->bool:
	if MetaProgression.get_current_chapter() >= VIEW_CHAPTER:
		return true
	return false

## 상점 상태 변경 콜백. 상점이 열리면 아이콘을 숨기고, 닫히면 표시한다.
func _on_shop_state_change(state: int):
	if state == upgrade_manager.ShopState.OPEN:
		inven_on(false)
	else:
		inven_on(true)

## Dialogic 시그널 콜백. 튜토리얼 중 비활성, 튜토리얼 종료 시 활성화한다.
func _on_dialogic_signal(arg: String) -> void:
	match arg:
		"kankannavi":
			disabled = true
		"tuto_exit":
			disabled = false

## 코스트 라벨 텍스트를 [code]현재/최대[/code] 형식으로 갱신한다.
func _update_cost(current_cost:int, max_cost:int):
	current_cost_label.text = str(current_cost) + "/" + str(max_cost)

## 코스트 업데이트 시그널 콜백. 라벨 갱신을 트리거한다.
func _cost_updated(current_cost:int, max_cost:int):
	_update_cost(current_cost, max_cost)
