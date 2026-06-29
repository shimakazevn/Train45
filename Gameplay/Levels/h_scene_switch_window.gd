extends Control
class_name HSceneSwitchWindow

signal h_window_close

var h_scene_data := HSceneData.new()
var h_scene_res_array: Array = []
var unlocked_events: Dictionary

@export var h_scene_window_component: HSceneWindowComponent
@onready var recollection_container: GridContainer = %RecollectionContainer
@onready var scroll_container: ScrollContainer = $MarginContainer/ScrollContainer

@export var recollection_button: PackedScene
@export var Npcs : Array[Npc] = []
@export var player: Player
var player_base_position: Vector2

func _ready() -> void:
	GameEvents.h_event_end.connect(_on_h_event_end)
	hide()
	h_scene_res_array = TrainUtil.get_res_from_path(h_scene_data.H_SCENE_DATA_PATH)
	
	for child in recollection_container.get_children():
		child.queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc") and self.visible:
		exit_window()
		get_viewport().set_input_as_handled()

func exit_window():
	# 창 안에 있는 h씬 리스트를 제거
	for i in recollection_container.get_children():
		i.queue_free()
	h_window_close.emit()
	hide()
	pause_game(false)
	GameEvents.set_window_state(Constants.WINDOW_STATE_SAFE_STAGE_H_ACTION, false)
	all_npc_show()

##이벤트 컴포넌트에서 함수를 실행해 해당 엔피씨의 h씬이 들은 데이터를 참조해 창을 연다
func set_open_recollect(npc_type: Constants.NpcTypes):
	pause_game(true)
	show()
	else_npc_hide(npc_type)
	player_base_position = player.position
	
	
	var current_h_array: Array[HSceneRes] = get_npc_info(npc_type)
	for i in current_h_array:
		var recollection_button_instance = recollection_button.instantiate() as RecollectionButton
		recollection_button_instance.h_res_info = i
		
		if recollection_button_instance.h_res_info.is_disabled: #해당 h씬 미공개일 경우 넘어감
			print("This scene has not appeared in-game yet : " + str(recollection_button_instance.h_res_info.scene_description))
			continue
		
		if unlocked_events.has(i.partner):
			if unlocked_events[i.partner].has(i.scene_name):
				recollection_button_instance.is_locked = false
			else:
				recollection_button_instance.is_locked = true
		else:
			recollection_button_instance.is_locked = true
		##DebugMode
		if Constants.RECOLLECTION_ALL_UNLOCK:
			recollection_button_instance.is_locked = false

		print("Scene added : " + str(recollection_button_instance.h_res_info.scene_description) + " Unlocked : " + str(!recollection_button_instance.is_locked))
		
		recollection_container.add_child(recollection_button_instance)
		recollection_button_instance.h_scene_play.connect(_on_h_scene_play)
		
	recollection_container.get_child(0).grab_focus()
	scroll_container.scroll_vertical = 0 ## 스크롤을 제일 위로 올린다
	GameEvents.set_window_state(Constants.WINDOW_STATE_SAFE_STAGE_H_ACTION, true)

##대상이 아닌 히로인들 hide
func else_npc_hide(npc_type: Constants.NpcTypes):
	for i in Npcs:
		if not is_instance_valid(i):
			continue
	
		if i.npc_name == npc_type:
			i.show()
		else:
			i.hide()

func all_npc_show():
	for i in Npcs:
		if not is_instance_valid(i):
			continue
		
		i.show()

func get_npc_info(npc_types: Constants.NpcTypes)-> Array[HSceneRes]:
	var current_h_array: Array[HSceneRes] = []
	for npc_h_data in h_scene_res_array:
		if (npc_h_data as HSceneRes).partner == npc_types:
			current_h_array.append(npc_h_data)
	return current_h_array

func set_current_npc_camera(npc_types: Constants.NpcTypes, priority: int):
	for i in Npcs:
		if not is_instance_valid(i):
			continue
		if i.npc_name == npc_types:
			i.npc_camera.set_priority(priority)

func _on_h_scene_play(npc_type: int):
	hide()
	pause_game(false)
	set_current_npc_camera(npc_type, 100) #타켓 히로인에게 카메라를 넘긴다

func _on_h_event_end(npc_type: int, free_action_component: HSceneFreeActionComponent):
	if h_scene_window_component:
		if not h_scene_window_component.current_base_h_mode_on: # h모드가 아닐때는 해당 함수 실행하지 않음
			return
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finishied
	free_action_component.free_sprite()
	set_current_npc_camera(npc_type, 0) #h씬을 끝내면 카메라를 원래대로 돌린다
	GameEvents.game_state_change(Constants.STATE_NORMAL)
	player.show()
	player.position = player_base_position
	pause_game(true)
	show()
	recollection_container.get_child(0).grab_focus()


func pause_game(pause: bool):
	get_tree().paused = pause
