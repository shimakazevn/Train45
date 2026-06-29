extends Control
class_name SubPartnerSlot

var sub_npc_ui: SubNpcUi
var partner_manager: PartnerManager
var partner : Npc
@onready var visual_box: Control = $VisualBox

@onready var current_partner_ui: TextureRect = $VisualBox/SubNpcFrame/CurrentPartnerUI
@onready var white_bar: TextureProgressBar = $VisualBox/SubLove/WhiteBar
@onready var love_progress_bar: TextureProgressBar = $VisualBox/SubLove/LoveProgressBar
@onready var love_level: Label = $VisualBox/SubLove/LoveLevel
@onready var ero_gauge_progress: TextureProgressBar = $VisualBox/EroGaugeProgress

const MAX_SIZE_X: float = 68.0
const MIN_SIZE_X: float = 43.0
const INNER_Y: float = 70.0
const OUTER_Y: float = 0.0
const WAIT_TIME: float = 3.0

var tween: Tween

func _ready() -> void:
	if partner_manager:
		partner_manager.love_gage_update.connect(_on_npc_exp_getted)
		partner_manager.ero_gage_update.connect(_on_ero_gauge_updated)
	white_bar.value_changed.connect(_on_bar_value_changed)
	ero_gauge_progress.max_value = Constants.PARTNER_MAX_ERO_GAUGE
	
	
	setting_partner()
	
	visual_box.position.y = INNER_Y
	set_show()

func setting_partner():
	if partner == null:
		return
	
	current_partner_ui.texture = Constants.SD_ICONS[partner.npc_name]
	_on_npc_love_level_up(partner.npc_name)
	
	##max value 먼저 설정후 value 설정
	white_bar.max_value = partner.target_love_exp
	white_bar.value = partner.love_exp
	
	love_progress_bar.max_value = white_bar.max_value
	if partner.npc_name == PartnerManager.NpcType.REINA or partner.npc_name == PartnerManager.NpcType.MAI:
		ero_gauge_progress.show()
		ero_gauge_progress.value = partner.ero_gage
		self.custom_minimum_size.x = MAX_SIZE_X
		
	else:
		self.custom_minimum_size.x = MIN_SIZE_X
		ero_gauge_progress.hide()
	
	partner.love_level_up_event.connect(_on_npc_love_level_up)

func set_show(wait_time: float = 0.0):
	if not is_inside_tree(): # 씬 해체 중 트리에서 빠진 상태면 트윈/타이머 생성 불가 (get_tree() null)
		return
	tween = create_tween()
	tween.tween_property(visual_box, "position:y", OUTER_Y, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	if wait_time > 0.0:
		await get_tree().create_timer(wait_time).timeout
		if not is_inside_tree(): # await 사이에 트리에서 빠졌을 수 있으므로 재확인
			return
		set_out()

func set_out():
	tween = create_tween()
	tween.tween_property(visual_box, "position:y", INNER_Y, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)

func _on_bar_value_changed(value: float):
	var bar_tween: Tween = create_tween()
	bar_tween.tween_property(love_progress_bar, "value", value, 0.5)

func _on_ero_gauge_updated(npc_type: int, gauge):
	
	
	if partner.npc_name == npc_type:
		if visible == true:
			if is_type_stage():
				set_show(WAIT_TIME)
			tween = create_tween()
			tween.tween_property(ero_gauge_progress, "value", gauge, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		else:
			self.value = gauge

func _on_npc_love_level_up(npc_type: int):
	if partner.npc_name == npc_type:
		var max_level: int = partner_manager.get_partner_max_level(npc_type)
		
		if partner.love_level >= max_level:
			love_level.text = "MAX"
			await get_tree().process_frame
			white_bar.value = white_bar.max_value
		else:
			await get_tree().process_frame
			love_level.text = str(partner.love_level)
			white_bar.max_value = partner.target_love_exp
			white_bar.value = partner.love_exp
			love_progress_bar.max_value = white_bar.max_value

func _on_npc_exp_getted(npc_type: PartnerManager.NpcType, current_exp : int):
	if partner.npc_name == npc_type:
		if is_type_stage():
			set_show(WAIT_TIME)
		white_bar.value = current_exp

func is_type_stage()-> bool:
	var stg_type: int = sub_npc_ui.get_current_stage_type()
	if stg_type == Constants.TYPE_STAGE or stg_type == Constants.TYPE_SAFE:
		return true
	return false
