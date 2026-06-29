extends Node2D

var konial: Npc

@onready var progress_bar: TextureProgressBar = $CanvasLayer/TextureProgressBar
@onready var max_exp_label: Label = $CanvasLayer/MaxLabel
@onready var max_level_label: Label = $CanvasLayer/MaxLevelLabel

@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _ready() -> void:
	GameEvents.stage_clear.connect(_on_stage_clear)
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	var partner_manager: PartnerManager = get_tree().get_first_node_in_group("partnermanager")
	konial = partner_manager.partner[Constants.NPC_KONIAL]
	if konial.npc_name != Constants.NPC_KONIAL:
		push_error("konial 이 아닙니다. 확인해주세요.")
	
	set_konial_exp()

func _on_stage_clear():
	# 기본 획득량 + (호감도 보너스 아이템 보유 시) 코니알 축소 보너스
	var gain := Constants.INCRESE_LOVE_EXP_KONIAL
	var panty_equipped := MetaProgression.has_equipment("love_bonus")
	if panty_equipped:
		gain += Constants.KONIAL_LOVE_BONUS
	# 아래에서 보너스 합산값(gain) 메시지를 직접 띄우므로, 경험치 지급 경로의 중복 알림은 끔.
	GameEvents.emit_get_npc_exp(gain, GameEvents.NpcTypes.KONIAL, false)

	# 보너스까지 합산된 총 획득량을 메시지에 표시
	var message = tr("NOTI_ITEM_KONIAL_LOVE_BONUS") % gain
	NotionEvent.notion(message, Constants.SD_ICONS[Constants.NPC_KONIAL])

	set_konial_exp()

func set_konial_exp():
	progress_bar.max_value = konial.target_love_exp
	progress_bar.value = konial.love_exp
	
	if konial.love_level < Constants.NPC_MAX_LEVEL_KONIAL: # 최고 레벨이면 MAX로 표시
		max_level_label.hide()
		
		if konial.love_exp >= konial.target_love_exp:
			## 경험치 맥스인지 확인
			if konial.love_level < Constants.NPC_MAX_LEVEL_KONIAL:
				max_exp_label.show()
			else:
				max_exp_label.hide()
		else:
			max_exp_label.hide()
	else:
		max_level_label.show()
		max_exp_label.hide()

func _on_timeline_started():
	hide()
	canvas_layer.hide()
func _on_timeline_ended():
	show()
	canvas_layer.show()
	set_konial_exp()
