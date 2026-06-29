extends CanvasLayer
class_name HSceneWindowComponent

@export var recollect_rect: RecollectionRect
var unlock_h_scenes: Dictionary = {}
var current_base_h_mode_on: bool = false

func _ready() -> void:
	GameEvents.quest_process.connect(_on_quest_process)
	recollect_rect.h_window_close.connect(_on_h_window_close)

func _on_quest_process(quest_str: String):
	if not quest_str.begins_with("recollect_"):
		return
	
	TransitionScreen.transition()
	if Dialogic.current_timeline:
		Dialogic.paused = true
	if Dialogic.Text.is_textbox_visible():
		Dialogic.Text.hide_textbox()
	
	#대화창 호감도 아이콘 켜져있다면 끄기
	var dialog_love_ui = get_tree().get_first_node_in_group("dialog_love_ui") as Control
	if dialog_love_ui:
		dialog_love_ui.hide()
	
	await TransitionScreen.on_transition_finishied

	recollect_rect.unlocked_events[Constants.NPC_OL] = MetaProgression.get_npc_unlock_event_list(Constants.NPC_OL)
	recollect_rect.unlocked_events[Constants.NPC_GYARU] = MetaProgression.get_npc_unlock_event_list(Constants.NPC_GYARU)
	match quest_str:
		"recollect_reina":
			recollect_rect.set_open_recollect(Constants.NpcTypes.REINA)
			current_base_h_mode_on = true
		"recollect_mai":
			recollect_rect.set_open_recollect(Constants.NpcTypes.MAI)
			current_base_h_mode_on = true
		"recollect_exit":
			pass

func _on_h_window_close():
	if Dialogic.current_timeline:
		Dialogic.paused = false
	if not Dialogic.Text.is_textbox_visible():
		Dialogic.Text.show_textbox()
	current_base_h_mode_on = false
