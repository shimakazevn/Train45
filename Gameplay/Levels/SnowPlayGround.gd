extends PlayGround

@export var ghost_skip_component: GhostSkipComponent

@export var stage : Level
@export var icicle : PackedScene
var player : Player
@onready var snow = $Snow
@onready var drop_zone = $DropZone
@onready var snow_woman = $SnowWoman

var stage_failed := false
var stage_clear := false
var player_init_speed
var player_init_acceleration

@onready var p_cam = $PhantomCamera2D
@onready var collision_shape_2d = $PlayWall/CollisionShape2D
@onready var collision_shape_2d_2 = $PlayWall/CollisionShape2D2

var icicle_end := false
@export var survive_time := 30.0  # 버텨야 하는 시간(초). 게이지가 이 시간에 걸쳐 비워진다.
var icicle_spawn_timer = Timer.new()

var run_gauge: Node  # 런 스테이지 지속 게이지 (run_stage_gauge 그룹)
var icicle_timer = 3.5 # icicle이 생성될 간격 (초)

func _ready():
	GameEvents.stage_clear.connect(_on_stage_clear)
	player = stage.player as Player
	GameEvents.node_ready.connect(_on_player_ready)


func _on_player_ready(node_name : String):
	#플레이어가 완전히 배치되면 감지할수있게 그때 감지를 켜준다.
	if node_name == "player":
		player_init_speed = player.velocity_component.max_speed
		player_init_acceleration = player.velocity_component.acceleration
		player.set_speed_percentage(90.0)
		player.set_speed_acceleration(.5)

func _on_stage_clear():
	if GameEvents.node_ready.is_connected(_on_player_ready):
		GameEvents.node_ready.disconnect(_on_player_ready)
	if player_init_speed != null:
		if not MetaProgression.has_equipment("ghost_skip"):
			player.velocity_component.max_speed = player_init_speed
		player.velocity_component.acceleration = player_init_acceleration
	stage_clear = true
	snow_woman.visible = false
	snow.visible = false
	if run_gauge:
		run_gauge.hide()

func _process(_delta):
	if GameEvents.game_state == Constants.STATE_RAPE and icicle_end == false:
		icicle_play_end()
		icicle_end = true

func play_start():
	p_cam.set_priority(100)
	var snow_material = snow.material as ShaderMaterial
	snow_material.set_shader_parameter("additional_rain_speed", 0.8)
	snow_material.set_shader_parameter("near_rain_length", 0.02)
	# 게이지를 표시·충전한 뒤 survive_time 동안 비운다. 다 비워지면 생존 성공.
	run_gauge = get_tree().get_first_node_in_group("run_stage_gauge")
	if run_gauge:
		run_gauge.drained.connect(_on_survived)
		run_gauge.run_timer(survive_time)
	start_icicle_spawner()
	
	# collision_shape_2d 및 collision_shape_2d_2의 disabled 속성을 지연하여 변경
	call_deferred("enable_collision_shapes")
func enable_collision_shapes():
	collision_shape_2d.disabled = false
	collision_shape_2d_2.disabled = false

# icicle 생성기 시작 함수
func start_icicle_spawner():
	# 일정 시간마다 icicle을 생성하는 타이머 설정
	icicle_spawn_timer.set_wait_time(icicle_timer)  # icicle이 생성될 간격
	icicle_spawn_timer.set_autostart(true)
	icicle_spawn_timer.set_one_shot(false)
	icicle_spawn_timer.timeout.connect(_spawn_icicle)
	add_child(icicle_spawn_timer)

func _spawn_icicle():
	if icicle_end:
		return
	# drop_zone 내에서 랜덤한 위치 구하기
	var drop_zone_shape = drop_zone.shape as RectangleShape2D
	var random_x = randf_range(drop_zone.position.x - drop_zone_shape.extents.x, drop_zone.position.x + drop_zone_shape.extents.x)
	var random_y = randf_range(drop_zone.position.y - drop_zone_shape.extents.y, drop_zone.position.y + drop_zone_shape.extents.y)
	var spawn_position = Vector2(random_x, random_y)

	# icicle 생성
	var new_icicle = icicle.instantiate() as Node2D
	new_icicle.position = spawn_position
	add_child(new_icicle)

	icicle_timer -= 0.5
	icicle_timer = clampf(icicle_timer, 1, 30.0)
	icicle_spawn_timer.set_wait_time(icicle_timer)
	


# 게이지가 다 비워지면(버텨야 할 시간을 다 채우면) 생존 성공으로 종료한다.
func _on_survived():
	if icicle_end:
		return
	icicle_end = true
	icicle_play_end()


func icicle_play_end():
	if GameEvents.game_state == Constants.STATE_RAPE:
		stage_failed = true
		await TransitionScreen.on_transition_finishied
		snow_woman.visible = false
	icicle_spawn_timer.timeout.disconnect(_spawn_icicle)
	if run_gauge:
		run_gauge.hide()
	p_cam.set_priority(0)
	collision_shape_2d.disabled = true
	collision_shape_2d_2.disabled = true
