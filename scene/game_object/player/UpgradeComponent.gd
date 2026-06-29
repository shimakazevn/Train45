## [KR] 플레이어의 장비 업그레이드를 관리하는 컴포넌트.
## [KR] [InventoryManager]의 장비 목록을 기반으로 속도, 탐지 영역, 수집 영역,
## [KR] 충전 시간, 생명력 등의 스탯을 적용한다.
## [EN] Component that manages the player's equipment upgrades.
## [EN] Based on the equipment list from [InventoryManager], applies stats such as
## [EN] speed, detection area, collection area, charge time, and life.
extends Node

## [KR] 속도 업그레이드 식별자
## [EN] Speed upgrade identifier
const SPEED_UP_ID = "speed_up"
## [KR] 탐지 영역 업그레이드 식별자
## [EN] Detection area upgrade identifier
const DETECT_AREA_UP_ID = "detect_area_up"
## [KR] 수집 영역 업그레이드 식별자
## [EN] Collection area upgrade identifier
const COLLECT_AREA_UP_ID = "collect_area_up"
## [KR] 탐지 충전 시간 업그레이드 식별자
## [EN] Detection charge time upgrade identifier
const AREA_CHARGE_TIME_UP = "area_charge_time_up"
## [KR] 생명력 업그레이드 식별자
## [EN] Life upgrade identifier
const LIFE_UP = "life_up"

## [KR] 인벤토리 매니저 참조 (그룹에서 검색)
## [EN] Inventory manager reference (searched from group)
@onready var inven_manager : InventoryManager
## [KR] 플레이어 액티브 어빌리티를 관리하는 [PlayerAbilities] 참조
## [EN] Reference to [PlayerAbilities] that manages player active abilities
@export var abilities: PlayerAbilities

# [KR] 플레이어 노드와 연결될 변수
# [EN] Variable to be linked with the player node
## [KR] 업그레이드를 적용할 대상 [Player]
## [EN] Target [Player] to apply upgrades to
@export var player: Player

## [KR] 초기화 시 [signal Player.player_enable]에 연결하고 인벤토리 매니저를 검색한다.
## [EN] On initialization, connects to [signal Player.player_enable] and searches for the inventory manager.
func _ready() -> void:
	player.player_enable.connect(_on_player_enable)
	inven_manager = get_tree().get_first_node_in_group("inventorymanager")

## [KR] 플레이어 활성화 시 장비 업그레이드 적용을 지연 호출한다.
## [EN] Defers equipment upgrade application when the player is enabled.
func _on_player_enable():
	call_deferred("delay_update_equip")


## [KR] 프레임 지연 후 장비 목록을 적용하고 디버그 모드 치트를 설정한다.
## [KR] [method call_deferred]로 호출되어 노드 트리가 안정된 후 실행된다.
## [EN] Applies the equipment list and sets debug mode cheats after a frame delay.
## [EN] Called via [method call_deferred] to execute after the node tree is stable.
func delay_update_equip():
	apply_upgrade(inven_manager.equipment.equipment_list)
	print("dev_mod = "+str(Constants.PLAYER_DEBUG_MOD))
	set_cheat(Constants.PLAYER_DEBUG_MOD)

# [KR] 플레이어를 설정하는 함수
# [EN] Function to set the player
## [KR] 외부에서 [Player] 인스턴스를 주입할 때 사용한다.
## [EN] Used to inject a [Player] instance from outside.
func set_player(player_instance: Player):
	player = player_instance

# [KR] 업그레이드 적용 함수
# [EN] Upgrade application function
## [KR] [param equipment_list]의 장비를 순회하며 업그레이드를 적용한다.
## [KR] 먼저 [method init_player_stat]으로 기본 스탯을 초기화한 뒤,
## [KR] [AbilityGet]은 [member abilities]에 위임하고 나머지는 ID별로 분기 처리한다.
## [EN] Iterates through equipment in [param equipment_list] and applies upgrades.
## [EN] First initializes base stats with [method init_player_stat],
## [EN] then delegates [AbilityGet] to [member abilities] and branches the rest by ID.
func apply_upgrade(equipment_list: Array[AbilityUpgrade]):
	init_player_stat()
	
	# [KR] ability_get의 경우 abilities에서 처리함
	# [EN] For ability_get, handled by abilities
	handle_ability_get(equipment_list)
	
	# [KR] abilityUpgrade의 경우 이 노드에서 바로 처리
	# [EN] For abilityUpgrade, handled directly in this node
	for _item in equipment_list:
		var __item = _item as AbilityUpgrade
		if __item is AbilityGet:
			pass
		elif __item.id == SPEED_UP_ID:
			handle_speed_up()
		elif __item.id == DETECT_AREA_UP_ID:
			handle_detect_area_up()
		elif __item.id == COLLECT_AREA_UP_ID:
			handle_collect_area_up()
		elif __item.id == AREA_CHARGE_TIME_UP:
			handle_area_charge_time_up()
		elif _item.id == LIFE_UP:
			player.global_game_manager.set_life_up_item_equip()

	#var update_player_data = player.global_game_manager.player_data.current_info
	#update_player_data["max_speed"] = player.velocity_component.max_speed
	#update_player_data["base_life"] = player.global_game_manager.life_base
	#update_player_data["charge_time"] = player.charge_time
	#var collision_shape = player.find_area.get_node("CollisionShape2D").shape
	#update_player_data["find_area"] = collision_shape.size
	#var collect_collision_shape = player.item_collect_area.get_node("CollisionShape2D").shape
	#update_player_data["find_area"] = collect_collision_shape.size


# [KR] 액티브 아이템 처리
# [EN] Active item handling
## [KR] [AbilityGet] 타입 장비를 [member abilities]에 전달하여 액티브 어빌리티를 갱신한다.
## [EN] Passes [AbilityGet] type equipment to [member abilities] to update active abilities.
func handle_ability_get(equipment_list: Array[AbilityUpgrade]):
	abilities.update_equip(equipment_list)

# [KR] 속도 업그레이드 처리
# [EN] Speed upgrade handling
## [KR] 이동 속도를 기본 속도의 150%로 설정한다.
## [EN] Sets movement speed to 150% of the base speed.
func handle_speed_up():
	var level := get_tree().get_first_node_in_group("current_level") as Level
	if level and level.disable_speed_upgrade:
		return
	player.velocity_component.max_speed = player.base_speed + (player.base_speed * 0.5)
	print("Speed increased: " + str(player.velocity_component.max_speed))

# [KR] 탐지 영역 업그레이드 처리
# [EN] Detection area upgrade handling
## [KR] 탐지 영역을 기본 크기의 3배로 확대한다.
## [EN] Expands the detection area to 3 times the base size.
func handle_detect_area_up():
	player.find_area.set_detect_size(PlayerData.PLAYER_START_AREA_SIZE * 3)
	print("Detection area increased: " + str(PlayerData.PLAYER_START_AREA_SIZE * 3))

# [KR] 아이템 수집 영역 업그레이드
# [EN] Item collection area upgrade
## [KR] 수집 영역을 가로 3배, 세로 1배로 확대한다.
## [EN] Expands the collection area to 3x width and 1x height.
func handle_collect_area_up():
	player.item_collect_area.set_collect_area(PlayerData.PLAYER_START_COLLECT_SIZE * Vector2 (3.0, 1.0))
	print("Collection area increased: " + str(PlayerData.PLAYER_START_COLLECT_SIZE * Vector2 (3.0, 1.0)))

## [KR] 탐지 충전 시간을 기본값의 50%로 감소시킨다.
## [EN] Reduces the detection charge time to 50% of the base value.
func handle_area_charge_time_up():
	player.charge_time = player.charge_base_time - (player.charge_base_time * 0.5)
	print("Detection time decreased: " + str(player.charge_time))

## [KR] 모든 플레이어 스탯을 [PlayerData]에 정의된 초기값으로 되돌린다.
## [KR] [method apply_upgrade] 시작 시 호출되어 중복 적용을 방지한다.
## [EN] Resets all player stats to the initial values defined in [PlayerData].
## [EN] Called at the start of [method apply_upgrade] to prevent duplicate application.
func init_player_stat():
	player.global_game_manager.life_base = PlayerData.PLAYER_START_LIFE
	player.global_game_manager.set_base_life()
	player.velocity_component.max_speed = PlayerData.PLAYER_START_SPEED
	player.find_area.set_detect_size(PlayerData.PLAYER_START_AREA_SIZE)
	player.item_collect_area.set_collect_area(PlayerData.PLAYER_START_COLLECT_SIZE)
	player.charge_time = PlayerData.PLAYER_START_CHARGE_TIME

## [KR] 개발자 모드 치트를 적용하거나 해제한다.
## [KR] [param state]가 [code]true[/code]이면 이동 속도 2배, 충전 시간 90% 감소를 적용한다.
## [EN] Applies or disables developer mode cheats.
## [EN] If [param state] is [code]true[/code], applies 2x movement speed and 90% charge time reduction.
func set_cheat(state: bool):
	if state:
		#push_warning("dev_mod: 이속, 감지속도 업")
		player.velocity_component.max_speed = player.base_speed * 2
		player.charge_time = player.charge_base_time - (player.charge_base_time * 0.9)
	else:
		pass
