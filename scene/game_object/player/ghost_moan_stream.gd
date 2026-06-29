## [KR] 귀신에게 강간당하는 동안 재생되는 귀신 신음 루프 플레이어.
## [KR] rape() anim_string으로 귀신을 구분해 해당 세트를 무작위로 루프 재생한다.
## [KR] wav의 import 루프는 꺼져 있어, 한 클립이 끝나면 세트에서 다시 무작위 선택해 재생한다(랜덤 루프).
extends AudioStreamPlayer
class_name GhostMoanStream

## [KR] 재생마다 피치를 살짝 랜덤화해 반복 단조로움을 줄인다.
@export var randomize_pitch := true
@export var min_pitch := 0.95
@export var max_pitch := 1.05

## [KR] 서큐버스(evil1/2/3 색상별 공용) 신음 세트.
const _EVIL := [
	preload("res://sound/sfx/h_sfx/ghost/EvilMoan1.wav"),
	preload("res://sound/sfx/h_sfx/ghost/EvilMoan2.wav"),
]

## [KR] rape() anim_string → 신음 세트. 비어 있으면(미정 귀신) 재생하지 않는다.
## [KR] 새 귀신 보이스가 정해지면 여기에 anim_string과 wav 세트를 추가하면 된다.
const MOAN_SETS := {
	"ghost": [        # stage 13 터널 귀신
		preload("res://sound/sfx/h_sfx/ghost/TunnelGhostMoan1.wav"),
		preload("res://sound/sfx/h_sfx/ghost/TunnelGhostMoan2.wav"),
	],
	"white_ghost": [  # stage 20 인형 귀신
		preload("res://sound/sfx/h_sfx/ghost/DollGhostFella.wav"),
	],
	"hug_ghost": [    # stage 50 포옹 귀신
		preload("res://sound/sfx/h_sfx/ghost/HugGhostMoan1.wav"),
		preload("res://sound/sfx/h_sfx/ghost/HugGhostMoan2.wav"),
		preload("res://sound/sfx/h_sfx/ghost/HugGhostMoan3.wav"),
	],
	"snow": [         # 설녀(고드름) 귀신
		preload("res://sound/sfx/h_sfx/ghost/SnowGhostMoan1.wav"),
		preload("res://sound/sfx/h_sfx/ghost/SnowGhostMoan2.wav"),
	],
	"evil1": _EVIL,   # stage 51 서큐버스(노랑/보라/빨강 공용)
	"evil2": _EVIL,
	"evil3": _EVIL,
}

# [KR] 사정 씬 추가 시: 귀신별 오르가즘 보이스를 여기에 두고 play_orgasm(anim)으로 끼워 넣으면 된다.
# const ORGASM_SETS := { "hug_ghost": [...] }

var _current_set: Array = []
var _looping := false

func _ready() -> void:
	finished.connect(_on_finished)

## [KR] 해당 귀신의 신음 루프를 시작한다. 세트가 없으면 아무것도 하지 않는다.
func start_moan(anim_string: String) -> void:
	_current_set = MOAN_SETS.get(anim_string, [])
	if _current_set.is_empty():
		return
	_looping = true
	_play_random()

## [KR] 신음 루프를 정지한다(H신 종료 시 호출).
func stop_moan() -> void:
	_looping = false
	stop()

func _play_random() -> void:
	if _current_set.is_empty():
		return
	if randomize_pitch:
		pitch_scale = randf_range(min_pitch, max_pitch)
	stream = _current_set.pick_random()
	play()

## [KR] 한 클립이 끝나면 다시 무작위로 재생 = 랜덤 루프.
func _on_finished() -> void:
	if _looping:
		_play_random()
