extends VBoxContainer

const BUTTON_SCENE = preload("res://Gameplay/qa/voice_qa_button.tscn")

@onready var header_button: Button = $HeaderButton
@onready var content: VBoxContainer = $Content

var viewer: Node = null
var voice_buttons: Array = []
var folder_name: String = ""
var _items: Array = []
var _loaded: bool = false
var _char_filter: String = ""

func setup(p_folder_name: String, items: Array, qa_viewer: Node) -> void:
	viewer = qa_viewer
	folder_name = p_folder_name
	_items = items
	content.visible = false
	header_button.text = "▶  " + folder_name
	header_button.pressed.connect(_toggle)

func _toggle() -> void:
	content.visible = not content.visible
	header_button.text = ("▼  " if content.visible else "▶  ") + folder_name
	if content.visible and not _loaded:
		_load_buttons()

func _load_buttons() -> void:
	_loaded = true
	for item in _items:
		var btn: Button = BUTTON_SCENE.instantiate()
		content.add_child(btn)
		btn.setup(item.id, item.char_name, item.text, item.path, item.has_file, self)
		if not _char_filter.is_empty():
			btn.visible = item.char_name == _char_filter
		voice_buttons.append(btn)
	viewer.on_section_loaded(self)

func set_collapsed(collapsed: bool) -> void:
	content.visible = not collapsed
	header_button.text = ("▼  " if not collapsed else "▶  ") + folder_name
	if not collapsed and not _loaded:
		_load_buttons()

## id로 버튼을 찾는다. 없으면 null. 필요시 섹션을 펼쳐 버튼을 로딩한다.
func find_button_by_id(id: String) -> Button:
	var has_item := false
	for item in _items:
		if item.id == id:
			has_item = true
			break
	if not has_item:
		return null
	set_collapsed(false)
	for btn in voice_buttons:
		if btn.voice_id == id:
			return btn
	return null

func get_next_button(current: Button) -> Button:
	var idx := voice_buttons.find(current)
	if idx >= 0 and idx < voice_buttons.size() - 1:
		return voice_buttons[idx + 1]
	return null


## 캐릭터 필터 적용. 빈 문자열이면 전체 표시.
func set_char_filter(filter: String) -> void:
	_char_filter = filter
	if filter.is_empty():
		visible = true
		for btn in voice_buttons:
			btn.visible = true
		return
	var has_match := _items.any(func(i): return i.char_name == filter)
	visible = has_match
	for btn in voice_buttons:
		btn.visible = btn.char_name == filter
