extends PlayGround
class_name EvilPlayGround

signal play_starting
signal evil_stage_clear
signal game_over

@export var player: Player
@export var anomaly_evil: PackedScene
@export var flash_light: FlashLightComponent

@export var ghost_skip_component: GhostSkipComponent
@export var ground_cam: PhantomCamera2D
@export var play_wall: StaticBody2D
@export var dark_light: ColorRect

@onready var spwan_position_right: Sprite2D = $SpwanPositionRight
@onready var spwan_position_left: Sprite2D = $SpwanPositionLeft
@onready var evil_spwan_timer: Timer = $EvilSpwanTimer

var current_stage_clear: bool = false
var current_game_over: bool = false

const EVIL_TOTAL := 7  # 퇴치해야 할 목표 서큐버스 수 (게이지 최고치 기준)
var evil_count:int = EVIL_TOTAL # 남은 목표 악마 수

var run_gauge: Node  # 런 스테이지 지속 게이지 (run_stage_gauge 그룹)

var evil_spwan_start: bool = false
var spawn_time: float = 3.0 #최초 스폰 시간, 소환할때마다 스폰시간이 줄어듬

func _ready() -> void:
	GameEvents.stage_clear.connect(_on_stage_clear)
	spwan_position_right.hide()
	spwan_position_left.hide()

func play_start():
	if current_stage_clear:
		return
	play_starting.emit()
	# 지속 게이지를 표시하고 최고치까지 채운다.
	run_gauge = get_tree().get_first_node_in_group("run_stage_gauge")
	if run_gauge:
		run_gauge.show_and_fill()
	ground_cam.set_priority(100)
	for i:CollisionShape2D in play_wall.get_children():
		i.set_deferred("disabled", false)
		
	await get_tree().create_timer(5.0).timeout
	set_evil_spawn_start()

func set_evil_spawn_start():
	evil_spwan_timer.wait_time = spawn_time
	evil_spwan_timer.timeout.connect(_on_evil_spawn_timeout)
	evil_spwan_timer.start()
	evil_spwan_start = true
	
func _on_evil_spawn_timeout():
	if current_game_over:
		evil_spwan_timer.stop()
		return
	spawn_time = max(spawn_time - 0.2, 2.0)  # 최소값 제한
	evil_spwan_timer.wait_time = spawn_time
	evil_spwan()

func evil_spwan():
	var anomaly_evil_instance = anomaly_evil.instantiate() as AnomalyEvil
	anomaly_evil_instance.player = player
	var spawn_dir := randi()%2
	var rand_offset := Vector2(0.0, randf_range(0.0, 60.0))
	if spawn_dir == 0 :
		anomaly_evil_instance.position = spwan_position_right.position + rand_offset
		anomaly_evil_instance.current_dir = AnomalyEvil.EvilDir.R
	else:
		anomaly_evil_instance.position = spwan_position_left.position + rand_offset
		anomaly_evil_instance.current_dir = AnomalyEvil.EvilDir.L
	anomaly_evil_instance.died.connect(_on_evil_dead)
	anomaly_evil_instance.catch_player.connect(_on_game_over)
	game_over.connect(anomaly_evil_instance.queue_free)
	evil_stage_clear.connect(anomaly_evil_instance.set_die)
	self.add_child(anomaly_evil_instance)

func _on_evil_dead():
	evil_count -= 1
	# 서큐버스가 퇴치된 만큼 게이지를 깎는다.
	if run_gauge:
		run_gauge.set_ratio(float(evil_count) / EVIL_TOTAL)
	if evil_count <= 0:
		stage_clear()

func _on_game_over():
	game_over.emit()
	if run_gauge:
		run_gauge.hide()
	dark_light.hide()
	flash_light.queue_free()
	current_game_over = true

func stage_clear():
	if current_stage_clear:
		return
	current_stage_clear = true
	if run_gauge:
		run_gauge.hide()
	for i:CollisionShape2D in play_wall.get_children():
		i.set_deferred("disabled", true)
	ground_cam.set_priority(0)
	evil_spwan_timer.stop()
	off_dark_light()
	flash_light.queue_free()
	evil_stage_clear.emit()

func off_dark_light():
	var light_tween := get_tree().create_tween()
	light_tween.tween_property(dark_light, "self_modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)

func _on_stage_clear():
	stage_clear()
