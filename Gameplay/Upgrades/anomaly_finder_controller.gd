extends AbilityController

var floor_manager : FloorManager

@export var anomaly_finder : PackedScene
var anomaly_collision : CollisionShape2D

func _ready():
	floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
	if floor_manager.current_stage_type == Constants.TYPE_STAGE:
		if not floor_manager.current_level.run_stage:
			anomaly_collision = floor_manager.current_anomaly.anomaly_collision
			set_anomaly_instance()
	elif floor_manager.current_stage_type == Constants.TYPE_SAFE:
		anomaly_collision = null
		set_anomaly_instance()
		
func set_anomaly_instance():
	# 파인더 인스턴스 생성 및 크기 설정
	var anomaly_finder_instance = anomaly_finder.instantiate()
	anomaly_finder_instance.size.y = 360.0  # 파인더의 y 크기 설정
	anomaly_finder_instance.size.x = 1200.0  # 파인더의 x 크기 설정 (적절히 조정 가능)

	if anomaly_collision == null:
		var min_x = 0
		var max_x = 1920 - anomaly_finder_instance.size.x
		anomaly_finder_instance.position.x = randf_range(min_x, max_x)
	else:
		var min_x = max(0, anomaly_collision.position.x - anomaly_finder_instance.size.x)
		var max_x = min(1920 - anomaly_finder_instance.size.x, anomaly_collision.position.x)
		anomaly_finder_instance.position.x = randf_range(min_x, max_x)
		#anomaly_collision.get_parent().add_child(anomaly_finder_instance)
	floor_manager.current_level.add_child(anomaly_finder_instance)
