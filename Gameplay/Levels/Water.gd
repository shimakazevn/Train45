extends CanvasGroup

var water_speed := 9.0

var stage_failed := false
var stage_clear := false
var init_position_y := 0.0
@export var stage : Level
var player : Player
var player_init_speed
var player_init_acceleration

func _ready():
	GameEvents.node_ready.connect(_on_player_ready)
	GameEvents.stage_clear.connect(_on_stage_clear)
	
	
func _on_player_ready(node_name : String):
	#플레이어가 완전히 배치되면 감지할수있게 그때 감지를 켜준다.
	if node_name == "player":
		player = stage.player as Player
		player_init_speed = player.velocity_component.max_speed
		player_init_acceleration = player.velocity_component.acceleration
		
		player.set_speed_percentage(45.0)
		
		player.set_speed_acceleration(1)
		init_position_y = position.y
	
	
func _process(delta):
	#print("speed %d" % player.velocity_component.max_speed)
	
	if stage_clear == false:
		if position.y >= 20.0 and stage_failed == false:
			position.y -= water_speed * delta
		else :
			stage_failed = true
			speed_init()
			player.find_faild.emit()
	else:
		if position.y != init_position_y:
			position.y = init_position_y


func _on_stage_clear():
	if GameEvents.node_ready.is_connected(_on_player_ready):
		GameEvents.node_ready.disconnect(_on_player_ready)
	speed_init()
	stage_clear = true

func speed_init():
	if is_instance_valid(player):
		player.velocity_component.max_speed = player_init_speed
		player.velocity_component.acceleration = player_init_acceleration
