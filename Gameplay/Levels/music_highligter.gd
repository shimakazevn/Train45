## [KR] 루프 BGM에서 클라이맥스 BGM으로 크로스페이드하는 컴포넌트.
## [KR] _ready 시 normal_music을 자동 재생하며,
## [KR] [method trigger_climax] 호출 시 노멀 음악은 페이드 아웃, 클라이맥스 음악은 페이드 인된다.
extends Node
class_name MusicHighligter

## [KR] 평상시 루프 재생할 BGM 플레이어.
@export var normal_music: AudioStreamPlayer
## [KR] 클라이맥스 구간에 재생할 BGM 플레이어.
@export var climax_music: AudioStreamPlayer

## [KR] 클라이맥스 음악의 재생 시작 지점 (초).
@export_range(0.0, 600.0, 0.1, "suffix:s") var climax_start_position: float = 0.0
## [KR] 크로스페이드 전환 시간 (초).
@export_range(0.1, 5.0, 0.1, "suffix:s") var crossfade_duration: float = 1.5

var _in_climax: bool = false

func _ready() -> void:
	if not normal_music or not climax_music:
		push_error("MusicHighlighter: normal_music 또는 climax_music이 설정되지 않았습니다.")
		return

	climax_music.volume_db = -80.0

	# 노멀 음악 자동 재생. 스트림 임포트에 loop가 꺼져 있어도 자동으로 반복됨.
	normal_music.finished.connect(_on_normal_finished)
	normal_music.play()

## [KR] 노멀 음악이 끝나면 다시 재생 (루프 임포트 설정과 무관하게 루프 보장).
func _on_normal_finished() -> void:
	if not _in_climax:
		normal_music.play()

## [KR] 클라이맥스 전환을 실행한다.
## [KR] 노멀 음악은 페이드 아웃되고, 클라이맥스 음악이 [member climax_start_position]부터 페이드 인된다.
## [KR] 이미 클라이맥스 상태면 무시된다.
func trigger_climax() -> void:
	if _in_climax:
		return
	_in_climax = true

	climax_music.volume_db = -80.0
	climax_music.play(climax_start_position)

	var tween := create_tween()
	tween.set_parallel()
	tween.tween_property(normal_music, "volume_db", -80.0, crossfade_duration)
	tween.tween_property(climax_music, "volume_db", 0.0, crossfade_duration)
	await tween.finished
	normal_music.stop()
