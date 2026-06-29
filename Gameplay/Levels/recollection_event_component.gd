extends EventComponent

@export var recollect_rect: RecollectionRect
@export_category("Debug")

func _ready() -> void:
	if Constants.RECOLLECTION_ALL_UNLOCK:
		push_warning("Debug 회상 전부 해금 : 테스트 종료 후 체크 해제해 주세요.")
	recollect_rect.unlocked_events = MetaProgression.get_all_recollection_events_grouped_by_npc()
	GameEvents.quest_process.connect(_on_quest_process)
	recollect_rect.h_window_close.connect(_on_h_window_close)
	call_deferred("set_hud_hide")
	call_deferred("call_dialogic")

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
