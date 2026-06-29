extends Node2D

var global_game_manager: GlobalGameManager
@export var trophy: Array[Node2D] = []

func _ready():
	global_game_manager = get_tree().get_first_node_in_group("globalgamemanager") as GlobalGameManager
	global_game_manager.ready.connect(on_global_game_manager_ready)
	#tropht_update()

func on_global_game_manager_ready():
	#tropht_update()
	pass

func tropht_update():
	# game_clear_num이 0이면 아무 트로피도 표시하지 않음
	if global_game_manager.game_clear_num == 0:
		return
	
	# game_clear_num이 0이 아닌 경우, 해당 인덱스의 트로피를 visible하게 설정
	for i in range(global_game_manager.game_clear_num):
		if i < trophy.size():
			trophy[i].visible = true
