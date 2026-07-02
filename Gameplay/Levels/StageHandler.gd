class_name StageHandler extends Node

@export var npc_active := true
var stage : Level
var player: Player
var stage_type
var run_stage : bool


var stage_clear : bool
var stage_find_anomaly : bool # 이상현상이 있는 스테이지에서 클리어시 대화 출력을 위한 변수

func _ready():
	stage = get_parent()
	player = stage.player
	player.find_anomaly.connect(find_target)
	player.find_faild.connect(_on_find_faild)
	stage_type = stage.stage_type
	run_stage = stage.run_stage
	stage_clear = stage.stage_clear
	stage_find_anomaly = stage.stage_find_anomaly
	stage.npc_active = npc_active

func find_target() -> void:
	# 회상방은 일반 스테이지 클리어 개념이 없다(귀신은 per-ghost로 따로 감지) → 전역 클리어 파이프라인 차단.
	if GameEvents.is_recollection_room:
		return
	if stage_type == Constants.TYPE_BASE:
		return
	if stage_clear == true:
		print("Already cleared. Returning from StageHandler/find_target")
		return
	stage_clear = true
	get_parent().stage_find_anomaly = true
	stage_find_anomaly = true
	GameEvents.emit_stage_clear()
	var floor_manager = get_tree().get_first_node_in_group("floormanager")
	floor_manager.stage_clear(get_parent())

func _on_find_faild() -> void:
	#level의 _ready에서 클리어 스테이지 목록 초기화가 되기 때문에 주석 처리 해놓음
	#var floor_manager = get_tree().get_first_node_in_group("floormanager")
	#floor_manager.stage_clear_list_remove() 
	pass

func next_stage()-> String:
	var floor_manager = get_tree().get_first_node_in_group("floormanager")
	var next_stage_name = floor_manager
	return next_stage_name
