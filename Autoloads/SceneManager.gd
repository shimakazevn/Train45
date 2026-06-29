extends Node

## [KR] SceneManager는 하나의 씬([Node])을 로드하고 다른 씬을 언로드하는 간단한 한 줄 호출을 제공하는 클래스입니다.
## [KR] 로딩 진행 상황을 모니터링하여 로딩 바로 표시할 수 있으며, 씬 전환 시 선택적 트랜지션을 제공합니다.
## [KR] 씬에 [method get_data], [method receive_data], [method init_scene], [method start_scene]을
## [KR] 구현하면 씬 간 데이터 핸드오프가 가능합니다 (자세한 내용은
## [KR] [method _on_content_finished_loading] 참조). [br][br]
## [KR] 주요 용도는 메인 화면 간 전환(시작/게임플레이/게임오버)이나 레벨 간 전환입니다.
## [KR] 적 스폰, 총알 등 빈번한 에셋 로딩이 아닌 상위 레벨 게임 관리에 사용하세요. [br][br]
## [KR] [b]설계 의도:[/b] v1.0에서 단순히 SceneTree를 교체하던 방식 대신, 콘텐츠가 로드될 위치를
## [KR] 지정할 수 있도록 개선했습니다. 클래스 타입 체크를 제거하고 [code]has_method[/code] 검사를
## [KR] 도입하여, 로드되는 씬이 SceneManager 수정 없이 로딩 과정에 선택적으로 반응할 수 있습니다.
## [KR] 시그널을 통해 로딩 중 다양한 시점에서 SceneTree를 자유롭게 관리할 수 있습니다. [br][br]
## [KR] [b]주의사항:[/b] [ResourceLoader]를 활용하지만 동시 스레드 로딩은 지원하지 않습니다.
## [KR] 로딩 진행 중 새 요청은 무시됩니다. 빠른 연속 호출이 우려되는 경우
## [KR] [code]_loading_in_progress == true[/code] 확인 후
## [KR] [code]await SceneManager.load_complete[/code]를 사용하세요.
## [EN] SceneManager is a class that provides a simple one-line call to load one scene ([Node]) and unload another.
## [EN] It monitors loading progress for loading bar display and offers optional transitions on scene change.
## [EN] Implement [method get_data], [method receive_data], [method init_scene], [method start_scene] on scenes
## [EN] for scene-to-scene data handoff (see [method _on_content_finished_loading] for details). [br][br]
## [EN] Main use cases are main screen transitions (start/gameplay/game over) or level-to-level transitions.
## [EN] Use for high-level game flow, not frequent asset loading like enemy spawns or bullets. [br][br]
## [EN] [b]Design intent:[/b] Improved from v1.0's simple SceneTree replacement to allow specifying where
## [EN] content loads. Removed class type checks and introduced [code]has_method[/code] checks so loaded scenes
## [EN] can optionally participate in loading without modifying SceneManager. Signals allow free SceneTree
## [EN] management at various points during loading. [br][br]
## [EN] [b]Note:[/b] Uses [ResourceLoader] but does not support concurrent thread loading. New requests during
## [EN] loading are ignored. For rapid successive calls, check [code]_loading_in_progress == true[/code] and
## [EN] use [code]await SceneManager.load_complete[/code].

## [KR] 레벨(뷰포트)의 높이 - 젤다 스타일 전환에서만 사용
## [EN] Level (viewport) height - used only for Zelda-style transitions
const LEVEL_H:int = 360
## [KR] 레벨(뷰포트)의 너비 - 젤다 스타일 전환에서만 사용
## [EN] Level (viewport) width - used only for Zelda-style transitions
const LEVEL_W:int = 640
## [KR] SceneManager+의 버전 번호
## [EN] SceneManager+ version number
const VERSION:String = "1.1"

## [KR] 에셋 로딩이 시작될 때 발생하는 시그널. [param loading_screen]은 로딩 화면 인스턴스
## [EN] Emitted when asset loading starts. [param loading_screen] is the loading screen instance
signal load_start(loading_screen)
## [KR] 에셋이 SceneTree에 추가된 직후, 트랜지션 애니메이션 완료 전에 발생하는 시그널
## [EN] Emitted right after asset is added to SceneTree, before transition animation completes
signal scene_added(loaded_scene:Node,loading_screen)
## [KR] 로딩이 완료되고 모든 전환 과정이 끝났을 때 발생하는 시그널
## [EN] Emitted when loading is complete and all transition processes have finished
signal load_complete(loaded_scene:Node)

## [KR] 내부용 - 콘텐츠 로드 완료 후 최종 데이터 전달 및 트랜지션 아웃이 시작될 때 발생
## [EN] Internal - Emitted when content load completes and final data handoff/transition out begins
signal _content_finished_loading(content)
## [KR] 내부용 - 유효하지 않은 콘텐츠 로드 시도 시 발생 (에셋이 존재하지 않거나 경로가 잘못된 경우)
## [EN] Internal - Emitted on invalid content load attempt (asset doesn't exist or path is wrong)
signal _content_invalid(content_path:String)
## [KR] 내부용 - 로딩이 시작되었으나 완료에 실패했을 때 발생
## [EN] Internal - Emitted when loading started but failed to complete
signal _content_failed_to_load(content_path:String)

## [KR] 로딩 화면 [PackedScene] 참조
## [EN] Loading screen [PackedScene] reference
var _loading_screen_scene:PackedScene = preload("res://Menus/loading_screen.tscn")
## [KR] 내부용 - 로딩 화면 인스턴스 참조
## [EN] Internal - Loading screen instance reference
var _loading_screen:LoadingScreen
## [KR] 내부용 - 현재 로드에 사용 중인 트랜지션 종류
## [EN] Internal - Transition type currently used for loading
var _transition:String
## [KR] 내부용 - 젤다 스타일 전환 방향. [code]Vector2.UP/RIGHT/DOWN/LEFT[/code]만 허용.
## [KR] [method swap_scenes_zelda] 호출 시 전달됨
## [EN] Internal - Zelda-style transition direction. Only [code]Vector2.UP/RIGHT/DOWN/LEFT[/code] allowed.
## [EN] Passed when [method swap_scenes_zelda] is called
var _zelda_transition_direction:Vector2
## [KR] 내부용 - SceneManager가 로드하려는 에셋의 경로를 저장
## [EN] Internal - Stores path of asset SceneManager is loading
var _content_path:String
## [KR] 내부용 - 로딩 진행 상황을 확인하는 데 사용하는 [Timer]
## [EN] Internal - [Timer] used to poll loading progress
var _load_progress_timer:Timer
## [KR] 내부용 - 새 씬이 로드될 [Node]. [code]null[/code]이면 [code]get_tree().root[/code]가 기본값
## [EN] Internal - [Node] where new scene will load. [code]null[/code] defaults to [code]get_tree().root[/code]
var _load_scene_into:Node
## [KR] 내부용 - 언로드할 [Node]. [code]null[/code]을 전달하면 언로드 과정을 건너뛰고 새 씬만 추가함.
## [KR] 대부분의 경우 두 씬 간 교체에 사용되지만, 언로드 생략 시 부작용 가능성이 있으므로 주의하여 사용
## [EN] Internal - [Node] to unload. [code]null[/code] skips unload and only adds new scene.
## [EN] Usually used for swapping two scenes; use with caution when skipping unload as side effects may occur
var _scene_to_unload:Node
## [KR] 내부용 - SceneManager가 동시에 두 개의 에셋을 로드하는 것을 방지하는 잠금 플래그
## [EN] Internal - Lock flag preventing SceneManager from loading two assets concurrently
var _loading_in_progress:bool = false

## [KR] 내부 시그널을 연결하는 초기화 함수
## [EN] Initialization function that connects internal signals
func _ready() -> void:
	_content_invalid.connect(_on_content_invalid)
	_content_failed_to_load.connect(_on_content_failed_to_load)
	_content_finished_loading.connect(_on_content_finished_loading)

## [KR] 내부용 - 로딩 화면을 [code]root[/code]에 추가합니다. [br]
## [KR] 로딩 화면 위치를 변경하려면 [signal scene_added] 및 [signal load_complete] 시그널을
## [KR] 수신하여 적절히 재배치하세요. [br][br]
## [KR] [b]설계 의도:[/b] SceneManager에 로딩 화면 위치 속성을 추가하는 대신 시그널 기반으로 설계하여,
## [KR] 각 프로젝트에서 SceneManager 수정 없이 SceneTree를 자유롭게 관리할 수 있습니다. [br][br]
## [KR] [codeblock]
## [KR]	func _on_load_start(_loading_screen):
## [KR]		# HUD를 로딩 화면 위에 유지
## [KR]		_loading_screen.reparent(self)
## [KR]		move_child(_loading_screen, hud.get_index())
## [KR] [/codeblock]
## [EN] Internal - Adds loading screen to [code]root[/code]. [br]
## [EN] To change loading screen position, receive [signal scene_added] and [signal load_complete] signals
## [EN] and reposition as needed. [br][br]
## [EN] [b]Design intent:[/b] Signal-based design instead of adding loading screen position to SceneManager,
## [EN] so each project can manage SceneTree freely without modifying SceneManager. [br][br]
## [EN] [codeblock]
## [EN]	func _on_load_start(_loading_screen):
## [EN]		# Keep HUD above loading screen
## [EN]		_loading_screen.reparent(self)
## [EN]		move_child(_loading_screen, hud.get_index())
## [EN] [/codeblock]
func _add_loading_screen(transition_type:String="fade_to_black", chapter_change: int = -1):
	# using "no_in_transition" as the transition name when skipping a transition felt... weird
	# dunno if this solution is better, but it's only one line so I can live with this one-off
	# An alternative would be to store strating animations in a dictionary and swap them for the animation name
	# it removes this one-off, but adds a step elsewhere - all about preference.
	_transition = "no_to_transition" if transition_type == "no_transition" else transition_type
	_loading_screen = _loading_screen_scene.instantiate() as LoadingScreen
	get_tree().root.add_child(_loading_screen)
	_loading_screen.start_transition(_transition, chapter_change)
	
## [KR] 가장 일반적인 공개 메서드로, 두 씬(에셋) 간 페이드 등의 트랜지션 전환에 사용됩니다. [br]
## [KR] 로딩 화면을 표시하면서 비동기로 씬을 교체합니다. [br][br]
## [KR] [param scene_to_load] - 로드할 리소스 경로 [String] [br]
## [KR] [param load_into] - 리소스를 로드할 [Node]. [code]null[/code]이면 [code]get_tree().root[/code] 사용 [br]
## [KR] [param scene_to_unload] - 언로드할 씬 [Node]. [code]null[/code]이면 언로드 과정 생략 (주의하여 사용) [br]
## [KR] [param transition_type] - 트랜지션 이름 [String]. [Door] 클래스 상단 참조 [br]
## [KR] [param chapter_change] - 챕터 전환 인덱스. [code]-1[/code]이면 챕터 전환 없음
## [EN] Most common public method; used for transition changes (e.g. fade) between two scenes (assets). [br]
## [EN] Replaces scene asynchronously while showing loading screen. [br][br]
## [EN] [param scene_to_load] - Resource path to load [String] [br]
## [EN] [param load_into] - [Node] to load resource into. [code]null[/code] uses [code]get_tree().root[/code] [br]
## [EN] [param scene_to_unload] - Scene [Node] to unload. [code]null[/code] skips unload (use with caution) [br]
## [EN] [param transition_type] - Transition name [String]. See [Door] class top [br]
## [EN] [param chapter_change] - Chapter transition index. [code]-1[/code] means no chapter change
func swap_scenes(scene_to_load:String, load_into:Node=null, scene_to_unload:Node=null, transition_type:String="fade_to_black", chapter_change: int = -1) -> void:
	
	if _loading_in_progress:
		push_warning("SceneManager is already loading something")
		return
	
	_loading_in_progress = true
	if load_into == null: load_into = get_tree().root
	_load_scene_into = load_into
	_scene_to_unload = scene_to_unload
	
	_add_loading_screen(transition_type, chapter_change)
	_load_content(scene_to_load)	

## [KR] [method swap_scenes]의 변형으로, 씬 간 젤다 던전 스타일 슬라이딩 전환을 수행합니다. [br]
## [KR] 열차 칸 사이의 이동에 사용되며, 로딩 화면 없이 바로 슬라이드합니다. [br][br]
## [KR] [b]참고:[/b] 모든 레벨이 동일한 크기([member LEVEL_H], [member LEVEL_W])라고 가정합니다.
## [KR] 레벨 크기가 다른 경우 이 메서드와 [method _on_content_finished_loading]의 트윈을
## [KR] 수정해야 합니다. [br][br]
## [KR] [param scene_to_load] - 로드할 씬의 리소스 경로 [br]
## [KR] [param load_into] - 씬을 로드할 부모 [Node] [br]
## [KR] [param scene_to_unload] - 슬라이드 아웃할 현재 씬 [br]
## [KR] [param move_dir] - 전환 방향 ([code]Vector2.UP/RIGHT/DOWN/LEFT[/code])
## [EN] Variant of [method swap_scenes]; performs Zelda dungeon-style sliding transition between scenes. [br]
## [EN] Used for movement between train cars; slides immediately without loading screen. [br][br]
## [EN] [b]Note:[/b] Assumes all levels have the same size ([member LEVEL_H], [member LEVEL_W]).
## [EN] If level sizes differ, modify tweens in this method and [method _on_content_finished_loading]. [br][br]
## [EN] [param scene_to_load] - Resource path of scene to load [br]
## [EN] [param load_into] - Parent [Node] to load scene into [br]
## [EN] [param scene_to_unload] - Current scene to slide out [br]
## [EN] [param move_dir] - Transition direction ([code]Vector2.UP/RIGHT/DOWN/LEFT[/code])
func swap_scenes_zelda(scene_to_load:String, load_into:Node, scene_to_unload:Node, move_dir:Vector2) -> void:
	
	if _loading_in_progress:
		push_warning("SceneManager is already loading something")
		return

	# [KR] swap_scenes와 동일하게 동시 전환을 막는 락을 건다.
	# [KR] 젤다 전환(열차칸 이동)은 가장 빈번한 경로라, 락이 없으면 2초 슬라이드 도중
	# [KR] 들어온 다른 전환이 로더 상태를 덮어써 로딩이 꼬이고 멈춤/튕김으로 이어진다.
	_loading_in_progress = true
	_transition = "zelda"
	_load_scene_into = load_into
	_scene_to_unload = scene_to_unload
	
	## [KR] 열차 이동을 위한 좌표 지정
	## [EN] Set coordinates for train movement
	_scene_to_unload.position.x -= 1280
	_zelda_transition_direction = move_dir
	_load_content(scene_to_load)

## [KR] 내부용 - 콘텐츠 로딩을 초기화합니다. [method swap_scenes]와 [method swap_scenes_zelda]에서
## [KR] 공통으로 사용되는 코드를 분리한 함수입니다. [br][br]
## [KR] [b]설계 의도:[/b] [code]ResourceLoader.load_threaded_request()[/code]를 통해 비동기 로딩을 시작하고,
## [KR] [member _load_progress_timer]로 로딩 상태를 주기적으로 폴링합니다.
## [KR] 젤다 전환과 일반 전환의 처리를 통합하는 것은 향후 버전에서 개선 예정입니다.
## [EN] Internal - Initializes content loading. Extracted shared logic from [method swap_scenes] and [method swap_scenes_zelda]. [br][br]
## [EN] [b]Design intent:[/b] Starts async loading via [code]ResourceLoader.load_threaded_request()[/code],
## [EN] polls loading status periodically with [member _load_progress_timer].
## [EN] Unifying Zelda and general transition handling is planned for a future version.
func _load_content(content_path:String) -> void:
	
	load_start.emit(_loading_screen)
	
	# zelda transition doesn't use a loading screen
	if _transition != "zelda":
		await _loading_screen.transition_in_complete
		
	_content_path = content_path
	var loader = ResourceLoader.load_threaded_request(content_path)
	if not ResourceLoader.exists(content_path) or loader == null:
		_content_invalid.emit(content_path)
		return 		
	
	_load_progress_timer = Timer.new()
	_load_progress_timer.wait_time = 0.1
	_load_progress_timer.timeout.connect(_monitor_load_status)
	
	get_tree().root.add_child(_load_progress_timer)		# NEW > insert loading bar into?
	_load_progress_timer.start()

## [KR] 내부용 - 로딩 상태를 주기적으로 확인합니다. [br]
## [KR] [b]설계 의도:[/b] [code]while[/code] 루프 대신 [Timer]를 사용하는 이유는,
## [KR] 루프가 너무 빠르게 실행되어 로딩 화면 표시를 건너뛸 수 있기 때문입니다.
## [EN] Internal - Periodically checks loading status. [br]
## [EN] [b]Design intent:[/b] Uses [Timer] instead of [code]while[/code] loop because
## [EN] the loop can run too fast and skip displaying the loading screen.
func _monitor_load_status() -> void:
	var load_progress = []
	var load_status = ResourceLoader.load_threaded_get_status(_content_path, load_progress)

	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_content_invalid.emit(_content_path)
			_load_progress_timer.stop()
			return
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if _loading_screen != null:
				_loading_screen.update_bar(load_progress[0] * 100) # 0.1
		ResourceLoader.THREAD_LOAD_FAILED:
			_content_failed_to_load.emit(_content_path)
			_load_progress_timer.stop()
			return
		ResourceLoader.THREAD_LOAD_LOADED:
			_load_progress_timer.stop()
			_load_progress_timer.queue_free()
			_content_finished_loading.emit(ResourceLoader.load_threaded_get(_content_path).instantiate())
			return # this last return isn't necessary but I like how the 3 dead ends stand out as similar

## [KR] 내부용 - 콘텐츠 로딩이 시작되었으나 완료에 실패했을 때 호출됩니다.
## [EN] Internal - Called when content loading started but failed to complete.
func _on_content_failed_to_load(path:String) -> void:
	printerr("error: Failed to load resource: '%s'" % [path])	

## [KR] 내부용 - 유효하지 않은 콘텐츠 로드 시도 시 호출됩니다 (콘텐츠가 존재하지 않거나 경로가 잘못된 경우).
## [EN] Internal - Called on invalid content load attempt (content doesn't exist or path is wrong).
func _on_content_invalid(path:String) -> void:
	printerr("error: Cannot load resource: '%s'" % [path])
	
## [KR] 내부용 - 콘텐츠 로딩 완료 시 호출됩니다. 데이터 전달, 수신 씬 추가, 송신 씬 제거,
## [KR] 젤다 전환 처리(해당 시), 트랜지션 아웃 완료 대기를 담당합니다. [br]
## [KR] SceneTree 관리를 위한 시그널도 이 함수에서 발생합니다. [br][br]
## [KR] [b]시그널 활용 예시:[/b] [br]
## [KR] [signal load_start] - 로딩 화면이 트리에 추가되는 즉시 발생 (예: 효과음 재생) [br]
## [KR] [signal scene_added] - 수신 씬이 트리에 추가된 후 발생. 트랜지션 완료 전이므로 초기화에 유용 [br]
## [KR] [signal load_complete] - 모든 과정 완료 후 발생. 플레이어에게 컨트롤 반환 시 사용 [br][br]
## [KR] [b]씬이 선택적으로 구현할 수 있는 핸드오프 프로토콜 메서드:[/b] [br]
## [KR] [code]get_data()[/code] - 송신 씬이 전달할 데이터를 노출 [br]
## [KR] [code]receive_data()[/code] - 수신 씬이 데이터를 받아 처리. 데이터 타입 검증 권장 [br]
## [KR] [code]init_scene()[/code] - 트리 추가 후 초기화 실행 ([code]receive_data[/code] 데이터 기반 설정 등) [br]
## [KR] [code]start_scene()[/code] - 로딩과 트랜지션 모두 완료 후 씬 시작 (예: 플레이어 컨트롤 활성화) [br][br]
## [KR] 구현 예시는 [Level] 참조
## [EN] Internal - Called when content loading completes. Handles data handoff, adding incoming scene, removing outgoing scene,
## [EN] Zelda transition (when applicable), and waiting for transition out to finish. [br]
## [EN] Signals for SceneTree management are also emitted from this function. [br][br]
## [EN] [b]Signal usage examples:[/b] [br]
## [EN] [signal load_start] - Emitted immediately when loading screen is added to tree (e.g. play sound effect) [br]
## [EN] [signal scene_added] - Emitted after incoming scene is added to tree. Before transition completes, useful for init [br]
## [EN] [signal load_complete] - Emitted after all processes complete. Use when returning control to player [br][br]
## [EN] [b]Optional handoff protocol methods scenes can implement:[/b] [br]
## [EN] [code]get_data()[/code] - Outgoing scene exposes data to pass [br]
## [EN] [code]receive_data()[/code] - Incoming scene receives and processes data. Type validation recommended [br]
## [EN] [code]init_scene()[/code] - Runs init after tree add (e.g. setup based on [code]receive_data[/code] data) [br]
## [EN] [code]start_scene()[/code] - Starts scene after loading and transition complete (e.g. enable player control) [br][br]
## [EN] See [Level] for implementation example
func _on_content_finished_loading(incoming_scene) -> void:
	var outgoing_scene = _scene_to_unload	# NEW > can't use current_scene anymore
	if outgoing_scene is Level:
		outgoing_scene.train_standard.globalLight.enabled = false
	
	# if our outgoing_scene has data to pass, give it to our incoming_scene
	if outgoing_scene != null:	
		if outgoing_scene.has_method("get_data") and incoming_scene.has_method("receive_data"):
			incoming_scene.receive_data(outgoing_scene.get_data())
	
	# load the incoming into the designated node
	_load_scene_into.add_child(incoming_scene)
		# listen for this if you want to perform tasks on the scene immeidately after adding it to the tree
	# ex: moveing the HUD back up to the top of the stack
	scene_added.emit(incoming_scene,_loading_screen)
	
#	This block is only used by the zelda transition, which is a special case that doesn't use the loading screen
	if _transition == "zelda":
		# slide new level in
		# [KR] 무조건 오른쪽으로 이동하기 때문에 임시로 1을 넣음 / [EN] Temporarily use 1 because it always moves right
		
		incoming_scene.position.x = 1 * LEVEL_W
		incoming_scene.position.y = _zelda_transition_direction.y * LEVEL_H
		
		
		var tween_in:Tween = get_tree().create_tween()
		tween_in.tween_property(incoming_scene, "position", Vector2.ZERO, 2).set_trans(Tween.TRANS_SINE)

		# slide old level out
		var tween_out:Tween = get_tree().create_tween()
		var vector_off_screen:Vector2 = Vector2.ZERO
		vector_off_screen.x = (-1 * LEVEL_W) - 1280
		vector_off_screen.y = -_zelda_transition_direction.y * LEVEL_H
		tween_out.tween_property(outgoing_scene, "position", vector_off_screen, 2).set_trans(Tween.TRANS_SINE)
	#	# once the tweens are done, do some cleanup
		await tween_in.finished
	
		# Remove the old scene
	if _scene_to_unload != null:
		if _scene_to_unload != get_tree().root: 
			_scene_to_unload.queue_free()
	
	# called right after scene is added to tree (presuming _ready has fired)
	# ex: do some setup before player gains control (I'm using it to position the player) 
	if incoming_scene.has_method("init_scene"): 
		incoming_scene.init_scene()
	
	# probably not necssary since we split our _content_finished_loading but it won't hurt to have an extra check
	if _loading_screen != null:
		_loading_screen.finish_transition()
		
		# Wait or loading animation to finish
		await _loading_screen.anim_player.animation_finished

	# if your incoming scene implements init_scene() > call it here
	# ex: I'm using it to enable control of the player (they're locked while in transition)
	if incoming_scene.has_method("start_scene"): 
		incoming_scene.start_scene()
	
	# load is complete, free up SceneManager to load something else and report load_complete signal
	_loading_in_progress = false
	load_complete.emit(incoming_scene)
