## [KR] 스테이지 간 텔레포트(문/포탈)를 처리하는 컴포넌트.
## [KR] [SceneManager]를 통해 씬 전환 애니메이션을 실행하며,
## [KR] 탐지 실패·게임 완료·외부 스테이지 변경 시그널에 반응하여 이동한다.
## [KR] [b]참고:[/b] [member transition_type]은 여기서 정의되어 [SceneManager]에 전달된다.
## [EN] Component that handles teleportation (doors/portals) between stages.
## [EN] Executes scene transition animations through [SceneManager],
## [EN] and reacts to detection failure, game complete, and external stage change signals.
## [EN] [b]Note:[/b] [member transition_type] is defined here and passed to [SceneManager].
class_name Teleport extends Node

## [KR] 플레이어가 텔레포트에 진입했을 때 발신되는 시그널
## [EN] Signal emitted when the player enters a teleport
signal player_entered_teleport(teleport:Teleport,transition_type:String)

## [KR] 문에 진입할 때의 이동 방향. 젤다식 전환 방향과 플레이어 밀어넣기 방향을 결정한다.
## [EN] Movement direction when entering a door. Determines Zelda-style transition direction and player push direction.
@export_enum("north","east","south","west") var entry_direction
## [KR] 문을 통과할 때 사용할 전환 애니메이션 종류
## [EN] Type of transition animation to use when passing through a door
@export_enum("fade_to_black","fade_to_white","wipe_to_right","zelda","no_transition") var transition_type:String
## [KR] 진입 시 방 안으로 플레이어를 밀어넣는 거리(픽셀)
## [EN] Distance (in pixels) to push the player into the room upon entry
@export var push_distance:int = 16
## [KR] 이 문을 통해 로드할 새 씬의 경로
## [EN] Path to the new scene to load through this door
@export var path_to_new_scene:String
## [KR] 실제로 이동할 스테이지 경로 (런타임에 결정)
## [EN] Actual stage path to move to (determined at runtime)
var path_to_stage:String
## [KR] 다음 방에서 진입하는 문의 이름
## [EN] Name of the entry door in the next room
@export var entry_door_name:String

## [KR] 현재 스테이지 [Level] 참조
## [EN] Current stage [Level] reference
var stage : Level
## [KR] 플레이어 [Player] 참조
## [EN] Player [Player] reference
var player : Player
## [KR] 층 관리자 [FloorManager] 참조
## [EN] Floor manager [FloorManager] reference
var floor_manager : FloorManager

## [KR] 다음 텔레포트 시 변경할 챕터 번호 ([code]-1[/code]이면 변경 없음)
## [EN] Chapter number to change on next teleport ([code]-1[/code] means no change)
var next_chapter_change : int = -1

## [KR] 플레이어가 문 근처에 있는지 여부
## [EN] Whether the player is near a door
var player_nearby:bool = false

## [KR] 초기화 시 부모 [Level]에서 [Player]를 참조하고 관련 시그널을 연결한다.
## [EN] On initialization, references [Player] from the parent [Level] and connects related signals.
func _ready():
	stage = get_parent() as Level
	player = stage.player as Player
	player.find_faild.connect(_on_find_faild_teleport)
	GameEvents.game_complete.connect(_on_game_complete_teleport)
	GameEvents.set_change_stage.connect(_on_set_change_stage)
	GameEvents.set_chapter.connect(_on_teleport_ep_change)

## [KR] 챕터 변경 시그널 수신 시 다음 텔레포트에서 적용할 [param chapter]를 저장한다.
## [EN] Stores the [param chapter] to apply on the next teleport when receiving the chapter change signal.
func _on_teleport_ep_change(chapter : int) -> void:
	next_chapter_change = chapter

## [KR] [signal Player.find_faild]에 의한 시작 지점 복귀 처리.
## [KR] 복귀 연출(지지직) 효과음을 재생한 뒤 베이스로 텔레포트한다.
## [KR] Why: 효과음을 라이프 차감(set_life)이 아니라 '복귀' 동작에 묶어, 탐지 실패뿐 아니라
## [KR] 귀환 버튼·H신 종료 등 모든 find_faild 복귀에서 동일하게 들리도록 한다.
## [KR] (오토로드 SoundManager로 재생해 씬 전환에도 끊기지 않으며, 락으로 복귀당 1회만 재생)
## [EN] Handles return to the start point triggered by [signal Player.find_faild].
## [EN] Plays the return (static) SFX, then teleports to base.
## [EN] Why: ties the SFX to the return action (not life deduction) so it sounds consistently
## [EN] across all find_faild returns (return button, H-scene end, etc.), not just detection failure.
func _on_find_faild_teleport() -> void:
	# [KR] 회상방은 단일 방이라 시작 지점 복귀(=base 씬 전환)를 하면 안 된다.
	#      귀신 도감의 rape 재생 종료(find_faild)는 갤러리 창이 받아 처리한다.
	if GameEvents.is_recollection_room:
		return
	# [KR] 이미 전환 중이면(다른 텔레포트가 먼저 처리) SE 중복 재생을 막는다.
	if SceneManager._loading_in_progress:
		return
	SoundManager.play_sfx(UiSoundStreamPlayer.RETURN_TO_START_POINT)
	_on_base_teleport()

## [KR] [signal GameEvents.game_complete](파주주/코니알의 최초 차량 복귀 등)에 의한 베이스 복귀 처리.
## [KR] 복귀 연출(지지직) 효과음을 재생한 뒤 베이스로 텔레포트한다.
## [KR] Why: game_complete는 find_faild funnel을 안 타서, 직접 _on_base_teleport에 연결하면
## [KR] 복귀 SE가 빠진다. find_faild 복귀와 동일하게 들리도록 래퍼에서 SE를 재생한다.
## [EN] Handles return to base triggered by [signal GameEvents.game_complete] (e.g. Pazuzu/Konial sending the player back to the first car).
## [EN] Plays the return (static) SFX, then teleports to base — mirrors [method _on_find_faild_teleport].
func _on_game_complete_teleport() -> void:
	if SceneManager._loading_in_progress:
		return
	SoundManager.play_sfx(UiSoundStreamPlayer.RETURN_TO_START_POINT)
	_on_base_teleport()

## [KR] 탐지 실패 또는 게임 완료 시 베이스 스테이지로 텔레포트한다.
## [KR] [method random_stage]로 경로를 결정한 뒤, [member transition_type]에 따라
## [KR] [SceneManager]의 전환 메서드를 호출하고 자신을 삭제한다.
## [EN] Teleports to the base stage on detection failure or game completion.
## [EN] Determines the path via [method random_stage], then calls
## [EN] [SceneManager]'s transition method based on [member transition_type] and frees itself.
func _on_base_teleport() -> void:
	# [KR] 이 함수는 find_faild·game_complete 두 복귀 래퍼가 모두 호출하므로 둘 다 발신되면 이중 호출된다.
	# [KR] 전환이 진행 중이면 부수효과(on_find_faild·random_stage)가 두 번 실행되지 않도록 막는다.
	if SceneManager._loading_in_progress:
		return
	player.on_find_faild()
	emit_signal("player_entered_teleport", self)
	
	# [KR] 무조건 베이스로 돌아간다
	# [EN] Always return to base
	path_to_stage = random_stage()
	
	var gameplay_node:Gameplay = get_tree().get_nodes_in_group("gameplay")[0] as Gameplay
	var unload:Node = stage

	if transition_type == "zelda":
		SceneManager.swap_scenes_zelda(path_to_stage, gameplay_node.level_holder, unload, get_move_dir())
	else:
		SceneManager.swap_scenes(path_to_stage, gameplay_node.level_holder, unload, transition_type, next_chapter_change)

	queue_free()


## [KR] [FloorManager]에서 베이스 스테이지 경로를 가져온다.
## [EN] Retrieves the base stage path from [FloorManager].
func random_stage() -> String:
	floor_manager = get_tree().get_first_node_in_group("floormanager")
	return floor_manager.stage_path_return_base(get_parent())

## [KR] 외부에서 [signal GameEvents.set_change_stage]로 지정한 [param stage_path]로 텔레포트한다.
## [KR] [method _on_base_teleport]와 동일한 전환 로직을 사용하되, 경로를 직접 지정받는다.
## [EN] Teleports to the [param stage_path] specified externally via [signal GameEvents.set_change_stage].
## [EN] Uses the same transition logic as [method _on_base_teleport], but receives the path directly.
func _on_set_change_stage(stage_path: String):
	# [KR] 전환 진행 중 중복 진입 차단 (락이 없으면 로더 상태가 덮어써져 멈춤/튕김으로 이어진다).
	if SceneManager._loading_in_progress:
		return
	emit_signal("player_entered_teleport", self)
	
	var gameplay_node:Gameplay = get_tree().get_nodes_in_group("gameplay")[0] as Gameplay
	var unload:Node = stage

	if transition_type == "zelda":
		SceneManager.swap_scenes_zelda(stage_path, gameplay_node.level_holder, unload, get_move_dir())
	else:
		SceneManager.swap_scenes(stage_path, gameplay_node.level_holder, unload, transition_type, next_chapter_change)

	queue_free()

# // UTILITY FUNCTIONS //
## [KR] [member entry_direction]과 [member push_distance]를 기반으로
## [KR] 플레이어가 방에 진입할 때의 시작 위치를 계산하여 반환한다.
## [EN] Calculates and returns the player's starting position when entering a room,
## [EN] based on [member entry_direction] and [member push_distance].
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

## [KR] [member entry_direction]을 반전시켜 플레이어가 방에 들어올 때의 이동 방향을 반환한다.
## [KR] 젤다식 전환 애니메이션에서 슬라이드 방향을 결정하는 데 사용된다.
## [EN] Inverts [member entry_direction] to return the player's movement direction when entering a room.
## [EN] Used to determine the slide direction in Zelda-style transition animations.
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
