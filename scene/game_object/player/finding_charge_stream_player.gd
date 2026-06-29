## [KR] 탐지 충전 효과음을 재생하는 오디오 플레이어.
## [EN] Audio player that plays the detection charge sound effect.
## [KR] [member find_effect]의 가시성 변화에 연동하여 자동으로 재생/정지한다.
## [EN] Automatically plays/stops in sync with [member find_effect] visibility changes.
extends AudioStreamPlayer

## [KR] 탐지 시각 효과 [ColorRect] 참조 (유니크 노드)
## [EN] Reference to the detection visual effect [ColorRect] (unique node).
@onready var find_effect: ColorRect = %FindEffect

## [KR] 초기화 시 [member find_effect]의 가시성 변경 시그널을 연결한다.
## [EN] On initialization, connects to [member find_effect]'s visibility change signal.
func _ready() -> void:
	find_effect.visibility_changed.connect(_on_find_effect_visible)

## [KR] [member find_effect]가 보이면 효과음을 재생하고, 숨겨지면 정지한다.
## [EN] Plays the sound effect when [member find_effect] is visible, stops when hidden.
## [KR] 이미 재생 중일 때는 중복 재생을 방지한다.
## [EN] Prevents duplicate playback when already playing.
func _on_find_effect_visible():
	if find_effect.visible == true:
		if not playing:
			play()
	else:
		stop()
