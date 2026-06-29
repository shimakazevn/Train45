extends Button
class_name RouteSlot

signal is_in_end

var active_route_buy_mode: bool = false
var is_unlocked: bool = false
var current_route : Dictionary = {}
var h_scene_data: HSceneRes
var item_data: ItemData
var route_path : String
var route_num : int
var total_route_num: int
@onready var route_num_label: Label = %RouteNum
@onready var route_title: Label = %RouteTitle
@onready var button_stream_player_component: AudioStreamPlayer = $ButtonStreamPlayerComponent
@onready var unlock_label: Label = $UnlockLabel
@onready var event_texture: TextureRect = %EventTexture
@onready var event_love_level: Label = %EventLoveLevel

@onready var item_box_icon: TextureRect = $ItemBoxIcon


var basic_route := []

func _ready() -> void:
	is_in_end.connect(_on_is_in_end)
	unlock_label.hide()
	route_num_label.text = str(route_num)
	route_info_setting()
	

func route_info_setting():
	if current_route == {}:
		return

	event_texture.texture = null
	is_unlocked = get_is_unlocked()

	if is_unlocked or MetaProgression.has_read_event(Constants.QUESTLINE_KANKANNAVI_UNHIDE_TITLE):
		route_title.text = current_route["title"]
	else:
		route_title.text = "???"

	_adjust_title_font_size()
	_inject_title_linebreak()
	update_h_event_info()


## [KR] 루트 슬롯 전용: 일본어 타이틀의 콜론(：)·반점(、) 뒤에서 줄바꿈한다.
## [KR] (예: 露出：\nおっぱい / レイナ、\n◯◯) 전각 부호라 영어/한국어(ASCII ':' ',')는 영향이 없다.
## [KR] 네비·힌트 등 다른 UI는 한 줄로 나와야 하므로 여기(슬롯)에서만 처리한다.
const _TITLE_BREAK_AFTER := ["：", "、"]
func _inject_title_linebreak() -> void:
	var t := tr(route_title.text)
	for c in _TITLE_BREAK_AFTER:
		t = t.replace(c, c + "\n")
	route_title.text = t


func _adjust_title_font_size() -> void:
	var longest := 0
	for word in tr(route_title.text).split(" "):
		longest = max(longest, word.length())

	if longest > 11:
		route_title.add_theme_font_size_override("font_size", 14)
		#print("font 14")
	elif longest > 7:
		route_title.add_theme_font_size_override("font_size", 15)
		#print("font 15")
	else:
		route_title.remove_theme_font_size_override("font_size")
		#print("font 16")

func update_h_event_info():
	if h_scene_data:
		event_texture.texture = Constants.SD_ICONS[h_scene_data.partner]
		event_love_level.text = str(h_scene_data.love_ability)
		event_texture.show()
		event_love_level.show()
		if is_event_unlock():
			event_texture.modulate = Color.WHITE
			event_love_level.modulate = Color.WHITE
		else:
			event_texture.modulate = Color.GRAY
			event_love_level.modulate = Color.GRAY
			event_texture.hide()
			event_love_level.hide()
	else:
		event_texture.texture = null
		event_texture.hide()
		event_love_level.hide()

func is_event_unlock()-> bool:
	if h_scene_data and MetaProgression.get_npc_unlock_event(h_scene_data.partner, h_scene_data.scene_name):
		return true
	return false

func get_is_unlocked()-> bool:
	var unlocked: bool
	if !MetaProgression.has_route_data(route_path):
		unlocked = false
		
		if basic_route.has(route_num): #1챕터부터 해금된 노선이면 선택 가능하게
			unlocked = true
	else:
		unlocked = true
	
	if Constants.ROUTE_ALL_UNLOCK:
		unlocked = true
	
	return unlocked

func route_info_update():
	route_info_setting()
	self.modulate = get_color_update(is_unlocked)

func get_color_update(unlocked: bool)->Color:
	if unlocked:
		return Color.WHITE
	else:
		return Color.SLATE_GRAY


func _on_focus_entered() -> void:
	if not MetaProgression.has_read_event(Constants.QUESTLINE_KANKANNAVI_UNHIDE_TITLE):
		return
	if is_unlocked:
		unlock_label.hide()
	else:
		unlock_label.show()


func _on_focus_exited() -> void:
	if not MetaProgression.has_read_event(Constants.QUESTLINE_KANKANNAVI_UNHIDE_TITLE):
		return
	if is_unlocked:
		unlock_label.hide()
	else:
		unlock_label.hide()

##칸칸네비 잠금해제 기능을 통해 노선 해제
func set_unlock():
	MetaProgression.set_route_data(route_path, current_route)
	route_info_update()

func _on_is_in_end():
	route_info_update()

func set_h_event_info(h_res_array: Array):
	for res in h_res_array:
		if res is HSceneRes:
			var scene_name = RouteData.get_stage_path(res.stage_name)
			if scene_name == route_path:
				h_scene_data = res

func get_route_path()-> String:
	return route_path

func get_route_num()-> int:
	return route_num
