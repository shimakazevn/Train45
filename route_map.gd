## 노선도(칸칸 네비) UI를 관리하는 컨트롤러.
## 노선 슬롯 생성, 노선 대기열 편집, 종착점 처리, 노선 구매 및 확정 등을 담당한다.
extends Control
class_name RouteMap

## 노선도 등장 애니메이션이 완료되었을 때 발행된다.
signal kankan_on

@export_category("Export")
## 칸칸 네비 패널.
@onready var kankan_navi: Panel = $KanKanNavi

## 노선 슬롯 [PackedScene] 프리팹.
@export var route_slot: PackedScene
## 대기열에 표시할 노선 슬롯 [PackedScene].
@export var route_set_scene: PackedScene
## 종착점 표시용 [PackedScene].
@export var destination_rect: PackedScene
## 노선 힌트 UI 참조.
@export var route_hint: RouteHint
## 노선 구매 확인용 [ConfirmBox].
@export var confirm_box: ConfirmBox
## 발견 가능한 노선들이 배치되는 [GridContainer].
@onready var route_container: GridContainer = %RouteContainer
## 선택된 노선 대기열을 표시하는 [HBoxContainer].
@onready var route_set_container: HBoxContainer = %RouteSetContainer
## 종착점 슬롯을 담는 [Panel].
@onready var destination_container: Panel = %DestinationContainer
## 노선 확정(출발) 버튼.
@onready var route_start: Button = %RouteStart
## 노선도 튜토리얼 컴포넌트.
@onready var route_tutorial := $RouteMapTutorial

## 칸칸 네비 등장/퇴장 애니메이션 플레이어.
@onready var kankan_anim: AnimationPlayer = %KanKanAnim
## 노선도 뒤 배경 오프스크린 딤 처리.
@onready var off_screen: ColorRect = %OffScreen

## 현재 포커스된 노선 이름 라벨.
@onready var route_name_lable: Label = %RouteNameLable
## 칸칸 타이틀 Rect.
@onready var title_rect: KankanTitleRect = %TitleRect
## 칸칸 설명 라벨.
@onready var description_label: KankanDescriptionLable = %DescriptionLabel
## 확인 버블 텍스처.
@onready var confirm_bubble: TextureRect = %ConfirmBubble
## 노선도 UI 사운드 플레이어.
@onready var route_map_stream_player: UiSoundStreamPlayer = $RouteMapStreamPlayer
## 잠금 해제 비용 정보 컨테이너.
@onready var unlock_info_container: HBoxContainer = %UnlockContainer

## 보유 티켓 수 표시 라벨.
@onready var my_ticket_label: Label = %MyTicketLabel
## 코인 아이콘 텍스처.
@onready var coin_icon: TextureRect = %CoinIcon
## 보유 코인 수 표시 라벨.
@onready var my_coin_label: Label = %MyCoinLabel

## H 이벤트 정보 표시 컨테이너.
@onready var event_info_container: HBoxContainer = %EventInfoContainer
## 이벤트 파트너 아이콘 텍스처.
@onready var event_partner_texture: TextureRect = %EventPartnerTexture
## 이벤트 이름 라벨.
@onready var event_name_label: Label = %EventNameLabel


## 레벨 씬 경로 기본 상수.
const ROUTE_PATH := "res://Gameplay/Levels/"

## 현재 [FloorManager] 참조.
var floor_manager : FloorManager
## 현재 챕터의 노선 데이터.
var route_data : RouteData
## H씬 데이터 인스턴스.
var h_scene_data := HSceneData.new()
## 아이템 데이터 인스턴스.
var item_data: ItemData = ItemData.new()

## H씬 리소스 배열 (경로에서 로드).
var h_scene_res_array: Array = []
## 현재 대기열에 추가된 노선 경로 목록.
var route_set_list : Array = []
## 노선 구매 모드 활성화 여부.
var active_route_buy_mode:= false

## 등장 애니메이션이 완료되었는지 추적. 완료 전까지 인터랙션을 차단한다.
var current_start_anim_finished: bool = false

## 패드 방향키(D-pad)로 노선을 이동할 때, 키보드처럼 길게 누르면 반복 이동시키기 위한 설정.
## 첫 이동은 엔진 기본 포커스 내비가 처리하고, 이 값들로 그 이후의 반복을 흉내낸다.
const NAV_REPEAT_DELAY := 0.2 ## 첫 입력 후 반복이 시작되기까지의 대기 시간(초).
const NAV_REPEAT_INTERVAL := 0.1 ## 반복 이동 간격(초).

## 현재 길게 눌린 D-pad 방향([enum Side]). 눌린 방향이 없으면 -1.
var _nav_repeat_side := -1
## 다음 반복 이동까지 남은 시간(초).
var _nav_repeat_timer := 0.0

## 종착점이 대기열에 추가되었을 때 발행된다.
signal destination_route_add
## 노선 확정 시 확인 메시지 키와 함께 발행된다.
signal route_confirm(target_text: String)

## 노선도 UI 초기화 — 기존 슬롯 정리, H씬 데이터 로드, 등장 애니메이션 재생, 튜토리얼 체크.
func _ready() -> void:
	
	if off_screen.visible == false:
		off_screen.show()
	if unlock_info_container.visible == true:
		unlock_info_container.hide()
	event_info_container.hide()
	
	clear_init()
	coin_icon.hide()
	my_coin_label.hide()
	h_scene_res_array = TrainUtil.get_res_from_path(h_scene_data.H_SCENE_DATA_PATH)
	
	GameEvents.set_window_state(Constants.WINDOW_KANKAN_OPEN, true)
	kankan_anim.play("in")
	route_map_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.SOUND_KANKAN_ON)
	pause_game(true)
	
	
	await kankan_on
	current_start_anim_finished = true
	set_route_buy_mode_actived()
	update_my_coin()
	route_tutorial.check_tutorial()
	get_viewport().gui_focus_changed.connect(on_focus_changed)
	check_route_start_button()
	floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
	
	if floor_manager == null: #테스트 등으로 플로어 매니저 정보가 없을 경우
		push_warning("플로어 매니저가 없습니다. 디버그중일수 있습니다")
		route_data = RouteData.new()
		#route_data.route_append(MetaProgression.get_current_chapter())
		route_data.route_append(6) #임의로 6챕터로 설정후 테스트
	else:
		route_data = floor_manager.route_data
		floor_manager.setting_route_manager.get_setting_route()
	create_routes()
	set_base_route()

## 패드 방향키(D-pad)를 길게 누르면 키보드처럼 포커스 이동을 반복시킨다.
## Why: 키보드 방향키는 echo 이벤트로 자동 반복되지만 게임패드 D-pad는 단발이라,
## 길게 눌러도 한 칸만 이동한다. 첫 이동은 엔진 기본 내비가 처리하므로
## 여기선 일정 지연 뒤부터 반복분만 보충한다. D-pad와 좌측 스틱 모두 대상.
func _process(delta: float) -> void:
	# [KR] 힌트/확인 창이 떠 있으면 노선 포커스가 도둑맞지 않도록 반복을 멈춘다.
	if route_hint.is_enable or confirm_bubble.is_enabled:
		_nav_repeat_side = -1
		return

	var side := _get_held_nav_side()
	if side == -1:
		_nav_repeat_side = -1
		return

	if side != _nav_repeat_side:
		# [KR] 새 방향 입력: 첫 이동은 엔진 기본 내비가 했으므로 반복 대기만 건다.
		_nav_repeat_side = side
		_nav_repeat_timer = NAV_REPEAT_DELAY
		return

	_nav_repeat_timer -= delta
	if _nav_repeat_timer <= 0.0:
		_nav_repeat_timer = NAV_REPEAT_INTERVAL
		_move_focus_to_side(side)

## 현재 눌려 있는 방향 입력(D-pad 또는 좌측 스틱)을 [enum Side]로 반환한다. 없으면 -1.
func _get_held_nav_side() -> int:
	for device in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP):
			return SIDE_TOP
		if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN):
			return SIDE_BOTTOM
		if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT):
			return SIDE_LEFT
		if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT):
			return SIDE_RIGHT
		# [KR] 좌측 스틱: 더 크게 기운 축 기준으로 방향 판정(데드존 0.5는 ui_* 액션과 동일).
		var stick_x := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		var stick_y := Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		if absf(stick_x) > absf(stick_y):
			if stick_x <= -0.5:
				return SIDE_LEFT
			if stick_x >= 0.5:
				return SIDE_RIGHT
		else:
			if stick_y <= -0.5:
				return SIDE_TOP
			if stick_y >= 0.5:
				return SIDE_BOTTOM
	return -1

## 현재 포커스에서 [param side] 방향의 이웃 컨트롤로 포커스를 옮긴다(가장자리면 무시).
func _move_focus_to_side(side: int) -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner == null:
		return
	var neighbor := focus_owner.find_valid_focus_neighbor(side)
	if neighbor:
		neighbor.grab_focus()

## 노선도창 열었을 때 기존 설정된 노선도 불러옴
func set_base_route():
	if floor_manager == null:
		push_warning("floor_manager가 없음")
		return
	var base_route = floor_manager.setting_route_manager.get_setting_route_base()
	if base_route == []:
		return
	
	for base_route_child in base_route:
		for route in route_container.get_children():
			if route is RouteSlot:
				if base_route_child == route.route_path:
					append_route_set_list(route)

## 발견 가능한 노선 슬롯을 [member route_data]로부터 생성하여 [member route_container]에 추가한다.
## [code]route_num[/code] 기준으로 정렬 후 인스턴스를 만든다.
func create_routes():
	var is_first := true

	# 1. 키들을 route_num 기준으로 정렬
	var sorted_keys := route_data.current_routes.keys()
	sorted_keys.sort_custom(func(a, b):
		return route_data.current_routes[a]["route_num"] < route_data.current_routes[b]["route_num"]
	)

	# 2. 정렬된 순서대로 인스턴스 생성
	for route_key in sorted_keys:
		var route_slot_instance = route_slot.instantiate() as RouteSlot
		route_slot_instance.route_num = route_data.current_routes[route_key]["route_num"]
		route_slot_instance.route_path = route_key
		route_slot_instance.current_route = route_data.current_routes[route_key]
		route_slot_instance.set_h_event_info(h_scene_res_array)
		route_slot_instance.pressed.connect(_on_button_pressed.bind(route_slot_instance))
		route_slot_instance.basic_route = route_tutorial.tuto_route as Array
		route_slot_instance.active_route_buy_mode = active_route_buy_mode
		route_slot_instance.mouse_entered.connect(_on_mouse_entered.bind(route_slot_instance))
		route_slot_instance.item_data = item_data
		route_slot_instance.total_route_num = route_data.current_routes.keys().size()
		route_container.add_child(route_slot_instance)

		if is_first:
			route_slot_instance.grab_focus()
			is_first = false

## 노선 컨테이너와 대기열 컨테이너의 자식 노드를 모두 제거하여 초기화한다.
func clear_init():
	for child in route_container.get_children():
		child.queue_free()
	for child in route_set_container.get_children():
		child.queue_free()

## 포커스가 변경될 때 호출. 힌트가 비활성 상태이면 상세 정보를 업데이트한다.
func on_focus_changed(slot: Control):
	if not (slot as Button):
		print("slot err")
	if slot as RouteSlot and not route_hint.is_enable:
		detail_update(slot)

## 마우스 진입 시 호출. [RouteSlot]이 아니거나 힌트 활성 중이면 무시한다.
func _on_mouse_entered(slot: Button):
	if !slot is RouteSlot and not route_hint.is_enable and current_start_anim_finished:
		return
	detail_update(slot)

## [param append_route_slot]을 노선 대기열에 추가한다.
## 중복 방지 및 최대 수 [code]Constants.MAX_ROUTE_COUNT[/code] 제한을 적용한다.
func append_route_set_list(append_route_slot: RouteSlot):
	if route_set_list.has(append_route_slot.route_path): #노선 중복 추가 방지
		return
	if route_set_container.get_children().size() >= Constants.MAX_ROUTE_COUNT: 
		print("Route queue is full.")
		return
	
	var route_set_instance: RouteSlot = route_set_scene.instantiate()
	route_set_instance.current_route = append_route_slot.current_route
	route_set_instance.route_num = append_route_slot.route_num
	route_set_instance.route_path = append_route_slot.route_path
	route_set_instance.pressed.connect(_on_route_button_pressed.bind(route_set_instance))
	route_set_instance.item_data = item_data
	route_set_container.add_child(route_set_instance)
	route_set_list.append(append_route_slot.route_path)
	check_set_list()

## [param erase_route_slot]을 노선 대기열에서 제거하고 종착점 상태를 재확인한다.
func erase_route_set_list(erase_route_slot: RouteSlot):
	route_set_list.erase(erase_route_slot.route_path)
	erase_route_slot.queue_free()
	check_set_list()
	_grab_focus_set_route()

## 대기열의 마지막 슬롯에 포커스를 부여. 대기열이 비었으면 노선 목록 첫 항목에 포커스.
func _grab_focus_set_route():
	await get_tree().process_frame
	if route_set_container.get_child_count() == 0:
		set_grab_focus_first_route()
		return
	var next_button: RouteSlot = route_set_container.get_child(-1)
	if next_button:
		next_button.grab_focus()
	else:
		set_grab_focus_first_route()

## 대기열 변경 시 호출 — 출발 버튼 상태 갱신, 종착점 조건 충족 여부 확인 및 추가/제거.
func check_set_list():
	check_route_start_button()
	
	for child in route_set_container.get_children():
		var route_set_info = child as RouteSlot
		route_set_info.modulate = Color(1, 1, 1)
		
	var destination_list = route_data.check_destination(route_set_list) as Dictionary
	if destination_list == {}:
		erase_destination_route()
		return

	for child in route_set_container.get_children():
		var route_set_info = child as RouteSlot
		var destination_route = destination_list["info"]["route_list"]
		if destination_route.has(route_set_info.route_path):
			route_set_info.modulate = Color(0, 1, 0)

	add_destination_route(destination_list)

## 종착점 슬롯을 [member destination_container]에 추가한다.
## 이미 존재하면 중복 추가하지 않는다.
func add_destination_route(destination_list : Dictionary):
	if destination_container.get_child_count() > 0:
		return
	#print(destination_list)
	var destination_instante : DestinationRect = destination_rect.instantiate()
	destination_instante.current_route = destination_list["info"]
	destination_instante.route_path = destination_list["path"]
	destination_container.add_child(destination_instante)
	route_map_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.SOUND_KANKAN_DESTINATION_CORECT)
	destination_route_add.emit()


## 종착점 슬롯이 존재하면 제거한다.
func erase_destination_route():
	var destination_route = get_destination_route()
	if destination_route == null:
		return

	if is_instance_valid(destination_route):
		destination_route.queue_free()

## 현재 종착점 [DestinationRect]를 반환한다. 없으면 [code]null[/code].
func get_destination_route() -> DestinationRect:
	if destination_container.get_child_count() == 0:
		return null
	else:
		var destination_route = destination_container.get_child(0)
		return destination_route

## 현재 포커스된 노선의 상세 정보(이름, 설명, H이벤트 등)를 우측 패널에 갱신한다.
## 같은 슬롯이 연속 입력되면 무시한다.
var current_focused_slot: RouteSlot
func detail_update(update_slot: RouteSlot):
	### 현재 표시중인 정보와 새로 입력받은 정보가 같으면 리턴
	if update_slot == current_focused_slot:
		return
	else:
		current_focused_slot = update_slot
	
	route_name_lable.text = ""
	description_label.text = "ROUTE_APP_NOT_FIND_DESCRIPTION"
	
	if update_slot.is_unlocked:
		unlock_info_container.hide()
	else:
		if active_route_buy_mode:
			%UnlockTicketCountLabel.text = "x"+str(1)
			unlock_info_container.show()
	
	if update_slot.current_route == {}:
		return
	
	var current_route = update_slot.current_route as Dictionary
	
	if current_route.has("title"):
		title_rect.info_update()
		description_label.info_update()
		# [KR] 슬롯(route_slot)의 ??? 마스킹과 동일 기준으로 가린다: 미해금이고 타이틀 공개 이벤트도
		#      안 봤으면 우측 슬롯이 ???이므로 좌측 정보(이름·설명)도 똑같이 가린다.
		if not (update_slot.is_unlocked or MetaProgression.has_read_event(Constants.QUESTLINE_KANKANNAVI_UNHIDE_TITLE)):
			route_name_lable.text = "ROUTE_APP_NOT_FIND"
		else:
			route_name_lable.text = current_route["title"]
			#route_name_lable.text = "a"
			description_label.text = current_route["info"]
			#description_label.text = "a"
	
	## 해당 스테이지에 H이벤트가 있으면 파트너 아이콘과 이벤트 이름을 표시한다.
	if update_slot.is_event_unlock():
		event_info_container.show()
		event_partner_texture.texture = Constants.SD_ICONS[update_slot.h_scene_data.partner]
		event_name_label.text = tr(update_slot.h_scene_data.scene_description) + "..♡"
	else:
		event_info_container.hide()


## 대기열의 노선 + 종착점을 [FloorManager]의 [code]setting_route[/code]에 반영한다.
func set_setting_route():
	if !floor_manager:
		push_warning("디버그 중입니다")
		return
	
	var setting_route = floor_manager.setting_route_manager.setting_route
	setting_route.clear()
	var route_set_list_copy = route_set_list.duplicate()
	setting_route.append_array(route_set_list_copy)

	#노선도 끝에 종착점 추가
	var destination_route = get_destination_route()
	if setting_route != []:
		if destination_route == null:
			var normal_complete_stage = RouteData.get_complete_stage(MetaProgression.get_current_chapter())
			setting_route.append(normal_complete_stage)
		else:
			setting_route.append(destination_route.route_path)
			

	#완성된 노선도를 플로어 매니저에 전달
	floor_manager.setting_route_manager.set_setting_route_base(route_set_list_copy)
	floor_manager.setting_route_manager.set_current_destination(destination_route)
	floor_manager.floor_setting(floor_manager.current_level)


## 게임 일시정지 상태를 [param pause]로 설정한다.
func pause_game(pause: bool):
	get_tree().paused = pause

## 노선도 UI가 트리에서 제거될 때 Dialogic 프로세스 모드 복원 및 일시정지 해제.
func _exit_tree():
	Dialogic.process_mode = Node.PROCESS_MODE_INHERIT
	GameEvents.set_window_state(Constants.WINDOW_KANKAN_OPEN, false)
	if get_viewport().gui_focus_changed.is_connected(on_focus_changed):
		get_viewport().gui_focus_changed.disconnect(on_focus_changed)
	pause_game(false)

## 입력 처리 — ESC/칸칸키로 닫기, Shift로 노선 확정, 테스트키로 대기열 초기화.
func _input(event):
	# [KR] 입장 애니메이션이 끝나기 전에는 입력을 무시한다.
	# Why: 라우트맵이 올라오는 동안 힌트 단축키(Q 등)가 들어오면 힌트 창이 먼저 열리는 레이스가 발생한다.
	if not current_start_anim_finished:
		return
	if route_tutorial.current_tutorial:
		if route_tutorial.route_set_input_enabled and event.is_action_pressed("kankan_routes_set"):
			_on_route_start_pressed()
			get_viewport().set_input_as_handled()
		elif route_tutorial.exit_input_enabled and (event.is_action_pressed("esc") or event.is_action_pressed(Constants.TRAIN_KEY_KANKANNAVI)):
			exit_anim_start()
			get_viewport().set_input_as_handled()
		return
	if not MetaProgression.has_read_event("chapter4_kankannavi") and not Constants.KANKAN_TUTORIAL_FORCE:
		return
	if GameEvents.get_window_state(Constants.WINDOW_STATE_BUG_REPORTER):
		return
	if event.is_action_pressed("esc") or event.is_action_pressed(Constants.TRAIN_KEY_KANKANNAVI):
		exit_anim_start()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("kankan_routes_set"):
		_on_route_start_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("kankan_routes_clear"):
		_on_route_clear_button_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("kankan_hint"):
		_on_hint_pressed()
		get_viewport().set_input_as_handled()


## 출발 버튼의 활성/비활성 상태를 갱신한다.
func check_route_start_button():
	route_start.disabled = false
	#if route_set_list == []:
		#route_start.disabled = true
	#else:
		#route_start.disabled = false

## 노선 슬롯을 선택하여 대기열에 추가한다. 잠긴 노선이면 구매 처리를 시도한다.
func _on_button_pressed(select_route_slot: RouteSlot):
	if confirm_bubble.is_enabled:
		return
	if route_hint.is_enable:
		return
	if select_route_slot.is_unlocked:
		append_route_set_list(select_route_slot)
	else:
		if active_route_buy_mode: #루트 구매 기능 해제 후 가능
			unlock_buy(select_route_slot)

## 대기열의 노선 슬롯을 클릭하여 대기열에서 제거한다.
func _on_route_button_pressed(route_set_list_button: RouteSlot):
	if route_hint.is_enable: # 힌트 창이 떠 있을때
		return
	route_map_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.SOUND_KANKAN_ROUTE_ERASE)
	erase_route_set_list(route_set_list_button)


## 대기열의 모든 노선을 순차적으로 제거(초기화)한다.
func _on_route_clear_button_pressed() -> void:
	if route_hint.is_enable:
		return
	if route_set_container.get_child_count() == 0:
		return
	for _route in route_set_container.get_children():
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(_route): 
			erase_route_set_list(_route)

## 노선을 확정하고 [signal route_confirm]을 발행한 뒤 [method set_setting_route]를 호출한다.
func _on_route_start_pressed() -> void:
	if route_hint.is_enable or confirm_bubble.is_enabled:
		return
	route_confirm.emit("ROUTE_APP_MSG_COMFIRM")
	set_setting_route()


## 힌트 버튼이 눌리면 노선 힌트 UI를 활성화한다.
func _on_hint_pressed() -> void:
	if route_hint.is_enable:
		return
	route_hint.set_enable(true)

## 등장 애니메이션 완료 후 [signal kankan_on]을 발행한다.
func emit_kankan_on():
	kankan_on.emit()

## 닫기 버튼이 눌리면 퇴장 애니메이션을 시작한다.
func _on_exit_pressed() -> void:
	exit_anim_start()

## 퇴장 애니메이션을 재생한다. 힌트가 열려있거나 이미 재생 중이면 무시.
func exit_anim_start():
	if not route_hint.is_enable and not kankan_anim.is_playing():
		
		route_map_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.SOUND_KANKAN_OFF)
		kankan_anim.play("out")

## 퇴장 애니메이션 완료 후 이 노드를 트리에서 제거한다.
func route_exit():
	if not route_hint.is_enable:
		queue_free()
		get_viewport().set_input_as_handled()

## 잠긴 노선의 구매를 시도한다. 코인이 부족하면 메시지만 표시하고, 충분하면 확인 절차를 진행.
func unlock_buy(select_route_slot: RouteSlot):

	var unlock_coin_num:int = get_need_unlock_coin_num()
	var current_coin:int = MetaProgression.get_route_coin()
	if current_coin < unlock_coin_num:
		route_confirm.emit("ROUTE_APP_MSG_NEEDCOIN")
	else:
		confirm_unlock(select_route_slot)

## [ConfirmBox]로 잠금 해제를 확인받고, 승인 시 코인 차감 + 슬롯 잠금 해제 처리.
func confirm_unlock(select_route_slot: RouteSlot):
	confirm_box.customize(
	"ROUTE_APP_MSG_UNLOCKROUTE",
	"Unlock",
	"ROUTE_APP_MSG_USECOIN",
	"YES",
	"NO"
	)
	var is_confirmed = await confirm_box.prompt(true)
	if is_confirmed:
		select_route_slot.set_unlock()
		#GameEvents.emit_set_ticket("minus", get_unlock_ticket_num())
		GameEvents.emit_set_coin(-get_need_unlock_coin_num())
		update_my_coin()
		select_route_slot.grab_focus()
	else:
		select_route_slot.grab_focus()

## 잠금 해제에 필요한 티켓 수를 반환한다 (현재 보유 노선 수 × 100).
func get_unlock_ticket_num()->int:
	return MetaProgression.get_routes_dict().size()*100

## 잠금 해제에 필요한 코인 수를 반환한다. 현재 1개 고정.
func get_need_unlock_coin_num()-> int:
	return 1

## 특정 퀘스트라인 이벤트 클리어 후 노선 구매 모드를 활성화한다.
## [code]Constants.KANKAN_ROUTE_BUY_MODE_UNLOCK[/code] 디버그 플래그도 확인한다.
func set_route_buy_mode_actived():
	if MetaProgression.has_read_event(Constants.QUESTLINE_KANKANNAVI_UPGRADE):
		active_route_buy_mode = true
		coin_icon.show()
		my_coin_label.show()
	else:
		active_route_buy_mode = false
		coin_icon.hide()
		my_coin_label.hide()
	if Constants.KANKAN_ROUTE_BUY_MODE_UNLOCK:
		active_route_buy_mode = true
		coin_icon.show()
		my_coin_label.show()

## 보유 코인 수 라벨을 현재 값으로 갱신한다. 구매 모드 비활성 시 무시.
func update_my_coin():
	if not active_route_buy_mode:
		return
	#var ticket_string: String = tr("TICKET_NUM") + " : "
	my_coin_label.text = "x" + str(MetaProgression.get_route_coin())

## 노선 목록의 첫 번째 슬롯에 포커스를 부여한다.
func set_grab_focus_first_route():
	var routes: Array[Node] = route_container.get_children()
	if routes.size() > 0:
		routes[0].grab_focus()
