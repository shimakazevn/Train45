## [KR] 개별 컷씬 이미지의 등장/퇴장 애니메이션을 담당하는 노드.
##
## [KR] [TextureRect]를 상속하며, 에디터에서 [member in_anim]과 [member out_anim]을 설정하여
## [KR] 방향별 슬라이드+페이드 애니메이션을 적용한다.
## [KR] [code]CutSceneManager[/code]에서 [method cutscene_in] / [method cutscene_out]을 호출한다.
## [EN] Node responsible for entrance/exit animation of individual cutscene images.
##
## [EN] Inherits [TextureRect]; set [member in_anim] and [member out_anim] in the editor to apply
## [EN] direction-specific slide+fade animations.
## [EN] [code]CutSceneManager[/code] calls [method cutscene_in] / [method cutscene_out].
extends TextureRect
class_name CutSceneAsset

## [KR] 현재 실행 중인 트윈 애니메이션 참조.
## [EN] Reference to the currently running tween animation.
var tween: Tween
## [KR] [method _ready]에서 저장한 초기 위치. 애니메이션의 기준점으로 사용된다.
## [EN] Initial position saved in [method _ready]. Used as the reference point for animations.
var base_position: Vector2

## [KR] 등장 애니메이션 방향 유형.
## [EN] Entrance animation direction type.
enum InAnimType {NONE, DOWNUP, UPDOWN, LEFTRIGHT, RIGHTLEFT}
## [KR] 등장 시 슬라이드 방향. NONE이면 페이드만 적용된다.
## [EN] Slide direction on entrance. NONE applies fade only.
@export var in_anim: InAnimType
## [KR] 퇴장 애니메이션 방향 유형.
## [EN] Exit animation direction type.
enum OutAnimType {NONE, DOWNUP, UPDOWN, LEFTRIGHT, RIGHTLEFT}
## [KR] 퇴장 시 슬라이드 방향. NONE이면 페이드만 적용된다.
## [EN] Slide direction on exit. NONE applies fade only.
@export var out_anim: OutAnimType
## [KR] 페이드 애니메이션 지속 시간(초).
## [EN] Fade animation duration in seconds.
@export var alpha_time: float = 0.5
## [KR] 이동 애니메이션 지속 시간(초).
## [EN] Move animation duration in seconds.
@export var move_time: float = 0.5

func _ready() -> void:
	self.hide()
	base_position = position

## [KR] 컷씬을 페이드인 + 슬라이드 애니메이션으로 표시한다.
##
## [KR] 투명 상태에서 시작하여 [member alpha_time] 동안 불투명으로 전환하고,
## [KR] [member in_anim]에 따라 100px 오프셋에서 [member base_position]으로 슬라이드한다.
## [EN] Displays the cutscene with fade-in + slide animation.
##
## [EN] Starts from transparent state, transitions to opaque over [member alpha_time],
## [EN] and slides from 100px offset to [member base_position] according to [member in_anim].
func cutscene_in():
	self.self_modulate = Color.TRANSPARENT
	self.show()
	tween = create_tween()
	tween.tween_property(self, "self_modulate", Color.WHITE, alpha_time).from(Color.TRANSPARENT)
	tween.parallel()
	match in_anim:
		InAnimType.NONE:
			pass
		InAnimType.DOWNUP:
			tween.tween_property(self, "position", base_position, move_time).from(base_position+Vector2(0, 100.0))
		InAnimType.UPDOWN:
			tween.tween_property(self, "position", base_position, move_time).from(base_position+Vector2(0, -100.0))
		InAnimType.LEFTRIGHT:
			tween.tween_property(self, "position", base_position, move_time).from(base_position+Vector2(-100.0, 0))
		InAnimType.RIGHTLEFT:
			tween.tween_property(self, "position", base_position, move_time).from(base_position+Vector2(100.0, 0))

## [KR] 컷씬을 페이드아웃 + 슬라이드 애니메이션으로 숨긴다.
##
## [KR] [member alpha_time] 동안 투명으로 전환하고,
## [KR] [member out_anim]에 따라 [member base_position]에서 100px 오프셋으로 슬라이드한다.
## [KR] 애니메이션 완료 후 [method CanvasItem.hide]를 콜백으로 호출하여 노드를 숨긴다.
## [EN] Hides the cutscene with fade-out + slide animation.
##
## [EN] Transitions to transparent over [member alpha_time],
## [EN] and slides from [member base_position] to 100px offset according to [member out_anim].
## [EN] Calls [method CanvasItem.hide] as callback when animation completes to hide the node.
func cutscene_out():
	tween = create_tween()
	tween.tween_property(self, "self_modulate", Color.TRANSPARENT, alpha_time)
	match out_anim:
		OutAnimType.NONE:
			pass
		OutAnimType.DOWNUP:
			tween.parallel()
			tween.tween_property(self, "position", base_position+Vector2(0, -100.0), move_time).from(base_position)
		OutAnimType.UPDOWN:
			tween.parallel()
			tween.tween_property(self, "position", base_position+Vector2(0, 100.0), move_time).from(base_position)
		OutAnimType.LEFTRIGHT:
			tween.parallel()
			tween.tween_property(self, "position", base_position+Vector2(100.0, 0), move_time).from(base_position)
		OutAnimType.RIGHTLEFT:
			tween.parallel()
			tween.tween_property(self, "position", base_position+Vector2(-100.0, 0), move_time).from(base_position)
	tween.tween_callback(self.hide)
