extends Node

var normal_speed := false

@onready var sprite = self  # 셰이더가 적용된 노드
@export var speed: float = 1.0  # 텍스처 이동 속도
@export var init_speed := 0.0
var max_speed_multiplier: float = 2.2  # init_speed 대비 상한 배율 (0이면 제한 없음, 예: 3.0 = init_speed의 3배)
@export var increase_percentage: float = 0.03  # 프레임마다 속도를 증가시킬 비율 (1% 증가)
var custom_time: float = 0.0  # 경과 시간을 관리할 변수
var final_uv_x: float = 0.0  # GDScript에서 계산한 최종 UV.x 값

func _ready():
	# 시간을 0으로 초기화 (매번 시작할 때 초기화됨)
	custom_time = 0.0
	speed = init_speed
	
	# 셰이더 초기화
	if sprite.material and sprite.material is ShaderMaterial:
		var shader_material = sprite.material as ShaderMaterial
		shader_material.set_shader_parameter("final_uv_x", final_uv_x)  # 초기 UV.x 값
	
	# 스테이지 클리어 이벤트 연결
	GameEvents.stage_clear.connect(_on_stage_clear)

func _process(delta: float):
	# 경과 시간을 누적
	custom_time += delta
	
	# normal_speed가 false일 때만 속도 증가
	if not normal_speed:
		# speed 값을 일정 비율로 증가시킴
		speed *= (1.0 + increase_percentage * delta)  # 매 프레임마다 일정 퍼센트씩 증가
		#print(speed)
		if max_speed_multiplier > 0.0:
			speed = minf(speed, init_speed * max_speed_multiplier)
	else:
		# normal_speed가 true일 때 speed는 고정된 init_speed 사용
		speed = init_speed
	
	# 최종 UV.x 좌표 계산 (시간 누적 값 * 현재 speed 값)
	final_uv_x = custom_time * speed
	
	# 셰이더에 최종 UV.x 좌표를 전달
	if sprite.material and sprite.material is ShaderMaterial:
		var shader_material = sprite.material as ShaderMaterial
		shader_material.set_shader_parameter("final_uv_x", final_uv_x)

func _on_stage_clear():
	# normal_speed가 true가 되면 더 이상 speed를 증가시키지 않고 초기 값으로 되돌림
	normal_speed = true
	
	# 시간과 UV.x 좌표를 초기화할 때 호출할 수 있는 함수
	custom_time = 0.0
	speed = init_speed  # speed도 초기화
	
	if sprite.material and sprite.material is ShaderMaterial:
		var shader_material = sprite.material as ShaderMaterial
		shader_material.set_shader_parameter("final_uv_x", final_uv_x)
