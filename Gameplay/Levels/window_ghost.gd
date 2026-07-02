extends Sprite2D

@export var level: Level
@onready var anim: AnimationPlayer = $AnimationPlayer

var follow_speed := 0.03  # 플레이어를 따라가는 속도 (값이 작을수록 느림)
var offset_distance := 50.0  # 플레이어와의 최소 거리 (offset)

## 스테이지 클리어 시 자동으로 숨길지 여부.
## 회상방(TYPE_COMPLETE)은 stage_clear가 항상 true라, 장식용으로 띄우려면 false로 둔다.
@export var hide_on_clear := true

var player : Player
var is_move := false

func _ready() -> void:
	player = level.player
	call_deferred("set_player_anim")

func _process(_delta: float) -> void:
	# 플레이어가 존재할 때만 따라다니도록 처리
	if is_instance_valid(player) and is_instance_valid(level):
		if hide_on_clear and level.stage_clear:
			if self.visible:
				hide()

			return
		# 플레이어와 이 노드의 X축 거리 계산
		var distance_to_player = abs(self.global_position.x - player.position.x)
		
		# X축 거리가 offset_distance 이상일 때만 따라감
		if distance_to_player > offset_distance:
			# 목표 X 위치는 플레이어의 X 위치
			var target_x_position = player.position.x
			
			# X축만 부드럽게 목표 위치로 이동 (러프 사용)
			self.global_position.x = lerp(self.global_position.x, target_x_position, follow_speed)

		if self.global_position.x < player.global_position.x:
			flip_h = false
		else:
			flip_h = true


func set_player_anim():
	(player.animation_player as AnimationPlayer).current_animation_changed.connect(_on_player_anim_changed)

func _on_player_anim_changed(anim_name: String):
	if anim_name == "walk":
		is_move = true
		anim.play("move")
	else:
		is_move = false
		anim.play("idle")
