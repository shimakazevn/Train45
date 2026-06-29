## 바닥 시각 이펙트(사정 연출 등)를 생성하는 매니저.
## [signal GameEvents.shot_semen] 시그널을 수신하여 NPC 위치 주변에
## 랜덤 개수의 이펙트 인스턴스를 열차 노드에 배치한다.
extends Node

## 현재 레벨 정보를 조회하기 위한 [FloorManager] 참조
@export var floor_manager: FloorManager
## 바닥 이펙트로 인스턴스화할 [PackedScene] 템플릿
@export var effect_semen: PackedScene

func _ready() -> void:
	GameEvents.shot_semen.connect(_shot_semens)


## [param npc_position] 주변에 1~3개의 이펙트를 랜덤 위치에 생성한다.
## [method is_use_semen]으로 해당 NPC/이벤트에 이펙트 적용 여부를 먼저 확인한다.
func _shot_semens(npc_position: Vector2, npc_type: int, event_num: int):
	if not is_use_semen(npc_type, event_num): #사정하지 않는 씬의 경우 실행하지 않음
		return
	
	for i in randi() % 3 +1:
		var current_level: Level = floor_manager.current_level
		var train = current_level.get_tree().get_first_node_in_group("Train")
		var rand_pos: Vector2 
		rand_pos.x = randi_range(int(npc_position.x) - 100, int(npc_position.x) + 100)
		rand_pos.y = randi_range(300, 347)
		
		var semen_instance = effect_semen.instantiate()
		semen_instance.position = rand_pos
		if train:
			train.add_child(semen_instance)
		else:
			push_error("train 그룹이 없습니다." + str(current_level.name))

## [param npc_type]과 [param event_num] 조합에서 이펙트를 사용할지 여부를 반환한다.
## 특정 이벤트(예: 가슴 만지기, 촉수 외부 씬)에서는 이펙트를 생략한다.
func is_use_semen(npc_type: int, event_num: int)-> bool:
	match npc_type:
		Constants.NPC_OL:
			match event_num:
				7: #가슴 만지기
					return false
		Constants.NPC_PAZUZU:
			match event_num:
				1: #촉수에게 전차 밖에서
					return false
	return true
