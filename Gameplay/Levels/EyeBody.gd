extends Node2D

@onready var animation_player = $Eye/AnimationPlayer
@export var level : Level  # 플레이어의 위치를 따라감
var player : Player
@export var follow_speed := 0.008  # 플레이어를 따라가는 속도 (값이 작을수록 느림)
@export var offset_distance := 150.0  # 플레이어와의 최소 거리 (offset)

func _ready():
	player = level.player
	animation_player.play("idle")

func _process(_delta: float):
	# 플레이어가 존재할 때만 따라다니도록 처리
	if is_instance_valid(player) and is_instance_valid(level):
		if level.stage_clear:
			return
		# 플레이어와 이 노드의 X축 거리 계산
		var distance_to_player = abs(position.x - player.position.x)
		
		# X축 거리가 offset_distance 이상일 때만 따라감
		if distance_to_player > offset_distance:
			# 목표 X 위치는 플레이어의 X 위치
			var target_x_position = player.position.x
			
			# X축만 부드럽게 목표 위치로 이동 (러프 사용)
			position.x = lerp(position.x, target_x_position, follow_speed)
		else:
			var target_x_position = player.position.x
			position.x = lerp(position.x, target_x_position, follow_speed /4)
			
