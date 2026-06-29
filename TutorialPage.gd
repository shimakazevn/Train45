## 튜토리얼 페이지를 관리하는 컨트롤러.
## 튜토리얼 ID를 받아 [member tuto_page]를 열고, 닫힐 때 읽음 상태를 저장한다.
extends Control
class_name TutorialPage

## 실제 튜토리얼 패널 UI.
@export var tuto_page: TutorialPanel
## 파트너 매니저 참조.
@export var partner_manager: PartnerManager
@export_group("Debug")
## 디버그용 테스트 튜토리얼 리소스.
@export var test_tuto: Tutos

## 튜토리얼 표시용 [CanvasLayer].
@onready var canvas_layer = $CanvasLayer
## 현재 표시 중인 튜토리얼 ID.
var current_tuto_id := ""

## 튜토리얼 종료 후 포커스를 복원할 버튼.
var current_focus_button: Button

## 초기화 — 캔버스 숨김 처리. 디버그 모드일 경우 테스트 튜토리얼을 즉시 호출한다.
func _ready():
	canvas_layer.visible = false
	#next.grab_focus()
	get_tree().paused = false
	
	if Constants.TUTORIAL_PAGE_DEBUG:
		push_error("튜토리얼 디버그 모드 적용중")
		GameEvents.emit_call_tutorial(test_tuto.id)

func _input(_event: InputEvent) -> void:
	pass

## 튜토리얼을 시작한다. [param id]로 튜토리얼을 식별하고,
## 종료 후 [param next_focus_button]에 포커스를 복원한다.
func start_tutorial(id: String, next_focus_button: Button):
	current_tuto_id = id
	
	if next_focus_button:
		current_focus_button = next_focus_button
	tutorial_on(current_tuto_id)

## [param tuto_id]에 해당하는 튜토리얼 패널을 열고 게임을 일시정지한다.
func tutorial_on(tuto_id: StringName):
	if canvas_layer.visible:
		return
	canvas_layer.visible = true
	tuto_page.open_tuto(tuto_id)
	tuto_page.confirm_button.pressed.connect(_on_close_button)
	get_tree().paused = true

## 확인 버튼 콜백 — 튜토리얼을 닫고, 읽음 이벤트를 저장하고, 포커스를 복원한다.
func _on_close_button():
	canvas_layer.visible = false
	tuto_page.confirm_button.pressed.disconnect(_on_close_button)
	get_tree().paused = false
	MetaProgression.read_event_update(current_tuto_id)
	tuto_page.set_close()
	if current_focus_button:
		current_focus_button.grab_focus()
		current_focus_button = null
