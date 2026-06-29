class_name Gameplay extends Node2D

## [KR] 메인 게임플레이 매니저 씬.
## [EN] Main gameplay manager scene.
##
## [KR] [SceneManager]를 통해 레벨 로딩과 전환을 관리한다.
## [EN] Manages level loading and transitions via [SceneManager].
## [KR] [member current_level]로 현재 활성화된 레벨을 추적하며,
## [EN] Tracks the currently active level with [member current_level],
## [KR] [method _on_level_loaded], [method _on_level_added], [method _on_load_start] 콜백을 통해
## [EN] and through [method _on_level_loaded], [method _on_level_added], [method _on_load_start] callbacks,
## [KR] SceneTree 노드 순서를 직접 제어한다.
## [EN] directly controls SceneTree node order.

## [KR] 레벨이 배치되는 컨테이너 노드
## [EN] Container node where levels are placed
@onready var level_holder: Node2D = $LevelHolder
## [KR] HUD 캔버스 레이어
## [EN] HUD canvas layer
@onready var hud: CanvasLayer = $HUD
## [KR] 층(스테이지) 진행 관리자
## [EN] Floor (stage) progression manager
@onready var floor_manager = $FloorManager

## [KR] 프롤로그 스테이지 씬
## [EN] Prologue stage scene
@export var prologue_stage: PackedScene
## [KR] 회상의 방 씬
## [EN] Recollection room scene
@export var recollection_room: PackedScene
@export_category("Debug")

## [KR] 디버그용 NPC 타입
## [EN] NPC type for debugging
@export var debug_npc: Constants.NpcTypes
## [KR] 디버그용 NPC 호감도
## [EN] NPC affection level for debugging
@export var debug_npc_love_level: int
## [KR] 디버그용 챕터 번호
## [EN] Chapter number for debugging
@export var debug_chapter := 0
## [KR] 디버그용 목표 달성 횟수 ([code]-1[/code]이면 무시)
## [EN] Goal completion count for debugging (ignored if [code]-1[/code])
@export var debug_goal_count := -1
## [KR] 디버그 모드에서 로드할 씬
## [EN] Scene to load in debug mode
@export var debug_mode_scene : PackedScene

## [KR] 현재 회상의 방인지 여부
## [EN] Whether currently in the recollection room
var is_recollection_room:= false
## [KR] 현재 활성화된 레벨 인스턴스
## [EN] Currently active level instance
var current_level:Level

## 고아 노드 모니터링 변수
var _orphan_count_prev: int = -1
var _orphan_pending_check: int = -1  # 0.3초 뒤 상세 출력 대기 중인 고아 수 (-1이면 대기 없음)
var _orphan_pending_timer: float = 0.0
#var _object_count_prev: int = -1  # 전체 오브젝트 수 추적 (비활성)

## [KR] 고아 노드 모니터링 디버그 출력 스위치. 누수 추적 시에만 에디터에서 켠다.
## print_orphan_nodes() 폭주가 프레임 멈칫·로그/영상 오염을 유발하므로 평소·릴리스·무인 QA에선 꺼 둔다.
## OS.is_debug_build() 이중 가드로, 실수로 true로 남겨도 릴리스(export) 빌드에는 들어가지 않는다.
const DEBUG_ORPHAN_MONITOR := false

func _process(_delta: float) -> void:
	# 디버그 스위치가 꺼져 있거나 릴리스 빌드면 모니터링 비활성(스파이크 시 print_orphan_nodes 폭주 방지)
	if not (DEBUG_ORPHAN_MONITOR and OS.is_debug_build()):
		return
	# 현재 고아 노드 수 샘플링
	var orphan := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) as int
	#var objects := Performance.get_monitor(Performance.OBJECT_COUNT) as int  # 전체 오브젝트 수 (비활성)

	# 0.3초 대기 후 아직도 증가 상태면 상세 출력
	if _orphan_pending_check != -1:
		_orphan_pending_timer -= _delta
		if _orphan_pending_timer <= 0.0:
			if orphan >= _orphan_pending_check:
				Node.print_orphan_nodes()
				print("─────────────────────────────────")
			_orphan_pending_check = -1

	# 고아 노드 수 변경 감지
	if orphan != _orphan_count_prev:
		var diff := orphan - _orphan_count_prev
		var prefix := "+" if diff > 0 else ""
		print("─── [Orphan] %d → %d  (%s%d) ───" % [_orphan_count_prev, orphan, prefix, diff])
		# 증가 시 0.3초 뒤 상세 출력 예약
		if orphan > _orphan_count_prev and _orphan_count_prev != -1:
			_orphan_pending_check = orphan
			_orphan_pending_timer = 0.3
		_orphan_count_prev = orphan
		#_object_count_prev = objects  # 전체 오브젝트 수 갱신 (비활성)

## [KR] [SceneManager] 시그널을 연결하고 초기 레벨을 설정한다.
## [EN] Connects [SceneManager] signals and sets up the initial level.
func _ready() -> void:
	DropItem.exiting_to_menu = false # 재진입 시 정적 플래그 초기화 (이전 세션 종료 값 잔존 방지)

	SceneManager.load_complete.connect(_on_level_loaded)
	SceneManager.load_start.connect(_on_load_start)
	SceneManager.scene_added.connect(_on_level_added)

	_init_level()
	floor_manager.floor_change(current_level)

## [KR] 게임 상태에 따라 적절한 초기 레벨을 결정한다.
## [EN] Determines the appropriate initial level based on game state.
## [KR] 디버그 모드, 신규 게임, 회상의 방, 저장된 게임 순으로 분기한다.
## [EN] Branches in order: debug mode, new game, recollection room, saved game.
func _init_level() -> void:
	if Constants.SCENE_DEBUG:
		_init_debug_mode()
	elif MetaProgression.is_new_game() and not GameEvents.is_recollection_room:
		_init_prologue()
	elif GameEvents.is_recollection_room:
		_init_recollection_room()
	else:
		_load_saved_game()

## [KR] 디버그 모드 활성화 시 에디터에서 설정한 값으로 게임을 시작한다.
## [EN] When debug mode is active, starts the game with values configured in the editor.
## [KR] [member debug_chapter], [member debug_goal_count], [member debug_mode_scene] 값을 사용한다.
## [EN] Uses [member debug_chapter], [member debug_goal_count], [member debug_mode_scene] values.
func _init_debug_mode() -> void:
	MetaProgression.set_current_chapter(debug_chapter)
	if debug_goal_count != -1:
		MetaProgression.set_game_complete_count(debug_goal_count)
	_set_instance_level(debug_mode_scene)
	push_error("현재 디버그 모드입니다")

## [KR] 신규 게임 시 [member prologue_stage] 씬을 로드하여 프롤로그를 시작한다.
## [EN] Loads the [member prologue_stage] scene to start the prologue on a new game.
func _init_prologue() -> void:
	print("This is a new game")
	_set_instance_level(prologue_stage)

## [KR] [member recollection_room] 씬을 로드하여 회상의 방을 시작한다.
## [EN] Loads the [member recollection_room] scene to enter the recollection room.
func _init_recollection_room() -> void:
	_set_instance_level(recollection_room)

## [KR] 기존 저장 데이터로부터 게임을 이어서 로드한다.
## [EN] Continues loading the game from existing save data.
func _load_saved_game() -> void:
	print("Loading saved game")
	current_level = level_holder.get_child(0) as Level   

## [KR] [param packed] 씬을 인스턴스화하여 [member level_holder]에 배치하고 [member current_level]을 갱신한다.
## [EN] Instantiates the [param packed] scene, places it in [member level_holder], and updates [member current_level].
func _set_instance_level(packed: PackedScene):
	_clear_holder()
	var instance = packed.instantiate() as Level
	level_holder.add_child(instance)
	current_level = instance

## [KR] [member level_holder]의 기존 자식 노드를 제거하여 새 레벨 배치를 준비한다.
## [EN] Removes existing child nodes from [member level_holder] to prepare for new level placement.
func _clear_holder() -> void:
	# [KR] level_holder 에 기본으로 있던 노드를 제거
	# [EN] Remove the default node from level_holder
	if level_holder.get_child_count() > 0:
		level_holder.get_child(0).queue_free()


## [KR] 레벨 로딩 완료 시 호출되어 [member current_level]을 갱신한다.
## [EN] Called when level loading is complete to update [member current_level].
func _on_level_loaded(level) -> void:
	if level is Level:
		current_level = level
		

## [KR] 레벨이 씬 트리에 추가된 후 호출된다.
## [EN] Called after a level is added to the scene tree.
## [KR] [FloorManager]에 층 변경을 알리고, 로딩 스크린과 HUD의 Z순서를 조정한다.
## [EN] Notifies [FloorManager] of the floor change and adjusts Z-order of the loading screen and HUD.
func _on_level_added(_level,_loading_screen) -> void:
	floor_manager.floor_change(_level)	
	pass
	# keep loading screen on top
	if _loading_screen != null:
		var loading_parent: Node = _loading_screen.get_parent() as Node
		loading_parent.move_child(_loading_screen, loading_parent.get_child_count()-1)
	# HUD example
	move_child(hud, get_child_count()-1) # uncomment to keep the HUD above the loading screen (like how it stays put in OG Zelda dungeons)

## [KR] 로딩 시작 시 호출된다. HUD 순서 커스터마이징에 활용할 수 있다.
## [EN] Called when loading starts. Can be used for HUD order customization.
func _on_load_start(_loading_screen):
	pass
	# keep HUD on top of loading screen - uncomment below to keep HUD up top (see above)
#	_loading_screen.reparent(self)
#	move_child(_loading_screen,hud.get_index())
