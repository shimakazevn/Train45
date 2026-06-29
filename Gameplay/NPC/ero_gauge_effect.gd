extends CPUParticles2D

@export var is_npc: Npc
var partner_manager: PartnerManager
var floor_manager: FloorManager

func _ready() -> void:
	if is_npc != null and is_npc.data_only:
		emitting = false
		return
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	GameEvents.stage_change.connect(_on_stage_changed)
	GameEvents.in_next_stage.connect(_in_next_stage)
	floor_manager = get_tree().get_first_node_in_group("floormanager")
	partner_manager = get_tree().get_first_node_in_group("partnermanager") as PartnerManager
	partner_manager.ero_gage_update.connect(_on_ero_gauge_updated)
	self.emitting = false

func _on_timeline_started():
	set_all_visible(false)

func _on_timeline_ended():
	set_all_visible(true)

func _in_next_stage():
	self.hide()
	self.emitting = false

func _on_stage_changed():
	if floor_manager.current_stage_type == Constants.TYPE_BASE:
		set_ero_gauge_effect()
	else:
		self.hide()
		self.emitting = false

func _on_ero_gauge_updated(npc_type:PartnerManager.NpcType, _gage: int):
	if is_npc.npc_name == npc_type:
		set_ero_gauge_effect()

func set_ero_gauge_effect():
	if floor_manager.current_stage_type == Constants.TYPE_BASE:
		var partner: Npc = partner_manager.partner[is_npc.npc_name]
		var amt: int = max(1, int(partner.ero_gage / 10.0))
		self.amount = amt

		if amt <= 3:
			self.emitting = false
		else:
			self.emitting = true
	else:
		self.emitting = false


func set_all_visible(should_show: bool):
	if should_show:
		self.show()
	else:
		self.hide()
