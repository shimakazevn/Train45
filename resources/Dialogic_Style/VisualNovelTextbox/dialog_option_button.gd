extends Button
## 대화 중 옵션 메뉴를 여는 버튼.
## [br]dialog_option 액션(키보드 ESC·게임패드 START) 또는 클릭 시 옵션 메뉴를 열고, 대화 진행을 정지한다.
## 대화 중에는 자막/음성 불일치를 막기 위해 언어 변경을 비활성화한 상태로 연다.

## 옵션 메뉴 씬 경로.
const OPTION_MENU_SCENE := "res://Gameplay/options_menu.tscn"

@onready var dialog_text_panel: PanelContainer = %DialogTextPanel

## 현재 열려 있는 옵션 메뉴 인스턴스. 중복 오픈 방지용.
var _menu_instance: Node = null
## 옵션 메뉴를 열기 직전 포커스를 갖고 있던 노드. (선택지 등 포커스 복원용)
var _prev_focus: Control = null
## 옵션 메뉴를 열기 직전 Dialogic.paused 값. (닫을 때 false 강제 대신 원래 값으로 복원)
var _prev_paused: bool = false

func _ready() -> void:
	# 형제 버튼들처럼 처음엔 숨겨두고, 텍스트박스가 보일 때 같이 나타나게 한다.
	self.hide()
	pressed.connect(_open_option_menu)
	dialog_text_panel.visibility_changed.connect(_on_textbox_visible_changed.bind(dialog_text_panel))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_option") and _can_open():
		_open_option_menu()
		get_viewport().set_input_as_handled()

## 옵션 메뉴를 열 수 있는 상태인지 확인한다.
## [br]이미 열려 있거나, 대화 중이 아니거나, 다른 창(H액션·인벤토리 등)이 열려 있으면 불가.
func _can_open() -> bool:
	if is_instance_valid(_menu_instance):
		return false
	if not Dialogic.current_timeline:
		return false
	if GameEvents.get_window_state_array().size() > 0:
		return false
	# 화면 전환 중 / 텍스트박스 애니메이션 중에는 열지 않는다. (dialog_hide_button과 동일한 가드)
	if TransitionScreen.get_is_transition():
		return false
	if Dialogic.Animations.is_animating():
		return false
	# 스킵(자동 진행) 도중에는 열지 않는다.
	if Dialogic.Inputs.auto_skip.enabled:
		return false
	# 텍스트박스가 숨김(HIDE) 상태일 때는 열지 않는다.
	if not Dialogic.Text.is_textbox_visible():
		return false
	# 선택지 등장 애니메이션 중(대기 상태이나 아직 선택지에 포커스가 안 잡힘)에는 열지 않는다.
	# 이때 열면 복원할 포커스가 없어, 옵션을 닫은 뒤 선택지 포커스가 사라진다.
	if Dialogic.current_state == Dialogic.States.AWAITING_CHOICE \
			and get_viewport().gui_get_focus_owner() == null:
		return false
	return true

func _open_option_menu() -> void:
	if not _can_open():
		return
	# 선택지 등 현재 포커스를 기억해 두었다가 닫을 때 복원한다.
	_prev_focus = get_viewport().gui_get_focus_owner()
	var menu = (load(OPTION_MENU_SCENE) as PackedScene).instantiate()
	# 대화 중에는 언어 변경을 막는다.
	menu.language_locked = true
	_menu_instance = menu
	# 대화 진행/입력 정지 (Dialogic.paused면 advance 입력도 차단됨)
	# 다른 시스템(프리액션 등)이 이미 걸어둔 일시정지를 깨지 않도록 기존 값을 보관해 둔다.
	_prev_paused = Dialogic.paused
	Dialogic.paused = true
	get_tree().current_scene.add_child(menu)
	menu.tree_exited.connect(_on_menu_closed)

func _on_menu_closed() -> void:
	_menu_instance = null
	# false로 강제하지 않고 열기 전 값으로 복원해, 다른 시스템의 일시정지를 깨지 않는다.
	Dialogic.paused = _prev_paused
	# 열기 전 포커스(선택지 버튼 등)를 복원한다. 메뉴 완전 제거 후 적용되도록 지연 호출.
	if is_instance_valid(_prev_focus) and _prev_focus.is_visible_in_tree():
		_prev_focus.grab_focus.call_deferred()
	_prev_focus = null

func _on_textbox_visible_changed(target: PanelContainer):
	self.visible = target.visible
