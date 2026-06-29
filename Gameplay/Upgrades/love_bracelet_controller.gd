extends AbilityController

@export var love_bracelet : PackedScene
var floor_manager : FloorManager

func _ready():
	floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
	if floor_manager.current_stage_type == Constants.TYPE_STAGE:
		love_bonus_set()
	elif floor_manager.current_stage_type == Constants.TYPE_SAFE:
		love_bonus_set()
	elif floor_manager.current_stage_type == Constants.TYPE_BASE:
		love_bonus_set()


func love_bonus_set():
	for node in floor_manager.current_level.get_children():
		if node.is_in_group("love_bracelet"):
			node.queue_free()

	var love_bracelet_instance = love_bracelet.instantiate()
	floor_manager.current_level.add_child(love_bracelet_instance)
	self.tree_exiting.connect(love_bracelet_instance.queue_free)
