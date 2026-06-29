extends Sprite2D

var speed: float = 50
var direction: Vector2

func _ready():
	# 무작위 방향 설정 (방사형)
	var angle = randf() * TAU  # TAU는 2 * PI, 즉 360도입니다.
	direction = Vector2(cos(angle), sin(angle))

func _process(delta):
	# 설정된 방향으로 이동
	position += direction * speed * delta
	
