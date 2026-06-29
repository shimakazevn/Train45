extends Node2D
class_name DropItem
## 월드에 드롭되는 아이템 엔티티.
## [br]NPC 레벨업, 전투 보상 등에서 생성되며, 포물선 낙하 → 바운스 → 유동 애니메이션 후
## 플레이어가 접근하면 자동 회수되어 티켓/호감도 등의 보상을 지급한다.

@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var item_texture: TextureRect = $ItemTexture
@onready var screen_notifier: VisibleOnScreenNotifier2D = $ScreenNotifier

## 집사 하트 아이템이 자동 회수되기까지의 대기 시간(초).
const BUTLER_HEART_AUTO_PICK_DELAY: float = 0.1
## 집사 하트 아이템 회수 이동 속도 (px/s).
const BUTLER_HEART_PICK_SPEED: float = 800.0

## 전차칸 길이가 다를 경우 드롭 X좌표 제한에 사용. 기본값 [code]0.0[/code]이면 표준 맵 길이 적용.
var train_length: float = 0.0

## 드롭 아이템의 종류 (티켓, 집사 하트 등).
var item_type : DropItemManager.ItemType
## 티켓 세부 등급 (쓰레기/일반/골드/플래티넘).
var ticket_type : DropItemManager.TicketType = DropItemManager.TicketType.NONE

## 플레이어가 회수 가능한 상태인지 여부.
var can_pick: bool = false
## 정상 수집 여부. [code]false[/code]인 채로 제거되면 보상을 대신 지급한다.
var was_collected: bool = false

## 메인 메뉴로 나가는 중인지 여부(전역 공유). 씬 전체 해체 시 [method _exit_tree]의 보상 발사를 막아
## 죽어가는 노드들의 연쇄 크래시를 방지한다. [Gameplay]._ready에서 false로 리셋된다.
static var exiting_to_menu := false

## 현재 활성 트윈 참조.
var tween: Tween
## 낙하 경과 시간.
var time_passed: float = 0.0
## 낙하 애니메이션 지속 시간(초).
var duration: float = 0.8

## 포물선 낙하 중인지 여부.
var moving := true
## 낙하 목표 X좌표.
var target_x: float

var drop_height: float = 150.0  # 시작 높이
var peak_offset: float = -180.0  # 위로 얼마나 튈지

## 포물선 시작 Y좌표.
var start_y: float
## 포물선 꼭짓점 Y좌표.
var peak_y: float
## 착지 Y좌표.
var ground_y: float

## 플레이어에게 회수 이동 중인지 여부.
var is_picking: bool = false
## 회수 시 이동할 대상 노드.
var pick_target_node: Node2D
## 회수 이동 시 약간의 랜덤 오프셋으로 자연스러운 궤적을 만든다.
var pick_target_rand_offset := Vector2(randf_range(-20, 20), randf_range(-20, 20))
## 회수 이동 속도 (px/s).
var pick_speed: float = 600.0
## 직전 프레임 타겟 위치 (순간이동 감지용).
var _last_pick_target_pos := Vector2.ZERO

## 아이템 정보 설정 및 물리 초기화를 수행한다.
func _ready() -> void:
	set_item_info()
	
	set_item_phisics_init()

## [member item_type]과 [member ticket_type]에 따라 아이템 텍스처를 설정한다.
func set_item_info():
	if item_type == DropItemManager.ItemType.TICKET:
		match ticket_type:
				DropItemManager.TicketType.TICKET_TRASH:
					item_texture.texture = Constants.TICKET_TRASH_ICON
				DropItemManager.TicketType.TICKET_NORMAL:
					item_texture.texture = Constants.TICKET_ICON
				DropItemManager.TicketType.TICKET_GOLD:
					item_texture.texture = Constants.TICKET_GOLD_ICON
				DropItemManager.TicketType.TICKET_PLATINUM:
					item_texture.texture = Constants.TICKET_PLATINUM_ICON
	elif item_type == DropItemManager.ItemType.BUTLER_HEART:
		item_texture.texture = Constants.HEART_BUTLER_ICON
## 아이템 회수 시 종류에 따라 보상을 지급한다.
## [br]티켓이면 [signal GameEvents.emit_set_ticket], 집사 하트이면 호감도 경험치를 추가한다.
func collect_item():
	was_collected = true
	var player := pick_target_node as Player
	if player:
		match item_type:
			DropItemManager.ItemType.TICKET:
				player.ui_sound_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.GET_TICKET)
			DropItemManager.ItemType.BUTLER_HEART:
				player.ui_sound_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.GET_BUTLER_HEART)
	if item_type == DropItemManager.ItemType.TICKET:
		var ticket_price: int = 0
		match ticket_type:
			DropItemManager.TicketType.TICKET_TRASH:
				ticket_price = Constants.TICKET_VALUE_TRASH
			DropItemManager.TicketType.TICKET_NORMAL:
				ticket_price = Constants.TICKET_VALUE_NORMAL
			DropItemManager.TicketType.TICKET_GOLD:
				ticket_price = Constants.TICKET_VALUE_GOLD
			DropItemManager.TicketType.TICKET_PLATINUM:
				ticket_price = Constants.TICKET_VALUE_PLATINUM
		GameEvents.emit_set_ticket("plus", ticket_price)
	elif item_type == DropItemManager.ItemType.BUTLER_HEART:
		GameEvents.emit_get_npc_exp(Constants.INCRESE_LOVE_EXP_BUTLER, GameEvents.NpcTypes.BUTLER)

## 드롭 물리 초기값을 설정한다.
## [br]랜덤 낙하 높이, 포물선 꼭짓점, 착지 위치, X좌표 이동 트윈을 생성한다.
func set_item_phisics_init():
	collision_shape_2d.set_deferred("disabled", true)
	z_index = 2
	
	# 랜덤 drop_height (예: 100~200 사이)
	drop_height = randf_range(50.0, 200.0)

	# 랜덤 peak_offset (예: -160 ~ -200 사이)
	peak_offset = randf_range(-200.0, -160.0)
	
	var target_ground_y_offset:= randf_range(-15.0, -40.0)

	# 착지 위치가 0이면 현재 위치로 설정 (기본값)
	const MAP_HEIGHT := 360 - 20 #맵 Y값 - 오프셋
	ground_y = clamp(position.y + target_ground_y_offset, 0.0, MAP_HEIGHT)

	# 시작 위치 설정
	start_y = ground_y - drop_height
	peak_y = start_y + peak_offset
	position.y = start_y

	# 랜덤 X 좌표
	var rand_pos: Vector2
	rand_pos.x = randf_range(position.x - 250, position.x + 250)
	target_x = clamp(rand_pos.x, 0.0, set_limit_drop_x_pos())  # X 좌표 제한

	# X 이동 트윈
	tween = create_tween()
	tween.tween_property(self, "position:x", target_x, duration)

## 아이템이 떨어질 수 있는 X좌표 최대값을 반환한다.
## [br][member train_length]가 설정되어 있으면 해당 값을 사용하고, 아니면 기본 맵 길이를 사용한다.
func set_limit_drop_x_pos()-> float:
	var offset: float = 40.0
	var map_length: float = 1920.0
	
	# 길이 제한 변경
	if train_length > 0.0:
		map_length = train_length
	
	var x_pos: float = map_length - offset
	return x_pos

## 매 프레임 포물선 낙하 또는 회수 이동을 처리한다.
## [br]Why: Tween 대신 수동 베지어 계산을 사용하는 이유는 포물선 궤적의 정밀한 제어를 위해서이다.
func _process(delta: float) -> void:
	if moving:
		time_passed += delta
		var t :float = clamp(time_passed / duration, 0.0, 1.0)

		# 포물선 계산: 단순 quadratic bezier 방식
		# y(t) = (1 - t)^2 * start + 2*(1 - t)*t * peak + t^2 * ground
		var one_minus_t = 1.0 - t
		position.y = one_minus_t * one_minus_t * start_y \
			+ 2.0 * one_minus_t * t * peak_y \
			+ t * t * ground_y
	
		if t >= 1.0:
			moving = false
			set_bounce()

	elif is_picking and pick_target_node:
		var target_pos: Vector2 = pick_target_node.global_position + Vector2(0.0, -150.0) + pick_target_rand_offset

		# 칸 전환으로 플레이어가 순간이동한 경우 즉시 수집
		if _last_pick_target_pos != Vector2.ZERO:
			var jump_dist := _last_pick_target_pos.distance_to(target_pos)
			if jump_dist > 400.0:
				#print("[DropItem] 순간이동 감지 → 즉시 수집")
				collect_item()
				queue_free()
				return
		_last_pick_target_pos = target_pos

		global_position = global_position.move_toward(target_pos, pick_speed * delta)
		if global_position.distance_to(target_pos) < 2.0:
			collect_item()
			queue_free()
	


## 착지 후 바운스 애니메이션을 재생한다.
func set_bounce():
	tween = create_tween()
	tween.tween_property(self, "position:y", position.y-20.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "position:y", position.y, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_callback(set_can_pick).set_delay(0.4)

## 회수 가능 상태로 전환하고 상하 유동 루프 애니메이션을 시작한다.
func set_can_pick():
	collision_shape_2d.disabled = false
	GameEvents.emit_can_pick_item()
	
	var current_position = position
	tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", current_position.y-10.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", current_position.y, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	can_pick = true

	if item_type == DropItemManager.ItemType.BUTLER_HEART:
		get_tree().create_timer(BUTLER_HEART_AUTO_PICK_DELAY).timeout.connect(_auto_pick)

## 타이머 만료 시 아직 회수되지 않은 경우 플레이어를 자동으로 찾아 회수를 시작한다.
func _auto_pick():
	if is_picking:
		return
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		set_pick(nodes[0] as Node2D)

## 플레이어가 아이템을 회수하기 시작할 때 호출된다.
## [br][param player_node]를 추적 대상으로 설정하고 유동 트윈을 중지한다.
func set_pick(player_node: Node2D):
	is_picking = true
	if item_type == DropItemManager.ItemType.TICKET:
		pick_target_node = player_node
	elif item_type == DropItemManager.ItemType.BUTLER_HEART:
		pick_target_node = player_node
		pick_speed = BUTLER_HEART_PICK_SPEED
		
	can_pick = false
	tween.kill()

## 스테이지 전환 등으로 수집되지 않고 제거될 때 집사 하트 보상을 대신 지급한다.
func _exit_tree() -> void:
	if exiting_to_menu: # 메인메뉴 종료로 씬이 통째로 해체되는 중이면 보상 발사 금지 (연쇄 크래시 방지)
		return
	if item_type == DropItemManager.ItemType.BUTLER_HEART and not was_collected:
		print("[DropItem] Butler heart loss compensation granted (stage transition)")
		GameEvents.emit_get_npc_exp(Constants.INCRESE_LOVE_EXP_BUTLER, GameEvents.NpcTypes.BUTLER)

## [param npc_type]에 해당하는 NPC 노드를 [code]"npc"[/code] 그룹에서 검색하여 반환한다.
func get_npc_node(npc_type: int)-> Node2D:
	var npcs = get_tree().get_nodes_in_group("npc")
	for i in npcs:
		var npc:Npc = i
		if npc.npc_name == npc_type:
			return npc
	return null
