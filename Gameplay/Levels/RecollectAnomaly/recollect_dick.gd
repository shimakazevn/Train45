## [KR] 회상방 전용 자지 아노말리.
## 기존 [DickAnomaly]의 도망/감지(hit)/dead 동작을 그대로 쓰되,
## 전역 stage_clear(클리어 처리)에 묶이지 않게 한다.
## - 원본은 dead가 GameEvents.stage_clear에 묶여 있어, 회상방에선 연결을 끊는다.
## - 대신 차지 완료(player_action) 시 이 자지를 감지중(DETECT)이면 dead → 잠시 뒤 idle로 부활한다.
class_name RecollectDick
extends DickAnomaly

## [KR] dead 후 다시 idle(감지 가능)로 되돌아오기까지 대기 시간(초).
@export var revive_delay: float = 3.0

func _ready() -> void:
	# [KR] 인스턴스 경계 NodePath export는 어긋나기 쉬워, 상위 Level에서 player를 직접 가져온다.
	if player == null:
		player = _find_level_player()
	super._ready()
	# [KR] 회상방: 전역 stage_clear로 죽거나 방이 클리어 처리되지 않게 연결을 끊는다.
	if GameEvents.stage_clear.is_connected(_on_stage_clear):
		GameEvents.stage_clear.disconnect(_on_stage_clear)
	# [KR] 감지(차지 완료) 시 dead 처리를 직접 건다(클리어 없이).
	if player and not player.player_action.is_connected(_on_recollect_action):
		player.player_action.connect(_on_recollect_action)

## [KR] 상위 트리에서 Level 루트를 찾아 그 player를 반환한다(없으면 null).
func _find_level_player() -> Player:
	var n: Node = get_parent()
	while n != null:
		if n is Level:
			return (n as Level).player
		n = n.get_parent()
	return null

## [KR] 차지 완료 시 호출. 이 자지를 감지중(DETECT)이면 dead → 잠시 뒤 부활.
func _on_recollect_action() -> void:
	if current_state == State.DEAD:
		return
	if current_state == State.DETECT:
		current_state = State.DEAD
		anim_player.play("dick_dead")
		_revive_after_delay()

## [KR] dead 후 일정 시간 뒤 idle(감지 가능)로 되돌린다.
func _revive_after_delay() -> void:
	await get_tree().create_timer(revive_delay).timeout
	if not is_inside_tree():
		return
	if current_state == State.DEAD:
		current_state = State.IDLE
		anim_player.play("dick_idle")
