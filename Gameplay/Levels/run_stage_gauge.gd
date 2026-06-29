extends Control

# 런 스테이지 지속 게이지.
# 시작하면 최고치까지 차오른 뒤, 잔량이 줄면 깎여나간다.
# 철권식 잔상 연출: 앞쪽(Over) 바는 즉시 줄고, 뒤쪽(Base) 바는 천천히 따라온다.
# 두 바의 차이만큼 깎인 구간이 잠깐 잔상으로 보인다.

signal drained  # 타이머 모드에서 게이지가 0까지 다 비워졌을 때

@onready var base_bar: TextureProgressBar = $BaseProgressBar
@onready var over_bar: TextureProgressBar = $OverProgressBar

#만약 피격 효과를 주고싶은 대상이 있다면 추가, 없으면 무시
@export var enemy: Sprite2D

@export var fill_time := 2.0       # 시작 시 최고치로 차오르는 시간
@export var over_drain_time := 0.12 # 앞 바가 즉시 줄어드는 시간
@export var base_drain_time := 0.5  # 뒤 잔상 바가 천천히 따라오는 시간
@export var shake_strength := 5.0   # 감소 시 흔들림 세기(px)
@export var shake_time := 0.2       # 흔들림 지속 시간
@export var flash_color := Color(1, 0.25, 0.25, 1)  # 피격 시 enemy가 물드는 색
@export var flash_time := 0.4      # 피격 색이 원래대로 돌아오는 시간

var _over_tween: Tween
var _base_tween: Tween
var _shake_tween: Tween
var _flash_tween: Tween
var _timer_tween: Tween
var _base_pos: Vector2  # 흔들림 복귀용 원위치

func _ready() -> void:
	# 스테이지 스크립트가 그룹으로 찾아 구동한다.
	add_to_group("run_stage_gauge")
	_base_pos = position
	hide()
	base_bar.value = 0.0
	over_bar.value = 0.0

# 게이지를 표시하고 최고치까지 차오르게 한다.
func show_and_fill() -> void:
	show()
	base_bar.value = 0.0
	over_bar.value = 0.0
	_over_tween = _restart(_over_tween, over_bar, over_bar.max_value, fill_time)
	_base_tween = _restart(_base_tween, base_bar, base_bar.max_value, fill_time)

# 타이머형 스테이지용: 표시 후 최고치까지 채우고, duration초에 걸쳐 0까지 비운다.
# 다 비워지면 drained 신호를 보낸다. (set_ratio와 달리 떨림/플래시 없음)
func run_timer(duration: float) -> void:
	show()
	base_bar.value = 0.0
	over_bar.value = 0.0
	if _timer_tween and _timer_tween.is_valid():
		_timer_tween.kill()
	_timer_tween = create_tween()
	# 최고치까지 차오르기
	_timer_tween.tween_property(over_bar, "value", over_bar.max_value, fill_time)
	_timer_tween.parallel().tween_property(base_bar, "value", base_bar.max_value, fill_time)
	# 지정 시간에 걸쳐 0까지 비우기
	_timer_tween.tween_property(over_bar, "value", 0.0, duration)
	_timer_tween.parallel().tween_property(base_bar, "value", 0.0, duration)
	_timer_tween.tween_callback(drained.emit)

# 잔량 비율(0.0~1.0)로 게이지를 갱신한다. 앞 바는 즉시, 뒤 바는 잔상처럼 천천히.
func set_ratio(ratio: float) -> void:
	var target := clampf(ratio, 0.0, 1.0) * over_bar.max_value
	if target < over_bar.value:  # 줄어들 때(피격)만 연출
		_shake()
		_flash_enemy()
	_over_tween = _restart(_over_tween, over_bar, target, over_drain_time)
	_base_tween = _restart(_base_tween, base_bar, target, base_drain_time)

# 게이지 전체를 짧게 흔든 뒤 제자리로 돌려놓는다.
func _shake() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = create_tween()
	var steps := 5
	for i in steps:
		var off := Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength))
		_shake_tween.tween_property(self, "position", _base_pos + off, shake_time / steps)
	_shake_tween.tween_property(self, "position", _base_pos, shake_time / steps)

# enemy 스프라이트를 빨갛게 물들였다가 원래 색으로 되돌려 피격을 표현한다.
func _flash_enemy() -> void:
	if enemy == null:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	enemy.modulate = flash_color
	_flash_tween = create_tween()
	_flash_tween.tween_property(enemy, "modulate", Color.WHITE, flash_time)

# 진행 중이던 트윈을 정리하고 새 트윈으로 value를 보간한다.
func _restart(tween: Tween, bar: TextureProgressBar, value: float, time: float) -> Tween:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(bar, "value", value, time)
	return tween
