extends TextureRect

@export var route_slot: RouteSlot

const ROUTE_BUTTON_ITEM_BOX_NOT_GET = preload("res://resources/ui/route_button_item_box1.png")
const ROUTE_BUTTON_ITEM_BOX_GETTED = preload("res://resources/ui/route_button_item_box2.png")

const ITEM_BOX_DATA := preload("res://Gameplay/GameData/item_box_scenes.json")
var route_path : String

func _ready() -> void:
	hide()
	set_item_box_icon()

func set_item_box_icon():
	route_path = route_slot.get_route_path()
	if not ITEM_BOX_DATA.data.has(route_path) \
	or not MetaProgression.has_read_event(Constants.QUESTLINE_BUTLER_LOVE_QUEST_START):
		hide()
		return
	
	# 아이템 박스 표시 조건
	# 맵 아이템 구매시 혹은 방문 후 상자 아이템 획득시
	
	# 해당 스테이지에 아이템 박스가 있는지 확인
	var box_array = ITEM_BOX_DATA.data[route_path]
	if typeof(box_array) == TYPE_ARRAY and not box_array.is_empty():
		var first_box = box_array[0]
		# 아이템 박스가 있으면 표시
		if first_box.has("name"):
			show()
			set_icon_getted_item_box(box_array)
	else:
		hide()
	
	

func set_icon_getted_item_box(boxes: Array):
	for item in boxes:
		# 힌트 혹은 아이템이 획득 상태일 시 박스 열림 아이콘으로 설정
		if MetaProgression.has_route_hint(item["name"])\
		 or MetaProgression.has_ability(item["name"])\
		or MetaProgression.has_box_getted_stage(route_path):
			self.texture = ROUTE_BUTTON_ITEM_BOX_GETTED
			var box_outline: Material = self.material
			box_outline.set_shader_parameter("width", 0.0)
		else: # 아이템 획득 상태가 아닐 시
			if is_box_map_enabled(): # 분실물 지도를 구매했고 범위 안에 있으면 표시
				show()
			else:
				hide()

## 분실물 표시 아이템의 범위 안에 포함되었는지
func is_box_map_enabled()-> bool:
	var box_maps : Dictionary = route_slot.item_data.BOX_MAPS
	for box in box_maps:
		if MetaProgression.has_box_map(box):
			var box_res: BoxMapItem = box_maps[box]["res"]
			if (route_slot.route_num >= box_res.stage_min) and (route_slot.route_num <= box_res.stage_max):
				return true
	return false
