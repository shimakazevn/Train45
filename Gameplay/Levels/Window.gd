extends Sprite2D

@export var stage : Level
@onready var anomaly_collision = %AnomalyCollision

var player : Player
var opacity := 0.0
var max_opacity := 1.0  # 최대 불투명도 (1.0은 완전히 불투명)
var min_opacity := 0.0  # 최소 투명도 (0.0은 완전히 투명)
var max_distance := 120.0  # 최대 거리에서 완전히 투명해지도록 설정
var min_distance := 70.0  # 이 거리에서부터 1의 opacity가 나오도록 설정
var lerp_speed := .5  # 초기 lerp 속도

func _ready():
	# 초기 투명도를 설정
	player = stage.player as Player
	opacity = self.self_modulate.a

func _process(delta):
	if player == null :
		return 
	# 플레이어와의 X축 거리만 계산
	var distance_to_player_x = abs(anomaly_collision.position.x - player.position.x)
	
	# target_opacity 변수를 선언
	var target_opacity = max_opacity

	# 최소 거리 이하일 때는 완전히 불투명하게 설정
	if distance_to_player_x <= min_distance:
		target_opacity = max_opacity
	else:
		# 최소 거리를 초과하면 투명도를 거리 비례로 줄임
		var adjusted_distance = distance_to_player_x - min_distance
		# 거리 비례로 투명도 감소 (min_distance 이후부터 max_distance까지)
		target_opacity = clamp(1.0 - (adjusted_distance / (max_distance - min_distance)), min_opacity, max_opacity)
	
	# 투명도를 점진적으로 목표값으로 변경 (lerp 사용)
	opacity = lerp(opacity, target_opacity, 1.0 - exp(-lerp_speed * delta))
	
	# 투명도를 Sprite2D의 self_modulate에 반영
	self.self_modulate.a = opacity
