## 기지 복귀 입력을 처리하는 컴포넌트.
## [code]return_base[/code] 액션 입력 시 확인 다이얼로그를 표시하고,
## 확인되면 플레이어의 [signal find_faild]를 발생시켜 기지로 복귀시킨다.
extends Label

## 기지 복귀 확인 다이얼로그 UI 참조
@export var confirm_box: ConfirmBox
## 현재 레벨/스테이지 정보를 조회하기 위한 [FloorManager] 참조
@export var floor_manager: FloorManager

## 스테이지 전환 중 여부 — [code]true[/code]이면 복귀 입력을 차단
var stage_changing:= false

func _ready() -> void:
	GameEvents.in_next_stage.connect(_on_in_next_stage)
	GameEvents.stage_change.connect(_on_stage_changed)

## [code]return_base[/code] 액션 입력을 감지하여 기지가 아닌 스테이지에서 확인 다이얼로그를 연다.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("return_base") and _can_return_base():
		if floor_manager.current_level.stage_type != Constants.TYPE_BASE:
			open_confirm_box()

## 기지 복귀 확인 다이얼로그를 표시하고, 확인 시 플레이어의 탐색 실패 시그널을 발생시킨다.
func open_confirm_box():
	confirm_box.customize(
	"RETURN_BASE_CONFIRM",
	"Return",
	"RETURN_BASE_CONFIRM_DESCRIPTION",
	"YES",
	"NO"
	)
	_force_grab_focus()
	
	var is_confirmed = await confirm_box.prompt(true)
	if is_confirmed:
		#return base
		floor_manager.current_level.player.find_faild.emit()
	

## 기지 복귀가 가능한 상태인지 확인한다.
## 에필로그, 다이얼로그 진행 중, 화면 전환 중, 스테이지 전환 중에는 [code]false[/code]를 반환한다.
func _can_return_base()-> bool:
	if GameEvents.is_epilogue_room:
		return false
	if Dialogic.current_timeline:
		return false
	if TransitionScreen.get_is_transition():
		return false
	if stage_changing:
		return false
	if GameEvents.game_state == Constants.STATE_RAPE:
		return false
	return true

## 다음 스테이지 진입 시 [member stage_changing]을 활성화하여 복귀 입력을 차단한다.
func _on_in_next_stage():
	stage_changing = true

## 스테이지 전환 완료 시 [member stage_changing]을 비활성화하여 복귀 입력을 허용한다.
func _on_stage_changed():
	stage_changing = false

## 확인 다이얼로그 표시 후 취소 버튼에 포커스를 강제 설정한다.
## 짧은 딜레이를 두어 UI가 완전히 준비된 후 포커스를 잡는다.
func _force_grab_focus():
	await  get_tree().create_timer(0.4).timeout
	confirm_box.cancel_button.grab_focus()
