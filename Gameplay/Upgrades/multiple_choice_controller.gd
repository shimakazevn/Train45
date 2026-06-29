extends AbilityController

var floor_manager : FloorManager

@export var choice_circle : PackedScene
var anomaly_collision : CollisionShape2D
const CHOICE_COUNT := 5

func _ready():
	floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
	if floor_manager.current_stage_type == Constants.TYPE_STAGE:
		if not floor_manager.current_level.run_stage:
			anomaly_collision = floor_manager.current_anomaly.anomaly_collision
			set_circles()
	elif floor_manager.current_stage_type == Constants.TYPE_SAFE:
		anomaly_collision = null
		set_circles()


func set_circles():
	var player_position = floor_manager.current_level.player.position
	var is_answer := true
	for i in CHOICE_COUNT:
		var circle_instance = choice_circle.instantiate() as ColorRect
		
		circle_instance.position = player_position + Vector2(0, -200)
		circle_instance.target_position.x = randf_range(0,1920 - circle_instance.size.x)
		circle_instance.target_position.y = randf_range(0,360 - circle_instance.size.y)
		if is_answer:
			if not anomaly_collision == null:
				circle_instance.target_position = anomaly_collision.global_position
			is_answer = false
		floor_manager.current_level.add_child(circle_instance)
		await get_tree().create_timer(0.2).timeout
	
