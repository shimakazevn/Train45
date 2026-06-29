## [KR] H씬 대사(Talk) 컴포넌트.
## [br]자유 행위 진행 중 행위 상태(대기/행위/사정/후)에 따라
## NPC의 비대화(undialogue) 대사를 라벨에 랜덤으로 출력한다.
## 절정 모드에서는 대사를 1회만 표시하고, 일반 모드에서는 타이머로 순환한다.
## [EN] H-scene Talk component.
## [br]During free action, randomly displays NPC undialogue lines on a label
## based on action state (standby/play/climax/after).
## In climax mode shows line once; in normal mode cycles via timer.
extends Control

signal climax_voice_delay(delay: float)

const SCENE_VOICE_PATH := "res://sound/voice/scene_voice/"

## [KR] 연결된 자유 행위 컴포넌트 참조. [signal HSceneFreeActionComponent.action_state_change]를 구독한다.
## [EN] Reference to the connected free action component. Subscribes to [signal HSceneFreeActionComponent.action_state_change].
@export var free_action_component: HSceneFreeActionComponent
## [KR] 현재 NPC에 해당하는 비대화 대사 사전 (키=대사 ID).
## [EN] Undialogue line dictionary for the current NPC (key=line ID).
var npc_undialogue_dict: Dictionary
## [KR] 현재 상태·씬에 매칭되는 대사 키 배열.
## [EN] Array of dialogue keys matching the current state and scene.
var h_talks: Array
## [KR] 마지막으로 표시한 대사 키. 같은 대사가 연속되지 않도록 중복 방지에 사용한다.
## [EN] Last displayed dialogue key. Used to prevent consecutive duplicate lines.
var current_talk: String = ""
## [KR] 대사를 표시하는 [Label] 노드.
## [EN] [Label] node for displaying dialogue lines.
@onready var h_talk_label: Label = %HTalkLabel
## [KR] 대사 순환 간격을 제어하는 타이머.
## [EN] Timer controlling dialogue cycling interval.
@onready var h_talk_timer: Timer = $HTalkTimer
## [KR] 대사 표시 지속 시간을 제어하는 타이머.
## [EN] Timer controlling dialogue display duration.
@onready var show_timer: Timer = $ShowTimer

## [KR] 대사 한 번의 표시 지속 시간(초).
## [EN] Display duration per dialogue line (seconds).
const TALK_SHOW_TIME:= 5.0
## [KR] 대사 간 대기 시간(초). ahen이 없을 때 폴백으로 사용한다.
## [EN] Wait time between dialogue lines (seconds). Used as fallback when no ahen is playing.
const TALK_CHANGE_TIME:= 7.0
## [KR] ahen 기반 대기 시간 산출 시 클립 길이에서 빼는 얼리 오프셋(초).
## [EN] Early offset subtracted from ahen clip length when calculating wait time.
const TALK_CHANGE_EARLY:= 2.0
## [KR] ahen 기반 대기 시간의 최솟값(초). 클립이 짧아 계산값이 0 이하가 되는 것을 방지한다.
## [EN] Minimum wait time when using ahen-based timing. Prevents negative values from short clips.
const TALK_CHANGE_MIN:= 0.5

## [KR] 절정 모드 여부. [code]true[/code]이면 대사를 1회만 표시하고 순환하지 않는다.
## [EN] Whether in climax mode. When [code]true[/code], shows dialogue once without cycling.
var is_climax_mode := false

var _audio_player: AudioStreamPlayer
var _ahen_player: AudioStreamPlayer
var _ahen_keys: PackedStringArray = PackedStringArray()
var _all_h_scene_res: Array = []

## [KR] NPC 타입 → 대사 데이터상의 _Speaker 키 매핑.
## [EN] NPC type to _Speaker key mapping in dialogue data.
var npc_name_map := {
	0: "reina",
	1: "mai",
	2: "konial",
	3: "pazuzu",
	4: "butler"
}
## [KR] 행위 진행 상태 → 대사 데이터상의 _Type 키 매핑.
## [EN] Action progress state to _Type key mapping in dialogue data.
var npc_action_state := {
	0: "null",
	1: "ready",
	2: "playing",
	3: "cum",
	4: "after"
}

## [KR] 초기화: [member free_action_component]의 상태 변경 시그널을 구독하고 NPC 대사 데이터를 로드한다.
## [EN] Initialization: subscribes to state change signal of [member free_action_component] and loads NPC dialogue data.
func _ready() -> void:
	free_action_component.action_state_change.connect(_on_action_state_changed)
	npc_undialogue_dict = set_npc_undialogue_talk_data(Constants.UNDIALOGUE_TALK_DATA, free_action_component.npc.npc_name)
	h_talk_timer.timeout.connect(_on_timeout)
	show_timer.timeout.connect(_on_show_timer_timeout)
	h_talk_label.text = ""
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = "Character"
	_audio_player.finished.connect(_on_voice_finished)
	add_child(_audio_player)
	_ahen_player = AudioStreamPlayer.new()
	_ahen_player.bus = "Character"
	_ahen_player.finished.connect(_on_ahen_finished)
	add_child(_ahen_player)
	_all_h_scene_res = TrainUtil.get_res_from_path(HSceneData.H_SCENE_DATA_PATH)
	climax_voice_delay.connect(free_action_component._on_climax_voice_delay)
	free_action_component.free_action_end.connect(_on_free_action_end)

## [KR] 행위 상태 변경 콜백. 기존 타이머를 초기화한 뒤 새 상태에 맞는 대사 세트를 설정한다.
## [br]절정 시 1회만 표시, [code]after(4)[/code] 상태에서는 대기 없이 즉시 출력한다.
## [EN] Action state change callback. Resets existing timers then sets dialogue set for the new state.
## [br]Shows once on climax; at [code]after(4)[/code] state, outputs immediately without waiting.
func _on_action_state_changed(state: int, scene_name: String, climax: bool):
	show_timer.stop()
	h_talk_timer.stop()
	_audio_player.stop()
	_stop_ahen()
	_ahen_keys.clear()
	h_talk_label.hide()

	is_climax_mode = climax  # [KR] climax 상태 저장 / [EN] Save climax state

	set_h_talk(state, scene_name)

	if state == 2:
		var res := _find_scene_res(free_action_component.npc.npc_name, scene_name)
		if res:
			_ahen_keys = res.ahen_keys.duplicate()

	if climax:
		show_rand_h_talk()  # [KR] 한 번만 보여줌 / [EN] Show only once
	else:
		if state == 4: # [KR] after일땐 대기시간 없이 대사 바로 출력 / [EN] At after state, output dialogue immediately without waiting
			show_rand_h_talk()
		else:
			wait_h_talk()

## [KR] [param state]와 [param scene_name]에 해당하는 대사 키 배열을 [member h_talks]에 설정한다.
## [EN] Sets the dialogue key array matching [param state] and [param scene_name] to [member h_talks].
func set_h_talk(state: int, scene_name: String):
	h_talks.clear()
	h_talks = get_keys_by_type(npc_undialogue_dict, npc_action_state[state], scene_name)

## [KR] [param undialogue_talk_data]에서 [param npc_type]에 해당하는 _Speaker 항목만 필터링하여 반환한다.
## [EN] Filters and returns only _Speaker entries matching [param npc_type] from [param undialogue_talk_data].
func set_npc_undialogue_talk_data(undialogue_talk_data: Dictionary, npc_type: int) -> Dictionary:
	var dict: Dictionary = {}
	## [KR] 해당하는 _Speaker의 캐릭터 키값만 가져온다.
	## [EN] Only retrieves character key values for the matching _Speaker.
	for key in undialogue_talk_data["undialogue_voice"].keys():
		var entry :Dictionary = undialogue_talk_data["undialogue_voice"][key]
		
		if entry.has("_Speaker") and entry["_Speaker"] == npc_name_map[npc_type]:
			dict[key] = entry
	
	return dict

## [KR] [param dict]에서 _Type이 [param desired_type]이고 _Scene이 [param scene_name]인 키를 필터링하여 반환한다.
## [EN] Filters and returns keys from [param dict] where _Type matches [param desired_type] and _Scene matches [param scene_name].
func get_keys_by_type(dict: Dictionary, desired_type: String, scene_name: String) -> Array:
	var filtered_keys: Array = []

	for key in dict.keys():
		var entry: Dictionary = dict[key]
		if entry.has("_Type") and entry["_Type"] == desired_type:
			if entry.has("_Scene") and entry["_Scene"] == scene_name:
				filtered_keys.append(key)

	return filtered_keys

## [KR] 대사 순환 타이머 콜백. [method show_rand_h_talk]를 호출하여 다음 대사를 표시한다.
## [EN] Dialogue cycling timer callback. Calls [method show_rand_h_talk] to display next dialogue.
func _on_timeout():
	show_rand_h_talk()

## [KR] [member h_talks]에서 랜덤 대사를 선택하여 라벨에 표시한다.
## [br]직전 대사와 중복되지 않도록 반복 선택하며,
## 표시 후 [member TALK_SHOW_TIME]만큼 show_timer를 시작한다.
## [EN] Selects a random dialogue from [member h_talks] and displays it on the label.
## [br]Repeatedly selects to avoid duplicating the previous line.
## Starts show_timer for [member TALK_SHOW_TIME] after display.
func show_rand_h_talk():
	if h_talks != []:
		h_talk_label.show()
		
		var next_talk := current_talk
		if h_talks.size() > 1:
			while next_talk == current_talk:
				next_talk = h_talks.pick_random()
		else:
			next_talk = h_talks[0]

		current_talk = next_talk
		_stop_ahen()
		h_talk_label.text = next_talk
		var voiced := _play_voice(next_talk)
		if is_climax_mode:
			var dur := _audio_player.stream.get_length() if voiced else 0.0
			climax_voice_delay.emit(dur)
		elif not voiced:
			show_timer.wait_time = TALK_SHOW_TIME
			show_timer.start()

## [KR] 대사 표시 시간 종료 콜백. [method wait_h_talk]를 호출하여 다음 대사 대기를 시작한다.
## [EN] Dialogue display time end callback. Calls [method wait_h_talk] to start waiting for next dialogue.
func _on_show_timer_timeout():
	wait_h_talk()

## [KR] 대사 라벨을 숨기고, 절정 모드가 아니면 [member TALK_CHANGE_TIME] 후 다음 대사를 표시하도록 타이머를 시작한다.
## [EN] Hides the dialogue label. If not in climax mode, starts timer to show next dialogue after [member TALK_CHANGE_TIME].
func wait_h_talk():
	h_talk_label.hide()
	_start_ahen()
	if not is_climax_mode:
		var wait_time := TALK_CHANGE_TIME
		if not _ahen_keys.is_empty():
			var duration := _ahen_player.stream.get_length()
			wait_time = randf_range(max(TALK_CHANGE_MIN, duration - TALK_CHANGE_EARLY), duration)
		h_talk_timer.start(wait_time)


func _on_free_action_end() -> void:
	show_timer.stop()
	h_talk_timer.stop()
	_audio_player.stop()
	_stop_ahen()
	_ahen_keys.clear()
	h_talk_label.hide()


func _on_voice_finished() -> void:
	wait_h_talk()


func _find_scene_res(npc_type: int, scene_name: String) -> HSceneRes:
	for res in _all_h_scene_res:
		if res is HSceneRes and res.partner == npc_type and res.scene_name == scene_name:
			return res
	return null


func _start_ahen() -> void:
	if _ahen_keys.is_empty():
		return
	var path := SCENE_VOICE_PATH + _ahen_keys[randi() % _ahen_keys.size()] + ".ogg"
	if not ResourceLoader.exists(path):
		return
	_ahen_player.stream = load(path)
	_ahen_player.play()


func _stop_ahen() -> void:
	_ahen_player.stop()


func _on_ahen_finished() -> void:
	_start_ahen()


func _play_voice(key: String) -> bool:
	var path := SCENE_VOICE_PATH + key + ".ogg"
	if not ResourceLoader.exists(path):
		return false
	_audio_player.stream = load(path)
	_audio_player.play()
	return true
