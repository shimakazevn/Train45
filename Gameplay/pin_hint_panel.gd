extends ColorRect
class_name PinedHint
## 힌트를 고정하여 볼 수 있는 패널.
## 선택한 힌트의 이미지와 설명을 상시 표시하며, 스크롤을 지원한다.

## 힌트 정보 패널 참조
@export var hint_panel: Panel

## 힌트 이미지를 표시하는 [TextureRect]
@onready var hint_info_texture: TextureRect = $HintInfoTexture
## 힌트 설명을 표시하는 [Label]
@onready var hint_info_label: RichTextLabel = $ScrollContainer/HintInfoLabel
## 스크롤 컨테이너 참조
@export var scroll: ScrollContainer

## 스크롤 속도 (px/sec)
@export var scroll_speed := 250.0 # px/sec
## 스크롤 입력 데드존
@export var deadzone := 0.15

## 초기화 시 패널을 숨긴다.
func _ready() -> void:
	hide()

## 힌트 정보를 고정 패널에 설정하고 표시한다.
## [param hint_info]로 설명 텍스트를, [param hint_texture]로 이미지를 업데이트한다.
func set_pined_hint(hint_info: String, hint_texture: CompressedTexture2D):
	show()
	hint_info_label.text = hint_info
	hint_info_texture.texture = hint_texture

## 매 프레임 스크롤 입력을 처리한다. 힌트 패널이 표시 중이면 스크롤을 비활성화한다.
func _process(delta: float) -> void:
	var v := Input.get_action_strength("scroll_down") - Input.get_action_strength("scroll_up")
	if abs(v) < deadzone or hint_panel.visible:
		return
	else:
		scroll.scroll_vertical += int(v * scroll_speed * delta)
