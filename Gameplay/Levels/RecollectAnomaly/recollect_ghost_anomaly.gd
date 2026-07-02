## [KR] 회상방 전용 귀신 H 아노말리.
## 기존 스테이지의 GhostHAnomaly를 건드리지 않기 위해, 회상방 씬에서만 이 서브클래스를 쓴다.
## 루프: NOT_FIND(감지 가능) → 차지 감지 → IN 애니 → H → 종료(AFTER_CUM) → 대기 후 NOT_FIND 복귀.
## - 회상방엔 ghost_ano_h 장비 개념이 없으므로 장비 체크를 항상 통과시킨다.
class_name RecollectGhostHAnomaly
extends GhostHAnomaly

## [KR] H 종료 후 다시 감지 가능해지기까지 대기 시간(초).
@export var reset_delay: float = 3.0

func _ready() -> void:
	# 회상방 일괄 감지 라우팅을 위해 그룹 등록 후 기본 초기화 수행
	add_to_group("recollect_ghost")
	# 인스턴스 경계를 넘는 NodePath export는 어긋나기 쉬워, 상위 Level에서 player를 직접 가져온다.
	# (인스펙터로 직접 지정해 둔 경우는 그대로 존중한다)
	if player == null:
		player = _find_level_player()
	super._ready()
	# 회상방 귀신은 전역 stage_clear가 아니라 per-ghost 감지(recollect_detect)로만 활성화한다.
	if GameEvents.stage_clear.is_connected(_on_stage_clear):
		GameEvents.stage_clear.disconnect(_on_stage_clear)
	# H 종료(AFTER_CUM) 시 일정 시간 뒤 원상복귀
	end_ghost_h.connect(_on_recollect_reset)

## [KR] 상위 트리에서 Level 루트를 찾아 그 player를 반환한다(없으면 null).
func _find_level_player() -> Player:
	var n: Node = get_parent()
	while n != null:
		if n is Level:
			return (n as Level).player
		n = n.get_parent()
	return null

## [KR] 회상방은 장비 체크를 우회한다(항상 통과).
func equip_item_check_override() -> bool:
	return true

## [KR] 회상방은 보상(티켓) 드롭이 없다. 드롭 매니저가 회상방엔 없어 freed 에러가 나므로,
## 드롭은 생략하고 게이지 연출만 유지한다.
func ticket_drop() -> void:
	set_progress_bar_tween()

## [KR] player_ghost_sex는 모든 귀신에 방송된다(base는 1마리 전제).
## 회상방엔 여럿이라, 지금 상호작용 중인 귀신(near_h_ghost == self)만 반응하게 막는다.
func _on_ghost_sex(state: bool) -> void:
	if player.near_h_ghost != self:
		return
	super._on_ghost_sex(state)

## [KR] 차지 감지 시 호출. NOT_FIND → IN 애니를 재생하고 HArea를 켠다.
## in 애니가 끝나면 base의 _on_anim_finished가 AFTER_FIND로 넘긴다.
func recollect_detect() -> void:
	if current_state != GhostState.NOT_FIND:
		return
	h_area.monitorable = true
	current_state = GhostState.IN
	ghost_anim.play(STATE_ANIM_NAME[GhostState.IN])

## [KR] H 종료 후 대기했다가 NOT_FIND(감지 가능)로 되돌린다.
func _on_recollect_reset() -> void:
	await get_tree().create_timer(reset_delay).timeout
	if not is_inside_tree():
		return
	set_sprite_random() # random 타입이면 텍스처 재추첨(base는 무동작)
	_reset_to_not_find()

## [KR] 상태/게이지/UI를 최초(_ready) 값으로 되돌린다.
func _reset_to_not_find() -> void:
	current_state = GhostState.NOT_FIND
	h_area.monitorable = false
	climax_life = climax_life_max
	dropped_sections = 0
	climax_progress.value = 0.0
	keyboard_icon.hide()
	climax_progress_base.hide()
	love_effect.emitting = false
	ghost_anim.play(STATE_ANIM_NAME[GhostState.NOT_FIND])
