## 경험치 보너스(팬티 아이템) 발동 연출 아이콘.
## 스테이지 클리어 시 love_bonus와 같은 타이밍에, 아래에서 위로 올라와 등장 →
## 잠시 대기 → 위로 마저 올라가며 페이드 아웃하는 트윈을 1회 재생한다.
## HUD/PartnerContainer/ItemEffectIcon (TextureRect)에 부착되어 있다.
extends TextureRect

enum NpcType {NORMAL, KONIAL}
@export var npc_type: NpcType

## 등장 시 아래에서 올라오는 거리(px). 시작 위치 = 기본 위치보다 이 값만큼 아래.
@export var rise_distance: float = 20.0
## 사라질 때 기본 위치에서 추가로 더 올라가는 거리(px).
@export var exit_distance: float = 10.0
## 다 올라온 뒤 유지하는 대기 시간(초).
@export var hold_time: float = 1.0
## 등장(아래→기본 위치) 트윈 시간(초).
@export var rise_time: float = 0.5
## 퇴장(기본 위치→위 + 페이드) 트윈 시간(초).
@export var exit_time: float = 0.7

## 에디터에 배치된 기본(정지) 위치. 트윈의 기준점.
var _base_position: Vector2
## 현재 활성 트윈.
var _tween: Tween
## [PartnerManager] 참조. 맥스 레벨 판정에 사용.
var _partner_manager: PartnerManager

func _ready() -> void:
	_base_position = position
	# 평소엔 숨김 + 투명 상태로 대기
	modulate.a = 0.0
	hide()
	# love_bonus.gd와 동일하게 스테이지 클리어 시 발동
	GameEvents.stage_clear.connect(_on_stage_clear)
	_partner_manager = get_tree().get_first_node_in_group("partnermanager")

func _on_stage_clear() -> void:
	# 팬티(love_bonus) 아이템 미장착 시에는 경험치 보너스가 없으므로 연출도 생략한다.
	if not MetaProgression.has_equipment("love_bonus"):
		return
	# 맥스 레벨이면 경험치가 실제로 오르지 않으므로 연출도 생략한다.
	if _is_target_max_level():
		return
	play()

## [param npc_type]에 해당하는 대상이 맥스 레벨인지 판정한다.
func _is_target_max_level() -> bool:
	match npc_type:
		NpcType.KONIAL:
			var konial := _partner_manager.partner[Constants.NPC_KONIAL] as Npc
			# 코니알은 전용 상한(NPC_MAX_LEVEL_KONIAL)을 사용한다.
			return konial.love_level >= Constants.NPC_MAX_LEVEL_KONIAL
		_:
			var current_partner := _partner_manager.get_current_partner() as Npc
			return current_partner != null and current_partner.is_max_level()

## 아래→위 등장 → 대기 → 위로 마저 올라가며 사라지는 연출을 1회 재생한다.
func play() -> void:
	if _tween and _tween.is_running():
		_tween.kill()

	# 시작 상태: 기본 위치보다 살짝 아래 + 완전 투명
	position = _base_position + Vector2(0.0, rise_distance)
	modulate.a = 0.0
	show()

	_tween = create_tween()
	# 1) 아래에서 기본 위치로 올라오며 등장 (동시에 페이드 인)
	_tween.tween_property(self, "position:y", _base_position.y, rise_time) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	_tween.parallel().tween_property(self, "modulate:a", 1.0, rise_time * 0.6)
	# 2) 대기
	_tween.tween_interval(hold_time)
	# 3) 위로 마저 올라가며 페이드 아웃
	_tween.tween_property(self, "position:y", _base_position.y - exit_distance, exit_time) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.parallel().tween_property(self, "modulate:a", 0.0, exit_time)
	# 종료 후 숨기고 위치 복귀 (다음 발동 대비)
	_tween.tween_callback(_reset_after_play)

func _reset_after_play() -> void:
	hide()
	position = _base_position
