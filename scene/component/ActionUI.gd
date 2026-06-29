## [KR] 자유 행위(Free Action) 조작 UI 컴포넌트.
## [br]정지/재생/배속 버튼의 시각적 상태를 [HSceneFreeActionComponent]의 상태와 동기화하고,
## 사정 후 종료 안내 라벨의 표시 여부를 제어한다.
## [EN] Free Action control UI component.
## [br]Syncs stop/play/speed button visual states with [HSceneFreeActionComponent] state,
## and controls the visibility of the post-climax exit guide label.
extends Control


## [KR] 정지 버튼.
## [EN] Stop button.
@onready var stop = %Stop
## [KR] 재생 버튼.
## [EN] Play button.
@onready var play = %Play
## [KR] 배속 버튼.
## [EN] Speed button.
@onready var double = %Double
## [KR] 종료 안내 라벨. 사정 후 대기/종료 상태에서 표시된다.
## [EN] Exit guide label. Displayed in standby/end state after climax.
@onready var exit_label = %ExitLabel
## [KR] 종료 라벨 잠금 플래그. 사정 발생 시 [code]false[/code]로 해제되어 라벨이 표시 가능해진다.
## [EN] Exit label lock flag. Released to [code]false[/code] on climax, allowing the label to be displayed.
var exit_label_lock := true

## [KR] 연결된 [HSceneFreeActionComponent] 참조.
## [EN] Reference to the connected [HSceneFreeActionComponent].
@export var free_action : Node

## [KR] 재생 상태 플래그 (미사용 예비).
## [EN] Play state flag (unused reserve).
var is_play := false

## [KR] 초기화: 종료 라벨을 숨긴다.
## [EN] Initialization: hides the exit label.
func _ready():
	exit_label.visible = false
	pass
	
## [KR] 매 프레임 [member free_action]의 상태를 참조하여 버튼 pressed 상태와 종료 라벨을 갱신한다.
## [EN] Updates button pressed states and exit label each frame by referencing [member free_action] state.
func _process(_delta):
	if free_action.is_increasing:
		if free_action.is_speed_doubled:
			play.button_pressed = true
			double.button_pressed = false
		else:
			play.button_pressed = false
			double.button_pressed = true
	else:
		play.button_pressed = false
		double.button_pressed = false
		
	if free_action.is_paused:
		play.button_pressed = false
		double.button_pressed = false
		stop.button_pressed = true
	else:
		stop.button_pressed = false
		
	exit_on()

## [KR] 종료 라벨 표시 로직. 사정이 발생하면 잠금을 해제하고,
## 대기(1) 또는 종료(4) 상태에서만 라벨을 표시한다.
## [EN] Exit label display logic. Releases lock when climax occurs,
## and shows label only in standby(1) or end(4) state.
func exit_on():
	if free_action.is_cum and exit_label_lock == true:
		exit_label_lock = false
		
	if free_action.scene_progress == 1 or free_action.scene_progress == 4:
		if exit_label_lock == false:
			exit_label.visible = true
	else:
		exit_label.visible = false
