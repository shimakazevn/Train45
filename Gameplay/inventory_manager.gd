## 장비 코스트(비용) 시스템을 관리하는 매니저.
## 발견한 노선 수와 추가 코스트를 합산하여 최대 코스트를 계산하고,
## [signal cost_update]를 통해 UI에 현재/최대 코스트를 전달한다.
extends Node
class_name InventoryManager

## 코스트가 변경될 때 [param current_cost]와 [param total_cost]를 전달하는 시그널
signal cost_update(current_cost:int, total_cost:int)

## 인벤토리 UI 노드 참조
@onready var inventory: Inventory = %Inventory
## 장비 노드 참조
@onready var equipment: Node = $Equipment

## 최대 장비 코스트 (발견 노선 수 + 추가 코스트로 계산)
var max_cost: int = 15
## 현재 사용 중인 장비 코스트 합계
var current_cost: int

func _ready() -> void:
	GameEvents.stage_clear.connect(_on_stage_clear)
	GameEvents.stage_change.connect(_on_stage_changed)
	GameEvents.set_equip_cost.connect(_on_equip_cost)
	update_max_cost()
	await get_tree().process_frame
	cost_update.emit(current_cost, max_cost)

## 최대 코스트를 재계산하고 [signal cost_update]를 발생시킨다.
func update_max_cost():
	max_cost = _get_max_cost()
	cost_update.emit(current_cost, max_cost)

## 현재 코스트에 [param cost]를 누적 합산하고 [signal cost_update]를 발생시킨다.
func set_current_cost(cost: int):
	current_cost += cost
	cost_update.emit(current_cost, max_cost)

## 스테이지 클리어 시 최대 코스트를 갱신한다.
func _on_stage_clear():
	update_max_cost()

## 스테이지 전환 시 최대 코스트를 갱신한다.
func _on_stage_changed():
	update_max_cost()

## 발견한 노선 수([method MetaProgression.get_routes_dict])와
## 추가 코스트([method MetaProgression.get_extra_cost])를 합산하여 최대 코스트를 반환한다.
func _get_max_cost()-> int:
	var new_max_cost: int = 0
	var route_found_count: int = MetaProgression.get_routes_dict().size()
	var extra_cost: int = MetaProgression.get_extra_cost()
	new_max_cost = route_found_count + extra_cost
	return new_max_cost

## 장비 코스트 변경 시그널 수신 시 최대 코스트를 갱신한다.
func _on_equip_cost(_cost: int):
	update_max_cost()
