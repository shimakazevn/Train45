extends AbilityController

var floor_manager : FloorManager

var player: Player
var is_magnet: bool = false
var current_drop_items: Array[Node]

func _ready():
	player = get_parent().owner
	floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
	if floor_manager.current_stage_type == Constants.TYPE_STAGE:
		pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action"):
		if Dialogic.current_timeline:
			return
		is_magnet = true
		current_drop_items = get_tree().get_nodes_in_group("DropItem")
	elif event.is_action_released("action"):
		is_magnet = false

func _process(delta: float) -> void:
	if is_magnet and player:
		for i in current_drop_items:
			if is_instance_valid(i):
				var drop_item = i as DropItem
				if not drop_item.is_picking:
					drop_item.position = drop_item.position.move_toward(player.position, drop_item.pick_speed* delta)
				
