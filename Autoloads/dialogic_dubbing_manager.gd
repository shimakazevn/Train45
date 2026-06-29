## Dialogic 텍스트 이벤트의 번역 ID(`#id:`)에 대응하는 `.ogg`를 재생한다.
##
## 경로 규칙: [member voice_folder]/[타임라인 파일 basename]/[번역 id].ogg
## [code]<a/b/c>[/code] 랜덤 변형이 있는 경우 [code]id_1.ogg / id_2.ogg / ...[/code]에서
## 표시된 텍스트와 대조해 정확한 변형 파일을 재생한다.
## - 새 대사가 표시되기 전에 [method Dialogic.Voice.stop_audio] 후 재생해 이전 음성을 끊는다.
## - [code][n+][/code] 연속(append) 구간은 같은 이벤트의 이어짐이므로 클립을 바꾸지 않는다.
## - 타임라인에서 바로 위 이벤트가 Dialogic Voice 이벤트면([method Dialogic.Voice.is_voiced]) 이 매니저는 재생하지 않고 Dialogic 기본 동작에 맡긴다.
extends Node

@onready var voice_folder: String = "res://sound/voice/"
@onready var audio_bus: String = "Character"
@onready var volume_db: float = 0.0

## <a/b/c> 변형 파싱용 정규식.
var _variant_regex := RegEx.create_from_string(r"(?<!\\)\<([^\[\>]+(?:\/[^\>]*)*)\>")

var _current_voice_path: String = ""
var _stopping_intentionally: bool = false
var _skip_resume_position: float = -1.0


## [param voice_root] 아래에 [param timeline_basename]/[param line_id].ogg 경로를 만든다. id나 basename이 비면 빈 문자열.
static func build_voice_path(voice_root: String, timeline_basename: String, line_id: String) -> String:
	if line_id.is_empty() or timeline_basename.is_empty():
		return ""
	var root := voice_root.trim_suffix("/")
	return root.path_join(timeline_basename).path_join(line_id + ".ogg")


## 노드 준비 시 Dialogic 시그널을 구독한다.
func _ready() -> void:
	_connect_dialogic()


## Dialogic 싱글톤이 유효하고 씬 트리 안에 있을 때만 true.
func _dialogic_ready() -> bool:
	return is_instance_valid(Dialogic) and Dialogic.is_inside_tree()


## 텍스트 표시 직전·타임라인 시작/종료 시그널을 한 번만 연결한다.
func _connect_dialogic() -> void:
	if not _dialogic_ready():
		return
	if not Dialogic.Text.about_to_show_text.is_connected(_on_about_to_show_text):
		Dialogic.Text.about_to_show_text.connect(_on_about_to_show_text)
	if not Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.connect(_on_timeline_ended)
	if not Dialogic.timeline_started.is_connected(_on_timeline_started):
		Dialogic.timeline_started.connect(_on_timeline_started)
	if Dialogic.has_subsystem("Voice") and not Dialogic.Voice.voiceline_stopped.is_connected(_on_voiceline_stopped):
		Dialogic.Voice.voiceline_stopped.connect(_on_voiceline_stopped)


## 타임라인이 시작되면 이전에 재생 중이던 더빙을 끈다.
func _on_timeline_started() -> void:
	_stop_voice()


## 타임라인이 끝나면 음성을 정지한다.
func _on_timeline_ended() -> void:
	_stop_voice()


## 새 대사 줄이 보이기 직전: append가 아니고, Voice 서브시스템이 있으며, 바로 위가 Dialogic Voice 이벤트가 아니면
## 번역 id에 맞는 ogg를 찾아 재생한다. 파일이 없거나 조건을 만족하지 않으면 아무 것도 하지 않는다.
func _on_about_to_show_text(info: Dictionary) -> void:
	if info.get("append", false):
		return
	if not Dialogic.has_subsystem("Voice"):
		return
	var idx: int = Dialogic.current_event_idx
	if idx < 0 or idx >= Dialogic.current_timeline_events.size():
		return
	if Dialogic.Voice.is_voiced(idx):
		return
	var ev: DialogicEvent = Dialogic.current_timeline_events[idx]
	if not ev is DialogicTextEvent:
		return
	var line_id: String = ev._translation_id
	if line_id.is_empty():
		return
	var tl: DialogicTimeline = Dialogic.current_timeline
	if tl == null or tl.resource_path.is_empty():
		return
	var base: String = tl.resource_path.get_file().get_basename()
	var path := build_voice_path(voice_folder, base, line_id)

	# 단순 파일이 없으면 _1/_2/_3 변형 시도
	if not ResourceLoader.exists(path):
		var variant_num := _get_variant_num(line_id, base, info.get("text", ""))
		if variant_num > 0:
			path = build_voice_path(voice_folder, base, line_id + "_" + str(variant_num))

	if not ResourceLoader.exists(path):
		return
	_stop_voice()
	if Dialogic.Voice.current_audio_file == path:
		Dialogic.Voice.current_audio_file = ""
	Dialogic.Voice.set_file(path)
	Dialogic.Voice.set_volume(volume_db)
	Dialogic.Voice.set_bus(_get_voice_bus(ev))
	Dialogic.Voice.play_voice()
	_current_voice_path = path


## 표시된 텍스트가 <a/b/c> 변형 중 몇 번째인지 반환한다 (1-based).
## 변형 파일이 없거나 매칭 실패 시 0 반환.
func _get_variant_num(line_id: String, base: String, displayed_text: String) -> int:
	# _1 파일이 없으면 변형 케이스 아님
	if not ResourceLoader.exists(build_voice_path(voice_folder, base, line_id + "_1")):
		return 0

	# 현재 로케일의 번역에서 <a/b/c> 변형 목록 파싱
	var tr_key := "Text/" + line_id + "/text"
	var full_text := tr(tr_key)
	if full_text == tr_key:
		return 1  # 번역 없음, 1번으로 폴백

	var m := _variant_regex.search(full_text)
	if not m:
		return 1

	var inner := m.get_string(1).replace("//", "<slash>")
	var variants := inner.split("/")
	for i in variants.size():
		if variants[i].replace("<slash>", "/").strip_edges() == displayed_text.strip_edges():
			return i + 1

	return 1  # 매칭 실패, 1번으로 폴백


## 현재 캐릭터의 활성 포트레이트가 "bird"면 "CharacterBird" 버스를, 아니면 기본 버스를 반환한다.
func _get_voice_bus(ev: DialogicTextEvent) -> String:
	if not is_instance_valid(ev.character):
		return audio_bus
	# 텍스트 이벤트에 포트레이트가 명시된 경우 우선 사용 (예: butler(human): ...)
	var portrait: String = ev.portrait
	if portrait.is_empty():
		portrait = Dialogic.current_state_info.get("portraits", {}) \
			.get(ev.character.resource_path, {}).get("portrait", "")
	if portrait.is_empty():
		portrait = ev.character.default_portrait
	return "CharacterBird" if portrait == "bird" else audio_bus


## skip_text_reveal()이 음성을 강제 정지했을 때: 재생 위치를 저장하고 deferred로 재개한다.
func _on_voiceline_stopped(_info: Dictionary) -> void:
	if _stopping_intentionally or _current_voice_path.is_empty():
		return
	_skip_resume_position = Dialogic.Voice.voice_player.get_playback_position()
	call_deferred("_resume_voice_after_skip")


func _resume_voice_after_skip() -> void:
	if _skip_resume_position < 0.0 or _current_voice_path.is_empty():
		return
	var pos := _skip_resume_position
	_skip_resume_position = -1.0
	Dialogic.Voice.voice_player.play(pos)


## Dialogic Voice가 있으면 [method Dialogic.Voice.stop_audio]로 재생을 멈춘다.
func _stop_voice() -> void:
	if _dialogic_ready() and Dialogic.has_subsystem("Voice"):
		_stopping_intentionally = true
		_current_voice_path = ""
		_skip_resume_position = -1.0
		Dialogic.Voice.stop_audio()
		_stopping_intentionally = false
