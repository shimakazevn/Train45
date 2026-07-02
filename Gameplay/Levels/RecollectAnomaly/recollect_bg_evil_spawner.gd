extends Node2D
## [KR] 회상방 배경 장식용 귀신 스포너. 귀신 H 모드 동안 화면 밖(좌/우)에서
## 배경 귀신(bg_evil)을 날려 보낸다. EvilPlayGround에 의존하지 않는 단순 버전.
## 노드 구성은 bg_evil_spwaner와 동일(SpwanPositionRight/Left, Timer)하다.

## [KR] 날릴 배경 귀신 씬(bg_evil.tscn).
@export var bg_evil: PackedScene
## [KR] 동시에 떠 있는 배경 귀신 상한(대략 두세 마리).
@export var spawn_cap := 2
## [KR] 배경 귀신이 소멸 전까지 가로로 이동하는 거리(px). 회상방은 화면이 넓어
## bg_anomaly_evil 기본값(900)으론 중간에 사라지므로 더 멀리 보낸다.
@export var travel_distance := 2100.0

@onready var spawn_position_right: Sprite2D = $SpwanPositionRight
@onready var spawn_position_left: Sprite2D = $SpwanPositionLeft
@onready var timer: Timer = $Timer

var _count := 0

func _ready() -> void:
	spawn_position_right.hide()
	spawn_position_left.hide()
	timer.timeout.connect(_on_timer_timeout)

## [KR] 스폰 시작(귀신 H 모드 진입 시 호출).
func start_spawning() -> void:
	timer.start()

## [KR] 스폰 중지 + 화면에 남은 배경 귀신 정리(귀신 H 모드 종료 시 호출).
func stop_spawning() -> void:
	timer.stop()
	for c in get_children():
		if c is BgAnomalyEvil:
			c.queue_free()

func _on_timer_timeout() -> void:
	if _count > spawn_cap:
		return
	timer.wait_time = randf_range(0.05, 0.3)
	_spawn_one()

## [KR] 좌/우 중 무작위로 골라 화면 밖에서 배경 귀신 하나를 스폰한다.
func _spawn_one() -> void:
	var evil := bg_evil.instantiate() as BgAnomalyEvil
	var offset := Vector2(0.0, randf_range(-47.0, 47.0))
	if randi() % 2 == 0:
		evil.position = spawn_position_right.position + offset
		evil.current_dir = BgAnomalyEvil.EvilDir.R
	else:
		evil.position = spawn_position_left.position + offset
		evil.current_dir = BgAnomalyEvil.EvilDir.L
	add_child(evil)
	# bg_anomaly_evil._ready가 900 기준으로 잡은 소멸 지점을 회상방용 이동거리로 덮어쓴다.
	evil.finish_pos_x = evil.position.x - (travel_distance * evil.current_dir)
	evil.tree_exited.connect(_on_evil_freed)
	_count += 1

func _on_evil_freed() -> void:
	_count -= 1
