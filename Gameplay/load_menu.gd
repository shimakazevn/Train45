extends Control
## 세이브/로드 메뉴 화면.
## [br]세이브 슬롯 목록을 표시하고, 선택된 슬롯의 상세 정보(챕터, 티켓, NPC 호감도, 클리어율 등)를 보여준다.
## [code]save[/code] 또는 [code]load[/code] 모드로 동작한다.

## 클리어율 계산 컴포넌트.
@onready var clear_percent_component: ClearPercentComponent = $ClearPercentComponent

@onready var back = %Back
@onready var scroll_container = %ScrollContainer
## 세이브 슬롯 버튼들이 배치되는 컨테이너.
@onready var slot_container = %SlotContainer
@onready var chapter_name = %ChapterName
@onready var chapter_description: Label = %ChapterDescription

## 상세 정보 패널 (슬롯에 데이터가 있을 때 표시).
@onready var details_info = %DetailsInfo
## 빈 슬롯일 때 표시되는 안내 노드.
@onready var empty = %Empty
@onready var game_clear_box = %GameClearBox
@onready var game_clear_count = %GameClearCount
@onready var screen_animation_player = %ScreenAnimationPlayer
@onready var play_time = %PlayTime


@onready var ticket_num = %TicketNum

@onready var reina_love_level = %ReinaLoveLevel
@onready var mai_love_level = %MaiLoveLevel
@onready var konial_love_level: Label = %KonialLoveLevel
@onready var butler_love_level: Label = %ButlerLoveLevel

@onready var reina_h_scene: Label = %ReinaHScene
@onready var mai_h_scene: Label = %MaiHScene
@onready var konial_h_scene: Label = %KonialHScene
@onready var butler_h_scene: Label = %ButlerHScene

@onready var konial_slot: TextureRect = %KonialSlot
@onready var butler_slot: TextureRect = %ButlerSlot


@onready var route_percent: Label = %RoutePercent
@onready var dest_percent: Label = %DestPercent
@onready var item_percent: Label = %ItemPercent
@onready var all_clear_percent: Label = %AllClearPercent


## 현재 선택된 슬롯의 상세 정보.
var current_detail : Dictionary = {}

## 패드 방향키(D-pad)로 슬롯을 이동할 때, 키보드처럼 길게 누르면 반복 이동시키기 위한 설정.
## 첫 이동은 엔진 기본 포커스 내비가 처리하고, 이 값들로 그 이후의 반복을 흉내낸다.
const NAV_REPEAT_DELAY := 0.2 ## 첫 입력 후 반복이 시작되기까지의 대기 시간(초).
const NAV_REPEAT_INTERVAL := 0.1 ## 반복 이동 간격(초).

## 현재 길게 눌린 D-pad 방향([enum Side]). 눌린 방향이 없으면 -1.
var _nav_repeat_side := -1
## 다음 반복 이동까지 남은 시간(초).
var _nav_repeat_timer := 0.0

## 슬롯 상세 정보를 표시하는 패널.
@export var detail_panel : MarginContainer
## 세이브 슬롯 UI 씬 리소스.
@export var save_slot : PackedScene
## 메뉴 동작 모드. [code]"save"[/code] 또는 [code]"load"[/code].
@export_enum("save", "load") var mode

## 저장 모드 상수.
const MODE_SAVE := 0
## 불러오기 모드 상수.
const MODE_LOAD := 1


## 세이브 슬롯 목록을 생성하고 마지막 저장 슬롯에 포커스를 설정한다.
func _ready():
	get_viewport().gui_focus_changed.connect(on_focus_changed)
	
	for child in slot_container.get_children():
		child.queue_free()
		
	#match mode:
		#MODE_SAVE:
			#title.text = "SAVE_GAME"
		#MODE_LOAD:
			#title.text = "LOAD_GAME"
			
	for i in Constants.AUTO_SAVE_SLOT_COUNT:
		set_save_slot(Constants.AUTO_SAVE_INDEX + i)
	for i in MetaProgression.SAVE_SLOT_MAX:
		set_save_slot(i)
	
	set_grab_last_save_data()
	scroll_container.scroll_vertical = 0
	
	screen_animation_player.play("in")

## [param i]번 슬롯을 인스턴스화하여 슬롯 컨테이너에 추가한다.
## [br]첫 번째 슬롯(자동 저장)은 자동으로 포커스를 받는다.
func set_save_slot(i: int):
	var save_slot_instante = save_slot.instantiate()
	save_slot_instante.slot_num = i
	
	save_slot_instante.slot_save_update.connect(on_slot_update.bind(save_slot_instante))
	
	if mode == MODE_SAVE:
		save_slot_instante.mode = "save"
	elif mode == MODE_LOAD:
		save_slot_instante.mode = "load"
	slot_container.add_child(save_slot_instante)
	if i == 0:
		save_slot_instante.grab_focus()

## 패드 방향키(D-pad)를 길게 누르면 키보드처럼 포커스 이동을 반복시킨다.
## Why: 키보드 방향키는 echo 이벤트로 자동 반복되지만 게임패드 D-pad는 단발이라,
## 길게 눌러도 한 칸만 이동한다. 첫 이동은 엔진 기본 내비가 처리하므로
## 여기선 일정 지연 뒤부터 반복분만 보충한다. D-pad와 좌측 스틱 모두 대상.
func _process(delta: float) -> void:
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

## ESC 키 입력 시 뒤로가기를 처리한다.
func _input(event):
	if event.is_action_pressed("esc"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


## 문자열 [param mode_str]로 메뉴 모드를 설정한다. [code]"save"[/code] 또는 [code]"load"[/code].
func set_mode(mode_str: String):
	match mode_str:
		"save":
			mode = MODE_SAVE
		"load":
			mode = MODE_LOAD

## 뒤로가기 애니메이션을 재생하고 슬롯 입력을 비활성화한다.
func _on_back_pressed():
	screen_animation_player.play("out")
	back.set_focus_mode(Control.FOCUS_NONE)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in slot_container.get_children(): 
		var slot = child as Button
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE


## 슬롯 저장/덮어쓰기 후 상세 정보를 갱신하는 콜백.
func on_slot_update(save_slot_instante: Button):
	detail_update(save_slot_instante)

## 포커스가 [code]SaveSlot[/code]으로 변경되면 상세 정보를 갱신한다.
## Why: gui_focus_changed는 뷰포트 전역 시그널이라 Button이 아닌 Control이 포커스를 받을 수도 있다.
## 인자를 Button으로 좁게 받으면 그때 형변환에 실패해 콜백이 죽으므로 Control로 받고 내부에서 캐스팅한다.
func on_focus_changed(slot: Control):
	if slot as SaveSlot:
		detail_update(slot)

## [param slot]의 저장 데이터를 읽어 상세 패널(챕터명, 티켓, NPC 호감도, 클리어율 등)을 갱신한다.
## [br]Why: 코니알/집사는 특정 퀘스트 완료 후에만 호감도 슬롯이 표시되므로, 읽은 이벤트 여부를 함께 검사한다.
func detail_update(slot: SaveSlot):
	var slot_update = slot as SaveSlot
	chapter_name.text = ""
	ticket_num.text = "0"
	reina_love_level.text = "0"
	mai_love_level.text = "0"
	
	konial_slot.hide()
	butler_slot.hide()
	
	game_clear_box.hide()
	game_clear_count.text = str(0)
	slot_empty(false)
	#print(slot_update.save_info)
	detail_panel.detail_update()
	
	if slot_update.save_info == {}:
		slot_empty(true)
		return
		
	if slot_update.save_info.has("chapter"):
		chapter_name.text = ChapterInfo.new().get_chapter_title(slot_update.save_info["chapter"])
		var desc: String = tr(ChapterInfo.new().get_chapter_description(slot_update.save_info["chapter"]))
		chapter_description.text = "【 "+desc+"】"
	if slot_update.save_info.has("ticket_num"):
		ticket_num.text = str(slot_update.save_info["ticket_num"])
	
	var npc_info: Dictionary = slot_update.save_info["npc_info"]
	if npc_info.has(Constants.NpcTypes.REINA):
		reina_love_level.text = _get_npc_level_text(npc_info[Constants.NpcTypes.REINA], Constants.NpcTypes.REINA)
	if npc_info.has(Constants.NpcTypes.MAI):
		mai_love_level.text = _get_npc_level_text(npc_info[Constants.NpcTypes.MAI], Constants.NpcTypes.MAI)
	# 레이나/마이는 항상 표시되므로 H씬 수집률도 항상 갱신한다.
	reina_h_scene.text = _h_scene_text(slot_update.save_info, Constants.NpcTypes.REINA)
	mai_h_scene.text = _h_scene_text(slot_update.save_info, Constants.NpcTypes.MAI)
	if npc_info.has(Constants.NpcTypes.KONIAL):
		if slot_update.save_info["read_event"].has(Constants.QUESTLINE_KONIAL_BIND):
			konial_slot.show()
			konial_love_level.text = _get_npc_level_text(npc_info[Constants.NpcTypes.KONIAL], Constants.NpcTypes.KONIAL)
			konial_h_scene.text = _h_scene_text(slot_update.save_info, Constants.NpcTypes.KONIAL)
	if npc_info.has(Constants.NpcTypes.BUTLER):
		if slot_update.save_info["read_event"].has(Constants.QUESTLINE_BUTLER_HUMAN):
			butler_slot.show()
			butler_love_level.text = _get_npc_level_text(npc_info[Constants.NpcTypes.BUTLER], Constants.NpcTypes.BUTLER)
			butler_h_scene.text = _h_scene_text(slot_update.save_info, Constants.NpcTypes.BUTLER)
	
	if slot_update.save_info["game_clear_count"] > 0:
		#game_clear_box.show()
		game_clear_count.text = str(slot_update.save_info["game_clear_count"])
	if slot_update.save_info.has("play_time"):
		play_time.text = Time.get_time_string_from_unix_time(slot_update.save_info["play_time"])
	
	route_percent.text = str(clear_percent_component.get_route_percent(slot.save_info)) + "%"
	dest_percent.text = str(clear_percent_component.get_destination_percent(slot.save_info)) + "%"
	item_percent.text = str(clear_percent_component.get_item_percent(slot.save_info)) + "%"
	all_clear_percent.text = str(clear_percent_component.get_all_clear_percent(slot.save_info)) + "%"

## [param npc_type]의 H씬 수집률 텍스트를 반환한다. 예) "H Scene 80%"
## [br]"SAVE_H_SCENE"은 라벨 문구 번역키이며, 퍼센트는 코드에서 계산해 붙인다.
func _h_scene_text(save_info: Dictionary, npc_type: int) -> String:
	return "%s %d%%" % [tr("SAVE_H_SCENE"), clear_percent_component.get_h_scene_percent(save_info, npc_type)]

## [param npc_name]에 해당하는 NPC의 호감도 레벨 텍스트를 반환한다.
## [br]최대 레벨에 도달하면 [code]"MAX"[/code]를 반환한다.
func _get_npc_level_text(npc_dict: Dictionary, npc_name: int)-> String:
	var max_level: int = 99
	
	match npc_name:
		Constants.NpcTypes.REINA, Constants.NpcTypes.MAI:
			max_level = Constants.PARTNER_MAX_LEVEL
		Constants.NpcTypes.KONIAL:
			max_level = Constants.NPC_MAX_LEVEL_KONIAL
		Constants.NpcTypes.BUTLER:
			max_level = Constants.NPC_MAX_LEVEL_BUTLER
	
	if npc_dict.has("level"):
		if npc_dict["level"] >= max_level:
			return "MAX"
		else:
			return str(npc_dict["level"])
	else:
		return str("0")

## [param slot_condition]에 따라 빈 슬롯 안내 / 상세 정보 표시를 토글한다.
func slot_empty(slot_condition : bool):
	if slot_condition:
		details_info.hide()
		empty.show()
	else:
		details_info.show()
		empty.hide()

## 가장 최근에 저장한 슬롯을 찾아 자동으로 포커스를 설정한다.
## [br]Why: 자동 저장 슬롯은 사용자가 직접 선택하는 것이 아니므로 포커스 대상에서 제외한다.
func set_grab_last_save_data():
	await get_tree().process_frame
	
	var latest_time: float = 0.0
	var latest_slot: SaveSlot = null
	
	for i in slot_container.get_children():
		var _save_slot: SaveSlot = i
		if _save_slot.save_info and _save_slot.save_info["last_save_date"].has("unix_time")\
		and not (_save_slot.slot_num >= Constants.AUTO_SAVE_INDEX \
			and _save_slot.slot_num < Constants.AUTO_SAVE_INDEX + Constants.AUTO_SAVE_SLOT_COUNT): #자동저장 슬롯이 포커스 안되게
			if _save_slot.save_info["last_save_date"]["unix_time"] > latest_time:
				latest_time = _save_slot.save_info["last_save_date"]["unix_time"]
				latest_slot = _save_slot
	
	if latest_slot:
		latest_slot.grab_focus()
	
	#버튼 스크롤 조정
	if scroll_container.scroll_vertical > 0.0:
		scroll_container.scroll_vertical += 150.0
