## [KR] NPC의 이벤트별 위치 정보를 관리하는 컴포넌트.
## [br]H씬 진행 시 NPC를 씬 번호에 맞는 좌표로 배치하며,
## 탐색 위치(전방/중앙/후방) 및 기본 위치 저장·복원 기능을 제공한다.
## [EN] Component managing NPC position info per event.
## [br]Places NPC at coordinates matching the scene number during H-scenes,
## and provides search positions (front/mid/back) and base position save/restore.
extends Node2D
class_name EventPositionComponent

## [KR] 이 컴포넌트가 속한 [Npc] 참조. [method _ready]에서 부모로부터 할당된다.
## [EN] Reference to the [Npc] this component belongs to. Assigned from parent in [method _ready].
var npc : Npc

## [KR] 기본 위치가 저장되었는지 여부.
## [EN] Whether the base position has been saved.
var base_position_enable: bool = false
## [KR] 이벤트 시작 전 NPC의 원래 위치. [method get_base_position] 호출 시 반환 후 초기화된다.
## [EN] NPC's original position before event start. Returned and reset when [method get_base_position] is called.
var base_position: Vector2 = Vector2.ZERO

## [KR] 전방 탐색 위치 인덱스.
## [EN] Front search position index.
const FIND_FRONT := 0
## [KR] 중앙 탐색 위치 인덱스.
## [EN] Mid search position index.
const FIND_MID := 1
## [KR] 후방 탐색 위치 인덱스.
## [EN] Back search position index.
const FIND_BACK := 2

## [KR] NPC 탐색 시 사용하는 위치 사전 (전방/중앙/후방).
## [EN] Position dictionary used for NPC search (front/mid/back).
var npc_find_position : Dictionary = {
	FIND_FRONT : Vector2(1600,317),
	FIND_MID : Vector2(960,317),
	FIND_BACK : Vector2(320,317)
}

## [KR] OL 히로인의 H씬별 위치 데이터. 키는 씬 번호.
## [EN] OL heroine's position data per H-scene. Key is scene number.
var ol_position : Dictionary = {
	1 : Vector2(890, 384),
	2 : Vector2(834, 340),
	3 : Vector2(1357, 345),
	4 : Vector2(1542, 375),
	7 : Vector2(1391, 331)
}
## [KR] 갸루 히로인의 H씬별 위치 데이터. 키는 씬 번호.
## [EN] Gyaru heroine's position data per H-scene. Key is scene number.
var gyaru_position : Dictionary = {
	3 : Vector2(523, 336),
	4 : Vector2(810, 337)
}
## [KR] 코니알 히로인의 H씬별 위치 데이터. 키는 씬 번호.
## [EN] Konial heroine's position data per H-scene. Key is scene number.
var konial_position : Dictionary = {
	1 : Vector2(717, 324)
}
## [KR] 파주주 히로인의 H씬별 위치 데이터. 키는 씬 번호.
## [EN] Pazuzu heroine's position data per H-scene. Key is scene number.
var pazuzu_position : Dictionary = {
	1 : Vector2(1311, 254)
}
## [KR] 집사 캐릭터의 H씬별 위치 데이터. 키는 씬 번호.
## [EN] Butler character's position data per H-scene. Key is scene number.
var butler_position : Dictionary = {
}

## [KR] 부모 노드에서 [Npc] 참조를 획득한다.
## [EN] Acquires [Npc] reference from the parent node.
func _ready():
	npc = get_parent() as Npc

## [KR] [param pos] 인덱스에 해당하는 NPC 탐색 위치를 반환한다.
## [br]유효하지 않은 인덱스이면 [code]Vector2.ZERO[/code]를 반환한다.
## [EN] Returns the NPC search position for the given [param pos] index.
## [br]Returns [code]Vector2.ZERO[/code] if the index is invalid.
func set_find_position(pos : int = FIND_MID) -> Vector2:
	if npc_find_position.has(pos):
		return npc_find_position[pos]
	
	return Vector2.ZERO

## [KR] [param scene_num]에 해당하는 NPC별 H씬 애니메이션 위치를 반환한다.
## [br][member npc]의 타입에 따라 각 히로인의 위치 사전을 조회하며,
## 해당 키가 없으면 경고 후 [code]Vector2.ZERO[/code]를 반환한다.
## [EN] Returns the NPC-specific H-scene animation position for [param scene_num].
## [br]Queries each heroine's position dictionary based on [member npc] type.
## Returns [code]Vector2.ZERO[/code] with a warning if the key is not found.
func set_anim_position(scene_num: int) -> Vector2:
	match npc.npc_name:
		Constants.NPC_OL:
			if ol_position.has(scene_num):
				return ol_position[scene_num]
		Constants.NPC_GYARU:
			if gyaru_position.has(scene_num):
				return gyaru_position[scene_num]
		Constants.NPC_KONIAL:
			if konial_position.has(scene_num):
				return konial_position[scene_num]
		Constants.NPC_PAZUZU:
			if pazuzu_position.has(scene_num):
				return pazuzu_position[scene_num]
		Constants.NPC_BUTLER:
			if butler_position.has(scene_num):
				return butler_position[scene_num]

	# [KR] 해당하는 키가 없거나 다른 NPC일 경우 기본 위치 반환
	# [EN] Return default position if key not found or different NPC
	push_warning("scene%d의 좌표 정보가 없습니다."%scene_num)
	return Vector2.ZERO

## [KR] NPC의 기본 위치를 저장한다. 이미 저장된 상태이면 무시한다.
## [br]H 이벤트 시작 전에 호출하여 이벤트 종료 후 원래 위치로 복귀할 수 있게 한다.
## [EN] Saves the NPC's base position. Ignored if already saved.
## [br]Called before H event start to allow restoring original position after event ends.
func set_base_position(npc_pos: Vector2):
	if not base_position_enable:
		base_position = npc_pos
		base_position_enable = true

## [KR] 저장된 기본 위치를 반환하고 저장 상태를 초기화한다.
## [br]1회 조회 후 [member base_position]은 [code]Vector2.ZERO[/code]로 리셋된다.
## [EN] Returns the saved base position and resets the save state.
## [br]After one retrieval, [member base_position] is reset to [code]Vector2.ZERO[/code].
func get_base_position()-> Vector2:
	var base_pos = base_position
	base_position = Vector2.ZERO
	base_position_enable = false
	return base_pos
