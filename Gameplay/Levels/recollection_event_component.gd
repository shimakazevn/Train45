extends EventComponent

@export var recollect_rect: RecollectionRect
@export_category("Debug")

## [KR] 메뉴 복귀(트랜지션) 진행 중 여부. 중복 ESC로 call_dialogic이 여러 번 불리는 것을 막는다.
var _exiting := false

func _ready() -> void:
	if Constants.RECOLLECTION_ALL_UNLOCK:
		push_warning("Debug 회상 전부 해금 : 테스트 종료 후 체크 해제해 주세요.")
	recollect_rect.unlocked_events = MetaProgression.get_all_recollection_events_grouped_by_npc()
	GameEvents.quest_process.connect(_on_quest_process)
	recollect_rect.h_window_close.connect(_on_h_window_close)
	call_deferred("set_hud_hide")
	call_deferred("call_dialogic")

## [KR] 귀신 H 모드 로밍 중 ESC: pause 메뉴 대신 트랜지션 후 선택 메뉴로 복귀한다.
## _unhandled_input(pause 메뉴)보다 먼저 _input에서 소비해 pause 메뉴를 막는다.
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("esc"):
		return
	# 이미 메뉴 복귀(트랜지션) 중이면 추가 ESC는 소비만 하고 무시(중복 call_dialogic 방지).
	if _exiting:
		get_viewport().set_input_as_handled()
		return
	# 로밍 중일 때만(갤러리/실제 귀신 H 중에는 각자 ESC 처리).
	if not recollect_rect.ghost_h_mode_active or recollect_rect.player.is_ghost_play:
		return
	# 도감 rape 재생 중에는 무시(rape가 끝까지 재생되도록).
	if GameEvents.game_state == Constants.STATE_RAPE:
		return
	get_viewport().set_input_as_handled()
	_exit_ghost_h_to_menu()

func _exit_ghost_h_to_menu():
	_exiting = true
	# 트랜지션으로 화면을 가린 뒤(검은 화면) NPC 표시·플레이어 리셋을 처리해 팝업을 숨긴다.
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finishied
	recollect_rect.end_ghost_h_mode()
	call_dialogic()
	_exiting = false

func set_hud_hide():
	var huds: Array = get_tree().get_nodes_in_group("train45hud")
	for i in huds:
		i.queue_free()

func call_dialogic():
		dialog_start("recollect_room")

func _on_quest_process(quest_str: String):
	match quest_str:
		"recollect_reina":
			recollect_rect.set_open_recollect(Constants.NpcTypes.REINA)
		"recollect_mai":
			recollect_rect.set_open_recollect(Constants.NpcTypes.MAI)
		"recollect_konial":
			recollect_rect.set_open_recollect(Constants.NpcTypes.KONIAL)
		"recollect_butler":
			recollect_rect.set_open_recollect(Constants.NpcTypes.BUTLER)
		"recollect_pazuzu":
			recollect_rect.set_open_recollect(Constants.NpcTypes.PAZUZU)
		"recollect_ghost_h":
			recollect_rect.start_ghost_h_mode()
		"recollect_exit":
			go_main_menu()

func _on_h_window_close():
	call_dialogic()

func go_main_menu():
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finishied
	DropItem.exiting_to_menu = true # 씬 해체 중 드롭아이템 _exit_tree 보상 발사 방지
	get_tree().change_scene_to_file("res://Gameplay/main_menu.tscn")
