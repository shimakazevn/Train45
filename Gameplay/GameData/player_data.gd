class_name PlayerData

const PLAYER_START_SPEED := 190.0
const PLAYER_START_ACCELATION := 50.0
const PLAYER_START_CHARGE_TIME := 3.0
const PLAYER_START_LIFE := 1
const PLAYER_START_AREA_SIZE := Vector2(118,352)
const PLAYER_START_COLLECT_SIZE := Vector2(86,288)

var max_speed : float = PLAYER_START_SPEED
var charge_time : float = PLAYER_START_CHARGE_TIME

var abilities : Array = []

var current_info: Dictionary = {
	"max_speed" : PLAYER_START_SPEED,
	"charge_time" : PLAYER_START_CHARGE_TIME,
	"accelation" : PLAYER_START_ACCELATION,
	"base_life" : PLAYER_START_LIFE,
	"find_area" : PLAYER_START_AREA_SIZE,
	"collect_area" : PLAYER_START_COLLECT_SIZE,
	"abilities" : []
}

func set_player_data(player: Player):
	# 플레이어의 속도 및 charge_time 데이터를 복원
	player.velocity_component.max_speed = current_info["max_speed"]
	player.charge_time = current_info["charge_time"]
	
	# global_game_manager에 저장된 abilities를 플레이어에게 복원
	var all_abilities = current_info["abilities"]
	for child in all_abilities:
		# 플레이어의 abilities에 자식 노드 추가
		player.abilities.add_child(child)
