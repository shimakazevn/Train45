## 티켓 보너스 인스턴스를 스테이지/세이프 스테이지에 배치하는 컨트롤러.
## [AbilityController]를 상속하며, 현재 스테이지 타입에 따라 보너스를 생성한다.
extends AbilityController

## 티켓 보너스 오브젝트 [PackedScene].
@export var ticket_bonus: PackedScene
## 현재 [FloorManager] 참조.
var floor_manager : FloorManager

## 초기화 — 스테이지 타입이 [code]TYPE_STAGE[/code] 또는 [code]TYPE_SAFE[/code]이면 보너스를 배치한다.
func _ready():
	floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
	if floor_manager.current_stage_type == Constants.TYPE_STAGE:
		ticket_bonus_set()
	elif floor_manager.current_stage_type == Constants.TYPE_SAFE:
		ticket_bonus_set()


## [member ticket_bonus]를 인스턴스화하여 현재 레벨에 자식으로 추가한다.
func ticket_bonus_set():
	var ticket_bonus_instance = ticket_bonus.instantiate()
	floor_manager.current_level.add_child(ticket_bonus_instance)
