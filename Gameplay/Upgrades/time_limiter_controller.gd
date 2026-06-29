extends AbilityController

var floor_manager : FloorManager
@export var time_limiter : PackedScene

func _ready() -> void:
	floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
	if floor_manager.current_stage_type == Constants.TYPE_STAGE:
		if not floor_manager.current_level.run_stage:
			set_limiter()
	elif floor_manager.current_stage_type == Constants.TYPE_SAFE:
		set_limiter()
		
func set_limiter():
	var time_limiter_instance = time_limiter.instantiate()
	
	var hud: TrainHud = get_tree().get_first_node_in_group("hudmain")
	hud.equip_item_container.add_child(time_limiter_instance)
