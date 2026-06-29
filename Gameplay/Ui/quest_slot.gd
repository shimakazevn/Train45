extends Panel
class_name QuestSlot

signal quest_cleared

const CHECK_FALSE = preload("res://resources/ui/gui/check_false.png")
const CHECK_TRUE = preload("res://resources/ui/gui/check_true.png")

@onready var icon: TextureRect = $QuestInfoContainer/Icon
@onready var info: Label = $QuestInfoContainer/Info
@onready var check: TextureRect = $QuestInfoContainer/Check
@onready var current_value_label: Label = $QuestInfoContainer/CurrentValue

enum QuestType { LOVE, TICKET, TALK, ROUTE, COLLECT_ITEM, COLLECT_DESTINATION, TOTAL_LOVE, GOAL_COUNT }

# 퀘스트 값
var quest_config := {
	QuestType.LOVE: {
		"value": -1,
		"text_key": "QUEST_PROCESS_LOVE_LEVEL",
		"get_current": func(): return MetaProgression.get_npc_love_level(quest_npc.npc_type) if quest_npc != null else -1,
		"get_icon": func(): return Constants.SD_ICONS.get(quest_npc.npc_type, null) if quest_npc != null else null,
		"checkbox_visible": true
	},
	QuestType.TOTAL_LOVE: {
		"value": -1,
		"text_key": "QUEST_PROCESS_TOTAL_LOVE",  # 예시
		"get_current": func(): return MetaProgression.get_npc_total_love_level(),
		"checkbox_visible": true
	},
	QuestType.TICKET: {
		"value": -1,
		"text_key": "QUEST_PROCESS_TICKET",
		"get_current": func(): return MetaProgression.get_ticket_num(),
		"checkbox_visible": true
	},
	QuestType.ROUTE: {
		"value": -1,
		"text_key": "QUEST_PROCESS_FIND_ROUTE",
		"get_current": func(): return MetaProgression.get_routes_dict().size(),
		"checkbox_visible": true
	},
	QuestType.COLLECT_DESTINATION: {
		"value": -1,
		"text_key": "QUEST_PROCESS_COLLECT_DEST",  # 예시
		"get_current": func(): return MetaProgression.get_current_destination_info().size(),
		"checkbox_visible": true
	},
	QuestType.COLLECT_ITEM: {
		"value": -1,
		"text_key": "QUEST_PROCESS_COLLECT_ITEM",  # 예시
		"get_current": func(): return MetaProgression.get_save_data_ability().size(),
		"checkbox_visible": true
	},
	QuestType.GOAL_COUNT: {
		"value": -1,
		"text_key": "QUEST_PROCESS_GOAL_COUNT",  # 예시
		"get_current": func(): return MetaProgression.get_game_clear_count(),
		"checkbox_visible": true
	},
	QuestType.TALK: {
		"value": -1,
		"text_key": "",  # 그냥 문장 그대로 출력
		"get_current": func(): return 1, # 바로 조건 참
		"checkbox_visible": false
	},
	
}

var type: QuestType
var quest_npc: QuestNpc
var current_quest_clear := false

func _ready() -> void:
	GameEvents.update_quest_process.connect(_on_update_quest_process)
	GameEvents.set_ticket.connect(_on_set_ticket)
	GameEvents.ability_upgrade_added.connect(_on_added_item)

	icon.texture = null
	icon.hide()
	info.text = ""
	current_value_label.text = ""

	set_quest_info()
	check_current_quest()

func set_quest_info():
	if not quest_config.has(type):
		return

	var cfg = quest_config[type]

	# 텍스트
	var value = cfg["value"]
	var current_value = cfg["get_current"].call()
	if cfg["value"] != -1:
		info.text = tr(cfg["text_key"]) % value
		var current_string: String = tr("QUEST_PROCESS_CURRENT")
		current_value_label.text = current_string % current_value

	if type == QuestType.TALK: ##텍스트 형식인 경우 바로 텍스트만 출력
		info.text = tr(cfg["text_key"])
	

	# 아이콘
	if cfg.has("get_icon") and cfg["get_icon"] is Callable:
		var icon_tex = cfg["get_icon"].call()
		if icon_tex:
			icon.texture = icon_tex
			icon.show()

	# 체크박스 기본 가시성
	check.visible = cfg.get("checkbox_visible", true)

##퀘스트 클리어 여부 체크
func check_current_quest():
	current_quest_clear = false

	if not quest_config.has(type):
		return

	var cfg = quest_config[type]
	var target = cfg["value"]
	var current = cfg["get_current"].call()

	if target == -1 or current == null:
		current_quest_clear = false
	else:
		current_quest_clear = current >= target
	
	if type == QuestType.TALK: ##텍스트 형식인 경우 바로 조건 충족
		current_quest_clear = true

	# 체크 이미지 설정
	if cfg.get("checkbox_visible", true):
		if current_quest_clear:
			check.texture = CHECK_TRUE
		else:
			check.texture = CHECK_FALSE
	else:
		check.hide()
	
	if current_quest_clear:
		## 퀘스트가 클리어 됐을때 전체 퀘스트 클리어 여부 검사 신호 방출
		quest_cleared.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		set_quest_info()

func _on_update_quest_process():
	check_current_quest()
	call_deferred("set_quest_info")

##티켓을 획득할 때마다 퀘스트 현황 갱신
func _on_set_ticket(_type:String, _number:int):
	if type == QuestType.TICKET:
		_on_update_quest_process()

##아이템 구매시
func _on_added_item(_upgrade: AbilityUpgrade, _current_upgrades: Dictionary):
	if type == QuestType.COLLECT_ITEM:
		_on_update_quest_process()
