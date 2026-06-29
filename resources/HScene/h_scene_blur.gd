## [KR] H씬 가장자리 블러 오버레이.
## [br]자유 행위(Free Action) H씬이 활성화된 동안에만 표시되며,
## 행위가 종료되면 숨겨진다. HScene의 자식으로 인스턴스되어 부모 체인에서
## [HSceneFreeActionComponent]를 찾아 상태 신호를 구독한다.
## [br]free action 중 단축키(shotcut_inventory = Q / 패드 버튼 9)로 블러 강도를 0%/50%/100% 단계로 순환한다.
extends CanvasLayer

## [KR] 블러 강도 단계(가장자리 번짐 정도의 비율). 0.0이면 끄기.
const BLUR_LEVELS := [0.0, 0.5, 1.0]
## [KR] 강도 순환 입력 액션. free action 중에만 사용된다.
## [br]Q/패드9의 인벤토리는 free action 중 H_ACTION 상태로 차단되고, 패드9를 OMT(패드10)와도 공유하지 않아 충돌이 없다.
const BLUR_CYCLE_ACTION := "shotcut_inventory"

## [KR] 100% 강도일 때의 셰이더 lod 값. 강도 = BLUR_LEVELS 비율 × 이 값.
## [br]기본 1.1은 기존 모습과 동일. 100%를 더 강하게 하려면 값을 올린다.
@export var blur_lod_max := 1.3

## [KR] 현재 강도 단계 인덱스. static이라 씬이 재생성돼도 세션 동안 유지된다. 기본 100%.
static var blur_level_index := 1

## [KR] 블러를 그리는 가장자리 마스크 TextureRect.
@onready var blur_rect: TextureRect = $BlurRect

## [KR] free action 활성 여부. 활성 상태에서만 강도 키가 동작한다.
var _active := false

func _ready() -> void:
	blur_rect.hide() # [KR] 기본은 숨김. free action 활성화 시에만 표시
	var fac := _find_free_action_component()
	if fac:
		fac.anim_info_changed.connect(_on_anim_info_changed)
		fac.free_action_end.connect(_on_free_action_end)

func _process(_delta: float) -> void:
	# [KR] free action 중에만 강도 순환 (100% → 50% → 0%(끄기) → 100% ...)
	if _active and Input.is_action_just_pressed(BLUR_CYCLE_ACTION):
		blur_level_index = (blur_level_index - 1 + BLUR_LEVELS.size()) % BLUR_LEVELS.size()
		_apply_blur_level()

## [KR] 부모 체인(HSceneBlur → HScene → npc)에서 FreeActionComponent를 찾는다.
func _find_free_action_component() -> HSceneFreeActionComponent:
	var npc_node := get_parent().get_parent()
	if npc_node and npc_node.has_node("FreeActionComponent"):
		return npc_node.get_node("FreeActionComponent") as HSceneFreeActionComponent
	return null

## [KR] free action H씬이 활성화되면 현재 강도 단계로 블러를 적용한다.
func _on_anim_info_changed(_current_npc: int, _current_anim: AnimationPlayer, _scene_name: String) -> void:
	_active = true
	_apply_blur_level()

## [KR] free action 종료 시 블러를 숨긴다.
func _on_free_action_end() -> void:
	_active = false
	blur_rect.hide()

## [KR] 현재 강도 단계를 셰이더에 반영한다. 0%이거나 비활성이면 숨긴다.
func _apply_blur_level() -> void:
	var frac: float = BLUR_LEVELS[blur_level_index]
	if not _active or frac <= 0.0:
		blur_rect.hide()
		return
	blur_rect.show()
	var mat := blur_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("lod", frac * blur_lod_max)
