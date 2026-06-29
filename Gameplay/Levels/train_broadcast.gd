extends AudioStreamPlayer
class_name TrainBroadcast

# 순서대로 이어 재생할 일반 안내 방송 음성 (135d~1362, 코니알 역장 멘트)
@export var broadcast_lines: Array[AudioStreamOggVorbis]
# 코니알이 붙잡힌 뒤(ahen) 재생할 음성. 이 중 한 줄을 랜덤 재생
@export var ahen_lines: Array[AudioStreamOggVorbis]
# 방송을 재생하지 않을 스테이지 (씬 파일명, 예: "stage_d_onsen.tscn").
# 일반 탑승 스테이지여도 여기 포함되면 방송하지 않음
@export var excluded_stages: Array[String] = []

# 일반 방송 주기(초) 최소/최대. 매번 이 범위에서 랜덤
var interval_min: float = 180.0
var interval_max: float = 200.0

# ahen 방송은 더 짧은 주기로 반복
var ahen_interval_min: float = 50.0
var ahen_interval_max: float = 56.0

# ahen 방송 시 줄일 볼륨(dB, 음수일수록 작아짐). 기본 볼륨에 더해짐
var ahen_volume_db: float = -9.0

# 한 방송 안에서 줄과 줄 사이의 간격(초)
var line_gap: float = 1.2

# 이 챕터부터는 코니알이 붙잡혀 있어 일반 방송 대신 ahen 방송을 재생
const AHEN_FROM_CHAPTER := 6

# 방송 주기 설정(오디오 설정 키). 집사 대화 선택지로 변경한다.
# "standard"=표준, "long"=표준의 3배 주기, "off"=방송 끔.
# 일반 방송과 신음(ahen) 방송에 동일하게 적용된다.
const INTERVAL_MODE_KEY := "broadcast_interval_mode"
const INTERVAL_MODE_STANDARD := "standard"
const INTERVAL_MODE_LONG := "long"
const INTERVAL_MODE_OFF := "off"
# "long" 모드에서 주기에 곱하는 배수
const LONG_INTERVAL_MULT := 3.0

# 현재 주기에 선택된 방송 음성 세트 (일반 또는 ahen)
var _active_lines: Array[AudioStreamOggVorbis]
# ahen 방송 여부. true면 한 줄 랜덤 재생, false면 전체 순차 재생
var _is_ahen := false
# 씬에 설정된 기본 볼륨 (ahen 감쇠의 기준)
var _base_volume_db: float

func _ready() -> void:
	_base_volume_db = volume_db
	_broadcast_loop()

# 대기 → 방송 한 편 → 대기 → ... 무한 반복. autoload 자식이므로 게임 내내 지속
func _broadcast_loop() -> void:
	while is_inside_tree():
		await _wait_interval()
		# 집사 설정에서 방송을 껐다면 이번 주기는 재생하지 않고 다시 대기한다
		if get_interval_mode() == INTERVAL_MODE_OFF:
			continue
		# 재생 직전에 모드를 평가 (대기 중 챕터가 바뀌었을 수 있음)
		_is_ahen = _chapter_is_ahen()
		_active_lines = ahen_lines if _is_ahen else broadcast_lines
		# 방송 불가 스테이지(메뉴·특수 씬 등)거나 음성이 없으면 이번 주기는 건너뜀
		if not _can_broadcast() or _active_lines.is_empty():
			continue
		# ahen이면 더 작은 볼륨으로, 아니면 기본 볼륨
		volume_db = _base_volume_db + (ahen_volume_db if _is_ahen else 0.0)
		await _play_announcement()

# 다음 방송까지 대기. 1초 단위로 나눠 기다리며, 대기 중 일반→ahen으로
# 바뀌면 즉시 대기를 끊어 첫 ahen이 곧바로 나오게 한다
func _wait_interval() -> void:
	var ahen_start := _chapter_is_ahen()
	var wait_min := ahen_interval_min if ahen_start else interval_min
	var wait_max := ahen_interval_max if ahen_start else interval_max
	var target := randf_range(wait_min, wait_max) * _interval_mult()
	var elapsed := 0.0
	while elapsed < target and is_inside_tree():
		# process_always=false: 게임이 일시정지되면 대기도 함께 멈춤
		await get_tree().create_timer(1.0, false).timeout
		elapsed += 1.0
		# 일반 대기 중 ahen 챕터로 진입하면 즉시 종료
		if not ahen_start and _chapter_is_ahen():
			return

# 현재 챕터가 ahen 방송 챕터(코니알 붙잡힘) 이상인지
func _chapter_is_ahen() -> bool:
	return MetaProgression.get_current_chapter() >= AHEN_FROM_CHAPTER

# 방송 한 편 재생. ahen이면 한 줄 랜덤, 일반이면 전체 순서대로 이어 재생
func _play_announcement() -> void:
	if _is_ahen:
		await _play_line(_active_lines.pick_random())
		return
	for line in _active_lines:
		# 한 줄이라도 중단되면(세이브 로드로 ahen 모드 변경 등) 남은 줄을 멈추고
		# 다음 루프에서 모드를 다시 평가하게 한다
		var finished_normally := await _play_line(line)
		if not finished_normally:
			return

# 한 줄을 재생하고 끝날 때까지 대기, 이어서 줄 간격만큼 대기.
# 정상 종료면 true, 재생 도중 중단되면 false 반환
func _play_line(line: AudioStreamOggVorbis) -> bool:
	if line == null:
		return true
	# 방송 불가 스테이지로 바뀌었으면 중단
	if not _can_broadcast():
		return false
	# 대화 중에는 방송하지 않음. 대화가 끝날 때까지 보류
	await _wait_while_dialog()
	# 대화를 기다리는 사이 스테이지가 바뀌었을 수 있으므로 재확인
	if not _can_broadcast():
		return false
	# ahen이면 붙잡힌 코니알과 같은 음성을 같은 타이밍에 재생(싱크)
	if _is_ahen:
		_sync_bound_konial(line)
	stream = line
	play()
	# 현재 줄이 끝날 때까지 대기하되, 재생 도중 세이브 로드 등으로 ahen 모드가
	# 바뀌면(1↔6챕터) 다른 챕터의 방송이 그대로 흘러나오므로 즉시 끊는다.
	# (stop()은 finished를 방출하지 않으므로 await finished 대신 폴링한다)
	while playing:
		if _is_ahen != _chapter_is_ahen():
			stop()
			return false
		await get_tree().create_timer(0.2, false).timeout
	# 다음 줄 전 짧은 간격
	if line_gap > 0.0:
		await get_tree().create_timer(line_gap, false).timeout
	return true

# 대화(Dialogic 타임라인)가 진행 중이면 끝날 때까지 대기
func _wait_while_dialog() -> void:
	while is_inside_tree() and Dialogic.current_timeline != null:
		await Dialogic.timeline_ended

# 지금 방송을 재생해도 되는 상태인지 (현재 살아있는 레벨 기준 실시간 판정)
func _can_broadcast() -> bool:
	return _is_broadcast_stage(_get_current_level())

# 현재 스테이지(Level)에서 방송을 재생해도 되는지
func _is_broadcast_stage(level: Level) -> bool:
	if level == null:
		return false
	# 회상방 / 에필로그(엔딩)에서는 방송 안 함
	if GameEvents.is_recollection_room or GameEvents.is_epilogue_room:
		return false
	# 프롤로그 스테이지 제외
	if level.prologue_stage:
		return false
	# 일반 탑승 스테이지만 허용 (base 허브 + 일반 스테이지 + 안전 스테이지).
	# safe도 포함하는 이유: 방송 유무로 안전 스테이지(이상현상 없음)를 역추론하지 못하게 함
	if level.stage_type != Constants.TYPE_BASE \
	and level.stage_type != Constants.TYPE_STAGE \
	and level.stage_type != Constants.TYPE_SAFE:
		return false
	# 명시적 제외 목록 (씬 파일명)
	if level.level_path.get_file() in excluded_stages:
		return false
	return true

# 현재 트리에 살아있는 Level 노드를 반환 (전환 중 freed된 이전 레벨은 제외)
func _get_current_level() -> Level:
	for node in get_tree().get_nodes_in_group("current_level"):
		if node is Level and node.is_inside_tree() and not node.is_queued_for_deletion():
			return node
	return null

# 붙잡힌 코니알의 로컬 플레이어를 찾아 같은 ahen 음성을 동시에 재생
func _sync_bound_konial(line: AudioStream) -> void:
	var konial_player := get_tree().get_first_node_in_group("bind_konial_ahen")
	if konial_player and konial_player.has_method("play_synced"):
		konial_player.play_synced(line)

# 현재 방송 주기 모드를 오디오 설정에서 읽어온다 (미설정 시 표준).
# 일반 방송과 신음(ahen) 방송에 동일하게 적용된다.
func get_interval_mode() -> String:
	return ConfigFileHandler.config.get_value("audio", INTERVAL_MODE_KEY, INTERVAL_MODE_STANDARD)

# 방송 주기 모드를 저장한다. 다음 대기 주기부터 즉시 반영된다.
func set_interval_mode(mode: String) -> void:
	ConfigFileHandler.save_audio_setting(INTERVAL_MODE_KEY, mode)

# 현재 모드에 따른 주기 배수. off는 대기 후 건너뛰므로 표준 배수로 둔다.
func _interval_mult() -> float:
	return LONG_INTERVAL_MULT if get_interval_mode() == INTERVAL_MODE_LONG else 1.0
