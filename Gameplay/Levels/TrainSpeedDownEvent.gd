extends Node

@export var bg: Array[Sprite2D] = []
@export var decrease_percentage: float = 0.001  # 프레임마다 감소시킬 퍼센티지 (0.01 = 1% 감소)
var normal_speed := false
var move_start := false

# 각 Sprite2D의 초기 speed 값을 저장할 배열
var initial_speeds: Array[float] = [0.005, 0.02, 0.06, 0.1, 0.15, 0.25, 0.25]

func _ready():
	# Sprite2D의 초기 speed 값을 설정
	for i in range(min(bg.size(), initial_speeds.size())):
		var sprite = bg[i]
		if sprite.material and sprite.material is ShaderMaterial:
			var shader_material = sprite.material as ShaderMaterial
			#print(shader_material.get_shader_parameter("speed"))
			# 초기 저장된 speed 값 복원
			shader_material.set_shader_parameter("speed", initial_speeds[i])
			#print("Setting initial speed for sprite " + str(i) + ": " + str(initial_speeds[i]))
	
	GameEvents.stage_clear.connect(_on_stage_clear)

func _process(delta: float):
	# normal_speed가 false일 때 speed 감소
	if not normal_speed:
		for sprite in bg:
			if sprite.material and sprite.material is ShaderMaterial:
				
				var shader_material = sprite.material as ShaderMaterial
				# 기존 speed 값 가져오기
				var current_speed = shader_material.get_shader_parameter("speed")
				# 프레임마다 퍼센티지로 speed 감소시키기
				var new_speed = current_speed * (1.0 - decrease_percentage)  # 속도 감소
				# 셰이더 파라미터 업데이트
				shader_material.set_shader_parameter("speed", new_speed)
				#print(new_speed)
	else:
		# normal_speed가 true일 때 초기 speed로 되돌리기
		for i in range(min(bg.size(), initial_speeds.size())):
			var sprite = bg[i]
			if sprite.material and sprite.material is ShaderMaterial:
				var shader_material = sprite.material as ShaderMaterial
				# 초기 저장된 speed 값 복원
				shader_material.set_shader_parameter("speed", initial_speeds[i])
				#print(initial_speeds[i])

func _on_stage_clear():
	# normal_speed가 true가 되면 더 이상 speed를 감소시키지 않고 초기 값으로 되돌림
	normal_speed = true
