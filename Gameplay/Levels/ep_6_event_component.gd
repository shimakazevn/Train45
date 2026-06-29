extends EventComponent

@export var pazuzu_cam : PhantomCamera2D
const EPILOGUE_STAGE_PATH:= "res://Gameplay/Levels/credit_stage.tscn"
@onready var black_screen: CanvasLayer = %BlackScreen

func _ready():
	GameEvents.quest_process.connect(_on_quest_process)
	Dialogic.signal_event.connect(_on_signal_event)

func _on_talk_1_area_body_entered(_body: Node2D) -> void:
	dialog_start("chapter6_complete")
	GameEvents.emit_npc_flip(GameEvents.NpcTypes.PAZUZU, true)
	pazuzu_cam.set_priority(100)

func _on_signal_event(arg: String):
	match arg:
		"chapter6_go_mainmenu":
			go_main_menu()
		"go_epilogue":
			black_screen.visible = true
			go_epilogue()

func go_main_menu():
	TransitionScreen.transition_white()
	await TransitionScreen.on_transition_finishied
	DropItem.exiting_to_menu = true # 씬 해체 중 드롭아이템 _exit_tree 보상 발사 방지
	get_tree().change_scene_to_file("res://Gameplay/main_menu.tscn")

func go_epilogue():
	GameEvents.emit_set_change_stage(EPILOGUE_STAGE_PATH)
