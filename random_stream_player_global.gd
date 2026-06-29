## 글로벌(비공간) 랜덤 오디오 스트림 플레이어.
## [member streams] 배열에서 무작위 스트림을 선택하고, 선택적으로 피치를 랜덤화하여 재생한다.
extends AudioStreamPlayer

## 재생 후보 오디오 스트림 배열.
@export var streams: Array[AudioStream]
## [code]true[/code]이면 재생 시 피치를 랜덤 범위 내에서 변경한다.
@export var randomize_pitch = true
## 랜덤 피치 최솟값.
@export var min_pitch = .9
## 랜덤 피치 최댓값.
@export var max_pitch = 1.1

## [member streams]에서 랜덤 스트림을 선택하여 재생한다.
## 배열이 비어있으면 무시한다.
func play_random():
	if streams == null or streams.size() == 0:
		return
	
	if randomize_pitch:
		pitch_scale = randf_range(min_pitch, max_pitch)
	else:
		pitch_scale = 1
	
	stream = streams.pick_random()
	play()
