## [KR] 배경음악 및 열차 효과음 재생을 담당하는 오토로드 싱글톤.
## [EN] Autoload singleton that handles background music and train sound effect playback.
##
## [KR] 게임 시작 시 열차 주행 효과음을 자동 재생하며,
## [KR] [method bg_play]와 [method bg_stop]으로 배경 사운드를 제어한다.
## [EN] Automatically plays train driving sound effects when the game starts,
## [EN] and controls background sound via [method bg_play] and [method bg_stop].
extends Node

## [KR] 기본 열차 주행 루프 효과음 리소스 경로.
## [EN] Default train driving loop sound effect resource path.
const TRAIN_TRACKS_LOOP_01 = "res://sound/sfx/train_tracks_loop_01.wav"

## [KR] BGM 전용 오디오 플레이어.
## [EN] BGM-dedicated audio player.
@onready var music_player: AudioStreamPlayer = $MusicPlayer
## [KR] 열차 효과음 전용 오디오 플레이어.
## [EN] Train sound effect dedicated audio player.
@onready var train_sound_player: AudioStreamPlayer = $TrainSoundPlayer
## [KR] 단발 효과음 전용 플레이어. 씬 전환으로 노드가 해제돼도 끊기지 않도록 오토로드에서 재생한다.
## [EN] One-shot SFX player. Plays from the autoload so it isn't cut off when scene nodes are freed.
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer
## [KR] 전차 방송 노드. 집사 대화에서 방송 주기를 조절할 때 사용한다.
## [EN] Train broadcast node. Used to adjust the broadcast interval from the butler dialog.
@onready var train_broadcast: TrainBroadcast = $TrainBroadcast

func _ready() -> void:
	bg_play(TRAIN_TRACKS_LOOP_01)
	# [KR] 대화가 끝나면 Dialogic [music]로 튼 BGM을 정지한다.
	# [KR] SoundManager가 Dialogic보다 먼저 로드되므로, 모든 오토로드가 준비된 뒤 연결한다.
	# [EN] Stop BGM played via Dialogic [music] when the dialog ends.
	# [EN] SoundManager loads before Dialogic, so connect after all autoloads are ready.
	_connect_dialogic.call_deferred()

## [KR] Dialogic 오토로드가 준비된 후 타임라인 종료 신호를 연결한다.
## [EN] Connects the timeline-ended signal once the Dialogic autoload is ready.
func _connect_dialogic() -> void:
	Dialogic.timeline_ended.connect(_on_timeline_ended)

## [KR] 지정한 사운드 파일을 배경 효과음으로 재생한다.
## [EN] Plays the specified sound file as background sound effect.
##
## [KR] [param sound_name]은 오디오 리소스 경로(예: "res://sound/sfx/...").
## [EN] [param sound_name] is the audio resource path (e.g. "res://sound/sfx/...").
## [KR] 기존 재생 중인 배경음은 새 스트림으로 교체된다.
## [EN] Any currently playing background sound is replaced by the new stream.
func bg_play(sound_name: String):
	var sound: AudioStream = load(sound_name)

	train_sound_player.stream = sound
	train_sound_player.play()

## [KR] 현재 재생 중인 배경 효과음을 정지한다.
## [EN] Stops the currently playing background sound effect.
func bg_stop():
	train_sound_player.stop()

## [KR] 단발 효과음을 재생한다. 씬 전환으로 호출자 노드가 해제돼도 오토로드라 끊기지 않는다.
## [EN] Plays a one-shot sound effect. Survives scene transitions since it runs on the autoload.
func play_sfx(stream: AudioStream):
	sfx_player.stream = stream
	sfx_player.play()

## [KR] 대화 종료 시 호출되어 Dialogic으로 재생 중이던 BGM을 정리한다.
## [EN] Called when the dialog ends to clean up BGM played via Dialogic.
func _on_timeline_ended():
	music_off()

## [KR] Dialogic Audio 서브시스템의 모든 채널 음악 플레이어를 정지·해제한다.
## [EN] Stops and frees all channel music players of the Dialogic Audio subsystem.
##
## [KR] Dialogic은 end_timeline 후에도 레이아웃이 남아 있으면 음악을 끄지 않으므로,
## [KR] 상태가 아닌 실제 플레이어 노드를 직접 정지하여 확실히 종료한다.
## [EN] Dialogic does not stop music if the layout remains after end_timeline,
## [EN] so we directly stop the actual player nodes instead of relying on state.
func music_off():
	for i in Dialogic.Audio.current_music_player.size():
		var player: AudioStreamPlayer = Dialogic.Audio.current_music_player[i]
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
			Dialogic.Audio.current_music_player[i] = null

## [KR] 전차 방송 주기 모드를 설정한다. (옵션 메뉴 방송 탭에서 호출)
## [param mode]는 "standard"(표준) / "long"(3배) / "off"(끄기). 일반·신음 방송에 동일 적용된다.
## [EN] Sets the train broadcast interval mode. Called from the options menu broadcast tab.
func set_broadcast_interval_mode(mode: String) -> void:
	train_broadcast.set_interval_mode(mode)

## [KR] 현재 저장된 방송 주기 모드("standard"/"long"/"off")를 반환한다. (옵션 메뉴 초기 선택용)
## [EN] Returns the currently saved broadcast interval mode, for initializing the options menu.
func get_broadcast_interval_mode() -> String:
	return train_broadcast.get_interval_mode()
