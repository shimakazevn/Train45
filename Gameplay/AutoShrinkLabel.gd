## 텍스트 너비에 따라 폰트 크기를 자동 조절하는 Label.
## ref_width보다 string이 크면 1씩 줄이고, 작으면 max까지 1씩 키운다.
class_name AutoShrinkLabel
extends Label

@export var max_font_size: int = 24
@export var min_font_size: int = 10

var _ref_width: float = 0.0
var _last_text: String = ""

func _ready() -> void:
	await get_tree().process_frame
	_ref_width = size.x
	_adjust()

func _process(_delta: float) -> void:
	if text != _last_text:
		_last_text = text
		_adjust()

func _adjust() -> void:
	if text.is_empty() or _ref_width <= 0:
		return
	var font := get_theme_font("font")
	var sz := max_font_size
	while sz > min_font_size and font.get_string_size(tr(text), HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > _ref_width:
		sz -= 1
	
	add_theme_font_size_override("font_size", sz)
