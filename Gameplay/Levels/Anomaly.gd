extends Area2D

@export var bubble : PackedScene
@onready var anomaly_collision = %AnomalyCollision
var floor_manager : FloorManager

func _ready():
	GameEvents.node_ready.connect(_on_player_ready)
	GameEvents.stage_clear.connect(_on_stage_clear)
	anomaly_collision.disabled = true
	floor_manager = get_tree().get_first_node_in_group("floormanager")
	floor_manager.current_anomaly = self
	
func _on_player_ready(node_name : String):
	#플레이어가 완전히 배치되면 감지할수있게 그때 감지를 켜준다.
	if node_name == "player":
		anomaly_collision.disabled = false

func _on_stage_clear():
	for i in range(30):
		create_exp_bubble()
		
func create_exp_bubble():
	var new_bubble = bubble.instantiate()  # PackedScene을 인스턴스화하여 노드 생성
	
	# 랜덤 위치 오프셋 생성
	var random_offset = Vector2(randi_range(-20, 20), randi_range(-20, 20))
	new_bubble.position = anomaly_collision.position + random_offset  # 방울을 아노말리 근처에 생성
	
	add_child(new_bubble)
