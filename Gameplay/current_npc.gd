## 현재 스테이지에 배치할 파트너 NPC를 생성하고 관리하는 컴포넌트.
## [member PartnerManager.current_partner]에 따라 적절한 NPC 씬을 인스턴스화하며,
## 스테이지 타입에 따른 위치 설정 및 좌우 반전을 처리한다.
extends Node2D
class_name CurrentNpc

## 현재 파트너 NPC 타입 인덱스 (Constants.NPC_OL 등)
var partner
## 인스턴스화된 현재 파트너 [Npc] 노드
var current_partner: Npc
## NPC 타입별 [PackedScene] 배열 — 인덱스가 [code]Constants.NPC_*[/code]에 대응
@export var Npcs:Array[PackedScene]
## [code]true[/code]이면 스테이지에서 NPC를 표시, [code]false[/code]이면 숨김 상태로 시작
@export var npc_on_stage := true
## NPC 초기 좌우 반전 여부
@export var npc_flip := false

## [PartnerManager] 참조 (런타임에 그룹으로 검색)
var partner_manager
## 현재 스테이지 타입 ([code]Constants.TYPE_STAGE[/code] 등)
var current_stage_type : int

## 파트너 매니저에서 현재 파트너를 조회하고 해당 NPC 씬을 인스턴스화한다.
## [member npc_on_stage]가 [code]false[/code]이면 NPC를 숨김 상태로 설정한다.
func _ready():
	npc_visible()
	partner_manager = get_tree().get_first_node_in_group("partnermanager")
	partner = partner_manager.current_partner
	var npc : Npc
	match partner:
		Constants.NPC_OL:
			npc = Npcs[Constants.NPC_OL].instantiate()
			add_child(npc)
		Constants.NPC_GYARU: 
			npc = Npcs[Constants.NPC_GYARU].instantiate()
			add_child(npc)
		Constants.NPC_KONIAL: 
			npc = Npcs[Constants.NPC_KONIAL].instantiate()
			add_child(npc)
	npc.set_flip(npc_flip)
	npc.position = self.position
	self.position = Vector2.ZERO
	if not npc_on_stage:
		npc.stage_state = Npc.StageState.NPC_HIDE
	current_partner = npc

## [member npc_on_stage] 값에 따라 노드 가시성을 설정한다.
func npc_visible():
	if !npc_on_stage:
		visible = false
	else:
		visible = true

## [param stage_type]을 저장하고, 일반/안전 스테이지면 NPC 탐색 위치를 설정한다.
func get_stage_type(stage_type: int):
	current_stage_type = stage_type
	var current_npc = get_child(0) as Npc
	if current_stage_type == Constants.TYPE_STAGE or \
		current_stage_type == Constants.TYPE_SAFE:
		current_npc.set_find_position()

## NPC 좌우 반전을 설정한다. [param flip]이 [code]false[/code]면 왼쪽, [code]true[/code]면 오른쪽.
func current_npc_flip(flip: bool):
	var current_npc = get_child(0) as Npc
	current_npc.set_flip(flip)

## NPC 위치를 [param pos]로 직접 설정한다.
func set_current_npc_position(pos: Vector2):
	var current_npc = get_child(0) as Npc
	current_npc.position = pos
