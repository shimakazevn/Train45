extends Node
class_name Equipment

var inven_manager : InventoryManager
var equipment_list : Array[AbilityUpgrade]
var item_data : ItemData = ItemData.new()

func _ready() -> void:
	inven_manager = get_parent()
	load_item_from_meta()

func has_equip_item(item: AbilityUpgrade) -> bool:
	if equipment_list.has(item):
		return true
	return false

func add_equip_list(item: AbilityUpgrade):
	equipment_list.append(item)
	MetaProgression.add_equipment(item.id)
	GameEvents.emit_update_equip_item(equipment_list)

func erase_equip_list(item: AbilityUpgrade):
	equipment_list.erase(item)
	MetaProgression.erase_equipment(item.id)
	GameEvents.emit_update_equip_item(equipment_list)

func load_item_from_meta():
	var id_list = MetaProgression.get_equipment_array()
	for id in id_list:
		var current_item = item_data.get_item(id, ItemData.ItemTypes.ABILITY) as AbilityUpgrade
		equipment_list.append(current_item)
		inven_manager.set_current_cost(current_item.cost)
