extends Node2D
class_name RewardItemBox

var base_width: float

@export_category("Reward")
@export var item: AbilityUpgrade
@export var hint: RouteHintPage
@export var ticket: int = 0
@export var route_coin: int = 0

@onready var sprite: Sprite2D = %Sprite2D
@onready var canvas_group: CanvasGroup = $CanvasGroup
@onready var shine_effect: ColorRect = $CanvasGroup/Sprite2D/ShineEffect
@onready var box_anim_player: AnimationPlayer = $AnimationPlayer

@onready var get_item_canvas_layer: CanvasLayer = $GetItemCanvasLayer
@onready var item_texture_rect: TextureRect = %ItemTextureRect
@onready var item_name_label: Label = %ItemNameLabel
@onready var item_description_label: Label = %ItemDescriptionLabel
@onready var canvas_anim_player: AnimationPlayer = $GetItemCanvasLayer/CanvasAnimPlayer

@onready var guide: Sprite2D = %guide
@onready var keyboard_icon: TextureRect = $KeyboardIcon

var current_level: Level

var box_active: bool = false
var getted: bool = false
var stage_type: int

enum BoxState {CLOSE, OPEN, SHOW_INFO, SHOW_INFO_END, ALREADY_GET}
var box_state: BoxState = BoxState.CLOSE
var current_near_player: bool = false

var returning_base: bool = false

func _ready() -> void:
	guide.hide()
	GameEvents.stage_clear.connect(_on_stage_clear)
	base_width = sprite.material.get_shader_parameter("width")
	near_player(false)
	get_item_canvas_layer.visible = false
	
	## 스테이지 타입에 따라 클리어후 보여질지 바로 보여질지 설정
	current_level = self.owner as Level
	stage_type = current_level.stage_type
	if stage_type == Constants.TYPE_STAGE:
		set_box_active(false)
	elif stage_type == Constants.TYPE_COMPLETE:
		set_box_active(true)
	
	await get_tree().process_frame # current_level.level_path의 정보를 불러오기 위해 한프레임 늦게 실행
	##아이템 타입에 따라 내용물 이미 획득했는지 설정
	if item and MetaProgression.has_ability(item.id):
		set_already_getted()
	elif hint and MetaProgression.has_route_hint(hint.id):
		set_already_getted()
	elif route_coin > 0 and MetaProgression.has_box_getted_stage(current_level.level_path): # current_level.name 은 level의 노드 이름
		set_already_getted()
	elif ticket > 0 and MetaProgression.has_box_getted_stage(current_level.level_path):
		set_already_getted()

	set_item_box_info()
	
	keyboard_icon.hide()
	

func set_already_getted():
	box_state = BoxState.ALREADY_GET
	## "open" 애니메이션엔 사운드 트랙(BoxOpenSFX/BoxOpenSFX2)이 포함돼 있어,
	## 안 보이는 상태에서도 재생됨. 이미 획득한 경우엔 애니메이션 대신 열린 상태만 직접 설정한다.
	sprite.frame = 1
	shine_effect.visible = true
	canvas_group.modulate = Color(1, 1, 1, 1)

func _on_stage_clear():
	if stage_type == Constants.TYPE_STAGE: #스테이지 클리어시 상자 활성화 여부
		if not can_drop_box():
			return
		#만약 이미 획득했거나 집사 호감도 퀘스트 시작 안했으면 상자 표시 안함,
		if box_state == BoxState.ALREADY_GET:
			set_box_active(false)
		elif box_state == BoxState.CLOSE:
			set_box_active(true)

func can_drop_box()-> bool:
	if MetaProgression.has_read_event(Constants.QUESTLINE_BUTLER_LOVE_QUEST_START):
		return true
	elif Constants.ITEM_BOX_DEBUG:
		push_warning("현재 디버그중입니다")
		return true
	return false

func set_box_active(active: bool):
	if active:
		box_active = true
		show()
		box_anim_player.play("in")
	else:
		box_active = false
		hide()

##아이템 박스의 내용물을 설정한다
func set_item_box_info():
	if item:
		item_texture_rect.texture = item.icon
		item_name_label.text = item.name
		item_description_label.text = item.description
		
		##보상으로 획득하기 때문에 가격은 항상 0으로 변경한다. 그래야 획득 과정에서 티켓이 감소되지 않는다
		item.price[0] = 0
	elif hint:
		item_texture_rect.texture = hint.texture
		item_name_label.text = hint.title
		item_description_label.text = "HINT_ITEM_GET"
	elif route_coin > 0:
		item_texture_rect.texture = Constants.ROUTE_COIN_ICON
		item_name_label.text = "ROUTE_COIN"
		item_description_label.text = "ROUTE_COIN_DESCRIPTION"
	elif ticket > 0:
		item_texture_rect.texture = Constants.TICKET_ICON
		item_name_label.text = "TICKET_ITEM"
		item_description_label.text = "TICKET_ITEM_DESCRIPTION"
	else:
		push_error("item이 설정 안됐습니다. 보상 아이템을 추가해 주세요.")


##아이템 박스 열기
func set_box_open():
	if not box_active: #박스 활성화 상태 아닐 시 처리 안함
		return

	near_player(false)
	box_state = BoxState.OPEN
	box_anim_player.play("open")
	get_tree().paused = true
	
	
	
	await box_anim_player.animation_finished
	await get_tree().create_timer(1.0).timeout
	
	box_state = BoxState.SHOW_INFO
	get_item_canvas_layer.visible = true
	canvas_anim_player.play("show_item")
	
	await canvas_anim_player.animation_finished
	box_state = BoxState.SHOW_INFO_END
	
	#아이템 or 힌트 획득 처리
	if item:
		GameEvents.emit_get_item_event(item.id) # 아이템 획득 시그널 함수, 아이템 가격은 0이어야 한다.
	elif hint:
		GameEvents.emit_add_route_hint(hint.id)
	elif route_coin > 0:
		GameEvents.emit_set_coin(route_coin)
		MetaProgression.add_box_getted_stage(current_level.level_path)
		# [KR] 코인/티켓 박스는 get_item_event/add_route_hint를 안 쏘므로, 도전과제 수집 판정을 직접 트리거한다.
		GameEvents.emit_item_box_collected()
	elif ticket > 0:
		match stage_type:
			Constants.TYPE_STAGE, Constants.TYPE_SAFE:
				GameEvents.emit_drop_item(Constants.PC_PLAYER, DropItemManager.ItemType.TICKET, int(float(ticket) / Constants.TICKET_VALUE_NORMAL))
			Constants.TYPE_COMPLETE:
				GameEvents.emit_set_ticket("plus", ticket)
		MetaProgression.add_box_getted_stage(current_level.level_path)
		# [KR] 코인/티켓 박스는 get_item_event/add_route_hint를 안 쏘므로, 도전과제 수집 판정을 직접 트리거한다.
		GameEvents.emit_item_box_collected()
	######################


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action"):
		match box_state:
			BoxState.CLOSE:
				# [KR] 대화/이벤트 진행 중에는 상자를 열지 않는다.
				# Why: 분실물 상자와 NPC(레이나 등) 위치가 겹칠 때, 대화를 진행하는 "action"(스페이스/엔터)
				# 입력이 상자 _input에도 잡혀 set_box_open()이 트리를 멈춰 대화가 끊기던 버그 방지.
				if GameEvents.game_state == Constants.STATE_EVENT or Dialogic.current_timeline:
					return
				if current_near_player:
					set_box_open()
			BoxState.SHOW_INFO_END:
				if not getted:
					# 시작 지점으로 돌아간다
					get_tree().paused = false
					set_getted_item()

##스테이지 타입에 따라 계속 이동할지, 시작지점으로 돌아갈지 정함
func set_getted_item():
	getted = true
	match stage_type:
		Constants.TYPE_STAGE:
			get_item_canvas_layer.visible = false
			canvas_anim_player.play("RESET")
			# 스테이지 형식인 경우 집사 호감도 하트 드랍
			drop_butler_love(Constants.INCRESE_LOVE_EXP_NUM_BUTLER)
		Constants.TYPE_COMPLETE:
			GameEvents.emit_game_complete()
			
			## 종착점의 아이템 박스는 집사 호감도를 상승시키지 않음으로 주석 처리함, 종착점은 호감도 이벤트 이전부터 방문 가능하기 때문에
			## 클리어 스테이지인 경우 바로 시작지점으로 가기에 바로 호감도 획득
			#var total_butler_love: int = Constants.INCRESE_LOVE_EXP_NUM_BUTLER * Constants.INCRESE_LOVE_EXP_BUTLER
			#GameEvents.emit_get_npc_exp(total_butler_love, GameEvents.NpcTypes.BUTLER)

func near_player(is_near: bool):
	var box_outline: Material = sprite.material

	if is_near:
		box_outline.set_shader_parameter("width", base_width)
		current_near_player = true
		keyboard_icon.show()
		
		#print("on")
	else:
		box_outline.set_shader_parameter("width", 0.0)
		current_near_player = false
		keyboard_icon.hide()
		
		#print("off")


##이미 아이템 획득했을 시 잠시 후 시작지점으로 돌아감
func already_get_return_base():
	if not box_active: #박스 활성화 상태가 아닐 시 실행 안함
		return

	if box_state == BoxState.ALREADY_GET and not returning_base:
		returning_base = true
		NotionEvent.notion("ALREADY_ITEM_GET")
		
		await get_tree().create_timer(4.0).timeout
		set_getted_item()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area is TalkArea:
		if box_state == BoxState.ALREADY_GET:
			already_get_return_base()
		elif box_state == BoxState.SHOW_INFO_END:
			near_player(false)
		else:
			near_player(true)

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area is TalkArea:
		near_player(false)

func drop_butler_love(drop_heart_num: int):
	@warning_ignore("integer_division")
	GameEvents.emit_drop_item(Constants.PC_PLAYER, DropItemManager.ItemType.BUTLER_HEART, drop_heart_num)
	
