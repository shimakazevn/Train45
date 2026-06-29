extends AbilityController

var floor_manager : FloorManager
var anomaly_collision : CollisionShape2D

@export var cola : PackedScene

func _ready() -> void:
	floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
	if floor_manager.current_stage_type == Constants.TYPE_STAGE:
		if not floor_manager.current_level.run_stage:
			anomaly_collision = floor_manager.current_anomaly.anomaly_collision
			set_cola()
	elif floor_manager.current_stage_type == Constants.TYPE_SAFE:
		anomaly_collision = null
		set_cola()

func set_cola():
	var player = floor_manager.current_level.player as Player
	var cola_instance = cola.instantiate()
	cola_instance.player = player
	cola_instance.anomaly_collision = anomaly_collision
	player.add_child(cola_instance)
