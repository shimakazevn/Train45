extends CanvasLayer
class_name TrainHud
## [KR] 게임 내 HUD(헤드업 디스플레이) 레이어.
## [EN] In-game HUD (heads-up display) layer.
## [KR] 파트너 UI, 티켓 카운트, 네비게이션·인벤토리 아이콘 등을 관리한다.
## [EN] Manages partner UI, ticket count, navigation/inventory icons, etc.
## [KR] 스테이지 전환·대화·상점 상태에 따라 자동으로 표시/숨김 처리한다.
## [EN] Automatically shows/hides based on stage transition, dialogue, and shop state.


## [KR] 층 관리자 참조. 현재 스테이지 타입 확인에 사용.
## [EN] Floor manager reference. Used for checking current stage type.
@export var floor_manager: Node
## [KR] 파트너 관리자 참조.
## [EN] Partner manager reference.
@export var partner_manager: Node
## [KR] 티켓 관리자 참조. 티켓 수 변동 시그널 구독.
## [EN] Ticket manager reference. Subscribes to ticket count change signals.
@export var ticket_manager: Node
## [KR] 업그레이드(상점) 관리자. 상점 열림/닫힘 시 HUD 숨김 처리.
## [EN] Upgrade (shop) manager. Handles HUD hiding on shop open/close.
@export var upgrade_manager: UpgradeManager
## [KR] 티켓 UI 컨테이너. 등장/퇴장 애니메이션 담당.
## [EN] Ticket UI container. Handles enter/exit animations.
@export var ticket_container: HBoxContainer
## [KR] 노선 설정 네비게이션 아이콘.
## [EN] Route setting navigation icon.
@export var route_set_icon : RouteSetIcon
## [KR] 인벤토리 버튼 아이콘.
## [EN] Inventory button icon.
@export var inven_icon: Button
## [KR] 장비 아이템 UI 컨테이너.
## [EN] Equipment item UI container.
@export var equip_item_container: HBoxContainer
## [KR] 플레이어 참조. [method _process]에서 지연 초기화.
## [EN] Player reference. Lazily initialized in [method _process].
var player : Player

## [KR] 현재 표시 중인 티켓 수. 트윈 애니메이션의 시작값으로 사용.
## [EN] Currently displayed ticket count. Used as start value for tween animation.
var current_ticket : int

## [KR] 현재 파트너 정보 UI 노드.
## [EN] Current partner info UI node.
@onready var current_partner_ui = %CurrentPartnerUI
## [KR] 파트너 UI 자동 숨김 타이머.
## [EN] Partner UI auto-hide timer.
@onready var timer = %CurrentPartnerUI/Timer
## [KR] 파트너 UI 등장/퇴장 애니메이션 플레이어.
## [EN] Partner UI enter/exit animation player.
@onready var animation_player = %CurrentPartnerUI/AnimationPlayer
## [KR] 티켓 총 수량 텍스트 라벨.
## [EN] Ticket total count text label.
@onready var ticket_num := %TicketNum
## [KR] 티켓 증감량 표시 라벨 (예: [code]+5[/code]).
## [EN] Ticket delta display label (e.g., [code]+5[/code]).
@onready var ticket_plus = %TicketPlus
## [KR] 티켓 카운트 in/out 애니메이션 플레이어.
## [EN] Ticket count in/out animation player.
@onready var count_anim = %TicketAnim

## [KR] 최신 티켓 수. 트윈 애니메이션의 목표값.
## [EN] Latest ticket count. Target value for tween animation.
var latest_num: int = 0
## [KR] 티켓 카운트 애니메이션 유예 타이머. 연속 획득 시 한 번에 합산 표시.
## [EN] Ticket count animation delay timer. Displays sum at once for consecutive acquisitions.
var delay_timer: Timer
## [KR] 현재 카운트 애니메이션 진행 중 여부.
## [EN] Whether the count animation is currently in progress.
var is_animating: bool = false

## [KR] 초기화. 시그널 연결, 티켓 UI 초기 세팅, 유예 타이머를 생성한다.
## [EN] Initialization. Connects signals, sets up ticket UI, and creates delay timer.
func _ready():
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	upgrade_manager.shop_state_changed.connect(_on_shop_state_changed)
	GameEvents.stage_change.connect(_on_stage_change)
	GameEvents.stage_clear.connect(_on_stage_clear)
	GameEvents.in_next_stage.connect(_on_in_next_stage)
	timer.wait_time = 3.0  # [KR] UI가 보일 시간 (3초) / [EN] UI display duration (3 seconds)
	timer.timeout.connect(_on_timer_timeout)
	
	ticket_manager.ticket_updated.connect(on_ticket_updated)
	current_ticket = ticket_manager.current_ticket
	#on_ticket_updated(ticket_manager.current_ticket)
	ticket_num.text = str(current_ticket)
	ticket_container.ticket_in()
	
	delay_timer = Timer.new()
	delay_timer.one_shot = true
	delay_timer.wait_time = 2.0
	delay_timer.timeout.connect(_on_delay_timeout)
	add_child(delay_timer)


## [KR] 매 프레임 호출. 티켓 증감 라벨이 0이 되면 카운트 UI를 자동 퇴장시킨다.
## [EN] Called every frame. Auto-exits the count UI when the ticket delta label reaches 0.
func _process(_delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	if floor_manager == null:
		print("Floor manager is empty")
		return
	
	if (ticket_plus.text == "0" or ticket_plus.text == "+0") \
		and ticket_plus.visible \
		and (count_anim.current_animation != "out" or !count_anim.is_playing()):

		ticket_count_state = TicketCountState.OUT
		count_anim.play("out")

		if floor_manager.current_stage_type != Constants.TYPE_BASE:
			ticket_container.ticket_out()
	
	

## [KR] 스테이지 진입 완료 시 호출. 베이스면 파트너 UI·네비·인벤 표시, 아니면 숨긴다.
## [EN] Called on stage entry completion. Shows partner UI/navi/inventory on base, hides otherwise.
func _on_stage_change():
	if floor_manager.current_stage_type == Constants.TYPE_BASE:
		current_partner_ui.visible = true
		ticket_container.ticket_in()
		route_set_icon.navi_on(true)
		inven_icon.inven_on(true)
	else:
		route_set_icon.navi_on(false)
		inven_icon.inven_on(false)

	# [KR] 타이머 설정
	# [EN] Timer setup
	timer.wait_time = 3.0  # [KR] UI가 보일 시간 (3초) / [EN] UI display duration (3 seconds)
	timer.start()

## [KR] 문 진입 또는 텔레포트 순간 호출. 네비·인벤 아이콘을 즉시 숨긴다.
## [EN] Called at the moment of door entry or teleport. Immediately hides navi/inventory icons.
func _on_in_next_stage():
	route_set_icon.navi_on(false)
	inven_icon.inven_on(false)


## [KR] 스테이지 클리어 시 파트너 UI를 표시하고 자동 숨김 타이머를 시작한다.
## [EN] Shows partner UI on stage clear and starts the auto-hide timer.
func _on_stage_clear():
	# [KR] 초기 설정
	# [EN] Initial setup
	current_partner_ui.visible = true

	# [KR] 타이머 설정
	# [EN] Timer setup
	timer.wait_time = 3.0  # [KR] UI가 보일 시간 (3초) / [EN] UI display duration (3 seconds)
	timer.start()

var is_running := false
## [KR] 티켓 카운트 UI 상태. [code]COUNTING[/code]이면 증감 표시 중, [code]OUT[/code]이면 퇴장 완료.
## [EN] Ticket count UI state. [code]COUNTING[/code] = showing delta, [code]OUT[/code] = exit complete.
enum TicketCountState {COUNTING, OUT}
var ticket_count_state: TicketCountState = TicketCountState.OUT

## [KR] 티켓 수 변동 시 호출. 증감량을 표시하고 유예 타이머를 (재)시작한다.
## [EN] Called on ticket count change. Displays delta and (re)starts the delay timer.
## Why: 짧은 시간 내 연속 획득 시 유예 후 한 번에 합산 애니메이션을 재생하기 위함.
func on_ticket_updated(num: int):
	latest_num = num
	var delta = latest_num - current_ticket
	if delta == 0:
		return

	# [KR] 즉시 표시할 부분
	# [EN] Part to display immediately
	ticket_plus.text = "%+d" % delta
	if ticket_count_state == TicketCountState.OUT:
		count_anim.play("in")
	ticket_container.ticket_in()
	
	ticket_count_state = TicketCountState.COUNTING
	
	# [KR] 유예 시간 리셋
	# [EN] Reset delay time
	if delay_timer.is_stopped():
		delay_timer.start()
	else:
		delay_timer.stop()
		delay_timer.start()

## [KR] [param from]에서 [param to]까지 티켓 수를 트윈 애니메이션으로 카운트한다.
## [EN] Counts ticket number from [param from] to [param to] with tween animation.
func start_ticket_tween(from: int, to: int):
	var tracker := {"prev_value": from}
	var assign = func(v):
		var int_val = round(v)
		if int_val != tracker.prev_value:
			tracker.prev_value = int_val
		ticket_num.text = str(int_val)

	var tween := create_tween()
	tween.tween_method(assign, from, to, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

## [KR] 증감량 라벨을 [param from]에서 0까지 트윈으로 감소시킨다.
## [EN] Tweens the delta label from [param from] to 0.
func start_ticket_plus_tween(from: int):
	var assign = func(v):
		ticket_plus.text = "%+d" % round(v)

	var tween := create_tween()
	tween.tween_method(assign, from, 0, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

## [KR] 유예 타이머 만료 시 호출. 누적된 증감량을 트윈 애니메이션으로 반영한다.
## [EN] Called when delay timer expires. Reflects accumulated delta with tween animation.
func _on_delay_timeout():
	# [KR] 애니메이션 시작
	# [EN] Start animation
	start_ticket_tween(current_ticket, latest_num)
	start_ticket_plus_tween(latest_num - current_ticket)
	current_ticket = latest_num

## [KR] 자동 숨김 타이머 만료 시 [method ui_exit]를 호출한다.
## [EN] Calls [method ui_exit] when the auto-hide timer expires.
func _on_timer_timeout():
	ui_exit()

## [KR] 베이스 스테이지가 아닐 경우 티켓·NPC UI를 퇴장시킨다.
## [EN] Exits ticket/NPC UI if not on the base stage.
func ui_exit():
	if floor_manager.current_stage_type == Constants.TYPE_BASE:
		return # [KR] 베이스 아니면 ui사라짐 / [EN] UI disappears if not base
	
	ticket_container.ticket_out()
	
	npc_ui_exit()

## [KR] NPC 관련 UI 퇴장 처리. 하위 클래스에서 오버라이드 가능.
## [EN] NPC-related UI exit handling. Can be overridden in subclasses.
func npc_ui_exit():
	pass

## [KR] Dialogic 타임라인 시작 시 HUD 전체를 숨긴다.
## [EN] Hides the entire HUD when Dialogic timeline starts.
func _on_timeline_started():
	hide()

## [KR] Dialogic 타임라인 종료 시 HUD를 다시 표시한다. 에필로그 방에서는 숨김 유지.
## [EN] Shows HUD again when Dialogic timeline ends. Stays hidden in epilogue room.
func _on_timeline_ended():
	if GameEvents.is_epilogue_room:
		hide()
		return
	show()

## [KR] 상점 열림/닫힘 상태에 따라 HUD를 숨기거나 표시한다.
## [EN] Hides or shows HUD based on shop open/close state.
func _on_shop_state_changed(state: int):
	if state == upgrade_manager.ShopState.OPEN:
		hide()
	else:
		show()
