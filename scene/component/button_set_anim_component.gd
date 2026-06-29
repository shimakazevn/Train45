## [KR] 버튼 토글 시 눌림/해제 스케일 애니메이션을 적용하는 컴포넌트.
## [member is_owner]로 지정한 [TextureButton]에 반응형 스케일 트윈을 제공한다.
## [EN] Component applying press/release scale animation on button toggle.
## Provides responsive scale tweens to the [TextureButton] specified by [member is_owner].
extends Node

## [KR] 애니메이션을 적용할 대상 [TextureButton].
## [EN] Target [TextureButton] to apply animation to.
@export var is_owner: TextureButton
## [KR] 현재 실행 중인 스케일 트윈. 중복 애니메이션 방지를 위해 매번 재생성한다.
## [EN] Currently running scale tween. Recreated each time to prevent duplicate animations.
var tween: Tween
## [KR] 대상 버튼의 초기 스케일. 애니메이션 복귀 기준값으로 사용된다.
## [EN] Initial scale of the target button. Used as the baseline for animation restoration.
var base_scale: Vector2

## [KR] 노드 준비 시 초기 스케일을 저장하고 토글 시그널에 연결한다.
## [EN] Saves initial scale and connects to toggle signal on node ready.
func _ready() -> void:
	base_scale = is_owner.scale
	is_owner.toggled.connect(_on_toggled)

## [KR] 버튼 토글 시그널 콜백. [method update_scale]에 상태를 전달한다.
## [param state]: 버튼이 눌린 상태이면 [code]true[/code]
## [EN] Button toggle signal callback. Passes state to [method update_scale].
## [param state]: [code]true[/code] if button is pressed
func _on_toggled(state: bool):
	update_scale(state)

## [KR] 버튼의 눌림 상태에 따라 스케일 트윈 애니메이션을 실행한다.
## 눌림 시 [member base_scale]의 90%로 축소, 해제 시 원래 크기로 복원한다.
## [param is_pressed]: 버튼이 눌린 상태이면 [code]true[/code]
## [EN] Executes scale tween animation based on button press state.
## Shrinks to 90% of [member base_scale] when pressed, restores to original when released.
## [param is_pressed]: [code]true[/code] if button is pressed
func update_scale(is_pressed: bool):
	if tween:
		tween.kill()
	tween = create_tween().set_parallel()
	var target_scale: Vector2
	if is_pressed:
		target_scale = base_scale * 0.9
	else:
		target_scale = base_scale
		
	tween.tween_property(is_owner, "scale", target_scale, 0.2)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
