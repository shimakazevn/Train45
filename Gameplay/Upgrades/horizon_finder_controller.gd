extends AbilityController

var floor_manager : FloorManager
var anomaly_collision : CollisionShape2D

@export var horizon_finder : PackedScene

const ANOMARY_UPPER := [0,120]
const ANOMARY_MIDDLE := [120,240]
const ANOMARY_LOWER := [240,360]

func _ready():
	floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
	if floor_manager.current_stage_type == Constants.TYPE_STAGE:
		if not floor_manager.current_level.run_stage:
			anomaly_collision = floor_manager.current_anomaly.anomaly_collision
			set_horizon()
	elif floor_manager.current_stage_type == Constants.TYPE_SAFE:
		anomaly_collision = null
		set_horizon()
		
func set_horizon():
	var horizon_finder_instance = horizon_finder.instantiate() as NinePatchRect
	if anomaly_collision:
		var y_pos = anomaly_collision.global_position.y

		if y_pos < 120:
			horizon_finder_instance.position.y = 0
		elif y_pos < 240:
			horizon_finder_instance.position.y = 120
		elif y_pos < 360:
			horizon_finder_instance.position.y = 240
	else:
		var random_y = [0,120,240].pick_random()
		horizon_finder_instance.position.y = random_y
	floor_manager.current_level.add_child(horizon_finder_instance)
