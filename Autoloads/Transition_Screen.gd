## [KR] 화면 전환(페이드 인/아웃) 애니메이션을 담당하는 오토로드 싱글톤.
##
## [KR] 검정 페이드와 흰색 페이드 두 가지 전환을 제공한다.
## [KR] 전환 중에는 ESC 입력을 흡수하여 의도치 않은 메뉴 열림을 방지한다.
## [KR] Dialogic 자동 스킵 모드가 활성화되면 애니메이션 속도를 3배로 올린다.
## [EN] Autoload singleton that handles screen transition (fade in/out) animations.
##
## [EN] Provides two transition types: black fade and white fade.
## [EN] During transitions, absorbs ESC input to prevent unintended menu opening.
## [EN] When Dialogic auto-skip mode is enabled, speeds up animations by 3x.
extends CanvasLayer

## [KR] 전환 애니메이션 시작 시 발행되는 시그널.
## [EN] Signal emitted when transition animation starts.
signal on_transition_start
## [KR] 인(In) 애니메이션 완료 시 발행되는 시그널. 씬 교체 타이밍에 사용된다.
## [EN] Signal emitted when In animation completes. Used for scene swap timing.
signal on_transition_finishied
## [KR] 아웃(Out) 애니메이션까지 모두 완료 시 발행되는 시그널.
## [EN] Signal emitted when Out animation fully completes.
signal on_transition_all_end

## [KR] 화면을 덮는 [ColorRect]. 페이드 애니메이션의 대상이다.
## [EN] [ColorRect] that covers the screen. Target of fade animations.
@export var color_rect : ColorRect
## [KR] 페이드 애니메이션을 재생하는 [AnimationPlayer].
## [EN] [AnimationPlayer] that plays fade animations.
@export var animation_player : AnimationPlayer

## [KR] 검정 페이드인 애니메이션 이름.
## [EN] Black fade-in animation name.
const BLACK_IN := "fade_in"
## [KR] 검정 페이드아웃 애니메이션 이름.
## [EN] Black fade-out animation name.
const BLACK_OUT := "fade_out"
## [KR] 흰색 페이드인 애니메이션 이름.
## [EN] White fade-in animation name.
const WHITE_IN := "fade_in_white"
## [KR] 흰색 페이드아웃 애니메이션 이름.
## [EN] White fade-out animation name.
const WHITE_OUT := "fade_out_white"

## [KR] 현재 실행할 인(In) 애니메이션 이름.
## [EN] Current In animation name to play.
var current_in := BLACK_IN
## [KR] 현재 실행할 아웃(Out) 애니메이션 이름.
## [EN] Current Out animation name to play.
var current_out := BLACK_OUT
## [KR] 화면 전환 진행 중 여부. true이면 ESC 입력을 흡수한다.
## [EN] Whether a screen transition is in progress. If true, absorbs ESC input.
var is_transition:= false

func _ready():
	color_rect.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)
	is_transition = false

## [KR] Dialogic 자동 스킵 모드일 때 전환 속도를 3배로 올려 대기 시간을 줄인다.
## [EN] When Dialogic auto-skip mode is on, triples transition speed to reduce wait time.
func _process(_delta: float) -> void:
	if Dialogic.Inputs.auto_skip.enabled:
		animation_player.speed_scale = 3.0
	else:
		animation_player.speed_scale = 1.0

## [KR] 검정 페이드 전환을 실행한다.
## [EN] Runs black fade transition.
func transition():
	set_transition(BLACK_IN, BLACK_OUT)

## [KR] 흰색 페이드 전환을 실행한다.
## [EN] Runs white fade transition.
func transition_white():
	set_transition(WHITE_IN, WHITE_OUT)


## [KR] 애니메이션 완료 콜백. 인 애니메이션이 끝나면 아웃 애니메이션을 이어서 재생한다.
## [EN] Animation finished callback. When In animation ends, plays Out animation next.
func _on_animation_finished(anim_name):
	if anim_name == current_in:
		on_transition_finishied.emit()
		animation_player.play(current_out)
	elif anim_name == current_out:
		color_rect.visible = false
		on_transition_all_end.emit()
		# [KR] 전환 끝나면 ESC 입력 다시 허용 / [EN] Re-allow ESC input when transition ends
		is_transition = false

## [KR] Dialogic 대화 중 화면 전환을 실행한다.
##
## [KR] 전환 시작 시 [code]Dialogic.paused[/code]를 true로 설정하여 대화를 일시정지하고,
## [KR] 인 애니메이션 완료 후 대화를 재개한다.
## [KR] 기존 전환이 진행 중이어도 강제로 실행한다(대화 흐름 유지를 위해).
## [EN] Runs screen transition during Dialogic dialogue.
##
## [EN] Sets [code]Dialogic.paused[/code] to true at transition start to pause dialogue,
## [EN] then resumes dialogue after In animation completes.
## [EN] Forces execution even if a transition is already running (to maintain dialogue flow).
func dialog_transition():
	set_transition(BLACK_IN, BLACK_OUT, true)
	Dialogic.paused = true
	await TransitionScreen.on_transition_finishied
	Dialogic.paused = false

## [KR] 전환 애니메이션을 설정하고 실행한다.
##
## [KR] [param in_anim]은 인(In) 애니메이션 이름, [param out_anim]은 아웃(Out) 애니메이션 이름이다.
## [KR] [param dialogue]가 true이면 이미 재생 중이어도 강제 실행한다.
## [KR] 이미 재생 중이고 [param dialogue]가 false이면 [code]push_warning[/code]을 출력하고 무시한다.
## [EN] Configures and runs transition animation.
##
## [EN] [param in_anim] is the In animation name, [param out_anim] is the Out animation name.
## [EN] If [param dialogue] is true, forces execution even when already playing.
## [EN] If already playing and [param dialogue] is false, outputs [code]push_warning[/code] and ignores.
func set_transition(in_anim: String, out_anim: String, dialogue: bool = false):
	if animation_player.is_playing() and not dialogue:
		# fade_in 중에는 씬 교체 타이밍이므로 중단 불가
		if animation_player.current_animation == current_in:
			push_warning("이미 화면전환이 실행중입니다 (fade_in 중)")
			return
		# fade_out 중이면 인터럽트 허용 — 시각적으로만 영향, 로직상 안전
		
	current_in = in_anim
	current_out = out_anim
	Engine.time_scale = 1.0
	color_rect.visible = true
	animation_player.play(current_in) 
	on_transition_start.emit()
	
	is_transition = true

## [KR] 전환 중 ESC 입력을 흡수하여 메뉴가 열리지 않도록 방지한다.
## [EN] Absorbs ESC input during transition to prevent menu from opening.
func _input(event):
	if not animation_player.is_playing():
		return
	# [KR] ui_cancel(ESC) 입력을 전환 중일 때만 흡수 / [EN] Absorb ui_cancel(ESC) input only during transition
	if event.is_action_pressed("ui_cancel"):
		print("ESC input not allowed during screen transition")
		get_viewport().set_input_as_handled()
	# [KR] fade-out 중 dialogic 입력 차단 — 전환 완료 전에 대사가 스킵되는 버그 방어
	elif event.is_action_pressed("dialogic_default_action"):
		get_viewport().set_input_as_handled()

## [KR] 현재 화면 전환 진행 중인지 여부를 반환한다.
## [EN] Returns whether a screen transition is currently in progress.
func get_is_transition()->bool:
	if is_transition:
		return true
	else:
		return false
