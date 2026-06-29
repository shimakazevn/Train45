extends AbilityController

var floor_manager : FloorManager
@export var unvisit_finder : PackedScene

func _ready() -> void:
	floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
	match floor_manager.current_stage_type:
		Constants.TYPE_STAGE, Constants.TYPE_SAFE:
			set_finder()
		
func set_finder():
	var unvisit_finder_instance = unvisit_finder.instantiate()
	
	var hud: TrainHud = get_tree().get_first_node_in_group("hudmain")
	hud.equip_item_container.add_child(unvisit_finder_instance)
