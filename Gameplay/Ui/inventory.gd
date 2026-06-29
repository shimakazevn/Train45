extends Control
class_name Inventory

@export var inventory_manager: InventoryManager
@export var equipment: Equipment

@export var inven_item: PackedScene
@export var cost_bubble_container: InventoryCostBubbles
@onready var item_name_lable: Label = %ItemNameLable
@onready var description_label: Label = %DescriptionLabel
@onready var icon_slot: TextureRect = %IconSlot
@onready var cost_label_container: InvenCost = %CostLabelContainer
@onready var inventory_anim: AnimationPlayer = $InventoryAnim
@onready var inven_stream_player: UiSoundStreamPlayer = $InvenStreamPlayer

var buttons: Array[Inven_Item]

var item_data : ItemData = ItemData.new()
enum InvenState {INVEN_CLOSE, INVEN_OPEN}
var current_inven_state = InvenState.INVEN_CLOSE

func _ready() -> void:
	item_name_lable.text = ""
	icon_slot.texture = null
	description_label.text = ""
	cost_label_container.current_cost_label.text = "0"
	
	create_items()
	#call_deferred("update_current_cost")
	set_inventory_state(InvenState.INVEN_CLOSE)

func set_inventory_state(state : InvenState):
	if current_inven_state == state:
		return

	match state:
		InvenState.INVEN_CLOSE:
			inventory_anim.play_backwards("in")
			inven_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.SOUND_INVEN_OFF)
			
			if get_viewport().gui_focus_changed.is_connected(on_focus_changed):
				get_viewport().gui_focus_changed.disconnect(on_focus_changed)
				
			await inventory_anim.animation_finished
			get_tree().paused = false
			hide()
			GameEvents.set_window_state(Constants.WINDOW_INVEN_OPEN, false) #완전히 닫히고 나서 리스트에서 빼기
		InvenState.INVEN_OPEN:
			GameEvents.set_window_state(Constants.WINDOW_INVEN_OPEN, true)
			
			inventory_anim.play("in")
			inven_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.SOUND_INVEN_ON)
			
			if not get_viewport().gui_focus_changed.is_connected(on_focus_changed):
				get_viewport().gui_focus_changed.connect(on_focus_changed)
			create_items()
			
			inventory_manager.update_max_cost()
			update_current_cost()
			update_icons()
			
			get_tree().paused = true
			show()

	current_inven_state = state

func create_items():
	var itemslots = get_tree().get_nodes_in_group("invenitem") as Array[TextureRect]
	
	for _item in MetaProgression.get_save_data_ability():
		var item_slot = itemslots[item_data.get_item_dict_count(_item)] as TextureRect
		if item_slot.get_child_count() > 0:
			continue
		var inven_item_instance = inven_item.instantiate() as Inven_Item
		inven_item_instance.inventory = self
		inven_item_instance.item_info = item_data.get_item(_item, ItemData.ItemTypes.ABILITY)
		inven_item_instance.item_index = item_data.get_item_dict_count(_item)
		inven_item_instance.mouse_entered.connect(_on_mouse_entered.bind(inven_item_instance))
		inven_item_instance.pressed.connect(_on_equip_item.bind(inven_item_instance))
		itemslots[inven_item_instance.item_index].add_child(inven_item_instance)
		buttons.append(inven_item_instance)
	
	if buttons.size() > 0:
		# 1️⃣ item_index 기준으로 정렬된 새 배열 생성
		var sorted_buttons = buttons.duplicate()
		sorted_buttons.sort_custom(func(a, b):
			return a.item_index < b.item_index
		)

		# 2️⃣ 좌우 포커스 설정
		for i in range(sorted_buttons.size()):
			var button: Inven_Item = sorted_buttons[i]

			# 왼쪽 연결
			if i > 0:
				button.focus_neighbor_left = sorted_buttons[i - 1].get_path()
			# 오른쪽 연결
			if i < sorted_buttons.size() - 1:
				button.focus_neighbor_right = sorted_buttons[i + 1].get_path()

	first_button_focus()

func first_button_focus():
	var first_button = get_tree().get_first_node_in_group("invenitembutton") as Inven_Item
	if first_button:
		first_button.grab_focus()

func _on_mouse_entered(button: Button):
	if !button is Inven_Item:
		return
	detail_update(button)
	
func _on_equip_item(button: Button):
	if !button is Inven_Item:
		return
	var _item = button as Inven_Item
	if !_item.is_equip:
		equip_item(_item)
	else:
		unequip_item(_item)

	update_icons()

func equip_item(current_item: Inven_Item):
	if equipment.has_equip_item(current_item.item_info):
		return
	if not can_equip(current_item.item_info.cost):
		inven_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.SOUND_INVEN_ITEM_DONT_EQUIP)
		return

	inventory_manager.set_current_cost(current_item.item_info.cost)
	equipment.add_equip_list(current_item.item_info)
	current_item.set_equip(true)
	inven_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.SOUND_INVEN_ITEM_EQUIP)
	
	update_current_cost()

func can_equip(item_cost: int) -> bool:
	var target_cost = inventory_manager.current_cost + item_cost
	if target_cost > inventory_manager.max_cost:
		return false
	return true

func unequip_item(current_item: Inven_Item):
	if !equipment.has_equip_item(current_item.item_info):
		return
		
	inventory_manager.set_current_cost(-current_item.item_info.cost)
	equipment.erase_equip_list(current_item.item_info)
	current_item.set_equip(false)
	update_current_cost()

func detail_update(button: Inven_Item):
	item_name_lable.text = button.item_info.name
	description_label.text = button.item_info.description
	icon_slot.texture = button.item_info.icon
	if not button.is_equip:
		cost_bubble_container.show_cost_bubble_example(button.item_info.cost)
	else:
		cost_bubble_container.show_cost_bubble_example(0)

func update_current_cost():
	if !inventory_manager:
		return
	cost_bubble_container.update_cost_bubble(inventory_manager.max_cost, inventory_manager.current_cost)
	cost_label_container.update_cost_label(inventory_manager.current_cost, InvenCost.CostType.CurrentCost)
	cost_label_container.update_cost_label(inventory_manager.max_cost, InvenCost.CostType.MaxCost)

func update_icons():
	var inven_items = get_tree().get_nodes_in_group("invenitembutton")
	for _item in inven_items:
		var _current_item = _item as Inven_Item
		if can_equip(_current_item.item_info.cost):
			_current_item.is_can_equip(true)
		else:
			_current_item.is_can_equip(false)


func _input(event):
	if event.is_action_pressed("esc") or event.is_action_pressed(Constants.TRAIN_KEY_INVENTORY):
		set_inven_close()


func _on_exit_pressed() -> void:
	set_inven_close()

##인벤토리 닫기. 닫고 여는 애니메이션중엔 실행되지 않음
func set_inven_close():
	if current_inven_state == InvenState.INVEN_OPEN and not inventory_anim.is_playing():
		set_inventory_state(InvenState.INVEN_CLOSE)
		get_viewport().set_input_as_handled()

func on_focus_changed(button: Button):
	if button as Inven_Item:
		detail_update(button)
