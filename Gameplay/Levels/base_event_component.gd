extends EventComponent

var current_chapter : int
var ticket_manager : TicketManager
var global_game_manager : GlobalGameManager
@export var entity : Node
@export var butler_packed : PackedScene
@export var konial_packed : PackedScene
@export var butler_position: Marker2D
@export var butler_human_position: Marker2D
@export var konial_position: Marker2D


func _ready() -> void:
	GameEvents.quest_process.connect(_on_quest_process)
	GameEvents.stage_change.connect(_on_stage_changed)
	current_chapter = MetaProgression.get_current_chapter()
	var current_level = get_parent() as Level
	current_level.stage_ready.connect(_on_stage_ready)
	current_level.stage_start.connect(_on_stage_start)
	ticket_manager = get_tree().get_first_node_in_group("ticketmanager")
	global_game_manager = get_tree().get_first_node_in_group("globalgamemanager")

func _on_quest_process(quest_str: String):
	match quest_str:
		"butler_change_human":
			GameEvents.emit_anim_change_this_npc("idle_2", GameEvents.NpcTypes.BUTLER)
			GameEvents.emit_npc_position_change(GameEvents.NpcTypes.BUTLER, butler_human_position.position)

## 현재 스테이지가 노드에 추가됐을 때 호출
func _on_stage_ready():
	is_over_chapter6()#챕터 6 이후부터 묶인 코니알이 시작 지점에 나타남

func _on_stage_changed():
	pass

func  _on_stage_start(): #스테이지 시작시 이벤트 발생
	is_over_chapter2() #챕터 2 이상일때 집사가 시작 지점에 나타남
	is_current_chapter3() #챕터 3시작할때 기절했다 깨어나는 이벤트
	is_current_chapter6() #챕터 6시작할때 묶인 코니알을 심문하는 이벤트

##챕터 2 이상일때 집사가 시작 지점에 나타남
func is_over_chapter2():
	if current_chapter >= 2:
		var butler_instante = butler_packed.instantiate() as Npc
		if MetaProgression.has_read_event(Constants.QUESTLINE_BUTLER_HUMAN): #집사 인간폼으로 변경
			butler_instante.call_deferred("anim_change", butler_instante.get_idle_anim_type("idle"))
			butler_instante.position = butler_human_position.position
		else:
			butler_instante.call_deferred("anim_change", butler_instante.get_idle_anim_type("idle"))
			butler_instante.position = butler_position.position
		entity.add_child(butler_instante)

##챕터 6 이후부터 묶인 코니알이 시작 지점에 나타남
func is_over_chapter6():
	if current_chapter >= 6:
		var konial_instante = konial_packed.instantiate() as Npc
		entity.add_child(konial_instante)
		call_deferred("set_bind_konial", konial_instante)

## npc가 세팅된 후에 노드 추가
func set_bind_konial(konial_instante: Npc):
	#konial_instante.call_deferred("anim_change", konial_instante.get_idle_anim_type("idle"))
	konial_instante.anim_change(konial_instante.get_idle_anim_type("idle"))
	konial_instante.position = konial_position.position

##챕터 3시작할때 기절했다 깨어나는 이벤트
func is_current_chapter3():
	start_current_chapter_event("chapter3_start", 3)

##챕터 6시작할때 묶인 코니알을 심문하는 이벤트
func is_current_chapter6():
	start_current_chapter_event("chapter6_start", 6)

## 챕터2가 시작하고 집사를 처음 마주치면 발생, 집사의 자기소개
func _on_chapter_2_butler_meet_body_entered(_body: Node2D) -> void:
	start_chapter_event("chapter2_butler", 2)

##챕터 4가 시작하고 집사를 마주치면 발생, 노선도 아이템 제작 퀘스트
func _on_chapter_4_butler_meet_body_entered(_body: Node2D) -> void:
	start_chapter_event("chapter4_butler", 4)

##챕터 4 요구 티켓과 노선도 정보를 모두 모으면 발생, 칸칸네비 기능 해금
func _on_chapter_4_butler_meet_2_body_entered(_body: Node2D) -> void:
	if current_chapter != 4:
		return
	if !MetaProgression.has_read_event("chapter4_butler"):
		return
	#금액과 스테이지 조건 확인
	if global_game_manager.main_quest_component.get_is_all_clear("quest_4"):
		start_chapter_event("chapter4_butler2", 4)

##챕터 5 시작, 지갑 획득 후 집사의 요청을 돕는다.
func _on_chapter_4_2_butler_meet_body_entered(_body: Node2D) -> void:
	start_chapter_event("chapter4_butler4", 5)


##챕터 5 집사가 티켓을 빼돌린 걸 들킴, 집사가 인간 모습으로 변한다
func _on_chapter_5_butler_meet_body_entered(_body: Node2D) -> void:
	if global_game_manager.main_quest_component.get_is_all_clear("quest_4_3"):
		start_chapter_event("chapter4_butler3", 5)
	

func _on_butler_love_quest_start_body_entered(_body: Node2D) -> void:
	if MetaProgression.has_read_event(Constants.QUESTLINE_BUTLER_HUMAN):
		start_chapter_event("butler_love_quest_start", 5)

##chapter_num이 현재 챕터가 아니면 리턴, 이미 읽은 이벤트면 호출 안됨
func start_current_chapter_event(event_name: String, chapter_num: int):
	if current_chapter != chapter_num:
		return
	if not MetaProgression.has_read_event(event_name):
			dialog_start(event_name)

func start_chapter_event(event_name: String, chapter_num: int):
	if current_chapter == chapter_num:
		if not MetaProgression.has_read_event(event_name):
			dialog_start(event_name)


func _on_before_ending_warning_body_entered(_body: Node2D) -> void:
	if MetaProgression.has_read_event(Constants.QUESTLINE_GET_ENGINE_ROOM):
		start_chapter_event("chapter6_2", 6)
