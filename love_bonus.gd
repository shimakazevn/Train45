## 스테이지 클리어 시 현재 파트너에게 호감도 보너스를 지급하고 알림을 표시한다.
extends Node2D

## [PartnerManager] 참조. [method _ready]에서 그룹으로 탐색한다.
var partner_manager : PartnerManager
## 알림에 표시할 호감도 보너스 아이콘.
const ICON_LOVE_BONUS = preload("res://resources/ui/icons/icons10.png")

## 초기화 — [signal GameEvents.stage_clear]에 연결하고 파트너 매니저를 탐색한다.
func _ready() -> void:
	GameEvents.stage_clear.connect(_on_stage_clear)
	partner_manager = get_tree().get_first_node_in_group("partnermanager")

## 스테이지 클리어 시 호출 — 현재 파트너에게 [code]Constants.LOVE_BONUS[/code] 경험치를 지급하고 알림을 표시.
func _on_stage_clear():
	var _npc = partner_manager.get_current_partner() as Npc

	# 기본 클리어 경험치(PartnerManager)에서 이미 "호감도 상승" 알림이 뜨므로 중복 방지를 위해 끔.
	GameEvents.emit_get_npc_exp(Constants.LOVE_BONUS, _npc.npc_name, false)
	var message = tr("NOTI_LOVE_EXP_BONUS")%Constants.LOVE_BONUS

	NotionEvent.notion(message, ICON_LOVE_BONUS)
	# 코니알 보너스는 love_bracelet에서 총합 지급·표시한다(메시지에 보너스 반영 위해 한 곳에서 처리).
