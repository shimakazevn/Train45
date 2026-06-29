extends Camera2D

func _ready():
	# 메인 루트일 때는 카메라 비활성화
	if Engine.is_editor_hint():
		pass
		# 에디터에서 실행 중일 때 (테스트 환경)
		#enabled = true
	else:
		pass
		# 메인 게임 루트에서 실행될 때 (실제 실행 환경)
		#enabled = true
