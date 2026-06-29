## 서브 파트너 UI.
## 메인 파트너 외의 서브 파트너(집사, 코니알 등) 슬롯을 관리하며,
## 파트너 변경·스테이지 전환·이벤트 감상에 따라 슬롯 현황을 갱신한다.
extends Control
class_name SubNpcUi

## 현재 [FloorManager] 참조.
@export var floor_manager: FloorManager
## 현재 [PartnerManager] 참조.
@export var partner_manager: PartnerManager
## 서브 파트너 슬롯 [PackedScene] 템플릿.
@export var sub_partner_slot: PackedScene

## 서브 파트너 슬롯이 배치되는 [HBoxContainer].
@onready var partner_container: HBoxContainer = $HBoxContainer

## 시그널 연결 및 컨테이너 초기화 후 서브 파트너를 설정한다.
func _ready() -> void:
	partner_manager.partner_change.connect(_on_partner_change)
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	GameEvents.stage_change.connect(_on_stage_change)
	GameEvents.in_next_stage.connect(_on_in_next_stage)
	GameEvents.add_read_history.connect(_on_add_read_history)
	
	## 컨테이너 내부 초기화
	if partner_container.get_child_count() > 0:
		for i in partner_container.get_children():
			i.queue_free()
			await i.tree_exited
	
	_on_partner_change(partner_manager.current_partner)
	set_sub_npc()

## 디버그용 입력 처리. [code]ui_copy[/code] 액션으로 서브 파트너를 재설정한다.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_copy"):
		set_sub_npc()

## 이벤트 진행 상황에 따라 집사·코니알 서브 파트너를 추가한다.
func set_sub_npc():
	if MetaProgression.has_read_event(Constants.QUESTLINE_BUTLER_HUMAN):
		add_sub_partner(PartnerManager.NpcType.BUTLER)
	if MetaProgression.has_read_event(Constants.QUESTLINE_KONIAL_BIND):
		add_sub_partner(PartnerManager.NpcType.KONIAL)

## 메인 파트너 변경 콜백. 레이나↔마이 전환 시 서브 파트너 슬롯을 갱신한다.
#레이나와 마이간 파트너가 바뀌면 서브 파트너 노드 현황 변경
func _on_partner_change(npc_type:PartnerManager.NpcType):
	if npc_type == PartnerManager.NpcType.REINA:
		add_sub_partner(PartnerManager.NpcType.MAI)
		erase_sub_partner(PartnerManager.NpcType.REINA)
	elif npc_type == PartnerManager.NpcType.MAI:
		add_sub_partner(PartnerManager.NpcType.REINA)
		erase_sub_partner(PartnerManager.NpcType.MAI)

## 타임라인 시작 시 UI를 숨긴다.
func _on_timeline_started():
	hide()

## 타임라인 종료 시 UI를 다시 표시한다.
func _on_timeline_ended():
	show()

## 스테이지 변경 시 스테이지 타입에 따라 슬롯의 표시/퇴장 상태를 설정한다.
func _on_stage_change():
	if partner_container.get_child_count() > 0:
		for i in partner_container.get_children():
			if is_instance_valid(i):
				var partner_slot: SubPartnerSlot = i
				var stage_type:= floor_manager.current_stage_type
				match stage_type:
					Constants.TYPE_BASE:
						partner_slot.set_show()
					Constants.TYPE_STAGE, Constants.TYPE_SAFE:
						partner_slot.set_out()
				await get_tree().create_timer(0.3).timeout

## 다음 스테이지 진입 콜백. (현재 미사용)
func _on_in_next_stage():
	pass

## [param npc_type]에 해당하는 서브 파트너 슬롯을 컨테이너에 추가한다.
## 이미 동일 NPC가 존재하면 중복 추가하지 않는다.
func add_sub_partner(npc_type:PartnerManager.NpcType):
	var sub_partner_inst: SubPartnerSlot = sub_partner_slot.instantiate()
	
	##중복일 시 return
	for i in partner_container.get_children():
		var current_partner_slot: SubPartnerSlot = i
		if current_partner_slot.partner:
			if current_partner_slot.partner.npc_name == npc_type:
				return
	
	sub_partner_inst.partner = partner_manager.partner[npc_type]
	sub_partner_inst.partner_manager = partner_manager
	sub_partner_inst.sub_npc_ui = self
	
	partner_container.add_child(sub_partner_inst)
	sort_slot()

## [param npc_type]에 해당하는 서브 파트너 슬롯을 컨테이너에서 제거한다.
func erase_sub_partner(npc_type:PartnerManager.NpcType):
	if partner_container.get_child_count() > 0:
		for i in partner_container.get_children():
			var partner_slot: SubPartnerSlot = i
			if partner_slot.partner.npc_name == npc_type:
				partner_slot.queue_free()
	sort_slot()

## 슬롯 정렬을 트리거한다.
func sort_slot():
	if partner_container.get_child_count() > 0:
		sort_partner_slots_by_npc_id()

## 서브 파트너 슬롯을 NPC ID 기준 고정 순서(레이나→마이→집사→코니알→파주주)로 정렬한다.
func sort_partner_slots_by_npc_id():
	var children := partner_container.get_children()

	# 원하는 정렬 순서
	var order := [Constants.NpcTypes.REINA, Constants.NpcTypes.MAI, Constants.NpcTypes.BUTLER, Constants.NpcTypes.KONIAL, Constants.NpcTypes.PAZUZU]

	children.sort_custom(func(a, b):
		var a_id :int = a.partner.npc_name
		var b_id :int = b.partner.npc_name

		var a_idx := order.find(a_id)
		var b_idx := order.find(b_id)

		# 혹시 order에 없는 값이 있으면 맨 뒤로
		if a_idx == -1:
			a_idx = order.size()
		if b_idx == -1:
			b_idx = order.size()

		return a_idx < b_idx
	)

	for i in range(children.size()):
		partner_container.move_child(children[i], i)

## 현재 스테이지 타입을 반환한다.
func get_current_stage_type()-> int:
	return floor_manager.current_stage_type

## 이벤트 대화 감상 후 파트너 현황을 업데이트한다.
## [param event_name]이 집사 인간화 또는 코니알 구속 이벤트이면 서브 파트너를 재설정한다.
func _on_add_read_history(event_name: String):
	match event_name:
		Constants.QUESTLINE_BUTLER_HUMAN, Constants.QUESTLINE_KONIAL_BIND:
			set_sub_npc()
