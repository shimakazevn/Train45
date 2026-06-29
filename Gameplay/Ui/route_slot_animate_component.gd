extends Node

@export var is_owner : RouteSlot

var tween: Tween
const WAIT_DURATION := 0.05
const MIN_VAL := 44.0
const MAX_VAL := 58.0

var popup_anim_spd: float

func _ready() -> void:
	popup_anim_spd = is_owner.total_route_num

	var original_color: Color = is_owner.get_color_update(is_owner.get_is_unlocked())
	is_owner.modulate = Color.TRANSPARENT

	# 1. 58 기준 가속 계산
	var t: float = clamp(
	(float(is_owner.total_route_num) - MIN_VAL) / (MAX_VAL - MIN_VAL),
	0.0,
	1.0
	)
	var speed_mul: float = lerp(1.0, 2.0, t)
	
	#print(speed_mul)
	# 2. 대기 시간 반영
	var wait_time: float = (is_owner.route_num * WAIT_DURATION) / speed_mul
	await get_tree().create_timer(wait_time).timeout

	is_owner.button_stream_player_component.button_show.emit()

	tween = create_tween().set_parallel()
	tween.tween_property(is_owner, "modulate", original_color, 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(is_owner, "scale", Vector2.ONE, 0.2)\
		.from(Vector2.ZERO).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	await tween.finished
	set_focus_signal()


func set_focus_signal():
	## 등장 애니메이션 끝난 후 신호 연결
	is_owner.focus_entered.connect(_on_focus_entered)
	is_owner.focus_exited.connect(_on_focus_exited)

func _on_focus_entered():
	set_twin()
	tween.tween_property(is_owner, "scale", Vector2.ONE*1.1, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_focus_exited():
	set_twin()
	tween.tween_property(is_owner, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func set_twin():
	if tween:
		tween.kill()
	tween = create_tween()
