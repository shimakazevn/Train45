## Button 또는 Label의 차일드 컴포넌트로 추가하면 텍스트 너비/높이에 따라 폰트 크기를 자동 조절한다.
extends Node
class_name AutoShirinkComponent

@export var max_font_size: int = 24
@export var min_font_size: int = 10
@export var fixed_ref_width: float = 0.0
@export var fixed_ref_height: float = 0.0

var _parent  # Button 또는 Label
var _ref_width: float = 0.0
var _ref_height: float = 0.0
var _last_text: String = ""

func _ready() -> void:
	_parent = get_parent() as Button
	if _parent == null:
		_parent = get_parent() as Label
	assert(_parent != null, "auto_shrink_component의 부모는 Button 또는 Label이어야 합니다.")
	await get_tree().process_frame
	_ref_width = _parent.size.x
	_ref_height = _parent.size.y
	# LabelSettings 공유 리소스를 복제해 이 노드 전용으로 만든다.
	if _parent is Label and _parent.label_settings != null:
		_parent.label_settings = _parent.label_settings.duplicate()
	_adjust()
	LanguageManager.lang_changed.connect(func(_locale): _adjust())

func _process(_delta: float) -> void:
	if _parent.text != _last_text:
		_last_text = _parent.text
		_adjust()

func _adjust() -> void:
	if _parent.text.is_empty() or _ref_width <= 0:
		return
	var w_threshold := fixed_ref_width if fixed_ref_width > 0.0 else _ref_width
	var h_threshold := fixed_ref_height if fixed_ref_height > 0.0 else _ref_height
	var font: Font = _parent.get_theme_font("font")
	var sz := max_font_size
	while sz > min_font_size:
		var text_size := font.get_string_size(tr(_parent.text), HORIZONTAL_ALIGNMENT_LEFT, -1, sz)
		if text_size.x > w_threshold or text_size.y > h_threshold:
			sz -= 1
		else:
			break
	if _parent is Label and _parent.label_settings != null:
		_parent.label_settings.font_size = sz
	else:
		_parent.add_theme_font_size_override("font_size", sz)

func update_adjust():
	_adjust()
