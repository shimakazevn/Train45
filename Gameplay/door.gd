class_name Door extends Area2D

## [KR] 문(포탈) 전환 트리거.
## [EN] Door (portal) transition trigger.
##
## [KR] 플레이어가 접촉하면 [SceneManager]를 통해 다음 스테이지로 전환한다.
## [EN] Transitions to the next stage via [SceneManager] when the player makes contact.
## [KR] [member transition_type]으로 전환 애니메이션 종류를, [member entry_direction]으로
## [EN] [member transition_type] specifies the transition animation type, and [member entry_direction]
## [KR] 진입 방향과 젤다식 전환 방향을 지정한다.
## [EN] specifies the entry direction and Zelda-style transition direction.

## [KR] 플레이어가 문에 진입했을 때 발생한다.
## [EN] Emitted when a player enters the door.
signal player_entered_door(door:Door,transition_type:String)
## [KR] 현재 레벨 참조
## [EN] Current level reference
var current_level: Level

## [KR] 문 진입 방향. 젤다식 전환 방향 및 플레이어 푸시 방향을 결정한다.
## [EN] Door entry direction. Determines Zelda-style transition direction and player push direction.
@export_enum("north","east","south","west") var entry_direction
## [KR] 문 통과 시 사용할 전환 애니메이션 종류
## [EN] Transition animation type to use when passing through the door
@export_enum("fade_to_black","fade_to_white","wipe_to_right","zelda","no_transition") var transition_type:String
## [KR] 문 진입 시 플레이어를 방 안쪽으로 밀어넣을 거리(픽셀)
## [EN] Distance (pixels) to push the player inward when entering the door
@export var push_distance:int = 16
## [KR] 이 문이 연결할 씬 경로
## [EN] Scene path this door connects to
@export var path_to_new_scene:String
## [KR] [FloorManager]에서 결정된 실제 스테이지 경로
## [EN] Actual stage path determined by [FloorManager]
var path_to_stage:String
## [KR] 다음 방에서 사용할 문 이름
## [EN] Door name to use in the next room
@export var entry_door_name:String
## [KR] 이벤트 블록 감지 영역
## [EN] Event block detection area
@onready var block_area: Area2D = %BlockArea

## [KR] [FloorManager] 참조
## [EN] [FloorManager] reference
var floor_manager

## [KR] 플레이어가 문 근처에 있는지 여부
## [EN] Whether the player is near the door
var player_nearby:bool = false

## [KR] 스테이지 클리어 시그널을 연결한다.
## [EN] Connects the stage clear signal.
func _ready() -> void:
	GameEvents.stage_clear.connect(_on_stage_clear)

## [KR] 플레이어가 문 영역에 진입하면 [SceneManager]를 통해 다음 스테이지로 전환한다.
## [EN] Transitions to the next stage via [SceneManager] when the player enters the door area.
## [KR] [member transition_type]에 따라 젤다식 또는 일반 전환을 수행한다.
## [EN] Performs Zelda-style or normal transition based on [member transition_type].
func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	# [KR] 이미 전환이 진행 중이면 무시한다. random_stage()가 swap보다 먼저 실행되므로,
	# [KR] 가드가 없으면 빠른 연속 진입·다중 문 접촉 시 FloorManager 진행도만 두 칸 전진해 어긋난다.
	if SceneManager._loading_in_progress:
		return
	player_nearby = true


	emit_signal("player_entered_door", self)
	path_to_stage = random_stage()
	
	var gameplay_node:Gameplay = get_tree().get_nodes_in_group("gameplay")[0] as Gameplay
	var unload:Node = get_parent()

	if transition_type == "zelda":
		SceneManager.swap_scenes_zelda(path_to_stage, gameplay_node.level_holder, unload, get_move_dir())
	else:
		SceneManager.swap_scenes(path_to_stage, gameplay_node.level_holder, unload, transition_type)
	
	queue_free()
	

## [KR] 플레이어가 문 영역에서 벗어나면 근접 플래그를 해제한다.
## [EN] Clears the proximity flag when the player leaves the door area.
func _on_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	player_nearby = false
	

## [KR] [FloorManager]에 현재 스테이지 정보를 전달하고 다음 스테이지 경로를 받아온다.
## [EN] Passes current stage info to [FloorManager] and receives the next stage path.
func random_stage() -> String:
	floor_manager = get_tree().get_first_node_in_group("floormanager")
	return floor_manager.into_next_door(get_parent())


## [KR] 이 문의 위치와 [member entry_direction]을 기반으로 플레이어의 시작 위치를 계산한다.
## [EN] Calculates the player's starting position based on this door's position and [member entry_direction].
## [KR] [member push_distance]만큼 방 안쪽으로 밀어넣은 좌표를 반환한다.
## [EN] Returns coordinates pushed inward by [member push_distance].
func get_player_entry_vector() -> Vector2:
	var vector:Vector2 = Vector2.LEFT
	match entry_direction:
		0:
			vector = Vector2.UP
		1: 
			vector = Vector2.RIGHT
		2:
			vector = Vector2.DOWN
	return (vector * push_distance) + self.position

## [KR] [member entry_direction]을 반전시켜 플레이어의 이동 방향 벡터를 반환한다.
## [EN] Inverts [member entry_direction] to return the player's movement direction vector.
## [KR] 젤다식 전환에서 스크롤 방향을 결정하는 데 사용한다.
## [EN] Used to determine scroll direction in Zelda-style transitions.
func get_move_dir() -> Vector2:
	var dir:Vector2 = Vector2.RIGHT
	match entry_direction:
		0:
			dir = Vector2.DOWN
		1: 
			dir = Vector2.LEFT
		2:
			dir = Vector2.UP	
	return dir

## [KR] 블록 영역에 진입 시 이벤트 컴포넌트의 대화 이벤트를 실행한다.
## [EN] Executes the event component's dialogue event when entering the block area.
## [KR] 스테이지 클리어 후 미처리된 이벤트가 있을 때 문 앞에서 대화를 차단한다.
## [EN] Blocks dialogue at the door when there are unprocessed events after stage clear.
func _on_block_area_body_entered(_body):
	var event_component = get_tree().get_first_node_in_group("eventcomponent")
	var partner_manager = get_tree().get_first_node_in_group("partnermanager")
	if event_component == null:
		return
	if event_component.event_played():
		return
	if event_component.event_enabled and event_component.current_stage_clear and not event_component.played:
		current_level = get_parent() as Level
		if current_level.stage_type == Constants.TYPE_STAGE:
			partner_manager.current_talker = -1
			Dialogic.start("door_block")

## [KR] 스테이지 클리어 시점에 이미 블록 영역 위에 있는 플레이어를 감지하여 이벤트를 발동한다.
## [EN] Detects players already in the block area at stage clear time and triggers the event.
func _on_stage_clear():
	# [KR] 모니터링이 꺼진 영역은 body 조회가 불가하므로(에러 방지) 건너뛴다.
	if not block_area.monitoring:
		return
	var bodies:= block_area.get_overlapping_bodies()
	for i in bodies:
		if i is Player:
			_on_block_area_body_entered(i)
