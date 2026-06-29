extends AbilityController

var floor_manager : FloorManager

@export var daruma_packed : PackedScene

func _ready() -> void:
	floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
	if floor_manager.current_stage_type == Constants.TYPE_SAFE:
		set_daruma()

func set_daruma():
	var daruma_instance = daruma_packed.instantiate()
	floor_manager.current_level.train_standard.add_child(daruma_instance)
