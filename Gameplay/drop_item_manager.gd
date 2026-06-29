## NPC 또는 플레이어 위치에 드롭 아이템(티켓, 집사 하트 등)을 생성하는 매니저.
## 호감도 기반 [code]ticket_drop_table[/code]을 사용하여 티켓 등급을 확률적으로 결정한다.
extends Node
class_name DropItemManager


## 드롭 아이템으로 인스턴스화할 [PackedScene] 템플릿
@export var item: PackedScene
## 현재 레벨 정보를 조회하기 위한 [FloorManager] 참조
@export var floor_manager: FloorManager
## 파트너 NPC 정보(호감도 등)를 조회하기 위한 [PartnerManager] 참조
@export var partner_manager: PartnerManager
## 화면 밖 아이템 마커에 드롭 아이템을 등록하기 위한 참조
@export var screen_out_item_marker: ScreenOutItemMarker

## 드롭 아이템 종류 — [code]TICKET[/code]: 티켓, [code]BUTLER_HEART[/code]: 집사 하트
enum ItemType {TICKET, BUTLER_HEART}
## 티켓 등급 — 호감도에 따라 확률적으로 결정됨
enum TicketType {NONE, TICKET_TRASH, TICKET_NORMAL, TICKET_GOLD, TICKET_PLATINUM}

func _ready() -> void:
	GameEvents.drop_item.connect(_on_drop_item, CONNECT_DEFERRED)

## [signal GameEvents.drop_item] 시그널 수신 시 호출.
## [param npc_type]에 해당하는 NPC(또는 플레이어) 위치를 찾아 [param count]개의 아이템을 생성한다.
func _on_drop_item(npc_type: int, item_type: DropItemManager.ItemType, count: int):
	
	#뿌려줄 위치 지정
	var target_position: Vector2
	
	if npc_type == Constants.PC_PLAYER:
		target_position = floor_manager.current_level.player.position
	else:
		var npcs = floor_manager.current_level.get_tree().get_nodes_in_group("npc")
		for i in npcs:
			var npc = i as Npc
			if npc.npc_name == npc_type:
				target_position = npc.position

	for i in count:
		set_drop_item(target_position, item_type)
			# 2번마다 한 번씩만 타이머 대기
		if i % 4 == 1:
			await get_tree().create_timer(0.01).timeout

## 단일 드롭 아이템을 [param target_position] 위치에 생성하여 열차에 추가한다.
## [param item_type]이 [code]TICKET[/code]이면 파트너 호감도에 따라 티켓 등급이 결정되고,
## 파트너가 없으면 기본 [code]TICKET_NORMAL[/code]이 할당된다.
func set_drop_item(target_position: Vector2, item_type: DropItemManager.ItemType):
	var current_level_train = floor_manager.current_level.train_standard
	var item_instance = item.instantiate() as DropItem
	item_instance.item_type = item_type
	match item_type:
		DropItemManager.ItemType.TICKET:
			if partner_manager.current_free_h_partner != PartnerManager.NpcType.NONE:
				var current_partner: Npc = partner_manager.partner[partner_manager.current_free_h_partner]
				item_instance.ticket_type = pick_ticket_type_by_love_level(current_partner.love_level)
			else:
				item_instance.ticket_type = TicketType.TICKET_NORMAL
		DropItemManager.ItemType.BUTLER_HEART:
			pass
	
	item_instance.position = target_position
	item_instance.train_length = floor_manager.current_level.variable_map_length
	
	current_level_train.add_child(item_instance)
	screen_out_item_marker.add_drop_items(item_instance)



## 호감도(0~10) 단계별 티켓 등급 드롭 확률 테이블.
## 호감도가 높을수록 고급 티켓(platinum) 확률이 증가한다.
var ticket_drop_table := {
	0: { "trash": 0.8, "normal": 0.2, "gold": 0.0,  "platinum": 0.0 },
	1: { "trash": 0.6, "normal": 0.4, "gold": 0.0,  "platinum": 0.0 },
	2: { "trash": 0.4, "normal": 0.5, "gold": 0.1,  "platinum": 0.0 },
	3: { "trash": 0.2, "normal": 0.6, "gold": 0.15, "platinum": 0.05 },
	4: { "trash": 0.1, "normal": 0.5, "gold": 0.3,  "platinum": 0.1 },
	5: { "trash": 0.0, "normal": 0.3, "gold": 0.4,  "platinum": 0.3 },
	6: { "trash": 0.0, "normal": 0.1, "gold": 0.5, "platinum": 0.4 },
	7: { "trash": 0.0, "normal": 0.0, "gold": 0.2,  "platinum": 0.8 },
	8: { "trash": 0.0, "normal": 0.0, "gold": 0.1,  "platinum": 0.9 },
	9: { "trash": 0.0, "normal": 0.0, "gold": 0.05, "platinum": 0.95 },
	10:{ "trash": 0.0, "normal": 0.0, "gold": 0.0,  "platinum": 1.0 }
}

## [param love_level] 호감도에 따라 [member ticket_drop_table]에서 확률을 조회하여
## 누적 확률 방식으로 티켓 등급을 결정한다.
func pick_ticket_type_by_love_level(love_level: int) -> DropItemManager.TicketType:
	#print("호감도 %d 단계 티켓"%love_level)
	var dist = ticket_drop_table.get(love_level, ticket_drop_table[1])
	var roll = randf()
	var accum = 0.0
	
	for ticket_type in dist.keys():
		accum += dist[ticket_type]
		if roll <= accum:
			match ticket_type:
				"trash": return DropItemManager.TicketType.TICKET_TRASH
				"normal": return DropItemManager.TicketType.TICKET_NORMAL
				"gold": return DropItemManager.TicketType.TICKET_GOLD
				"platinum": return DropItemManager.TicketType.TICKET_PLATINUM

	# fallback
	return DropItemManager.TicketType.NONE
