extends CharacterBody2D

@export var ghost_skip_component: GhostSkipComponent
@export var stage : Level
@export var wall_coll: CollisionShape2D
var player : Player
@onready var pcam = $PhantomCamera2D
@onready var canvas_group = $CanvasGroup
@onready var ghost_player = $CanvasGroup/GhostSprite/GhostPlayer
@onready var float_player = $FloatPlayer

var ghost_stage_clear := false

var chase := false
var p_cam_setted := false
var speed := 45.0  # 이동 속도
var extra_speed := 23.0 # 가속도

signal die_anim_finished

func _ready():
	GameEvents.stage_change.connect(_on_stage_changed)
	player = stage.player as Player
	ghost_player.animation_finished.connect(_on_anim_finished)
	wall_coll.disabled = true

func _on_stage_changed():
	if ghost_skip_component.equip_ghost_skip:
		pcam.erase_follow_targets(player)

func _process(delta):
	# 플레이어와의 거리가 400보다 작을 때 추적 시작
	if player:
		# 플레이어가 귀신이 보이는 범위안에 들어와서 카메라 고정
		if player.position.distance_to(position) < 550.0 and not ghost_skip_component.equip_ghost_skip and not p_cam_setted:
			pcam.set_priority(100)
			wall_coll.disabled = false # 퇴로 잠금
			p_cam_setted = true
			
		if player.position.distance_to(position) < 300.0 and not chase:
			chase_mode()
			wall_coll.disabled = true # 퇴로 잠금 해제

		# 추적 모드일 때 플레이어를 향해 이동
		if chase and ghost_stage_clear == false:
			move_towards_player(delta)
		
	

# 추적 모드로 전환
func chase_mode():
	chase = true
	

# 플레이어를 향해 좌우(X축)로만 이동하는 함수
func move_towards_player(_delta):
	# 플레이어와 자신의 위치 사이의 방향 계산 (X축만 사용)
	var direction = (player.position - position).normalized()
	
	# Y축 값을 0으로 설정하여 좌우로만 이동하게 변경
	direction.y = 0
	
	var move_sign = sign(direction.x)
	if move_sign != 0:
		canvas_group.scale = Vector2(move_sign, 1)
	
	var far_add_speed: float = 0.0
	if player.position.distance_to(position) > 550.0:
		far_add_speed = 100.0
	
	# 속도를 방향에 따라 설정 (X축만)
	velocity = direction * (speed + far_add_speed)
	speed += extra_speed * _delta
	
	
	
	# CharacterBody2D의 move_and_slide를 이용해 이동
	move_and_slide()

func stage_clear():
	ghost_player.play("die")
	ghost_stage_clear = true
	float_player.stop()
	await die_anim_finished
	queue_free()
	
	
func _on_anim_finished(anim : String):
	if anim == "die":
		die_anim_finished.emit()
