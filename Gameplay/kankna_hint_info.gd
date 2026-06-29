extends Panel
## 힌트 정보 패널을 관리하는 [code]Panel[/code].
## 선택된 힌트 슬롯의 상세 정보(이미지, 설명, 빈칸 수)를 표시하며,
## 힌트 고정 기능과 스크롤을 지원한다.

## 상세 정보 패널이 닫힐 때 발생하는 시그널
signal detail_exit()

## 힌트 고정 패널 참조
@export var pin_hint_panel: PinedHint
## 힌트 이미지를 표시하는 [TextureRect]
@onready var hint_info_texture: TextureRect = %HintInfoTexture
## 힌트 설명을 표시하는 [Label]
@onready var hint_info_label: RichTextLabel = %HintInfoLabel
## 힌트 고정 버튼
@onready var hint_info_pin_button: Button = %HintInfoPinButton

## 스크롤 컨테이너 참조
@export var scroll: ScrollContainer
## 메인 빈칸 힌트 컴포넌트
@export var hint_blank_container: HintBlankComponent
## 힌트 정보창 내 빈칸 힌트 컴포넌트
@export var hint_blank_container_info: HintBlankComponent # 힌트 정보창에 뜨는 칸갯수힌트
## 스크롤 속도 (px/sec)
var scroll_speed := 250.0 # px/sec
## 스크롤 입력 데드존
var deadzone := 0.15

## 현재 선택된 [HintSlot] 참조
var current_hint_slot: HintSlot

## 초기화 시 힌트 패널을 숨긴다.
func _ready() -> void:
	hide_hint()

func _input(event):
	if event.is_action_pressed("esc") and visible:
		_on_hint_info_back_button_pressed()
		get_viewport().set_input_as_handled()

## 매 프레임 스크롤 입력을 처리한다.
func _process(delta: float) -> void:
	var v := Input.get_action_strength("scroll_down") - Input.get_action_strength("scroll_up")
	if abs(v) < deadzone:
		return

	scroll.scroll_vertical += int(v * scroll_speed * delta)

## [param hint_slot]의 상세 정보를 패널에 표시한다.
## 이미지, 설명, 빈칸 수를 업데이트하고 고정 버튼에 포커스를 맞춘다.
func show_hint(hint_slot: HintSlot):
	hint_info_pin_button.grab_focus()
	current_hint_slot = hint_slot
	
	show()
	if hint_slot.hint_info == null:
		return

	if hint_slot.hint_info.texture:
		hint_info_texture.texture = hint_slot.hint_info.texture
	hint_info_label.text = hint_slot.hint_info.description
	hint_blank_container_info.set_blank_slot(current_hint_slot.answer_num)
	hint_blank_container_info.update_hint_labels(hint_slot.hint_info)

## 힌트 정보 패널을 숨기고 [signal detail_exit] 시그널을 발생시킨다.
func hide_hint():
	if self.visible:
		hide()
		detail_exit.emit()

## 현재 힌트를 고정 패널에 설정한다.
func set_fin_hint():
	pin_hint_panel.set_pined_hint(current_hint_slot.hint_info.description, current_hint_slot.hint_info.texture)

## 뒤로 가기 버튼 클릭 시 힌트 패널을 숨긴다.
func _on_hint_info_back_button_pressed() -> void:
	hide_hint()

## 힌트를 확인하면서 노선을 설정할 수 있게 보조 창에 정보를 띄운다
func _on_hint_info_pin_button_pressed() -> void:
	set_fin_hint()
	hint_blank_container.set_blank_slot(current_hint_slot.answer_num)
	hide_hint()
