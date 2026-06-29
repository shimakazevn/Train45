extends AbilityController

@export var love_bonus: PackedScene
var floor_manager : FloorManager

func _ready():
	floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
	if floor_manager.current_stage_type == Constants.TYPE_STAGE:
		love_bonus_set()
	elif floor_manager.current_stage_type == Constants.TYPE_SAFE:
		love_bonus_set()


func love_bonus_set():
	var love_bonus_instance = love_bonus.instantiate()
	floor_manager.current_level.add_child(love_bonus_instance)
