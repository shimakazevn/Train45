extends Sprite2D

@onready var animation_player = $AnimationPlayer
@onready var timer = Timer.new()  # 타이머 생성

var current_animation = "out"  # 현재 재생 중인 애니메이션을 추적
var min_interval = 2.5  # 최소 간격 (초)
var max_interval = 5.0  # 최대 간격 (초)

func _ready():
	# 타이머 설정 및 씬에 추가
	timer.one_shot = true  # 한 번만 발동하는 타이머
	timer.timeout.connect(_on_timeout)  # 타이머가 끝났을 때 호출할 함수 연결
	add_child(timer)

	# 첫 번째 애니메이션 재생
	play_random_animation()

func _on_timeout():
	# 타이머가 끝나면 애니메이션 전환 및 재생
	play_random_animation()

func play_random_animation():
	# 현재 애니메이션이 "in"이면 "out"을 재생하고, 반대의 경우 "in" 재생
	if current_animation == "in":
		animation_player.play("out")
		current_animation = "out"
	else:
		animation_player.play("in")
		current_animation = "in"
	
	# 랜덤한 시간으로 타이머 시작
	var random_interval = randf_range(min_interval, max_interval)
	timer.start(random_interval)
