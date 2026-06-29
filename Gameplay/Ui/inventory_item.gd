extends Button
class_name Inven_Item

var inventory : Inventory

@onready var select_box: TextureRect = $SelectBox

@onready var icon_rect: TextureRect = $IconRect
@onready var item_name: Label = $ItemName
@onready var cost_label: Label = %CostLabel

var item_index : int
var item_info : AbilityUpgrade

var is_equip := false

func _ready() -> void:
	if !item_info:
		return
	if select_box.visible:
		hide()
	item_name.text = item_info.name
	if item_info.icon:
		icon_rect.texture = item_info.icon
	cost_label.text = str(item_info.cost)

	set_equip(current_equip())

func set_equip(equip: bool):
	if equip:
		is_equip = true
	else:
		is_equip = false
	update_icon()
	icon_rect.update_scale(equip)

func update_icon():
	if is_equip:
		select_box.show()
	else:
		select_box.hide()

func is_can_equip(can: bool):
	if is_equip:
		return
	if can:
		modulate.a8 = 255
		modulate = Color.WHITE
	else:
		modulate.a8 = 120
		modulate = Color.INDIAN_RED
		

func current_equip()-> bool:
	var equip_list = MetaProgression.get_equipment_array() as Array
	if equip_list.has(item_info.id):
		return true
	return false
