## [KR] 플레이어 주변의 NPC·이벤트·유령 등 상호작용 대상을 감지하는 영역.
## [KR] 플레이어 이동 방향에 따라 좌/우 충돌 셰이프를 전환하여
## [KR] 바라보는 방향의 대상만 감지한다.
## [EN] Area that detects interaction targets such as NPCs, events, and ghosts near the player.
## [EN] Switches left/right collision shapes based on the player's movement direction
## [EN] to only detect targets in the facing direction.
extends Area2D
class_name TalkArea

## [KR] 부모 [Player] 노드 참조
## [EN] Parent [Player] node reference
@onready var player
## [KR] 현재 플레이어가 바라보는 방향 ([code]1[/code] = 오른쪽, [code]-1[/code] = 왼쪽)
## [EN] Current direction the player is facing ([code]1[/code] = right, [code]-1[/code] = left)
var current_sign = 1

## [KR] 오른쪽 방향 감지용 충돌 셰이프
## [EN] Collision shape for right-direction detection
@onready var collision_right: CollisionShape2D = $CollisionRight
## [KR] 왼쪽 방향 감지용 충돌 셰이프
## [EN] Collision shape for left-direction detection
@onready var collision_left: CollisionShape2D = $CollisionLeft

## [KR] 초기화 시 Dialogic 대화 종료 시그널과 스테이지 클리어 시그널을 연결한다.
## [EN] On initialization, connects the Dialogic dialogue end signal and stage clear signal.
func _ready():
	Dialogic.timeline_ended.connect(_on_update_near_npc)
	GameEvents.stage_clear.connect(_on_stage_clear)
	player = get_parent()

## [KR] 플레이어 이동 방향이 변경되었을 때 감지 방향을 갱신한다.
## [KR] [param player_sign]이 현재 방향과 다를 때만 [method change_move_sign]을 호출한다.
## [EN] Updates the detection direction when the player's movement direction changes.
## [EN] Only calls [method change_move_sign] when [param player_sign] differs from the current direction.
func update_move_sign(player_sign: int):
	if current_sign != player_sign:
		current_sign = player_sign
		change_move_sign(current_sign)

## [KR] 플레이어 방향 열거형. [code]LEFT = -1[/code], [code]RIGHT = 1[/code]
## [EN] Player direction enum. [code]LEFT = -1[/code], [code]RIGHT = 1[/code]
enum PlayerSign{ LEFT = -1, RIGHT = 1 }

## [KR] [param player_sign]에 따라 좌/우 충돌 셰이프의 활성화를 전환한다.
## [EN] Toggles left/right collision shape activation based on [param player_sign].
func change_move_sign(player_sign: int):
	if player_sign == PlayerSign.LEFT:
		collision_left.disabled = false
		collision_right.disabled = true
	elif player_sign == PlayerSign.RIGHT:
		collision_left.disabled = true
		collision_right.disabled = false

## [KR] [Npc]가 영역에 진입했을 때 가까운 NPC로 등록한다.
## [KR] 기존에 근처에 있던 NPC가 있으면 해제 후 교체한다.
## [EN] Registers an [Npc] as the nearby NPC when it enters the area.
## [EN] If there was an existing nearby NPC, releases it before replacing.
func _on_body_entered(body):
	if not body is Npc:
		return
	if player.near_npc:
		player.near_npc.near_player(false)
	# 마지막 진입 우선: NPC가 나중에 들어왔으니, 먼저 잡혀 있던 이벤트는 해제한다(강조도 끔).
	if player.near_event:
		player.near_event.near_player(false)
		player.near_event = null
		player.is_near_event = false
	body.near_player(true)
	player.near_npc = body
	player.is_near_npc = true


## [KR] [Npc]가 영역에서 벗어났을 때 근처 NPC 참조를 해제한다.
## [EN] Releases the nearby NPC reference when an [Npc] exits the area.
func _on_body_exited(body):
	if not body is Npc:
		return
	body.near_player(false)
	
	if player.near_npc == body:
		player.near_npc = null
		player.is_near_npc = false
		# 잡고 있던 대상이 빠졌으니, 영역에 남아있는 다른 대상(이벤트/다른 NPC)을 다시 잡는다.
		_reacquire_remaining_target()


## [KR] [Area2D]가 영역에 진입했을 때 [EventArea] 또는 [GhostHAnomaly]를 처리한다.
## [EN] Handles [EventArea] or [GhostHAnomaly] when an [Area2D] enters the area.
func _on_area_entered(area):
	if area is EventArea:
		# 마지막 진입 우선: 이벤트가 나중에 들어왔으니, 먼저 잡혀 있던 NPC는 해제한다(강조도 끔).
		# (NPC는 대화 종료 시 _on_update_near_npc가 겹친 NPC를 다시 등록해 복구된다)
		if player.near_npc:
			player.near_npc.near_player(false)
			player.near_npc = null
			player.is_near_npc = false
		area.near_player(true)
		player.near_event = area
		player.is_near_event = true
	if area is Area2D:
		if area.get_parent() is GhostHAnomaly:
			player.near_h_ghost = area.get_parent()


## [KR] [Area2D]가 영역에서 벗어났을 때 이벤트 및 유령 참조를 해제한다.
## [EN] Releases event and ghost references when an [Area2D] exits the area.
func _on_area_exited(area):
	if area is EventArea:
		area.near_player(false)
		player.near_event = null
		player.is_near_event = false
		# 잡고 있던 대상이 빠졌으니, 영역에 남아있는 다른 대상(다른 이벤트/NPC)을 다시 잡는다.
		_reacquire_remaining_target()
	if area is Area2D:
		if area.get_parent() is GhostHAnomaly:
			player.near_h_ghost = null


## [KR] 잡고 있던 대상이 영역을 빠져나가 잡힌 대상이 없어졌을 때,
## [KR] 영역에 아직 남아있는 대상을 다시 잡는다. (NPC↔NPC, 이벤트↔이벤트, 혼합 모두 대응)
## [KR] 진입 우선순위(이벤트 > NPC)와 동일하게 이벤트를 먼저 검사한다.
## [KR] 콜리전 방향 토글 직후 감지가 갱신되도록 physics_frame 1회 대기 후 재스캔한다.
func _reacquire_remaining_target() -> void:
	await get_tree().physics_frame
	# 대기 사이 씬 전환 등으로 트리에서 빠졌거나 모니터링이 꺼진(스테이지 클리어 블링크) 상태면 중단.
	if not is_inside_tree() or not monitoring:
		return
	# 대기 중 다른 대상이 이미 잡혔으면 중복 처리하지 않는다.
	if player.near_event or player.near_npc:
		return
	for a in get_overlapping_areas():
		if a is EventArea:
			_on_area_entered(a)
			return
	for b in get_overlapping_bodies():
		if b is Npc:
			_on_body_entered(b)
			return


## [KR] 대화 종료 후 영역 내 [Npc]를 재검사하여 [member player.near_npc]를 갱신한다.
## [KR] Dialogic 타임라인 종료 시 호출되며, 대화 중 감지가 누락된 NPC를 복구한다.
## [EN] Re-examines [Npc] within the area after dialogue ends to update [member player.near_npc].
## [EN] Called when the Dialogic timeline ends, recovering NPCs missed during dialogue.
func _on_update_near_npc():
	var npcs: Array = self.get_overlapping_bodies()
	for i in npcs:
		if i is Npc:
			_on_body_entered(i)

#func _on_update_near_event():
	#await get_tree().physics_frame # 이벤트의 감지 상황이 변경된 후에 실행
	#var events: Array = self.get_overlapping_areas()
	#for i in events:
		#if i is EventArea:
			#_on_area_entered(i)

## [KR] 스테이지 클리어 시 모니터링을 잠시 비활성화했다가 다시 활성화한다.
## [KR] 겹쳐 있는 오브젝트가 감지되지 않는 현상을 방지하기 위해 깜박임 처리한다.
## [EN] Temporarily disables and re-enables monitoring on stage clear.
## [EN] Blinks monitoring to prevent overlapping objects from not being detected.
func _on_stage_clear():
	monitoring = false
	await get_tree().create_timer(0.1).timeout
	monitoring = true
