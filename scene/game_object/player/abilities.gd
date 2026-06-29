## [KR] 플레이어의 액티브 어빌리티를 관리하는 컴포넌트.
## [EN] Component that manages the player's active abilities.
## [KR] [AbilityGet] 장비에 대응하는 [AbilityController]를 자식 노드로 인스턴스화하여
## [KR] 장비 목록과 동기화한다.
## [EN] Instantiates [AbilityController] corresponding to [AbilityGet] equipment as child nodes and
## [EN] syncs with the equipment list.
extends Node
class_name PlayerAbilities

## [KR] 어빌리티를 소유하는 [Player] 참조
## [EN] Reference to the [Player] that owns the abilities.
@export var player :Player
## [KR] 인벤토리 매니저 참조 (그룹에서 검색)
## [EN] Reference to the inventory manager (searched from group).
@onready var inven_manager : InventoryManager

## [KR] 초기화 시 인벤토리 매니저를 검색하고 장비 갱신 시그널을 연결한다.
## [EN] On initialization, searches for the inventory manager and connects the equipment update signal.
func _ready() -> void:
	inven_manager = get_tree().get_first_node_in_group("inventorymanager")
	GameEvents.update_equip_item.connect(_on_update_equip)


## [KR] [param ability]의 씬을 인스턴스화하여 [AbilityController]로 자식에 추가한다.
## [EN] Instantiates the scene of [param ability] and adds it as a child [AbilityController].
func ability_active(ability: AbilityGet):
	var ability_instance = ability.ability_controller_scene.instantiate() as AbilityController
	ability_instance.id = ability.id
	add_child(ability_instance)

## [KR] 현재 활성화된 모든 어빌리티 자식 노드를 제거한다.
## [EN] Removes all currently active ability child nodes.
func erase_active():
	var children = get_children()
	for i in children:
		i.queue_free()

## [KR] [signal GameEvents.update_equip_item] 수신 시 장비 동기화를 수행한다.
## [EN] Performs equipment sync when [signal GameEvents.update_equip_item] is received.
func _on_update_equip(equipment_list: Array[AbilityUpgrade]):
	update_equip(equipment_list)

## [KR] [param equipment_list]와 현재 자식 노드를 비교하여 어빌리티를 동기화한다.
## [KR] 새로 추가된 [AbilityGet]은 인스턴스화하고, 목록에서 제거된 어빌리티는 삭제한다.
## [EN] Syncs abilities by comparing [param equipment_list] with current child nodes.
## [EN] Instantiates newly added [AbilityGet], and removes abilities that were removed from the list.
func update_equip(equipment_list: Array[AbilityUpgrade]):
	var current_abilities = get_children()
	
	for i in equipment_list:
		var should_add = true
		if i is AbilityGet:
			if current_abilities == []:
				ability_active(i)
			else:
				for j in current_abilities:
					if (j as AbilityController).id == (i as AbilityGet).id:
						should_add = false
						break
				if should_add:
					ability_active(i)

	# [KR] equipment_list에 없는 경우 삭제하는 부분
	# [EN] Section that removes items not in equipment_list
	for j in current_abilities:
		var should_remove = true
		for i in equipment_list:
			if i is AbilityGet and (j as AbilityController).id == (i as AbilityGet).id:
				should_remove = false
				break
		
		if should_remove:
			j.queue_free()  # [KR] 리스트에 없는 기존 노드 삭제 / [EN] Remove existing nodes not in the list
