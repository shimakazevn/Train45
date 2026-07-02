extends TextureRect
class_name RecollectionRect

signal h_window_close

var h_scene_data := HSceneData.new()
var h_scene_res_array: Array = []
var unlocked_events: Dictionary
var select_frame: HWindowSelectFrame

var base_postion : Vector2

@export var h_scene_window_component: HSceneWindowComponent
@onready var recollection_container: Container = %RecollectionContainer
@onready var scroll_container: ScrollContainer = %RecollectionScrollContainer
## [KR] 귀신 H 모드 안내 라벨(나가기). 귀신 H 모드일 때만 표시.
@onready var exit_label: CanvasItem = get_node_or_null("../ExitLabel")


@export var recollection_button: PackedScene
@export var Npcs : Array[Npc] = []
@export var player: Player
var player_base_position: Vector2
## 회상방 최초 진입 시 플레이어 위치. H씬 종료 후 좌석 위치로 남는 것을 막기 위해 사용
var recollection_entry_position: Vector2
var _entry_position_saved: bool = false

var current_fold: bool = false

const TICKET_MULTIPLIER = [1.2, 1.5]
var multiplier_dict: Dictionary = {
	Constants.NPC_OL: {},
	Constants.NPC_GYARU: {}
}
var multiplier_setted: bool = false

## 귀신 H 모드(로밍) 활성 여부. ESC 처리 분기에 사용.
var ghost_h_mode_active := false
## 귀신 H 모드 진입 시 끈 NPC 콜리전 레이어를 복원하기 위한 원본 값 저장.
var _npc_orig_layers := {}
## 회상방 최초 진입(메뉴) 플레이어 위치. 로드 시 1회 저장해 귀신 H 종료 시 이 위치로 리셋.
var _menu_player_pos: Vector2
## 배경 장식용 귀신 스포너(같은 씬 루트의 BGEvilSpwaner). 귀신 H 모드에서만 스폰. 없으면 무시.
var bg_evil_spawner


func _ready() -> void:
	select_frame = get_node_or_null("SelectFrame")
	base_postion = self.position
	
	GameEvents.h_event_end.connect(_on_h_event_end)
	hide()
	h_scene_res_array = TrainUtil.get_res_from_path(h_scene_data.H_SCENE_DATA_PATH)
	
	#res test
	#for res in h_scene_res_array:
		#print(res.resource_path)
	#
	
	for child in recollection_container.get_children():
		child.queue_free()

	# 선택 메뉴 단계에선 귀신을 숨긴다("귀신 H" 선택 시 다시 표시).
	# 그룹 등록이 끝난 뒤 처리하도록 지연 호출한다.
	call_deferred("_set_recollect_ghosts_visible", false)
	# 최초 진입(메뉴) 플레이어 위치를 1회 저장(스테이지 초기화 후).
	call_deferred("_capture_menu_player_pos")
	# 귀신 H 모드 안내 라벨은 평소 숨김.
	if exit_label:
		exit_label.hide()
	# 같은 씬 루트의 배경 귀신 스포너를 찾아 둔다(있을 때만).
	bg_evil_spawner = owner.get_node_or_null("BGEvilSpwaner") if owner else null

## [KR] 메뉴(최초 진입) 플레이어 위치를 1회 저장한다 — 귀신 H 종료 시 이 위치로 리셋.
func _capture_menu_player_pos() -> void:
	if player:
		_menu_player_pos = player.position


func _input(event: InputEvent) -> void:
	if not self.visible:
		return
	if event.is_action_pressed("esc"):
		if not _get_current_h_scene_playing() and not TransitionScreen.is_transition:
			exit_window()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("h_list_fold"):
		set_fold(true)

func _get_current_h_scene_playing()->bool:
	var playing_h_scene: bool = false
	for i in Npcs:
		if i:
			if i.free_action_component.is_event:
				playing_h_scene = true
				break
	return playing_h_scene

func exit_window():
	# 창 안에 있는 h씬 리스트를 제거
	for i in recollection_container.get_children():
		i.queue_free()
	h_window_close.emit()
	hide()
	pause_game(false)
	GameEvents.set_window_state(Constants.WINDOW_STATE_SAFE_STAGE_H_ACTION, false)

##이벤트 컴포넌트에서 함수를 실행해 해당 엔피씨의 h씬이 들은 데이터를 참조해 창을 연다
func set_open_recollect(npc_type: Constants.NpcTypes):
	if h_scene_window_component: # 시작 지점일 경우 정지 안함
		pass
	else: # 회상방일 경우 게임 정지
		pause_game(true)
		# 회상방 최초 진입 위치를 1회만 저장 (H씬이 플레이어를 좌석으로 옮기기 전 시점)
		if not _entry_position_saved:
			recollection_entry_position = player.position
			_entry_position_saved = true
	show()
	player_base_position = player.position

	
	var current_h_array: Array[HSceneRes] = get_npc_info(npc_type)
	for i in current_h_array:
		if i.is_disabled: #해당 h씬 미공개일 경우 넘어감
			print("This scene has not appeared in-game yet : " + str(i.scene_description))
			continue

		var recollection_button_instance = recollection_button.instantiate() as RecollectionButton
		set_npc_multiplier(npc_type, i.scene_name)
		recollection_button_instance.h_res_info = i
		if recollection_button_instance is RecollectionButtonMini:
			recollection_button_instance.bonus_ticket_multiplier = get_npc_multiplier(npc_type, i.scene_name)

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

		if recollection_button_instance is RecollectionButtonMini and recollection_button_instance.is_locked: # 잠긴 상태면 리스트에 추가 안함
			recollection_button_instance.queue_free()
		else:
			recollection_container.add_child(recollection_button_instance)
			if recollection_button_instance is RecollectionButtonMini:
				recollection_button_instance.focus_entered.connect(_on_h_button_focused.bind(recollection_button_instance))
			recollection_button_instance.h_scene_play.connect(_on_h_scene_play)
		
	if select_frame:
		select_frame.set_frame_pos(recollection_container.get_child(0).global_position)
	scroll_container.scroll_vertical = 0 ## 스크롤을 제일 위로 올린다
	scroll_container.scroll_horizontal = 0 ## 스크롤을 제일 위로 올린다
	
	_sort_h_level(recollection_container)
	GameEvents.set_window_state(Constants.WINDOW_STATE_SAFE_STAGE_H_ACTION, true)
	recollection_container.get_child(0).grab_focus()
	
	##최초 실행시 튜토리얼 출력
	if not GameEvents.is_recollection_room:
		GameEvents.emit_call_tutorial(TutoManager.TUTO_BASE_H_ACTION, recollection_container.get_child(0))

func _sort_h_level(container: Container) -> void:
	# 1. 자식들을 배열로 수집
	var buttons: Array[RecollectionButton] = []
	for child in container.get_children():
		if child is RecollectionButton:
			buttons.append(child)

	# 2. 정렬 로직
	buttons.sort_custom(func(a: RecollectionButton, b: RecollectionButton) -> bool:
		var a_main := a.h_res_info.main_love_event
		var b_main := b.h_res_info.main_love_event

		# main_love_event가 false인 쪽은 무조건 뒤로
		if a_main != b_main:
			return a_main and not b_main
			# a_main=true, b_main=false → a가 앞
			# a_main=false, b_main=true → b가 앞

		# 둘 다 true이거나 둘 다 false인 경우
		return a.h_res_info.love_ability < b.h_res_info.love_ability
	)

	# 3. 정렬된 순서대로 다시 배치
	for btn in buttons:
		container.move_child(btn, container.get_child_count())

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

## 귀신 H 모드 진입: 선택 메뉴의 NPC들을 감추고 상호작용(콜리전)을 차단해
## 플레이어가 방을 자유롭게 돌아다닐 수 있게 한다.
## 이동 자체는 game_state=STATE_NORMAL이고 타임라인이 종료되면
## player._process가 자동으로 가시화·입력을 복원하므로 별도 처리가 필요 없다.
func start_ghost_h_mode():
	ghost_h_mode_active = true
	if exit_label:
		exit_label.show()
	for i in Npcs:
		if not is_instance_valid(i):
			continue
		_npc_orig_layers[i] = i.collision_layer
		i.hide()
		# NPC는 Entity 공유 부모를 두므로 hide만으로는 can_talk_to_npc(부모 visible)를
		# 통과해 대화가 걸린다. talk_area가 감지하지 못하도록 콜리전 레이어를 끈다.
		i.set_deferred("collision_layer", 0)
	player.show()
	# 귀신 H 모드 시작 위치로 플레이어를 옮긴다.
	player.position = GhostGalleryWindow.PLAYER_BASE_POS
	# 숨겨 뒀던 귀신들을 표시한다.
	_set_recollect_ghosts_visible(true)
	# 귀신 H 시작(ghost_sex)과 차지 감지는 둘 다 find_lock==false를 요구한다.
	# 회상방은 TYPE_COMPLETE라 init_scene이 find_lock=true로 잠그므로 여기서 해제한다.
	player.set_find_lock(false)
	# 차지 탐지를 3배 빠르게, find 이펙트 크기를 감지 거리(GHOST_DETECT_RANGE 반경)에 맞춘다.
	_apply_ghost_detection_boost()
	# player.enable()이 불릴 때마다 UpgradeComponent가 스탯을 기본값으로 되돌린다(도감 H 재생 등).
	# enable 이후 부스트를 다시 적용하도록 player_enable에 연결한다.
	if not player.player_enable.is_connected(_on_player_enable_reapply_boost):
		player.player_enable.connect(_on_player_enable_reapply_boost)
	# 차지 완료(player_action) 시 스프라이트 거리 기준으로 가장 가까운 귀신을 감지한다.
	# find_anomaly는 FindArea의 단일 불리언(is_player_in_area)에 의존하는데, 귀신이 여럿이면
	# 그 불리언이 어긋나 감지가 누락된다. player_action 직접 연결로 우회한다.
	if not player.player_action.is_connected(_on_recollect_find):
		player.player_action.connect(_on_recollect_find)
	# 배경 장식용 귀신 스폰 시작.
	if bg_evil_spawner:
		bg_evil_spawner.start_spawning()

## [KR] 귀신 H 모드 감지 부스트(차지 속도 3배·가로 감지 범위 확대)를 적용한다.
func _apply_ghost_detection_boost() -> void:
	player.charge_time = player.charge_base_time / 3.0
	# 세로(Y)는 기본값을 유지하고, 가로(X)만 감지 거리에 맞춘다.
	player.find_area.set_detect_size(Vector2(GHOST_DETECT_RANGE * 2.0, player.find_area.collision_shape.size.y))

## [KR] player.enable() 시 UpgradeComponent가 call_deferred로 스탯을 리셋하므로,
## 그 뒤에 실행되도록 deferred로 부스트를 다시 적용한다(도감 H 감상 후 부스트 유지).
func _on_player_enable_reapply_boost() -> void:
	if ghost_h_mode_active:
		_apply_ghost_detection_boost.call_deferred()

## 귀신 H 모드 종료: 선택 메뉴로 돌아가기 전에 start_ghost_h_mode가 바꾼 상태를 원복한다.
func end_ghost_h_mode():
	ghost_h_mode_active = false
	if exit_label:
		exit_label.hide()
	if player.player_action.is_connected(_on_recollect_find):
		player.player_action.disconnect(_on_recollect_find)
	if player.player_enable.is_connected(_on_player_enable_reapply_boost):
		player.player_enable.disconnect(_on_player_enable_reapply_boost)
	# 귀신·플레이어를 메뉴 상태로 되돌린다.
	_set_recollect_ghosts_visible(false)
	player.is_ghost_play = false
	player.set_find_lock(true) # 회상방은 TYPE_COMPLETE 기본값
	player.position = _menu_player_pos # 최초 진입(중앙) 위치로 리셋
	player.hide()
	# NPC 표시·콜리전 복원(이후 일반 회상 재생에 지장 없도록).
	for i in Npcs:
		if not is_instance_valid(i):
			continue
		i.show()
		if _npc_orig_layers.has(i):
			i.set_deferred("collision_layer", _npc_orig_layers[i])
	# 배경 장식용 귀신 스폰 중지 및 정리.
	if bg_evil_spawner:
		bg_evil_spawner.stop_spawning()

## 회상방 귀신 감지 범위(px). 감지 시 이 안의 가장 가까운 NOT_FIND 귀신을 IN으로 만든다.
const GHOST_DETECT_RANGE := 120.0

## [KR] 이변 감지 콜백. 범위 내에서 가장 가까운 NOT_FIND 회상 귀신을 감지(IN)시킨다.
func _on_recollect_find() -> void:
	# 감지 기준점은 find 이펙트 중심(find_area)과 일치시켜 시각/감지를 정렬한다.
	var find_pos: Vector2 = player.find_area.global_position
	var nearest: GhostHAnomaly = null
	var nearest_dist := GHOST_DETECT_RANGE
	for g in get_tree().get_nodes_in_group("recollect_ghost"):
		var d: float = find_pos.distance_to(g.ghost_sprite.global_position)
		if g.current_state != GhostHAnomaly.GhostState.NOT_FIND:
			continue
		if d <= nearest_dist:
			nearest_dist = d
			nearest = g
	if nearest:
		nearest.recollect_detect()

## [KR] 회상방 귀신들(RecollectGhost 그룹)의 표시/숨김을 일괄 전환한다.
func _set_recollect_ghosts_visible(visible_state: bool) -> void:
	for g in get_tree().get_nodes_in_group("RecollectGhost"):
		g.visible = visible_state

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
	if h_scene_window_component: # 시작 지점 h 일 경우
		set_fold(true) #선택창 접기
	else: # 회상방일 경우 게임 정지 해제
		hide()
		pause_game(false)
	else_npc_hide(npc_type)
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
	all_npc_show()
	player.show()
	
	#_player_position_reset()
	show()
	recollection_container.get_child(0).grab_focus()
	
	##만약 시작지점 h일 경우 바로 종료한다
	if h_scene_window_component and h_scene_window_component.current_base_h_mode_on:
		exit_window()
	else: # 회상방일 경우 게임 일시 정지
		pause_game(true)
		# 회상방 한정: H씬이 플레이어를 좌석 위치로 옮기므로(npc.position_setting),
		# 최초 진입 위치로 되돌리고 확실히 보이게 한다
		if _entry_position_saved:
			player.position = recollection_entry_position
		player.show()
		# H씬 중 본체 스프라이트 hide + 애니메이션 stop되므로, H씬을 한 NPC를
		# idle 상태로 복원한다 (회상방은 NPC가 영구 노드라 직접 되돌려야 함)
		for i in Npcs:
			if is_instance_valid(i) and i.npc_name == npc_type:
				i.restore_to_idle()

##플레이어의 위치를 h이벤트 시작 전으로 돌린다
func _player_position_reset():
	player.position = player_base_position


func pause_game(pause: bool):
	get_tree().paused = pause


func _on_fold_button_toggled(toggled_on: bool) -> void:
	set_fold(toggled_on)

func set_fold(fold: bool):
	if current_fold == fold:
		return
	var tween: Tween = get_tree().create_tween()
	current_fold = fold
	if fold:
		tween.tween_property(self, "position:y", base_postion.y - 50, 0.8).from(base_postion.y).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.set_parallel()
		tween.tween_property($FoldButton, "rotation_degrees", 90, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(self, "position:y", base_postion.y, 0.8).from_current().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.set_parallel()
		tween.tween_property($FoldButton, "rotation_degrees", -90, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _on_h_button_focused(button: RecollectionButtonMini):
	if select_frame:
		set_fold(false)
		select_frame.set_frame_pos(button.global_position)

func set_npc_multiplier(npc_type: int, scene_name: String):
	if multiplier_dict.has(npc_type):
		if not multiplier_dict[npc_type].has(scene_name): # 만약, 이번 베이스에서 점수 배율이 정해졌을 경우, 다시 정하지 않는다.
			var multiplier: int = 0
			var rand = randf() # 0.0 ~ 1.0 사이 랜덤값
			if rand < 0.2:
				multiplier = 1
			elif rand < 0.2 + 0.1:
				multiplier = 2
			else:
				multiplier = 0
			multiplier_dict[npc_type][scene_name] = multiplier
	else:
		return

func get_npc_multiplier(npc_type: int, scene_name: String)-> int:
	var multiplier: int = 0
	if multiplier_dict.has(npc_type) and multiplier_dict[npc_type].has(scene_name):
		multiplier = multiplier_dict[npc_type][scene_name]
	return multiplier
