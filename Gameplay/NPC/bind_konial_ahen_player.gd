extends AudioStreamPlayer2D

# 코니알의 현재 상태를 확인할 AnimationPlayer (형제 노드)
@onready var _anim: AnimationPlayer = $"../AnimationPlayer"

func _ready() -> void:
	# 방송(TrainBroadcast)이 찾아 호출할 수 있도록 그룹에 등록
	add_to_group("bind_konial_ahen")

# ahen 방송과 같은 음성을 같은 타이밍에 위치 기반으로 재생 (방송과 싱크)
func play_synced(line: AudioStream) -> void:
	if line == null:
		return
	# 코니알이 묶인(bind) 상태일 때만 재생
	if _anim.current_animation != "bind":
		return
	stream = line
	play()
