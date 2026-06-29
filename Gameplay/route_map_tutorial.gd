extends Node
## 노선도(칸칸네비) 튜토리얼 시스템.
## [br]챕터 4에서 칸칸네비를 처음 획득할 때 실행되며, Dialogic 시그널과 연동하여
## 단계별로 UI를 하이라이트하고, 특정 경로만 선택 가능하도록 제한한다.

## 튜토리얼 하이라이트 사각형 노드.
@onready var tutorial_rect: Tutorial_Rect = %TutorialRect
## 현재 튜토리얼이 진행 중인지 여부.
var current_tutorial := false
## tuto_routeset 이후 노선 확정 단축키 허용 여부.
var route_set_input_enabled := false
## tuto_exit 이후 나가기 키 허용 여부.
var exit_input_enabled := false
## Dialogic 스타일 레이어 노드.
var node : CanvasLayer

## 튜토리얼 단계 열거형.
enum {NAVIFULL, ROUTELIST, ROUTESET, ROUTE_EXIT, TUTO_DESTINATION, TUTO_HINT_PANEL}

var tuto_route :Array = [3,4,5] #튜토리얼을 위해 미리 해금된 경로들


## 튜토리얼 초기화. 칸칸네비 이벤트를 이미 읽었으면 튜토리얼을 건너뛴다.
func _ready() -> void:
	tutorial_rect.hide()
	Dialogic.signal_event.connect(_on_dialogic_signal)
	if MetaProgression.has_read_event("chapter4_kankannavi") and not Constants.KANKAN_TUTORIAL_FORCE:
		return
	get_parent().destination_route_add.connect(_on_destination_add)
	get_parent().route_confirm.connect(_on_route_confirm)


## 튜토리얼 시작 조건을 확인하고, 조건 충족 시 Dialogic 타임라인을 실행한다.
## [br]Why: [code]PROCESS_MODE_ALWAYS[/code]로 설정하여 게임 일시정지 중에도 튜토리얼이 동작하도록 한다.
func check_tutorial():
	if (not MetaProgression.has_read_event("chapter4_kankannavi") or Constants.KANKAN_TUTORIAL_FORCE) and not Constants.KANKAN_TUTORIAL_SKIP:
		if Constants.KANKAN_TUTORIAL_FORCE:
			MetaProgression.add_route_hint("storage")
		current_tutorial = true
		tutorial_rect.show()
		node = Dialogic.Styles.load_style('TextBubbleStyle') as CanvasLayer
		node.process_mode = Node.PROCESS_MODE_ALWAYS
		node.layer = 5
		Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS
		node.register_character("res://Gameplay/Dialog/Character/butler.dch", $ButlerMarker )
		node.register_character("res://Gameplay/Dialog/Character/mai.dch", $MaiMarker )
		node.register_character("res://Gameplay/Dialog/Character/reina.dch", $ReinaMarker )
		node = Dialogic.start("chapter4_kankannavi")
		Dialogic.timeline_ended.connect(_timeline_ended)



## Dialogic 시그널 콜백. 튜토리얼 단계별로 UI 하이라이트와 버튼 제어를 수행한다.
func _on_dialogic_signal(arg: String) -> void:
	match arg:
		"tuto_navifull":
			%Exit.disabled = true
			%Hint.disabled = true
			%RouteStart.disabled = true
			%RouteClearButton.disabled = true
			all_button_disabled()
			tutorial_rect.set_tuto_rect(NAVIFULL)
		"tuto_routelist":
			tutorial_rect.set_tuto_rect(ROUTELIST)
		"tuto_routeset":
			tutorial_rect.set_tuto_rect(ROUTESET)
			route_set_input_enabled = true
		"tuto_exit":
			%Exit.disabled = false
			tutorial_rect.set_tuto_rect(ROUTE_EXIT)
			exit_input_enabled = true
		"tuto_destination":
			tutorial_rect.set_tuto_rect(TUTO_DESTINATION)
		"tuto_hint_panel":
			tutorial_rect.set_tuto_rect(TUTO_HINT_PANEL)

		"tuto_naviinput":
			dialogic_input_wait()
		"tuto_highlight_route":
			set_tuto_routes()
		"tuto_confirminput_show":
			dialogic_input_wait()
			set_confirm_button()

## Dialogic를 일시정지하고 텍스트박스를 숨겨 플레이어 입력을 대기한다.
func dialogic_input_wait():
	Dialogic.paused = true
	node.hide()
	if Dialogic.Text.is_textbox_visible():
		Dialogic.Text.hide_textbox()
	for route in %RouteContainer.get_children():
		var slot := route as RouteSlot
		if slot and not slot.disabled:
			slot.grab_focus()
			break

## 플레이어 입력 완료 후 Dialogic를 재개하고 텍스트박스를 다시 표시한다.
func dialogic_input_end():
	if not current_tutorial:
		return
		
	Dialogic.paused = false
	node.show()
	if !Dialogic.Text.is_textbox_visible():
		Dialogic.Text.show_textbox()

## 튜토리얼용 경로만 선택 가능하도록 나머지 경로 버튼을 비활성화한다.
func set_tuto_routes():
	if not current_tutorial:
		return
		
	var route_container = %RouteContainer
	for route in route_container.get_children():
		var route_button = route as RouteSlot
		route_button.disabled = true
		if is_tuto_route(route_button):
			route_button.disabled = false

## 경로 확정 단계에서 확인 버튼만 활성화하고 경로 슬롯은 비활성화한다.
func set_confirm_button():
	if not current_tutorial:
		return

	var route_set_container = %RouteSetContainer
	for route in route_set_container.get_children():
		var route_button = route as RouteSlot
		route_button.disabled = true
	var route_start = %RouteStart
	route_start.disabled = false

## [param route_slot]이 튜토리얼 지정 경로([member tuto_route])에 해당하는지 반환한다.
func is_tuto_route(route_slot: RouteSlot)-> bool:
	if tuto_route.has(route_slot.route_num):
		return true
	return false

## 종착지 추가 시그널 콜백. Dialogic 입력 대기를 종료한다.
func _on_destination_add():
	dialogic_input_end()

## 경로 확정 시그널 콜백. Dialogic 입력 대기를 종료한다.
func _on_route_confirm(_target_text: String):
	dialogic_input_end()

## Dialogic 타임라인 종료 시 시그널 연결을 해제하고 튜토리얼을 완료한다.
func _timeline_ended():
	get_parent().destination_route_add.disconnect(_on_destination_add)
	get_parent().route_confirm.disconnect(_on_route_confirm)
	node.queue_free()
	current_tutorial = false

## 모든 경로 버튼과 출발 버튼을 비활성화한다.
func all_button_disabled():
	var route_container = %RouteContainer
	for route in route_container.get_children():
		var route_button = route as RouteSlot
		if route_button:
			route_button.disabled = true
	var route_start = %RouteStart
	route_start.disabled = true
