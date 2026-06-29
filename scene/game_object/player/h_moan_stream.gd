## [KR] 파트너 H의 action 중 재생되는 신음 보이스(랜덤 루프).
## [KR] action을 벗어나면 soft_stop: 재생 중인 클립은 끝까지 재생하고, 끝나도 다음 클립은 재생하지 않는다.
## [KR] [member streams]에 해당 파트너의 신음 음성을 넣어두면 무작위로 이어서 재생된다.
## [KR] 화면 위치감이 필요 없어 비위치 AudioStreamPlayer를 쓴다(free action 신음과 동일하게 항상 풀볼륨).
extends AudioStreamPlayer
class_name HMoanStream

## [KR] 무작위로 선택해 재생할 신음 음성 배열.
@export var streams: Array[AudioStream]
## [KR] 재생마다 피치를 살짝 랜덤화해 반복 단조로움을 줄인다.
@export var randomize_pitch := true
@export var min_pitch := 0.9
@export var max_pitch := 1.1

var _looping := false

func _ready() -> void:
	finished.connect(_on_finished)

## [KR] 신음 루프 시작. 이미 재생 중이면(soft_stop 직후 꼬리 재생 등) 루프 플래그만 다시 켠다.
func start_loop() -> void:
	if streams.is_empty():
		return
	_looping = true
	if not playing:
		play_random()

## [KR] 부드러운 정지: 재생 중인 클립은 마저 재생하고, 끝나도 다음 클립을 재생하지 않는다.
func soft_stop() -> void:
	_looping = false

## [KR] 즉시 정지: 루프를 끄고 재생 중인 클립도 바로 멈춘다(H 중단·종료 시).
func stop_now() -> void:
	_looping = false
	stop()

## [KR] streams에서 무작위 하나를 선택해 재생한다.
func play_random() -> void:
	if streams.is_empty():
		return
	if randomize_pitch:
		pitch_scale = randf_range(min_pitch, max_pitch)
	else:
		pitch_scale = 1.0
	stream = streams.pick_random()
	play()

## [KR] 한 클립이 끝나면, 루프 중일 때만 다시 무작위로 재생 = 랜덤 루프.
func _on_finished() -> void:
	if _looping:
		play_random()
