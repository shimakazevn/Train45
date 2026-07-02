extends Button
## 대화 자동 진행(오토 플레이) 버튼.
## 켜면 텍스트가 다 표시된 뒤(음성이 재생 중이면 음성이 끝날 때까지 기다린 뒤)
## 일정 시간 대기했다가 다음 대사로 자동 진행한다.

## 음성 종료 후 다음 대사까지 기다리는 시간(초).
const VOICED_DELAY := 1.0
## 음성이 없는 대사의 기본 대기 시간(초).
const UNVOICED_BASE_DELAY := 0.5
## 음성이 없는 대사에서 글자당 추가로 주는 읽기 시간(초) — CJK(한/일/중)용.
const PER_CHAR_DELAY_CJK := 0.05
## 영문(라틴)용 글자당 지연. 같은 대사라도 영어는 글자 수가 2~3배 많으므로 낮춰 체감 시간을 맞춘다.
const PER_CHAR_DELAY_LATIN := 0.02

@onready var dialog_text_panel: PanelContainer = %DialogTextPanel

## 자동 진행 활성화 여부.
var enabled := false
## 대기 루틴 세대 토큰. 새 대사가 시작되거나 자동 진행을 끄면 증가시켜
## 이전에 대기 중이던 루틴을 무효화한다.
var _token := 0
## 음성이 재생된 이벤트 인덱스. (이 프로젝트는 더빙 매니저가 [voice] 이벤트 없이 음성을 재생하므로
## is_voiced()로는 못 잡는다. 더빙·실제 voice 이벤트 모두 발생시키는 voiceline_started로 판정한다.)
var _voiced_idx := -1


func _ready() -> void:
	# 형제 버튼들처럼 처음엔 숨겨두고, 텍스트박스가 보일 때 같이 나타나게 한다.
	self.hide()
	toggled.connect(_on_toggled)
	dialog_text_panel.visibility_changed.connect(_on_textbox_visible_changed.bind(dialog_text_panel))
	Dialogic.Text.text_finished.connect(_on_text_finished)
	# 스킵이 켜지면 오토 플레이를 끈다.
	Dialogic.Inputs.auto_skip.toggled.connect(_on_auto_skip_toggled)
	# 음성이 실제로 재생됐는지 추적한다. (음성 대사/무음성 대사 대기 시간 구분용)
	if Dialogic.has_subsystem("Voice"):
		Dialogic.Voice.voiceline_started.connect(_on_voiceline_started)
	# 타임라인이 바뀌면 음성 인덱스 기록을 초기화한다. (인덱스 재사용으로 인한 오판 방지)
	Dialogic.timeline_started.connect(_on_timeline_boundary)
	Dialogic.timeline_ended.connect(_on_timeline_boundary)
	# 세션 동안 유지한 오토 플레이 설정을 복원한다. (상태만 맞추고 즉시 진행 루틴은 띄우지 않음)
	enabled = GameEvents.autoplay_enabled
	set_pressed_no_signal(GameEvents.autoplay_enabled)


## 음성이 재생되기 시작하면 현재 이벤트 인덱스를 기록해 둔다.
func _on_voiceline_started(_info: Dictionary) -> void:
	_voiced_idx = Dialogic.current_event_idx


## 타임라인 시작/종료 시 음성 인덱스 기록을 초기화한다.
func _on_timeline_boundary() -> void:
	_voiced_idx = -1


func _input(event: InputEvent) -> void:
	# 키보드 A / 패드 X 로 오토 플레이를 토글한다.
	if event.is_action_pressed("dialog_auto") and _can_toggle_by_input():
		button_pressed = not button_pressed
		get_viewport().set_input_as_handled()


## 입력(키보드 A·패드 X)으로 오토 토글을 바꿀 수 있는 상태인지 확인한다.
func _can_toggle_by_input() -> bool:
	# 대화 중이 아니거나 텍스트박스가 숨김 상태면 토글하지 않는다.
	if not Dialogic.current_timeline:
		return false
	if not Dialogic.Text.is_textbox_visible():
		return false
	# 일시정지(프리액션·옵션 메뉴·백로그 등) 중에는 토글하지 않는다.
	# 프리액션은 대화를 paused로 두고 행위 대사로 텍스트박스만 다시 띄우므로 여기서 막는다.
	if Dialogic.paused:
		return false
	# H액션·인벤토리 등 다른 창이 떠 있으면 토글하지 않는다.
	if GameEvents.get_window_state_array().size() > 0:
		return false
	return true


func _on_toggled(toggled_on: bool) -> void:
	enabled = toggled_on
	GameEvents.autoplay_enabled = toggled_on   # 세션 동안 설정 유지
	if enabled:
		# 이미 텍스트가 다 표시되어 입력을 기다리는 중이면 즉시 진행 루틴을 시작한다.
		if Dialogic.current_state == Dialogic.States.IDLE:
			_start_advance_routine()
	else:
		# 진행 중이던 대기 루틴을 취소한다.
		_token += 1


## 스킵(자동 스킵)이 켜지면 오토 플레이를 끈다. (두 자동 진행이 충돌하지 않도록)
func _on_auto_skip_toggled(skip_enabled: bool) -> void:
	if skip_enabled and button_pressed:
		# button_pressed 변경이 toggled 시그널을 발생시켜 _on_toggled에서 루틴을 취소한다.
		button_pressed = false


## 한 대사의 텍스트 표시가 끝나면 호출된다.
func _on_text_finished(_info: Dictionary) -> void:
	if enabled:
		_start_advance_routine()


## 음성 종료까지 기다린 뒤, 추가 대기 후 다음 대사로 진행하는 루틴.
func _start_advance_routine() -> void:
	_token += 1
	var my_token := _token
	# 이 루틴이 담당하는 대사(이벤트) 인덱스. 대기 중 수동(스페이스)으로 이미 넘어가면 인덱스가 바뀐다.
	var start_idx := Dialogic.current_event_idx

	# 이 대사에 음성이 붙어 있는지 판정한다. (대기 시간 계산 방식이 달라진다.)
	# 현재 대사 이벤트에 대해 음성이 재생됐으면 음성 대사로 본다.
	var voiced := _voiced_idx == Dialogic.current_event_idx

	# 음성이 끝날 때까지 기다린다. (중간에 취소되면 빠져나간다.)
	# 백로그·옵션 메뉴 등으로 일시정지된 동안에는 음성이 멈춰 있어도 끝난 것으로 보지 않는다.
	while _is_voice_pending():
		await get_tree().process_frame
		if not _is_routine_valid(my_token):
			return

	# 대기 시간: 음성 대사는 고정, 무음성 대사는 글자 수에 비례한 읽기 시간을 준다.
	# (일시정지 중에는 시간을 세지 않는다.)
	var remaining := VOICED_DELAY if voiced else _calc_unvoiced_delay()
	while remaining > 0.0:
		await get_tree().process_frame
		if not _is_routine_valid(my_token):
			return
		if not Dialogic.paused:
			remaining -= get_process_delta_time()

	# 넘길 수 있는 상태가 될 때까지 기다린다.
	# 옵션 메뉴·화면 전환·텍스트박스 숨김 등으로 잠시 막힌 경우, 풀리면 이어서 진행한다.
	while not _can_advance():
		if not _is_routine_valid(my_token):
			return
		# 선택지에서는 자동으로 넘기지 않는다. (플레이어가 직접 선택)
		if Dialogic.current_state == Dialogic.States.AWAITING_CHOICE:
			return
		# 자동 스킵이 켜져 있으면 그쪽에 진행을 맡긴다.
		if Dialogic.Inputs.auto_skip.enabled:
			return
		await get_tree().process_frame

	# 수동 입력(스페이스)으로 이미 다음 대사로 넘어갔다면, 이 루틴은 옛 대사용이므로 중복 진행하지 않는다.
	if Dialogic.current_event_idx != start_idx:
		return

	Dialogic.Inputs.auto_advance.autoadvance.emit()


## 음성이 없는 대사의 대기 시간을 글자 수에 비례해 계산한다. (읽을 시간 확보)
func _calc_unvoiced_delay() -> float:
	var parsed: String = Dialogic.current_state_info.get("text_parsed", "")
	# 영문은 같은 대사라도 글자 수가 많으므로 글자당 지연을 낮춰 언어별 체감 시간을 맞춘다.
	var per_char := PER_CHAR_DELAY_LATIN if TranslationServer.get_locale() == "en" else PER_CHAR_DELAY_CJK
	return UNVOICED_BASE_DELAY + per_char * parsed.length()


## 음성이 아직 끝나지 않았는지(재생 중이거나 일시정지로 멈춰 있는지) 확인한다.
func _is_voice_pending() -> bool:
	if not Dialogic.has_subsystem("Voice"):
		return false
	# 일시정지(백로그·옵션 메뉴) 중에는 음성이 멈춰 있어도 아직 끝난 게 아니다.
	if Dialogic.paused:
		return true
	return Dialogic.Voice.is_running()


## 대기 루틴이 아직 유효한지 확인한다. (자동 진행이 켜져 있고, 더 최신 루틴으로 교체되지 않았을 때)
func _is_routine_valid(my_token: int) -> bool:
	return enabled and _token == my_token


## 지금 다음 대사로 자동 진행해도 되는 상태인지 점검한다.
func _can_advance() -> bool:
	# 입력 대기(IDLE) 상태가 아니면(선택지·애니메이션 등) 넘기지 않는다.
	if Dialogic.current_state != Dialogic.States.IDLE:
		return false
	# 옵션 메뉴 등으로 대화가 일시정지된 동안에는 넘기지 않는다.
	if Dialogic.paused:
		return false
	# 텍스트박스가 숨김(HIDE) 상태면 보이지 않는 대사를 넘기지 않는다.
	if not Dialogic.Text.is_textbox_visible():
		return false
	# 화면 전환(씬 이동) 중에는 넘기지 않는다.
	if TransitionScreen.get_is_transition():
		return false
	# H액션·인벤토리 등 다른 창이 떠 있으면 넘기지 않는다.
	if GameEvents.get_window_state_array().size() > 0:
		return false
	# 자동 스킵이 켜져 있으면 그쪽에 진행을 맡긴다.
	if Dialogic.Inputs.auto_skip.enabled:
		return false
	return true


func _on_textbox_visible_changed(target: PanelContainer) -> void:
	self.visible = target.visible
