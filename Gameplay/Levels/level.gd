## 모든 레벨(게임 콘텐츠)의 베이스 클래스.
## [SceneManager]와 직접 연관되지 않으며, 레벨 간 데이터 전달을 위해
## [method get_data]와 [method receive_data]를 구현한다.
class_name Level extends Node2D

## 현재 레벨의 씬 파일 경로. [method _ready]에서 자동 설정된다.
var level_path:String

## 플레이어 노드 참조.
@export var player:Player
## 현재 NPC 관리 노드.
@export var current_npc:CurrentNpc
## 레벨에 배치된 [Door] 배열.
@export var doors:Array[Door]
## 레벨에 배치된 [Teleport] 배열.
@export var teleports:Array[Teleport]
## 열차 표준 배경 노드.
@onready var train_standard = $TrainStandard
## 카메라 줌 제어용 [PhantomCamera2D].
@onready var phantom_camera_2d = $PhantomCamera2D
## H씬(is_ghost_play) 중 카메라 리미트 해제 상태 추적(상태 변할 때만 토글).
var _ghost_limit_off := false
## 리미트 해제 전 원래 limit_target을 저장해 두고 종료 시 복원한다.
var _saved_limit_target: NodePath

## 스테이지 유형 — base, stage, event, safe_stage, complete 중 하나.
@export_enum("base", "stage", "event", "safe_stage", "complete") var stage_type
## [code]true[/code]이면 탐지 없이 달리기 전용 스테이지로 동작한다.
@export var run_stage := false
## 파트너에게 이상현상이 발생하는 스테이지일 경우 할당되는 [NpcAnomaly] 노드.
@export var npc_anomaly : NpcAnomaly = null
## 프롤로그 전용 스테이지 여부.
@export var prologue_stage := false
## true이면 speed_up 아이템이 이동속도에 영향을 주지 않는다.
@export var disable_speed_upgrade := false
## 현재 챕터 번호.
@export var current_chapter := 0
## 대화 시 특수 상황에서 사용할 Dialogic 레이블. 비어있으면 기본 대화를 사용한다.
@export var extra_info:= ""
## 가변 맵 길이 (맵 크기 조절용).
@export var variable_map_length: float
## 종착점(완료 스테이지)의 추가 정보 딕셔너리.
var destination_info: Dictionary
## 현재 스테이지 클리어 여부.
var stage_clear := false
## [FloorManager] 참조.
var floorManager:FloorManager
## [GlobalGameManager] 참조.
var global_game_manager : GlobalGameManager
## 이상현상 발견 여부 플래그.
var stage_find_anomaly := false
## NPC 활성 상태 여부.
var npc_active = true

## 레벨 간 전달되는 핸드오프 데이터.
var data:LevelDataHandoff

## 레벨 초기화가 완료되면 발행된다.
signal stage_ready
## 플레이어 조작이 가능해지면 발행된다.
signal stage_start

func _init() -> void:
	pass

## 레벨 초기화 — 씬 경로 설정, [FloorManager] 탐색, 스테이지 클리어 상태 결정,
## 플레이어 비활성화 후 [method init_scene] → [method start_scene] 호출.
func _ready() -> void:
	level_path = scene_file_path
	add_to_group("current_level")
	floorManager = get_tree().get_first_node_in_group("floormanager")
	if stage_type == Constants.TYPE_COMPLETE:
		destination_info = floorManager.route_data.get_destination_data(self)
	
	if stage_type == null:
		print("stage type null!")
	if current_npc:
		current_npc.get_stage_type(stage_type)
	
	global_game_manager = get_tree().get_first_node_in_group("globalgamemanager") as GlobalGameManager
		
	#스테이지 클리어 상태 설정
	if stage_type == Constants.TYPE_BASE or stage_type == Constants.TYPE_SAFE \
	or stage_type == Constants.TYPE_EVENT or stage_type == Constants.TYPE_COMPLETE:
		if stage_type == Constants.TYPE_BASE:
			floorManager.stage_clear_list_remove()
		elif stage_type == Constants.TYPE_COMPLETE:
			floorManager.stage_clear_list_remove()
		stage_clear = true
	else:
		stage_clear = false
	
	
		
	player.disable()
	player.visible = false
	# This block is here to allow us to test current scene without needing the SceneManager to call these :) 
	if data == null: 
		init_scene()
		start_scene()
	
	stage_ready.emit()
	

## 매 프레임 카메라 줌을 갱신한다. 차징 또는 고스트 플레이 중이면 줌인한다.
func _process(_delta):
	var target_zoom = Vector2(1.0, 1.0)  # 기본 줌 설정
	
	if player.is_charging:
		target_zoom = Vector2(1.2, 1.2)  # 차징 중일 때 목표 줌 설정
		# 현재 줌에서 목표 줌으로 점차적으로 전환
		phantom_camera_2d.zoom = phantom_camera_2d.zoom.lerp(target_zoom, 0.003)
	else:
		phantom_camera_2d.zoom = phantom_camera_2d.zoom.lerp(target_zoom, 0.1)
	
	if player.is_ghost_play:
		target_zoom = Vector2(1.2, 1.2)  # 차징 중일 때 목표 줌 설정
		phantom_camera_2d.zoom = phantom_camera_2d.zoom.lerp(target_zoom, 0.3)

	# 회상방 한정: H씬(is_ghost_play 갤러리 뷰 / STATE_RAPE 강간) 중엔 화면이 카메라 리미트에
	# 잘리지 않도록 해제한다. limit_target을 비우면 reset_limit + update_limit_all_sides가 돌아
	# _limit_sides가 기본값(무제한)이 되고 limit 라인도 화면 밖으로 밀려난다. 종료 시 원래 target 복원.
	var need_limit_off: bool = GameEvents.is_recollection_room \
		and (player.is_ghost_play or GameEvents.game_state == Constants.STATE_RAPE)
	if need_limit_off != _ghost_limit_off:
		_ghost_limit_off = need_limit_off
		if need_limit_off:
			_saved_limit_target = phantom_camera_2d.limit_target
			phantom_camera_2d.limit_target = NodePath("")
		else:
			phantom_camera_2d.limit_target = _saved_limit_target

## 현재 레벨의 핸드오프 데이터를 반환한다.
## [SceneManager]가 씬 전환 시 이 메서드를 호출하여 다음 씬에 데이터를 전달한다.
func get_data():
	return data
	
## 이전 씬에서 전달된 데이터를 수신한다.
## [LevelDataHandoff] 타입만 처리하고, 그 외 데이터는 경고 후 무시한다.
func receive_data(_data):
	# implementing class should do some basic checks to make sure it only acts on data it's prepared to accept
	# if previous scene sends data this scene doesn't need, simple logic as follows ensures no crash occurs
	# act only on the data you want to receive and process :) 
	if _data is LevelDataHandoff:
		data = _data
		# process data here if need be, for this we just need to receive it but only if it's of the correct data type
	else:
		# SceneManager is designed to allow data mismatches like this occur, because you wno't always know
		# which scene precedes or follows another. For example, this sample project passes data between
		# levels but not between a level and the start screen, or vice versa. But it's possible Start screen might
		# look for data from a different scene. So both incoming and outgoing scenes might implement get/receive_data
		# but you may not always want to process that data. This is way more explanation than you need for something
		# that's pretty much designed to work this way and fail silently when not in use :D
		
		push_warning("Level %s is receiving data it cannot process" % name)

## 씬이 트리에 추가된 직후 호출 — 플레이어 데이터 설정, 탐지 잠금, 시작 위치 초기화 등
## 사용자가 조작권을 얻기 전에 수행해야 할 초기화를 처리한다.
func init_scene() -> void:
	set_player_data()
	
	if stage_type == Constants.TYPE_COMPLETE:
		player.set_find_lock(true)
	
	#탐지 없이 뛰는 스테이지일 경우
	if run_stage:
		player.set_find_lock(true)
		GameEvents.emit_stage_run(true)
	init_player_location()
	GameEvents.node_ready.emit("player")

## 트랜지션 완료 후 호출 — 플레이어를 활성화하고 도어/텔레포트 시그널을 연결한다.
## 베이스 스테이지에서는 라이프 초기화 및 자동 저장도 수행한다.
func start_scene() -> void:
	player.enable()
	
	if stage_type == Constants.TYPE_BASE:
		global_game_manager.init_base_life()
		
		if MetaProgression.get_play_time() > 0.0: #게임 새로 시작시 바로 자동저장되어 튜토리얼이 스킵되는 버그로 추가한 코드
			MetaProgression.auto_save()

	#if stage_type == Constants.TYPE_STAGE:
		#current_npc.npc_visible()

	_connect_to_doors()
	_connect_to_teleports()
	
	stage_start.emit()

## 핸드오프 데이터의 도어/텔레포트 이름을 기반으로 플레이어의 시작 위치와 방향을 설정한다.
func init_player_location() -> void:
	player.visible = true
	
	
	GameEvents.call_deferred("emit_stage_change")
#	var doors = find_children("*","Door")
	if data != null:
		var door_found = false
		for door in doors:
			if door.name == data.entry_door_name:
				player.position = door.get_player_entry_vector()
				door_found = true
				
		for teleport in teleports:
			if teleport.name == data.entry_door_name:
				player.position = teleport.get_player_entry_vector()
				
		if not door_found:
			push_error("경고: 지정된 이름의 도어를 찾을 수 없습니다. 이름을 확인해주세요!")
		player.orient(data.move_dir)
	if doors == null:
		push_error("door정보가 비었습니다. 채워주세요!")

## 플레이어가 [Door]에 진입했을 때 호출. 도어 시그널 해제, 플레이어 비활성화,
## 핸드오프 데이터 생성 후 다음 씬 전환을 준비한다.
func _on_player_entered_door(door:Door) -> void:
	_disconnect_from_doors()
	#train_standard.globalLight.enabled
	player.disable()
	player.queue_free()
	GameEvents.emit_in_next_stage()
	if current_npc:
		current_npc.hide()
	
	data = LevelDataHandoff.new()
	data.entry_door_name = door.entry_door_name
	data.move_dir = door.get_move_dir()
	set_process(false)
		
## 플레이어가 [Teleport]에 진입했을 때 호출. 텔레포트 시그널 해제 및 핸드오프 데이터 생성.
func _on_player_teleport(_teleport:Teleport) -> void:
	_disconnect_from_teleports()
	GameEvents.emit_in_next_stage()
	#train_standard.globalLight.enabled
	#player.disable()
	#player.queue_free()
	data = LevelDataHandoff.new()
	
	data.entry_door_name = "frontDoor"
	data.move_dir = _teleport.get_move_dir()
	set_process(false)

## 레벨 내 모든 [Door]의 [signal Door.player_entered_door] 시그널에 연결한다.
func _connect_to_doors() -> void:
	for door in doors:
		if not door.player_entered_door.is_connected(_on_player_entered_door):
			door.player_entered_door.connect(_on_player_entered_door)

## 레벨 내 모든 [Door] 시그널 연결을 해제한다.
func _disconnect_from_doors() -> void:
	for door in doors:
		if door.player_entered_door.is_connected(_on_player_entered_door):
			door.player_entered_door.disconnect(_on_player_entered_door)
			
## 레벨 내 모든 [Teleport]의 시그널에 연결한다.
func _connect_to_teleports() -> void:
	for teleport in teleports:
		if not teleport.player_entered_teleport.is_connected(_on_player_teleport):
			teleport.player_entered_teleport.connect(_on_player_teleport)

## 레벨 내 모든 [Teleport] 시그널 연결을 해제한다.
func _disconnect_from_teleports() -> void:
	for teleport in teleports:
		if teleport.player_entered_teleport.is_connected(_on_player_teleport):
			teleport.player_entered_teleport.disconnect(_on_player_teleport)
			

## [GlobalGameManager]의 플레이어 데이터를 [member player]에 적용한다.
## 데이터가 [code]null[/code]이면 무시한다.
func set_player_data():
	# 플레이어 데이터가 null인 경우 함수 종료
	if global_game_manager.player_data == null:
		return
	global_game_manager.player_data.set_player_data(player)
