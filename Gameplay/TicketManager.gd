## 플레이어의 티켓 보유량을 관리하는 매니저.
## 티켓 추가/차감 및 스테이지 클리어 보상 처리를 담당하며,
## [signal ticket_updated] 시그널로 UI 등에 변경 사항을 전달한다.
extends Node
class_name TicketManager

## 현재 레벨/층 정보를 조회하기 위한 [FloorManager] 참조
@export var floor_manager : FloorManager
## 티켓 알림 UI에 사용되는 아이콘 리소스
const TICKET_ICON = preload("res://resources/ui/ticket_icon.png")

## 티켓 수량이 변경될 때 현재 보유량 [param num]과 함께 발생
signal ticket_updated(num : int)

## 현재 일반 티켓 보유량
var current_ticket = 0
## 현재 골드 티켓 보유량
var current_ticket_gold = 0


func _ready():
	current_ticket = MetaProgression.get_ticket_num()
	GameEvents.set_ticket.connect(_on_set_ticket)
	GameEvents.stage_clear.connect(on_stage_clear)
	#set_ticket("plus", 777)

## [signal GameEvents.set_ticket] 수신 시 [method set_ticket_info]로 위임
func _on_set_ticket(type: String, number: int):
	set_ticket_info(type, number)

##스테이지 클리어시 티켓 지급
func on_stage_clear():
	pass
	#set_stage_clear_ticket() # 게임 플레이방식 변경으로 인한 스테이지 클리어시 지급 기능 제외
	#push test2

## 스테이지 클리어 시 층수 기반 배율로 티켓을 지급한다. (현재 기능 보류중)
## 안전 구역이면 즉시 지급, 일반 스테이지면 드롭 아이템으로 생성한다.
func set_stage_clear_ticket(): # 현재 기능 보류중
	var current_stage_type: int = floor_manager.current_level.stage_type
	var base_ticket := 5
	var multiplier = score_multiplier(floor_manager.current_floor)
	var result_ticket = base_ticket * multiplier
	if floor_manager.current_floor > 1:
		var message = tr("NOTI_TICKET_BONUS") % [floor_manager.current_floor, multiplier, int(result_ticket)]
		NotionEvent.notion(message, TICKET_ICON)
	if current_stage_type == Constants.TYPE_SAFE:
		GameEvents.emit_set_ticket("plus", result_ticket)
	else:
		GameEvents.emit_drop_item(Constants.PC_PLAYER, DropItemManager.ItemType.TICKET, result_ticket)

## [param current_floor] 층수에 따른 티켓 배율을 반환한다. 1층은 1.0배, 이후 0.5씩 증가.
func score_multiplier(current_floor: int):
	return 1.0 + (current_floor - 1) * 0.5

## 티켓 수량을 실제로 변경하고 [MetaProgression]에 저장한 뒤 [signal ticket_updated]를 발생시킨다.
## [param type]이 [code]"plus"[/code]이면 추가, [code]"minus"[/code]이면 차감한다.
func set_ticket_info(type: String, number: int):
	if type == "plus":
		current_ticket += number
		MetaProgression.add_ticket_total(number)
	elif type == "minus":
		current_ticket -= number
	else:
		print("_on_set_ticket type error")
	MetaProgression.ticket_count_update(current_ticket)
	ticket_updated.emit(current_ticket)

	
