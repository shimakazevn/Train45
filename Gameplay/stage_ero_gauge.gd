## 스테이지 내 에로 게이지 UI를 표시하는 [TextureProgressBar].
## [PartnerManager]의 게이지 변화를 트윈 애니메이션으로 반영하며,
## 일정 수치 이상이면 하트 파티클 이펙트를 활성화한다.
extends TextureProgressBar

## 파트너 데이터를 관리하는 [PartnerManager] 참조.
@export var partner_manager: PartnerManager

## 하트 이펙트가 발생하기 시작하는 게이지 퍼센트 임계값.
const EFFECT_EMITTING_GAUGE_PERCENT: int = 70

## 현재 활성화된 [Tween] 인스턴스.
var tween : Tween
## 게이지가 임계값 이상일 때 표시되는 하트 파티클 이펙트.
@onready var love_effect: CPUParticles2D = $LoveEffect

## 노드 준비 시 게이지 초기값과 최대값을 설정하고, [PartnerManager] 시그널을 연결한다.
func _ready() -> void:
	self.value = 0
	self.max_value = Constants.PARTNER_MAX_ERO_GAUGE
	partner_manager.ero_gage_update.connect(_on_update_ui)
	partner_manager.partner_change.connect(_on_partner_change)
	
	_on_update_ui(partner_manager.current_partner, partner_manager.partner[partner_manager.current_partner].ero_gage)


## 에로 게이지 UI를 갱신한다. 현재 파트너가 아니면 무시한다.
## 표시 중이면 트윈 애니메이션으로 부드럽게 변경하고,
## [param gage]가 [const EFFECT_EMITTING_GAUGE_PERCENT] 초과 시 하트 이펙트를 활성화한다.
func _on_update_ui(_npc_type:PartnerManager.NpcType, gage: int):
	if _npc_type != partner_manager.get_current_partner().npc_name:
		return
	
	if visible == true:
		tween = create_tween()
		tween.tween_property(self, "value", gage, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		love_effect.emitting = false
		await tween.finished
		if gage > EFFECT_EMITTING_GAUGE_PERCENT: # 하트이펙트 나오기 시작하는 계수
			love_effect.emitting = true
			love_effect.global_position.x = get_progress_end_point(self, gage)
		else:
			love_effect.emitting = false
	else:
		self.value = gage
		love_effect.emitting = false
	

## 파트너 변경 시 새 파트너의 에로 게이지로 UI를 갱신한다.
func _on_partner_change(npc_type: int):
	_on_update_ui(npc_type, partner_manager.get_current_partner().ero_gage)
	

## 프로그레스 바에서 현재 게이지에 해당하는 끝 지점의 글로벌 X 좌표를 계산한다.
## [param progress_bar]: 대상 프로그레스 바. [param gauge]: 현재 게이지 값.
func get_progress_end_point(progress_bar: TextureProgressBar, gauge: int)-> float:
	var bar_width = progress_bar.texture_progress.get_width() * progress_bar.scale.x
	var is_ratio = gauge / float(progress_bar.max_value)
	var end_point = progress_bar.global_position.x + bar_width * is_ratio + progress_bar.texture_progress_offset.x - 4
	return end_point
