## [KR] 액션 프로그레스 바의 진행도에 따라 색상을 변경하는 베이스 스프라이트.
## 진행률이 높아질수록 흰색에서 붉은색으로 전환되어 긴박감을 표현한다.
## [EN] Base sprite that changes color based on action progress bar progression.
## Transitions from white to red as progress increases, expressing urgency.
extends Sprite2D

## [KR] 현재 색조 변조 값.
## [EN] Current hue modulation value.
var current_modulate: float

## [KR] 진행도를 표시하는 텍스처 프로그레스 바 참조.
## [EN] Reference to the texture progress bar displaying progress.
@onready var action_progress_bar: TextureProgressBar = %ActionProgressBar

## [KR] 매 프레임 [member action_progress_bar]의 진행률에 따라 [member self_modulate] 색상을 갱신한다.
## 진행률 [code]0→1[/code] 구간에서 G, B 채널을 [code]1.0→0.56[/code]으로 보간하여 붉은 색조로 전환한다.
## [EN] Updates [member self_modulate] color each frame based on [member action_progress_bar] progress.
## Interpolates G, B channels from [code]1.0→0.56[/code] over the [code]0→1[/code] progress range to shift toward red.
func _process(_delta: float) -> void:
	var value := action_progress_bar.value
	var max_value := action_progress_bar.max_value
	var t := clampf(value / max_value, 0.0, 1.0)

	var green_blue = lerp(1.0, 0.56, t)
	self_modulate = Color(1.0, green_blue, green_blue)
