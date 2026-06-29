extends EventComponent

@export var player: Player

enum {CUT_NEWS1, CUT_NEWS2, CUT_SHOW_REINA, CUT_NEWS3, CUT_SHOW_MAI, CUT_SHOW_BUTLER, CUT_SHOW_KONIAL}

##씬 테스트할때 변경해서 테스트 가능, 기본값 0
var player_loop:= 0

const PLAYER_START_POSITION :Vector2 = Vector2(43, 338)
@export var cutscene_anim: AnimationPlayer
@export var credit_screen: CreditCanvas
@export var save_scene: PackedScene
@onready var save_sreen_canvas: CanvasLayer = %SaveSreenCanvas
@export var cut_cam1: PhantomCamera2D
@export var cut_cam2: PhantomCamera2D
@export var cut_cam3: PhantomCamera2D
@export var cut_cam4: PhantomCamera2D
@export var cut_cam5: PhantomCamera2D
@export var cut_cam6: PhantomCamera2D
@export var climax_music: MusicHighligter

func _ready() -> void:
	GameEvents.stage_change.connect(_on_stage_change)
	Dialogic.signal_event.connect(_on_signal_event)
	
	###test## 회상방 해제 기능 확인용 테스트
	#await get_tree().create_timer(3.0).timeout
	#Dialogic.start("epilogue_0", "ending_exit")
	
	if player_loop == 0:
		dialog_start("epilogue_0", "epilogue_flashback1")
	
	GameEvents.emit_join_epilogue()
	player.set_find_lock(true)
	

func _on_stage_change():
	credit_screen.credit_screen_play(player_loop)
	background_change()


func _on_talk_1_area_body_entered(body: Node2D) -> void:
	if player_loop == CUT_NEWS1 and body is Player:
		dialog_start("epilogue_0", "news_0")

func _on_talk_2_area_body_entered(body: Node2D) -> void:
	if player_loop == CUT_NEWS2 and body is Player:
		dialog_start("epilogue_0", "news_1")

func _on_meet_reina_area_body_entered(body: Node2D) -> void:
	if player_loop == CUT_SHOW_REINA and body is Player:
		cut_cam1.set_priority(100)
		dialog_start("epilogue_0", "meet_reina")

func _on_talk_3_area_body_entered(body: Node2D) -> void:
	if player_loop == CUT_NEWS3 and body is Player:
		dialog_start("epilogue_0", "news_2")


func _on_meet_mai_area_body_entered(body: Node2D) -> void:
	if player_loop == CUT_SHOW_MAI and body is Player:
		cut_cam2.set_priority(100)
		dialog_start("epilogue_0", "meet_mai")

func _on_talk_4_area_body_entered(body: Node2D) -> void:
	if player_loop == CUT_SHOW_BUTLER and body is Player:
		cut_cam3.set_priority(100)
		dialog_start("epilogue_0", "meet_butler")

func _on_meet_konial_area_body_entered(body: Node2D) -> void:
	if player_loop == CUT_SHOW_KONIAL and body is Player:
		dialog_start("epilogue_0", "meet_konial")



func _on_signal_event(arg: String):
	match arg:
		"credit_next_loop":
			if cut_cam1.is_active():
				cut_cam1.set_priority(0)
			if cut_cam2.is_active():
				cut_cam2.set_priority(0)
			if cut_cam3.is_active():
				cut_cam3.set_priority(0)
			go_start_line()
		"credit_ending_save":
			set_save_screen()
		"credit_go_mainmenu":
			go_main_menu()
		"epilogue_cut1_2":
			cutscene_anim.play("credit_cut1_2")
		"epilogue_cut1_3":
			cutscene_anim.play("credit_cut1_3")
		"epilogue_cut1_4":
			cutscene_anim.play("credit_cut1_4")
		"epilogue_cut2_2":
			cutscene_anim.play("credit_cut2_2")
		"epilogue_cut2_3":
			cutscene_anim.play("credit_cut2_3")
		"epilogue_cut2_4":
			cutscene_anim.play("credit_cut2_4")
		"epilogue_cut3_2":
			cutscene_anim.play("credit_cut3_2")
		"epilogue_cut4_2":
			cutscene_anim.play("credit_cut4_2")
			cut_cam4.set_priority(100)
		"epilogue_cut4_3":
			cut_cam4.set_priority(0)
			cut_cam5.set_priority(100)
		"epilogue_cut4_4":
			cutscene_anim.play("credit_cut4_4")
			cut_cam5.set_priority(0)
			cut_cam6.set_priority(100)
			GameEvents.game_state_change(Constants.STATE_DONT_MOVE)
			climax_music.trigger_climax()


func _on_next_loop_area_body_entered(_body: Node2D) -> void:
	if _body is Player:
		go_start_line()


func go_start_line():
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finishied
	var ch = get_tree().get_first_node_in_group("player")
	ch.position = PLAYER_START_POSITION
	
	player_loop += 1
	background_change()

func background_change():
	credit_screen.credit_screen_play(player_loop)
	if player_loop == CUT_SHOW_REINA:
		cutscene_anim.play("credit_cut1")
	elif player_loop == CUT_SHOW_MAI:
		cutscene_anim.play("credit_cut2")
	elif player_loop == CUT_SHOW_BUTLER:
		cutscene_anim.play("credit_cut3")
	elif player_loop == CUT_SHOW_KONIAL:
		cutscene_anim.play("credit_cut4")
	else:
		cutscene_anim.play("RESET")

func set_save_screen():
	var save_scene_instance = save_scene.instantiate()
	save_sreen_canvas.add_child(save_scene_instance)
	save_scene_instance.tree_exited.connect(_on_save_menu_exited)
	
func _on_save_menu_exited():
	go_main_menu()

func go_main_menu():
	TransitionScreen.transition_white()
	await TransitionScreen.on_transition_finishied
	DropItem.exiting_to_menu = true # 씬 해체 중 드롭아이템 _exit_tree 보상 발사 방지
	get_tree().change_scene_to_file("res://Gameplay/main_menu.tscn")

func call_title_screen():
	credit_screen.final_ending_play()


func _on_ending_exit_area_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.
