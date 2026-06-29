extends RandomAudioStreamPlayer2D
class_name HSfxStream

enum HSceneTypes{ NORMAL, HARD, FELLA_IN, FELLA_OUT, KISS, HAND, CUM, ORGASM, BREASE_TOUCH, NORMAL_SUMATA, ONAHO}

signal h_sfx_played(type: HSceneTypes)

## 체크하면 기존 사운드가 재생중일 경우 이번 재생을 넘긴다
@export var wait_play: bool = false

@export var sfx_normal_streams: Array[AudioStream] = []
@export var sfx_hard_streams: Array[AudioStream] = []
@export var sfx_fella_in_streams: Array[AudioStream] = []
@export var sfx_fella_out_streams: Array[AudioStream] = []
@export var sfx_kiss_streams: Array[AudioStream] = []
@export var sfx_hand_streams: Array[AudioStream] = []
@export var sfx_cum_streams: Array[AudioStream] = []
@export var sfx_breast_touch_streams: Array[AudioStream] = []

func play_h_sfx(type: HSceneTypes):
	h_sfx_played.emit(type)
	match type:
		HSceneTypes.NORMAL:
			streams = sfx_normal_streams
		HSceneTypes.HARD:
			streams = sfx_hard_streams
		HSceneTypes.FELLA_IN:
			streams = sfx_fella_in_streams
		HSceneTypes.FELLA_OUT:
			streams = sfx_fella_out_streams
		HSceneTypes.KISS:
			streams = sfx_kiss_streams
		HSceneTypes.HAND:
			streams = sfx_kiss_streams
		HSceneTypes.CUM:
			streams = sfx_cum_streams
		HSceneTypes.NORMAL_SUMATA:
			streams = sfx_hard_streams
		HSceneTypes.ONAHO:
			streams = sfx_kiss_streams
		HSceneTypes.BREASE_TOUCH:
			streams = sfx_breast_touch_streams
	if wait_play:
		if not playing:
			play_random()
	else:
		play_random()

func play_h_sfx_normal():
	play_h_sfx(HSceneTypes.NORMAL)
func play_h_sfx_hard():
	play_h_sfx(HSceneTypes.HARD)
func play_h_sfx_fella_in():
	play_h_sfx(HSceneTypes.FELLA_IN)
func play_h_sfx_fella_out():
	play_h_sfx(HSceneTypes.FELLA_OUT)
func play_h_sfx_kiss():
	play_h_sfx(HSceneTypes.KISS)
func play_h_sfx_hand():
	play_h_sfx(HSceneTypes.HAND)
func play_h_sfx_cum():
	play_h_sfx(HSceneTypes.CUM)
func play_h_sfx_breast_touch():
	play_h_sfx(HSceneTypes.BREASE_TOUCH)
func play_h_sfx_normal_sumata():
	play_h_sfx(HSceneTypes.NORMAL_SUMATA)
