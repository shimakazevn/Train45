extends Area2D

var stage_clear = false
var anomaly_enable := true
var player_in := false
var player : Player

func _ready():
	GameEvents.stage_clear.connect(_on_stage_clear)
	
func _on_stage_clear():
	stage_clear = true

func _on_area_entered(area):
	if area is AnomalyDisableArea:
		anomaly_enable = false
		

func _on_area_exited(area):
	if area is AnomalyDisableArea:
		anomaly_enable = true
		

func _on_body_entered(body):
	if body is Player:
		player = body
		player_in = true

func _on_body_exited(body):
	if body is Player:
		player_in = false

func _process(_delta):
	if anomaly_enable and player_in and !stage_clear and GameEvents.game_state == Constants.STATE_NORMAL:
		#player.find_faild.emit()
		player.rape("ghost")
		anomaly_enable = false
