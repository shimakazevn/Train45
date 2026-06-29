extends Button

@onready var dialog_text_panel: PanelContainer = %DialogTextPanel


func _ready() -> void:
	TransitionScreen.on_transition_start.connect(_on_transition_start)
	TransitionScreen.on_transition_all_end.connect(_on_transition_all_end)
	self.hide()
	dialog_text_panel.visibility_changed.connect(_on_textbox_visible_changed.bind(dialog_text_panel))
	#_skip_init()

func _process(_delta: float) -> void:
	if Dialogic.Inputs.auto_skip.enabled:
		self.button_pressed = true
	else:
		self.button_pressed = false

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Dialogic.Inputs.auto_skip.enabled = true
		_choice_auto_select()
	else:
		Dialogic.Inputs.auto_skip.enabled = false

func _on_textbox_visible_changed(target: PanelContainer):
	self.visible = target.visible

func _skip_init():
	self.button_pressed = false
	Dialogic.Inputs.auto_skip.enabled = false

func _choice_auto_select():
	# [KR] 실제로 선택지를 대기 중일 때만 자동 선택한다.
	# 타임라인 종료 직후 등 선택지가 없는 상태에서 호출하면 current_event_idx가 -1이고
	# current_timeline_events가 비어 있어, get_current_choice_indexes()가 빈 배열에 [-1] 접근으로 크래시한다.
	if Dialogic.current_state != Dialogic.States.AWAITING_CHOICE:
		return
	var info = DialogicUtil.autoload().Choices.get_current_question_info()
	for choice in info["choices"].size():
		if info["choices"][choice]["disabled"] == false:
			DialogicUtil.autoload().Choices._on_choice_selected(info["choices"][choice])
			break

func _on_transition_start():
	pass

func _on_transition_all_end():
	if self.button_pressed:
		Dialogic.Inputs.auto_skip.enabled = true
