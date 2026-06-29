extends Panel
class_name RouteHint
## 노선도 힌트 패널을 관리하는 [code]Panel[/code].
## 획득한 힌트 목록을 표시하고, 힌트 상세 정보 확인 및 고정 기능을 제공한다.

## 노선도 맵 참조
@onready var route_map: RouteMap = $".."

## 힌트 슬롯 인스턴스용 [PackedScene]
@export var  hint_slot : PackedScene
## 힌트 고정 패널 참조
@export var hint_pint_panel: PinedHint
## 힌트 슬롯을 담는 [VBoxContainer]
@onready var hint_slot_container: VBoxContainer = %HintSlotContainer
## 힌트 이미지를 표시하는 [TextureRect]
@onready var hint_info_texture: TextureRect = %HintInfoTexture
## 힌트 설명을 표시하는 [Label]
@onready var hint_info_label: RichTextLabel = %HintInfoLabel
## 힌트 상세 정보 패널
@onready var hint_info_panel: Panel = $HintInfoPanel
## 종료 버튼
@onready var exit_button: Button = $Exit
## 힌트 스크롤 컨테이너
@onready var hint_scroll_container: ScrollContainer = %HintScrollContainer

## VHS 효과 [ColorRect] 참조
@export var VHS: ColorRect # 화면에 까만줄생기는 현상 해결을 위한 참조

## 디버그용 힌트 리소스 목록
@export var debug_hint_list: Array[Resource]

## 힌트 데이터 관리 인스턴스
var hint_info : RouteHintData = RouteHintData.new()

## 노선도 힌트 창이 열려있는지 여부
var is_enable:= false
## 현재 힌트 ID 목록
var hint_list: Array[String] = []

## 초기화 시 패널을 숨기고, 포커스 및 상세 정보 시그널을 연결한 후 컨테이너를 비운다.
func _ready() -> void:
	hide()
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	hint_info_panel.detail_exit.connect(_on_hint_detail_exited)
	clear_container()

func _input(event):
	if event.is_action_pressed("esc") and is_enable and hint_info_panel.visible == false:
		_on_exit_pressed()
		get_viewport().set_input_as_handled()

## 힌트 패널의 활성화 상태를 [param state]로 설정한다.
## 활성화 시 힌트 목록을 구성하여 표시하고, 비활성화 시 숨기고 노선도로 돌아간다.
func set_enable(state: bool):
	clear_container()
	is_enable = state
	if state:
		set_hint_list()
		hint_scroll_container.scroll_vertical = 0
		show()
		VHS.hide()
	else:
		hide()
		route_map.set_grab_focus_first_route()
		VHS.show()

##획득한 힌트들을 추가한다
func set_hint_list():
	hint_list.clear()
	hint_list.append_array(MetaProgression.get_route_hint_array())
	
	if Constants.ROUTE_ALL_UNLOCK:
		for i in debug_hint_list.size():
			hint_list.append((debug_hint_list[i] as RouteHintPage).id)
	
	var hint_list_array : Array[HintSlot]
	for i in hint_list:
		var hint_slot_instance = hint_slot.instantiate() as HintSlot
		hint_list_array.append(hint_slot_instance)
		hint_slot_instance.hint_info = hint_info.get_route_hint(i)
		hint_slot_instance.pressed.connect(_on_hint_slot_pressed.bind(hint_slot_instance))
		hint_slot_container.add_child(hint_slot_instance)
		
	sort_hints()


## 힌트 슬롯 컨테이너의 모든 자식 노드를 제거한다.
func clear_container():
	for i in hint_slot_container.get_children():
		if is_instance_valid(i):
			i.queue_free()
			await i.tree_exited

## 종료 버튼 클릭 시 패널을 비활성화한다.
func _on_exit_pressed() -> void:
	set_enable(false)

## 포커스 변경 시 호출되는 콜백.
func _on_focus_changed(_button: Control):
	if not is_enable:
		return
	
	#hint_info_panel.hide_hint()

## 힌트 슬롯 클릭 시 [param current_hint_slot]의 상세 정보를 표시한다.
func _on_hint_slot_pressed(current_hint_slot: HintSlot):
	if not is_enable:
		return

	hint_info_panel.show_hint(current_hint_slot)

## 힌트 슬롯을 노선 상태 기준으로 정렬하고 포커스를 재설정한다.
func sort_hints():
	var children:= hint_slot_container.get_children()
	
	# 1️⃣ SubPartnerSlot 기준으로 정렬
	children.sort_custom(func(a, b):
		return a.is_route_state < b.is_route_state
	)
	
	# 2️⃣ 정렬된 순서대로 다시 배치
	for i in range(children.size()):
		hint_slot_container.move_child(children[i], i)
	
	var new_hint_list: Array[HintSlot]
	for i in children:
		var new_hint_slot: HintSlot = i as HintSlot
		new_hint_list.append(new_hint_slot)
	
	##해당 정렬을 바탕으로 다시 포커스 지정
	setting_focus(new_hint_list)


##키보드로 이동시 포커스 지정
func setting_focus(hint_list_array: Array[HintSlot]):
	if hint_list_array == []:
		exit_button.grab_focus()
		exit_button.focus_neighbor_top = exit_button.get_path()
		exit_button.focus_neighbor_left = exit_button.get_path()
		exit_button.focus_neighbor_right = exit_button.get_path()
		exit_button.focus_neighbor_bottom = exit_button.get_path()
		return

	hint_list_array[0].grab_focus()
	
	exit_button.focus_neighbor_top = exit_button.get_path()
	exit_button.focus_neighbor_left = exit_button.get_path()
	exit_button.focus_neighbor_right = exit_button.get_path()
	exit_button.focus_neighbor_bottom = hint_list_array[0].get_path()
	for i in hint_list_array.size():
		var current = hint_list_array[i]

		# 포커스 제한: 좌우 막기
		current.focus_neighbor_left = current.get_path()
		current.focus_neighbor_right = exit_button.get_path()

		# 위쪽
		if i > 0:
			current.focus_neighbor_top = hint_list_array[i - 1].get_path()
		else:
			current.focus_neighbor_top = exit_button.get_path()

		# 아래쪽
		if i < hint_list_array.size() - 1:
			current.focus_neighbor_bottom = hint_list_array[i + 1].get_path()
		else:
			current.focus_neighbor_bottom = current.get_path()


## 힌트 상세 정보 패널이 닫혔을 때 종료 버튼에 포커스를 맞춘다.
func _on_hint_detail_exited():
	exit_button.grab_focus()
