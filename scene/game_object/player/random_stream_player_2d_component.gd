## [KR] 여러 [AudioStream] 중 하나를 무작위로 선택하여 재생하는 2D 오디오 컴포넌트.
## [EN] 2D audio component that randomly selects and plays one of multiple [AudioStream]s.
## [KR] 피치 랜덤화를 지원하여 반복 재생 시 단조로움을 방지한다.
## [EN] Supports pitch randomization to prevent monotony during repeated playback.
extends AudioStreamPlayer2D
class_name RandomAudioStreamPlayer2D

## [KR] 무작위로 선택할 오디오 스트림 배열
## [EN] Array of audio streams to randomly select from.
@export var streams: Array[AudioStream]
## [KR] 피치 랜덤화 활성화 여부
## [EN] Whether pitch randomization is enabled.
@export var randomize_pitch = true
## [KR] 피치 랜덤 범위의 최솟값
## [EN] Minimum value of the pitch random range.
@export var min_pitch = .9
## [KR] 피치 랜덤 범위의 최댓값
## [EN] Maximum value of the pitch random range.
@export var max_pitch = 1.1

## [KR] [member streams]에서 무작위 스트림을 선택하여 재생한다.
## [EN] Selects a random stream from [member streams] and plays it.
## [KR] [member randomize_pitch]가 [code]true[/code]이면 [member min_pitch]~[member max_pitch]
## [KR] 범위에서 피치를 랜덤으로 설정한다.
## [EN] If [member randomize_pitch] is [code]true[/code], sets pitch randomly within [member min_pitch]~[member max_pitch] range.
func play_random():
	if streams == null or streams.size() == 0:
		return
	
	if randomize_pitch:
		pitch_scale = randf_range(min_pitch, max_pitch)
	else:
		pitch_scale = 1
	
	stream = streams.pick_random()
	play()
